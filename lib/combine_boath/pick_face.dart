import 'dart:io';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

class PickFace {

  PickFace({required this.setImage, required this.onImage,required this.onError});

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );

  bool _isBusy = false;

  final Function(File?) setImage;
  final Function(Face face, File imageFile) onImage;
  final Function(String error) onError;

  ImagePicker imagePicker = ImagePicker();

  Future pickImageFor({required ImageSource source}) async {

    setImage(null);

    final pickedFile = await imagePicker.pickImage(source: source);
    if (pickedFile != null) {
      _processPickedFile(pickedFile);
    }
  }

  Future _processPickedFile(XFile? pickedFile) async {
    final path = pickedFile?.path;
    if (path == null) {
      return;
    }
    setImage(File(path));

    final inputImage = InputImage.fromFilePath(path);
    processImage(inputImage, File(path));
  }

  Future<void> processImage(InputImage inputImage, File imageFile) async {

    if (_isBusy) return;
    _isBusy = true;

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
              onImage(faces.first,imageFile);
            } else {
              onError("Too many Faces");
            }
          }
    } catch (e) {
      print("Error $e");
    } finally {
      _isBusy = false;
    }
    print("Loading Completed");
  }

}