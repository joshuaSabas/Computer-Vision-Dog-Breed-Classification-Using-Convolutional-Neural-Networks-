import 'dart:typed_data';
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
      // 1. I-FORCE ANG RGB (3 CHANNELS) PARA TANGGALIN ANG ALPHA
      final img.Image rgbImage = image.convert(numChannels: 3); 
      
      // 2. I-RESIZE SA 224x224
      final img.Image resized = img.copyResize(rgbImage, width: 224, height: 224);

      // 3. GAWING FLOAT32 TENSOR (Eksaktong gaya ng sa Colab)
      final input = Float32List(1 * 224 * 224 * 3);
      int pixelIndex = 0;
      
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = resized.getPixel(x, y);
          
          // HATIIN LANG SA 255.0 (ITO ANG GINAMIT NATIN SA COLAB)
          input[pixelIndex++] = pixel.r / 255.0;
          input[pixelIndex++] = pixel.g / 255.0;
          input[pixelIndex++] = pixel.b / 255.0;
        }
      }

      // 4. I-RESHAPE
      final reshapedInput = input.reshape([1, 224, 224, 3]);
      final output = List.filled(118, 0.0).reshape([1, 118]);
      
      // 5. PATAKBUHIN
      _interpreter!.run(reshapedInput, output);

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
