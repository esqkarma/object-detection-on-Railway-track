import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:railway_security/Authority/authorityHome.php.dart';
import 'package:railway_security/Police/PoliceHome.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController uCont = TextEditingController();
  TextEditingController passCont = TextEditingController();
  bool isLoading = false;
  bool _obsecure = true;

  Future<void> login() async {
    setState(() => isLoading = true);

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";

    try {
      final response = await http.post(
        Uri.parse("$url/myapp/userlogin/"),
        body: {
          'uname': uCont.text.trim(),
          'pass': passCont.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'error') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonData['message'] ?? 'Invalid Username or Password')),
          );
        } else {
          final user = jsonData['user'];
          final type = jsonData['utype'];

          sh.setString('uid', user['id'].toString());
          sh.setBool('logged', true);
          sh.setString('utype', type);

          if (type == 'authority') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>  AuthHome ()));
          } else if(type == 'police'){
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PoliceHome()));
          }else
            {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("No user Found")),
              );

            }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong. Please try again.")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Welcome Back ",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Login to continue",
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                    const SizedBox(height: 30),

                    // Username Field
                    TextFormField(
                      controller: uCont,
                      decoration: InputDecoration(
                        labelText: "Username",
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.blueAccent),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: passCont,
                      obscureText: _obsecure,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.blueAccent),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obsecure = !_obsecure;
                            });
                          },
                          icon: Icon(
                            _obsecure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.blueAccent,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          "Log In",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loader Overlay
          if (isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
