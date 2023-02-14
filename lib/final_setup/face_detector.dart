import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {

  final Function(Face face, InputImage inputImage) onFace;
  final Function(String error) onError;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );

  bool _canProcess = true;

  bool _isBusy = false;

  FaceDetectorService({required this.onFace, required this.onError});

  Future<void> processImage(InputImage inputImage) async {

    print("isBusy $_isBusy");

    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;

    try {
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
          onFace(faces.first,inputImage);
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
          onFace(faces.first,inputImage);
        } else {
          onError("Too many Faces");
        }
      }

    } catch (e) {
      onError(e.toString());
    } finally {
      _isBusy = false;
    }



  }

}