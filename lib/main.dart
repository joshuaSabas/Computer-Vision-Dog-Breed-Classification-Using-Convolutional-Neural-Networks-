import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Breed Classifier',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFDF6F0),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFE8D5C4),
          secondary: const Color(0xFFD4A574),
        ),
        textTheme: GoogleFonts.loraTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFFDF6F0),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.lora(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A3728),
          ),
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==========================================
// SPLASH SCREEN
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Maghihintay ng 3 segundo bago pumunta sa HomeScreen
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pets,
              size: 100,
              color: Color(0xFFD4A574),
            ),
            const SizedBox(height: 24),
            Text(
              'Dog Breed Classifier',
              style: GoogleFonts.lora(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A3728),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading AI Model...',
              style: GoogleFonts.lora(
                fontSize: 16,
                color: const Color(0xFF8B7355),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Color(0xFFD4A574),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// HOME SCREEN (MAIN UI)
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedImage;
  String? _predictedBreed;
  double? _confidence;
  bool _isLoading = false;

  Interpreter? _interpreter;
  List<String>? _labels;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset('assets/models/model_unquant.tflite', options: options);
      
      // Dummy labels (palitan ito ng totoong labels kung meron ka)
      _labels = List.generate(118, (index) => 'Breed ${index + 1}'); 
      print('Model loaded successfully');
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _predictedBreed = null;
          _confidence = null;
        });
        await _classifyImage();
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _classifyImage() async {
    if (_selectedImage == null || _interpreter == null || _labels == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Preprocess image
      final imageBytes = await _selectedImage!.readAsBytes();
      final image = img.decodeImage(imageBytes);
      final resized = img.copyResize(image!, width: 224, height: 224);

      // Convert to tensor
      final input = List.generate(1, (i) => List.generate(224, (j) => List.generate(224, (k) => List.generate(3, (l) => resized.getPixel(j, k)[l] / 255.0))));
      final output = List.filled(118, 0.0).reshape([1, 118]);

      // Run inference
      _interpreter!.run(input, output);

      // Get result
      final predictions = output[0] as List<double>;
      final maxIndex = predictions.indexOf(predictions.reduce((a, b) => a > b ? a : b));

      setState(() {
        _predictedBreed = _labels![maxIndex];
        _confidence = predictions[maxIndex];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error classifying image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🐕 Dog Breed Classifier')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE4DA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.pets, size: 80, color: Color(0xFFD4A574)),
                            const SizedBox(height: 16),
                            Text('📸 Select or capture a dog photo', style: GoogleFonts.lora(fontSize: 16, color: const Color(0xFF8B7355))),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading) ...[
                const CircularProgressIndicator(color: Color(0xFFD4A574)),
                const SizedBox(height: 16),
                Text('🔍 Analyzing image...', style: GoogleFonts.lora(color: const Color(0xFF8B7355))),
              ],
              if (_predictedBreed != null && !_isLoading) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8D5C4).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD4A574), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text('🐕 $_predictedBreed', style: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF4A3728)), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Text('${(_confidence! * 100).toStringAsFixed(1)}% confidence', style: GoogleFonts.lora(fontSize: 16, color: const Color(0xFF4A3728))),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: Text('Gallery', style: GoogleFonts.lora()),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A574), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: Text('Camera', style: GoogleFonts.lora()),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A574), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
