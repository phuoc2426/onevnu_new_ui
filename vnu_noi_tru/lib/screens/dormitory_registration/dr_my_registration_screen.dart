import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_core/widgets/progress_hub_widget.dart';
import 'package:vnu_core/common/utils.dart';
import 'package:vnu_noi_tru/cubit/dormitory_registration_cubit.dart';
import 'package:intl/intl.dart';
import 'dr_wizard_flow.dart';
import 'package:vnu_core/common/app_text_styles.dart';

class DRMyRegistrationScreen extends StatefulWidget {
  const DRMyRegistrationScreen({super.key});

  @override
  State<DRMyRegistrationScreen> createState() => _DRMyRegistrationScreenState();
}

class _DRMyRegistrationScreenState extends State<DRMyRegistrationScreen> {
  /// Nếu true, ẩn nút đăng ký mới khi sinh viên đang có hồ sơ còn hiệu lực.
  static const bool kHideRegisterNewIfHasActiveRegistration = true;

  final _cubit = DormitoryRegistrationCubit();

  late BuildContext _hubContext;

  bool _showFAB = false;

  List<dynamic> _currentHistories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String get _studentCode {
    return Globals().thongTinSinhVienModel.value?.maSinhVien ?? '';
  }

  Future<void> _loadData() async {
    await _cubit.getRegistrationPeriods();
    await _cubit.getDormitories();
    await _cubit.getRoomTypes();
    await _cubit.getPriorityObjects();

    await _cubit.getMyRegistrations(studentCode: _studentCode);
  }

  Future<void> _refreshData() {
    return _cubit.getMyRegistrations(studentCode: _studentCode);
  }

  // =========================================================
  // Helpers đọc dữ liệu dynamic
  // Hỗ trợ cả trường hợp repository trả Map hoặc model object.
  // =========================================================

  dynamic _readDataFromState(dynamic state) {
    try {
      return state.data;
    } catch (_) {
      return null;
    }
  }

  dynamic _readStudent(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      return data['student'];
    }

