import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vnu_core/modules/paht_v2/ktx/models/ktx_issue_models.dart';
import 'package:vnu_core/modules/paht_v2/ktx/repository/ktx_issue_repository.dart';
import 'package:vnu_core/screens/vcore_select_location_view.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';

class KtxIssueCreateView extends StatefulWidget {
  const KtxIssueCreateView({super.key});

  @override
  State<KtxIssueCreateView> createState() => _KtxIssueCreateViewState();
}

class _KtxIssueCreateViewState extends State<KtxIssueCreateView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final KtxIssueRepository _repository = KtxIssueRepository();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  KtxIssueMeta? _meta;
  int? _type;
  int? _priority;
  LatLng? _location;
  List<XFile> _images = <XFile>[];

  bool _loadingMeta = true;
  bool _submitting = false;
  String? _metaError;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() {
      _loadingMeta = true;
      _metaError = null;
    });

    try {
      final KtxIssueMeta meta = await _repository.getMeta();
      if (!mounted) return;
      setState(() {
        _meta = meta;
        _loadingMeta = false;
        if (_type == null && meta.types.isNotEmpty) {
          _type = meta.types.first.value;
        }
      });
    } on KtxIssueApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingMeta = false;
        _metaError = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingMeta = false;
        _metaError = error.toString();
      });
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> picked =
        await _picker.pickMultiImage(imageQuality: 90);
    if (picked.isEmpty) return;

    await _appendImages(picked);
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (photo == null) return;

    await _appendImages(<XFile>[photo]);
  }

  Future<void> _appendImages(List<XFile> picked) async {
    final List<XFile> accepted = <XFile>[];
    final List<String> tooLarge = <String>[];

    for (final XFile image in picked) {
      final int length = await image.length();
      if (length > KtxIssueRepository.maxImageBytes) {
        tooLarge.add(image.name);
        continue;
      }

      final bool duplicated = _images.any(
        (XFile current) => current.path == image.path,
      );
      if (!duplicated) {
        accepted.add(image);
      }
    }

    if (!mounted) return;

    setState(() {
      _images = <XFile>[..._images, ...accepted];
    });

    if (tooLarge.isNotEmpty) {
      _showMessage(
        'Bỏ qua ${tooLarge.length} ảnh vượt quá 5 MB.',
        warning: true,
      );
    }
  }

  Future<void> _selectLocation() async {
    final LatLng? selected = await Get.to<LatLng>(
      () => VcoreSelectLocationView(
        selectedLocation: _location,
      ),
    );

    if (selected == null || !mounted) return;
    setState(() => _location = selected);
  }

  void _clearLocation() {
    setState(() => _location = null);
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final int? type = _type;
    if (type == null) {
      _showMessage('Vui lòng chọn loại phản ánh.', warning: true);
      return;
    }

    final LatLng? location = _location;
    final String? mapUrl = location == null
        ? null
        : 'https://maps.google.com/?q='
            '${location.latitude},${location.longitude}';

    setState(() => _submitting = true);

    try {
      await _repository.createIssue(
        title: _titleController.text,
        description: _descriptionController.text,
        type: type,
        priority: _priority,
        latitude: location?.latitude,
        longitude: location?.longitude,
        address: _addressController.text,
        mapUrl: mapUrl,
        images: _images,
      );

      if (!mounted) return;
      _showMessage('Đã gửi phản ánh tới Ký túc xá.');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (mounted) {
        Get.back(result: true);
      }
    } on KtxIssueApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message, warning: true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString(), warning: true);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showMessage(String message, {bool warning = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              warning ? const Color(0xFF9B6B00) : const Color(0xFF078B3E),
        ),
      );
  }

  InputDecoration _decoration(
    String label, {
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E6E2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E6E2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF078B3E),
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VcoreModuleScaffold(
      title: 'Tạo phản ánh KTX',
      body: Stack(
        children: <Widget>[
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
              children: <Widget>[
                const _HeaderCard(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  maxLength: 255,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoration(
                    'Tiêu đề *',
                    hint: 'Ví dụ: Đèn hành lang tầng 4 bị hỏng',
                  ),
                  validator: (String? value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Vui lòng nhập tiêu đề.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 5,
                  maxLines: 9,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoration(
                    'Nội dung phản ánh *',
                    hint: 'Mô tả rõ tình trạng, vị trí và thời điểm phát hiện.',
                  ),
                  validator: (String? value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Vui lòng nhập nội dung phản ánh.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildMetaFields(),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  maxLength: 255,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoration(
                    'Địa chỉ / vị trí mô tả',
                    hint: 'Ví dụ: Sảnh tầng 1, tòa D2',
                  ),
                ),
                const SizedBox(height: 2),
                _LocationCard(
                  location: _location,
                  onSelect: _selectLocation,
                  onClear: _clearLocation,
                ),
                const SizedBox(height: 16),
                _ImagePickerSection(
                  images: _images,
                  onPick: _pickImages,
                  onCamera: _takePhoto,
                  onRemove: (int index) {
                    setState(() => _images.removeAt(index));
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _submitting || _loadingMeta || _meta == null
                        ? null
                        : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _submitting ? 'Đang gửi...' : 'Gửi phản ánh KTX',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF078B3E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_submitting)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x22000000),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetaFields() {
    if (_loadingMeta) {
      return  Container(
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: CircularProgressIndicator(
          color: Color(0xFF078B3E),
          strokeWidth: 2.4,
        ),
      );
    }

    final String? error = _metaError;
    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8EB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0DCAA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              error,
              style: const TextStyle(
                color: Color(0xFF795A17),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 7),
            TextButton.icon(
              onPressed: _loadMeta,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tải lại danh mục'),
            ),
          ],
        ),
      );
    }

    final KtxIssueMeta meta = _meta ?? const KtxIssueMeta();

    return Column(
      children: <Widget>[
        DropdownButtonFormField<int>(
          value: _type,
          isExpanded: true,
          decoration: _decoration('Loại phản ánh *'),
          items: meta.types
              .map(
                (KtxIssueOption item) => DropdownMenuItem<int>(
                  value: item.value,
                  child: Text(item.label),
                ),
              )
              .toList(),
          onChanged: (int? value) => setState(() => _type = value),
          validator: (int? value) {
            if (value == null) return 'Vui lòng chọn loại phản ánh.';
            return null;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _priority ?? 0,
          isExpanded: true,
          decoration: _decoration('Độ ưu tiên'),
          items: <DropdownMenuItem<int>>[
            const DropdownMenuItem<int>(
              value: 0,
              child: Text('Không đặt ưu tiên'),
            ),
            ...meta.priorities.map(
              (KtxIssueOption item) => DropdownMenuItem<int>(
                value: item.value,
                child: Text(item.label),
              ),
            ),
          ],
          onChanged: (int? value) {
            setState(() {
              _priority = value == null || value == 0 ? null : value;
            });
          },
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7EBDD)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF078B3E),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Phản ánh này được gửi trực tiếp tới hệ thống Ký túc xá. '
              'Loại phản ánh và độ ưu tiên được lấy động từ API KTX.',
              style: TextStyle(
                color: Color(0xFF44604D),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final LatLng? location;
  final VoidCallback onSelect;
  final VoidCallback onClear;

  const _LocationCard({
    required this.location,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final LatLng? point = location;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E6E2)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF078B3E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: point == null
                ? const Text(
                    'Chưa chọn vị trí trên bản đồ',
                    style: TextStyle(
                      color: Color(0xFF727E76),
                      fontSize: 12.5,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Đã gắn vị trí',
                        style: TextStyle(
                          color: Color(0xFF26312A),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${point.latitude.toStringAsFixed(6)}, '
                        '${point.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Color(0xFF728078),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
          ),
          TextButton(
            onPressed: onSelect,
            child: Text(point == null ? 'Chọn' : 'Đổi'),
          ),
          if (point != null)
            IconButton(
              tooltip: 'Bỏ vị trí',
              onPressed: onClear,
              icon: const Icon(
                Icons.close_rounded,
                color: Color(0xFF8A948E),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImagePickerSection extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onPick;
  final VoidCallback onCamera;
  final ValueChanged<int> onRemove;

  const _ImagePickerSection({
    required this.images,
    required this.onPick,
    required this.onCamera,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E6E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Hình ảnh đính kèm',
            style: TextStyle(
              color: Color(0xFF26312A),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mỗi ảnh tối đa 5 MB.',
            style: TextStyle(
              color: Color(0xFF7C887F),
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPick,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Chọn ảnh'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Chụp ảnh'),
                ),
              ),
            ],
          ),
          if (images.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (BuildContext context, int index) {
                  final XFile image = images[index];
                  return Stack(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(image.path),
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => onRemove(index),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
