import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:railway_security/Police/alerts.dart';
import 'package:railway_security/Police/manageProfile.dart';
import 'package:railway_security/Police/viewCriminals.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class PoliceHome extends StatefulWidget {
  const PoliceHome({super.key});

  @override
  State<PoliceHome> createState() => _PoliceHomeState();
}

class _PoliceHomeState extends State<PoliceHome> {
  List alerts = [];
  Timer? timer;
  String? baseUrl;
  int selectedPage = 0;

  final List<Widget> pages = [
    Alerts(),
    ManageCriminals(),
    ManageProfile(),
  ];

  @override
  void initState() {
    super.initState();
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'alerts',
          channelName: 'Alert Notifications',
          channelDescription: 'Notifications for new railway alerts',
          importance: NotificationImportance.High,
        ),
      ],
    );
    loadBaseUrl();
  }

  Future<void> loadBaseUrl() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    baseUrl = sh.getString('url');
    if (baseUrl != null && baseUrl!.isNotEmpty) {
      getAlerts();
      timer = Timer.periodic(const Duration(seconds: 5), (_) => getAlerts());
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> showNotification(String message) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: 'alerts',
        title: '🚨 New Alert',
        body: message,
      ),
    );
  }

  Future<void> getAlerts() async {
    try {
      if (baseUrl == null || baseUrl!.isEmpty) return;
      final response = await http.post(Uri.parse('$baseUrl/myapp/viewAlerts/'));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List newAlerts = jsonData['alerts'] ?? [];

        if (alerts.isNotEmpty && newAlerts.length > alerts.length) {
          final latest = newAlerts.first;
          await showNotification(latest['message'] ?? "New alert received!");
        }
        setState(() => alerts = newAlerts);
      }
    } catch (e) {
      debugPrint("Error fetching alerts: $e");
    }
  }

  void _onItemTapped(int index) {
    if (index < pages.length) {
      setState(() => selectedPage = index);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],

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
          currentIndex: selectedPage,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_search_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_rounded),
              label: '',
            ),
          ],
        ),
      ),
    );
  }


}
