from pathlib import Path
from datetime import datetime

# =========================================================
# CONFIG
# =========================================================

ROOT_DIR = Path(
    r"D:\Data\App\ONEVNU\git\iworkspace_mobile_onevnu-master"
)

OUTPUT_FILE = Path("CODE_BUNDLE_AVATAR_PROFILE_PASSWORD.txt")

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
    # "vcore_news_view_v2.dart",
    # "vcore_news_view_v3.dart",
    # "vcore_news_detail_view.dart",
    # "vcore_news_item_widget.dart",
    # "vcore_news_tab_widget_v2.dart",
    # "vcore_news_category_widget_v2.dart",
    # "vcore_news_filter_widget.dart",
    # "vcore_news_view.dart",
    # "vcore_jobs_view_v2.dart",

    # # =====================================================
    # # Controllers
    # # =====================================================
    # "vcore_news_controller.dart",
    # "vcore_news_detail_controller.dart",
    # "vcore_jobs_controller_v2.dart",
    # # =====================================================
    # # Main files
    # # =====================================================
    # "grade_scale_helper.dart",

    # "vcore_exam_schedule_controller.dart",
    # "vcore_exam_schedule_view.dart",

    # "vcore_course_points_controller.dart",
    # "vcore_course_points_view.dart",

    # # =====================================================
    # # Related widgets
    # # =====================================================
    # "vcore_dropdown_select_widget.dart",
    # "vcore_course_points_detail_widget.dart",

    # # =====================================================
    # # Data / repository
    # # =====================================================
    # "gpa_cache_manager.dart",
    # "app_repository.dart",
    # "app_api.dart",
    # "app_api.g.dart",

    # # =====================================================
    # # Schedule models
    # # =====================================================
    # "hoc_ky_model.dart",
    # "thoi_khoa_bieu_model.dart",
    # "lich_thi_hoc_ky_model.dart",
    # "vcore_schedule_event.dart",

    # # =====================================================
    # # Grade models
    # # =====================================================
    # "diem_thi_hoc_ky_model.dart",
    # "diem_hoc_phan_model.dart",
    # "diem_trung_binh_model.dart",
    # "tong_ket_den_hien_tai_model.dart",
    # "model.dart",

    # # =====================================================
    # # AI Radar
    # # =====================================================
    # "academic_course.dart",
    # "ai_radar_analysis.dart",
    # "radar_axis_profile.dart",
    # "local_ai_radar_engine.dart",
    # "semantic_axis_discovery_engine.dart",
    # "semantic_scoring_engine.dart",
    # "vector_math.dart",
    # "ai_axis_cache.dart",
    # "onnx_embedding_model.dart",
    # "local_embedding_model.dart",
    # "simple_tokenizer.dart",

    # # =====================================================
    # # Entry points
    # # =====================================================
    # "vcore_home_view_v3.dart",
    # "vcore_home_service_widget.dart",
    # "vcore_home_service_widget_v2.dart",
    # "vcore_sidebar_widget.dart",


    # =====================================================
# Avatar / Profile Photos
# =====================================================

"vcore_profile_view.dart",
"vcore_profile_avatar_widget.dart",

"vcore_profile_photos_view.dart",
"vcore_profile_photos_controller.dart",

"current_user_model.dart",
"globals.dart",

"vcore_sidebar_widget.dart",
"vcore_home_view.dart",

"app_repository.dart",
"app_api.dart",
"app_api.g.dart",

# =====================================================
# Password
# =====================================================

"vcore_profile_forgot_pass_view.dart",
"vcore_profile_pass_controller.dart",
"vcore_profile_change_pass_view.dart",

"loai_mat_khau_model.dart",

"vcore_login_screen_v3.dart",

"app_repository.dart",
"app_api.dart",
"app_api.g.dart",

# =====================================================
# PROFILE / AVATAR / COVER (BACKEND)
# =====================================================

"NguoiDung.java",

"NguoiDungRequestDTO.java",
"NguoiDungResponseDTO.java",

"ContextController.java",
"NguoiDungController.java",

"Constants.java",

# Mobile API
"ContextController.java",
"NguoiDungResponseDTO.java",

# =====================================================
# FORGOT PASSWORD (BACKEND)
# =====================================================

"QuenMatKhauRequestDTO.java",

"SinhVienService.java",
"SinhVienServiceImpl.java",

"LoaiPasswordEnum.java",

