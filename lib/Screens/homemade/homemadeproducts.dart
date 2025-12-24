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

                // Helper method to parse double values safely
                double parseToDouble(dynamic value) {
                  if (value == null) return 0.0;
                  if (value is double) return value;
                  if (value is int) return value.toDouble();
                  if (value is String) return double.tryParse(value) ?? 0.0;
                  return 0.0;
                }

                // Handle pricing logic
                final originalPrice = product['price']?.toString() ?? '';
                final discountedPrice = product['discountedprice']?.toString() ?? '';
                
                // Parse prices to double for comparison
                final originalPriceNum = parseToDouble(product['price']);
                final discountedPriceNum = parseToDouble(product['discountedprice']);
                
                String discountedPriceStr;
                String offerPriceStr;
                
                if (discountedPriceNum > 0 && discountedPriceNum < originalPriceNum) {
                  // Show discounted price scenario
                  discountedPriceStr = originalPriceNum.toStringAsFixed(2);
                  offerPriceStr = discountedPriceNum.toStringAsFixed(2);
                } else {
                  // Show regular price scenario
                  discountedPriceStr = '';
                  offerPriceStr = originalPriceNum.toStringAsFixed(2);
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image - Square aspect ratio
                      GestureDetector(
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
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.network(
                              product['imageUrl']?.toString() ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Product Details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name']?.toString() ?? 'Product Name',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Price Section
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (discountedPriceStr.isNotEmpty)
                                        Text(
                                          '₹$discountedPriceStr',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      Text(
                                        '₹$offerPriceStr',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              // View Details Button
                             
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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