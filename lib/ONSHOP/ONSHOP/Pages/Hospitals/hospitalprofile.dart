import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:harithagramam/1SCREENS/ONSHOP/Pages/Hospitals/edithospital.dart';


import 'package:url_launcher/url_launcher.dart';

class HospitalProfilePage extends StatelessWidget {
  final Map<String, dynamic> hospitalData;

  const HospitalProfilePage({required this.hospitalData, Key? key}) : super(key: key);

  void makeCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (!await launchUrl(uri)) {
        print('Could not launch $uri');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  void openWhatsAppChat(String whatsappNumber) async {
    final whatsappUrl = 'https://wa.me/$whatsappNumber';
    try {
      if (!await launchUrl(Uri.parse(whatsappUrl))) {
        print('Could not launch $whatsappUrl');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  void shareDetails(String title, String description, String phoneNumber) async {
    final footer =
        '\n\nShared from Onshop App\n\nDownload Onshop App now\nGoogle Playstore: https://play.google.com/store/apps/details?id=com.onshopin.onshopapp&pcampaignid=web_share\nApp Store: https://apps.apple.com/in/app/on-shop/id6740747263';
    final shareContent = '''
  $title

  $description

  Contact: $phoneNumber
  $footer
  ''';

    // try {
    //   await Share.share(shareContent, subject: 'Check out this hospital on Onshop!');
    //   print('Sharing successful');
    // } catch (e) {
    //   print('Error while sharing: $e');
    // }
  }

  void openMapLink(BuildContext context, String mapLink) async {
    if (mapLink.isNotEmpty) {
      try {
        if (!await launchUrl(Uri.parse(mapLink))) {
          print('Could not launch $mapLink');
        }
      } catch (e) {
        print('Error occurred: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No map link available')),
      );
    }
  }

  Future<String> getUserAddress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return 'No address provided';
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        return 'No address provided';
      }

      return userDoc.data()?['address'] ?? 'No address provided';
    } catch (e) {
      print('Error fetching user address: $e');
      return 'No address provided';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final String hospitalId = hospitalData['hospitalid'] ?? '';
    print('Hospital ID: $hospitalId'); // Debugging: Print the hospital ID

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        toolbarHeight: 70,
        elevation: 0,
        flexibleSpace: Column(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 255, 185, 41),
                      Colors.white,
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
                      ClipRRect(
                        child: Image.asset("asset/onshopnewcurvedlogo.png", width: 50),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'On Shop',
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
            Container(
              height: 4,
              color: const Color.fromARGB(255, 164, 164, 164),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildImageCarousel(),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospitalData['name'] ?? 'No Name',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hospitalData['description'] ?? 'No Description',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildButton(
                        imagePath: "asset/phone-call.png",
                        text: 'Call',
                        color: Colors.blue,
                        onPressed: () {
                          makeCall(hospitalData['phone'] ?? '');
                        },
                      ),
                      _buildButton(
                        imagePath: "asset/whatsapp2.png",
                        text: 'Chat',
                        color: Colors.green,
                        onPressed: () {
                          openWhatsAppChat(hospitalData['whatsapp'] ?? '');
                        },
                      ),
                      _buildButton(
                        imagePath: "asset/share2.png",
                        text: 'Share',
                        color: Colors.amber,
                        onPressed: () {
                          shareDetails(
                            hospitalData['name'] ?? 'No Name',
                            hospitalData['description'] ?? 'No Description',
                            hospitalData['phone'] ?? '',
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: double.infinity,
                    child: _buildButton(
                      imagePath: "asset/google-maps2.png",
                      text: 'Get Direction',
                      color: Colors.black,
                      backgroundColor: Colors.white,
                      borderColor: Colors.black,
                      onPressed: () {
                        openMapLink(context, hospitalData['maplink'] ?? '');
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Doctors",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('doctors')
                        .where('hospitalid', isEqualTo: hospitalId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No doctors found."));
                      }

                      var doctors = snapshot.data!.docs;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          childAspectRatio: 0.9, // Square shape
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 25,
                        ),
                        itemCount: doctors.length,
                        itemBuilder: (context, index) {
                          var doctor = doctors[index].data() as Map<String, dynamic>;
                          String doctorId = doctors[index].id;
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 1),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1), // Shadow color with opacity
                                  spreadRadius: 1, // Spread radius
                                  blurRadius: 2, // Blur radius
                                  offset: const Offset(0, 1), // Offset in the x and y directions
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0), // Add padding inside the border
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start (left)
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: CachedNetworkImage(
                                          imageUrl: doctor['image_url'] ?? '',
                                          placeholder: (context, url) => Container(
                                            color: Colors.grey, // Grey rectangle placeholder
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: Colors.grey, // Grey rectangle for error
                                          ),
                                          fit: BoxFit.fill, // Ensure the image fills the square container
                                          alignment: Alignment.center, // Center the image
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity, // Full width
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey, width: 1),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                doctor['name'] ?? 'No Name',
                                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                doctor['description'] ?? 'No Description',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity, // Full width
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey, width: 1),
                                    ),
                                    child: Text(
                                      'Timing: ${doctor['timing'] ?? 'Not specified'}',
                                      style: const TextStyle(fontSize: 16, color: Colors.black),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity, // Full width
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey, width: 1),
                                    ),
                                    child: Text(
                                      'Days: ${doctor['days'] ?? 'Not specified'}',
                                      style: const TextStyle(fontSize: 16, color: Colors.black),
                                    ),
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showHospitalIdDialog(context, hospitalId);
        },
        tooltip: 'Edit Hospital',
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildImageCarousel() {
    List<String> imageUrls = [
      hospitalData['image_url'] ?? '',
      hospitalData['image1'] ?? '',
      hospitalData['image2'] ?? '',
      hospitalData['image3'] ?? '',
      hospitalData['image4'] ?? '',
      hospitalData['image5'] ?? '',
    ];

    // Filter out empty strings
    imageUrls = imageUrls.where((url) => url.isNotEmpty).toList();

    if (imageUrls.isEmpty) {
      return const Center(
        child: Text('No images available'),
      );
    }

    return CarouselSlider.builder(
      itemCount: imageUrls.length,
      itemBuilder: (context, index, realIndex) {
        return CachedNetworkImage(
          imageUrl: imageUrls[index],
          width: double.infinity,
          height: 300, // Image height same as screen width
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
        );
      },
      options: CarouselOptions(
        height: 300,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 1.0,
        aspectRatio: 2.0,
        initialPage: 0,
      ),
    );
  }

  void _showHospitalIdDialog(BuildContext context, String hospitalId) {
    final TextEditingController _hospitalIdController = TextEditingController();
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            children: [
              const Text('Enter Hospital ID'),
              const SizedBox(height: 20),
            ],
          ),
          content: TextField(
            autofocus: true,
            controller: _hospitalIdController,
            decoration: InputDecoration(
              hintText: 'Hospital ID',
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed: () {
                  final enteredHospitalId = _hospitalIdController.text;
                  if (enteredHospitalId == hospitalId) {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HospitalEditPage(
                          hospitalId: hospitalId,
                          hospitalData: hospitalData,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect Hospital ID')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
        );
      },
    );
  }

  Widget _buildButton({
    required String imagePath,
    required String text,
    required Color color,
    VoidCallback? onPressed,
    Color backgroundColor = Colors.transparent,
    Color borderColor = Colors.black,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 28),
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              imagePath,
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}