"DaoTaoServiceImpl.java",
"LdapServiceImpl.java",

"EmailServiceImpl.java",
"JavaMailSenderConfig.java",

}

# =========================================================
# FILE PATTERNS (logic architecture)
# =========================================================

# suffix/pattern match
FIXED_FILE_PATTERNS = [
#     "grade_scale_helper.dart",

#     "vcore_exam_schedule_controller.dart",
#     "vcore_exam_schedule_view.dart",

#     "vcore_course_points_controller.dart",
#     "vcore_course_points_view.dart",

#     "vcore_dropdown_select_widget.dart",
#     "vcore_course_points_detail_widget.dart",

#     "gpa_cache_manager.dart",
#     "app_repository.dart",
#     "app_api.dart",
#     "app_api.g.dart",

#     "hoc_ky_model.dart",
#     "thoi_khoa_bieu_model.dart",
#     "lich_thi_hoc_ky_model.dart",
#     "vcore_schedule_event.dart",

#     "diem_thi_hoc_ky_model.dart",
#     "diem_hoc_phan_model.dart",
#     "diem_trung_binh_model.dart",
#     "tong_ket_den_hien_tai_model.dart",
#     "model.dart",

#     "academic_course.dart",
#     "ai_radar_analysis.dart",
#     "radar_axis_profile.dart",
#     "local_ai_radar_engine.dart",
#     "semantic_axis_discovery_engine.dart",
#     "semantic_scoring_engine.dart",
#     "vector_math.dart",
#     "ai_axis_cache.dart",
#     "onnx_embedding_model.dart",
#     "local_embedding_model.dart",
#     "simple_tokenizer.dart",

#     "vcore_home_view_v3.dart",
#     "vcore_home_service_widget.dart",
#     "vcore_home_service_widget_v2.dart",
#     "vcore_sidebar_widget.dart",
#     "schedule", "exam_schedule", "course_points", "gpa", "radar", "embedding",
#   "vcore_news_view_v2.dart",
#     "vcore_news_view_v3.dart",
#     "vcore_news_detail_view.dart",
#     "vcore_news_item_widget.dart",
#     "vcore_news_tab_widget_v2.dart",
#     "vcore_news_category_widget_v2.dart",
#     "vcore_news_filter_widget.dart",
#     "vcore_news_view.dart",
#      # =====================================================
#     # Jobs
#     # =====================================================
#     "vcore_jobs_view_v2.dart",

#     # =====================================================
#     # Controllers
#     # =====================================================
#     "vcore_news_controller.dart",
#     "vcore_news_detail_controller.dart",
#     "vcore_jobs_controller_v2.dart",

#     # =====================================================
#     # Generic patterns
#     # =====================================================
#     "news",
#     "job",
#     "jobs",

# =====================================================
# Avatar / Profile Photos
# =====================================================

"vcore_profile_view.dart",
"vcore_profile_avatar_widget.dart",

"vcore_profile_photos_view.dart",
"vcore_profile_photos_controller.dart",

"current_user_model.dart",
"globals.dart",

"vcore_sidebar_widget.dart",
"vcore_home_view.dart",

"app_repository.dart",
"app_api.dart",
"app_api.g.dart",

# =====================================================
# Password
# =====================================================

"vcore_profile_forgot_pass_view.dart",
"vcore_profile_pass_controller.dart",
"vcore_profile_change_pass_view.dart",

"loai_mat_khau_model.dart",

"vcore_login_screen_v3.dart",

"app_repository.dart",
"app_api.dart",
"app_api.g.dart",

# =====================================================
# Avatar / Cover
# =====================================================

"nguoidung",
"anhdaidien",
"anh_dai_dien",
"avatar",
"cover",
"anhnen",
"anh_nen",

"NguoiDung.java",
"NguoiDungRequestDTO.java",
"NguoiDungResponseDTO.java",

"ContextController.java",
"NguoiDungController.java",

# =====================================================
# Password
# =====================================================

"quenmatkhau",
"quen_mat_khau",
"forgot",
"forgot_password",

"password",
"matkhau",
"mat_khau",

"QuenMatKhauRequestDTO.java",

"SinhVienService.java",
"SinhVienServiceImpl.java",

"LoaiPasswordEnum.java",

"DaoTaoServiceImpl.java",
"LdapServiceImpl.java",

"EmailServiceImpl.java",
"JavaMailSenderConfig.java",

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