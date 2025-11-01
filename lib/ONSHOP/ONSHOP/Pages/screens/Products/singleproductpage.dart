import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class SingleProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const SingleProductPage({required this.product, Key? key}) : super(key: key);

  @override
  _SingleProductPageState createState() => _SingleProductPageState();
}

class _SingleProductPageState extends State<SingleProductPage> {
  String currentMainImage = '';

  @override
  void initState() {
    super.initState();
    // Initialize the main image to the product's main image_url
    currentMainImage = widget.product['image_url'] ?? '';
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

  Future<void> _openWhatsApp(BuildContext context, String phoneNumber, String productName, int price, int discountedPrice, String description) async {
  try {
    final userAddress = await getUserAddress();
    final formattedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final productDetails = """
Hello! I am interested in your product:

*Product:* $productName
*Price:* ₹$price
*Discounted Price:* ₹$discountedPrice
*Description:* $description
*Address:* $userAddress

Please process this order. Thank you!
    """.trim();

    final uri = Uri.parse('https://wa.me/$formattedPhoneNumber?text=${Uri.encodeComponent(productDetails)}');

    if (!await launchUrl(uri)) {
      print('Could not launch $uri');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open WhatsApp for $phoneNumber')),
      );
    }
  } catch (e) {
    print('Error launching WhatsApp: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

  void _showLargeImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Product Image
            GestureDetector(
              onTap: () => _showLargeImage(context, currentMainImage),
              child: CachedNetworkImage(
                imageUrl: currentMainImage,
                placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Icon(Icons.error),
                fit: BoxFit.fitHeight,
                width: double.infinity,
                height: 300,
              ),
            ),
            const SizedBox(height: 20),

            // Additional Images Grid
            _buildAdditionalImagesGrid(context),
            const SizedBox(height: 20),

            // Product Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.product['name'] ?? 'No Name',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 3),

            // Product Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.product['description'] ?? 'No Description',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 6),

            // Product Price
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'MRP ₹${widget.product['price'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 18, decoration: TextDecoration.lineThrough, color: Color.fromARGB(255, 206, 32, 20)),
                  ),
                  const SizedBox(width: 10),
                  Text("Discounted Price: ", style: TextStyle(fontSize: 14),),
                  Text(
                    '₹${widget.product['discountedprice'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Order on WhatsApp Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.product['whatsappnumber'] != null) {
                      _openWhatsApp(
                        context,
                        widget.product['whatsappnumber'],
                        widget.product['name'] ?? 'No Name',
                        widget.product['price'] ?? 0,
                        widget.product['discountedprice'] ?? 0,
                        widget.product['description'] ?? 'No Description',
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
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Additional Details
            if (widget.product.containsKey('details') && widget.product['details'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.product['details'],
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalImagesGrid(BuildContext context) {
    List additionalImages = [
      widget.product['image_url'] ?? '',
      widget.product['image1'] ?? '',
      widget.product['image2'] ?? '',
      widget.product['image3'] ?? '',
      widget.product['image4'] ?? '',
    ].where((imageUrl) => imageUrl.isNotEmpty).toList();

    if (additionalImages.isEmpty) return SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1, // Adjust this value to change the aspect ratio of the images
      ),
      itemCount: additionalImages.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              currentMainImage = additionalImages[index];
            });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8), // Rounded corners
            child: CachedNetworkImage(
              imageUrl: additionalImages[index],
              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}