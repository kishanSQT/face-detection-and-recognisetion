import 'dart:io';

import 'package:face_detector_recog/final_setup/scan_user_face.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

import 'face_detector.dart';

class SelectUserProfilePic extends StatefulWidget {
  const SelectUserProfilePic({Key? key}) : super(key: key);

  @override
  State<SelectUserProfilePic> createState() => _SelectUserProfilePicState();
}

class _SelectUserProfilePicState extends State<SelectUserProfilePic> {

  late final FaceDetectorService faceDetectorService;

  ImagePicker imagePicker = ImagePicker();

  File? imageFile;

  bool? isFaceFound;

  Face? lastFace;
  InputImage? inputImage;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    faceDetectorService = FaceDetectorService(onFace: (face,inputImage) {

      print("Found the face ${face}");
      setState(() {
        isFaceFound = true;
      });
      lastFace = face;
      this.inputImage = inputImage;
    }, onError: (error) {
      print("Error $error");
      setState(() {
        isFaceFound = false;
      });
      lastFace = null;
      inputImage = null;
    },);

  }

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text("Upload Profile Pic"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () async {

                final image = await imagePicker.pickImage(source: ImageSource.camera, imageQuality: 50,maxHeight: 700,maxWidth: 500);

                if(image != null) {
                  final path = image.path;

                  setState(() {
                    isFaceFound = null;
                    imageFile = File(path);
                  });

                  final inputImage = InputImage.fromFilePath(path);
                  faceDetectorService.processImage(inputImage);
                }

              },
              borderRadius: BorderRadius.circular(15),
              child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.black12
                  ),
                  height: size.width * 0.9,
                  // alignment: Alignment.center,
                  child: imageFile == null ? Icon(Icons.image,size: size.width * 0.5,color: Colors.black54,) : Image.file(imageFile!)
              ),
            ),
            const SizedBox(
              height: 15,
            ),

            if(isFaceFound != null)
              Icon(isFaceFound == true ? Icons.thumb_up : Icons.thumb_down,size: 30.0),

            const SizedBox(
              height: 15,
            ),
            ElevatedButton(onPressed: () {

              if(lastFace != null && inputImage != null) {

                print("inputImage $inputImage");
                print("inputImage ${inputImage?.bytes}");

                Navigator.of(context).push(MaterialPageRoute(builder: (context) => ScanUserFace(comparingFace: lastFace!, inputImage: inputImage!)));
              }

            }, child: Text("Next"))
          ],
        ),
      ),
    );
  }
}
