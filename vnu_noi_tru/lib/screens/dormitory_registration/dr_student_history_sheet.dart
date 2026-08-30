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
                      _buildReceiptSection(receipts),
                      const SizedBox(height: 10),
                      _buildIssueSection(issues),
                      const SizedBox(height: 10),
                      _buildHistorySection(histories),
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
            'Họ và tên',
            student,
            const <String>['fullName', 'full_name'],
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
            const <String>['dob', 'dateOfBirth', 'date_of_birth'],
            dateOnly: true,
          ),
          _entry(
            'Điện thoại',
            student,
            const <String>['phoneNumber', 'phone_number', 'phone'],
          ),
          _entry('Email', student, const <String>['email']),
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
            'Số giấy tờ',
            student,
            const <String>['identityNo', 'identity_no'],
            transform: _maskIdentityNumber,
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
          _entry(
            'Quốc tịch',
            student,
            const <String>['nationality', 'national', 'country'],
          ),
        ]),
        const SizedBox(height: 12),
        _groupTitle('Địa chỉ và thông tin lưu trú'),
        ..._rows(<_DisplayEntry>[
          _entry(
            'Thường trú',
            student,
            const <String>[
              'permanentAddress',
              'permanent_address',
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
            const <String>[
              'temporaryAddress',
              'temporary_address',
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
          _entry(
            'Trường',
            student,
            const <String>[
              'universityName',
              'university_name',
              'university',
            ],
          ),
          _entry(
            'Lớp',
            student,
            const <String>['className', 'class_name', 'class'],
          ),
          _entry('Khoa', student, const <String>['faculty']),
          _entry('Ngành', student, const <String>['major']),
          _entry(
            'Niên khóa',
            student,
            const <String>['academicYear', 'academic_year'],
          ),
          _entry(
            'Hệ đào tạo',
            student,
            const <String>['educationSystem', 'education_system', 'system'],
          ),
          _entry(
            'Bậc đào tạo',
            student,
            const <String>['educationLevel', 'education_level', 'level'],
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
      const <String>[
        'relationshipLabel',
        'relationship_label',
        'relationship',
      ],
    );

    return _itemContainer(
      title: relationship.isEmpty ? 'Người thân ${index + 1}' : relationship,
      children: _rows(<_DisplayEntry>[
        _entry(
          'Quan hệ',
          member,
          const <String>[
            'relationshipLabel',
            'relationship_label',
            'relationship',
          ],
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
          const <String>['phoneNumber', 'phone_number', 'phone'],
        ),
      ]),
    );
  }

  Map<String, dynamic> _enrichAccommodationDisplayMap(dynamic rawValue) {
    final Map<String, dynamic> value = Map<String, dynamic>.from(_asMap(rawValue));
    if (value.isEmpty) return value;

    bool missing(String key) {
      final dynamic current = value[key];
      return current == null || (current is String && current.trim().isEmpty);
    }

    final Map<String, dynamic> room = _asMap(value['room']);
    final Map<String, dynamic> dormitory = _asMap(value['dormitory']);
    final Map<String, dynamic> roomType = _asMap(
      value['room_type'] ?? value['roomType'],
    );
    final Map<String, dynamic> period = _asMap(
      value['registration_period'] ?? value['registrationPeriod'],
    );

    // Production contract added room.building_name. This is the source of
    // truth for the building shown to the student.
    if (missing('buildingName')) {
      final dynamic buildingName = room['building_name'] ?? room['buildingName'];
      if (buildingName != null && buildingName.toString().trim().isNotEmpty) {
        value['buildingName'] = buildingName.toString().trim();
      }
    }

    if (missing('assignedRoom')) {
      final dynamic roomNumber =
          room['room_number'] ?? room['roomNumber'] ?? room['room_no'];
      if (roomNumber != null && roomNumber.toString().trim().isNotEmpty) {
        value['assignedRoom'] = roomNumber.toString().trim();
      }
    }

    if (missing('dormitoryName')) {
      final dynamic name = dormitory['name'];
      if (name != null && name.toString().trim().isNotEmpty) {
        value['dormitoryName'] = name.toString().trim();
      }
    }

    if (missing('roomTypeName')) {
      final dynamic name = roomType['name'];
      if (name != null && name.toString().trim().isNotEmpty) {
        value['roomTypeName'] = name.toString().trim();
      }
    }

    if (missing('registrationPeriodName')) {
      final dynamic name = period['name'];
      if (name != null && name.toString().trim().isNotEmpty) {
        value['registrationPeriodName'] = name.toString().trim();
      }
    }

    return value;
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
              final Map<String, dynamic> value =
                  _enrichAccommodationDisplayMap(item.value);
              final String periodName = _text(
                value,
                const <String>[
                  'registrationPeriodName',
                  'registration_period_name',
                ],
              );
              final String dormitoryName = _text(
                value,
                const <String>[
                  'dormitoryName',
                  'dormitory_name',
                  'dormitory',
                ],
              );
              final String title = periodName.isNotEmpty
                  ? periodName
                  : dormitoryName.isNotEmpty
                      ? dormitoryName
                      : 'Hồ sơ nội trú ${item.key + 1}';

              return _itemContainer(
                title: title,
                badge: _statusText(
                  _firstValue(
                    value,
                    const <String>[
                      'statusLabel',
                      'status_label',
                      'status',
                    ],
                  ),
                ),
                children: _rows(<_DisplayEntry>[
                  _entry(
                    'Đợt đăng ký',
                    value,
                    const <String>[
                      'registrationPeriodName',
                      'registration_period_name',
                    ],
                  ),
                  _entry(
                    'Trạng thái',
                    value,
                    const <String>[
                      'statusLabel',
                      'status_label',
                      'status',
                    ],
                    transform: _statusLabel,
                  ),
                  _entry(
                    'Ký túc xá',
                    value,
                    const <String>[
                      'dormitoryName',
                      'dormitory_name',
                      'dormitory',
                    ],
                  ),
                  _entry(
                    'Tòa nhà',
                    value,
                    const <String>[
                      'buildingName',
                      'building_name',
                      'building',
                    ],
                  ),
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
                    const <String>[
                      'assignedRoom',
                      'assigned_room',
                      'roomNumber',
                      'room_number',
                      'room',
                    ],
                  ),
                  _entry(
                    'Đối tượng ưu tiên',
                    value,
                    const <String>[
                      'priorityObjectName',
                      'priority_object_name',
                      'priorityObject',
                      'priority_object',
                    ],
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
                    'Ngày đăng ký',
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
                const <String>[
                  'studentName',
                  'student_name',
                  'fullName',
                  'full_name',
                  'student',
                ],
              );
              return _itemContainer(
                title: name.isEmpty ? 'Bạn cùng phòng ${item.key + 1}' : name,
                children: _rows(<_DisplayEntry>[
                  _entry(
                    'Họ và tên',
                    value,
                    const <String>[
                      'studentName',
                      'student_name',
                      'fullName',
                      'full_name',
                      'student',
                    ],
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

  Widget _buildReceiptSection(List<dynamic> values) {
    return _sectionCard(
      icon: Icons.receipt_long_rounded,
      title: 'Biên lai',
      subtitle: '${values.length} biên lai',
      children: values.isEmpty
          ? <Widget>[_emptyText('Chưa có biên lai')]
          : values.asMap().entries.map((MapEntry<int, dynamic> item) {
              final Map<String, dynamic> value = _asMap(item.value);
              final String kind = _text(
                value,
                const <String>['kindLabel', 'kind_label', 'kind'],
              );
              final String period = _text(
                value,
                const <String>[
                  'billingPeriodName',
                  'billing_period_name',
                ],
              );
              final String title = kind.isNotEmpty
                  ? kind
                  : period.isNotEmpty
                      ? period
                      : 'Biên lai ${item.key + 1}';

              return _itemContainer(
                title: title,
                badge: _statusText(
                  _firstValue(
                    value,
                    const <String>[
                      'statusLabel',
                      'status_label',
                      'status',
                    ],
                  ),
                ),
                children: _rows(<_DisplayEntry>[
                  _entry(
                    'Kỳ thu',
                    value,
                    const <String>[
                      'billingPeriodName',
                      'billing_period_name',
                    ],
                  ),
                  _entry(
                    'Loại khoản thu',
                    value,
                    const <String>['kindLabel', 'kind_label', 'kind'],
                    transform: _humanize,
                  ),
                  _moneyEntry(
                    'Tổng tiền',
                    value,
                    const <String>['totalAmount', 'total_amount', 'amount'],
                  ),
                  _entry(
                    'Trạng thái',
                    value,
                    const <String>[
                      'statusLabel',
                      'status_label',
                      'status',
                    ],
                    transform: _paymentStatusLabel,
                  ),
                  _dateEntry(
                    'Hạn thanh toán',
                    value,
                    const <String>['dueDate', 'due_date'],
                    dateOnly: true,
                  ),
                  _dateEntry(
                    'Đã thanh toán lúc',
                    value,
                    const <String>['paidAt', 'paid_at'],
                  ),
                  _dateEntry(
                    'Ngày tạo',
                    value,
                    const <String>['createdAt', 'created_at'],
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
              return _itemContainer(
                title: title.isEmpty ? 'Phản ánh ${item.key + 1}' : title,
                badge: _statusText(
                  _firstValue(
                    value,
                    const <String>[
                      'statusLabel',
                      'status_label',
                      'status',
                    ],
                  ),
                ),
                children: _rows(<_DisplayEntry>[
                  _entry('Tiêu đề', value, const <String>['title']),
                  _entry(
                    'Nội dung',
                    value,
                    const <String>['description', 'content'],
                  ),
                  _entry(
                    'Loại phản ánh',
                    value,
                    const <String>['typeLabel', 'type_label', 'type'],
                    transform: _humanize,
                  ),
                  _entry(
                    'Mức ưu tiên',
                    value,
                    const <String>[
                      'priorityLabel',
                      'priority_label',
                      'priority',
                    ],
                    transform: _humanize,
                  ),
                  _entry(
                    'Trạng thái',
                    value,
                    const <String>[
                      'statusLabel',
                      'status_label',
                      'status',
                    ],
                    transform: _statusLabel,
                  ),
                  _entry(
                    'Người xử lý',
                    value,
                    const <String>[
                      'assignedToName',
                      'assigned_to_name',
                      'handlerName',
                      'handler_name',
                      'assignedTo',
                      'assigned_to',
                    ],
                    hideNumericOnly: true,
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

  Widget _buildHistorySection(List<dynamic> values) {
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
              final String action = _text(value, const <String>['action']);
              final String type = _text(value, const <String>['type']);
              final dynamic rawData = _firstValue(value, const <String>['data']);
              final List<_DisplayEntry> eventDetails =
                  _eventDetailEntries(rawData);

              return _itemContainer(
                title: action.isNotEmpty
                    ? _actionLabel(action)
                    : type.isNotEmpty
                        ? _eventTypeLabel(type)
                        : 'Cập nhật hồ sơ',
                badge: _formatDate(
                  _firstValue(
                    value,
                    const <String>['created_at', 'createdAt'],
                  ),
                ),
                children: <Widget>[
                  ..._rows(<_DisplayEntry>[
                    _entry(
                      'Loại sự kiện',
                      value,
                      const <String>['type'],
                      transform: _eventTypeLabel,
                    ),
                    _entry(
                      'Hành động',
                      value,
                      const <String>['action'],
                      transform: _actionLabel,
                    ),
                    _entry(
                      'Người thực hiện',
                      value,
                      const <String>[
                        'performedByName',
                        'performed_by_name',
                        'performer',
                        'performedBy',
                        'performed_by',
                      ],
                      hideNumericOnly: true,
                    ),
                    _entry('Ghi chú', value, const <String>['note']),
                    _dateEntry(
                      'Thời gian',
                      value,
                      const <String>['created_at', 'createdAt'],
                    ),
                    ...eventDetails,
                  ]),
                ],
              );
            }).toList(),
    );
  }

  Map<String, dynamic> _normalizeHistoryData(dynamic rawData) {
    final Map<String, dynamic> direct = _asMap(rawData);
    if (direct.isNotEmpty) return direct;

    // OpenAPI allows StudentHistory.data to be array|null, while production
    // also returns an object. Merge map items so KTX/building/room metadata is
    // still visible in the history sheet.
    if (rawData is Iterable && rawData is! String) {
      final Map<String, dynamic> merged = <String, dynamic>{};
      for (final dynamic item in rawData) {
        merged.addAll(_asMap(item));
      }
      return merged;
    }

    return <String, dynamic>{};
  }

  List<_DisplayEntry> _eventDetailEntries(dynamic rawData) {
    final Map<String, dynamic> value = _normalizeHistoryData(rawData);
    if (value.isEmpty) {
      return <_DisplayEntry>[];
    }

    return <_DisplayEntry>[
      _entry(
        'Trạng thái hồ sơ',
        value,
        const <String>[
          'statusLabel',
          'status_label',
          'newStatusLabel',
          'new_status_label',
          'toStatusLabel',
          'to_status_label',
          'status',
          'newStatus',
          'new_status',
          'toStatus',
          'to_status',
        ],
        transform: _statusLabel,
      ),
      _entry(
        'Ký túc xá',
        value,
        const <String>[
          'dormitoryName',
          'dormitory_name',
          'dormitory',
        ],
      ),
      _entry(
        'Tòa nhà',
        value,
        const <String>[
          'buildingName',
          'building_name',
          'building',
          'buildingCode',
          'building_code',
          'blockName',
          'block_name',
          'toa',
        ],
      ),
      _entry(
        'Đợt đăng ký',
        value,
        const <String>[
          'registrationPeriodName',
          'registration_period_name',
          'periodName',
          'period_name',
        ],
      ),
      _entry(
        'Phòng',
        value,
        const <String>[
          'assignedRoom',
          'assigned_room',
          'roomNumber',
          'room_number',
          'room',
        ],
      ),
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
        'Đối tượng ưu tiên',
        value,
        const <String>[
          'priorityObjectName',
          'priority_object_name',
          'priorityObject',
          'priority_object',
        ],
      ),
      _entry(
        'Trạng thái yêu cầu',
        value,
        const <String>[
          'requestStatusLabel',
          'request_status_label',
          'requestStatus',
          'request_status',
        ],
        transform: _requestStatusLabel,
      ),
      _entry(
        'Lý do',
        value,
        const <String>['reason', 'reasonStay', 'reason_stay', 'message'],
      ),
    ];
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
    bool hideNumericOnly = false,
  }) {
    String value = _text(source, keys);
    if (hideNumericOnly && _isNumericText(value)) {
      value = '';
    }
    if (value.isNotEmpty && transform != null) {
      value = transform(value);
    }
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
    if (number == null) {
      return _DisplayEntry(label, '');
    }

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
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      final Map<String, dynamic> result = <String, dynamic>{};
      value.forEach((dynamic key, dynamic item) {
        result[key.toString()] = item;
      });
      return result;
    }
    return <String, dynamic>{};
  }

  static dynamic _firstValue(Map<String, dynamic> source, List<String> keys) {
    for (final String key in keys) {
      if (!source.containsKey(key)) {
        continue;
      }
      final dynamic value = source[key];
      if (value == null) {
        continue;
      }
      if (value is String && value.trim().isEmpty) {
        continue;
      }
      return value;
    }
    return null;
  }

  static String _text(Map<String, dynamic> source, List<String> keys) {
    return _friendlyValue(_firstValue(source, keys));
  }

  static String _friendlyValue(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is Map) {
      final Map<String, dynamic> map = _asMap(value);
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
        'relationshipLabel',
        'relationship_label',
        'abbreviation',
      ];

      for (final String key in preferredKeys) {
        final dynamic nested = map[key];
        if (nested == null || identical(nested, value)) {
          continue;
        }
        final String result = _friendlyValue(nested);
        if (result.isNotEmpty && !_isNumericText(result)) {
          return result;
        }
      }
      return '';
    }

    if (value is Iterable && value is! String) {
      final List<String> items = value
          .map(_friendlyValue)
          .where((String item) => item.isNotEmpty)
          .toSet()
          .toList();
      return items.join(', ');
    }

    if (value is bool) {
      return value ? 'Có' : 'Không';
    }

    return value.toString().trim();
  }

  static List<dynamic> _listValue(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    final dynamic value = _firstValue(source, keys);
    if (value is List) {
      return List<dynamic>.from(value);
    }
    if (value is Iterable && value is! String) {
      return List<dynamic>.from(value);
    }
    return <dynamic>[];
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.tryParse(value.toString());
  }

  static String _formatDate(dynamic value, {bool dateOnly = false}) {
    final DateTime? date = _parseDate(value);
    if (date == null) {
      return '';
    }
    return DateFormat(dateOnly ? 'dd/MM/yyyy' : 'dd/MM/yyyy HH:mm')
        .format(date.toLocal());
  }

  static String _maskIdentityNumber(String value) {
    final String normalized = value.replaceAll(RegExp(r'\s+'), '');
    if (normalized.length <= 4) {
      return normalized;
    }
    return '•••• •••• ${normalized.substring(normalized.length - 4)}';
  }

  static String _statusText(dynamic value) {
    final String text = _friendlyValue(value);
    return text.isEmpty ? '' : _statusLabel(text);
  }

  static String _statusLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'draft':
        return 'Bản nháp';
      case 'pending':
      case 'waiting':
      case 'submitted':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      case 'assigned':
      case 'room_assigned':
        return 'Đã xếp phòng';
      case 'active':
      case 'checked_in':
      case 'checkin':
        return 'Đang lưu trú';
      case 'checkout':
      case 'checked_out':
        return 'Đã trả phòng';
      case 'cancelled':
      case 'canceled':
        return 'Đã hủy';
      case 'completed':
      case 'success':
        return 'Hoàn thành';
      default:
        return _humanize(value);
    }
  }

  static String _paymentStatusLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'pending':
      case 'waiting':
      case 'submitted':
        return 'Chờ xác nhận';
      case 'paid':
      case 'completed':
      case 'success':
        return 'Đã thanh toán';
      case 'rejected':
        return 'Minh chứng bị từ chối';
      case 'unpaid':
      case 'new':
        return 'Chưa thanh toán';
      case 'overdue':
        return 'Quá hạn';
      default:
        return _statusLabel(value);
    }
  }

  static String _requestStatusLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'none':
        return 'Không có yêu cầu';
      case 'change_room':
        return 'Yêu cầu chuyển phòng';
      case 'checkout':
        return 'Yêu cầu trả phòng';
      case 'pending':
        return 'Đang chờ xử lý';
      case 'approved':
        return 'Đã chấp thuận';
      case 'rejected':
        return 'Đã từ chối';
      default:
        return _humanize(value);
    }
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

  static String _relationshipLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'father':
        return 'Bố';
      case 'mother':
        return 'Mẹ';
      case 'guardian':
        return 'Người giám hộ';
      default:
        return _humanize(value);
    }
  }

  static String _actionLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'submitted':
        return 'Đã nộp hồ sơ';
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
        return _humanize(value);
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
        return _humanize(value);
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
    if (normalized.isEmpty) {
      return value;
    }
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  static bool _isNumericText(String value) {
    return value.trim().isNotEmpty && num.tryParse(value.trim()) != null;
  }
}

class _DisplayEntry {
  final String label;
  final String value;

  const _DisplayEntry(this.label, this.value);
}
