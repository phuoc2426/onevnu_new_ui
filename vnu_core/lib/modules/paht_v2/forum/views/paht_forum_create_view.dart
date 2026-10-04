import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vnu_core/constants/enum.dart';
import 'package:vnu_core/models/file_upload_model.dart';
import 'package:vnu_core/modules/paht_v2/forum/models/paht_forum_models.dart';
import 'package:vnu_core/modules/paht_v2/forum/repository/paht_forum_repository.dart';
import 'package:vnu_core/modules/paht_v2/forum/views/paht_forum_detail_view.dart';
import 'package:vnu_core/modules/paht_v2/forum/widgets/paht_topic_visual.dart';
import 'package:vnu_core/modules/paht_v2/ktx/models/ktx_issue_models.dart';
import 'package:vnu_core/modules/paht_v2/ktx/repository/ktx_issue_repository.dart';
import 'package:vnu_core/themes/app_theme.dart';
import 'package:vnu_core/widgets/vcore_action_dialog.dart';
import 'package:vnu_core/widgets/vcore_module_scaffold.dart';
import 'package:vnu_core/widgets/vcore_notice_toast.dart';

class PahtForumCreateView extends StatefulWidget {
  final String? preselectTopicCode;
  final bool? ktxEligible;

  const PahtForumCreateView({
    super.key,
    this.preselectTopicCode,
    this.ktxEligible,
  });

  @override
  State<PahtForumCreateView> createState() => _PahtForumCreateViewState();
}

class _PahtForumCreateViewState extends State<PahtForumCreateView> {
  static const int _maxImages = 3;

  final PahtForumRepository _repository = PahtForumRepository();
  final KtxIssueRepository _ktxRepository = KtxIssueRepository();
  final TextEditingController _contentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final List<FileUploadModel> _files = <FileUploadModel>[];

