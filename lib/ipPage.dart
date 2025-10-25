import 'package:flutter/material.dart';
import 'package:railway_security/Authority/authorityHome.php.dart';
import 'package:railway_security/Home.dart';
import 'package:railway_security/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Police/PoliceHome.dart';

class IpPage extends StatefulWidget {
  const IpPage({super.key});

  @override
  State<IpPage> createState() => _IpPageState();
}

class _IpPageState extends State<IpPage> {
  TextEditingController ipCont = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool islogged = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Blue gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1565C0), // deep blue
              Color(0xFF42A5F5), // light blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Center(
                      child: Text(
                        "Connect to Server",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // IP Address label
                    const Text(
                      "Server IP Address",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // TextField
                    TextFormField(
                      controller: ipCont,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.blue[50],
                        hintText: "Enter IP address",
                        hintStyle: const TextStyle(color: Colors.black45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: Colors.blueAccent),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: Colors.blueAccent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: Color(0xFF1565C0), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                      validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? "Enter IP address"
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Connect Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            SharedPreferences sh =
                            await SharedPreferences.getInstance();
                            setState(() {
                              islogged = sh.getBool('logged') ?? false;
                            });
                            String ip = ipCont.text.trim();
                            sh.setString('url', "http://$ip:8000");

                            if (islogged) {
                              if (sh.getString('utype') == 'authority') {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (ctx) => AuthHome()),
                                );
                              } else {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (ctx) => PoliceHome()),
                                );
                              }
                            } else {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (ctx) => const Login(),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          "Connect",
                          style: TextStyle(
                            fontSize: 18,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Footer text
                    const Center(
                      child: Text(
                        "Ensure server is running before connecting",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
