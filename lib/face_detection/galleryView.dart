import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

class GalleryView extends StatefulWidget {
  const GalleryView({Key? key, required this.onImage}) : super(key: key);
  final Function(InputImage inputImage) onImage;
  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> {

  late ImagePicker imagePicker;

  File? imageFile;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    imagePicker = ImagePicker();

  }

  Future _getImage(ImageSource source) async {

    setState(() {
      imageFile = null;
    });

    final pickedFile = await imagePicker.pickImage(source: source);
    if (pickedFile != null) {
      _processPickedFile(pickedFile);
    }
    setState(() {});
  }

  Future _processPickedFile(XFile? pickedFile) async {
    final path = pickedFile?.path;
    if (path == null) {
      return;
    }

    setState(() {
      imageFile = File(path);
    });

    final inputImage = InputImage.fromFilePath(path);
    widget.onImage(inputImage);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
              child: imageFile != null ? Image.file(imageFile!) : Icon(Icons.image)),

          ElevatedButton(onPressed: () {
            _getImage(ImageSource.gallery);
          }, child: Text("Pick Image"))

        ],
      ),
    );
  }
}
