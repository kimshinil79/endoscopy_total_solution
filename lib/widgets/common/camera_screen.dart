import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'display_picture.dart';
import 'package:path_provider/path_provider.dart';
//import 'dart:io';
import 'package:path/path.dart' show join;
import 'package:flutter/services.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'dart:io';

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

      // EXIF 정보를 기반으로 이미지 회전 수정
      File rotatedImage = await FlutterExifRotation.rotateAndSaveImage(
        path: picture.path,
      );

      // 회전된 이미지를 사용하여 화면 전환
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => DisplayPictureScreen(imagePath: rotatedImage.path),
        ),
      );
    } catch (e) {
      print('이미지 촬영 오류: $e');
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
                  child: Center(child: CameraPreview(_controller!)),
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
