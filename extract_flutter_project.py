from __future__ import annotations

import argparse
import os
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Iterable, Optional, Sequence


SCRIPT_NAME = "extract_flutter_project.py"
SCRIPT_VERSION = "2026.08.19-01"
DEFAULT_OUTPUT_NAME = "FLUTTER_PROJECT_SOURCE.txt"
OUTPUT_ENCODING = "utf-8-sig"
SEPARATOR_WIDTH = 120

# Generated folders, dependency caches, IDE metadata and platform build outputs.
EXCLUDED_DIR_NAMES = {
    ".git",
    ".github",
    ".idea",
    ".metadata",
    ".vscode",
    ".dart_tool",
    ".pub-cache",
    ".fvm",
    ".gradle",
    ".swiftpm",
    ".symlinks",
    "build",
    "coverage",
    "node_modules",
    "Pods",
    "DerivedData",
    "ephemeral",
    ".plugin_symlinks",
    "xcuserdata",
    "tmp",
    "temp",
    "logs",
    "log",
}

# Common Flutter/Dart source, config and platform-wrapper text formats.
TEXT_EXTENSIONS = {
    # Flutter / Dart
    ".dart",
    ".arb",

    # Project/config/data
    ".yaml",
    ".yml",
    ".json",
    ".json5",
    ".toml",
    ".ini",
    ".conf",
    ".config",
    ".properties",
    ".xml",
    ".txt",
    ".md",
    ".csv",

    # Android / JVM
    ".java",
    ".kt",
    ".kts",
    ".gradle",
    ".groovy",
    ".pro",

    # iOS / macOS
    ".swift",
    ".m",
    ".mm",
    ".h",
    ".plist",
    ".pbxproj",
    ".xcconfig",
    ".entitlements",

    # Web
    ".html",
    ".htm",
    ".css",
    ".scss",
    ".sass",
    ".less",
    ".js",
    ".mjs",
    ".cjs",
    ".ts",
    ".tsx",
    ".jsx",

    # Desktop platform code
    ".c",
    ".cc",
    ".cpp",
    ".cxx",
    ".hpp",
    ".cmake",
    ".rc",

    # Scripts
    ".sh",
    ".bash",
    ".zsh",
    ".bat",
    ".cmd",
    ".ps1",
}

TEXT_FILE_NAMES = {
    "pubspec.yaml",
    "pubspec.lock",
    "analysis_options.yaml",
    "l10n.yaml",
    "melos.yaml",
    "build.yaml",
    "build.gradle",
    "build.gradle.kts",
    "settings.gradle",
    "settings.gradle.kts",
    "gradle.properties",
    "gradlew",
    "gradlew.bat",
    "podfile",
    "podfile.lock",
    "gemfile",
    "gemfile.lock",
    "cmakelists.txt",
    "makefile",
    "dockerfile",
    "readme",
    "readme.md",
    "license",
    "notice",
    ".gitignore",
    ".gitattributes",
    ".editorconfig",
    ".packages",
    ".flutter-plugins",
    ".flutter-plugins-dependencies",
}

# Files that can contain credentials, signing material, tokens or private config.
# They stay visible in PROJECT STRUCTURE but their contents are not exported unless
# --include-sensitive is supplied.
SENSITIVE_FILE_NAMES = {
    ".env",
    ".env.local",
    ".env.dev",
    ".env.development",
    ".env.test",
    ".env.staging",
    ".env.prod",
    ".env.production",
    "key.properties",
    "keystore.properties",
    "local.properties",
    "service-account.json",
    "serviceaccount.json",
    "google-services.json",
    "googleservice-info.plist",
    "firebase_options.dart",
    "id_rsa",
    "id_ed25519",
}

SENSITIVE_EXTENSIONS = {
    ".pem",
    ".key",
    ".p8",
    ".p12",
    ".pfx",
    ".jks",
    ".keystore",
    ".cer",
    ".crt",
    ".der",
    ".mobileprovision",
}

READ_ENCODINGS = (
    "utf-8",
    "utf-8-sig",
    "cp1258",
    "cp1252",
    "latin-1",
)


@dataclass(frozen=True)
class SourceFile:
    absolute_path: Path
    relative_path: Path
    size_bytes: int


