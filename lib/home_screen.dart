import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'classifier_service.dart';

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

  final ClassifierService _classifier = ClassifierService();

  @override
  void initState() {
    super.initState();
    _classifier.loadModel();
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
          _isLoading = true;
        });

        final imageBytes = await _selectedImage!.readAsBytes();
        final image = img.decodeImage(imageBytes);
        final resized = img.copyResize(image!, width: 160, height: 160);

        final result = await _classifier.classify(resized);

        setState(() {
          if (result != null) {
            _predictedBreed = result['breed'];
            _confidence = result['confidence'];
          } else {
            _predictedBreed = "Error";
            _confidence = 0.0;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dog Breed AI')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 2,
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.pets, size: 80, color: Color(0xFF00A3FF)),
                            const SizedBox(height: 16),
                            Text(
                              'Capture or select\na dog photo',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                flex: 1,
                child: Center(
                  child: _isLoading
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: Color(0xFF0056D2)),
                            const SizedBox(height: 12),
                            Text('Analyzing...', style: TextStyle(color: Colors.grey[600])),
                          ],
                        )
                      : _predictedBreed != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F0FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF0056D2).withOpacity(0.3), width: 1),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _predictedBreed!,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0056D2)),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(_confidence! * 100).toStringAsFixed(1)}% Match',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildButton(icon: Icons.photo_library_outlined, label: 'Gallery', onTap: () => _pickImage(ImageSource.gallery)),
                  _buildButton(icon: Icons.camera_alt_outlined, label: 'Camera', onTap: () => _pickImage(ImageSource.camera)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0056D2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
