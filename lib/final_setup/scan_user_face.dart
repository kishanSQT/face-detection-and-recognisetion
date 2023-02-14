import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../combine_boath/image_processing_service.dart';
import '../face_recognisetion/ml_service.dart';
import 'face_detector.dart';
import 'package:image/image.dart' as imglib;

class ScanUserFace extends StatefulWidget {
  const ScanUserFace({Key? key, required this.comparingFace, required this.inputImage}) : super(key: key);

  final Face comparingFace;
  final InputImage inputImage;

  @override
  State<ScanUserFace> createState() => _ScanUserFaceState();
}

class _ScanUserFaceState extends State<ScanUserFace> {

  late CameraController controller;

  late List<CameraDescription> _cameras;

  bool isReady = false;

  late final FaceDetectorService faceDetectorService;

  bool? isFaceFound;

  Face? lastFace;
  InputImage? inputImage;

  late ImageProcessingService imageService;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {

      imageService = ImageProcessingService();

      await imageService.initialize();

      _cameras = await availableCameras();

      controller = CameraController(_cameras[_cameras.length - 1], ResolutionPreset.max);

      setState(() {
        isReady = true;
      });

      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});

        controller.startImageStream(_processCameraImage);

      }).catchError((Object e) {
        if (e is CameraException) {
          switch (e.code) {
            case 'CameraAccessDenied':
            // Handle access errors here.
              break;
            default:
            // Handle other errors here.
              break;
          }
        }
      });

      faceDetectorService = FaceDetectorService(onFace: (face,inputImage) {

        print("Found the face ${face}");
        setState(() {
          isFaceFound = true;
        });
        lastFace = face;
        // this.inputImage = inputImage;
      }, onError: (error) {
        print("Error $error");
        setState(() {
          isFaceFound = false;
        });
        lastFace = null;
        inputImage = null;
      },);

    });

  }

  Future _processCameraImage(CameraImage image) async {

    final WriteBuffer allBytes = WriteBuffer();

    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final camera = _cameras[_cameras.length - 1];
    final imageRotation =
    InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (imageRotation == null) return;

    final inputImageFormat =
    InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return;

    final planeData = image.planes.map(
          (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage =
    InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    faceDetectorService.processImage(inputImage);

  }

  compareImage() async {

    final comparingImageList = await performImage(face: widget.comparingFace, inputImage: widget.inputImage);

    if(lastFace == null) return;
    if(inputImage == null) return;

    final scannedImageList = await performImage(face: lastFace!, inputImage: inputImage!);

    final match = imageService.isMatch(comparingImageList, scannedImageList);

    print("is Match ${match.isMatch} Value ${match.accuracy}");

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(match.isMatch ? "Image is Matching" : "Not a match"),
      duration: const Duration(seconds: 5),
    ));

  }

  Future<List> performImage({required Face face, required InputImage inputImage}) async {

    Uint8List? imageBytes;

    if(inputImage.filePath != null) {

      imageBytes = await File(inputImage.filePath ?? "").readAsBytes();

    } else {
      imageBytes = inputImage.bytes;
    }

    if(imageBytes == null) throw "Please Select Image.";

    print("Bytes $imageBytes");

    imglib.Image? imageInput = imglib.decodeImage(imageBytes);

    print("imageInput $imageInput");

    if(imageInput == null) throw "Invalid image";

    const offset = 25;

    double x = face.boundingBox.left - offset;
    double y = face.boundingBox.top - offset;
    double w = face.boundingBox.width + (offset * 2);
    double h = face.boundingBox.height + (offset * 2);

    final cropperImage = imglib.copyCrop(
        imageInput, x.round(), y.round(), w.round(), h.round());

    imglib.Image img = imglib.copyResizeCropSquare(cropperImage, 112);

    return imageService.setPrediction(image: img);

  }

  @override
  Widget build(BuildContext context) {

    if(!isReady) {
      return Container();
    }

    if (!controller.value.isInitialized) {
      return Container();
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text("Scan User Face"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black12
                ),
                height: size.width * 0.9,
                alignment: Alignment.center,
                child: CameraPreview(controller)
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
            ElevatedButton(onPressed: () async {

              if(isFaceFound == true) {
                await controller.pausePreview();

                await controller.stopImageStream();

                final file = await controller.takePicture();

                inputImage = InputImage.fromFile(File(file.path));

                compareImage();

              }

            }, child: Text("Capture")),

          ],
        ),
      ),
    );
  }
}
