import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:railway_security/Police/viewCriminals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Addcriminals extends StatefulWidget {
  const Addcriminals({super.key});

  @override
  State<Addcriminals> createState() => _AddcriminalsState();
}

class _AddcriminalsState extends State<Addcriminals> {
  TextEditingController nameCont = TextEditingController();
  TextEditingController placeCont = TextEditingController();
  File? criminalImage;
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => criminalImage = File(picked.path));
  }

  void showTopSnackbar(String message, {Color bg = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> regUser() async {
    if (criminalImage == null) {
      showTopSnackbar("Please select an image first");
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url') ?? '';

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$url/myapp/uploadImage/'),
      );
      request.files.add(await http.MultipartFile.fromPath('photo', criminalImage!.path));
      request.fields['uid'] = pref.getString('uid')!;
      request.fields['name'] = nameCont.text.trim();
      request.fields['place'] = placeCont.text.trim();

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = jsonDecode(responseData);

      if (response.statusCode == 200 && jsonData['status'] == 'success') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (ctx) => ManageCriminals()),
        );
      } else {
        showTopSnackbar(jsonData['message'] ?? "Upload failed");
      }
    } catch (e) {
      showTopSnackbar("Something went wrong");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text("Add Criminal", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: width * 0.5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4)),
                    ],
                    image: criminalImage != null
                        ? DecorationImage(
                        image: FileImage(criminalImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: criminalImage == null
                      ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.camera_alt, size: 50, color: Colors.blueAccent),
                        SizedBox(height: 8),
                        Text("Tap to upload image",
                            style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField("Criminal Name", nameCont),
              const SizedBox(height: 16),
              _buildTextField("Place", placeCont),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : regUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Upload",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          showTopSnackbar("$hint cannot be empty");
          return '';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        fillColor: Colors.white,
        filled: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
