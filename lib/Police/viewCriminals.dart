import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:railway_security/Police/PoliceHome.dart';
import 'package:railway_security/Police/addCriminals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageCriminals extends StatefulWidget {
  const ManageCriminals({super.key});

  @override
  State<ManageCriminals> createState() => _ManageCriminalsState();
}

class _ManageCriminalsState extends State<ManageCriminals> {
  List criminals = [];
  String urls = '';

  @override
  void initState() {
    super.initState();
    loadCriminals();
  }

  Future<void> loadCriminals() async {
    final sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? '';
    try {
      var response = await http.post(Uri.parse('$url/myapp/viewCriminals/'));
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        setState(() {
          criminals = jsonData['criminals'];
          urls = url;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteCriminal(tid) async {
    final pref = await SharedPreferences.getInstance();
    String url = pref.getString('url') ?? '';
    try {
      var response =
      await http.post(Uri.parse('$url/myapp/deleteCriminal/'), body: {
        'cid': tid.toString(),
      });
      if (response.statusCode == 200) {
        await loadCriminals();
        showTopSnackbar('Criminal deleted');
      }
    } catch (e) {
      showTopSnackbar('An error occurred');
    }
  }

  void showTopSnackbar(String message, {Color bg = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    ));
  }

  void confirmDelete(tid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Criminal"),
        content: const Text("Do you want to delete this criminal?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () async {
                await deleteCriminal(tid);
                Navigator.of(ctx).pop();
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        title: const Text("Manage Criminals", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (ctx) => PoliceHome()));
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: criminals.isEmpty
            ? const Center(child: Text("No criminals found"))
            : ListView.builder(
          itemCount: criminals.length,
          itemBuilder: (ctx, index) {
            final data = criminals[index];
            String imgUrl = urls + "/media/" + data['image'];

            return GestureDetector(
              onLongPress: () => confirmDelete(data['id']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.network(
                        imgUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.person, size: 70, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'Unknown',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data['place'] ?? '',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (ctx) => const Addcriminals()));
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
