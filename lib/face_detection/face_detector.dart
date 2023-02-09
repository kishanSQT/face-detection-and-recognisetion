import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'galleryView.dart';


class FaceDetectorScreen extends StatefulWidget {
  const FaceDetectorScreen({Key? key}) : super(key: key);

  @override
  State<FaceDetectorScreen> createState() => _FaceDetectorScreenState();
}

class _FaceDetectorScreenState extends State<FaceDetectorScreen> {

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );

  bool _canProcess = true;

  bool _isBusy = false;

  CustomPaint? _customPaint;

  String? _text;

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GalleryView(
              onImage: (inputImage) {
                processImage(inputImage);
              },
            ),

            // CameraView(
            //   onImage: (inputImage) {
            //     processImage(inputImage);
            //   },
            // ),

            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10)
              ),
                padding: EdgeInsets.all(15),
            margin: EdgeInsets.all(15),
            child: Text("Text: $_text"))
          ],
        ),
      ),
    );
  }

  Future<void> processImage(InputImage inputImage) async {

    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;

    setState(() {
      _text = '';
    });

    final faces = await _faceDetector.processImage(inputImage);

    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {

      // Use faces
      // Use inputImage.inputImageData!.size
      // Use inputImage.inputImageData!.imageRotation
      // print("cool");

      print("Faces Found ${faces.length}");

    } else {

      print("Faces Found ${faces.length}");

      String text = 'Faces found: ${faces.length}\n\n';
      for (final face in faces) {
        text += 'face: ${face.boundingBox}\n\n';
      }
      _text = text;
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }

  }

}
