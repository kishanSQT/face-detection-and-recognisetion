import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'ml_service.dart';

class FaceRecognisetionScreen extends StatefulWidget {
  const FaceRecognisetionScreen({Key? key}) : super(key: key);

  @override
  State<FaceRecognisetionScreen> createState() => _FaceRecognisetionScreenState();
}

class _FaceRecognisetionScreenState extends State<FaceRecognisetionScreen> {

  late ImagePicker imagePicker;

  MLService mlService = MLService();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    imagePicker = ImagePicker();

    mlService.initialize();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: Text("Pick"),
          onPressed: () async {

            final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);


            final path = pickedFile?.path;

            if (path == null) {
              return;
            }

            // final inputImage = InputImage.fromFilePath(path);


            final bytes = await pickedFile?.readAsBytes();

            if(bytes != null) {
              img.Image? imageInput = img.decodeImage(bytes);

              if(imageInput != null) {
                mlService.setPrediction(image: imageInput);
              }


            }


          },
        ),
      ),
    );
  }
}

