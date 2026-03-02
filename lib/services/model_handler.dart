import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ModelHandler {
  Interpreter? _faceNetInterpreter;
  Interpreter? _segmentationInterpreter;
  bool _isLoaded = false;

  Future<void> loadModels() async {
    if (_isLoaded) return;

    // Load FaceNet 512
    _faceNetInterpreter = await Interpreter.fromAsset(
      'assets/models/facenet_512.tflite',
      options: InterpreterOptions()..threads = 4,
    );

    // Segmentation unchanged
    _segmentationInterpreter = await Interpreter.fromAsset(
      'assets/models/mediapipe_selfie-mediapipe-selfie-segmentation-float.tflite',
      options: InterpreterOptions()..threads = 4,
    );

    _isLoaded = true;
  }

  void dispose() {
    _faceNetInterpreter?.close();
    _segmentationInterpreter?.close();
  }

  // ==========================
  // FACE EMBEDDING
  // ==========================
  Future<List<double>> runFaceEmbedding(File imageFile) async {
    if (_faceNetInterpreter == null) {
      throw Exception("FaceNet interpreter not loaded");
    }

    var inputShape = _faceNetInterpreter!.getInputTensor(0).shape;
    int height = inputShape[1];
    int width = inputShape[2];

    final input = await _preprocessImageToList(imageFile, width, height);

    var outputShape = _faceNetInterpreter!.getOutputTensor(0).shape;
    var output = _allocateBuffer(outputShape);

    _faceNetInterpreter!.run(input, output);

    List<double> embedding = _flatten(output);
    return _l2Normalize(embedding);
  }

  // ==========================
  // SEGMENTATION
  // ==========================
  Future<List<List<List<List<double>>>>> runSegmentation(File imageFile) async {
    if (_segmentationInterpreter == null) {
      throw Exception("Segmentation interpreter not loaded");
    }

    var inputShape = _segmentationInterpreter!.getInputTensor(0).shape;
    int height = inputShape[1];
    int width = inputShape[2];

    final input = await _preprocessImageToList(imageFile, width, height);

    var outShape = _segmentationInterpreter!.getOutputTensor(0).shape;
    var output = _allocateBuffer(outShape);

    _segmentationInterpreter!.run(input, output);

    if (outShape.length == 3) {
      List<dynamic> outList = output as List<dynamic>;
      return List.generate(
        1,
        (i) => List.generate(
          outShape[1],
          (y) => List.generate(
            outShape[2],
            (x) => [(outList[0][y][x] as num).toDouble()],
          ),
        ),
      );
    }

    return output as List<List<List<List<double>>>>;
  }

  // ==========================
  // HELPER FUNCTIONS
  // ==========================
  dynamic _allocateBuffer(List<int> shape) {
    if (shape.length == 1) return List.filled(shape[0], 0.0);
    if (shape.length == 2) return List.generate(shape[0], (_) => List.filled(shape[1], 0.0));
    if (shape.length == 3) return List.generate(shape[0], (_) => List.generate(shape[1], (_) => List.filled(shape[2], 0.0)));
    if (shape.length == 4) return List.generate(shape[0], (_) => List.generate(shape[1], (_) => List.generate(shape[2], (_) => List.filled(shape[3], 0.0))));
    throw Exception("Unsupported shape dimension: ${shape.length}");
  }

  List<double> _flatten(dynamic list) {
    List<double> result = [];
    for (var item in list) {
      if (item is List) result.addAll(_flatten(item));
      else result.add((item as num).toDouble());
    }
    return result;
  }

  List<double> _l2Normalize(List<double> vector) {
    double sum = vector.fold(0.0, (p, v) => p + v * v);
    double norm = sum == 0 ? 1.0 : sqrt(sum);
    return vector.map((v) => v / norm).toList();
  }

  Future<List<List<List<List<double>>>>> _preprocessImageToList(File imageFile, int width, int height) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? baseImage = img.decodeImage(bytes);
    if (baseImage == null) throw Exception("Failed to decode image");

    img.Image resized = img.copyResize(baseImage, width: width, height: height);

    var input = List.generate(
      1,
      (_) => List.generate(
        height,
        (_) => List.generate(width, (_) => List.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = resized.getPixel(x, y);
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }

    return input;
  }
}