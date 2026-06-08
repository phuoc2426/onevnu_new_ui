from pathlib import Path

ROOT = Path(
    r"D:\Data\App\ONEVNU\git\iworkspace_mobile_onevnu-master"
)

EXCLUDE = {
    ".git",
    ".dart_tool",
    "build",
    ".idea",
    ".vscode",
}

ICONS = {
    ".dart": "📄",
    ".json": "📋",
    ".yaml": "⚙️",
    ".yml": "⚙️",
}


def get_icon(path: Path):

    name = path.name.lower()

    if "controller" in name:
        return "🎮"

    if "view" in name:
        return "🖼️"

    if "widget" in name:
        return "🧩"

    if "model" in name:
        return "📦"

    if "repository" in name:
        return "🗄️"

    if "api" in name:
        return "🌐"

    return ICONS.get(path.suffix.lower(), "📄")


def build_tree(folder: Path, prefix=""):

    entries = [
        p for p in sorted(folder.iterdir(), key=lambda x: (x.is_file(), x.name.lower()))
        if p.name not in EXCLUDE
    ]

    result = []

    for i, entry in enumerate(entries):

        last = i == len(entries) - 1

        connector = "└── " if last else "├── "

        if entry.is_dir():

            result.append(
                f"{prefix}{connector}📁 {entry.name}"
            )

            extension = "    " if last else "│   "

            result.extend(
                build_tree(
                    entry,
                    prefix + extension,
                )
            )

        else:

            result.append(
                f"{prefix}{connector}{get_icon(entry)} {entry.name}"
            )

    return result


lines = [f"📁 {ROOT.name}"]
lines.extend(build_tree(ROOT))

output = "\n".join(lines)

with open(
    "project_structure.txt",
    "w",
    encoding="utf-8"
) as f:
    f.write(output)

print(output)
print()
print("Saved -> project_structure.txt")