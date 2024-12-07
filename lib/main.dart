import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Upload Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ImageUploadScreen(),
    );
  }
}

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({Key? key}) : super(key: key);
  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _selectedImage;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _studentNameController = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    } else {
      // No image selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
    }
  }

  // Function to send data to the backend API
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image')),
        );
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2/backend/student/student.php'),
      );

      // Add text fields (student name)
      request.fields['sname'] = _studentNameController.text;

      // Add image file
      var stream = http.ByteStream(_selectedImage!.openRead());
      var length = await _selectedImage!.length();
      var multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: _selectedImage!.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      // Send request
      try {
        var response = await request.send();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data submitted successfully')),
          );

      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error submitting data')),
        );
      }
    }
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Image'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Student name input
              TextFormField(
                controller: _studentNameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter student name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Display selected image or message
              _selectedImage != null
                  ? Column(
                      children: [
                        Image.file(
                          _selectedImage!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 10),
                        Text('Image Path: ${_selectedImage!.path}'),
                      ],
                    )
                  : const Text('No image selected'),
              const SizedBox(height: 20),

              // Pick image from gallery button
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                child: const Text('Pick Image from Gallery'),
              ),
              const SizedBox(height: 10),

              // Capture image from camera button
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.camera),
                child: const Text('Capture Image from Camera'),
              ),
              const SizedBox(height: 20),

              // Submit button
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
