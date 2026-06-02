from pathlib import Path
from datetime import datetime

# =========================================================
# CONFIG
# =========================================================

ROOT_DIR = Path(
    r"D:\Data\App\ONEVNU\git\iworkspace_mobile_onevnu-master"
)

OUTPUT_FILE = Path("CODE_BUNDLE.txt")

RECURSIVE_SCAN = True
MAX_LINES_PER_FILE = None

WRITE_LINE_NUMBER = True
WRITE_FULL_PATH = True

# =========================================================
# MODE
# =========================================================

# True = chỉ lấy file cố định
FIXED_FILE_MODE = True

# =========================================================
# FILE EXTENSIONS
# =========================================================

ALLOWED_EXTENSIONS = {
    ".java",
    ".kt",
    ".ts",
    ".html",
    ".json",
    ".yml",
    ".yaml",
    ".properties",
    ".sql",
}

# =========================================================
# FIXED FILE NAMES
# =========================================================

# tên file exact match
FIXED_FILE_NAMES = {
    "pom.xml",
    "build.gradle",
    "settings.gradle",

    "package.json",
    "angular.json",
    "tsconfig.json",

    "application.yml",
    "application.yaml",
    "application.properties",

    "app.module.ts",
    "app-routing.module.ts",
    "app.routes.ts",
    "app.config.ts",
    "dormitory_registration_cubit.dart",
"dormitory_registration_state.dart",
"nt_register_cubit.dart",
"nt_register_state.dart",

"dormitory_registration_repository.dart",
"dormitory_registration_api.dart",

"registration_payload_model.dart",
"my_registration_model.dart",
"uploaded_attachment_model.dart",
"registration_period_model.dart",
"dormitory_model.dart",
"room_type_model.dart",
"priority_object_model.dart",
"registration_history_model.dart",

"dr_wizard_flow.dart",
"dr_step1_period_screen.dart",
"dr_step2_dormitory_screen.dart",
"dr_step3_info_screen.dart",
"dr_step4_review_screen.dart",
"dr_my_registration_screen.dart",
"dr_history_bottom_sheet.dart",
"nt_register_process_screen.dart",

"nt_register_image_widget.dart",
"nt_register_cmnd_widget.dart",
"nt_file_da_upload_widget.dart",
"nt_register_price_widget.dart",
"nt_register_payment_info.dart",
"nt_register_infrastructure_widget.dart",
"nt_custom_dropdown.dart",
"nt_dropbox_widget.dart",
"nt_container_dropbox_widget.dart",
"nt_noitru_item_widget.dart",

"nt_boading_register_view.dart",
"nt_boarding_register_controller.dart",
"nt_boarding_controller.dart",

"vnu_noi_tru.dart"
}

# =========================================================
# FILE PATTERNS (logic architecture)
# =========================================================

# suffix/pattern match
FIXED_FILE_PATTERNS = [
   "dormitory_registration_cubit.dart",
"dormitory_registration_state.dart",
"nt_register_cubit.dart",
"nt_register_state.dart",

"dormitory_registration_repository.dart",
"dormitory_registration_api.dart",

"registration_payload_model.dart",
"my_registration_model.dart",
"uploaded_attachment_model.dart",
"registration_period_model.dart",
"dormitory_model.dart",
"room_type_model.dart",
"priority_object_model.dart",
"registration_history_model.dart",

"dr_wizard_flow.dart",
"dr_step1_period_screen.dart",
"dr_step2_dormitory_screen.dart",
"dr_step3_info_screen.dart",
"dr_step4_review_screen.dart",
"dr_my_registration_screen.dart",
"dr_history_bottom_sheet.dart",
"nt_register_process_screen.dart",

"nt_register_image_widget.dart",
"nt_register_cmnd_widget.dart",
"nt_file_da_upload_widget.dart",
"nt_register_price_widget.dart",
"nt_register_payment_info.dart",
"nt_register_infrastructure_widget.dart",
"nt_custom_dropdown.dart",
"nt_dropbox_widget.dart",
"nt_container_dropbox_widget.dart",
"nt_noitru_item_widget.dart",

"nt_boading_register_view.dart",
"nt_boarding_register_controller.dart",
"nt_boarding_controller.dart",

"vnu_noi_tru.dart"
]

# =========================================================
# EXCLUDE DIRS
# =========================================================

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

# =========================================================
# HELPERS
# =========================================================

def should_exclude(path: Path) -> bool:
    return any(part in EXCLUDE_DIRS for part in path.parts)


def is_allowed_fixed_file(path: Path) -> bool:
    """
    chỉ lấy file logic quan trọng
    """

    filename = path.name
    filename_lower = filename.lower()

    # exact file name
    if filename in FIXED_FILE_NAMES:
        return True

    # extension check
    if path.suffix.lower() not in ALLOWED_EXTENSIONS:
        return False

    # pattern match
    for pattern in FIXED_FILE_PATTERNS:
        if filename_lower.endswith(pattern.lower()):
            return True

    return False


def read_text_safely(file_path: Path):

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
# SCAN FILES
# =========================================================

def scan_files():

    files = []

    iterator = (
        ROOT_DIR.rglob("*")
        if RECURSIVE_SCAN
        else ROOT_DIR.glob("*")
    )

    for path in iterator:

        if not path.is_file():
            continue

        if should_exclude(path):
            continue

        if FIXED_FILE_MODE:
            if not is_allowed_fixed_file(path):
                continue
        else:
            if path.suffix.lower() not in ALLOWED_EXTENSIONS:
                continue

        files.append(path)

    return sorted(files)


# =========================================================
# WRITE OUTPUT
# =========================================================

def write_bundle(files):

    total_lines_written = 0

    with OUTPUT_FILE.open(
        "w",
        encoding="utf-8"
    ) as out:

        out.write("=" * 120 + "\n")
        out.write("CODE BUNDLE\n")
        out.write(
            f"Generated: "
            f"{datetime.now().isoformat(timespec='seconds')}\n"
        )
        out.write(f"Root dir: {ROOT_DIR}\n")
        out.write(f"Total files: {len(files)}\n")
        out.write("=" * 120 + "\n\n")

        for index, file_path in enumerate(files, start=1):

            relative_path = file_path.relative_to(ROOT_DIR)

            out.write("=" * 120 + "\n")
            out.write(f"[{index}/{len(files)}]\n")
            out.write(f"FILE: {relative_path}\n")

            if WRITE_FULL_PATH:
                out.write(f"FULL_PATH: {file_path}\n")

            out.write("=" * 120 + "\n\n")

            lines = read_text_safely(file_path)

            if MAX_LINES_PER_FILE:
                lines = lines[:MAX_LINES_PER_FILE]

            for line_number, line in enumerate(lines, start=1):

                if WRITE_LINE_NUMBER:
                    out.write(
                        f"{line_number:05d}: {line}"
                    )
                else:
                    out.write(line)

            out.write("\n\n")

            total_lines_written += len(lines)

        out.write("=" * 120 + "\n")
        out.write("SUMMARY\n")
        out.write(
            f"Files processed: {len(files)}\n"
        )
        out.write(
            f"Total lines written: "
            f"{total_lines_written}\n"
        )
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