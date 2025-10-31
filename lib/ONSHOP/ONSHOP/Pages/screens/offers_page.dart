import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:harithagramam/1SCREENS/ONSHOP/Pages/utils/offappbar.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OffersPage extends StatefulWidget {
  @override
  _OffersPageState createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  String? selectedCity;
  List<String> cities = [];
  List<Map<String, dynamic>> offers = [];
  bool isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _shopnameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _expirydateController = TextEditingController();
  final TextEditingController _posteddateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  DateTime? _postedDate;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchCities();
    await _loadSelectedCity();
    await _fetchOffers();
  }

  Future<void> _fetchCities() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('cities').get();
      final cityList =
          querySnapshot.docs.map((doc) => doc['name'] as String).toList();
      setState(() {
        cities = cityList;
      });
    } catch (e) {
      print('Error fetching cities: $e');
    }
  }

  Future<void> _loadSelectedCity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedCity = prefs.getString('selectedCity');
    });

    if (selectedCity == null) {
      await _fetchLoggedInUserCity();
    }
  }

  Future<void> _fetchLoggedInUserCity() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final userCity = userDoc.data()?['city'] as String?;
        setState(() {
          selectedCity = userCity ?? (cities.isNotEmpty ? cities.first : null);
        });

        final prefs = await SharedPreferences.getInstance();
        if (selectedCity != null) {
          prefs.setString('selectedCity', selectedCity!);
        }
      }
    } catch (e) {
      print('Error fetching user city: $e');
    }
  }

  Future<void> _fetchOffers() async {
    if (selectedCity == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('city', isEqualTo: selectedCity)
          .where('display', isEqualTo: true)
          .get();

      final offerList = querySnapshot.docs.map((doc) {
        return {
          'title': doc['title'],
          'description': doc['description'],
          'mobile': doc['mobile'],
          'posteddate': doc['posteddate'].toDate(),
          'expirydate': doc['expirydate'].toDate(),
          'shopname': doc['shopname'],
          'city': doc['city'],
          'image': doc['image'],
        };
      }).toList();

      offerList.sort((a, b) => b['posteddate'].compareTo(a['posteddate']));

      setState(() {
        offers = offerList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching offers: $e");
    }
  }

  void _makeCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (!await launchUrl(uri)) {
        print('Could not launch $uri');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  Future<void> _submitOffer() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('offers').add({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'shopname': _shopnameController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'posteddate': _postedDate ?? DateTime.now(),
          'expirydate': _expiryDate ?? DateTime.now(),
          'city': selectedCity,
          'display': false,
          'image': '',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer submitted successfully!')),
        );

        Navigator.of(context).pop();
        _fetchOffers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting offer: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isExpiryDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isExpiryDate
          ? (_expiryDate ?? DateTime.now())
          : (_postedDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isExpiryDate) {
          _expiryDate = picked;
          _expirydateController.text = "${picked.toLocal()}".split(' ')[0];
        } else {
          _postedDate = picked;
          _posteddateController.text = "${picked.toLocal()}".split(' ')[0];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: OffAppBar(
  selectedCity: selectedCity,
  cities: cities,
  onCityChanged: (newValue) {
    setState(() {
      selectedCity = newValue;
    });

    if (newValue != null) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('selectedCity', newValue);
      });
    }

    // Fetch offers for the new city
    _fetchOffers();
  },
),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : offers.isEmpty
              ? Center(child: Text("No Offers Available"))
              : ListView.builder(
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    String imageUrl = offer['image'] ?? '';
                    print("Image URL: $imageUrl");

                    return Card(
                      margin: const EdgeInsets.all(10),
                      elevation: 5,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromARGB(255, 202, 202, 202),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: Image.network(
                                      imageUrl,
                                      width: double.infinity,
                                      height: 350,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Text('');
                                      },
                                    ),
                                  )
                                : Text(""),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                offer['title'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              offer['description'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (offer['shopname'] != null &&
                                offer['shopname'].isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Shop Name: ${offer['shopname']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text("Mobile: "),
                                const SizedBox(width: 5),
                                Text(
                                  offer['mobile'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Posted on: ${offer['posteddate'].toLocal().toString().split(' ')[0]}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black45,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Expiry: ${offer['expirydate'].toLocal().toString().split(' ')[0]}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.topLeft,
                              child: TextButton(
                                onPressed: () {
                                  _makeCall(offer['mobile']);
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.phone,
                                        size: 20, color: Colors.black54),
                                    SizedBox(width: 10),
                                    Text(
                                      'Call Now',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Add Offer'),
                content: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(labelText: 'Title'),
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter a title' : null,
                        ),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(labelText: 'Description'),
                          validator: (value) => value!.isEmpty
                              ? 'Please enter a description'
                              : null,
                        ),
                        TextFormField(
                          controller: _shopnameController,
                          decoration: InputDecoration(labelText: 'Shop Name'),
                          validator: (value) => value!.isEmpty
                              ? 'Please enter a shop name'
                              : null,
                        ),
                        TextFormField(
                          controller: _mobileController,
                          decoration: InputDecoration(labelText: 'Mobile'),
                          keyboardType: TextInputType.phone,
                          validator: (value) => value!.isEmpty
                              ? 'Please enter a mobile number'
                              : null,
                        ),
                        TextFormField(
                          controller: _posteddateController,
                          decoration: InputDecoration(labelText: 'Posted Date'),
                          readOnly: true,
                          onTap: () => _selectDate(context, false),
                          validator: (value) => value!.isEmpty
                              ? 'Please enter posted date'
                              : null,
                        ),
                        TextFormField(
                          controller: _expirydateController,
                          decoration: InputDecoration(labelText: 'Expiry Date'),
                          readOnly: true,
                          onTap: () => _selectDate(context, true),
                          validator: (value) => value!.isEmpty
                              ? 'Please enter expiry date'
                              : null,
                        ),
                        DropdownButtonFormField<String>(
                          value: selectedCity,
                          items: cities.map((city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(city),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedCity = newValue;
                            });
                          },
                          decoration: InputDecoration(labelText: 'Select City'),
                          validator: (value) =>
                              value == null ? 'Please select a city' : null,
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _submitOffer,
                          child: Text('Submit'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}