// lib/1SCREENS/Products/single_product_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SingleProductPage extends StatelessWidget {
  final Map<String, dynamic> product;
  const SingleProductPage({super.key, required this.product});

  /* ---------- fetch current user's panchayath contact number ---------- */
  Future<String?> _getPanchayathContact() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      // Get user's panchayath
      final userDoc = await FirebaseFirestore.instance
          .collection('harith-users')
          .doc(uid)
          .get();
      
      if (!userDoc.exists) return null;
      
      final panchayathName = userDoc.data()?['panchayath'] as String?;
      if (panchayathName == null || panchayathName.isEmpty) return null;

      // Get panchayath contact number
      final panchayathQuery = await FirebaseFirestore.instance
          .collection('harith-panchayaths')
          .where('name', isEqualTo: panchayathName)
          .limit(1)
          .get();

      if (panchayathQuery.docs.isEmpty) return null;

      final panchayathData = panchayathQuery.docs.first.data();
      final contactNumber = panchayathData['number'] as String?;
      
      return contactNumber;
    } catch (e) {
      print('Error fetching panchayath contact: $e');
      return null;
    }
  }

  /* ---------- send WhatsApp to panchayath ---------- */
  Future<void> _orderOnWhatsApp(BuildContext context) async {
    try {
      final contact = await _getPanchayathContact();
      
      if (contact == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find your panchayath contact number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Clean the contact number (remove spaces, dashes, etc.)
      final cleanContact = contact.replaceAll(RegExp(r'[+\s\-()]'), '');
      
      // Get the final price to show in message (offerprice if available, otherwise discountedprice)
      final finalPrice = product['offerprice']?.toString() ?? 
                         product['discountedprice']?.toString() ?? 
                         'N/A';
      
      // Create the message
      final message = '''
*New Product Order - Harithagramam*

🛍️ *Product:* ${product['name'] ?? 'N/A'}
📦 *Category:* ${product['category'] ?? 'N/A'}
💰 *Price:* ₹$finalPrice

Please process this order. Thank you!
      '''.trim();

      // Create WhatsApp URL
      final whatsappUrl = 'https://wa.me/$cleanContact?text=${Uri.encodeComponent(message)}';

      // Launch WhatsApp - ALWAYS open in external browser
      if (await canLaunchUrlString(whatsappUrl)) {
        await launchUrlString(
          whatsappUrl,
          mode: LaunchMode.externalApplication, // Always open in external browser
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error launching WhatsApp: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPriceSection() {
    final discountedPrice = product['discountedprice']?.toString() ?? '';
    final offerPrice = product['offerprice']?.toString() ?? '';
    final hasOffer = offerPrice.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasOffer) ...[
            // Show offer price as highlighted final price
            Text(
              '₹$offerPrice',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            // Show discounted price as striked through
            Text(
              '₹$discountedPrice',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            // Show discount percentage if both prices are available
            if (discountedPrice.isNotEmpty && offerPrice.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _calculateDiscountPercentage(discountedPrice, offerPrice),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
          ] else if (discountedPrice.isNotEmpty) ...[
            // Only discounted price available (no offer price)
            Text(
              '₹$discountedPrice',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.green,
              ),
            ),
          ] else ...[
            // No pricing information available
            const Text(
              'Price not available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _calculateDiscountPercentage(String discountedPrice, String offerPrice) {
    try {
      final discounted = double.tryParse(discountedPrice);
      final offer = double.tryParse(offerPrice);
      
      if (discounted != null && offer != null && discounted > 0 && offer < discounted) {
        final discountPercentage = ((discounted - offer) / discounted * 100).round();
        return '$discountPercentage% OFF';
      }
    } catch (e) {
      print('Error calculating discount: $e');
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = 'product_${product['image_url']}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(product['name'] ?? 'Product'),
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 116, 190, 119),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: heroTag,
              child: CachedNetworkImage(
                imageUrl: product['image_url'] ?? '',
                height: 400,
                fit: BoxFit.cover,
                placeholder: (_, __) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error, size: 50),
                ),
              ),
            ),
            const SizedBox(height: 16),

            /* ---- name & category ---- */
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  if (product['category'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        product['category'],
                        style: TextStyle(
                          fontSize: 14, 
                          color: Colors.grey[600]
                        ),
                      ),
                    ),
                ],
              ),
            ),

            /* ---- price section with proper discount logic ---- */
            _buildPriceSection(),

            /* ---- details ---- */
            if (product['details'] != null &&
                (product['details'] as String).trim().isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  product['details'],
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ),

            // Info section about ordering
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 232, 245, 233),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Color.fromARGB(255, 116, 190, 119),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'How to Order',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap "Order on WhatsApp" to send your order directly to your panchayath. They will contact you for delivery details.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => _orderOnWhatsApp(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: const Color.fromARGB(255, 116, 190, 119),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat),
                SizedBox(width: 8),
                Text(
                  'Order on WhatsApp',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}