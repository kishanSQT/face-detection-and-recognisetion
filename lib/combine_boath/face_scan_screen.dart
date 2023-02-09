import 'dart:io';
import 'dart:typed_data';

import 'package:face_detector_recog/combine_boath/pick_face.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as imglib;

import 'image_processing_service.dart';

class FaceScanScreen extends StatefulWidget {
  const FaceScanScreen({Key? key}) : super(key: key);

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {

  late PickFace pickFace;

  bool isMainImage = true;

  File? mainImageFile;
  File? checkImageFile;

  Uint8List? imageData;

  List mainImageList = [];
  List checkImageList = [];

  late ImageProcessingService imageService;

  String text = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    imageService = ImageProcessingService();

    imageService.initialize();

    pickFace = PickFace(setImage: (imageFile) {

      setState(() {
        if(isMainImage) {
          mainImageFile = imageFile;
        } else {
          checkImageFile = imageFile;
        }
      });

    }, onImage: (faceDetected, image) async {

      print(faceDetected.boundingBox);

      final imageBytes = await image.readAsBytes();

      imglib.Image? imageInput = imglib.decodeImage(imageBytes);

      if(imageInput != null) {

        double x = faceDetected.boundingBox.left;
        double y = faceDetected.boundingBox.top;
        double w = faceDetected.boundingBox.width;
        double h = faceDetected.boundingBox.height;

        final cropperImage = imglib.copyCrop(imageInput, x.round(), y.round(), w.round(), h.round());

        imglib.Image img = imglib.copyResizeCropSquare(cropperImage, 112);

        setState(() {
          imageData = Uint8List.fromList(imglib.encodePng(img));
        });

        if(isMainImage) {

          mainImageList = imageService.setPrediction(image: img);

        } else {

          checkImageList = imageService.setPrediction(image: img);

          try {
            final match = imageService.isMatch(mainImageList, checkImageList);

            print("isMatch ${match.isMatch}");
            print("isMatch ${match.isMatch}");

            setState(() {
              text = "is Match = ${match.isMatch}\naccuracy = ${match.accuracy}";
            });

          } catch (e) {
            print(e);
          }

        }



      }

    },onError: (error) {
      print("ERROR $error");
    },);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan For All"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(child: Column(children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      color: Colors.blue,
                      padding: EdgeInsets.all(2),
                      child: mainImageFile != null ? Image.file(mainImageFile!) : null,
                    ),
                  ),
                  ElevatedButton(onPressed: () {
                    isMainImage = true;
                    pickFace.pickImageFor(source: ImageSource.gallery);
                  }, child: Text("Pick main Image"))
                ],)),
                SizedBox(width: 15),
                Expanded(child: Column(children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      color: Colors.yellow,
                      padding: EdgeInsets.all(2),
                      child: checkImageFile != null ? Image.file(checkImageFile!) : null,
                    ),
                  ),
                  ElevatedButton(onPressed: () {
                    isMainImage = false;
                    pickFace.pickImageFor(source: ImageSource.gallery);
                  }, child: Text("Pick check Image"))
                ],)),
              ],
            ),
          ),

          Text(text),

          if(imageData != null)
          SizedBox(
            width: 100,
            height: 100,
            child: Image.memory(imageData!),
          )

        ],
      ),
    );
  }
}
