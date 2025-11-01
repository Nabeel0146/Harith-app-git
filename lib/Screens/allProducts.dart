// lib/1SCREENS/Products/all_products_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:harithapp/Screens/catgeoryProducts.dart';
import 'package:harithapp/Screens/harithsingleproduct.dart';
import 'package:harithapp/widgets/productcard.dart';

class AllProductsPage extends StatelessWidget {
  const AllProductsPage({super.key});

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionError(String message) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /* ---------- Category Grid ---------- */
  Widget _buildCategoryGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('harith_product_categories')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Category Error: ${snapshot.error}');
          return _buildErrorWidget('Failed to load categories');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No categories found')),
          );
        }

        final cats = snapshot.data!.docs
            .map((d) => {
                  'name': d['name'] as String? ?? 'Unnamed',
                  'image': d['image'] as String? ?? '',
                })
            .toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 16, bottom: 12),
                child: Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.70,
                ),
                itemCount: cats.length,
                itemBuilder: (_, idx) {
                  final cat = cats[idx];
                  return GestureDetector(
                    onTap: () {
                      // CORRECTED: Add Navigator.push to navigate to CategoryProductsPage
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CategoryProductsPage(
                            categoryName: cat['name']!,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey, width: 0.5),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: cat['image']!.isEmpty
                                ? Container(
                                    width: 45,
                                    height: 45,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.category,
                                        color: Colors.grey),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: cat['image']!,
                                    width: 45,
                                    height: 45,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      width: 45,
                                      height: 45,
                                      color: Colors.grey[300],
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      width: 45,
                                      height: 45,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.error,
                                          color: Colors.grey),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            cat['name']!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 9),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
  }

  /* ---------- All Products Grid ---------- */
  Widget _buildAllProductsGrid() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('harith-products')
          .where('display', isEqualTo: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('All Products Error: ${snapshot.error}');
          return _buildSectionError('Failed to load all products');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No products available',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Check back later for new products',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final items = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 24, bottom: 12),
                child: Text(
                  'All Products',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemCount: items.length,
                itemBuilder: (_, idx) {
                  final doc = items[idx];
                  final p = doc.data() as Map<String, dynamic>;
                  final productId = doc.id;

                  return ProductCard(
                    name: p['name'] ?? 'Product Name',
                    imageUrl: p['image_url'] ?? '',
                    discountedPrice: p['discountedprice']?.toString() ?? '',
                    offerPrice: p['offerprice']?.toString() ??
                        p['discountedprice']?.toString() ??
                        '',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SingleProductPage(
                            product: {
                              ...p,
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
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 116, 190, 119),
        title: const Text(
          'All Products',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Grid Section
            _buildCategoryGrid(),
            
            // All Products Grid Section
            _buildAllProductsGrid(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}