  Timer? _similarDebounce;
  PahtBootstrap? _bootstrap;
  final Set<int> _topicIds = <int>{};
  int? _areaId;
  String _visibility = 'PUBLIC';
  KtxIssueMeta? _ktxMeta;
  int? _ktxType;
  int? _ktxPriority;
  bool _ktxMetaLoading = false;
  String _ktxMetaError = '';
  PahtCreateResult? _createdPaht;
  int? _createdKtxIssueId;
  List<PahtSimilarHit> _similar = <PahtSimilarHit>[];
  Position? _position;
  bool _loading = true;
  bool _saving = false;
  bool _similarLoading = false;
  bool _gettingLocation = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadBootstrap();
  }

  @override
  void dispose() {
    _similarDebounce?.cancel();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadBootstrap() async {
    try {
      final PahtBootstrap data = await _repository.getBootstrap();
      if (!mounted) return;
      setState(() {
        _bootstrap = data;
        _loading = false;
        final String requested=(widget.preselectTopicCode ?? '').trim().toUpperCase();
        if(requested.isNotEmpty) {
          for(final PahtTopic topic in data.topics) {
            if(topic.code.trim().toUpperCase()==requested &&
                (!_isKtxTopic(topic) || widget.ktxEligible != false)) {
              _topicIds.add(topic.id);
              if(!topic.allowPublic) _visibility='PRIVATE';
              break;
            }
          }
        }
      });
      if (_hasKtxSelected) await _ensureKtxOptions();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  bool _isKtxTopic(PahtTopic topic) => topic.code.trim().toUpperCase() == 'KTX';

  bool get _hasKtxSelected {
    final List<PahtTopic> topics=_bootstrap?.topics ?? <PahtTopic>[];
    return topics.any((PahtTopic topic) => _topicIds.contains(topic.id) && _isKtxTopic(topic));
  }

  Future<bool> _ensureKtxOptions() async {
    if (!_hasKtxSelected) return true;
    if (widget.ktxEligible == false) {
      _removeKtxTopic();
      return false;
    }
    if (widget.ktxEligible == null) {
      final bool eligible=await _ktxRepository.isKtxResidentEligible();
      if(!eligible) {
        _removeKtxTopic();
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chủ đề KTX chỉ dành cho sinh viên đang lưu trú tại KTX.')),
          );
        }
        return false;
      }
    }
    if (_ktxMeta != null) return true;
    if (mounted) setState(() { _ktxMetaLoading=true; _ktxMetaError=''; });
    try {
      final KtxIssueMeta meta=await _ktxRepository.getMeta();
      if(!mounted) return false;
      setState(() {
        _ktxMeta=meta;
        _ktxMetaLoading=false;
        _ktxType ??= meta.types.isEmpty ? null : meta.types.first.value;
      });
      return meta.types.isNotEmpty;
    } catch(error) {
      if(mounted) setState(() { _ktxMetaLoading=false; _ktxMetaError=error.toString(); });
      return false;
    }
  }

  void _removeKtxTopic() {
    final List<PahtTopic> topics=_bootstrap?.topics ?? <PahtTopic>[];
    if(!mounted) return;
    setState(() {
      for(final PahtTopic topic in topics) {
        if(_isKtxTopic(topic)) _topicIds.remove(topic.id);
      }
    });
  }

  String _ktxTitleFromContent(String content) {
    final String normalized=content.trim().replaceAll(RegExp(r'\s+'),' ');
    if(normalized.length <= 120) return normalized;
    return '${normalized.substring(0, 117)}...';
  }

  void _onContentChanged(String value) {
    _similarDebounce?.cancel();
    if (value.trim().length < 15) {
      if (_similar.isNotEmpty || _similarLoading) {
        setState(() {
          _similar = <PahtSimilarHit>[];
          _similarLoading = false;
        });
      }
      return;
    }

    _similarDebounce = Timer(const Duration(milliseconds: 650), () async {
      if (!mounted) return;
      setState(() => _similarLoading = true);
      try {
        final List<PahtSimilarHit> hits = await _repository.getSimilar(value);
        if (!mounted) return;
        setState(() {
          _similar = hits;
          _similarLoading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _similar = <PahtSimilarHit>[];
          _similarLoading = false;
        });
      }
    });
  }

  Future<void> _pickFromCamera() async {
    if (_files.length >= _maxImages) return;
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (image != null) await _addAndUpload(<XFile>[image]);
  }

  Future<void> _pickFromGallery() async {
    if (_files.length >= _maxImages) return;
    final List<XFile> images = await _imagePicker.pickMultiImage(
      imageQuality: 88,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (images.isEmpty) return;
    final int remaining = _maxImages - _files.length;
    await _addAndUpload(images.take(remaining).toList(growable: false));
  }

  Future<void> _addAndUpload(List<XFile> images) async {
    for (final XFile image in images) {
      final FileUploadModel model = FileUploadModel(image);
      setState(() => _files.add(model));
      await model.excUpload();
      if (mounted) setState(() {});
    }
  }

  Future<void> _showImageSource() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Chụp ảnh'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Chọn từ thư viện'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _askShareLocation() async {
    if (!mounted) return false;
    final bool? share = await showVcoreActionDialog<bool>(
      context: context,
      title: 'Chia sẻ vị trí khi gửi?',
      content:
          'Vị trí là tùy chọn. Nếu chia sẻ, vị trí chính xác chỉ được gửi cho đơn vị xử lý để tìm đúng nơi phản ánh và không hiển thị công khai trên Cộng đồng.',
      leadingIcon: Icons.location_on_outlined,
      actions: const <VcoreDialogAction<bool>>[
        VcoreDialogAction<bool>(
          label: 'Không chia sẻ vị trí',
          value: false,
          tone: VcoreDialogActionTone.secondary,
        ),
        VcoreDialogAction<bool>(
          label: 'Chia sẻ vị trí',
          value: true,
          icon: Icons.my_location_rounded,
          tone: VcoreDialogActionTone.primary,
        ),
      ],
    );
    return share == true;
  }

  Future<bool> _captureLocation() async {
    if (_position != null) return true;
    setState(() => _gettingLocation = true);
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vui lòng bật dịch vụ vị trí rồi thử lại.'),
            action: SnackBarAction(
              label: 'Mở cài đặt',
              onPressed: () { Geolocator.openLocationSettings(); },
            ),
          ),
        );
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ứng dụng chưa được cấp quyền vị trí.'),
            action: permission == LocationPermission.deniedForever
                ? SnackBarAction(
                    label: 'Cài đặt',
                    onPressed: () { Geolocator.openAppSettings(); },
                  )
                : null,
          ),
        );
        return false;
      }

      final Position position = await Geolocator.getCurrentPosition();
      if (!mounted) return false;
      setState(() => _position = position);
      return true;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa lấy được vị trí hiện tại. Bạn vẫn có thể gửi phản ánh không kèm vị trí.')),
      );
      return false;
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<bool> _askSendWithoutLocationAfterFailure() async {
    if (!mounted) return false;
    final bool? sendWithoutLocation = await showVcoreActionDialog<bool>(
      context: context,
      title: 'Chưa lấy được vị trí',
      content:
          'Bạn có thể gửi phản ánh ngay mà không kèm vị trí, hoặc quay lại để kiểm tra quyền và dịch vụ vị trí.',
      leadingIcon: Icons.location_off_outlined,
      actions: const <VcoreDialogAction<bool>>[
        VcoreDialogAction<bool>(
          label: 'Quay lại',
          value: false,
          tone: VcoreDialogActionTone.secondary,
        ),
        VcoreDialogAction<bool>(
          label: 'Gửi phản ánh không kèm vị trí',
          value: true,
          tone: VcoreDialogActionTone.primary,
        ),
      ],
    );
    return sendWithoutLocation == true;
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_topicIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một chủ đề phản ánh.')),
      );
      return;
    }

    if (_hasKtxSelected) {
      final bool ready=await _ensureKtxOptions();
      if(!mounted) return;
      if(!ready || _ktxType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn loại phản ánh KTX.')),
        );
        return;
      }
    }

    for (final FileUploadModel file in _files) {
      if (file.status.value == UploadFileState.uploading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ảnh đang được tải lên, vui lòng chờ một chút.')),
        );
        return;
      }
      if (file.uploadResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có ảnh chưa tải lên thành công. Vui lòng bỏ ảnh lỗi hoặc thử lại.')),
        );
        return;
      }
    }

    final bool shareLocation = await _askShareLocation();
    if (!mounted) return;

    bool attachLocation = false;
    if (shareLocation) {
      attachLocation = await _captureLocation();
      if (!mounted) return;
      if (!attachLocation) {
        final bool continueWithoutLocation = await _askSendWithoutLocationAfterFailure();
        if (!continueWithoutLocation || !mounted) return;
      }
    }

    final List<Map<String, dynamic>> attachments = _files.map((FileUploadModel file) {
      final result = file.uploadResult!;
      return <String, dynamic>{
        'guid': result.guid ?? '',
        'name': result.name ?? file.source.name,
        'extension': result.extension ?? '',
        'size': result.size ?? 0,
      };
    }).where((Map<String, dynamic> item) => (item['guid'] as String).isNotEmpty).toList(growable: false);

    setState(() => _saving = true);
    try {
      final PahtCreateResult result = _createdPaht ?? await _repository.createFeedback(
        topicIds: _topicIds.toList(growable: false),
        areaId: _areaId,
        content: _contentController.text,
        visibility: _visibility,
        latitude: attachLocation ? _position?.latitude : null,
        longitude: attachLocation ? _position?.longitude : null,
        publicLocationMode: 'HIDDEN',
        attachments: attachments,
      );
      _createdPaht=result;

      if (_hasKtxSelected) {
        final int type=_ktxType!;
        int? issueId=_createdKtxIssueId;
        if(issueId == null) {
          final String content=_contentController.text.trim();
          final KtxIssue issue=await _ktxRepository.createIssue(
            title:_ktxTitleFromContent(content),
            description:content,
            type:type,
            priority:_ktxPriority,
            latitude:attachLocation ? _position?.latitude : null,
            longitude:attachLocation ? _position?.longitude : null,
            images:_files.map((FileUploadModel file) => file.source).toList(growable:false),
          );
          issueId=issue.id;
          if (issueId <= 0) {
            throw const KtxIssueApiException(
              'KTX đã nhận phản ánh nhưng không trả issue id hợp lệ.',
            );
          }
          _createdKtxIssueId=issueId;
        }
        await _repository.linkKtxIssue(result.guid,issueId);
      }
      if (!mounted) return;
      showVcoreNotice(
        context: context,
        title: 'Gửi phản ánh thành công',
        message: result.code.isEmpty
            ? 'Đã gửi thành công phản ánh.'
            : 'Đã gửi thành công phản ánh với mã phản ánh là ${result.code}.',
        tone: VcoreNoticeTone.success,
        duration: const Duration(milliseconds: 3200),
      );
      // Cho animation notice bắt đầu trước khi đóng màn hình tạo. Notice dùng
      // root overlay nên tiếp tục hiển thị mượt trên màn hình quay về.
      await Future<void>.delayed(const Duration(milliseconds: 140));
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showVcoreNotice(
        context: context,
        title: _createdPaht != null && _hasKtxSelected
            ? 'Đã lưu OneVNU, chưa gửi xong KTX'
            : 'Chưa gửi được phản ánh',
        message: _createdPaht != null && _hasKtxSelected
            ? '${error.toString()}\nNhấn Gửi lại để chỉ thử lại phần KTX; phản ánh OneVNU sẽ không bị tạo thêm.'
            : error.toString(),
        tone: VcoreNoticeTone.error,
        duration: const Duration(milliseconds: 3400),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return VcoreModuleScaffold(
      title: 'Tạo phản ánh',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _buildError()
              : _buildForm(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFA84444)),
            const SizedBox(height: 10),
            Text(_error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadBootstrap, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final List<PahtTopic> allTopics = _bootstrap?.topics ?? <PahtTopic>[];
    final List<PahtTopic> topics = allTopics
        .where((PahtTopic topic) => !_isKtxTopic(topic) || widget.ktxEligible != false)
        .toList(growable:false);
    final List<PahtArea> areas = _bootstrap?.areas ?? <PahtArea>[];
    final bool selectedTopicAllowsPublic = topics
        .where((PahtTopic topic) => _topicIds.contains(topic.id))
        .every((PahtTopic topic) => topic.allowPublic);

    if (!selectedTopicAllowsPublic && _visibility == 'PUBLIC') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _visibility = 'PRIVATE');
      });
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: <Widget>[
          const _FieldLabel('Chọn chủ đề', isRequired: true),
          const SizedBox(height: 9),
          _buildTopicSelector(topics),
          const SizedBox(height: 6),
          Text(
            _topicIds.isEmpty
                ? 'Chọn một hoặc nhiều chủ đề · tối đa 5 chủ đề'
                : 'Đã chọn ${_topicIds.length} chủ đề · chạm lại để bỏ chọn',
            style: const TextStyle(
              fontSize: 11.2,
              color: Color(0xFF6C786F),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_hasKtxSelected) ...<Widget>[
            const SizedBox(height: 14),
            _buildKtxOptions(),
          ],
          const SizedBox(height: 18),
          const _FieldLabel('Nội dung phản ánh', isRequired: true),
          const SizedBox(height: 7),
          TextFormField(
            controller: _contentController,
            onChanged: _onContentChanged,
            minLines: 5,
            maxLines: 9,
            maxLength: 4000,
            decoration: _inputDecoration('Mô tả vấn đề cần được xử lý...').copyWith(alignLabelWithHint: true),
            validator: (String? value) {
              final String text = value?.trim() ?? '';
              if (text.isEmpty) return 'Vui lòng nhập nội dung phản ánh';
              if (text.length < 10) return 'Nội dung cần ít nhất 10 ký tự';
              return null;
            },
          ),
          if (_similarLoading || _similar.isNotEmpty) ...<Widget>[
            _buildSimilar(),
            const SizedBox(height: 14),
          ],
          const _FieldLabel('Ảnh hiện trường'),
          const SizedBox(height: 7),
          _buildImages(),
          const SizedBox(height: 16),
          const _FieldLabel('Khu vực / đơn vị'),
          const SizedBox(height: 7),
          DropdownButtonFormField<int?>(
            value: _areaId,
            isExpanded: true,
            items: <DropdownMenuItem<int?>>[
              const DropdownMenuItem<int?>(value: null, child: Text('Không chọn khu vực cụ thể')),
              ...areas.map(
                (PahtArea area) => DropdownMenuItem<int?>(
                  value: area.id,
                  child: Text(area.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (int? value) => setState(() => _areaId = value),
            decoration: _inputDecoration('Chọn khu vực'),
          ),
          const SizedBox(height: 16),
          _buildLocationStatus(),
          const SizedBox(height: 16),
          if (selectedTopicAllowsPublic)
            _buildVisibility(),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: AppTheme.colorMain),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_saving ? 'Đang gửi...' : 'Gửi phản ánh'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicSelector(List<PahtTopic> topics) {
    if (topics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE1E7E3)),
        ),
        child: const Text(
          'Chưa có chủ đề để lựa chọn.',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF647168)),
        ),
      );
    }

    final int columnCount = (topics.length / 2).ceil();
    final double topicTileWidth =
        (MediaQuery.sizeOf(context).width * .64).clamp(205.0, 240.0).toDouble();
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: columnCount,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int columnIndex) {
          final int firstIndex = columnIndex * 2;
          final int secondIndex = firstIndex + 1;
          return SizedBox(
            width: topicTileWidth,
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 54,
                  child: _TopicSelectTile(
                    topic: topics[firstIndex],
                    selected: _topicIds.contains(topics[firstIndex].id),
                    onTap: () => _selectTopic(topics[firstIndex]),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 54,
                  child: secondIndex < topics.length
                      ? _TopicSelectTile(
                          topic: topics[secondIndex],
                          selected: _topicIds.contains(topics[secondIndex].id),
                          onTap: () => _selectTopic(topics[secondIndex]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectTopic(PahtTopic topic) async {
    if (_topicIds.contains(topic.id)) {
      setState(() => _topicIds.remove(topic.id));
      return;
    }
    if (_topicIds.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn có thể chọn tối đa 5 chủ đề cho một phản ánh.')),
      );
      return;
    }
    if(_isKtxTopic(topic)) {
      if(widget.ktxEligible == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chủ đề KTX chỉ dành cho sinh viên đang lưu trú tại KTX.')),
        );
        return;
      }
      setState(() => _topicIds.add(topic.id));
      final bool ready=await _ensureKtxOptions();
      if(!ready && mounted && _ktxMetaError.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_ktxMetaError)),
        );
      }
      return;
    }
    setState(() {
      _topicIds.add(topic.id);
      if (!topic.allowPublic) _visibility = 'PRIVATE';
    });
  }

  Widget _buildKtxOptions() {
    if(_ktxMetaLoading) {
      return const _KtxInfoBox(
        child: Row(children:<Widget>[
          SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)),
          SizedBox(width:10),
          Text('Đang tải danh mục KTX...'),
        ]),
      );
    }
    if(_ktxMetaError.isNotEmpty) {
      return _KtxInfoBox(
        child: Row(children:<Widget>[
          Expanded(child:Text(_ktxMetaError,style:const TextStyle(fontSize:12,color:Color(0xFF8A5B13)))),
          TextButton(onPressed:_ensureKtxOptions,child:const Text('Thử lại')),
        ]),
      );
    }
    final KtxIssueMeta meta=_ktxMeta ?? const KtxIssueMeta();
    return _KtxInfoBox(
      child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,
        children:<Widget>[
          const Text('Thông tin gửi sang KTX',style:TextStyle(fontWeight:FontWeight.w800,fontSize:13)),
          const SizedBox(height:8),
          DropdownButtonFormField<int>(
            value:_ktxType,
            isExpanded:true,
            decoration:_inputDecoration('Loại phản ánh KTX'),
            items:meta.types.map((KtxIssueOption item)=>DropdownMenuItem<int>(value:item.value,child:Text(item.label))).toList(),
            onChanged:(int? value)=>setState(()=>_ktxType=value),
            validator:(int? value)=>_hasKtxSelected && value==null ? 'Vui lòng chọn loại phản ánh KTX' : null,
          ),
          const SizedBox(height:10),
          DropdownButtonFormField<int>(
            value:_ktxPriority ?? 0,
            isExpanded:true,
            decoration:_inputDecoration('Độ ưu tiên KTX'),
            items:<DropdownMenuItem<int>>[
              const DropdownMenuItem<int>(value:0,child:Text('Không đặt ưu tiên')),
              ...meta.priorities.map((KtxIssueOption item)=>DropdownMenuItem<int>(value:item.value,child:Text(item.label))),
            ],
            onChanged:(int? value)=>setState(()=>_ktxPriority=value==null || value==0 ? null : value),
          ),
          const SizedBox(height:7),
          const Text(
            'MSSV, CCCD, KTX/phòng và ảnh sẽ được lấy từ phiên sinh viên và dữ liệu hiện có của ứng dụng khi gửi sang API KTX.',
            style:TextStyle(fontSize:11.2,height:1.35,color:Color(0xFF647168)),
          ),
        ],
      ),
    );
  }

  Widget _buildImages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_files.isNotEmpty)
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _files.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (BuildContext context, int index) {
                final FileUploadModel model = _files[index];
                return Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(model.source.path),
                        width: 94,
                        height: 94,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: Obx(() {
                        if (model.status.value == UploadFileState.uploading) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${model.processing.value}%',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                          );
                        }
                        if (model.status.value == UploadFileState.failed) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.error_outline_rounded, color: Colors.white),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: InkWell(
                        onTap: () => setState(() => _files.removeAt(index)),
                        child: const CircleAvatar(
                          radius: 11,
                          backgroundColor: Color(0xFF29332E),
                          child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (_files.isNotEmpty) const SizedBox(height: 9),
        OutlinedButton.icon(
          onPressed: _files.length >= _maxImages ? null : _showImageSource,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(_files.isEmpty ? 'Chụp hoặc chọn ảnh' : 'Thêm ảnh (${_files.length}/$_maxImages)'),
        ),
      ],
    );
  }

  Widget _buildLocationStatus() {
    final bool captured = _position != null;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: captured ? const Color(0xFFEAF8F0) : const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: captured ? const Color(0xFFBCE6CE) : const Color(0xFFE1E7E3)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            captured ? Icons.location_on_rounded : Icons.location_on_outlined,
            color: captured ? const Color(0xFF168A52) : const Color(0xFF65736B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              captured
                  ? 'Đã lấy vị trí hiện tại. Khi gửi bạn vẫn có thể chọn chia sẻ hoặc không chia sẻ.'
                  : 'Vị trí là tùy chọn. Khi gửi, bạn sẽ chọn chia sẻ vị trí hoặc gửi phản ánh không kèm vị trí.',
              style: const TextStyle(fontSize: 12.3, height: 1.4, color: Color(0xFF526158)),
            ),
          ),
          if (_gettingLocation)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }

  Widget _buildVisibility() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E7E3)),
      ),
      child: SwitchListTile.adaptive(
        value: _visibility == 'PUBLIC',
        onChanged: (bool value) => setState(() => _visibility = value ? 'PUBLIC' : 'PRIVATE'),
        title: Text(
          _visibility == 'PUBLIC' ? 'Hiển thị trên cộng đồng' : 'Chỉ tôi và đơn vị xử lý',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: const Text('Danh tính người gửi không hiển thị trên cộng đồng.'),
      ),
    );
  }

  Widget _buildSimilar() {
    if (_similarLoading) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1E4B9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Có phản ánh gần giống', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          ..._similar.map(
            (PahtSimilarHit hit) => InkWell(
              onTap: () => Get.to(() => PahtForumDetailView(guid: hit.guid)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.forum_outlined, size: 17, color: Color(0xFF8A6A12)),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        hit.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.2, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
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
        borderSide: BorderSide(color: AppTheme.colorMain.withOpacity(.6)),
      ),
    );
  }
}

