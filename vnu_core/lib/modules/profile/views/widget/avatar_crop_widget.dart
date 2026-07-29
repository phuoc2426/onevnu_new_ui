import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class AvatarCropWidget extends StatefulWidget {
  final File imageFile;

  /// Dùng khi widget không nhận được kích thước hữu hạn từ parent.
  final double cropSize;

  /// Kích thước ảnh cuối cùng được upload.
  final int outputSize;

  const AvatarCropWidget({
    super.key,
    required this.imageFile,
    this.cropSize = 300,
    this.outputSize = 500,
  });

  @override
  State<AvatarCropWidget> createState() => AvatarCropWidgetState();
}

class AvatarCropWidgetState extends State<AvatarCropWidget> {
  ui.Image? _image;
  Size? _imageSize;
  Size? _viewportSize;

  bool _isLoading = true;
  Object? _loadError;

  /// Scale thực tế: pixel ảnh gốc → pixel trên viewport.
  double _scale = 1;

  /// Scale nhỏ nhất để ảnh luôn phủ kín khung crop.
  double _minScale = 1;

  double _maxScale = 5;

  /// Vị trí góc trái trên của ảnh trong viewport.
  Offset _offset = Offset.zero;

  double _startScale = 1;
  Offset _startOffset = Offset.zero;
  Offset _imagePointAtFocal = Offset.zero;

  double? _scheduledViewportSide;

  bool get _isReady {
    return _image != null &&
        _imageSize != null &&
        _viewportSize != null &&
        !_isLoading;
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final decodedImage = frame.image;

      if (!mounted) return;

      setState(() {
        _image = decodedImage;
        _imageSize = Size(
          decodedImage.width.toDouble(),
          decodedImage.height.toDouble(),
        );
        _isLoading = false;

        if (_viewportSize != null) {
          _resetTransformValues();
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = error;
      });
    }
  }

