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

  bool isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    imageService = ImageProcessingService();

    imageService.initialize();

    pickFace = PickFace(
      (isLoading) {
        setState(() {
          this.isLoading = isLoading;
        });
      },
      setImage: (imageFile) {
        setState(() {
          if (isMainImage) {
            mainImageFile = imageFile;
          } else {
            checkImageFile = imageFile;
          }
        });
      },
      onImage: (faceDetected, image) async {
        setState(() {
          isLoading = true;
        });
        print("TIME Start ${DateTime.now().millisecondsSinceEpoch}");
        try {
          print(faceDetected.boundingBox);

          final imageBytes = await image.readAsBytes();

          // await Future.delayed(Duration(seconds: 1));

          print("TIME before decode ${DateTime.now().millisecondsSinceEpoch}");

          imglib.Image? imageInput = imglib.decodeImage(imageBytes);

          if (imageInput != null) {

            const offset = 25;

            double x = faceDetected.boundingBox.left - offset;
            double y = faceDetected.boundingBox.top - offset;
            double w = faceDetected.boundingBox.width + (offset * 2);
            double h = faceDetected.boundingBox.height + (offset * 2);

            print("TIME before crop ${DateTime.now().millisecondsSinceEpoch}");
            final cropperImage = imglib.copyCrop(
                imageInput, x.round(), y.round(), w.round(), h.round());

            print("TIME after crop ${DateTime.now().millisecondsSinceEpoch}");

            imglib.Image img = imglib.copyResizeCropSquare(cropperImage, 112);

            print("TIME after resize ${DateTime.now().millisecondsSinceEpoch}");

            setState(() {
              imageData = Uint8List.fromList(imglib.encodePng(img));
            });

            if (isMainImage) {
              mainImageList = imageService.setPrediction(image: img);
            } else {
              checkImageList = imageService.setPrediction(image: img);

              try {
                final match =
                    imageService.isMatch(mainImageList, checkImageList);

                print("isMatch ${match.isMatch}");
                print("isMatch ${match.isMatch}");

                setState(() {
                  text =
                      "is Match = ${match.isMatch}\naccuracy = ${match.accuracy}";
                });
              } catch (e) {
                print(e);
              }
            }
          }
        } catch (e) {
          print(e);
        } finally {
          setState(() {
            isLoading = false;
          });
          print("TIME End ${DateTime.now().millisecondsSinceEpoch}");
        }
      },
      onError: (error) {
        print("ERROR $error");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error),
          duration: const Duration(seconds: 3),
        ));
        setState(() {
          isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan For All"),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Expanded(
                        child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            color: Colors.blue,
                            padding: EdgeInsets.all(2),
                            child: mainImageFile != null
                                ? Image.file(mainImageFile!)
                                : null,
                          ),
                        ),
                        ElevatedButton(
                            onPressed: () {
                              isMainImage = true;
                              pickFace.pickImageFor(
                                  source: ImageSource.gallery);
                            },
                            child: Text("Pick main Image"))
                      ],
                    )),
                    SizedBox(width: 15),
                    Expanded(
                        child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            color: Colors.yellow,
                            padding: EdgeInsets.all(2),
                            child: checkImageFile != null
                                ? Image.file(checkImageFile!)
                                : null,
                          ),
                        ),
                        ElevatedButton(
                            onPressed: () {
                              isMainImage = false;
                              pickFace.pickImageFor(
                                  source: ImageSource.gallery);
                            },
                            child: Text("Pick check Image"))
                      ],
                    )),
                  ],
                ),
              ),
              Text(text),
              if (imageData != null)
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.memory(imageData!),
                )
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
        ],
      ),
    );
  }
}
