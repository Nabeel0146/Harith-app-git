import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:harithagramam/1SCREENS/ONSHOP/Pages/screens/Products/singleproductpage.dart';

import 'package:url_launcher/url_launcher.dart';

class ProductsPage extends StatefulWidget {
  final String category;

  const ProductsPage({required this.category, Key? key}) : super(key: key);

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeData();
  }

  Future<void> _initializeData() async {
    // Initialization logic if needed
  }

  Future<List<Map<String, dynamic>>> _fetchFilteredItems(
      String category) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: category)
          .where('display', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching items: $e');
      return [];
    }
  }

  Future<String> getUserAddress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return 'No address provided';
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!userDoc.exists) {
        return 'No address provided';
      }

      return userDoc.data()?['address'] ?? 'No address provided';
    } catch (e) {
      print('Error fetching user address: $e');
      return 'No address provided';
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, String productName, int price,
      int discountedPrice, String description) async {
    final userAddress = await getUserAddress();
    final formattedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final productDetails = """
    Name: $productName
    Price: ₹$price
    Discounted Price: ₹$discountedPrice
    Description: $description
    Address: $userAddress
    """;

    final uri = Uri.parse(
        'https://wa.me/$formattedPhoneNumber?text=${Uri.encodeComponent(productDetails)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open WhatsApp for $phoneNumber')),
      );
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
                ClipRRect(
                  child:
                      Image.asset("asset/onshopnewcurvedlogo.png", width: 50),
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
      body: Container(
        padding: EdgeInsets.only(top: 30, left: 10, right: 10),
        child: FutureBuilder<void>(
          future: _initializationFuture,
          builder: (context, initializationSnapshot) {
            if (initializationSnapshot.connectionState !=
                ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchFilteredItems(widget.category),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const Center(
                    child: Text('No items found for this category.',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  );
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: 30),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio:
                          0.55, // Adjust this value to give more height to each grid item
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SingleProductPage(product: item),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors
                                  .grey, // You can change the border color as needed
                              width: 0.5, // Set the border width to 0.5
                            ),
                            borderRadius: BorderRadius.circular(
                                8), // Optional: Add rounded corners
                          ),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (item['image_url'] != null &&
                                          item['image_url'].toString().isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: AspectRatio(
                                            aspectRatio: 4 / 4,
                                            child: CachedNetworkImage(
                                              imageUrl: item['image_url'],
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                  Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.error),
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        AspectRatio(
                                          aspectRatio: 3 / 3,
                                          child: Container(
                                            color: Colors.grey[300],
                                            child: const Icon(
                                                Icons.image_not_supported),
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Text(
                                          item['name'] ?? 'No Name',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 2.0),
                                        child: Container(
                                          padding: const EdgeInsets.only(
                                              left: 6.0,
                                              right: 6,
                                              top: 2,
                                              bottom: 2),
                                          child: Text(
                                            item['description'] ??
                                                'No Description',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color.fromARGB(
                                                  255, 107, 160, 107),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Text(
                                          'MRP ₹${item['price'] ?? 'N/A'}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Text(
                                          '₹${item['discountedprice'] ?? 'N/A'}',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 1.0, vertical: 2.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (item['whatsappnumber'] != null) {
                                        _openWhatsApp(
                                          item['whatsappnumber'],
                                          item['name'] ?? 'No Name',
                                          item['price'] ?? 0,
                                          item['discountedprice'] ?? 0,
                                          item['description'] ?? 'No Description',
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize
                                          .min, // Wrap content tightly
                                      children: [
                                        Image.asset(
                                          'asset/whatsapp.png',
                                          width: 16,
                                          height: 16,
                                        ),
                                        const SizedBox(width: 2),
                                        const Text(
                                          'Order on Whatsapp',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}