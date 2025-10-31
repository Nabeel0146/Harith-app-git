import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

class SearchResultsPage extends StatefulWidget {
  @override
  _SearchResultsPageState createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List<DocumentSnapshot> _searchResults = [];
  TextEditingController _searchController = TextEditingController();
  String? selectedCity;
  List<String> cities = [];

  @override
  void initState() {
    super.initState();
    _fetchCities();
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

  Future<void> _searchShops(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final shopSnapshot = await FirebaseFirestore.instance
          .collection('shops')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      final citySnapshot = await FirebaseFirestore.instance
          .collection('shops')
          .where('city', isGreaterThanOrEqualTo: query)
          .where('city', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // Combine results and use a Set to remove duplicates based on 'name' and 'city'
      final uniqueResults = <String, DocumentSnapshot>{};

      for (var doc in shopSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['display'] == true) { // Filter by `display` field
          final key = '${data['name']}-${data['city']}';
          uniqueResults[key] = doc;
        }
      }

      for (var doc in citySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['display'] == true) { // Filter by `display` field
          final key = '${data['name']}-${data['city']}';
          uniqueResults[key] = doc;
        }
      }

      setState(() {
        _searchResults = uniqueResults.values.toList();
      });
    } catch (error) {
      print("Error searching for shops: $error");
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

  void _openWhatsApp(String? phoneNumber) {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final formattedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      final uri = 'https://wa.me/$formattedPhoneNumber';
      launch(uri).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Could not open WhatsApp for $formattedPhoneNumber')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('WhatsApp is not available for this number')),
      );
    }
  }

  void _shareDetails(
      String title, String description, String phoneNumber) async {
    final footer =
        '\n\nShared from Onshop App. Download Onshop App now from Google Playstore / App Store';
    final shareContent = '''
$title

$description

Contact: $phoneNumber
$footer
''';

    // try {
    //   await Share.share(shareContent,
    //       subject: 'Check out this item on Onshop!');
    //   print('Sharing successful');
    // } catch (e) {
    //   print('Error while sharing: $e');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
                const SizedBox(width: 15),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                _searchShops(query);
              },
              decoration: InputDecoration(
                hintText: 'Search by name or city...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          _searchResults.isEmpty
              ? const Expanded(child: Center(child: Text('No results found')))
              : Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final shop = _searchResults[index];
                      final data = shop.data() as Map<String, dynamic>?;

                      final name = data?['name'] ?? 'No name available';
                      final city = data?['city'] ?? 'No city available';
                      final description =
                          data?['description'] ?? 'No description available';
                      final phone = data?['mobile'] ?? 'No phone available';
                      final whatsapp =
                          data?['whatsapp'] ?? 'No WhatsApp available';
                      final imageUrl = data?.containsKey('image_url') == true
                          ? data!['image_url']
                          : 'https://onshop.in/categories/unnamed.png'; // Placeholder image

                      return GestureDetector(
                        onTap: () {
                          // Handle tap to view shop profile
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey[400]!, // Border color
                              width: 1.0, // Border width
                            ),
                          ),
                          color: const Color.fromARGB(255, 255, 255, 255),
                          elevation: 2,
                          shadowColor: Colors.grey.withOpacity(0.8),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 14.0, right: 14, bottom: 14, top: 22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (imageUrl != null && imageUrl.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                            width: 80,
                                            height: 80,
                                            color: const Color.fromARGB(
                                                255,
                                                235,
                                                235,
                                                235), // Placeholder background
                                            child: const Center(
                                              child: SizedBox(
                                                width: 16, // Smaller size
                                                height: 16, // Smaller size
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth:
                                                      2, // Thinner stroke
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                          Colors
                                                              .black), // Black color
                                                ),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.error,
                                                color: Colors.red),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                            Icons.image_not_supported,
                                            size: 30),
                                      ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                          if (description.isNotEmpty)
                                            Text(description,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 12)),
                                          if (phone.isNotEmpty)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                    'Mobile: $phone',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 12)),
                                                Row(
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () {
                                                        _makeCall(phone);
                                                      },
                                                      child: Image.asset(
                                                        "asset/phone-call.png",
                                                        width: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    if (whatsapp.isNotEmpty)
                                                      GestureDetector(
                                                        onTap: () {
                                                          _openWhatsApp(whatsapp);
                                                        },
                                                        child: Image.asset(
                                                          "asset/whatsapp2.png",
                                                          width: 20,
                                                        ),
                                                      ),
                                                    const SizedBox(width: 10),
                                                    GestureDetector(
                                                      onTap: () {
                                                        if (data?['name'] !=
                                                                null &&
                                                            data?['description'] !=
                                                                null &&
                                                            data?['mobile'] !=
                                                                null) {
                                                          _shareDetails(
                                                              data!['name'],
                                                              data['description'],
                                                              data['mobile']);
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    'Unable to share. Missing item details.')),
                                                          );
                                                        }
                                                      },
                                                      child: Image.asset(
                                                        "asset/share2.png",
                                                        width: 20,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                        ],
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
                ),
        ],
      ),
    );
  }
}