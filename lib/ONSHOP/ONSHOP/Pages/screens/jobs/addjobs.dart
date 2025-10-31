import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class AddJobPage extends StatefulWidget {
  @override
  _AddJobPageState createState() => _AddJobPageState();
}

class _AddJobPageState extends State<AddJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _postedDateController = TextEditingController();
  final _salaryController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _contactNumberController = TextEditingController();

  String? selectedGender;
  String? selectedCity;
  String? selectedTimeFrom;
  String? selectedTimeTo;

  List<String> cities = [];
  List<String> timeOptions = [
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
    '07:00 PM',
    '08:00 PM',
    '09:00 PM',
    '10:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _postedDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _fetchCities();
  }

  Future<void> _fetchCities() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('cities').get();
      final cityList = querySnapshot.docs.map((doc) => doc['name'] as String).toList();
      setState(() {
        cities = cityList;
      });
    } catch (e) {
      print('Error fetching cities: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (selectedDate != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(selectedDate);
    }
  }

  Future<void> _addJob() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final title = _titleController.text;
        final description = _descriptionController.text;
        final postedDate = DateFormat('yyyy-MM-dd').parse(_postedDateController.text);
        final salary = _salaryController.text;
        final qualification = _qualificationController.text;
        final contactNumber = _contactNumberController.text;

        await FirebaseFirestore.instance.collection('jobs').add({
          'title': title,
          'description': description,
          'posteddate': postedDate,
          'gender': selectedGender,
          'city': selectedCity,
          'salary': salary,
          'qualification': qualification,
          'mobile': contactNumber,
          'timeFrom': selectedTimeFrom,
          'timeTo': selectedTimeTo,
        });

        // Clear the form after submission
        _titleController.clear();
        _descriptionController.clear();
        _postedDateController.clear();
        _salaryController.clear();
        _qualificationController.clear();
        _contactNumberController.clear();
        setState(() {
          selectedGender = null;
          selectedCity = null;
          selectedTimeFrom = null;
          selectedTimeTo = null;
        });

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job added successfully!')),
        );

        // Optionally, navigate back to the previous screen
        Navigator.pop(context);
      } catch (e) {
        print('Error adding job: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add job. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent to allow gradient
        toolbarHeight: 70,
        elevation: 0, // Remove shadow if not needed
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
                const SizedBox(width: 45),
                
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Add Job Vacancy',
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Job Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _postedDateController,
                  decoration: InputDecoration(
                    labelText: 'Posted Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  readOnly: true, // Prevent manual input
                  onTap: () => _selectDate(context, _postedDateController), // Show date picker on tap
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  onChanged: (newValue) {
                    setState(() {
                      selectedGender = newValue;
                    });
                  },
                  items: ['Male', 'Female'].map((gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a gender';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCity,
                  onChanged: (newValue) {
                    setState(() {
                      selectedCity = newValue;
                    });
                  },
                  items: cities.map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a city';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _salaryController,
                  decoration: InputDecoration(
                    labelText: 'Salary (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedTimeFrom,
                  onChanged: (newValue) {
                    setState(() {
                      selectedTimeFrom = newValue;
                    });
                  },
                  items: timeOptions.map((time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Time From',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a start time';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedTimeTo,
                  onChanged: (newValue) {
                    setState(() {
                      selectedTimeTo = newValue;
                    });
                  },
                  items: timeOptions.map((time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Time To',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an end time';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _qualificationController,
                  decoration: InputDecoration(
                    labelText: 'Qualification',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a qualification';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _contactNumberController,
                  decoration: InputDecoration(
                    labelText: 'Contact Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length != 10) {
                      return 'Please enter a valid 10-digit contact number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addJob,
                    child: Text('Submit Job'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 185, 41),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}