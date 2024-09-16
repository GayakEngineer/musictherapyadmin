import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For date formatting

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AdminApp(),
    );
  }
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  _AdminAppState createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  List<Map<String, dynamic>> clientsData = [];
  late String userIDs;
  final Random _random = Random(); // Random number generator

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

  // Delete client data from SharedPreferences
  Future<void> deleteClientData(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      clientsData.removeAt(index);
      List<String> clientDataList =
          clientsData.map((item) => json.encode(item)).toList();
      prefs.setStringList('clientsData', clientDataList);
    });
  }

  // Generate a unique 4-digit user ID
  String generateUniqueUserId() {
    String userId;
    do {
      userId = (_random.nextInt(9000) + 1000).toString(); // Generates a 4-digit number
    } while (clientsData.any((client) => client['userId'] == userId));
    return userId;
  }

  // Show dialog to add a new client with auto-generated user ID
  void _showAddClientDialog() {
    TextEditingController nameController = TextEditingController();
    String userId = generateUniqueUserId();

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
              const SizedBox(height: 10),
              Text('Generated User ID: $userId'),
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
                if (clientName.isNotEmpty) {
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

    // Pre-fill the data if it exists for the client
    Map<String, String> storedLinks = Map<String, String>.from(clientsData[index]['links']);
    morningController.text = storedLinks['morning'] ?? '';
    afternoonController.text = storedLinks['afternoon'] ?? '';
    eveningController.text = storedLinks['evening'] ?? '';
    nightController.text = storedLinks['night'] ?? '';
    expiryDate = clientsData[index]['expiryDate'] != null
        ? DateTime.parse(clientsData[index]['expiryDate'])
        : null;

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
                      const SizedBox(height: 10),
                      ListTile(
                        title: Text(expiryDate == null
                            ? 'Select Expiry Date'
                            : DateFormat('yyyy-MM-dd').format(expiryDate!)),
                        trailing: const Icon(Icons.calendar_today),
                        
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: expiryDate ?? DateTime.now(),
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

  // Show a confirmation dialog to delete a client
  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Client'),
          content: const Text('Are you sure you want to delete this client?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                deleteClientData(index);
                Navigator.of(context).pop();
              },
              child: const Text('Yes'),
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
           // Parse the expiry date from the stored data
        DateTime? expiryDate = clientsData[index]['expiryDate'] != null
            ? DateTime.parse(clientsData[index]['expiryDate'])
            : null;

        // Calculate the days remaining if expiryDate exists
        String expiryStatus;
        if (expiryDate != null) {
          int daysRemaining = expiryDate.difference(DateTime.now()).inDays;

          if (daysRemaining < 0) {
            expiryStatus = 'Audio expired';
          } else if (daysRemaining == 0) {
            expiryStatus = 'Audio expires today';
          } else {
            expiryStatus = 'Days left: $daysRemaining';
          }
        } else {
          expiryStatus = 'No expiry date set';
        }
          return Card(
            child: ListTile(
              title: Text('Name: ${clientsData[index]['name']}'),
              subtitle: Text('User ID: ${clientsData[index]['userId']}\n$expiryStatus'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _showDeleteConfirmationDialog(index);
                },
              ),
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
