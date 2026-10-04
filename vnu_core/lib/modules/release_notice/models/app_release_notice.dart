class AppReleaseNotice {
  const AppReleaseNotice({
    required this.id,
    required this.code,
    required this.revision,
    required this.title,
    required this.summary,
    required this.placement,
    required this.changeTitle,
    required this.changeContent,
    required this.reasonTitle,
    required this.reasonContent,
    required this.impactTitle,
    required this.impactContent,
    required this.actionTitle,
    required this.actionContent,
    required this.acknowledgementText,
    required this.primaryActionLabel,
    required this.requiredAck,
    required this.requireScrollEnd,
    required this.priority,
  });

  final int id;
  final String code;
  final int revision;
  final String title;
  final String summary;
  final String placement;
  final String changeTitle;
  final String changeContent;
  final String reasonTitle;
  final String reasonContent;
  final String impactTitle;
  final String impactContent;
  final String actionTitle;
  final String actionContent;
  final String acknowledgementText;
  final String primaryActionLabel;
  final bool requiredAck;
  final bool requireScrollEnd;
  final int priority;

  factory AppReleaseNotice.fromJson(Map<String, dynamic> json) {
    return AppReleaseNotice(
      id: _asInt(json['id']),
      code: _asString(json['code']),
      revision: _asInt(json['revision'], fallback: 1),
      title: _asString(json['title']),
      summary: _asString(json['summary']),
      placement: _asString(json['placement'], fallback: 'PRE_LOGIN'),
      changeTitle: _asString(
        json['changeTitle'],
        fallback: 'Chúng tôi đã thay đổi gì?',
      ),
      changeContent: _asString(json['changeContent']),
      reasonTitle: _asString(
        json['reasonTitle'],
        fallback: 'Vì sao thay đổi?',
      ),
      reasonContent: _asString(json['reasonContent']),
      impactTitle: _asString(
        json['impactTitle'],
        fallback: 'Ảnh hưởng tới người dùng',
      ),
      impactContent: _asString(json['impactContent']),
      actionTitle: _asString(
        json['actionTitle'],
        fallback: 'Bạn cần làm gì?',
      ),
      actionContent: _asString(json['actionContent']),
      acknowledgementText: _asString(
        json['acknowledgementText'],
        fallback: 'Tôi đã đọc và hiểu nội dung thông báo.',
      ),
      primaryActionLabel: _asString(
        json['primaryActionLabel'],
        fallback: 'Tôi đã đọc và hiểu',
      ),
      requiredAck: json['requiredAck'] == true,
      requireScrollEnd: json['requireScrollEnd'] == true,
      priority: _asInt(json['priority']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'code': code,
        'revision': revision,
        'title': title,
        'summary': summary,
        'placement': placement,
        'changeTitle': changeTitle,
        'changeContent': changeContent,
        'reasonTitle': reasonTitle,
        'reasonContent': reasonContent,
        'impactTitle': impactTitle,
        'impactContent': impactContent,
        'actionTitle': actionTitle,
        'actionContent': actionContent,
        'acknowledgementText': acknowledgementText,
        'primaryActionLabel': primaryActionLabel,
        'requiredAck': requiredAck,
        'requireScrollEnd': requireScrollEnd,
        'priority': priority,
      };

  static AppReleaseNotice idpCompatibilityFallback() {
    return const AppReleaseNotice(
      id: 0,
      code: 'LOGIN_SSO_CHANGE_202609',
      revision: 1,
      title: 'Thay đổi phương thức đăng nhập OneVNU',
      summary:
          'OneVNU bổ sung VNU SSO và vẫn giữ Tài khoản VNU làm phương án đăng nhập thay thế khi thiết bị không hoàn tất được luồng SSO.',
      placement: 'PRE_LOGIN',
      changeTitle: 'Chúng tôi đã thay đổi gì?',
      changeContent:
          'OneVNU bổ sung phương thức đăng nhập VNU SSO. Khi đăng nhập bằng VNU SSO, phiên xác thực có thể được sử dụng thuận tiện hơn với các dịch vụ và trang web của VNU có hỗ trợ SSO trên trình duyệt tương thích.',
      reasonTitle: 'Vì sao thay đổi?',
      reasonContent:
          'Mục tiêu là thống nhất phương thức xác thực trong hệ sinh thái VNU và giảm việc người dùng phải đăng nhập lại nhiều lần trên các dịch vụ hỗ trợ SSO.',
      impactTitle: 'Một số thiết bị có thể gặp vấn đề gì?',
      impactContent:
          'Một số thiết bị, phiên bản Android, ROM tùy biến, trình duyệt, Custom Tabs, VPN, Private DNS hoặc chính sách bảo mật có thể không hỗ trợ đầy đủ quá trình trao đổi dữ liệu giữa cửa sổ VNU SSO và OneVNU. Khi đó trang VNU SSO vẫn có thể truy cập bình thường nhưng OneVNU không nhận được đầy đủ kết quả xác thực để hoàn tất phiên đăng nhập.',
      actionTitle: 'Bạn cần làm gì?',
      actionContent:
          'Nếu VNU SSO không hoàn tất trên thiết bị, hãy chọn Tài khoản VNU. Đây vẫn là phương thức đăng nhập bằng tài khoản/email VNU hoặc mã sinh viên và mật khẩu đang sử dụng bình thường. OneVNU sẽ tự động chuyển sang phương thức này khi phiên SSO không hoàn tất.',
      acknowledgementText:
          'Tôi đã đọc và hiểu nội dung thay đổi, bao gồm khả năng một số thiết bị hoặc trình duyệt không hoàn tất được VNU SSO và phương án đăng nhập bằng Tài khoản VNU.',
      primaryActionLabel: 'Chấp nhận & tiếp tục',
      requiredAck: true,
      requireScrollEnd: true,
      priority: 100,
    );
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    final String text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
