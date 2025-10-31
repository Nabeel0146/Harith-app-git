// lib/1SCREENS/Products/category_products_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:harithapp/Screens/harithsingleproduct.dart';
import 'package:harithapp/widgets/productcard.dart';

class CategoryProductsPage extends StatelessWidget {
  final String categoryName;
  const CategoryProductsPage({super.key, required this.categoryName});

  Widget _buildSectionError(String message) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /* ---------- Category Products Grid ---------- */
  Widget _buildCategoryProductsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('harith-products')
          .where('display', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Category Products Error: ${snapshot.error}');
          return _buildSectionError('Failed to load products');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

       

        // Filter products by category on the client side for better debugging
        final allProducts = snapshot.data!.docs;
        final filteredProducts = allProducts.where((doc) {
          final product = doc.data() as Map<String, dynamic>;
          final productCategory = product['category'] as String?;
          
          // Debug print to see what's happening
          print('Product: ${product['name']}, Category: "$productCategory", Looking for: "$categoryName"');
          
          // Flexible matching: trim and case insensitive
          if (productCategory == null) return false;
          
          final normalizedProductCategory = productCategory.trim().toLowerCase();
          final normalizedSearchCategory = categoryName.trim().toLowerCase();
          
          return normalizedProductCategory == normalizedSearchCategory;
        }).toList();

        print('Found ${filteredProducts.length} products for category: $categoryName');

        if (filteredProducts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.category_outlined,
                    size: 80,
                    color: Color.fromARGB(255, 116, 190, 119),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No $categoryName Products',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No products found in this category',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Debug info
                
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${filteredProducts.length} products found',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final doc = filteredProducts[index];
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
        title: Text(
          categoryName,
          style: const TextStyle(
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
            // Category Info Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 232, 245, 233),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.category,
                    size: 40,
                    color: Color.fromARGB(255, 116, 190, 119),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Browse all products in this category',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Products Grid
            _buildCategoryProductsGrid(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}