import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:harithapp/Screens/harithsingleproduct.dart';
import 'package:harithapp/widgets/productcard.dart';
import 'package:shimmer/shimmer.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ProductsPage extends StatelessWidget {
  final String categoryName;
  const ProductsPage({super.key, required this.categoryName});

  /* ---------------  AD CAROUSEL  --------------- */
  Widget _buildAdCarousel(List<String> adUrls) {
    if (adUrls.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sponsored Ads',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          CarouselSlider.builder(
            itemCount: adUrls.length,
            options: CarouselOptions(
              height: 160,
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: 0.97,
              autoPlayInterval: const Duration(seconds: 4),
            ),
            itemBuilder: (_, idx, __) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: adUrls[idx],
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => Container(color: Colors.grey[300]),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /* ---------------  PRODUCT GRID (FIXED for SingleProductPage)  --------------- */
  Widget _buildProductGrid(BuildContext context, List<QueryDocumentSnapshot> products) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No products in this category',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.70,
      ),
      itemCount: products.length,
      itemBuilder: (_, idx) {
        final doc = products[idx];
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
        
        // Calculate price strings
        final double discountedPrice = parseToDouble(product['discountedprice']);
        final double? offerPrice = product['offerprice'] != null 
            ? parseToDouble(product['offerprice'])
            : null;
        
        final String discountedPriceStr;
        final String offerPriceStr;
        
        if (offerPrice != null && offerPrice < discountedPrice) {
          discountedPriceStr = discountedPrice.toStringAsFixed(2);
          offerPriceStr = offerPrice.toStringAsFixed(2);
        } else {
          discountedPriceStr = '';
          offerPriceStr = discountedPrice.toStringAsFixed(2);
        }

        return ProductCard(
          productId: productId, // ADDED: Required parameter
          name: product['name']?.toString() ?? 'Product Name',
          imageUrl: product['image_url']?.toString() ?? '',
          discountedPrice: discountedPriceStr,
          offerPrice: offerPriceStr,
          category: categoryName, // Use the page's category name
          onTap: () {
            // Add document ID to the product map for SingleProductPage
            final productWithId = {
              ...product,
              'id': productId,
            };
            
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SingleProductPage(product: productWithId),
              ),
            );
          },
          isGridItem: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(categoryName),
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 116, 190, 119),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('display', isEqualTo: true)
            .where('category', isEqualTo: categoryName)
            .snapshots(),
        builder: (context, productSnapshot) {
          if (productSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (productSnapshot.hasError) {
            return Center(child: Text('Error: ${productSnapshot.error}'));
          }
          
          if (!productSnapshot.hasData || productSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No products found in this category',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final products = productSnapshot.data!.docs;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sponsoredads')
                .snapshots(),
            builder: (context, adSnapshot) {
              final adUrls = adSnapshot.hasData 
                  ? adSnapshot.data!.docs
                      .expand((d) => [d['ad1'], d['ad2']])
                      .whereType<String>()
                      .where((u) => u.isNotEmpty)
                      .toList()
                  : <String>[];

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildAdCarousel(adUrls),
                  _buildProductGrid(context, products),
                ],
              );
            },
          );
        },
      ),
    );
  }
}