@dataclass(frozen=True)
class ExportResult:
    output_file: Path
    source_file_count: int
    skipped_binary_count: int
    skipped_sensitive_count: int
    read_error_count: int
    total_lines: int


def parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Export the folder structure and all readable source/config files of "
            "one Flutter project into a single TXT file."
        )
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=None,
        help=(
            "Flutter project root. Default: the directory containing this script "
            "if it looks like a Flutter project; otherwise the current directory."
        ),
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help=(
            f"Output TXT file. Default: ROOT/{DEFAULT_OUTPUT_NAME}. "
            "A relative path is resolved from ROOT."
        ),
    )
    parser.add_argument(
        "--line-numbers",
        action="store_true",
        help="Prefix each exported source line with its original line number.",
    )
    parser.add_argument(
        "--full-path",
        action="store_true",
        help="Also print the absolute path before each source file.",
    )
    parser.add_argument(
        "--include-sensitive",
        action="store_true",
        help=(
            "Also export env files, Firebase config, signing files and other "
            "credential-like files. Use carefully."
        ),
    )
    parser.add_argument(
        "--all-text",
        action="store_true",
        help=(
            "Export every readable non-binary text file, not only common Flutter "
            "source/config extensions."
        ),
    )
    return parser.parse_args(argv)


def looks_like_flutter_project(path: Path) -> bool:
    has_pubspec = (path / "pubspec.yaml").is_file()
    has_flutter_dir = any(
        (path / name).is_dir()
        for name in (
            "lib",
            "android",
            "ios",
            "web",
            "windows",
            "linux",
            "macos",
        )
    )
    return has_pubspec and has_flutter_dir


def resolve_root_dir(root_arg: Optional[Path]) -> Path:
    if root_arg is not None:
        return root_arg.expanduser().resolve()

    script_dir = Path(__file__).resolve().parent
    if looks_like_flutter_project(script_dir):
        return script_dir

    cwd = Path.cwd().resolve()
    if looks_like_flutter_project(cwd):
        return cwd

    return cwd


def resolve_output_file(root_dir: Path, output_arg: Optional[Path]) -> Path:
    if output_arg is None:
        return (root_dir / DEFAULT_OUTPUT_NAME).resolve()

    output = output_arg.expanduser()
    if output.is_absolute():
        return output.resolve()
    return (root_dir / output).resolve()


def validate_root_dir(root_dir: Path) -> None:
    if not root_dir.exists():
        raise FileNotFoundError(f"Project root does not exist: {root_dir}")
    if not root_dir.is_dir():
        raise NotADirectoryError(f"Project root is not a directory: {root_dir}")

    if not looks_like_flutter_project(root_dir):
        print(
            "WARNING: root does not look like a standard Flutter project "
            "(expected pubspec.yaml plus lib/ or a platform directory). "
            "Export will continue.",
            file=sys.stderr,
        )


def is_excluded_dir_name(name: str) -> bool:
    return name.casefold() in {item.casefold() for item in EXCLUDED_DIR_NAMES}


def is_sensitive_file(path: Path) -> bool:
    name = path.name.casefold()
    if name in {item.casefold() for item in SENSITIVE_FILE_NAMES}:
        return True

    # Catch .env.* variants without enumerating every environment name.
    if name.startswith(".env."):
        return True

    return path.suffix.casefold() in {
        item.casefold() for item in SENSITIVE_EXTENSIONS
    }


def is_candidate_text_file(path: Path, all_text: bool) -> bool:
    if all_text:
        return True

    name = path.name.casefold()
    if name in {item.casefold() for item in TEXT_FILE_NAMES}:
        return True

    return path.suffix.casefold() in {
        item.casefold() for item in TEXT_EXTENSIONS
    }


def is_probably_binary(path: Path, sample_size: int = 8192) -> bool:
    try:
        with path.open("rb") as fh:
            sample = fh.read(sample_size)
    except OSError:
        return False

    if not sample:
        return False

    if b"\x00" in sample:
        return True

    control = sum(
        1
        for byte in sample
        if byte < 9 or (13 < byte < 32)
    )
    return (control / len(sample)) > 0.20


