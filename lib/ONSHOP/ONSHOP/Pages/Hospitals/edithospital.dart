import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class HospitalEditPage extends StatefulWidget {
  final String hospitalId;
  final Map<String, dynamic> hospitalData;

  const HospitalEditPage({
    required this.hospitalId,
    required this.hospitalData,
    Key? key,
  }) : super(key: key);

  @override
  State<HospitalEditPage> createState() => _HospitalEditPageState();
}

class _HospitalEditPageState extends State<HospitalEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _imageUrlController;
  late TextEditingController _mapLinkController;

  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _doctorDescriptionController =
      TextEditingController();
  final TextEditingController _doctorTimingController = TextEditingController();
  final TextEditingController _doctorDaysController = TextEditingController();
  final TextEditingController _doctorImageUrlController =
      TextEditingController(); // Define here

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.hospitalData['name']);
    _descriptionController =
        TextEditingController(text: widget.hospitalData['description']);
    _phoneController =
        TextEditingController(text: widget.hospitalData['mobile']);
    _whatsappController =
        TextEditingController(text: widget.hospitalData['whatsapp']);
    _imageUrlController =
        TextEditingController(text: widget.hospitalData['image_url']);
    _mapLinkController =
        TextEditingController(text: widget.hospitalData['maplink']);

    // Debug statement to print the hospitalData
    print('Hospital Data: ${widget.hospitalData}');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _imageUrlController.dispose();
    _mapLinkController.dispose();
    _doctorNameController.dispose();
    _doctorDescriptionController.dispose();
    _doctorTimingController.dispose();
    _doctorDaysController.dispose();
    super.dispose();
  }

  Future<void> _updateHospital() async {
  final name = _nameController.text;
  final description = _descriptionController.text;
  final phone = _phoneController.text;
  final whatsapp = _whatsappController.text;
  final mapLink = _mapLinkController.text;

  if (name.isEmpty || description.isEmpty || phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all the required fields')),
    );
    return;
  }

  try {
    // 🔍 Fetch the document where the field 'hospitalid' matches widget.hospitalId
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('hospitallisting')
        .where('hospitalid', isEqualTo: widget.hospitalId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hospital document not found')),
      );
      return;
    }

    // ✅ Get the actual Firestore document ID
    DocumentSnapshot doc = querySnapshot.docs.first;
    String actualDocId = doc.id;
    print('Actual Document ID: $actualDocId');

    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch hospital data')),
      );
      return;
    }

    String imageUrl = data['image_url'] ?? '';

    if (_selectedImage != null) {
      try {
        imageUrl = await _uploadImage(_selectedImage!);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
        return;
      }
    }

    await FirebaseFirestore.instance
        .collection('hospitallisting')
        .doc(actualDocId)
        .update({
      'name': name,
      'description': description,
      'mobile': phone,
      'whatsapp': whatsapp,
      'image_url': imageUrl,
      'maplink': mapLink,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hospital updated successfully')),
    );
    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating hospital: $e')),
    );
  }
}


  void _showAddDoctorDialog() {
    List<String> daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    String? selectedStartDay = daysOfWeek.first;
    String? selectedEndDay = daysOfWeek.last;

    TimeOfDay? startTime; // Define startTime
    TimeOfDay? endTime; // Define endTime

    File? localDoctorImage; // Local variable to hold the selected doctor image

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Doctor'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final ImagePicker _picker = ImagePicker();
                      final XFile? pickedFile =
                          await _picker.pickImage(source: ImageSource.gallery);

                      if (pickedFile != null) {
                        setState(() {
                          localDoctorImage = File(pickedFile.path);
                        });
                      }
                    },
                    child: Text("Pick Image"),
                  ),
                  const SizedBox(height: 10),
                  if (localDoctorImage != null)
                    Image.file(localDoctorImage!,
                        width: 100, height: 100, fit: BoxFit.cover),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _doctorNameController,
                    decoration: InputDecoration(
                      labelText: 'Doctor Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _doctorDescriptionController,
                    decoration: InputDecoration(
                      labelText: 'Doctor Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Colors.grey, width: 1),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  startTime = picked;
                                });
                              }
                            },
                            child: Text(
                              startTime == null
                                  ? 'Select Start Time'
                                  : startTime!.format(context).toString(),
                              style: TextStyle(
                                  color: startTime == null
                                      ? Colors.grey
                                      : Colors.black),
                            ),
                          ),
                        ),
                        const Text('to'),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  endTime = picked;
                                });
                              }
                            },
                            child: Text(
                              endTime == null
                                  ? 'Select End Time'
                                  : endTime!.format(context).toString(),
                              style: TextStyle(
                                  color: endTime == null
                                      ? Colors.grey
                                      : Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedStartDay,
                            items: daysOfWeek.map((day) {
                              return DropdownMenuItem<String>(
                                value: day,
                                child: Text(day),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedStartDay = value;
                              });
                            },
                            decoration:
                                const InputDecoration(labelText: 'From'),
                          ),
                        ),
                        const Text('to'),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedEndDay,
                            items: daysOfWeek.map((day) {
                              return DropdownMenuItem<String>(
                                value: day,
                                child: Text(day),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedEndDay = value;
                              });
                            },
                            decoration: const InputDecoration(labelText: 'To'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (startTime != null &&
                        endTime != null &&
                        selectedStartDay != null &&
                        selectedEndDay != null) {
                      String imageUrl = '';
                      if (localDoctorImage != null) {
                        try {
                          imageUrl =
                              await _uploadDoctorImage(localDoctorImage!);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error uploading image: $e')),
                          );
                          return;
                        }
                      }
                      _addDoctor(
                        startTime!,
                        endTime!,
                        selectedStartDay!,
                        selectedEndDay!,
                        imageUrl,
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Please select all time and day fields')),
                      );
                    }
                  },
                  child: const Text('Add Doctor'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> _uploadImage(File imageFile) async {
    Reference storageReference = FirebaseStorage.instance.ref().child(
        'hospital_images/${widget.hospitalId}/${DateTime.now().millisecondsSinceEpoch}');
    UploadTask uploadTask = storageReference.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> _addDoctor(TimeOfDay startTime, TimeOfDay endTime,
      String startDay, String endDay, String imageUrl) async {
    final name = _doctorNameController.text;
    final description = _doctorDescriptionController.text;

    if (name.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please fill all the required fields for the doctor')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('doctors').add({
        'name': name,
        'description': description,
        'timing': '${startTime.format(context)}-${endTime.format(context)}',
        'days': '$startDay-$endDay',
        'hospital': widget.hospitalData['name'],
        'hospitalid': widget.hospitalId,
        'image_url': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor added successfully')),
      );
      _doctorNameController.clear();
      _doctorDescriptionController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding doctor: $e')),
      );
    }
  }

  Future<String> _uploadDoctorImage(File imageFile) async {
    if (imageFile == null) {
      throw 'No image selected';
    }

    Reference storageReference = FirebaseStorage.instance.ref().child(
        'doctor_images/${widget.hospitalId}/${DateTime.now().millisecondsSinceEpoch}');
    UploadTask uploadTask = storageReference.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;

    return await taskSnapshot.ref.getDownloadURL();
  }

  File? _selectedImage; // For hospital image

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showEditDoctorDialog(String doctorId, Map<String, dynamic> doctorData) {
    final TextEditingController nameController =
        TextEditingController(text: doctorData['name']);
    final TextEditingController descriptionController =
        TextEditingController(text: doctorData['description']);
    final TextEditingController timingController =
        TextEditingController(text: doctorData['timing']);
    final TextEditingController daysController =
        TextEditingController(text: doctorData['days']);

    String? currentImageUrl =
        doctorData['image_url']; // Current image URL from Firestore
    File? localDoctorImage; // Local variable to hold the selected doctor image

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Doctor'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Display current image or a placeholder
                  currentImageUrl != null && currentImageUrl.isNotEmpty
                      ? Image.network(
                          currentImageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : Icon(Icons.image, size: 100),
                  ElevatedButton(
                    onPressed: () async {
                      final ImagePicker _picker = ImagePicker();
                      final XFile? pickedFile =
                          await _picker.pickImage(source: ImageSource.gallery);

                      if (pickedFile != null) {
                        setState(() {
                          localDoctorImage = File(pickedFile.path);
                        });
                      }
                    },
                    child: Text("Change Image"),
                  ),
                  if (localDoctorImage != null)
                    Image.file(localDoctorImage!,
                        width: 100, height: 100, fit: BoxFit.cover),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Doctor Name'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descriptionController,
                    decoration:
                        const InputDecoration(labelText: 'Doctor Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: timingController,
                    decoration: const InputDecoration(labelText: 'Timing'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: daysController,
                    decoration: const InputDecoration(labelText: 'Days'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text;
                    final description = descriptionController.text;
                    final timing = timingController.text;
                    final days = daysController.text;

                    if (name.isEmpty ||
                        description.isEmpty ||
                        timing.isEmpty ||
                        days.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Please fill all the required fields')),
                      );
                      return;
                    }

                    String imageUrl = currentImageUrl ?? '';
                    if (localDoctorImage != null) {
                      try {
                        imageUrl = await _uploadDoctorImage(localDoctorImage!);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error uploading image: $e')),
                        );
                        return;
                      }
                    }

                    try {
                      await FirebaseFirestore.instance
                          .collection('doctors')
                          .doc(doctorId)
                          .update({
                        'name': name,
                        'description': description,
                        'timing': timing,
                        'days': days,
                        'image_url': imageUrl,
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Doctor updated successfully')),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating doctor: $e')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 255, 185, 41), // Yellow at the top
                Colors.white, // White at the bottom
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text(
                        'Edit Hospital Profile',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display the current image
            if (widget.hospitalData['image_url'] != null &&
                widget.hospitalData['image_url'].isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  widget.hospitalData['image_url'],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              )
            else
              Icon(Icons.image, size: 100),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Change Image"),
            ),

            if (_selectedImage != null)
              Image.file(_selectedImage!,
                  width: 100, height: 100, fit: BoxFit.cover),

            SizedBox(height: 20),

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
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextFormField(
              controller: _whatsappController,
              decoration: const InputDecoration(labelText: 'WhatsApp'),
            ),
            TextFormField(
              controller: _mapLinkController,
              decoration: const InputDecoration(labelText: 'Map Link'),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity, // Full width
              margin: const EdgeInsets.symmetric(
                  vertical: 10.0), // Add some vertical margin
              child: GestureDetector(
                onTap: _updateHospital, // Handle the tap event
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0), // Add padding inside the container
                  decoration: BoxDecoration(
                    color: Colors.amber, // Amber background color
                    borderRadius: BorderRadius.circular(8.0), // Rounded corners
                  ),
                  child: const Text(
                    'Update Hospital',
                    textAlign: TextAlign.center, // Center the text
                    style: TextStyle(
                      color: Colors.white, // Text color
                      fontSize: 14.0, // Font size
                      fontWeight: FontWeight.bold, // Bold font weight
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Doctors",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _showAddDoctorDialog,
                  child: const Text('Add Doctor'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('doctors')
      .where('hospitalid', isEqualTo: widget.hospitalId)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Center(child: Text("No doctors found."));
    }

    var doctors = snapshot.data!.docs;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        var doctor = doctors[index].data() as Map<String, dynamic>;
        String doctorId = doctors[index].id;

        // Extract the image URL from the doctor's data
        String imageUrl = doctor['image_url'] ?? '';

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
                color: Colors.grey, width: 1), // Add a border
            borderRadius:
                BorderRadius.circular(10), // Rounded corners
          ),
          child: ListTile(
            // Display the doctor's image in the leading part
            leading: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.image, size: 50, color: Colors.grey),

            title: Text(doctor['name'] ?? 'Unnamed Doctor'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor['description'] ?? ''),
                Text('Timing: ${doctor['timing'] ?? ''}'),
                Text('Days: ${doctor['days'] ?? ''}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditDoctorDialog(doctorId, doctor),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('doctors')
                          .doc(doctorId)
                          .delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Doctor deleted successfully')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting doctor: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  },
),
          ],
        ),
      ),
    );
  }
}