  void _scheduleViewportUpdate(double side) {
    if (side <= 0) return;

    if (_viewportSize?.width == side || _scheduledViewportSide == side) {
      return;
    }

    _scheduledViewportSide = side;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduledViewportSide = null;

      if (!mounted) return;
      if (_viewportSize?.width == side) return;

      setState(() {
        _viewportSize = Size.square(side);

        if (_imageSize != null) {
          _resetTransformValues();
        }
      });
    });
  }

  /// Thiết lập BoxFit.cover ban đầu.
  void _resetTransformValues() {
    if (_imageSize == null || _viewportSize == null) return;

    final imageWidth = _imageSize!.width;
    final imageHeight = _imageSize!.height;
    final viewportWidth = _viewportSize!.width;
    final viewportHeight = _viewportSize!.height;

    // BoxFit.cover:
    // ảnh phải phủ kín cả chiều rộng và chiều cao của viewport.
    _minScale = math.max(
      viewportWidth / imageWidth,
      viewportHeight / imageHeight,
    );

    _maxScale = _minScale * 5;
    _scale = _minScale;

    final renderedWidth = imageWidth * _scale;
    final renderedHeight = imageHeight * _scale;

    // Căn giữa ảnh lúc đầu.
    _offset = Offset(
      (viewportWidth - renderedWidth) / 2,
      (viewportHeight - renderedHeight) / 2,
    );
  }

  /// Có thể gọi từ bên ngoài nếu muốn đưa ảnh về vị trí ban đầu.
  void reset() {
    if (!_isReady) return;

    setState(() {
      _resetTransformValues();
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (!_isReady) return;

    _startScale = _scale;
    _startOffset = _offset;

    // Điểm trên ảnh đang nằm dưới vị trí ngón tay.
    _imagePointAtFocal = (details.localFocalPoint - _startOffset) / _startScale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!_isReady) return;

    final nextScale = (_startScale * details.scale)
        .clamp(_minScale, _maxScale)
        .toDouble();

    // Giữ nguyên điểm ảnh nằm dưới ngón tay khi zoom.
    final nextOffset =
        details.localFocalPoint - (_imagePointAtFocal * nextScale);

    setState(() {
      _scale = nextScale;
      _offset = _clampOffset(nextOffset, nextScale);
    });
  }

  Offset _clampOffset(Offset value, double scale) {
    if (_imageSize == null || _viewportSize == null) {
      return value;
    }

    final renderedWidth = _imageSize!.width * scale;
    final renderedHeight = _imageSize!.height * scale;

    // Với BoxFit.cover:
    // offset lớn nhất là 0;
    // offset nhỏ nhất là viewport - kích thước ảnh đã scale.
    final minDx = math.min(0, _viewportSize!.width - renderedWidth);

    final minDy = math.min(0, _viewportSize!.height - renderedHeight);

    return Offset(
      value.dx.clamp(minDx, 0.0).toDouble(),
      value.dy.clamp(minDy, 0.0).toDouble(),
    );
  }

  /// Xuất đúng phần ảnh đang nhìn thấy trong preview.
  Future<File> cropImage() async {
    if (!_isReady) {
      throw StateError('Ảnh chưa sẵn sàng để crop.');
    }

    final sourceImage = _image!;
    final viewportSize = _viewportSize!;
    final outputSize = widget.outputSize;

    final outputScale = outputSize / viewportSize.width;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Nền vuông 500x500.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, outputSize.toDouble(), outputSize.toDouble()),
      Paint()..color = Colors.white,
    );

    final sourceRect = Rect.fromLTWH(
      0,
      0,
      sourceImage.width.toDouble(),
      sourceImage.height.toDouble(),
    );

    // Dùng đúng offset và scale của preview.
    final destinationRect = Rect.fromLTWH(
      _offset.dx * outputScale,
      _offset.dy * outputScale,
      _imageSize!.width * _scale * outputScale,
      _imageSize!.height * _scale * outputScale,
    );

    canvas.drawImageRect(
      sourceImage,
      sourceRect,
      destinationRect,
      Paint()..filterQuality = FilterQuality.high,
    );

    final picture = recorder.endRecording();

    final renderedImage = await picture.toImage(outputSize, outputSize);

    final pngData = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (pngData == null) {
      throw StateError('Không thể tạo dữ liệu ảnh crop.');
    }

    final pngBytes = pngData.buffer.asUint8List();
    final decodedOutput = img.decodeImage(pngBytes);

    if (decodedOutput == null) {
      throw StateError('Không thể mã hóa ảnh crop.');
    }

    final jpgBytes = img.encodeJpg(decodedOutput, quality: 92);

    final tempDirectory = await getTemporaryDirectory();

    final outputFile = File(
      '${tempDirectory.path}/'
      'cropped_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await outputFile.writeAsBytes(jpgBytes, flush: true);

    return outputFile;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : widget.cropSize;

        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : widget.cropSize;

        final side = math.min(maxWidth, maxHeight);

        _scheduleViewportUpdate(side);

        return SizedBox.square(
          dimension: side,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildContent(side),
          ),
        );
      },
    );
  }

  Widget _buildContent(double side) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_loadError != null || _image == null) {
      return const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white, size: 48),
      );
    }

    if (_viewportSize == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _AvatarImagePainter(
              image: _image!,
              imageSize: _imageSize!,
              offset: _offset,
              scale: _scale,
            ),
          ),

          // Viền hiển thị khung crop.
          IgnorePointer(
            child: CustomPaint(painter: const _CropBorderPainter()),
          ),
        ],
      ),
    );
  }
}

class _AvatarImagePainter extends CustomPainter {
  final ui.Image image;
  final Size imageSize;
  final Offset offset;
  final double scale;

  const _AvatarImagePainter({
    required this.image,
    required this.imageSize,
    required this.offset,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sourceRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final destinationRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      imageSize.width * scale,
      imageSize.height * scale,
    );

    canvas.drawImageRect(
      image,
      sourceRect,
      destinationRect,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarImagePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.offset != offset ||
        oldDelegate.scale != scale;
  }
}

class _CropBorderPainter extends CustomPainter {
  const _CropBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawOval(
      rect.deflate(2),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
