import 'dart:io';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddNewHospitalPage extends StatefulWidget {
  final List<String> cities;
  final String subcategory;

  const AddNewHospitalPage({
    required this.cities,
    required this.subcategory,
    Key? key,
  }) : super(key: key);

  @override
  State<AddNewHospitalPage> createState() => _AddNewHospitalPageState();
}

class _AddNewHospitalPageState extends State<AddNewHospitalPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  String? _selectedCity;
  String? _imageUrl;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('images/${pickedFile.name}');
      final uploadTask = storageRef.putFile(File(pickedFile.path));
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _imageUrl = downloadUrl;
      });
    }
  }

  Future<void> _addNewHospital() async {
    final name = _nameController.text;
    final description = _descriptionController.text;
    final mobile = _mobileController.text;
    final whatsapp = _whatsappController.text;
    final imageUrl = _imageUrl;
    final city = _selectedCity;

    if (name.isEmpty || description.isEmpty || mobile.isEmpty || city == null || imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all the required fields')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('hospitallisting').add({
        'name': name,
        'description': description,
        'mobile': mobile,
        'whatsapp': whatsapp,
        'image_url': imageUrl,
        'city': city,
        'subcategory': widget.subcategory,
        'display': false, // Set display to false
        'associate': false,
        'lock': false,
        'customerid': '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hospital added successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding hospital: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Set the default selected city to the first item in the list
    _selectedCity = widget.cities.isNotEmpty ? widget.cities.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Hospital'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Upload Image'),
            ),
            if (_imageUrl != null)
              Image.network(
                _imageUrl!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextFormField(
              controller: _mobileController,
              decoration: const InputDecoration(labelText: 'Mobile'),
            ),
            TextFormField(
              controller: _whatsappController,
              decoration: const InputDecoration(labelText: 'WhatsApp'),
            ),
            DropdownSearch<String>(
              items: widget.cities,
              selectedItem: _selectedCity,
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Search city...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              dropdownButtonProps: const DropdownButtonProps(
                icon: Icon(Icons.arrow_drop_down, color: Colors.black),
              ),
              dropdownDecoratorProps: DropDownDecoratorProps(
                baseStyle: TextStyle(color: Colors.black),
                dropdownSearchDecoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
              ),
              onChanged: (newValue) {
                setState(() {
                  _selectedCity = newValue;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addNewHospital,
              child: const Text('Add Hospital'),
            ),
          ],
        ),
      ),
    );
  }
}