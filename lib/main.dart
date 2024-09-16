import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For date formatting

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
  late String userIDs;

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
        'links': {'morning': '', 'afternoon': '', 'evening': '', 'night': ''},
        'expiryDate': null,
      });
      List<String> clientDataList =
          clientsData.map((item) => json.encode(item)).toList();
      prefs.setStringList('clientsData', clientDataList);
    });
  }

  // Update client data in SharedPreferences
  Future<void> updateClientData(
      int index, Map<String, String> links, DateTime expiryDate) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      clientsData[index]['links'] = links;
      clientsData[index]['expiryDate'] = expiryDate.toIso8601String();
      List<String> clientDataList =
          clientsData.map((item) => json.encode(item)).toList();
      prefs.setStringList('clientsData', clientDataList);
    });
  }

  // Show dialog to add a new client
  void _showAddClientDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController userIdController = TextEditingController();

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
              TextField(
                controller: userIdController,
                decoration: const InputDecoration(labelText: 'User ID'),
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
                String clientName = nameController.text;
                String userId = userIdController.text;
                if (clientName.isNotEmpty && userId.isNotEmpty) {
                  userIDs=userId;
                  saveClientData(clientName, userId);
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

  // Show page for entering client's links and expiry date
  void _showClientDetailsPage(int index) {
    TextEditingController morningController = TextEditingController();
    TextEditingController afternoonController = TextEditingController();
    TextEditingController eveningController = TextEditingController();
    TextEditingController nightController = TextEditingController();
    DateTime? expiryDate;

    showModalBottomSheet(
      isScrollControlled: true, // Allows the modal sheet to expand when needed
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom, // Adjust for the keyboard
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: morningController,
                        decoration:
                            const InputDecoration(labelText: 'Morning Link'),
                      ),
                      TextField(
                        controller: afternoonController,
                        decoration:
                            const InputDecoration(labelText: 'Afternoon Link'),
                      ),
                      TextField(
                        controller: eveningController,
                        decoration:
                            const InputDecoration(labelText: 'Evening Link'),
                      ),
                      TextField(
                        controller: nightController,
                        decoration:
                            const InputDecoration(labelText: 'Night Link'),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        title: Text(expiryDate == null
                            ? 'Select Expiry Date'
                            : DateFormat('yyyy-MM-dd').format(expiryDate!)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              expiryDate = picked;
                            });
                          }
                        },
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final FirebaseFirestore firestore =
                              FirebaseFirestore.instance;
                          Map<String, String> links = {
                            'morning': morningController.text,
                            'afternoon': afternoonController.text,
                            'evening': eveningController.text,
                            'night': nightController.text,
                          };

                          if (expiryDate != null) {
                            updateClientData(index, links, expiryDate!);
                            try {
                              await firestore
                                  .collection('users')
                                  .doc(userIDs)
                                  .set({
                                'morning': morningController.text,
                            'afternoon': afternoonController.text,
                            'evening': eveningController.text,
                            'night': nightController.text,
                                'expiry_date': expiryDate,
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Data saved")));
                              
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text("Failed to save data: $e")));
                            }
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text("Please select an expiry date."),
                            ));
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
              subtitle: Text('User ID: ${clientsData[index]['userId']}'),
              onTap: () {
                _showClientDetailsPage(index);
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
