// lib/1SCREENS/Homemade/homemade_products_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:harithapp/Screens/homemade/addhomemade.dart';
import 'package:harithapp/Screens/homemade/singlehomemade.dart';
import 'package:harithapp/widgets/productcard.dart';

class HomemadeProductsPage extends StatelessWidget {
  const HomemadeProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 116, 190, 119),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Homemade Products',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'വീട്ടിൽ ഉത്പ്പാദിപ്പിക്കുന്ന സാധനങ്ങൾ വിൽക്കാനുള്ള ഒരു ഇടം ',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('harith_market_products')
            .where('display', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.eco,
                    size: 80,
                    color: Color.fromARGB(255, 116, 190, 119),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No Homemade Products Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Be the first to add your homemade product!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final doc = products[index];
                final product = doc.data() as Map<String, dynamic>;
                final productId = doc.id;

                // Handle pricing logic
                final originalPrice = product['price']?.toString() ?? '';
                final discountedPrice = product['discountedprice']?.toString() ?? '';
                
                // If discounted price exists, show both prices
                // Otherwise just show the original price
                final displayPrice = discountedPrice.isNotEmpty ? discountedPrice : originalPrice;
                final offerPrice = discountedPrice.isNotEmpty ? originalPrice : '';

                return ProductCard(
                  name: product['name'] ?? 'Product Name',
                  imageUrl: product['imageUrl'] ?? '',
                  discountedPrice: offerPrice,
                  offerPrice: displayPrice,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HomemadeSingleProductPage(
                          product: {
                            ...product,
                            'id': productId,
                          },
                        ),
                      ),
                    );
                  },
                  isGridItem: true,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddHomemadeProductPage(),
            ),
          );
        },
        backgroundColor: const Color.fromARGB(255, 116, 190, 119),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Sell your own product'),
      ),
    );
  }
}