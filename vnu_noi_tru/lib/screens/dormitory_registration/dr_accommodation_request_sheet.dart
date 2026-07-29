import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_text_styles.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_noi_tru/repository/dormitory_registration_repository.dart';

class DRAccommodationRequestSheet extends StatefulWidget {
  final Object registrationId;
  final int? dormitoryId;
  final int? currentRoomId;
  final String currentRoomNumber;
  final String currentRequestStatus;
  final String currentRequestStatusLabel;

  const DRAccommodationRequestSheet({
    super.key,
    required this.registrationId,
    this.dormitoryId,
    this.currentRoomId,
    this.currentRoomNumber = '',
    this.currentRequestStatus = '',
    this.currentRequestStatusLabel = '',
  });

  static Future<bool?> show(
    BuildContext context, {
    required Object registrationId,
    int? dormitoryId,
    int? currentRoomId,
    String currentRoomNumber = '',
    String currentRequestStatus = '',
    String currentRequestStatusLabel = '',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DRAccommodationRequestSheet(
          registrationId: registrationId,
          dormitoryId: dormitoryId,
          currentRoomId: currentRoomId,
          currentRoomNumber: currentRoomNumber,
          currentRequestStatus: currentRequestStatus,
          currentRequestStatusLabel:
              currentRequestStatusLabel,
        );
      },
    );
  }

  @override
  State<DRAccommodationRequestSheet> createState() =>
      _DRAccommodationRequestSheetState();
}

