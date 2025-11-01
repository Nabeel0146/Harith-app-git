import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/jobs/addjobs.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';


class JobsListingPage extends StatefulWidget {
  @override
  _JobsListingPageState createState() => _JobsListingPageState();
}

class _JobsListingPageState extends State<JobsListingPage> {
  String? selectedCity;
  List<String> cities = [];
  List<Map<String, dynamic>> jobs = []; // Store job data
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchCities();
    await _loadSelectedCity();
    await _fetchJobs(); // Fetch jobs after loading cities and selected city
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

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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

  Future<void> _fetchJobs() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('jobs').get();
      final jobList = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'title': doc['title'] ?? '',
          'description': doc['description'] ?? '',
          'mobile': doc['mobile'] ?? '',
          'posteddate': (doc['posteddate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'city': doc['city'] ?? '',
          'gender': doc['gender'] ?? '',
          'salary': doc['salary'] ?? '',
          'qualification': doc['qualification'] ?? '',
          'timeFrom': doc['timeFrom'] ?? '',
          'timeTo': doc['timeTo'] ?? '',
        };
      }).toList();

      // Sort the job list by posted date in ascending order
      jobList.sort((a, b) {
        return b['posteddate'].compareTo(a['posteddate']);
      });

      setState(() {
        jobs = jobList;
      });
    } catch (e) {
      print('Error fetching jobs: $e');
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

  void _shareJobDetails(Map<String, dynamic> job) {
    final shareText = """
    Job Title: ${job['title']}
    Description: ${job['description']}
    Mobile: ${job['mobile']}
    City: ${job['city']}
    Gender: ${job['gender']}
    Salary: ${job['salary']}
    Qualification: ${job['qualification']}
    Time From: ${job['timeFrom']}
    Time To: ${job['timeTo']}
    Posted on: ${DateFormat('yyyy-MM-dd').format(job['posteddate'])}
    Shared from OnShop App Jobs
    """;

    // try {
    //   // Use share_plus to share the job details
    //   Share.share(shareText);
    //   print('Sharing job details successful');
    // } catch (e) {
    //   print('Error while sharing job details: $e');
    // }
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
      body: jobs.isEmpty
          ? Center(child: Text("No Jobs Available"))
          : ListView.builder(
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Card(
                    elevation: 0, // Remove the default elevation
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // Curved borders
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job['title'] ?? '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            job['description'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text("Mobile: "),
                              const SizedBox(width: 5),
                              Text(
                                job['mobile'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text("City: ", style: TextStyle(fontWeight: FontWeight.bold),),
                              const SizedBox(width: 5),
                              Text(
                                job['city'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text("Gender: "),
                              const SizedBox(width: 5),
                              Text(
                                job['gender'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text("Salary: "),
                              const SizedBox(width: 5),
                              Text(
                                job['salary'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text("Qualification: "),
                              const SizedBox(width: 5),
                              Text(
                                job['qualification'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text("Time From: "),
                              const SizedBox(width: 5),
                              Text(
                                job['timeFrom'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text("Time To: "),
                              const SizedBox(width: 5),
                              Text(
                                job['timeTo'] ?? '',
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
                                    'Posted on: ${DateFormat('yyyy-MM-dd').format(job['posteddate'])}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    _makeCall(job['mobile'] ?? '');
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center, // Center the icon and text
                                    children: [
                                      Icon(Icons.phone, size: 20, color: Colors.white),
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
                                    padding: const EdgeInsets.symmetric(vertical: 10), // Adjust padding as needed
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10), // Add some space between the buttons
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    _shareJobDetails(job);
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center, // Center the icon and text
                                    children: [
                                      Icon(Icons.share, size: 20, color: Colors.white),
                                      SizedBox(width: 10),
                                      Text(
                                        'Share',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(vertical: 10), // Adjust padding as needed
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddJobPage()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.amber,
      ),
    );
  }
}