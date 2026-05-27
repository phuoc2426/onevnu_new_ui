from pathlib import Path
from datetime import datetime

# =========================================================
# CẤU HÌNH
# =========================================================

# Folder gốc cần quét
ROOT_DIR = Path(r"D:\Data\App\ONEVNU\git\iworkspace_mobile_onevnu-master")

# File output
OUTPUT_FILE = Path("CODE_BUNDLE.txt")

# Có đọc file trong folder con không
RECURSIVE_SCAN = True

# Giới hạn số dòng mỗi file
# None = không giới hạn
MAX_LINES_PER_FILE = None

# Danh sách extension cần gom
# Chỉ cần thêm/xóa extension tại đây
ALLOWED_EXTENSIONS = {
    ".php",
    ".js",
    ".ts",
    ".jsx",
    ".tsx",
    ".java",
    ".kt",
    ".dart",
    ".py",
    ".cs",
    ".cpp",
    ".c",
    ".h",
    ".hpp",
    ".html",
    ".css",
    ".scss",
    ".json",
    ".xml",
    ".sql",
    ".yml",
    ".yaml",
    ".md",
    ".example",
    ".template",
    ".env"
}

# Folder bỏ qua
EXCLUDE_DIRS = {
    ".git",
    ".idea",
    ".vscode",
    "node_modules",
    "vendor",
    "build",
    "dist",
    "out",
    "target",
    "__pycache__",
    ".dart_tool",
    ".gradle",
    ".next",
    ".nuxt",
    "coverage",
    "tmp",
    "temp",
    "logs",
    "storage",
    "uploads",
}

# Có ghi số dòng không
WRITE_LINE_NUMBER = True

# Có ghi path đầy đủ không
WRITE_FULL_PATH = True


# =========================================================
# HÀM HỖ TRỢ
# =========================================================

def should_exclude(path: Path) -> bool:
    """
    Kiểm tra path có nằm trong folder cần exclude không
    """
    return any(part in EXCLUDE_DIRS for part in path.parts)


def read_text_safely(file_path: Path) -> list[str]:
    """
    Đọc file với nhiều encoding
    """
    encodings = [
        "utf-8",
        "utf-8-sig",
        "cp1258",
        "latin-1",
    ]

    for enc in encodings:
        try:
            with file_path.open(
                "r",
                encoding=enc,
                errors="strict"
            ) as f:
                return f.readlines()

        except UnicodeDecodeError:
            continue

        except Exception as e:
            return [f"[ERROR] {e}\n"]

    # fallback
    try:
        with file_path.open(
            "r",
            encoding="utf-8",
            errors="replace"
        ) as f:
            return f.readlines()

    except Exception as e:
        return [f"[ERROR] {e}\n"]


# =========================================================
# QUÉT FILE
# =========================================================

def scan_files() -> list[Path]:
    """
    Quét toàn bộ file code
    """
    files = []

    if RECURSIVE_SCAN:
        iterator = ROOT_DIR.rglob("*")
    else:
        iterator = ROOT_DIR.glob("*")

    for path in iterator:

        if not path.is_file():
            continue

        if should_exclude(path):
            continue

        if path.suffix.lower() not in ALLOWED_EXTENSIONS:
            continue

        files.append(path)

    return sorted(files)


# =========================================================
# GHI OUTPUT
# =========================================================

def write_bundle(files: list[Path]):

    total_lines_written = 0

    with OUTPUT_FILE.open(
        "w",
        encoding="utf-8"
    ) as out:

        # HEADER
        out.write("=" * 120 + "\n")
        out.write("CODE BUNDLE\n")
        out.write(
            f"Generated: "
            f"{datetime.now().isoformat(timespec='seconds')}\n"
        )
        out.write(f"Root dir: {ROOT_DIR}\n")
        out.write(f"Total files: {len(files)}\n")
        out.write("=" * 120 + "\n\n")

        # FILE CONTENT
        for index, file_path in enumerate(files, start=1):

            relative_path = file_path.relative_to(ROOT_DIR)

            out.write("\n")
            out.write("=" * 120 + "\n")
            out.write(f"[{index}/{len(files)}]\n")
            out.write(f"FILE: {relative_path}\n")

            if WRITE_FULL_PATH:
                out.write(f"FULL_PATH: {file_path}\n")

            out.write("=" * 120 + "\n\n")

            lines = read_text_safely(file_path)

            original_line_count = len(lines)

            # giới hạn dòng nếu cần
            if MAX_LINES_PER_FILE is not None:
                lines = lines[:MAX_LINES_PER_FILE]

            # ghi content
            for line_number, line in enumerate(lines, start=1):

                if WRITE_LINE_NUMBER:
                    out.write(f"{line_number:05d}: {line}")
                else:
                    out.write(line)

            # truncated
            if (
                MAX_LINES_PER_FILE is not None
                and original_line_count > MAX_LINES_PER_FILE
            ):
                out.write("\n")
                out.write("-" * 120 + "\n")
                out.write(
                    f"[TRUNCATED] "
                    f"Original lines: {original_line_count}, "
                    f"Included: {MAX_LINES_PER_FILE}\n"
                )
                out.write("-" * 120 + "\n")

            out.write("\n\n")

            total_lines_written += len(lines)

        # SUMMARY
        out.write("\n")
        out.write("=" * 120 + "\n")
        out.write("SUMMARY\n")
        out.write(f"Files processed: {len(files)}\n")
        out.write(f"Total lines written: {total_lines_written}\n")
        out.write("=" * 120 + "\n")


# =========================================================
# MAIN
# =========================================================

def main():

    if not ROOT_DIR.exists():
        raise FileNotFoundError(
            f"ROOT_DIR does not exist: {ROOT_DIR}"
        )

    files = scan_files()

    if not files:
        print("No matching files found.")
        return

    write_bundle(files)

    print("=" * 80)
    print("DONE")
    print(f"Output : {OUTPUT_FILE.resolve()}")
    print(f"Files  : {len(files)}")
    print("=" * 80)


if __name__ == "__main__":
    main()