    try {
      return data.student;
    } catch (_) {
      return null;
    }
  }

  List<dynamic> _readAccommodations(dynamic data) {
    if (data == null) return [];

    if (data is Map) {
      return List<dynamic>.from(data['accommodations'] ?? []);
    }

    try {
      return List<dynamic>.from(data.accommodations ?? []);
    } catch (_) {
      return [];
    }
  }

  List<dynamic> _readHistories(dynamic data) {
    if (data == null) return [];

    if (data is Map) {
      return List<dynamic>.from(data['histories'] ?? []);
    }

    try {
      return List<dynamic>.from(data.histories ?? []);
    } catch (_) {
      return [];
    }
  }

  dynamic _readMapValue(dynamic obj, String key) {
    if (obj == null) return null;

    if (obj is Map) {
      return obj[key];
    }

    return null;
  }

  String _readString(dynamic obj, String mapKey, String Function(dynamic o) getter) {
    if (obj == null) return '';

    if (obj is Map) {
      final value = obj[mapKey];
      return value?.toString() ?? '';
    }

    try {
      final value = getter(obj);
      return value.toString();
    } catch (_) {
      return '';
    }
  }

  int? _readInt(dynamic obj, String mapKey, int? Function(dynamic o) getter) {
    if (obj == null) return null;

    if (obj is Map) {
      final value = obj[mapKey];
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    }

    try {
      return getter(obj);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  DateTime? _readDate(dynamic obj, String mapKey, dynamic Function(dynamic o) getter) {
    if (obj == null) return null;

    if (obj is Map) {
      return _parseDate(obj[mapKey]);
    }

    try {
      return _parseDate(getter(obj));
    } catch (_) {
      return null;
    }
  }

  dynamic _readNested(dynamic obj, String mapKey, dynamic Function(dynamic o) getter) {
    if (obj == null) return null;

    if (obj is Map) {
      return obj[mapKey];
    }

    try {
      return getter(obj);
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // Student helpers
  // =========================================================

  String _studentFullName(dynamic student) {
    final fromApi = _readString(student, 'full_name', (o) => o.fullName);
    if (fromApi.isNotEmpty) return fromApi;

    return Globals().thongTinSinhVienModel.value?.hoVaTen ?? '';
  }

  String _studentCodeText(dynamic student) {
    final fromApi = _readString(student, 'student_code', (o) => o.studentCode);
    if (fromApi.isNotEmpty) return fromApi;

    return Globals().thongTinSinhVienModel.value?.maSinhVien ?? '';
  }

  String _studentClass(dynamic student) {
    return _readString(student, 'class', (o) => o.className);
  }

  String _studentMajor(dynamic student) {
    return _readString(student, 'major', (o) => o.major);
  }

  String _studentPhone(dynamic student) {
    return _readString(student, 'phone', (o) => o.phone);
  }

  String _studentEmail(dynamic student) {
    return _readString(student, 'email', (o) => o.email);
  }

  String _studentUniversity(dynamic student) {
    return _readString(student, 'university_name', (o) => o.universityName);
  }

  // =========================================================
  // Accommodation helpers
  // =========================================================

  int? _accommodationId(dynamic item) {
    return _readInt(item, 'id', (o) => o.id);
  }

  String _accommodationStatus(dynamic item) {
    return _readString(item, 'status', (o) => o.status).toLowerCase();
  }

  String _accommodationNote(dynamic item) {
    return _readString(item, 'note', (o) => o.note);
  }

  DateTime? _accommodationCreatedAt(dynamic item) {
    return _readDate(item, 'created_at', (o) => o.createdAt);
  }

  DateTime? _accommodationApprovedAt(dynamic item) {
    return _readDate(item, 'approved_at', (o) => o.approvedAt);
  }

  DateTime? _accommodationAssignedAt(dynamic item) {
    return _readDate(item, 'assigned_at', (o) => o.assignedAt);
  }

  DateTime? _accommodationStartDate(dynamic item) {
    return _readDate(item, 'start_date', (o) => o.startDate);
  }

  DateTime? _accommodationEndDate(dynamic item) {
    return _readDate(item, 'end_date', (o) => o.endDate);
  }

  dynamic _registrationPeriod(dynamic item) {
    return _readNested(item, 'registration_period', (o) => o.registrationPeriod);
  }

  dynamic _dormitory(dynamic item) {
    return _readNested(item, 'dormitory', (o) => o.dormitory);
  }

  dynamic _roomType(dynamic item) {
    return _readNested(item, 'room_type', (o) => o.roomType);
  }

  dynamic _room(dynamic item) {
    return _readNested(item, 'room', (o) => o.room);
  }

  String _periodName(dynamic item) {
    final period = _registrationPeriod(item);
    final name = _readString(period, 'name', (o) => o.name);

    if (name.isNotEmpty) return name;

    final periodId = _readInt(item, 'registration_period_id', (o) => o.registrationPeriodId);
    return periodId != null ? 'Đợt đăng ký #$periodId' : 'Đợt đăng ký';
  }

  String _dormitoryName(dynamic item) {
    final dormitory = _dormitory(item);
    final name = _readString(dormitory, 'name', (o) => o.name);

    return name.isNotEmpty ? name : 'Chưa có thông tin';
  }

  String _dormitoryAddress(dynamic item) {
    final dormitory = _dormitory(item);
    return _readString(dormitory, 'address', (o) => o.address);
  }

  String _roomTypeName(dynamic item) {
    final roomType = _roomType(item);
    final name = _readString(roomType, 'name', (o) => o.name);

    return name.isNotEmpty ? name : 'Chưa có thông tin';
  }

  String _roomTypePrice(dynamic item) {
    final roomType = _roomType(item);
    return _readString(roomType, 'price', (o) => o.price);
  }

  String _roomNumber(dynamic item) {
    final room = _room(item);
    return _readString(room, 'room_number', (o) => o.roomNumber);
  }

  String _roomCapacity(dynamic item) {
    final room = _room(item);
    final capacity = _readInt(room, 'capacity', (o) => o.capacity);
    return capacity?.toString() ?? '';
  }

  String _roomCurrentOccupancy(dynamic item) {
    final room = _room(item);
    final current = _readInt(room, 'current_occupancy', (o) => o.currentOccupancy);
    return current?.toString() ?? '';
  }

  // =========================================================
  // Status / Action mapping
  // =========================================================

  bool _hasBlockingRegistration(List<dynamic> list) {
    return list.any((item) {
      final status = _accommodationStatus(item);

      return status == 'draft' ||
          status == 'pending' ||
          status == 'approved' ||
          status == 'assigned' ||
          status == 'active';
    });
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return Colors.orange;
      case 'pending':
        return AppTheme.colorWarning;
      case 'approved':
        return Colors.blue;
      case 'assigned':
      case 'active':
        return AppTheme.colorSuccess;
      case 'rejected':
      case 'terminated':
        return AppTheme.colorError;
      case 'checkout':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return Icons.edit_note;
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'approved':
        return Icons.verified_rounded;
      case 'assigned':
        return Icons.meeting_room_rounded;
      case 'active':
        return Icons.home_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'checkout':
        return Icons.logout_rounded;
      case 'terminated':
        return Icons.block_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return 'Bản nháp';
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'assigned':
        return 'Đã xếp phòng';
      case 'active':
        return 'Đang ở';
      case 'rejected':
        return 'Từ chối';
      case 'checkout':
        return 'Đã trả phòng';
      case 'terminated':
        return 'Chấm dứt';
      default:
        return 'Không xác định';
    }
  }

  String _getActionText(String? action) {
    switch (action?.toLowerCase()) {
      case 'draft_saved':
        return 'Lưu nháp';
      case 'submitted':
        return 'Nộp đơn';
      case 'updated':
        return 'Cập nhật hồ sơ';
      case 'approved':
        return 'Đã duyệt';
      case 'assigned':
        return 'Đã xếp phòng';
      case 'rejected':
        return 'Từ chối';
      case 'checked_in':
        return 'Nhận phòng';
      case 'checked_out':
        return 'Trả phòng';
      case 'terminated':
        return 'Chấm dứt';
      default:
        return action ?? 'Không xác định';
    }
  }

  Color _getActionColor(String? action) {
    switch (action?.toLowerCase()) {
      case 'approved':
      case 'assigned':
      case 'checked_in':
        return AppTheme.colorSuccess;
      case 'rejected':
      case 'terminated':
        return AppTheme.colorError;
      case 'updated':
        return Colors.blue;
      case 'submitted':
        return AppTheme.colorWarning;
      case 'draft_saved':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return VcoreModuleScaffold(
      title: 'Ký túc xá của tôi',
      floatingActionButton: _showFAB
          ? FloatingActionButton.extended(
        onPressed: _goToRegisterFlow,
        label: const Text(
          'Đăng ký mới',
          style: TextStyle(
            color: Colors.white,
            fontSize: AppFontSizes.mediumSmall,
            fontWeight: FontWeight.bold,
          ),
        ),
        icon: const Icon(
          Icons.app_registration,
          color: Colors.white,
          size: 18,
        ),
        backgroundColor: const Color(0xFF078B3E),
      )
          : null,
      body: ProgressHubWidget(
        contextComplete: (ctx) {
          _hubContext = ctx;
        },
        child: BlocListener<DormitoryRegistrationCubit, DormitoryRegistrationState>(
          bloc: _cubit,
          listener: (context, state) {
            if (state is DormitoryRegistrationShowHub) {
              Utils.showProgress(_hubContext);
            }

            if (state is DormitoryRegistrationDismissHub) {
              Utils.dismissProgress(_hubContext);
            }

            if (state is DormitoryRegistrationSavedSuccess) {
              snackBarSuccess(state.message);
              _refreshData();
            }

            if (state is DormitoryRegistrationError) {
              snackBarError(state.message);
            }

            final data = _readDataFromState(state);
            if (data != null) {
              final accommodations = _readAccommodations(data);

              _currentHistories = _readHistories(data);

              setState(() {
                _showFAB = accommodations.isEmpty ||
                    !_hasBlockingRegistration(accommodations);
              });
            }
          },
          child: BlocBuilder<DormitoryRegistrationCubit, DormitoryRegistrationState>(
            bloc: _cubit,
            builder: (context, state) {
              if (state is DormitoryRegistrationLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.colorMain),
                );
              }

              final data = _readDataFromState(state);

              if (data == null) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.colorMain),
                );
              }

              final student = _readStudent(data);
              final accommodations = _readAccommodations(data);
              final histories = _readHistories(data);

              _currentHistories = histories;

              accommodations.sort((a, b) {
                final timeA = _accommodationCreatedAt(a) ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                final timeB = _accommodationCreatedAt(b) ??
                    DateTime.fromMillisecondsSinceEpoch(0);

                final compTime = timeB.compareTo(timeA);
                if (compTime != 0) return compTime;

                return (_accommodationId(b) ?? 0).compareTo(_accommodationId(a) ?? 0);
              });

              if (accommodations.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                      const Center(
                        child: Text(
                          'Chưa có thông tin đăng ký ký túc xá',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: AppFontSizes.mediumSmall,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refreshData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildStudentCard(student),
                    const SizedBox(height: 16),
                    ...accommodations.map(
                          (item) => _buildAccommodationCard(item, student),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(dynamic student) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.person_rounded,
                  color: Color(0xFF078B3E),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Thông tin sinh viên',
                  style: TextStyle(
                    fontSize: AppFontSizes.mediumSmall,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111318),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildInfoRow('Họ và tên:', _studentFullName(student)),
            _buildInfoRow('Mã SV:', _studentCodeText(student)),
            if (_studentClass(student).isNotEmpty)
              _buildInfoRow('Lớp:', _studentClass(student)),
            if (_studentMajor(student).isNotEmpty)
              _buildInfoRow('Ngành:', _studentMajor(student)),
            if (_studentPhone(student).isNotEmpty)
              _buildInfoRow('SĐT:', _studentPhone(student)),
            if (_studentEmail(student).isNotEmpty)
              _buildInfoRow('Email:', _studentEmail(student)),
            if (_studentUniversity(student).isNotEmpty)
              _buildInfoRow('Trường:', _studentUniversity(student)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccommodationCard(dynamic item, dynamic student) {
    final status = _accommodationStatus(item);
    final periodName = _periodName(item);
    final dormitoryName = _dormitoryName(item);
    final dormitoryAddress = _dormitoryAddress(item);
    final roomTypeName = _roomTypeName(item);
    final roomTypePrice = _roomTypePrice(item);
    final roomNumber = _roomNumber(item);
    final roomCapacity = _roomCapacity(item);
    final roomCurrentOccupancy = _roomCurrentOccupancy(item);

    final createdAt = _accommodationCreatedAt(item);
    final approvedAt = _accommodationApprovedAt(item);
    final assignedAt = _accommodationAssignedAt(item);
    final startDate = _accommodationStartDate(item);
    final endDate = _accommodationEndDate(item);
    final note = _accommodationNote(item);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () => _showHistory(_accommodationId(item)),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 20,
                    color: _getStatusColor(status),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      periodName,
                      style: const TextStyle(
                        fontSize: AppFontSizes.mediumSmall,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111318),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(status),
                ],
              ),

              const Divider(height: 20),

              _buildInfoRow('Khu nội trú:', dormitoryName),

              if (dormitoryAddress.isNotEmpty)
                _buildInfoRow('Địa chỉ:', dormitoryAddress),

              _buildInfoRow('Loại phòng:', roomTypeName),

              if (roomTypePrice.isNotEmpty)
                _buildInfoRow(
                  'Giá phòng:',
                  '${_formatPrice(roomTypePrice)} đ',
                ),

              if (roomNumber.isNotEmpty)
                _buildInfoRow('Phòng:', roomNumber),

              if (roomCapacity.isNotEmpty)
                _buildInfoRow(
                  'Sức chứa:',
                  roomCurrentOccupancy.isNotEmpty
                      ? '$roomCurrentOccupancy/$roomCapacity người'
                      : '$roomCapacity người',
                ),

              if (startDate != null)
                _buildInfoRow(
                  'Ngày bắt đầu:',
                  DateFormat('dd/MM/yyyy').format(startDate),
                ),

              if (endDate != null)
                _buildInfoRow(
                  'Ngày kết thúc:',
                  DateFormat('dd/MM/yyyy').format(endDate),
                ),

              if (createdAt != null)
                _buildInfoRow(
                  'Ngày đăng ký:',
                  DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                ),

              if (approvedAt != null)
                _buildInfoRow(
                  'Ngày duyệt:',
                  DateFormat('dd/MM/yyyy HH:mm').format(approvedAt),
                ),

              if (assignedAt != null)
                _buildInfoRow(
                  'Ngày xếp phòng:',
                  DateFormat('dd/MM/yyyy HH:mm').format(assignedAt),
                ),

              if (note.isNotEmpty)
                _buildInfoRow('Ghi chú:', note),

              const SizedBox(height: 12),

              _buildActionArea(item),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'Xem lịch sử xử lý',
                    style: TextStyle(
                      fontSize: AppFontSizes.font11,
                      color: Color(0xFF078B3E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: Color(0xFF078B3E),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionArea(dynamic item) {
    final status = _accommodationStatus(item);

    if (status == 'draft') {
      return Row(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              final id = _accommodationId(item);
              if (id != null) {
                _cubit.submitDraft(id);
              }
            },
            icon: const Icon(
              Icons.send,
              size: 12,
              color: Colors.white,
            ),
            label: const Text(
              'Gửi',
              style: TextStyle(
                color: Colors.white,
                fontSize: AppFontSizes.font11,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF078B3E),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _goToEditDraftFlow(),
            icon: const Icon(
              Icons.edit,
              size: 12,
              color: Color(0xFF078B3E),
            ),
            label: const Text(
              'Sửa',
              style: TextStyle(
                color: Color(0xFF078B3E),
                fontSize: AppFontSizes.font11,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF078B3E)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      );
    }

    if (status == 'rejected') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.colorError.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Hồ sơ đã bị từ chối. Bạn có thể đăng ký lại nếu đợt đăng ký còn mở.',
          style: TextStyle(
            fontSize: AppFontSizes.font11,
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (status == 'approved') {
      return _buildNoticeBox(
        icon: Icons.verified_rounded,
        color: Colors.blue,
        text: 'Hồ sơ đã được duyệt. Vui lòng chờ ban quản lý xếp phòng.',
      );
    }

    if (status == 'assigned') {
      return _buildNoticeBox(
        icon: Icons.meeting_room_rounded,
        color: AppTheme.colorSuccess,
        text: 'Bạn đã được xếp phòng. Vui lòng theo dõi lịch nhận phòng.',
      );
    }

    if (status == 'pending') {
      return _buildNoticeBox(
        icon: Icons.hourglass_top_rounded,
        color: AppTheme.colorWarning,
        text: 'Hồ sơ đang chờ ban quản lý xét duyệt.',
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildNoticeBox({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppFontSizes.font11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: AppFontSizes.extraSmall,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppFontSizes.font11,
                color: Color(0xFF666B75),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppFontSizes.font11,
                color: Color(0xFF111318),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(String value) {
    final raw = value.replaceAll(',', '');
    final number = double.tryParse(raw);

    if (number == null) return value;

    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(number);
  }

  // =========================================================
  // History bottom sheet
  // =========================================================

  void _showHistory(int? accommodationId) {
    if (accommodationId == null) return;

    final histories = _currentHistories.where((item) {
      final id = _readInt(item, 'accommodation_id', (o) => o.accommodationId);
      return id == accommodationId;
    }).toList();

    histories.sort((a, b) {
      final timeA = _readDate(a, 'created_at', (o) => o.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final timeB = _readDate(b, 'created_at', (o) => o.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return timeB.compareTo(timeA);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.65,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Lịch sử xử lý hồ sơ',
                  style: TextStyle(
                    fontSize: AppFontSizes.mediumSmall,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111318),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                Expanded(
                  child: histories.isEmpty
                      ? const Center(
                    child: Text(
                      'Chưa có lịch sử xử lý',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: AppFontSizes.mediumSmall,
                      ),
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: histories.length,
                    itemBuilder: (context, index) {
                      return _buildHistoryItem(histories[index], index);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryItem(dynamic item, int index) {
    final action = _readString(item, 'action', (o) => o.action);
    final note = _readString(item, 'note', (o) => o.note);
    final createdAt = _readDate(item, 'created_at', (o) => o.createdAt);

    final performer = _readNested(item, 'performer', (o) => o.performer);
    final performerName = _readString(performer, 'name', (o) => o.name);

    final color = _getActionColor(action);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.circle,
                size: 10,
                color: color,
              ),
            ),
            Container(
              width: 1,
              height: 58,
              color: Colors.grey.shade300,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getActionText(action),
                  style: TextStyle(
                    fontSize: AppFontSizes.font11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: const TextStyle(
                      fontSize: AppFontSizes.font11,
                      color: Color(0xFF111318),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (performerName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Người xử lý: $performerName',
                    style: const TextStyle(
                      fontSize: AppFontSizes.font11,
                      color: Color(0xFF666B75),
                    ),
                  ),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                    style: const TextStyle(
                      fontSize: AppFontSizes.font11,
                      color: Color(0xFF666B75),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // Navigation
  // =========================================================

  void _goToRegisterFlow() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DRWizardFlow(),
      ),
    );

    if (result is String && result.isNotEmpty) {
      _refreshData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF078B3E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(result)),
            ],
          ),
        ),
      );
      return;
    }

    if (result == true) {
      _refreshData();
    }
  }

  void _goToEditDraftFlow() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DRWizardFlow(),
      ),
    );

    if (result is String && result.isNotEmpty) {
      _refreshData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF078B3E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(result)),
            ],
          ),
        ),
      );
      return;
    }

    if (result == true) {
      _refreshData();
    }
  }
}
