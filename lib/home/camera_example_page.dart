// 카메라 사용법 익히기 위한 페이지
import 'package:camera/camera.dart';
import 'package:fastcampus_market_02/main.dart';
import 'package:flutter/material.dart';

class CameraExamplePage extends StatefulWidget {
  const CameraExamplePage({super.key});

  @override
  State<CameraExamplePage> createState() => _CameraExamplePageState();
}

class _CameraExamplePageState extends State<CameraExamplePage> {

  // 카메라 컨트롤러
  CameraController? cameraController;

  @override
  void initState() {
    super.initState();
    // 첫번째 카메라 설정, 해상도 설정
    cameraController = CameraController(cameras[0], ResolutionPreset.high);
    // 카메라 초기화 완료되면 화면 갱신
    cameraController?.initialize().then((value) {
      setState(() {

      });
    });
  }

  // 컨트롤 사용할 때에는 dispose 처리 필요
  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: cameraController?.value.isInitialized ?? false
      ? CameraPreview(cameraController!)
      : const Center(
        child: Text('카메라 초기화 중...'),
      ),
    );
  }
}
