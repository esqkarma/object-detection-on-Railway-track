import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:railway_security/Authority/authorityAlerts.dart';
import 'package:railway_security/Authority/authorityViewProfile.dart';
import 'package:railway_security/Authority/sendComplaints.dart';
import 'package:railway_security/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthHome extends StatefulWidget {

   AuthHome({super.key});

  @override
  State<AuthHome> createState() => _AuthHomeState();
}

class _AuthHomeState extends State<AuthHome> {

  List data = [];
  List<Widget> pages = [
    AuthorityAlerts(),
    Complaint(),
    AuthorityViewProfile()
  ];
  int selectedPage = 0;


  void _onItemTapped(int index) {
    if (index < pages.length) {
      setState(() => selectedPage = index);
    }
  }



  // @override
  // void initState() {
  //   loadComplaint();
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: pages[selectedPage],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueAccent, // affects label
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
                color: selectedPage == 0 ? Colors.blueAccent : Colors.grey,
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.feed,
                color: selectedPage == 1 ? Colors.blueAccent : Colors.grey,
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                color: selectedPage == 2 ? Colors.blueAccent : Colors.grey,
              ),
              label: '',
            ),
          ],
        ),
      ),

    );
  }

}
