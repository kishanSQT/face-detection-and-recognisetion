import 'dart:io';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

class PickFace {

  PickFace(this.onLoading, {required this.setImage, required this.onImage,required this.onError});

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );

  bool _isBusy = false;

  final Function(bool isLoading) onLoading;
  final Function(File?) setImage;
  final Function(Face face, File imageFile) onImage;
  final Function(String error) onError;

  ImagePicker imagePicker = ImagePicker();

  Future pickImageFor({required ImageSource source}) async {

    onLoading(true);
    setImage(null);

    try {
      final pickedFile = await imagePicker.pickImage(source: source,imageQuality: 50,maxHeight: 700,maxWidth: 500);
      if (pickedFile != null) {
        _processPickedFile(pickedFile);
      } else {
        onLoading(false);
      }
    } catch (e) {
      onLoading(false);
    }
  }

  Future _processPickedFile(XFile? pickedFile) async {
    final path = pickedFile?.path;
    if (path == null) {
      onLoading(false);
      return;
    }
    setImage(File(path));

    final inputImage = InputImage.fromFilePath(path);
    processImage(inputImage, File(path));
  }

  Future<void> processImage(InputImage inputImage, File imageFile) async {
    onLoading(false);
    if (_isBusy) return;
    _isBusy = true;
    onLoading(true);
    try {
      print("Loading Started");

      final faces = await _faceDetector.processImage(inputImage);

      if (inputImage.inputImageData?.size != null &&
              inputImage.inputImageData?.imageRotation != null) {

            // Use faces
            // Use inputImage.inputImageData!.size
            // Use inputImage.inputImageData!.imageRotation
            // print("cool");

            print("Faces Found ${faces.length}");

            if(faces.isEmpty) {
              onError("No Face Found");
              return;
            }

            if(faces.length == 1) {
              onLoading(false);
              onImage(faces.first,imageFile);
            } else {
              onError("Too many Faces");
            }

          } else {

            print("Faces Found ${faces.length}");

            String text = 'Faces found: ${faces.length}\n\n';
            for (final face in faces) {
              text += 'face: ${face.boundingBox}\n\n';
            }
            print(text);

            if(faces.isEmpty) {
              onError("No Face Found");
              return;
            }

            if(faces.length == 1) {
              onLoading(false);
              onImage(faces.first,imageFile);
            } else {
              onError("Too many Faces");
            }
          }
    } catch (e) {
      print("Error $e");
      onLoading(false);
    } finally {
      _isBusy = false;

    }
    print("Loading Completed");
  }

}