import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:tolyui_refresh/tolyui_refresh.dart';

class Complaint extends StatefulWidget {
  const Complaint({super.key});

  @override
  State<Complaint> createState() => _ComplaintState();
}

class _ComplaintState extends State<Complaint> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController complaintCont = TextEditingController();
  List complaints = [];
  bool isSending = false;
  RefreshController controller = RefreshController();

  Future<void> sendComplaint(ctext) async {
    if (formKey.currentState!.validate()) {
      setState(() {
        isSending = true;
      });

      final sh = await SharedPreferences.getInstance();
      String url = sh.getString('url') ?? '';

      try {
        var response = await http.post(Uri.parse('$url/myapp/addComplaint/'), body: {
          'complaint': complaintCont.text.trim(),
          'uid': sh.getString('uid')
        });

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complaint submitted successfully'),
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
          complaintCont.clear();
        } else {
          setState(() {
            isSending = false;
          });
        }
      } catch (e) {
        print(e);
        setState(() {
          isSending = false;
        });
      }
    }
  }

  Future<void> loadComplaint() async {
    final sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? '';
    try {
      var response = await http.post(Uri.parse('$url/myapp/viewComplaint/'), body: {
        'uid': sh.getString('uid'),
      });
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        setState(() {
          complaints = jsonData['complaint'];
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteComp(tid) async {
    final pref = await SharedPreferences.getInstance();
    String url = pref.getString('url') ?? '';
    try {
      var response = await http.post(Uri.parse('$url/myapp/deleteComplaint/'), body: {
        'cid': tid.toString()
      });

      if (response.statusCode == 200) {
        await loadComplaint();
        _showSnackBar('Complaint deleted');
      }
    } catch (e) {
      _showSnackBar('An error occurred');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    loadComplaint();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.blue.shade50, // 🔹 blue background
      appBar: AppBar(
        backgroundColor: Colors.blueAccent, // 🔹 blue appbar
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Complaints",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, // 🔹 white container
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.1), // 🔹 soft blue shadow
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: complaints.isEmpty
              ? const Center(child: Text("No complaints found"))
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Previous Complaints',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent, // 🔹 blue text
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final data = complaints[index];

                    return GestureDetector(
                      onLongPress: () {
                        showDelete(data['id']);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.1),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                DateFormat('dd-MM-yyyy HH:mm:ss')
                                    .format(DateTime.parse(data['date_time'])),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              data['complaint'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: data['reply'] == 'pending'
                                    ? Colors.orange[50]
                                    : Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                data['reply'] == 'pending'
                                    ? 'No reply yet'
                                    : data['reply'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: data['reply'] == 'pending'
                                      ? Colors.orange[800]
                                      : Colors.green[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,

        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Send a Complaint",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent, // 🔹 blue header
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          validator: (value) =>
                          value!.isEmpty ? 'Complaint box is empty' : null,
                          controller: complaintCont,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: "Enter your complaint",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent, // 🔹 blue button
                              foregroundColor: Colors.white,
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              await sendComplaint(context);
                              loadComplaint();
                            },
                            child: const Text("Submit"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void showDelete(tid) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Do you want to delete?",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black),
                      )),
                  ElevatedButton(
                    onPressed: () async {
                      await deleteComp(tid);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
