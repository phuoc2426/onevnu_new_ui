from pathlib import Path
from datetime import datetime

# =========================================================
# CONFIG
# =========================================================

ROOT_DIR = Path(
    r"D:\Data\App\ONEVNU\code3\code\iworkspace_mobile_onevnu-master"
)

# Tên file output đã đổi đúng theo chức năng đang trích code
OUTPUT_FILE = Path("CODE_BUNDLE_LOGIN_PASSWORD_SINHVIEN_SERVICE.txt")

RECURSIVE_SCAN = True
MAX_LINES_PER_FILE = None

WRITE_LINE_NUMBER = True
WRITE_FULL_PATH = True

# =========================================================
# MODE
# =========================================================

# True = chỉ lấy các file cố định / đúng chức năng cần trích
FIXED_FILE_MODE = True

# =========================================================
# FILE EXTENSIONS
# =========================================================

ALLOWED_EXTENSIONS = {
    ".dart",
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

# Exact match theo tên file.
# Nhóm này tập trung vào:
# - Login cũ
# - Login v3
# - Quên mật khẩu
# - Đổi mật khẩu trong app
# - API repository / endpoint
# - Backend SinhVienService và các service liên quan
FIXED_FILE_NAMES = {
    # =====================================================
    # LOGIN SCREENS
    # =====================================================

    # Login cũ:
    # vcore_login_screen.dart line 239:
    # "Quên mật khẩu" đang bị comment, không dẫn đi đâu, không gọi service.
    "vcore_login_screen.dart",

    # Login v3:
    # vcore_login_screen_v3.dart line 625:
    # chỉ là Text('Quên mật khẩu?'), không có onTap, chưa gọi service.
    "vcore_login_screen_v3.dart",

    # =====================================================
    # PROFILE PASSWORD - MOBILE FRONTEND
    # =====================================================

    # Màn hình đổi mật khẩu trong app:
    # Vào app > Quản lý mật khẩu > Đổi mật khẩu
    # vcore_profile_change_pass_view.dart line 124:
    # gọi controller.thayDoiMatKhau()
    "vcore_profile_change_pass_view.dart",

    # Controller đổi mật khẩu:
    # vcore_profile_pass_controller.dart line 88:
    # gọi ApiRepository().putCapNhatMatKhau(...)
    # cũng load danh sách loại mật khẩu bằng getDanhSachLoaiMatKhau()
    "vcore_profile_pass_controller.dart",

    # Quên mật khẩu bản cũ:
    # vcore_profile_forgot_pass_view.dart line 63:
    # gọi controller.quenMatKhau()
    # service ApiRepository().putQuenMatKhau(...)
    "vcore_profile_forgot_pass_view.dart",

    # Quên mật khẩu bản hiện tại:
    # VcoreProfileForgotPassViewV2 không gọi API quên mật khẩu;
    # mở cổng https://it.vnu.edu.vn/support hoặc compose email qua MethodChannel gmail_sender.
    "vcore_profile_forgot_pass_view_v2.dart",

    # Model loại mật khẩu:
    # dùng cho getDanhSachLoaiMatKhau()
    "loai_mat_khau_model.dart",

    # =====================================================
    # MOBILE API / REPOSITORY
    # =====================================================

    # Repository chứa các hàm gọi API:
    # putCapNhatMatKhau(...)
    # putQuenMatKhau(...)
    # getDanhSachLoaiMatKhau(...)
    "app_repository.dart",

    # API declaration:
    # app_api.dart line 445:
    # endpoint PUT /api/context/capNhatMatKhau
    # ngoài ra có:
    # GET /api/context/getDanhSachLoaiMatKhau
    # PUT /api/context/quenMatKhau
    "app_api.dart",

    # File generated retrofit/dio tương ứng
    "app_api.g.dart",

    # =====================================================
    # BACKEND CONTROLLER / DTO
    # =====================================================

    # Controller context thường chứa các endpoint:
    # /api/context/capNhatMatKhau
    # /api/context/getDanhSachLoaiMatKhau
    # /api/context/quenMatKhau
    "ContextController.java",

    # DTO request quên mật khẩu
    "QuenMatKhauRequestDTO.java",

    # =====================================================
    # BACKEND SINHVIEN SERVICE / LOGIN CŨ
    # =====================================================

    # Interface service sinh viên
    "SinhVienService.java",

    # Implement service sinh viên:
    # nơi thường xử lý nghiệp vụ sinh viên, login cũ,
    # đổi mật khẩu, quên mật khẩu, LDAP / đào tạo / email.
    "SinhVienServiceImpl.java",

    # Enum loại password
    "LoaiPasswordEnum.java",

    # Service đào tạo liên quan tài khoản sinh viên
    "DaoTaoServiceImpl.java",

    # LDAP service liên quan xác thực / đổi mật khẩu
    "LdapServiceImpl.java",

    # Email service dùng cho luồng quên mật khẩu
    "EmailServiceImpl.java",

    # Cấu hình gửi mail
    "JavaMailSenderConfig.java",

    # Constants có thể chứa key, message, loại tài khoản, cấu hình chung
    "Constants.java",
}

# =========================================================
# FILE PATTERNS
# =========================================================

# Pattern match bổ sung để tránh miss file do tên hơi khác giữa các branch/package.
# Script vẫn ưu tiên exact file name ở trên.
FIXED_FILE_PATTERNS = [
    # Login
    "login",
    "vcore_login",

    # Password / forgot password
    "password",
    "forgot",
    "forgot_pass",
    "forgot_password",
    "quenmatkhau",
    "quen_mat_khau",
    "matkhau",
    "mat_khau",
    "loai_mat_khau",

    # Sinh viên service / login cũ backend
    "sinhvienservice",
    "sinh_vien_service",
    "sinhvien",
    "sinh_vien",

    # Backend helpers
    "ldap",
    "daotao",
    "dao_tao",
    "emailservice",
    "java_mail_sender",
    "javamailsender",
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
    Chỉ lấy các file liên quan trực tiếp đến:
    - Login cũ / Login v3
    - Quên mật khẩu
    - Đổi mật khẩu
    - SinhVienService backend
    """

    filename = path.name
    filename_lower = filename.lower()

    # Exact file name: cho phép trước extension check
    if filename in FIXED_FILE_NAMES:
        return True

    # Extension check cho pattern mode
    if path.suffix.lower() not in ALLOWED_EXTENSIONS:
        return False

    # Pattern match
    for pattern in FIXED_FILE_PATTERNS:
        if pattern.lower() in filename_lower:
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
                errors="strict",
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
            errors="replace",
        ) as f:
            return f.readlines()

    except Exception as e:
        return [f"[ERROR] {e}\n"]


def build_file_note(relative_path: Path) -> str:
    """
    Ghi chú ngắn theo chức năng file để khi đọc bundle dễ định vị.
    """

    name = relative_path.name

    notes = {
        "vcore_login_screen.dart":
            "Login cũ - phần Quên mật khẩu đang bị comment / chưa gọi service.",
        "vcore_login_screen_v3.dart":
            "Login v3 - Text('Quên mật khẩu?') chưa có onTap / chưa gọi service.",
        "vcore_profile_change_pass_view.dart":
            "UI đổi mật khẩu trong app - gọi controller.thayDoiMatKhau().",
        "vcore_profile_pass_controller.dart":
            "Controller đổi mật khẩu / quên mật khẩu / load loại mật khẩu.",
        "vcore_profile_forgot_pass_view.dart":
            "Quên mật khẩu bản cũ - gọi controller.quenMatKhau().",
        "vcore_profile_forgot_pass_view_v2.dart":
            "Quên mật khẩu bản hiện tại - mở support/email, không gọi API quên mật khẩu.",
        "loai_mat_khau_model.dart":
            "Model loại mật khẩu cho getDanhSachLoaiMatKhau().",
        "app_repository.dart":
            "Repository mobile - chứa putCapNhatMatKhau / putQuenMatKhau / getDanhSachLoaiMatKhau.",
        "app_api.dart":
            "Khai báo endpoint mobile API.",
        "app_api.g.dart":
            "Generated API client tương ứng app_api.dart.",
        "ContextController.java":
            "Backend controller cho nhóm endpoint /api/context.",
        "QuenMatKhauRequestDTO.java":
            "DTO request quên mật khẩu.",
        "SinhVienService.java":
            "Interface service sinh viên / login cũ.",
        "SinhVienServiceImpl.java":
            "Implement service sinh viên / login cũ / password flow.",
        "LoaiPasswordEnum.java":
            "Enum loại mật khẩu.",
        "DaoTaoServiceImpl.java":
            "Service đào tạo liên quan tài khoản sinh viên.",
        "LdapServiceImpl.java":
            "LDAP service liên quan xác thực / mật khẩu.",
        "EmailServiceImpl.java":
            "Email service dùng trong luồng quên mật khẩu.",
        "JavaMailSenderConfig.java":
            "Cấu hình gửi email.",
        "Constants.java":
            "Hằng số dùng chung.",
    }

    return notes.get(name, "File liên quan theo pattern Login / Password / SinhVienService.")


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

    return sorted(files, key=lambda p: str(p.relative_to(ROOT_DIR)).lower())


# =========================================================
# WRITE OUTPUT
# =========================================================

def write_bundle(files):
    total_lines_written = 0

    with OUTPUT_FILE.open(
        "w",
        encoding="utf-8",
    ) as out:

        out.write("=" * 120 + "\n")
        out.write("CODE BUNDLE - LOGIN / PASSWORD / SINHVIEN SERVICE\n")
        out.write(f"Generated: {datetime.now().isoformat(timespec='seconds')}\n")
        out.write(f"Root dir: {ROOT_DIR}\n")
        out.write(f"Total files: {len(files)}\n")
        out.write("=" * 120 + "\n\n")

        out.write("FILE PURPOSE SUMMARY\n")
        out.write("- Login cũ: kiểm tra Quên mật khẩu bị comment / chưa gọi service.\n")
        out.write("- Login v3: kiểm tra Text('Quên mật khẩu?') chưa có onTap.\n")
        out.write("- Đổi mật khẩu trong app: kiểm tra thayDoiMatKhau / putCapNhatMatKhau.\n")
        out.write("- Quên mật khẩu bản cũ: kiểm tra quenMatKhau / putQuenMatKhau.\n")
        out.write("- Backend: kiểm tra ContextController, SinhVienService, LDAP, Đào tạo, Email.\n")
        out.write("=" * 120 + "\n\n")

        for index, file_path in enumerate(files, start=1):
            relative_path = file_path.relative_to(ROOT_DIR)
            note = build_file_note(relative_path)

            out.write("=" * 120 + "\n")
            out.write(f"[{index}/{len(files)}]\n")
            out.write(f"FILE: {relative_path}\n")
            out.write(f"PURPOSE: {note}\n")

            if WRITE_FULL_PATH:
                out.write(f"FULL_PATH: {file_path}\n")

            out.write("=" * 120 + "\n\n")

            lines = read_text_safely(file_path)

            if MAX_LINES_PER_FILE:
                lines = lines[:MAX_LINES_PER_FILE]

            for line_number, line in enumerate(lines, start=1):
                if WRITE_LINE_NUMBER:
                    out.write(f"{line_number:05d}: {line}")
                else:
                    out.write(line)

            out.write("\n\n")

            total_lines_written += len(lines)

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

    print("\nFILES EXTRACTED:")
    for index, file_path in enumerate(files, start=1):
        relative_path = file_path.relative_to(ROOT_DIR)
        print(f"{index:03d}. {relative_path}")


if __name__ == "__main__":
    main()
