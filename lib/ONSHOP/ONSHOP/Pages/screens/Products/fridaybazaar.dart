import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/Products/99deals.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/Products/singleproductpage.dart';

import 'package:url_launcher/url_launcher.dart';

class FridayBazaarSale extends StatefulWidget {
  const FridayBazaarSale({Key? key}) : super(key: key);

  @override
  _FridayBazaarSaleState createState() => _FridayBazaarSaleState();
}

class _FridayBazaarSaleState extends State<FridayBazaarSale> {
  late Future<void> _initializationFuture;
  late bool _isBazaarDay;

  /* ---------- helpers ---------- */
  bool _checkBazaarDay() {
    final int weekday = DateTime.now().weekday;
    return weekday == DateTime.friday || weekday == DateTime.saturday;
  }

  Future<void> _initializeData() async {
    _isBazaarDay = _checkBazaarDay();
    print('Bazaar-day check: $_isBazaarDay');
  }

  /* ---------- Firestore ---------- */
  Future<List<Map<String, dynamic>>> _fetchFridayBazaarItems() async {
    try {
      print('Fetching Friday Bazaar items…');
      final qs = await FirebaseFirestore.instance
          .collection('products')
          .where('fridaybazaar', isEqualTo: true)
          .where('display', isEqualTo: true)
          .get();
      print('Items fetched: ${qs.docs.length}');
      return qs.docs.map((d) => d.data()).toList();
    } catch (e) {
      print('Error fetching items: $e');
      return [];
    }
  }

  /* ---------- User address ---------- */
  Future<String> getUserAddress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'No address provided';

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!snap.exists) return 'No address provided';

      return snap.data()?['address'] ?? 'No address provided';
    } catch (e) {
      print('Error fetching address: $e');
      return 'No address provided';
    }
  }

  /* ---------- WhatsApp ---------- */
  Future<void> _openWhatsApp(
    String phoneNumber,
    String productName,
    int price,
    int discountedPrice,
    String description,
  ) async {
    final address = await getUserAddress();
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final text = '''
Name: $productName
Price: ₹$price
Discounted Price: ₹$discountedPrice
Description: $description
Address: $address
''';
    final uri = Uri.parse(
        'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(text)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open WhatsApp for $phoneNumber')),
      );
    }
  }

  /* ---------- Lifecycle ---------- */
  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeData();
  }

  /* ---------- UI ---------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        toolbarHeight: 70,
        elevation: 0,
        flexibleSpace: Container(
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
                const SizedBox(width: 15),
                ClipRRect(
                  child:
                      Image.asset('asset/onshopnewcurvedlogo.png', width: 50),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
        padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
        child: FutureBuilder<void>(
          future: _initializationFuture,
          builder: (context, initSnap) {
            if (initSnap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            /* ----- NOT Friday or Saturday ----- */
            if (!_isBazaarDay) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('asset/99deals.png',
                        width: double.infinity, fit: BoxFit.fitHeight),
                    const SizedBox(height: 24),
                    const Text(
                      'Friday Bazaar is open only on\nFriday & Saturday',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Come back then for the best discounts!',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            /* ----- Friday or Saturday -> show products ----- */
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchFridayBazaarItems(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }

                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No items found for Friday Bazaar Sale.',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NinetyNineDealsPage())),
                        child: Image.asset('asset/99deals.png',
                            width: double.infinity, fit: BoxFit.fitHeight),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Text(
                            'Welcome To Friday Bazaar',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Get the products at the best discounted price ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Only On Fridays',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color.fromARGB(255, 217, 23, 10),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.55,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SingleProductPage(product: item),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey, width: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (item['image_url'] != null &&
                                              item['image_url']
                                                  .toString()
                                                  .isNotEmpty)
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: AspectRatio(
                                                aspectRatio: 4 / 4,
                                                child: CachedNetworkImage(
                                                  imageUrl: item['image_url'],
                                                  fit: BoxFit.cover,
                                                  placeholder: (_, __) =>
                                                      Container(
                                                    color: Colors.grey[300],
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  ),
                                                  errorWidget: (_, __, ___) =>
                                                      Container(
                                                    color: Colors.grey[300],
                                                    child:
                                                        const Icon(Icons.error),
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
                                                horizontal: 8),
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
                                                horizontal: 2),
                                            child: Container(
                                              padding: const EdgeInsets.only(
                                                  left: 6,
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
                                                horizontal: 8),
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
                                                horizontal: 8),
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
                                          horizontal: 1, vertical: 2),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (item['whatsappnumber'] != null) {
                                            _openWhatsApp(
                                              item['whatsappnumber'],
                                              item['name'] ?? 'No Name',
                                              item['price'] ?? 0,
                                              item['discountedprice'] ?? 0,
                                              item['description'] ??
                                                  'No Description',
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
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
                    ],
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
