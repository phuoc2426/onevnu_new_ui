import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vnu_core/common/app_text_styles.dart';

class DRStudentHistorySheet extends StatelessWidget {
  final dynamic data;

  const DRStudentHistorySheet({
    super.key,
    required this.data,
  });

  static const Color _mainColor = Color(0xFF078B3E);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _borderColor = Color(0xFFE2E7E4);

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> root = _asMap(data);
    final dynamic student = _firstValue(root, const <String>['student']);
    final List<dynamic> accommodations = _listValue(
      root,
      const <String>['accommodations'],
    );
    final List<dynamic> roommates = _listValue(
      root,
      const <String>['roommates'],
    );
    final List<dynamic> receipts = _listValue(
      root,
      const <String>['receipts'],
    );
    final List<dynamic> issues = _listValue(
      root,
      const <String>['issues'],
    );
    final List<dynamic> histories = _listValue(
      root,
      const <String>['histories'],
    );

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.96,
        child: Container(
          decoration: const BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4D9D6),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 8, 10),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5F5EB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.manage_search_rounded,
                        color: _mainColor,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Thông tin và lịch sử sinh viên',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF171A18),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${accommodations.length} hồ sơ · '
                            '${receipts.length} biên lai · '
                            '${histories.length} sự kiện',
                            style: const TextStyle(
                              fontSize: AppFontSizes.font11,
                              color: Color(0xFF6F756F),
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
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: _mainColor,
                          secondary: _mainColor,
                        ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                    children: <Widget>[
                      _buildStudentSection(student),
                      const SizedBox(height: 10),
                      _buildAccommodationSection(accommodations),
                      const SizedBox(height: 10),
                      _buildRoommateSection(roommates),
                      const SizedBox(height: 10),
                      _buildReceiptSection(receipts, accommodations),
                      const SizedBox(height: 10),
                      _buildIssueSection(issues),
                      const SizedBox(height: 10),
                      _buildHistorySection(histories, accommodations),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentSection(dynamic rawStudent) {
    final Map<String, dynamic> student = _asMap(rawStudent);
    final List<dynamic> familyMembers = _listValue(
      student,
      const <String>['familyMembers', 'family_members'],
    );

    return _sectionCard(
      icon: Icons.person_rounded,
      title: 'Thông tin sinh viên',
      subtitle: _text(student, const <String>['fullName', 'full_name']),
      initiallyExpanded: true,
      children: <Widget>[
        _groupTitle('Thông tin cơ bản'),
        ..._rows(<_DisplayEntry>[
          _entry(
            'Mã sinh viên',
            student,
            const <String>['studentCode', 'student_code'],
          ),
          _entry(
            'Họ và tên',
            student,
            const <String>['fullName', 'full_name'],
          ),
          _entry(
            'Ảnh thẻ',
            student,
            const <String>['avatar'],
          ),
          _entry(
            'Giới tính',
            student,
            const <String>['gender'],
            transform: _genderLabel,
          ),
          _dateEntry(
            'Ngày sinh',
            student,
            const <String>['dob'],
            dateOnly: true,
          ),
          _entry(
            'Điện thoại',
            student,
            const <String>['phoneNumber', 'phone_number'],
          ),
          _entry('Email', student, const <String>['email']),
          _entry(
            'Loại cư trú',
            student,
            const <String>[
              'residenceTypeLabel',
              'residence_type_label',
              'residenceType',
              'residence_type',
            ],
            transform: _residenceLabel,
          ),
          _entry('Trạng thái', student, const <String>['status']),
        ]),
        const SizedBox(height: 12),
        _groupTitle('Giấy tờ và nhân thân'),
        ..._rows(<_DisplayEntry>[
          _entry(
            'Loại giấy tờ',
            student,
            const <String>['identityType', 'identity_type'],
          ),
          _entry(
            'Tên trên giấy tờ',
            student,
            const <String>['identityName', 'identity_name'],
          ),
          _entry(
            'Số giấy tờ',
            student,
            const <String>['identityNo', 'identity_no'],
          ),
          _dateEntry(
            'Ngày cấp',
            student,
            const <String>['identityIssueDate', 'identity_issue_date'],
            dateOnly: true,
          ),
          _entry(
            'Nơi cấp',
            student,
            const <String>['identityIssuePlace', 'identity_issue_place'],
          ),
          _entry('Dân tộc', student, const <String>['ethnicity']),
          _entry('Tôn giáo', student, const <String>['religion']),
          _entry('Quốc gia', student, const <String>['country']),
          _entry('Quốc tịch', student, const <String>['national']),
        ]),
        const SizedBox(height: 12),
        _groupTitle('Địa chỉ và thông tin lưu trú'),
        ..._rows(<_DisplayEntry>[
          _entry(
            'Thường trú',
            student,
            const <String>['permanentAddress', 'permanent_address'],
          ),
          _entry(
            'Thường trú VNeID',
            student,
            const <String>[
              'vneidPermanentAddress',
              'vneid_permanent_address',
            ],
          ),
          _entry(
            'Địa chỉ liên hệ',
            student,
            const <String>['contactAddress', 'contact_address'],
          ),
          _entry(
            'Tạm trú',
            student,
            const <String>['temporaryAddress', 'temporary_address'],
          ),
          _entry(
            'Tạm trú VNeID',
            student,
            const <String>[
              'vneidTemporaryAddress',
              'vneid_temporary_address',
            ],
          ),
          _entry(
            'Lý do lưu trú',
            student,
            const <String>['reasonStay', 'reason_stay'],
          ),
        ]),
        const SizedBox(height: 12),
        _groupTitle('Thông tin học tập'),
        ..._rows(<_DisplayEntry>[
          _entry('Trường', student, const <String>['university']),
          _entry('Lớp', student, const <String>['class']),
          _entry('Khoa', student, const <String>['faculty']),
          _entry('Ngành', student, const <String>['major']),
          _entry(
            'Niên khóa',
            student,
            const <String>['academicYear', 'academic_year'],
          ),
        ]),
        if (familyMembers.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _groupTitle('Thông tin gia đình'),
          ...familyMembers.asMap().entries.map(
                (MapEntry<int, dynamic> item) =>
                    _buildFamilyMember(item.value, item.key),
              ),
        ],
      ],
    );
  }

  Widget _buildFamilyMember(dynamic rawMember, int index) {
    final Map<String, dynamic> member = _asMap(rawMember);
    final String relationship = _text(
      member,
      const <String>['relationshipLabel', 'relationship_label', 'relationship'],
    );

    return _itemContainer(
      title: relationship.isEmpty ? 'Người thân ${index + 1}' : relationship,
      children: _rows(<_DisplayEntry>[
        _entry(
          'Quan hệ',
          member,
          const <String>['relationship', 'relationshipLabel'],
          transform: _relationshipLabel,
        ),
        _entry(
          'Họ và tên',
          member,
          const <String>['fullName', 'full_name'],
        ),
        _entry(
          'Năm sinh',
          member,
          const <String>['birthYear', 'birth_year'],
        ),
        _entry('Nghề nghiệp', member, const <String>['occupation']),
        _entry(
          'Điện thoại',
          member,
          const <String>['phoneNumber', 'phone_number'],
        ),
      ]),
    );
  }

  Widget _buildAccommodationSection(List<dynamic> values) {
    return _sectionCard(
      icon: Icons.apartment_rounded,
      title: 'Lịch sử hồ sơ nội trú',
      subtitle: '${values.length} hồ sơ',
      initiallyExpanded: true,
      children: values.isEmpty
          ? <Widget>[_emptyText('Chưa có hồ sơ nội trú')]
          : values.asMap().entries.map((MapEntry<int, dynamic> item) {
              final Map<String, dynamic> value = _asMap(item.value);
              final String dormitoryName = _text(
                value,
                const <String>['dormitory', 'dormitoryName', 'dormitory_name'],
              );
              final String periodName = _text(
                value,
                const <String>[
                  'registrationPeriodName',
                  'registration_period_name',
                  'periodName',
                  'period_name',
                ],
              );
              final String statusLabel = _accommodationStatusLabel(value);
              final List<String> titleParts = <String>[
                dormitoryName,
                periodName,
              ].where((String part) => part.trim().isNotEmpty).toList();

              final dynamic rawDraft = _firstValue(
                value,
                const <String>['isDraft', 'is_draft'],
              );
              final String draftLabel = rawDraft == null
                  ? ''
                  : (_asBool(rawDraft) ? 'Bản nháp' : 'Đã gửi');

              return _itemContainer(
                title: titleParts.isEmpty
                    ? 'Hồ sơ nội trú ${item.key + 1}'
                    : titleParts.join(' · '),
                badge: statusLabel,
                children: _rows(<_DisplayEntry>[
                  _DisplayEntry('Ký túc xá', dormitoryName),
                  _DisplayEntry('Đợt đăng ký', periodName),
                  _DisplayEntry('Trạng thái', statusLabel),
                  _DisplayEntry('Loại hồ sơ', draftLabel),
                  _entry('Tòa nhà', value, const <String>['building']),
                  _entry(
                    'Loại phòng',
                    value,
                    const <String>[
                      'roomTypeName',
                      'room_type_name',
                      'roomType',
                      'room_type',
                    ],
                  ),
                  _entry(
                    'Phòng được xếp',
                    value,
                    const <String>['assignedRoom', 'assigned_room'],
                  ),
                  _entry(
                    'Đối tượng ưu tiên',
                    value,
                    const <String>['priorityObject', 'priority_object'],
                  ),
                  _dateEntry(
                    'Bắt đầu lưu trú',
                    value,
                    const <String>['startDate', 'start_date'],
                    dateOnly: true,
                  ),
                  _dateEntry(
                    'Kết thúc lưu trú',
                    value,
                    const <String>['endDate', 'end_date'],
                    dateOnly: true,
                  ),
                  _dateEntry(
                    'Ngày tạo',
                    value,
                    const <String>['createdAt', 'created_at'],
                  ),
                  _dateEntry(
                    'Cập nhật gần nhất',
                    value,
                    const <String>['updatedAt', 'updated_at'],
                  ),
                ]),
              );
            }).toList(),
    );
  }

  Widget _buildRoommateSection(List<dynamic> values) {
    return _sectionCard(
      icon: Icons.groups_rounded,
      title: 'Bạn cùng phòng',
      subtitle: '${values.length} sinh viên',
      children: values.isEmpty
          ? <Widget>[_emptyText('Chưa có thông tin bạn cùng phòng')]
          : values.asMap().entries.map((MapEntry<int, dynamic> item) {
              final Map<String, dynamic> value = _asMap(item.value);
              final String name = _text(
                value,
                const <String>['studentName', 'student_name'],
              );
              return _itemContainer(
                title: name.isEmpty ? 'Sinh viên ${item.key + 1}' : name,
                children: _rows(<_DisplayEntry>[
                  _entry(
                    'Mã sinh viên',
                    value,
                    const <String>['studentCode', 'student_code'],
                  ),
                  _entry(
                    'Họ và tên',
                    value,
                    const <String>['studentName', 'student_name'],
                  ),
                  _dateEntry(
                    'Bắt đầu ở',
                    value,
                    const <String>['startDate', 'start_date'],
                    dateOnly: true,
                  ),
                ]),
              );
            }).toList(),
    );
  }

  Widget _buildReceiptSection(
    List<dynamic> values,
    List<dynamic> accommodations,
  ) {
    return _sectionCard(
      icon: Icons.receipt_long_rounded,
      title: 'Biên lai',
      subtitle: '${values.length} biên lai',
      children: values.isEmpty
          ? <Widget>[_emptyText('Chưa có biên lai')]
          : values.asMap().entries.map((MapEntry<int, dynamic> item) {
              final Map<String, dynamic> value = _asMap(item.value);
              final Map<String, dynamic> accommodation =
                  _findAccommodationForRecord(value, accommodations);
              final String dormitoryName = _text(
                accommodation,
                const <String>['dormitory', 'dormitoryName', 'dormitory_name'],
              );
              final String periodName = _text(
                accommodation,
                const <String>[
                  'registrationPeriodName',
                  'registration_period_name',
                  'periodName',
                  'period_name',
                ],
              );
              final String kind = _receiptKindLabel(value);
              final String statusLabel = _paymentStatusLabel(value);
              final String dateRange = _dateRange(
                _firstValue(value, const <String>['start_date', 'startDate']),
                _firstValue(value, const <String>['end_date', 'endDate']),
              );
              final List<String> titleParts = <String>[
                kind,
                periodName,
              ].where((String part) => part.trim().isNotEmpty).toList();

              return _itemContainer(
                title: titleParts.isEmpty
                    ? 'Khoản thu ${item.key + 1}'
                    : titleParts.join(' · '),
                badge: statusLabel,
                children: _rows(<_DisplayEntry>[
                  _DisplayEntry('Ký túc xá', dormitoryName),
                  _DisplayEntry('Đợt đăng ký', periodName),
                  _DisplayEntry('Thời gian áp dụng', dateRange),
                  _moneyEntry(
                    'Tổng tiền',
                    value,
                    const <String>['total_amount', 'totalAmount'],
                  ),
                  _DisplayEntry(
                    'Loại khoản thu',
                    kind,
                  ),
                  _DisplayEntry(
                    'Chiều giao dịch',
                    _transactionDirectionLabel(value),
                  ),
                  _DisplayEntry('Trạng thái', statusLabel),
                  _dateEntry(
                    'Hạn thanh toán',
                    value,
                    const <String>['due_date', 'dueDate'],
                  ),
                  _dateEntry(
                    'Đã thanh toán lúc',
                    value,
                    const <String>['paid_at', 'paidAt'],
                  ),
                  _dateEntry(
                    'Ngày tạo',
                    value,
                    const <String>['created_at', 'createdAt'],
                  ),
                  _dateEntry(
                    'Ngày cập nhật',
                    value,
                    const <String>['updated_at', 'updatedAt'],
                  ),
                ]),
              );
            }).toList(),
    );
  }

  Widget _buildIssueSection(List<dynamic> values) {
    return _sectionCard(
      icon: Icons.report_problem_rounded,
      title: 'Sự cố và phản ánh',
      subtitle: '${values.length} nội dung',
      children: values.isEmpty
          ? <Widget>[_emptyText('Chưa có sự cố hoặc phản ánh')]
          : values.asMap().entries.map((MapEntry<int, dynamic> item) {
              final Map<String, dynamic> value = _asMap(item.value);
              final String title = _text(value, const <String>['title']);
              final String statusLabel = _issueSemanticLabel(
                value,
                const <String>['statusLabel', 'status_label'],
                const <String>['status'],
              );
              final String typeLabel = _issueSemanticLabel(
                value,
                const <String>['typeLabel', 'type_label'],
                const <String>['type'],
              );
              final String priorityLabel = _issueSemanticLabel(
                value,
                const <String>['priorityLabel', 'priority_label'],
                const <String>['priority'],
              );

              return _itemContainer(
                title: title.isEmpty ? 'Sự cố ${item.key + 1}' : title,
                badge: statusLabel,
                children: _rows(<_DisplayEntry>[
                  _entry('Tiêu đề', value, const <String>['title']),
                  _entry('Nội dung', value, const <String>['description']),
                  _DisplayEntry('Loại', typeLabel),
                  _DisplayEntry('Mức ưu tiên', priorityLabel),
                  _DisplayEntry('Trạng thái', statusLabel),
                  _dateEntry(
                    'Ngày tạo',
                    value,
                    const <String>['created_at', 'createdAt'],
                  ),
                  _dateEntry(
                    'Ngày cập nhật',
                    value,
                    const <String>['updated_at', 'updatedAt'],
                  ),
                ]),
              );
            }).toList(),
    );
  }

  Widget _buildHistorySection(
    List<dynamic> values,
    List<dynamic> accommodations,
  ) {
    final List<dynamic> sorted = List<dynamic>.from(values)
      ..sort((dynamic first, dynamic second) {
        final DateTime firstDate = _parseDate(
              _firstValue(
                _asMap(first),
                const <String>['created_at', 'createdAt'],
              ),
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime secondDate = _parseDate(
              _firstValue(
                _asMap(second),
                const <String>['created_at', 'createdAt'],
              ),
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return secondDate.compareTo(firstDate);
      });

    return _sectionCard(
      icon: Icons.history_rounded,
      title: 'Lịch sử thay đổi',
      subtitle: '${sorted.length} sự kiện',
      initiallyExpanded: true,
      children: sorted.isEmpty
          ? <Widget>[_emptyText('Chưa có lịch sử thay đổi')]
          : sorted.asMap().entries.map((MapEntry<int, dynamic> item) {
              final Map<String, dynamic> value = _asMap(item.value);
              final Map<String, dynamic> accommodation =
                  _findAccommodationForRecord(value, accommodations);
              final String action = _text(value, const <String>['action']);
              final String type = _text(value, const <String>['type']);
              final String dormitoryName = _text(
                accommodation,
                const <String>['dormitory', 'dormitoryName', 'dormitory_name'],
              );
              final String periodName = _text(
                accommodation,
                const <String>[
                  'registrationPeriodName',
                  'registration_period_name',
                  'periodName',
                  'period_name',
                ],
              );
              final String statusLabel = accommodation.isEmpty
                  ? _registrationStatusLabel(
                      _firstValue(
                        value,
                        const <String>['statusLabel', 'status_label', 'status'],
                      ),
                    )
                  : _accommodationStatusLabel(accommodation);
              final String performerName = _firstNonEmpty(<String>[
                _text(
                  value,
                  const <String>[
                    'performedByName',
                    'performed_by_name',
                    'performerName',
                    'performer_name',
                  ],
                ),
                _nestedText(value, 'performer', const <String>[
                  'fullName',
                  'full_name',
                  'name',
                  'username',
                ]),
              ]);
              final dynamic rawData = _firstValue(value, const <String>['data']);

              return _itemContainer(
                title: action.isNotEmpty
                    ? _actionLabel(action)
                    : type.isNotEmpty
                        ? _eventTypeLabel(type)
                        : 'Cập nhật hồ sơ',
                badge: _formatDate(
                  _firstValue(value, const <String>['created_at', 'createdAt']),
                ),
                children: <Widget>[
                  ..._rows(<_DisplayEntry>[
                    _DisplayEntry('Ký túc xá', dormitoryName),
                    _DisplayEntry('Đợt đăng ký', periodName),
                    _DisplayEntry('Trạng thái hồ sơ', statusLabel),
                    _DisplayEntry('Loại sự kiện', _eventTypeLabel(type)),
                    _DisplayEntry('Hành động', _actionLabel(action)),
                    _DisplayEntry('Người thực hiện', performerName),
                    _entry('Ghi chú', value, const <String>['note']),
                    _dateEntry(
                      'Thời gian',
                      value,
                      const <String>['created_at', 'createdAt'],
                    ),
                  ]),
                  if (rawData != null) ...<Widget>[
                    const SizedBox(height: 8),
                    _groupTitle('Dữ liệu thay đổi'),
                    _buildDynamicData(
                      rawData,
                      accommodation: accommodation,
                    ),
                  ],
                ],
              );
            }).toList(),
    );
  }

  Widget _buildDynamicData(
    dynamic value, {
    int depth = 0,
    Map<String, dynamic>? accommodation,
  }) {
    if (value == null) {
      return _emptyText('Không có dữ liệu chi tiết');
    }

    if (value is Map) {
      if (value.isEmpty) return _emptyText('Không có dữ liệu chi tiết');
      final List<MapEntry<dynamic, dynamic>> entries = value.entries
          .where(
            (MapEntry<dynamic, dynamic> item) =>
                !_isTechnicalIdentifierKey(item.key.toString()),
          )
          .toList();
      if (entries.isEmpty) {
        return _emptyText('Không có thông tin nghiệp vụ cần hiển thị');
      }

      final List<Widget> widgets = <Widget>[];
      for (final MapEntry<dynamic, dynamic> item in entries) {
        final String key = item.key.toString();
        final dynamic nested = item.value;
        final bool complex = nested is Map || nested is List;
        final String displayValue = complex
            ? ''
            : _displayDynamicFieldValue(
                key,
                nested,
                accommodation: accommodation,
              );
        if (!complex && displayValue.trim().isEmpty) continue;

        widgets.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: depth.isEven ? const Color(0xFFF7F9F8) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _dynamicFieldLabel(key),
                  style: const TextStyle(
                    fontSize: AppFontSizes.extraSmall,
                    color: Color(0xFF6F756F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (complex)
                  _buildDynamicData(
                    nested,
                    depth: depth + 1,
                    accommodation: accommodation,
                  )
                else
                  SelectableText(
                    displayValue,
                    style: const TextStyle(
                      fontSize: AppFontSizes.font11,
                      color: Color(0xFF252A27),
                      height: 1.35,
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      return widgets.isEmpty
          ? _emptyText('Không có thông tin nghiệp vụ cần hiển thị')
          : Column(children: widgets);
    }

    if (value is List) {
      if (value.isEmpty) return _emptyText('Danh sách trống');
      return Column(
        children: value.asMap().entries.map((MapEntry<int, dynamic> item) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9F8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Nội dung ${item.key + 1}',
                  style: const TextStyle(
                    fontSize: AppFontSizes.extraSmall,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6F756F),
                  ),
                ),
                const SizedBox(height: 4),
                _buildDynamicData(
                  item.value,
                  depth: depth + 1,
                  accommodation: accommodation,
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return SelectableText(
      _displayValue(value),
      style: const TextStyle(
        fontSize: AppFontSizes.font11,
        color: Color(0xFF252A27),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    String? subtitle,
    bool initiallyExpanded = false,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        iconColor: _mainColor,
        collapsedIconColor: const Color(0xFF68716B),
        leading: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F6ED),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _mainColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: AppFontSizes.mediumSmall,
            fontWeight: FontWeight.w700,
            color: Color(0xFF171A18),
          ),
        ),
        subtitle: subtitle == null || subtitle.trim().isEmpty
            ? null
            : Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppFontSizes.extraSmall,
                  color: Color(0xFF737A75),
                ),
              ),
        children: children,
      ),
    );
  }

  Widget _itemContainer({
    required String title,
    required List<Widget> children,
    String? badge,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSizes.font11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D211F),
                  ),
                ),
              ),
              if (badge != null && badge.trim().isNotEmpty) ...<Widget>[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F5EC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: AppFontSizes.extraSmall,
                      fontWeight: FontWeight.w700,
                      color: _mainColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Divider(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _groupTitle(String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: <Widget>[
          Container(
            width: 3,
            height: 15,
            decoration: BoxDecoration(
              color: _mainColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppFontSizes.font11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF263029),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _rows(List<_DisplayEntry> values) {
    return values
        .where((_DisplayEntry item) => item.value.trim().isNotEmpty)
        .map(_buildInfoRow)
        .toList();
  }

  Widget _buildInfoRow(_DisplayEntry item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 128,
            child: Text(
              item.label,
              style: const TextStyle(
                fontSize: AppFontSizes.extraSmall,
                color: Color(0xFF747B76),
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              item.value,
              style: const TextStyle(
                fontSize: AppFontSizes.font11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF252A27),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyText(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: AppFontSizes.font11,
          color: Color(0xFF777E79),
        ),
      ),
    );
  }

  _DisplayEntry _entry(
    String label,
    Map<String, dynamic> source,
    List<String> keys, {
    String Function(String value)? transform,
  }) {
    String value = _text(source, keys);
    if (value.isNotEmpty && transform != null) value = transform(value);
    return _DisplayEntry(label, value);
  }

  _DisplayEntry _dateEntry(
    String label,
    Map<String, dynamic> source,
    List<String> keys, {
    bool dateOnly = false,
  }) {
    return _DisplayEntry(
      label,
      _formatDate(_firstValue(source, keys), dateOnly: dateOnly),
    );
  }

  _DisplayEntry _moneyEntry(
    String label,
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    final dynamic raw = _firstValue(source, keys);
    if (raw == null || raw.toString().trim().isEmpty) {
      return _DisplayEntry(label, '');
    }

    final num? number = raw is num
        ? raw
        : num.tryParse(raw.toString().replaceAll(',', '').trim());
    if (number == null) return _DisplayEntry(label, raw.toString());

    return _DisplayEntry(
      label,
      NumberFormat.currency(
        locale: 'vi_VN',
        symbol: 'đ',
        decimalDigits: 0,
      ).format(number),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static dynamic _firstValue(Map<String, dynamic> source, List<String> keys) {
    for (final String key in keys) {
      if (!source.containsKey(key)) continue;
      final dynamic value = source[key];
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      return value;
    }
    return null;
  }

  static String _text(Map<String, dynamic> source, List<String> keys) {
    final dynamic value = _firstValue(source, keys);
    if (value == null) return '';
    if (value is Map || value is List) {
      try {
        return const JsonEncoder.withIndent('  ').convert(value);
      } catch (_) {
        return value.toString();
      }
    }
    return value.toString().trim();
  }

  static List<dynamic> _listValue(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    final dynamic value = _firstValue(source, keys);
    if (value is List) return List<dynamic>.from(value);
    if (value is Iterable && value is! String) {
      return List<dynamic>.from(value);
    }
    return <dynamic>[];
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static String _formatDate(dynamic value, {bool dateOnly = false}) {
    final DateTime? date = _parseDate(value);
    if (date == null) return value?.toString().trim() ?? '';
    return DateFormat(dateOnly ? 'dd/MM/yyyy' : 'dd/MM/yyyy HH:mm')
        .format(date.toLocal());
  }

  static Map<String, dynamic> _findAccommodationForRecord(
    Map<String, dynamic> record,
    List<dynamic> accommodations,
  ) {
    final dynamic rawId = _firstValue(
      record,
      const <String>['accommodation_id', 'accommodationId'],
    );
    final String targetId = rawId?.toString().trim() ?? '';
    if (targetId.isNotEmpty) {
      for (final dynamic item in accommodations) {
        final Map<String, dynamic> mapped = _asMap(item);
        final String candidate =
            _firstValue(mapped, const <String>['id'])?.toString().trim() ?? '';
        if (candidate.isNotEmpty && candidate == targetId) return mapped;
      }
    }

    if (accommodations.length == 1) return _asMap(accommodations.first);
    return <String, dynamic>{};
  }

  static String _accommodationStatusLabel(Map<String, dynamic> value) {
    final String explicit = _text(
      value,
      const <String>['statusLabel', 'status_label'],
    );
    if (explicit.isNotEmpty) return explicit;
    return _registrationStatusLabel(
      _firstValue(value, const <String>['status']),
    );
  }

  static String _registrationStatusLabel(dynamic value) {
    final String normalized = value?.toString().trim().toLowerCase() ?? '';
    switch (normalized) {
      case '0':
      case 'draft':
        return 'Bản nháp';
      case '1':
      case 'pending':
      case 'submitted':
        return 'Chờ duyệt';
      case '2':
      case 'approved':
        return 'Đã duyệt';
      case '3':
      case 'assigned':
      case 'room_assigned':
        return 'Đã xếp phòng';
      case '4':
      case 'active':
      case 'checked_in':
      case 'checkin':
        return 'Đang lưu trú';
      case '5':
      case 'rejected':
        return 'Từ chối';
      case '6':
      case 'checkout':
      case 'checked_out':
        return 'Đã trả phòng';
      case '7':
      case 'terminated':
      case 'cancelled':
      case 'canceled':
        return 'Đã chấm dứt';
      default:
        if (normalized.isEmpty || _isNumericText(normalized)) return '';
        return _humanize(normalized);
    }
  }

  static String _paymentStatusLabel(Map<String, dynamic> value) {
    final String explicit = _text(
      value,
      const <String>['statusLabel', 'status_label'],
    );
    if (explicit.isNotEmpty) return explicit;

    final String normalized = _text(value, const <String>['status'])
        .trim()
        .toLowerCase();
    switch (normalized) {
      case 'paid':
      case 'completed':
      case 'success':
        return 'Đã thanh toán';
      case 'pending':
      case 'waiting':
      case 'submitted':
        return 'Chờ xác nhận';
      case 'overdue':
        return 'Quá hạn';
      case 'cancelled':
      case 'canceled':
        return 'Đã hủy';
      case 'rejected':
        return 'Bị từ chối';
      case 'unpaid':
      case 'new':
        return 'Chưa thanh toán';
      default:
        if (normalized.isEmpty || _isNumericText(normalized)) return '';
        return _humanize(normalized);
    }
  }

  static String _receiptKindLabel(Map<String, dynamic> value) {
    final String explicit = _text(
      value,
      const <String>['kindLabel', 'kind_label', 'title'],
    );
    if (explicit.isNotEmpty) return explicit;
    final String raw = _text(value, const <String>['kind']);
    return raw.isEmpty || _isNumericText(raw) ? '' : _humanize(raw);
  }

  static String _transactionDirectionLabel(Map<String, dynamic> value) {
    final String raw = _text(value, const <String>['direction'])
        .trim()
        .toLowerCase();
    switch (raw) {
      case 'in':
      case 'income':
      case 'debit':
      case 'collect':
      case 'collection':
        return 'Khoản thu';
      case 'out':
      case 'expense':
      case 'credit':
      case 'refund':
        return 'Hoàn trả / chi';
      default:
        if (raw.isEmpty || _isNumericText(raw)) return '';
        return _humanize(raw);
    }
  }

  static String _issueSemanticLabel(
    Map<String, dynamic> value,
    List<String> labelKeys,
    List<String> rawKeys,
  ) {
    final String label = _text(value, labelKeys);
    if (label.isNotEmpty) return label;
    final String raw = _text(value, rawKeys);
    if (raw.isEmpty || _isNumericText(raw)) return '';
    return _humanize(raw);
  }

  static String _actionLabel(String value) {
    switch (value.trim().toLowerCase()) {
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
        return value.trim().isEmpty ? '' : _humanize(value);
    }
  }

  static String _eventTypeLabel(String value) {
    switch (value.trim().toLowerCase()) {
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
        return value.trim().isEmpty ? '' : _humanize(value);
    }
  }

  static String _dateRange(dynamic start, dynamic end) {
    final String startText = _formatDate(start, dateOnly: true);
    final String endText = _formatDate(end, dateOnly: true);
    if (startText.isNotEmpty && endText.isNotEmpty) {
      return '$startText đến $endText';
    }
    return startText.isNotEmpty ? startText : endText;
  }

  static String _nestedText(
    Map<String, dynamic> source,
    String parentKey,
    List<String> keys,
  ) {
    final dynamic nested = source[parentKey];
    return _text(_asMap(nested), keys);
  }

  static String _firstNonEmpty(List<String> values) {
    for (final String value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final String normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  static bool _isNumericText(String value) {
    return num.tryParse(value.trim()) != null;
  }

  static bool _isTechnicalIdentifierKey(String key) {
    final String normalized = key
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (Match match) => '${match.group(1)}_${match.group(2)}',
        )
        .toLowerCase();

    if (normalized == 'id' ||
        normalized.endsWith('_id') ||
        normalized.endsWith('_ids') ||
        normalized.endsWith('_code') ||
        normalized.endsWith('_codes')) {
      return true;
    }

    return <String>{
      'performed_by',
      'approved_by',
      'assigned_to',
      'student_code',
      'receipt_code',
      'payment_code',
      'trace_id',
    }.contains(normalized);
  }

  static String _dynamicFieldLabel(String key) {
    final String normalized = key
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (Match match) => '${match.group(1)}_${match.group(2)}',
        )
        .toLowerCase();
    const Map<String, String> labels = <String, String>{
      'dormitory': 'Ký túc xá',
      'dormitory_name': 'Ký túc xá',
      'registration_period_name': 'Đợt đăng ký',
      'period_name': 'Đợt đăng ký',
      'status': 'Trạng thái hồ sơ',
      'status_label': 'Trạng thái hồ sơ',
      'request_status': 'Trạng thái yêu cầu',
      'room_type_name': 'Loại phòng',
      'assigned_room': 'Phòng được xếp',
      'priority_object': 'Đối tượng ưu tiên',
      'priority_object_name': 'Đối tượng ưu tiên',
      'start_date': 'Ngày bắt đầu',
      'end_date': 'Ngày kết thúc',
      'created_at': 'Ngày tạo',
      'updated_at': 'Ngày cập nhật',
      'approved_at': 'Ngày duyệt',
      'assigned_at': 'Ngày xếp phòng',
      'checkin_at': 'Ngày nhận phòng',
      'checkout_at': 'Ngày trả phòng',
      'reason_stay': 'Lý do lưu trú',
      'note': 'Ghi chú',
      'is_draft': 'Loại hồ sơ',
      'is_room_leader': 'Trưởng phòng',
    };
    return labels[normalized] ?? _humanize(normalized);
  }

  static String _displayDynamicFieldValue(
    String key,
    dynamic value, {
    Map<String, dynamic>? accommodation,
  }) {
    final String normalized = key
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (Match match) => '${match.group(1)}_${match.group(2)}',
        )
        .toLowerCase();

    if (normalized == 'status' || normalized == 'status_label') {
      final String fromAccommodation = accommodation == null
          ? ''
          : _accommodationStatusLabel(accommodation);
      return fromAccommodation.isNotEmpty
          ? fromAccommodation
          : _registrationStatusLabel(value);
    }
    if (normalized == 'request_status') {
      final String raw = value?.toString().trim().toLowerCase() ?? '';
      switch (raw) {
        case '0':
        case 'none':
          return 'Không có yêu cầu';
        case '1':
        case 'pending':
          return 'Đang chờ xử lý';
        case '2':
        case 'approved':
          return 'Đã chấp thuận';
        case '3':
        case 'rejected':
          return 'Từ chối';
        case 'change_room':
          return 'Yêu cầu chuyển phòng';
        case 'checkout':
          return 'Yêu cầu trả phòng';
        default:
          return raw.isEmpty || _isNumericText(raw) ? '' : _humanize(raw);
      }
    }
    if (normalized == 'is_draft') {
      return _asBool(value) ? 'Bản nháp' : 'Đã gửi';
    }
    if (normalized.startsWith('is_')) return _asBool(value) ? 'Có' : 'Không';
    if (normalized.endsWith('_date') ||
        normalized.endsWith('_at') ||
        normalized == 'start_date' ||
        normalized == 'end_date') {
      return _formatDate(value);
    }
    return _displayValue(value);
  }

  static String _displayValue(dynamic value) {
    if (value == null) return '—';
    if (value is bool) return value ? 'Có' : 'Không';
    final DateTime? date = _parseDate(value);
    if (date != null && value.toString().contains(RegExp(r'[-T:]'))) {
      return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
    }
    return value.toString();
  }

  static String _boolLabel(String value) {
    final String normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' ? 'Có' : 'Không';
  }

  static String _genderLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'male':
      case 'nam':
        return 'Nam';
      case 'female':
      case 'nữ':
      case 'nu':
        return 'Nữ';
      default:
        return value;
    }
  }

  static String _residenceLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'noi_tru':
        return 'Nội trú';
      case 'ngoai_tru':
        return 'Ngoại trú';
      default:
        return value;
    }
  }

  static String _relationshipLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'father':
        return 'Bố';
      case 'mother':
        return 'Mẹ';
      case 'guardian':
        return 'Người giám hộ';
      default:
        return value;
    }
  }

  static String _humanize(String value) {
    final String normalized = value
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (Match match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
    if (normalized.isEmpty) return value;
    return normalized[0].toUpperCase() + normalized.substring(1);
  }
}

class _DisplayEntry {
  final String label;
  final String value;

  const _DisplayEntry(this.label, this.value);
}