class _DRAccommodationRequestSheetState
    extends State<DRAccommodationRequestSheet> {
  final DormitoryRegistrationRepository _repository =
      DormitoryRegistrationRepository();

  final TextEditingController _noteController =
      TextEditingController();

  String _selectedType = 'change_room';
  int? _desiredRoomId;

  bool _loadingRooms = false;
  bool _submitting = false;

  List<_RoomOption> _rooms = <_RoomOption>[];

  String get _existingRequest {
    final String normalized =
        widget.currentRequestStatus.trim().toLowerCase();

    if (normalized == 'change_room' ||
        normalized == 'checkout') {
      return normalized;
    }

    return '';
  }

  @override
  void initState() {
    super.initState();

    if (_existingRequest.isEmpty) {
      _loadRooms();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _loadingRooms = true;
    });

    try {
      final List<Map<String, dynamic>> values =
          await _repository.getRooms(
        dormitoryId: widget.dormitoryId,
      );

      final List<_RoomOption> rooms = values
          .map(_RoomOption.fromJson)
          .where(
            (_RoomOption room) =>
                room.id != null &&
                room.id != widget.currentRoomId,
          )
          .toList()
        ..sort(
          (_RoomOption a, _RoomOption b) =>
              a.roomNumber.compareTo(b.roomNumber),
        );

      if (!mounted) return;

      setState(() {
        _rooms = rooms;
      });
    } catch (_) {
      // desired_room_id được API cho phép null.
      // Vì vậy lỗi tải phòng không chặn gửi yêu cầu.
    } finally {
      if (mounted) {
        setState(() {
          _loadingRooms = false;
        });
      }
    }
  }

  Future<void> _submit(String type) async {
    if (_submitting) return;

    setState(() {
      _submitting = true;
    });

    try {
      final Map<String, dynamic> response =
          await _repository.updateAccommodationRequestStatus(
        registrationId: widget.registrationId,
        type: type,
        desiredRoomId:
            type == 'change_room' ? _desiredRoomId : null,
        note: _noteController.text,
      );

      if (!mounted) return;

      final String message =
          response['message']?.toString().trim() ?? '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isNotEmpty
                ? message
                : type == 'none'
                    ? 'Đã hủy yêu cầu'
                    : 'Đã gửi yêu cầu đến Ban quản lý',
          ),
          backgroundColor: AppTheme.colorSuccess,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _readErrorMessage(error),
          ),
          backgroundColor: AppTheme.colorError,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  String _readErrorMessage(Object error) {
    final String value = error.toString();

    if (value.startsWith('Exception: ')) {
      return value.substring('Exception: '.length);
    }

    return 'Không gửi được yêu cầu. Vui lòng thử lại.';
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight =
        MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * 0.88,
        ),
        padding: EdgeInsets.fromLTRB(
          18,
          12,
          18,
          18 + keyboardHeight,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: _existingRequest.isNotEmpty
              ? _buildExistingRequest()
              : _buildCreateRequest(),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Column(
      children: <Widget>[
        Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFD8DCE2),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            const Icon(
              Icons.swap_horiz_rounded,
              color: Color(0xFF078B3E),
              size: 24,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: AppFontSizes.medium,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111318),
                ),
              ),
            ),
            IconButton(
              onPressed: _submitting
                  ? null
                  : () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExistingRequest() {
    final bool isChangeRoom =
        _existingRequest == 'change_room';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeader('Yêu cầu đang chờ xử lý'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFFD98A),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.hourglass_top_rounded,
                color: Color(0xFFB76E00),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.currentRequestStatusLabel.trim().isNotEmpty
                      ? widget.currentRequestStatusLabel
                      : isChangeRoom
                          ? 'Đang yêu cầu chuyển phòng'
                          : 'Đang yêu cầu trả phòng',
                  style: const TextStyle(
                    color: Color(0xFF6B4300),
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Bạn có thể hủy yêu cầu hiện tại trước khi gửi một yêu cầu khác.',
          style: TextStyle(
            color: Color(0xFF666B75),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _submitting
                ? null
                : () => _submit('none'),
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.cancel_outlined),
            label: const Text('Hủy yêu cầu hiện tại'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.colorError,
              side: BorderSide(
                color: AppTheme.colorError,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateRequest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeader('Đổi phòng hoặc trả phòng'),
        const SizedBox(height: 10),
        const Text(
          'Yêu cầu sẽ được gửi đến Ban quản lý ký túc xá để xem xét và xử lý.',
          style: TextStyle(
            color: Color(0xFF666B75),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildTypeButton(
                type: 'change_room',
                icon: Icons.swap_horiz_rounded,
                label: 'Chuyển phòng',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTypeButton(
                type: 'checkout',
                icon: Icons.logout_rounded,
                label: 'Trả phòng',
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          maxLength: 500,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Nội dung yêu cầu',
            hintText: _selectedType == 'change_room'
                ? 'Ví dụ: Lý do cần chuyển phòng, mong muốn của bạn...'
                : 'Ví dụ: Thời gian dự kiến rời ký túc xá...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _submitting
                ? null
                : () => _submit(_selectedType),
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              _selectedType == 'change_room'
                  ? 'Gửi yêu cầu chuyển phòng'
                  : 'Gửi yêu cầu trả phòng',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF078B3E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeButton({
    required String type,
    required IconData icon,
    required String label,
  }) {
    final bool selected = _selectedType == type;

    return InkWell(
      onTap: _submitting
          ? null
          : () {
              setState(() {
                _selectedType = type;
                if (type != 'change_room') {
                  _desiredRoomId = null;
                }
              });
            },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEAF8EF)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF078B3E)
                : const Color(0xFFDDE3EA),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: <Widget>[
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF078B3E)
                  : const Color(0xFF69707A),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF078B3E)
                    : const Color(0xFF41454C),
                fontWeight: selected
                    ? FontWeight.w800
                    : FontWeight.w600,
                fontSize: AppFontSizes.small,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomOption {
  final int? id;
  final String roomNumber;
  final int? capacity;
  final int? currentOccupancy;

  const _RoomOption({
    required this.id,
    required this.roomNumber,
    this.capacity,
    this.currentOccupancy,
  });

  factory _RoomOption.fromJson(
    Map<String, dynamic> json,
  ) {
    int? toInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    }

    return _RoomOption(
      id: toInt(json['id']),
      roomNumber:
          (json['room_number'] ?? json['roomNumber'])
                  ?.toString()
                  .trim() ??
              '',
      capacity: toInt(json['capacity']),
      currentOccupancy: toInt(
        json['current_occupancy'] ??
            json['currentOccupancy'],
      ),
    );
  }

  String get displayName {
    final String name =
        roomNumber.isEmpty ? 'Phòng #$id' : 'Phòng $roomNumber';

    if (capacity == null) {
      return name;
    }

    return '$name • ${currentOccupancy ?? 0}/$capacity người';
  }
}
