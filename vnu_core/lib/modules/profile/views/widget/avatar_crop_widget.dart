
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class AvatarCropWidget extends StatefulWidget {
  final File imageFile;
  final double cropSize;

  const AvatarCropWidget({
    super.key,
    required this.imageFile,
    this.cropSize = 300,
  });

  @override
  State<AvatarCropWidget> createState() => AvatarCropWidgetState();
}

class AvatarCropWidgetState extends State<AvatarCropWidget> {
  final GlobalKey _containerKey = GlobalKey();
  Offset _offset = Offset.zero;
  Size? _imageSize;
  Size? _containerSize;
  double _scale = 1.0;
  double _minScale = 1.0;
  double _maxScale = 3.0;
  Offset _startOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  double _startScale = 1.0;
  bool _isLoading = true;
  ui.Image? _uiImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final image = await decodeImageFromList(bytes);
    setState(() {
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      _uiImage = image;
      _isLoading = false;
      _calculateInitialScale();
    });
  }

  void _calculateInitialScale() {
    if (_imageSize == null || _containerSize == null) return;

    final imageAspectRatio = _imageSize!.width / _imageSize!.height;
    final containerAspectRatio = _containerSize!.width / _containerSize!.height;

    if (imageAspectRatio > containerAspectRatio) {
      _scale = _containerSize!.height / _imageSize!.height;
    } else {
      _scale = _containerSize!.width / _imageSize!.width;
    }

    _minScale = _scale;

    final imageWidth = _imageSize!.width * _scale;
    final imageHeight = _imageSize!.height * _scale;
    _offset = Offset(
      (_containerSize!.width - imageWidth) / 2,
      (_containerSize!.height - imageHeight) / 2,
    );
  }

  // Phương thức crop ảnh - public để gọi từ bên ngoài
  Future<File> cropImage() async {
    if (_imageSize == null || _containerSize == null) {
      return widget.imageFile;
    }

    // Đọc ảnh gốc
    final bytes = await widget.imageFile.readAsBytes();
    final image = img.decodeImage(bytes)!;

    // Tính toán vùng crop
    final cropX = (-_offset.dx / _scale).clamp(0.0, _imageSize!.width);
    final cropY = (-_offset.dy / _scale).clamp(0.0, _imageSize!.height);
    final cropWidth = (_containerSize!.width / _scale).clamp(0.0, _imageSize!.width - cropX);
    final cropHeight = (_containerSize!.height / _scale).clamp(0.0, _imageSize!.height - cropY);

    // Crop ảnh theo khung tròn
    final croppedImage = img.copyCrop(
      image,
      x: cropX.toInt(),
      y: cropY.toInt(),
      width: cropWidth.toInt(),
      height: cropHeight.toInt(),
    );

    // Resize ảnh crop thành hình vuông
    final size = cropWidth < cropHeight ? cropWidth : cropHeight;
    final squareImage = img.copyResizeCropSquare(
      croppedImage,
      size: size.toInt(),
    );

    // Resize về kích thước mong muốn (500x500)
    final finalImage = img.copyResize(
      squareImage,
      width: 500,
      height: 500,
    );

    // Lưu ảnh
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/cropped_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(img.encodeJpg(finalImage, quality: 90));

    return file;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        _containerSize = Size(size, size);
        return Container(
          key: _containerKey,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: _isLoading
              ? const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          )
              : GestureDetector(
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            onScaleEnd: _handleScaleEnd,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Ảnh nền
                CustomPaint(
                  painter: _ImagePainter(
                    image: widget.imageFile,
                    imageSize: _imageSize!,
                    offset: _offset,
                    scale: _scale,
                  ),
                  size: Size(size, size),
                ),
                // Lớp phủ tối ở viền
                CustomPaint(
                  painter: _BorderOverlayPainter(
                    size: size,
                  ),
                  size: Size(size, size),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _startFocalPoint = details.focalPoint;
    _startScale = _scale;
    _startOffset = _offset;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_startScale * details.scale).clamp(_minScale, _maxScale);
      final delta = details.focalPoint - _startFocalPoint;
      _offset = _startOffset + delta;

      final imageWidth = _imageSize!.width * _scale;
      final imageHeight = _imageSize!.height * _scale;
      final maxDx = (imageWidth - _containerSize!.width) / 2;
      final maxDy = (imageHeight - _containerSize!.height) / 2;

      _offset = Offset(
        _offset.dx.clamp(-maxDx, maxDx),
        _offset.dy.clamp(-maxDy, maxDy),
      );
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {}
}

// Painter vẽ ảnh
class _ImagePainter extends CustomPainter {
  final File image;
  final Size imageSize;
  final Offset offset;
  final double scale;

  _ImagePainter({
    required this.image,
    required this.imageSize,
    required this.offset,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final imageProvider = FileImage(image);
    final imageStream = imageProvider.resolve(const ImageConfiguration());

    imageStream.addListener(
      ImageStreamListener((info, _) {
        final uiImage = info.image;
        final imageWidth = imageSize.width * scale;
        final imageHeight = imageSize.height * scale;

        final srcRect = Rect.fromLTWH(
          -offset.dx / scale,
          -offset.dy / scale,
          size.width / scale,
          size.height / scale,
        );

        final dstRect = Rect.fromLTWH(
          offset.dx,
          offset.dy,
          imageWidth,
          imageHeight,
        );

        final paint = Paint()..filterQuality = FilterQuality.high;
        canvas.drawImageRect(uiImage, srcRect, dstRect, paint);
      }),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Painter vẽ overlay viền
class _BorderOverlayPainter extends CustomPainter {
  final double size;

  _BorderOverlayPainter({required this.size});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Vẽ overlay tối bên ngoài khung tròn
    final path = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    // Vẽ viền trắng nổi bật
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1);

    canvas.drawOval(
      Rect.fromCircle(center: center, radius: radius - 2),
      borderPaint,
    );

    // Vẽ viền ngoài mờ
    final outerBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawOval(
      Rect.fromCircle(center: center, radius: radius + 2),
      outerBorderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}