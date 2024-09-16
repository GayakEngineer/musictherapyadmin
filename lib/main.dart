import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AdminApp(),
    );
  }
}

class AdminApp extends StatefulWidget {
  @override
  _AdminAppState createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  List<Map<String, dynamic>> clientsData = [];
  Set<String> usedUserIds = {}; // Track used user IDs

  @override
  void initState() {
    super.initState();
    loadClientData();
  }

  // Load saved client data from SharedPreferences
  Future<void> loadClientData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedData = prefs.getStringList('clientsData');
    if (storedData != null) {
      setState(() {
        clientsData = storedData
            .map((item) => Map<String, dynamic>.from(json.decode(item)))
            .toList();
        usedUserIds =
            clientsData.map((item) => item['userId'] as String).toSet();
      });
    }
  }

  // Save client data to SharedPreferences
  Future<void> saveClientData(String name, String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      clientsData.add({
        'name': name,
        'userId': userId,
      });
      usedUserIds.add(userId); // Track the new user ID as used
      List<String> clientDataList =
          clientsData.map((item) => json.encode(item)).toList();
      prefs.setStringList('clientsData', clientDataList);
    });
  }

  // Generate a unique user ID
  String _generateUniqueUserId() {
    String userId;
    do {
      userId = Random().nextInt(10000).toString().padLeft(4, '0');
    } while (usedUserIds.contains(userId));
    usedUserIds.add(userId); // Add the newly generated ID to used IDs
    return userId;
  }

  // Show dialog to add a new client
  void _showAddClientDialog() {
    TextEditingController nameController = TextEditingController();
    String generatedUserId = _generateUniqueUserId();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Client'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Client Name'),
              ),
              Text(
                'Generated User ID: $generatedUserId',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  String clientName = nameController.text;
                  saveClientData(clientName, generatedUserId);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin App'),
      ),
      body: ListView.builder(
        itemCount: clientsData.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text('Name: ${clientsData[index]['name']}'),
              subtitle: Text(
                'User ID: ${clientsData[index]['userId']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ClientDetailsPage(
                    clientData: clientsData[index],
                    onUpdate: (updatedData) {
                      setState(() {
                        clientsData[index] = updatedData;
                      });
                    },
                  ),
                ));
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClientDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ClientDetailsPage extends StatefulWidget {
  final Map<String, dynamic> clientData;
  final Function(Map<String, dynamic>) onUpdate;

  const ClientDetailsPage({super.key, required this.clientData, required this.onUpdate});

  @override
  _ClientDetailsPageState createState() => _ClientDetailsPageState();
}

class _ClientDetailsPageState extends State<ClientDetailsPage> {
  TextEditingController additionalInfoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.clientData.containsKey('additionalInfo')) {
      additionalInfoController.text = widget.clientData['additionalInfo'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Client Name: ${widget.clientData['name']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'User ID: ${widget.clientData['userId']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: additionalInfoController,
              decoration: const InputDecoration(
                labelText: 'Additional Info',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                widget.clientData['additionalInfo'] =
                    additionalInfoController.text;
                widget.onUpdate(widget.clientData);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}