def iter_project_files(root_dir: Path, output_file: Path) -> Iterable[Path]:
    output_resolved = output_file.resolve()

    for current_root, dir_names, file_names in os.walk(root_dir, followlinks=False):
        dir_names[:] = sorted(
            [name for name in dir_names if not is_excluded_dir_name(name)],
            key=str.casefold,
        )
        current_path = Path(current_root)

        for file_name in sorted(file_names, key=str.casefold):
            file_path = current_path / file_name
            try:
                if file_path.resolve() == output_resolved:
                    continue
            except OSError:
                pass
            yield file_path


def collect_source_files(
    root_dir: Path,
    output_file: Path,
    include_sensitive: bool,
    all_text: bool,
) -> tuple[list[SourceFile], int, int]:
    source_files: list[SourceFile] = []
    skipped_binary = 0
    skipped_sensitive = 0

    for file_path in iter_project_files(root_dir, output_file):
        if not include_sensitive and is_sensitive_file(file_path):
            skipped_sensitive += 1
            continue

        if not is_candidate_text_file(file_path, all_text=all_text):
            continue

        if is_probably_binary(file_path):
            skipped_binary += 1
            continue

        try:
            size_bytes = file_path.stat().st_size
            relative_path = file_path.relative_to(root_dir)
        except (OSError, ValueError):
            continue

        source_files.append(
            SourceFile(
                absolute_path=file_path,
                relative_path=relative_path,
                size_bytes=size_bytes,
            )
        )

    source_files.sort(key=lambda item: item.relative_path.as_posix().casefold())
    return source_files, skipped_binary, skipped_sensitive


def build_tree_lines(root_dir: Path, output_file: Path) -> list[str]:
    """Build a deterministic project tree while excluding generated/cache dirs."""
    output_resolved = output_file.resolve()
    lines = [f"{root_dir.name}/"]

    def walk(directory: Path, prefix: str) -> None:
        try:
            entries = list(directory.iterdir())
        except OSError as exc:
            lines.append(f"{prefix}[ERROR READING DIRECTORY: {exc}]")
            return

        visible: list[Path] = []
        for entry in entries:
            if entry.is_dir() and is_excluded_dir_name(entry.name):
                continue
            try:
                if entry.is_file() and entry.resolve() == output_resolved:
                    continue
            except OSError:
                pass
            visible.append(entry)

        visible.sort(key=lambda p: (not p.is_dir(), p.name.casefold()))

        for index, entry in enumerate(visible):
            is_last = index == len(visible) - 1
            branch = "└── " if is_last else "├── "
            suffix = "/" if entry.is_dir() else ""
            lines.append(f"{prefix}{branch}{entry.name}{suffix}")

            if entry.is_dir() and not entry.is_symlink():
                extension = "    " if is_last else "│   "
                walk(entry, prefix + extension)

    walk(root_dir, "")
    return lines


def read_text_safely(file_path: Path) -> tuple[str, str, Optional[str]]:
    for encoding in READ_ENCODINGS:
        try:
            return file_path.read_text(encoding=encoding), encoding, None
        except UnicodeDecodeError:
            continue
        except OSError as exc:
            return "", encoding, f"{type(exc).__name__}: {exc}"

    try:
        return (
            file_path.read_text(encoding="utf-8", errors="replace"),
            "utf-8/replace",
            None,
        )
    except OSError as exc:
        return "", "unknown", f"{type(exc).__name__}: {exc}"


def write_separator(out, char: str = "=") -> None:
    out.write(char * SEPARATOR_WIDTH + "\n")


def write_project_structure(out, root_dir: Path, tree_lines: Sequence[str]) -> None:
    write_separator(out)
    out.write("PROJECT STRUCTURE\n")
    out.write(f"PROJECT ROOT: {root_dir}\n")
    write_separator(out)
    for line in tree_lines:
        out.write(line + "\n")
    out.write("\n")