class _TopicSelectTile extends StatelessWidget {
  final PahtTopic topic;
  final bool selected;
  final VoidCallback onTap;

  const _TopicSelectTile({
    required this.topic,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final PahtTopicVisual visual = pahtTopicVisual(
      topicId: topic.id,
      topicName: topic.name,
    );

    return Material(
      color: selected ? visual.softColor : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? visual.color.withOpacity(.75)
                  : const Color(0xFFE0E6E2),
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: visual.softColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(visual.icon, size: 17, color: visual.color),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  topic.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? visual.color : const Color(0xFF314038),
                    fontSize: 11.9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (selected) ...<Widget>[
                const SizedBox(width: 4),
                Icon(Icons.check_circle_rounded, size: 15, color: visual.color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KtxInfoBox extends StatelessWidget {
  final Widget child;
  const _KtxInfoBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:const EdgeInsets.all(12),
      decoration:BoxDecoration(
        color:const Color(0xFFF2FAF5),
        borderRadius:BorderRadius.circular(14),
        border:Border.all(color:const Color(0xFFD4E9DB)),
      ),
      child:child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isRequired;

  const _FieldLabel(this.text, {this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Color(0xFF26322B), fontSize: 13, fontWeight: FontWeight.w800),
        children: <InlineSpan>[
          TextSpan(text: text),
          if (isRequired)
            const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFD23A3A))),
        ],
      ),
    );
  }
}
