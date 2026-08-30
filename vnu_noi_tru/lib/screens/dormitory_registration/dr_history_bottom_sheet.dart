import 'package:flutter/material.dart';
import 'package:vnu_core/common/error/app_error_mapper.dart';
import 'package:intl/intl.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/empty_data_widget.dart';
import 'package:vnu_core/widgets/loading_indicator.dart';
import 'package:vnu_noi_tru/models/dormitory_registration/registration_history_model.dart';
import 'package:vnu_noi_tru/repository/dormitory_history_lookup_repository.dart';

class DRHistoryBottomSheet extends StatefulWidget {
  final Object registrationId;

  const DRHistoryBottomSheet({
    super.key,
    required this.registrationId,
  });

  @override
  State<DRHistoryBottomSheet> createState() =>
      _DRHistoryBottomSheetState();
}

class _DRHistoryBottomSheetState extends State<DRHistoryBottomSheet> {
  final DormitoryHistoryLookupRepository _repository =
      DormitoryHistoryLookupRepository();

  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  late Future<DormitoryHistoryResolvedData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<DormitoryHistoryResolvedData> _loadData() {
    return _repository.loadResolvedHistory(widget.registrationId);
  }

  Future<void> _refresh() async {
    final Future<DormitoryHistoryResolvedData> next = _loadData();
    setState(() {
      _future = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.94,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6F7F9),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
          ),
          child: FutureBuilder<DormitoryHistoryResolvedData>(
            future: _future,
            builder: (
              BuildContext context,
              AsyncSnapshot<DormitoryHistoryResolvedData> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShell(
                  child: const Center(child: LoadingIndicator()),
                );
              }

              if (snapshot.hasError) {
                return _buildShell(
                  child: _buildErrorState(
                    AppErrorMapper.map(snapshot.error!).userMessage,
                  ),
                );
              }

              final DormitoryHistoryResolvedData? data = snapshot.data;
              if (data == null) {
                return _buildShell(
                  child: _buildErrorState('Không nhận được dữ liệu lịch sử'),
                );
              }

              final List<RegistrationHistoryModel> histories =
                  List<RegistrationHistoryModel>.from(data.histories)
                    ..sort(
                      (
                        RegistrationHistoryModel first,
                        RegistrationHistoryModel second,
                      ) {
                        final DateTime firstTime = first.createdAt ??
                            DateTime.fromMillisecondsSinceEpoch(0);
                        final DateTime secondTime = second.createdAt ??
                            DateTime.fromMillisecondsSinceEpoch(0);
                        return secondTime.compareTo(firstTime);
                      },
                    );

              return _buildShell(
                count: histories.length,
                child: histories.isEmpty
                    ? const Center(child: EmptyDataWidget())
                    : RefreshIndicator(
                        color: AppTheme.colorMain,
                        onRefresh: _refresh,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                          itemCount: histories.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (BuildContext context, int index) {
                            return _buildHistoryCard(
                              histories[index],
                              data,
                              isLatest: index == 0,
                            );
                          },
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildShell({
    required Widget child,
    int? count,
  }) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 10),
        Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFD5D8DD),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 8, 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7F6EC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Color(0xFF078B3E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Lịch sử xử lý hồ sơ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17191D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      count == null
                          ? 'Đang tải lịch sử và dữ liệu danh mục'
                          : '$count sự kiện được ghi nhận',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF71757D),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Đóng',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.red,
            size: 54,
          ),
          const SizedBox(height: 14),
          const Text(
            'Không tải được lịch sử xử lý',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message.replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7078)),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    RegistrationHistoryModel history,
    DormitoryHistoryResolvedData lookup, {
    required bool isLatest,
  }) {
    final Color color = _actionColor(history.action);
    final RegistrationHistoryAccommodationModel? accommodation =
        history.accommodation;

    final int? dormitoryId = _firstInt(<dynamic>[
      history.data['dormitory_id'],
      history.data['dormitoryId'],
      accommodation?.dormitoryId,
      lookup.registrationDetail['dormitory_id'],
      lookup.registrationDetail['dormitoryId'],
    ]);

    final int? periodId = _firstInt(<dynamic>[
      history.data['period_id'],
      history.data['registration_period_id'],
      history.data['registrationPeriodId'],
      accommodation?.registrationPeriodId,
      lookup.registrationDetail['registration_period_id'],
      lookup.registrationDetail['registrationPeriodId'],
    ]);

    final int? roomTypeId = _firstInt(<dynamic>[
      history.data['room_type_id'],
      history.data['roomTypeId'],
      accommodation?.roomTypeId,
      lookup.registrationDetail['room_type_id'],
      lookup.registrationDetail['roomTypeId'],
    ]);

    final int? roomId = _firstInt(<dynamic>[
      history.data['room_id'],
      history.data['roomId'],
      accommodation?.roomId,
      lookup.registrationDetail['room_id'],
      lookup.registrationDetail['roomId'],
    ]);

    final int? priorityObjectId = _firstInt(<dynamic>[
      history.data['priority_object_id'],
      history.data['priorityObjectId'],
      accommodation?.priorityObjectId,
      lookup.registrationDetail['priority_object_id'],
      lookup.registrationDetail['priorityObjectId'],
    ]);

    final String dormitoryName = _firstText(<dynamic>[
      history.data['dormitory'],
      history.data['dormitory_name'],
      history.data['dormitoryName'],
      history.data['dormitory_label'],
      history.data['dormitoryLabel'],
      lookup.registrationDetail['dormitory_name'],
      lookup.registrationDetail['dormitoryName'],
      lookup.dormitoryNameFor(dormitoryId),
    ]);
    final String periodName = _firstText(<dynamic>[
      history.data['registration_period_name'],
      history.data['registrationPeriodName'],
      history.data['period_name'],
      history.data['periodName'],
      lookup.registrationDetail['registration_period_name'],
      lookup.registrationDetail['registrationPeriodName'],
      lookup.periodNameFor(periodId),
    ]);
    final String roomTypeName = _firstText(<dynamic>[
      history.data['room_type_name'],
      history.data['roomTypeName'],
      lookup.registrationDetail['room_type_name'],
      lookup.registrationDetail['roomTypeName'],
      lookup.roomTypeNameFor(roomTypeId),
    ]);
    final String roomDescription = _firstText(<dynamic>[
      history.data['assigned_room'],
      history.data['assignedRoom'],
      history.data['room_number'],
      history.data['roomNumber'],
      lookup.registrationDetail['assigned_room'],
      lookup.registrationDetail['assignedRoom'],
      lookup.roomDescriptionFor(roomId),
    ]);
    final String priorityName = _firstText(<dynamic>[
      history.data['priority_object'],
      history.data['priorityObject'],
      history.data['priority_object_name'],
      history.data['priorityObjectName'],
      lookup.registrationDetail['priority_object'],
      lookup.registrationDetail['priorityObject'],
      lookup.priorityObjectNameFor(priorityObjectId),
    ]);

    final dynamic status = history.data['status'] ?? accommodation?.status;
    final String statusLabel = _firstText(<dynamic>[
      history.data['status_label'],
      history.data['statusLabel'],
      lookup.statusLabelFor(status),
    ]);
    final RegistrationHistoryPerformerModel? performer = history.performer;
    final String performerName = lookup.performerNameFor(history);
    final String performerDetail = <String>[
      if (_hasText(performer?.role)) performer!.role!.trim(),
      if (_hasText(performer?.position)) performer!.position!.trim(),
      if (_hasText(performer?.unitName)) performer!.unitName!.trim(),
    ].join(' · ');

    final List<_HistoryField> summary = <_HistoryField>[
      _HistoryField(
        'Sinh viên',
        lookup.studentNameFor(history.studentId),
        Icons.person_outline_rounded,
      ),
      if (_hasText(performerName) &&
          performerName != 'API chưa trả thông tin người thực hiện')
        _HistoryField(
          'Người thực hiện',
          performerName,
          Icons.badge_outlined,
          subtitle: performerDetail.isEmpty ? null : performerDetail,
        ),
      if (_hasText(performer?.email))
        _HistoryField(
          'Email người thực hiện',
          performer!.email!.trim(),
          Icons.alternate_email_rounded,
        ),
      if (dormitoryName.isNotEmpty)
        _HistoryField(
          'Ký túc xá',
          dormitoryName,
          Icons.apartment_rounded,
          subtitle: lookup.dormitoryAddressFor(dormitoryId),
        ),
      if (periodName.isNotEmpty)
        _HistoryField(
          'Đợt đăng ký',
          periodName,
          Icons.event_note_rounded,
        ),
      if (priorityName.isNotEmpty)
        _HistoryField(
          'Đối tượng ưu tiên',
          priorityName,
          Icons.workspace_premium_outlined,
        ),
      if (roomTypeName.isNotEmpty)
        _HistoryField(
          'Loại phòng',
          roomTypeName,
          Icons.bed_outlined,
        ),
      if (roomDescription.isNotEmpty)
        _HistoryField(
          'Phòng được xếp',
          roomDescription,
          Icons.meeting_room_outlined,
        ),
      if (statusLabel.isNotEmpty)
        _HistoryField(
          'Trạng thái hồ sơ',
          statusLabel,
          Icons.fact_check_outlined,
        ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      elevation: isLatest ? 3 : 1,
      shadowColor: Colors.black.withOpacity(0.06),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLatest
              ? color.withOpacity(0.28)
              : const Color(0xFFE5E7EA),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.13),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_actionIcon(history.action), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                _actionLabel(history.action),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF17191D),
                                ),
                              ),
                            ),
                            if (isLatest)
                              _buildBadge('Mới nhất', color),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _typeLabel(history.type),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6F747C),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.schedule_rounded,
                              size: 15,
                              color: Color(0xFF71757D),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _formatDateTime(history.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5F646C),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Column(
                children: summary
                    .map((_HistoryField field) => _buildField(field))
                    .toList(),
              ),
            ),
            if (history.data.isNotEmpty || history.accommodation != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ..._buildResolvedDataFields(history, lookup),
                    ..._buildSnapshotFields(history, lookup),
                  ],
                ),
              ),
            if (_hasText(history.note))
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(14, 2, 14, 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Ghi chú xử lý',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF66551E),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      history.note!.trim(),
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF3D351A),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResolvedDataFields(
    RegistrationHistoryModel history,
    DormitoryHistoryResolvedData lookup,
  ) {
    if (history.data.isEmpty) return <Widget>[];

    final List<Widget> result = <Widget>[
      _buildSectionTitle('Dữ liệu thay đổi'),
    ];

    final List<String> keys = history.data.keys.toList()..sort();
    for (final String key in keys) {
      final dynamic value = history.data[key];
      if (value == null) continue;

      final _ResolvedValue resolved = _resolveApiValue(
        key,
        value,
        history,
        lookup,
      );

      if (resolved.value.trim().isEmpty) continue;

      result.add(
        _buildDetailRow(
          resolved.label,
          resolved.value,
          subtitle: resolved.subtitle,
        ),
      );
    }

    return result;
  }

  List<Widget> _buildSnapshotFields(
    RegistrationHistoryModel history,
    DormitoryHistoryResolvedData lookup,
  ) {
    final RegistrationHistoryAccommodationModel? item = history.accommodation;
    if (item == null) return <Widget>[];

    final List<Widget> result = <Widget>[
      const SizedBox(height: 8),
      _buildSectionTitle('Hồ sơ tại thời điểm xử lý'),
    ];

    void add(String label, String value, {String? subtitle}) {
      if (value.trim().isEmpty) return;
      result.add(_buildDetailRow(label, value, subtitle: subtitle));
    }

    add(
      'Sinh viên',
      lookup.studentNameFor(item.studentId),
    );
    add(
      'Ký túc xá',
      _firstText(<dynamic>[
        history.data['dormitory'],
        history.data['dormitory_name'],
        history.data['dormitoryName'],
        lookup.registrationDetail['dormitory_name'],
        lookup.registrationDetail['dormitoryName'],
        lookup.dormitoryNameFor(item.dormitoryId),
      ]),
      subtitle: lookup.dormitoryAddressFor(item.dormitoryId),
    );
    add(
      'Đợt đăng ký',
      _firstText(<dynamic>[
        history.data['registration_period_name'],
        history.data['registrationPeriodName'],
        history.data['period_name'],
        history.data['periodName'],
        lookup.registrationDetail['registration_period_name'],
        lookup.registrationDetail['registrationPeriodName'],
        lookup.periodNameFor(item.registrationPeriodId),
      ]),
    );
    add(
      'Đối tượng ưu tiên',
      _firstText(<dynamic>[
        history.data['priority_object'],
        history.data['priorityObject'],
        history.data['priority_object_name'],
        history.data['priorityObjectName'],
        lookup.priorityObjectNameFor(item.priorityObjectId),
      ]),
    );
    add(
      'Loại phòng',
      _firstText(<dynamic>[
        history.data['room_type_name'],
        history.data['roomTypeName'],
        lookup.roomTypeNameFor(item.roomTypeId),
      ]),
    );
    add(
      'Phòng',
      _firstText(<dynamic>[
        history.data['assigned_room'],
        history.data['assignedRoom'],
        history.data['room_number'],
        history.data['roomNumber'],
        lookup.roomDescriptionFor(item.roomId),
      ]),
    );
    add(
      'Trạng thái hồ sơ',
      _firstText(<dynamic>[
        history.data['status_label'],
        history.data['statusLabel'],
        lookup.statusLabelFor(item.status),
      ]),
    );

    if (item.asmStatus != null &&
        !_isNumericText(item.asmStatus.toString())) {
      add('Trạng thái xếp chỗ', _humanizeValue(item.asmStatus.toString()));
    }
    if (item.requestStatus != null) {
      add(
        'Trạng thái yêu cầu',
        lookup.requestStatusLabelFor(item.requestStatus),
      );
    }
    if (item.startDate != null) {
      add('Ngày bắt đầu', _dateFormat.format(item.startDate!.toLocal()));
    }
    if (item.endDate != null) {
      add('Ngày kết thúc', _dateFormat.format(item.endDate!.toLocal()));
    }
    if (item.approvedAt != null) {
      add('Ngày duyệt', _formatDateTime(item.approvedAt));
    }
    if (item.approvedBy != null) {
      add(
        'Người duyệt',
        lookup.approvedByNameFor(history, item.approvedBy),
      );
    }
    if (item.assignedAt != null) {
      add('Ngày xếp phòng', _formatDateTime(item.assignedAt));
    }
    if (item.checkinAt != null) {
      add('Ngày nhận phòng', _formatDateTime(item.checkinAt));
    }
    if (item.checkoutAt != null) {
      add('Ngày trả phòng', _formatDateTime(item.checkoutAt));
    }
    if (_hasText(item.reasonStay)) {
      add('Lý do lưu trú', item.reasonStay!.trim());
    }
    if (_hasText(item.note)) {
      add('Ghi chú hồ sơ', item.note!.trim());
    }
    if (item.isRoomLeader != null) {
      add('Trưởng phòng', item.isRoomLeader! ? 'Có' : 'Không');
    }
    if (item.createdAt != null) {
      add('Ngày tạo hồ sơ', _formatDateTime(item.createdAt));
    }
    if (item.updatedAt != null) {
      add('Cập nhật gần nhất', _formatDateTime(item.updatedAt));
    }

    return result;
  }

  _ResolvedValue _resolveApiValue(
    String key,
    dynamic value,
    RegistrationHistoryModel history,
    DormitoryHistoryResolvedData lookup,
  ) {
    final String normalized = key.toLowerCase();
    final int? id = _toInt(value);

    switch (normalized) {
      case 'dormitory_id':
      case 'dormitoryid':
        return _resolvedId(
          'Ký túc xá',
          lookup.dormitoryNameFor(id),
          id,
          subtitle: lookup.dormitoryAddressFor(id),
        );
      case 'period_id':
      case 'registration_period_id':
      case 'registrationperiodid':
        return _resolvedId('Đợt đăng ký', lookup.periodNameFor(id), id);
      case 'building_id':
      case 'buildingid':
        return _resolvedId(
          'Tòa nhà',
          lookup.buildingNameFor(id),
          id,
        );
      case 'room_type_id':
      case 'roomtypeid':
        return _resolvedId('Loại phòng', lookup.roomTypeNameFor(id), id);
      case 'room_id':
      case 'roomid':
        return _resolvedId('Phòng', lookup.roomDescriptionFor(id), id);
      case 'priority_object_id':
      case 'priorityobjectid':
        return _resolvedId(
          'Đối tượng ưu tiên',
          lookup.priorityObjectNameFor(id),
          id,
        );
      case 'student_id':
      case 'studentid':
        return _resolvedId('Sinh viên', lookup.studentNameFor(id), id);
      case 'accommodation_id':
      case 'accommodationid':
        return const _ResolvedValue('Hồ sơ nội trú', 'Hồ sơ lưu trú liên quan');
      case 'performed_by':
      case 'performedby':
        return _ResolvedValue(
          'Người thực hiện',
          lookup.performerNameFor(history),
        );
      case 'approved_by':
      case 'approvedby':
        return _ResolvedValue(
          'Người duyệt',
          lookup.approvedByNameFor(history, id),
        );
      case 'status':
        return _ResolvedValue('Trạng thái hồ sơ', lookup.statusLabelFor(value));
      case 'status_label':
      case 'statuslabel':
        return _ResolvedValue('Trạng thái hồ sơ', value.toString());
      case 'asm_status':
      case 'asmstatus':
        final String asmText = value.toString().trim();
        return _ResolvedValue(
          'Trạng thái xếp chỗ',
          _isNumericText(asmText) ? '' : _humanizeValue(asmText),
        );
      case 'request_status':
      case 'requeststatus':
        return _ResolvedValue(
          'Trạng thái yêu cầu',
          lookup.requestStatusLabelFor(value),
        );
      case 'is_room_leader':
      case 'isroomleader':
        return _ResolvedValue('Trưởng phòng', _boolText(value));
      case 'start_date':
      case 'startdate':
        return _ResolvedValue('Ngày bắt đầu', _formatDynamicDate(value));
      case 'end_date':
      case 'enddate':
        return _ResolvedValue('Ngày kết thúc', _formatDynamicDate(value));
      case 'approved_at':
      case 'approvedat':
        return _ResolvedValue('Ngày duyệt', _formatDynamicDateTime(value));
      case 'assigned_at':
      case 'assignedat':
        return _ResolvedValue('Ngày xếp phòng', _formatDynamicDateTime(value));
      case 'checkin_at':
      case 'checkinat':
        return _ResolvedValue('Ngày nhận phòng', _formatDynamicDateTime(value));
      case 'checkout_at':
      case 'checkoutat':
        return _ResolvedValue('Ngày trả phòng', _formatDynamicDateTime(value));
      case 'note':
        return _ResolvedValue('Ghi chú', value.toString());
      case 'reason_stay':
      case 'reasonstay':
        return _ResolvedValue('Lý do lưu trú', value.toString());
      default:
        if (_isTechnicalIdentifierKey(normalized)) {
          return const _ResolvedValue('', '');
        }
        return _ResolvedValue(
          _fieldLabel(key),
          _displayDynamicValue(value),
        );
    }
  }

  _ResolvedValue _resolvedId(
    String label,
    String resolvedName,
    int? id, {
    String? subtitle,
  }) {
    final String displayName = resolvedName.trim().isEmpty
        ? '$label chưa cập nhật thông tin'
        : resolvedName.trim();

    return _ResolvedValue(
      label,
      displayName,
      subtitle: _hasText(subtitle) ? subtitle!.trim() : null,
    );
  }

  Widget _buildField(_HistoryField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F4F2),
              shape: BoxShape.circle,
            ),
            child: Icon(field.icon, size: 17, color: const Color(0xFF527062)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  field.label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF747981)),
                ),
                const SizedBox(height: 2),
                Text(
                  field.value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202328),
                  ),
                ),
                if (_hasText(field.subtitle)) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    field.subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF777C84),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F2),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF34453B),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6F747C)),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF22252A),
                  ),
                ),
                if (_hasText(subtitle)) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF858A92)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  String _actionLabel(String? action) {
    switch (action?.trim().toLowerCase()) {
      case 'submitted':
        return 'Đã nộp hồ sơ đăng ký';
      case 'approved':
        return 'Hồ sơ đã được duyệt';
      case 'rejected':
        return 'Hồ sơ bị từ chối';
      case 'assigned':
      case 'room_assigned':
        return 'Đã xếp phòng';
      case 'checkin':
      case 'checked_in':
        return 'Đã nhận phòng';
      case 'checkout':
      case 'checked_out':
        return 'Đã trả phòng';
      case 'updated':
        return 'Đã cập nhật hồ sơ';
      case 'cancelled':
      case 'canceled':
        return 'Hồ sơ đã bị hủy';
      default:
        final String raw = action?.trim() ?? '';
        return raw.isEmpty ? 'Cập nhật hồ sơ' : raw;
    }
  }

  String _typeLabel(String? type) {
    switch (type?.trim().toLowerCase()) {
      case 'registration':
        return 'Đăng ký nội trú';
      case 'approval':
        return 'Xét duyệt hồ sơ';
      case 'assignment':
        return 'Xếp phòng';
      case 'payment':
        return 'Thanh toán';
      case 'checkin':
        return 'Nhận phòng';
      case 'checkout':
        return 'Trả phòng';
      default:
        final String raw = type?.trim() ?? '';
        return raw.isEmpty ? 'Xử lý hồ sơ' : raw;
    }
  }

  Color _actionColor(String? action) {
    switch (action?.trim().toLowerCase()) {
      case 'approved':
      case 'assigned':
      case 'room_assigned':
      case 'checkin':
      case 'checked_in':
        return const Color(0xFF078B3E);
      case 'rejected':
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      case 'submitted':
        return Colors.blue;
      case 'checkout':
      case 'checked_out':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _actionIcon(String? action) {
    switch (action?.trim().toLowerCase()) {
      case 'submitted':
        return Icons.send_rounded;
      case 'approved':
        return Icons.verified_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'assigned':
      case 'room_assigned':
        return Icons.meeting_room_rounded;
      case 'checkin':
      case 'checked_in':
        return Icons.login_rounded;
      case 'checkout':
      case 'checked_out':
        return Icons.logout_rounded;
      case 'updated':
        return Icons.edit_note_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Không có thời gian';
    return _dateTimeFormat.format(value.toLocal());
  }

  String _formatDynamicDate(dynamic value) {
    final DateTime? parsed = DateTime.tryParse(value.toString());
    return parsed == null ? value.toString() : _dateFormat.format(parsed.toLocal());
  }

  String _formatDynamicDateTime(dynamic value) {
    final DateTime? parsed = DateTime.tryParse(value.toString());
    return parsed == null ? value.toString() : _dateTimeFormat.format(parsed.toLocal());
  }

  String _boolText(dynamic value) {
    if (value is bool) return value ? 'Có' : 'Không';
    final String normalized = value.toString().trim().toLowerCase();
    if (normalized == '1' || normalized == 'true') return 'Có';
    if (normalized == '0' || normalized == 'false') return 'Không';
    return value.toString();
  }

  String _displayDynamicValue(dynamic value) {
    if (value == null) return '';

    if (value is Map) {
      final Map<String, dynamic> map = <String, dynamic>{};
      value.forEach((dynamic key, dynamic item) {
        map[key.toString()] = item;
      });
      const List<String> preferredKeys = <String>[
        'label',
        'name',
        'fullName',
        'full_name',
        'displayName',
        'display_name',
        'title',
        'roomNumber',
        'room_number',
        'statusLabel',
        'status_label',
        'kindLabel',
        'kind_label',
        'abbreviation',
      ];

      for (final String key in preferredKeys) {
        final dynamic nested = map[key];
        if (nested == null || identical(nested, value)) continue;
        final String text = _displayDynamicValue(nested).trim();
        if (text.isNotEmpty && !_isNumericText(text)) return text;
      }

      // Không hiển thị map dưới dạng JSON/toString vì đây là giao diện người dùng.
      return '';
    }

    if (value is Iterable && value is! String) {
      return value
          .map(_displayDynamicValue)
          .where((String item) => item.trim().isNotEmpty)
          .toSet()
          .join(', ');
    }

    if (value is bool) return value ? 'Có' : 'Không';
    return value.toString().trim();
  }

  String _fieldLabel(String key) {
    final Map<String, String> known = <String, String>{
      'asm_status': 'Trạng thái xếp chỗ',
      'created_at': 'Ngày tạo',
      'updated_at': 'Ngày cập nhật',
      'deleted_at': 'Ngày xóa',
    };

    return known[key.toLowerCase()] ??
        key
            .replaceAll('_', ' ')
            .split(' ')
            .where((String part) => part.isNotEmpty)
            .map(
              (String part) =>
                  '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
  }

  String _firstText(List<dynamic> values) {
    for (final dynamic value in values) {
      if (value == null) continue;
      final String text = _displayDynamicValue(value).trim();
      if (text.isEmpty || _isNumericText(text)) continue;
      return text;
    }
    return '';
  }

  bool _isNumericText(String value) {
    return num.tryParse(value.trim()) != null;
  }

  bool _isTechnicalIdentifierKey(String normalizedKey) {
    final String key = normalizedKey
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (Match match) => '${match.group(1)}_${match.group(2)}',
        )
        .toLowerCase();
    return key == 'id' ||
        key.endsWith('_id') ||
        key.endsWith('_ids') ||
        key.endsWith('_code') ||
        key.endsWith('_codes') ||
        <String>{
          'performed_by',
          'approved_by',
          'assigned_to',
          'student_code',
          'receipt_code',
          'payment_code',
          'trace_id',
        }.contains(key);
  }

  String _humanizeValue(String value) {
    final String normalized = value
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (Match match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
    if (normalized.isEmpty) return '';
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  int? _firstInt(List<dynamic> values) {
    for (final dynamic value in values) {
      final int? parsed = _toInt(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}

class _HistoryField {
  final String label;
  final String value;
  final IconData icon;
  final String? subtitle;

  const _HistoryField(
    this.label,
    this.value,
    this.icon, {
    this.subtitle,
  });
}

class _ResolvedValue {
  final String label;
  final String value;
  final String? subtitle;

  const _ResolvedValue(
    this.label,
    this.value, {
    this.subtitle,
  });
}
