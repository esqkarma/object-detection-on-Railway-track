import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:railway_security/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tolyui_refresh/tolyui_refresh.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File? _profileImage;
  bool isLoading = false;
  List pred = [];
  String urls = "";
  bool isFetching = true;// initially true
  List solution = [];


  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  Future<void> regUser() async {
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url') ?? '';

    try {
      var request =
      http.MultipartRequest('POST', Uri.parse('$url/uploadImage'));

      request.files.add(
        await http.MultipartFile.fromPath('photo', _profileImage!.path),
      );
      request.fields['uid'] = pref.getString('uid')!;

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = jsonDecode(responseData);

        String status = jsonData['status'];
        if (status == 'good') {

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonData['message'])),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('')),
      );
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<void> getpredicts() async {
    setState(() {
      isFetching = true; // start loading
    });

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? '';
    try {
      final response = await http.post(
        Uri.parse("$url/getPrediction"),
        body: {'uid': sh.getString('uid')},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          pred = jsonData['predictions'];
          urls = sh.getString('url') ?? " ";
          isFetching = false; // stop loading
        });
      } else {
        setState(() {
          isFetching = false;
          pred = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data Found')),
        );
      }
    } catch (e) {
      setState(() {
        isFetching = false;
        pred = [];
      });
      print(e);
    }
  }



  Future<void> logout() async{
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url')??"";
    sh.clear();
    sh.setBool('logged', false);
    sh.setString('url', url);

  }





  @override
  void initState() {
    getpredicts();
    super.initState();
  }
  final RefreshController controller = RefreshController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          toolbarHeight: width*0.20,
          backgroundColor: Colors.white54,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  // if (value == "Feedback") {
                  //   Navigator.of(context).push(MaterialPageRoute(builder: (ctx)=>Userfeedback()));
                  // } else if (value == "Complaint") {
                  //   Navigator.of(context).push(MaterialPageRoute(builder: (ctx)=>Complaint()));
                  // } else
                    if (value == "logout") {
                    logout();
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(builder: (ctx)=>Login()));
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: "Feedback",
                    child: Text("Feedbacks"),
                  ),
                  const PopupMenuItem(
                    value: "Complaint",
                    child: Text("Complaint"),
                  ),
                  const PopupMenuItem(
                    value: "logout",
                    child: Text("Logout"),
                  ),
                ],
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.person, size: 40),
                ),
              ),
            )

          ],

        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: pickImage,
                child: _profileImage != null
                    ? Column(
                  children: [
                    Container(
                      height: width * 0.50,
                      width: width * 0.85,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: FileImage(_profileImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () async{
                        await regUser();
                        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx)=>Home()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,

                      ),
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Upload'),
                    ),
                  ],
                )
                    : Container(
                  height: width * 0.50,
                  width: width * 0.85,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt),
                      SizedBox(width: 8),
                      Text('Upload Image'),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 50,left: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('Recent Uploads',style: TextStyle(fontSize: 25),)
                  ],),
              ),
              SizedBox(width: width*0.90,child: Divider()),
              SizedBox(height: 20,),
              Expanded(
                child: TolyRefresh(
                  controller: controller,
                  header: WaterDropMaterialHeader(
                    color: Colors.black,
                    backgroundColor: Colors.black45,
                  ),
                  onRefresh: () async {
                    await getpredicts();
                    controller.refreshCompleted();
                  },
                  child: isFetching
                      ? const Center(child: CircularProgressIndicator(
                  )) // show loader first
                      : pred.isEmpty
                      ? Center(
                    child: SizedBox(
                      height: width * 0.70,
                      child: Lottie.asset('assets/empty ghost.json'),
                    ),
                  )
                      : ListView.builder(
                    itemCount: pred.length,
                    itemBuilder: (BuildContext context, int index) {
                      final data = pred[index];
                      print(data);
                      String imgUrl = "$urls/static/media/" + data['image'];

                      return GestureDetector(
                        onTap: () {
                          String dat = data['solution']??"No solution Found..";

                          _showBottomModal(context, dat,imgUrl,width);
                        },
                        child: Card(
                          margin: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          color: Colors.white70,
                          child: Row(
                            children: [
                              Container(
                                height: width * 0.30,
                                width: width * 0.30,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                  ),
                                  child: Image.network(imgUrl, fit: BoxFit.cover),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        data['prediction'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('dd-MM-yyyy')
                                            .format(DateTime.parse(data['date'])),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                ),
              )
            ],
          ),
        ),
      ),
    );
  }







  void _showBottomModal(BuildContext context, String? data,String? imgrl,double width) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allow full height if needed
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5, // initial height (30% of screen)
          minChildSize: 0.2,     // minimum height (20% of screen)
          maxChildSize: 0.8,     // maximum height (80% of screen)
          expand: false,         // don’t take full screen immediately
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController, // attach scroll controller
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Container(
                    width: width,
                    height: width*0.40,
                    child: Image.network(imgrl!,fit: BoxFit.cover,),
                  ),

                  const SizedBox(height: 16),
                  Text('Solution',style: TextStyle(fontSize: 28,fontWeight: FontWeight.bold),),
                  const SizedBox(height: 16),
                  Text(data??"No solution Found..", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

}
