import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ClassifierService {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isLoaded = false;

  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model_unquant.tflite');
      
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData.split('\n').where((line) => line.isNotEmpty).toList();
      
      _isLoaded = true;
      print('Model loaded successfully');
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  Future<Map<String, dynamic>?> classify(img.Image image) async {
    if (!_isLoaded || _interpreter == null || _labels == null) return null;

    try {
      // 1. I-FORCE ANG RGB (3 CHANNELS)
      final img.Image rgbImage = image.convert(numChannels: 3); 
      
      // 2. I-RESIZE SA 224x224 (DATING 160)
      final img.Image resized = img.copyResize(rgbImage, width: 224, height: 224);

      // 3. GAWING TENSOR (224 NA, HINDI 160)
      final input = List.generate(
        1, 
        (i) => List.generate(
          224, 
          (j) => List.generate(
            224, 
            (k) => List.generate(
              3, 
              (l) => resized.getPixel(j, k)[l] / 255.0
            )
          )
        )
      );
      
      final output = List.filled(118, 0.0).reshape([1, 118]);

      _interpreter!.run(input, output);

      final predictions = output[0] as List<double>;
      final maxIndex = predictions.indexOf(predictions.reduce((a, b) => a > b ? a : b));

      return {
        'breed': _labels![maxIndex].replaceAll('_', ' '),
        'confidence': predictions[maxIndex],
      };
    } catch (e) {
      print('Error classifying image: $e');
      return null;
    }
  }
}
