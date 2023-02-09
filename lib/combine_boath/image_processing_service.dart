import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;

class ImageProcessingService {

  Interpreter? _interpreter;
  double threshold = 1;

  List _predictedData = [];
  List get predictedData => _predictedData;

  Future initialize() async {
    late Delegate delegate;
    try {
      if (Platform.isAndroid) {
        delegate = GpuDelegateV2(
          options: GpuDelegateOptionsV2(
            isPrecisionLossAllowed: false,
            inferencePreference: TfLiteGpuInferenceUsage.fastSingleAnswer,
            inferencePriority1: TfLiteGpuInferencePriority.minLatency,
            inferencePriority2: TfLiteGpuInferencePriority.auto,
            inferencePriority3: TfLiteGpuInferencePriority.auto,
          ),
        );
      } else if (Platform.isIOS) {
        // delegate = GpuDelegate(
        //   options: GpuDelegateOptions(
        //       allowPrecisionLoss: true,
        //       waitType: TFLGpuDelegateWaitType.active),
        // );
      }
      var interpreterOptions = InterpreterOptions();//..addDelegate(delegate);

      _interpreter = await Interpreter.fromAsset('mobilefacenet.tflite',
          options: interpreterOptions);
    } catch (e) {
      print('Failed to load model.');
      print(e);
    }
  }

  List setPrediction({required imglib.Image image}) {

    List input = imageToByteListFloat32(image);

    input = input.reshape([1, 112, 112, 3]);
    List output = List.generate(1, (index) => List.filled(192, 0));

    _interpreter?.run(input, output);
    output = output.reshape([192]);

    print("output $output");

    _predictedData = List.from(output);

    return _predictedData;
  }

  Float32List imageToByteListFloat32(imglib.Image image) {
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (imglib.getRed(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imglib.getGreen(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imglib.getBlue(pixel) - 128) / 128;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }

  double _euclideanDistance(List? e1, List? e2) {
    if (e1 == null || e2 == null) throw Exception("Null argument");

    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    return sqrt(sum);
  }

  MatchModel isMatch(List? e1, List? e2) {

    double minDist = 999;

    double currDist = _euclideanDistance(e1, e2);

    return MatchModel((currDist < threshold), currDist);
  }

}

class MatchModel {
  final bool isMatch;
  final double accuracy;

  MatchModel(this.isMatch, this.accuracy);
}