def write_source_file(
    out,
    source: SourceFile,
    index: int,
    total: int,
    line_numbers: bool,
    full_path: bool,
) -> tuple[int, Optional[str]]:
    write_separator(out)
    out.write(f"SOURCE FILE {index}/{total}: {source.relative_path.as_posix()}\n")
    if full_path:
        out.write(f"FULL PATH: {source.absolute_path}\n")
    out.write(f"SIZE: {source.size_bytes} bytes\n")
    write_separator(out, "-")

    content, encoding, error = read_text_safely(source.absolute_path)
    out.write(f"ENCODING: {encoding}\n")
    write_separator(out, "-")

    if error is not None:
        out.write(f"[READ ERROR] {error}\n\n")
        return 0, error

    lines = content.splitlines(keepends=True)
    if line_numbers:
        for line_number, line in enumerate(lines, start=1):
            text = line.rstrip("\r\n")
            out.write(f"{line_number:05d}: {text}\n")
    else:
        out.write(content)
        if content and not content.endswith(("\n", "\r")):
            out.write("\n")

    out.write("\n")
    return len(lines), None


def write_output(
    root_dir: Path,
    output_file: Path,
    source_files: Sequence[SourceFile],
    tree_lines: Sequence[str],
    skipped_binary: int,
    skipped_sensitive: int,
    line_numbers: bool,
    full_path: bool,
) -> ExportResult:
    output_file.parent.mkdir(parents=True, exist_ok=True)

    total_lines = 0
    read_errors = 0

    with output_file.open("w", encoding=OUTPUT_ENCODING, newline="") as out:
        # Requirement: project tree must be the first section.
        write_project_structure(out, root_dir, tree_lines)

        write_separator(out)
        out.write("SOURCE CODE\n")
        write_separator(out)
        out.write(f"Generated: {datetime.now().isoformat(timespec='seconds')}\n")
        out.write(f"Exporter: {SCRIPT_NAME} {SCRIPT_VERSION}\n")
        out.write(f"Source files: {len(source_files)}\n")
        out.write(f"Skipped binary files: {skipped_binary}\n")
        out.write(f"Skipped sensitive files: {skipped_sensitive}\n\n")

        for index, source in enumerate(source_files, start=1):
            line_count, error = write_source_file(
                out=out,
                source=source,
                index=index,
                total=len(source_files),
                line_numbers=line_numbers,
                full_path=full_path,
            )
            total_lines += line_count
            if error is not None:
                read_errors += 1

        write_separator(out)
        out.write("SUMMARY\n")
        write_separator(out)
        out.write(f"Project root: {root_dir}\n")
        out.write(f"Output file: {output_file}\n")
        out.write(f"Exported source files: {len(source_files)}\n")
        out.write(f"Skipped binary files: {skipped_binary}\n")
        out.write(f"Skipped sensitive files: {skipped_sensitive}\n")
        out.write(f"Read errors: {read_errors}\n")
        out.write(f"Total source lines: {total_lines}\n")
        write_separator(out)

    return ExportResult(
        output_file=output_file,
        source_file_count=len(source_files),
        skipped_binary_count=skipped_binary,
        skipped_sensitive_count=skipped_sensitive,
        read_error_count=read_errors,
        total_lines=total_lines,
    )


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = parse_args(argv)

    try:
        root_dir = resolve_root_dir(args.root)
        validate_root_dir(root_dir)
        output_file = resolve_output_file(root_dir, args.output)

        source_files, skipped_binary, skipped_sensitive = collect_source_files(
            root_dir=root_dir,
            output_file=output_file,
            include_sensitive=args.include_sensitive,
            all_text=args.all_text,
        )
        tree_lines = build_tree_lines(root_dir, output_file)

        result = write_output(
            root_dir=root_dir,
            output_file=output_file,
            source_files=source_files,
            tree_lines=tree_lines,
            skipped_binary=skipped_binary,
            skipped_sensitive=skipped_sensitive,
            line_numbers=args.line_numbers,
            full_path=args.full_path,
        )

        print("=" * 100)
        print("DONE - FLUTTER PROJECT SOURCE EXPORT")
        print(f"Version          : {SCRIPT_VERSION}")
        print(f"Project root     : {root_dir}")
        print(f"Output           : {result.output_file}")
        print(f"Source files     : {result.source_file_count}")
        print(f"Skipped binary   : {result.skipped_binary_count}")
        print(f"Skipped sensitive: {result.skipped_sensitive_count}")
        print(f"Read errors      : {result.read_error_count}")
        print(f"Source lines     : {result.total_lines}")
        print("=" * 100)

        return 1 if result.read_error_count else 0

    except (FileNotFoundError, NotADirectoryError, OSError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
