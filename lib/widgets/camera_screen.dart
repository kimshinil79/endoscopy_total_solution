import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'display_picture.dart';
import 'package:path_provider/path_provider.dart';
//import 'dart:io';
import 'package:path/path.dart' show join;
import 'package:flutter/services.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.max,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture) return; // Prevent multiple captures at the same time
    setState(() {
      _isTakingPicture = true;
    });

    try {
      await _initializeControllerFuture;

      final directory = await getApplicationDocumentsDirectory();
      final path = join(directory.path, '${DateTime.now()}.png');

      XFile picture = await _controller!.takePicture();
      await picture.saveTo(path);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(imagePath: path),
        ),
      );
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isTakingPicture = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('사진 찍어주세요')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Positioned.fill(
                  child: Transform.rotate(
                    angle: 90 * 3.1415927 / 180, // 90도 회전
                    child: Transform.scale(
                      scale: 1, // scale 값을 1.0으로 조정
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1 / _controller!.value.aspectRatio,
                          child: CameraPreview(_controller!),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        onPressed: _takePicture,
      ),
    );
  }
}
