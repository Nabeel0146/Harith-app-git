import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddNewItemButton extends StatefulWidget {
  final List<String> cities;
  final String subcategory;

  const AddNewItemButton({
    required this.cities,
    required this.subcategory,
    Key? key,
  }) : super(key: key);

  @override
  _AddNewItemButtonState createState() => _AddNewItemButtonState();
}

class _AddNewItemButtonState extends State<AddNewItemButton> {
  late String selectedCity;
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController mobileController;
  late TextEditingController whatsappController;
  bool display = false; // Display is false by default

  @override
  void initState() {
    super.initState();
    selectedCity = widget.cities.isNotEmpty ? widget.cities.first : '';
    nameController = TextEditingController();
    descriptionController = TextEditingController();
    mobileController = TextEditingController();
    whatsappController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    mobileController.dispose();
    whatsappController.dispose();
    super.dispose();
  }

  Future<void> _addNewItem(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Item'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    TextField(
                      controller: mobileController,
                      decoration: const InputDecoration(labelText: 'Mobile'),
                    ),
                    TextField(
                      controller: whatsappController,
                      decoration: const InputDecoration(labelText: 'WhatsApp'),
                    ),
                    DropdownButton<String>(
                      value: selectedCity.isEmpty ? null : selectedCity,
                      onChanged: (value) {
                        setState(() {
                          selectedCity = value!;
                        });
                      },
                      items: widget.cities
                          .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                          .toList(),
                      hint: const Text('Select City'), // Provide a hint if no city is selected
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (selectedCity.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a city')),
                  );
                  return;
                }
                try {
                  await FirebaseFirestore.instance.collection('shops').add({
                    'name': nameController.text,
                    'description': descriptionController.text,
                    'mobile': mobileController.text,
                    'whatsapp': whatsappController.text,
                    'city': selectedCity,
                    'subcategory': widget.subcategory,
                    'display': display,
                  });

                  // Show confirmation message
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Your Request is submitted to admin. It will be listed after Admin Approve.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  print('Error saving item: $e');
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _addNewItem(context),
      child: const Icon(Icons.add),
      backgroundColor: Colors.green,
    );
  }
}