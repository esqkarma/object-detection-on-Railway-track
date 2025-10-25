import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class Alerts extends StatefulWidget {
  const Alerts({super.key});

  @override
  State<Alerts> createState() => _AlertsState();
}

class _AlertsState extends State<Alerts> {
  List criminalAlerts = [];
  List obstacleAlerts = [];

  String? urls;
  bool isLoading = true;
  Timer? timer;

  late PageController _pageController;
  int _currentPage = 0; // 0 = Criminal, 1 = Obstacle

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'alerts',
          channelName: 'Alerts',
          channelDescription: 'Notifications for new alerts',
          importance: NotificationImportance.High,
        )
      ],
    );

    getAlerts();

    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      getAlerts();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _pageController.dispose();
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
      SharedPreferences sh = await SharedPreferences.getInstance();
      String url = sh.getString('url') ?? '';

      final response = await http.post(Uri.parse('$url/myapp/viewAlerts/'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        final List newCriminalAlerts = jsonData['criminal_alerts'] ?? [];
        final List newObstacleAlerts = jsonData['obstacle_alerts'] ?? [];

        if (criminalAlerts.isNotEmpty && newCriminalAlerts.length > criminalAlerts.length) {
          final latest = newCriminalAlerts.first;
          showNotification("👮 Criminal Alert: ${latest['message'] ?? 'New criminal detected!'}");
        }
        if (obstacleAlerts.isNotEmpty && newObstacleAlerts.length > obstacleAlerts.length) {
          final latest = newObstacleAlerts.first;
          showNotification("🚧 Obstacle Alert: ${latest['message'] ?? 'New obstacle detected!'}");
        }

        setState(() {
          criminalAlerts = newCriminalAlerts;
          obstacleAlerts = newObstacleAlerts;
          urls = url;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String getTodayDay() {
    final now = DateTime.now();
    return ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][now.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: width*0.20,
        centerTitle: true,
        title: Text(getTodayDay(),style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),


        backgroundColor: Colors.blueAccent),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (criminalAlerts.isEmpty && obstacleAlerts.isEmpty)
          ? const Center(child: Text("No alerts available"))
          : Column(
        children: [
          // 👇 Header indicator with tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    setState(() => _currentPage = 0);
                  },
                  child: Container(
                    width: width * 0.45,
                    height: width * 0.11,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _currentPage == 0
                          ? Colors.blueAccent
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      "Criminals",
                      style: TextStyle(
                        color: _currentPage == 0 ?Colors.white: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.045,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    setState(() => _currentPage = 1);
                  },
                  child: Container(
                    width: width * 0.45,
                    height: width * 0.11,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _currentPage == 1
                          ? Colors.blueAccent
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      "Obstacle",
                      style: TextStyle(
                        color: _currentPage == 1 ?Colors.white: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.045,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 👇 PageView content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: [
                CriminalList(criminalAlerts, urls!),
                ObstacleList(obstacleAlerts, urls!),
              ],
            ),
          ),
        ],
      ),
    );

  }
}

Widget CriminalList(criminalData, String urls) {
  return ListView.builder(
    itemCount: criminalData.length,
    itemBuilder: (ctx, index) {
      var data = criminalData[index];
      String? img = data['image'];

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 5,
        shadowColor: Colors.blueAccent.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  '$urls/media/$img',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Text section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['message'] ?? "No message",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (data['criminal_details']?['name'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Criminal: ${data['criminal_details']['name']}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      "Date: ${data['date_time'] ?? 'N/A'}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

    },
  );
}

Widget ObstacleList(obstacleList, String urls) {
  return ListView.builder(
    itemCount: obstacleList.length,
    itemBuilder: (ctx, index) {
      var data = obstacleList[index];
      String? img = data['image'];

      return Card(
        margin: const EdgeInsets.all(8),
        child: ListTile(
          leading: Image.network(
            '$urls/media/$img',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => const Icon(Icons.dangerous, color: Colors.red, size: 40),
          ),
          title: Text(data['message'] ?? "No message"),
          subtitle: Text("Date : ${data['date_time'] ?? 'N/A'}"),
        ),
      );
    },
  );
}
