// lib/1SCREENS/Products/category_products_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:harithapp/Screens/Whatsappcart/whatsappcart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import 'package:harithapp/Screens/harithsingleproduct.dart';
import 'package:harithapp/widgets/productcard.dart'; // ADD THIS IMPORT


class CategoryProductsPage extends StatefulWidget {
  final String categoryName;
  const CategoryProductsPage({super.key, required this.categoryName});

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> _whatsappCartItems = [];
  late SharedPreferences _prefs;
  bool _isLoadingCart = true;
  
  // WhatsApp configuration
  final String _whatsappNumber = '917012345678'; // Replace with your WhatsApp number
  final String _whatsappMessageHeader = '🛒 *NEW ORDER REQUEST* 🛒\n\n';
  
  // Helper method to safely parse to double
  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  
  @override
  void initState() {
    super.initState();
    _initializeWhatsAppCart();
  }

  Future<void> _initializeWhatsAppCart() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadWhatsAppCartFromPrefs();
    } catch (e) {
      print('Error initializing WhatsApp cart: $e');
    } finally {
      setState(() {
        _isLoadingCart = false;
      });
    }
  }

  // Load WhatsApp cart from SharedPreferences
  Future<void> _loadWhatsAppCartFromPrefs() async {
    try {
      final cartJson = _prefs.getString('harith_whatsapp_cart');
      if (cartJson != null && cartJson.isNotEmpty) {
        final cartData = (jsonDecode(cartJson) as List).cast<Map<String, dynamic>>();
        setState(() {
          _whatsappCartItems = cartData;
        });
        print('Loaded ${_whatsappCartItems.length} items from WhatsApp cart');
      }
    } catch (e) {
      print('Error loading WhatsApp cart from prefs: $e');
      await _prefs.remove('harith_whatsapp_cart');
    }
  }

  // Save WhatsApp cart to SharedPreferences
  Future<void> _saveWhatsAppCartToPrefs() async {
    try {
      final cartJson = jsonEncode(_whatsappCartItems);
      await _prefs.setString('harith_whatsapp_cart', cartJson);
    } catch (e) {
      print('Error saving WhatsApp cart to prefs: $e');
    }
  }

  // Navigate to WhatsApp cart page
  void _navigateToWhatsAppCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WhatsAppCartPage(
          cartItems: _whatsappCartItems,
          onCartUpdate: (updatedCart) {
            setState(() {
              _whatsappCartItems = updatedCart;
            });
            _saveWhatsAppCartToPrefs();
            _initializeWhatsAppCart();
          },
          onPlaceOrder: _placeOrderViaWhatsApp,
        ),
      ),
    );
  }

  // Add item to WhatsApp cart - UPDATED to use ProductCard's cart service
  void _addToWhatsAppCart(Map<String, dynamic> product) {
    final String productId = product['id'];
    final int existingIndex =
        _whatsappCartItems.indexWhere((item) => item['id'] == productId);

    if (existingIndex != -1) {
      // Update quantity if already in cart
      setState(() {
        _whatsappCartItems[existingIndex]['quantity'] =
            (_whatsappCartItems[existingIndex]['quantity'] ?? 0) + 1;
      });
    } else {
      // Add new item to cart
      setState(() {
        _whatsappCartItems.add({
          'id': productId,
          'name': product['name'],
          'price': _parseToDouble(product['discountedprice'] ?? 0.0),
          'offerPrice': product['offerprice'] != null 
              ? _parseToDouble(product['offerprice'])
              : null,
          'image': product['image_url'] ?? '',
          'quantity': 1,
          'category': product['category'] ?? widget.categoryName,
          'addedAt': DateTime.now().toIso8601String(),
        });
      });
    }

    _saveWhatsAppCartToPrefs();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to WhatsApp Cart'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: _navigateToWhatsAppCart,
        ),
      ),
    );
  }

  // Remove item from WhatsApp cart
  void _removeFromWhatsAppCart(String productId) {
    setState(() {
      _whatsappCartItems.removeWhere((item) => item['id'] == productId);
    });
    _saveWhatsAppCartToPrefs();
  }

  // Update quantity in WhatsApp cart
  void _updateWhatsAppCartQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      _removeFromWhatsAppCart(productId);
      return;
    }

    final cartIndex = _whatsappCartItems.indexWhere((item) => item['id'] == productId);
    if (cartIndex != -1) {
      setState(() {
        _whatsappCartItems[cartIndex]['quantity'] = quantity;
      });
      _saveWhatsAppCartToPrefs();
    }
  }

  // Check if product is in WhatsApp cart
  bool _isProductInWhatsAppCart(String productId) {
    return _whatsappCartItems.any((item) => item['id'] == productId);
  }

  // Get WhatsApp cart quantity for product
  int _getWhatsAppCartQuantity(String productId) {
    final cartItem = _whatsappCartItems.firstWhere(
      (item) => item['id'] == productId,
      orElse: () => {},
    );
    return cartItem.isNotEmpty ? (cartItem['quantity'] ?? 0) : 0;
  }

  // Show WhatsApp cart preview
  void _showWhatsAppCartPreview() {
    if (_whatsappCartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your WhatsApp cart is empty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int totalItems = 0;
        double totalAmount = 0.0;
        
        for (var item in _whatsappCartItems) {
          final quantity = item['quantity'] is int ? item['quantity'] as int : 0;
          totalItems += quantity;
          final price = item['offerPrice'] ?? item['price'] ?? 0.0;
          totalAmount += (price * quantity);
        }

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.message, color: Colors.green, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'WhatsApp Cart',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Cart stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$totalItems items',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '₹${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              // Cart items list
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _whatsappCartItems.length,
                  itemBuilder: (context, index) {
                    final item = _whatsappCartItems[index];
                    final price = item['offerPrice'] ?? item['price'] ?? 0.0;
                    final quantity = item['quantity'] is int ? item['quantity'] as int : 0;
                    
                    return ListTile(
                      leading: item['image']?.isNotEmpty == true
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: item['image'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.shopping_bag),
                            ),
                      title: Text(
                        item['name'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '₹${price.toStringAsFixed(2)} × $quantity',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: () => _updateWhatsAppCartQuantity(item['id'], quantity - 1),
                          ),
                          Text('$quantity'),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => _updateWhatsAppCartQuantity(item['id'], quantity + 1),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeFromWhatsAppCart(item['id']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearWhatsAppCart();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Clear Cart'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToWhatsAppCart();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      icon: const Icon(Icons.message, color: Colors.white),
                      label: const Text('Go to Cart'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Clear WhatsApp cart
  void _clearWhatsAppCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear WhatsApp Cart'),
        content: const Text('Remove all items from WhatsApp cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _whatsappCartItems.clear();
              });
              _saveWhatsAppCartToPrefs();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('WhatsApp cart cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // Place order via WhatsApp
  Future<void> _placeOrderViaWhatsApp(List<Map<String, dynamic>> cartItems) async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty. Add items to place an order.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Generate order message
    String orderMessage = _whatsappMessageHeader;
    
    // Add customer info if available
    final user = _auth.currentUser;
    if (user != null) {
      orderMessage += '👤 *Customer:* ${user.displayName ?? user.email ?? 'N/A'}\n';
    }
    
    orderMessage += '📅 *Date:* ${DateTime.now().toString().split(' ')[0]}\n';
    orderMessage += '⏰ *Time:* ${DateTime.now().toString().split(' ')[1].substring(0, 8)}\n\n';
    
    // Add items
    orderMessage += '📋 *ORDER ITEMS:*\n';
    orderMessage += '════════════════════\n\n';
    
    double totalAmount = 0.0;
    int totalItems = 0;
    
    for (var item in cartItems) {
      final quantity = item['quantity'] is int ? item['quantity'] as int : 0;
      final price = item['offerPrice'] ?? item['price'] ?? 0.0;
      final itemTotal = price * quantity;
      
      orderMessage += '🔹 *${item['name']}*\n';
      orderMessage += '   Quantity: $quantity\n';
      orderMessage += '   Price: ₹${price.toStringAsFixed(2)} each\n';
      orderMessage += '   Total: ₹${itemTotal.toStringAsFixed(2)}\n';
      orderMessage += '   ─────────────\n';
      
      totalItems += quantity;
      totalAmount += itemTotal;
    }
    
    // Add summary
    orderMessage += '\n════════════════════\n';
    orderMessage += '📊 *ORDER SUMMARY:*\n';
    orderMessage += 'Total Items: $totalItems\n';
    orderMessage += 'Total Amount: *₹${totalAmount.toStringAsFixed(2)}*\n\n';
    
    // Add footer
    orderMessage += '📍 *Category:* ${widget.categoryName}\n';
    orderMessage += '📱 *Sent via:* Harith App\n';
    orderMessage += '────────────────────\n';
    orderMessage += 'Please confirm this order and provide delivery details.\n';
    orderMessage += 'Thank you! 🙏';

    // Encode the message for URL
    final encodedMessage = Uri.encodeComponent(orderMessage);
    
    // Create WhatsApp URL
    final whatsappUrl = 'https://wa.me/$_whatsappNumber?text=$encodedMessage';
    
    try {
      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
        
        // Clear cart after successful order placement
        setState(() {
          _whatsappCartItems.clear();
        });
        await _saveWhatsAppCartToPrefs();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order sent to WhatsApp successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch WhatsApp. Please install WhatsApp first.'),
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

  // Build floating WhatsApp cart button
  Widget _buildWhatsAppCartFloatingButton() {
    if (_whatsappCartItems.isEmpty) {
      return const SizedBox.shrink();
    }
    
    int totalItems = 0;
    for (var item in _whatsappCartItems) {
      final quantity = item['quantity'] is int ? item['quantity'] as int : 0;
      totalItems += quantity;
    }
    
    double totalAmount = 0.0;
    for (var item in _whatsappCartItems) {
      final price = item['offerPrice'] ?? item['price'] ?? 0.0;
      final quantity = item['quantity'] is int ? item['quantity'] as int : 0;
      totalAmount += (price * quantity);
    }
    
    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton.extended(
        onPressed: _navigateToWhatsAppCart,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: Badge(
          label: Text('$totalItems'),
          isLabelVisible: true,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          child: const Icon(Icons.message),
        ),
        label: Text(
          '₹${totalAmount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

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
      )
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

        // Filter products by category on the client side
        final allProducts = snapshot.data!.docs;
        final filteredProducts = allProducts.where((doc) {
          final product = doc.data() as Map<String, dynamic>;
          final productCategory = product['category'] as String?;
          
          if (productCategory == null) return false;
          
          final normalizedProductCategory = productCategory.trim().toLowerCase();
          final normalizedSearchCategory = widget.categoryName.trim().toLowerCase();
          
          return normalizedProductCategory == normalizedSearchCategory;
        }).toList();

        print('Found ${filteredProducts.length} products for category: ${widget.categoryName}');

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
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${widget.categoryName} Products',
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
                  childAspectRatio: 0.56,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final doc = filteredProducts[index];
                  final product = doc.data() as Map<String, dynamic>;
                  final productId = doc.id;

                  // Safely parse prices
                  final double discountedPrice = _parseToDouble(product['discountedprice']);
                  final double? offerPrice = product['offerprice'] != null 
                      ? _parseToDouble(product['offerprice'])
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

                  // Note: Since ProductCard now handles cart internally,
                  // we don't need to pass cart callbacks.
                  // The cart state will be managed by the WhatsAppCartService
                  return ProductCard(
                    productId: productId,
                    name: product['name']?.toString() ?? 'Product Name',
                    imageUrl: product['image_url']?.toString() ?? '',
                    discountedPrice: discountedPriceStr,
                    offerPrice: offerPriceStr,
                    category: widget.categoryName, // Use the page's category
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SingleProductPage(
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
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalWhatsAppCartItems = 0;
    for (var item in _whatsappCartItems) {
      final quantity = item['quantity'] is int ? item['quantity'] as int : 0;
      totalWhatsAppCartItems += quantity;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          // WhatsApp Cart button with badge
          IconButton(
            icon: Badge(
              label: Text('$totalWhatsAppCartItems'),
              isLabelVisible: totalWhatsAppCartItems > 0,
              backgroundColor: Colors.orange,
              textColor: Colors.white,
              child: const Icon(Icons.message, color: Colors.white),
            ),
            onPressed: _showWhatsAppCartPreview,
            tooltip: 'View WhatsApp Cart',
          ),
          
          // Clear WhatsApp cart button (only shown when cart has items)
          if (_whatsappCartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
              onPressed: _clearWhatsAppCart,
              tooltip: 'Clear WhatsApp Cart',
            ),
        ],
      ),
      body: Stack(
        children: [
          _isLoadingCart
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.green,
                  ),
                )
              : SingleChildScrollView(
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
                            Icon(
                              Icons.category,
                              size: 40,
                              color: Colors.green[700],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.categoryName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Add items to WhatsApp Cart and place order via WhatsApp',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.message, color: Colors.green, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'WhatsApp Cart',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Products Grid
                      _buildCategoryProductsGrid(),
                      
                      const SizedBox(height: 80), // Extra space for floating button
                    ],
                  ),
                ),
          
          // Floating WhatsApp Cart Button
          _buildWhatsAppCartFloatingButton(),
        ],
      ),
    );
  }
}