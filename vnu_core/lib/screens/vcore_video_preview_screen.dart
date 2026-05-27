import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:vnu_core/globals.dart';
import 'package:vnu_core/widgets/navi_widget.dart';

class VcoreVideoPreviewScreen extends StatefulWidget {
  final String videoUrl;
  const VcoreVideoPreviewScreen({super.key, required this.videoUrl});

  @override
  State<VcoreVideoPreviewScreen> createState() =>
      _VcoreVideoPreviewScreenState();
}

class _VcoreVideoPreviewScreenState extends State<VcoreVideoPreviewScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl),
        httpHeaders: Globals().headerToken())
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
        _controller.play();
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NaviWidget(
        titleStr: 'Video',
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? Stack(
                // fit: StackFit.expand,
                alignment: AlignmentDirectional.center,
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                  GestureDetector(
                    onTap: () {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    },
                  )
                ],
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }
}
