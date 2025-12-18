// lib/1SCREENS/Products/all_products_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:harithapp/widgets/productcard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:harithapp/Screens/catgeoryProducts.dart';
import 'package:harithapp/Screens/harithsingleproduct.dart';
import 'package:harithapp/Screens/Harith-Store/cartpage.dart';

class AllProductsPage extends StatefulWidget {
  const AllProductsPage({super.key});

  @override
  State<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> _cartItems = [];
  late SharedPreferences _prefs;
  bool _isLoadingCart = true;
  
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
    _initializeCart();
  }

  Future<void> _initializeCart() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadCartFromPrefs();
    } catch (e) {
      print('Error initializing cart: $e');
    } finally {
      setState(() {
        _isLoadingCart = false;
      });
    }
  }

  // Load cart from SharedPreferences
  Future<void> _loadCartFromPrefs() async {
    try {
      final cartJson = _prefs.getString('harith_store_cart');
      if (cartJson != null && cartJson.isNotEmpty) {
        final cartData = (jsonDecode(cartJson) as List).cast<Map<String, dynamic>>();
        setState(() {
          _cartItems = cartData;
        });
      }
    } catch (e) {
      print('Error loading cart from prefs: $e');
      await _prefs.remove('harith_store_cart');
    }
  }

  // Save cart to SharedPreferences
  Future<void> _saveCartToPrefs() async {
    try {
      final cartJson = jsonEncode(_cartItems);
      await _prefs.setString('harith_store_cart', cartJson);
    } catch (e) {
      print('Error saving cart to prefs: $e');
    }
  }

  // Navigate to cart page
  void _navigateToCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HarithCartPage(
          cartItems: _cartItems,
          onCartUpdate: (updatedCart) {
            setState(() {
              _cartItems = updatedCart;
            });
            _saveCartToPrefs();
            // Refresh the page to update cart status on products
            _initializeCart();
          },
        ),
      ),
    );
  }

  // Add item to cart
  void _addToCart(Map<String, dynamic> product) {
    final String productId = product['id'];
    final int existingIndex =
        _cartItems.indexWhere((item) => item['id'] == productId);

    if (existingIndex != -1) {
      // Update quantity if already in cart
      setState(() {
        _cartItems[existingIndex]['quantity'] =
            (_cartItems[existingIndex]['quantity'] ?? 0) + 1;
      });
    } else {
      // Add new item to cart
      setState(() {
        _cartItems.add({
          'id': productId,
          'name': product['name'],
          'price': _parseToDouble(product['discountedprice'] ?? 0.0),
          'offerPrice': product['offerprice'] != null 
              ? _parseToDouble(product['offerprice'])
              : null,
          'image': product['image_url'] ?? '',
          'quantity': 1,
          'addedAt': DateTime.now().toIso8601String(),
        });
      });
    }

    _saveCartToPrefs();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart'),
        backgroundColor: const Color.fromARGB(255, 116, 190, 119),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: _navigateToCart,
        ),
      ),
    );
  }

  // Remove item from cart
  void _removeFromCart(String productId) {
    setState(() {
      _cartItems.removeWhere((item) => item['id'] == productId);
    });
    _saveCartToPrefs();
  }

  // Update quantity in cart
  void _updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      _removeFromCart(productId);
      return;
    }

    final cartIndex = _cartItems.indexWhere((item) => item['id'] == productId);
    if (cartIndex != -1) {
      setState(() {
        _cartItems[cartIndex]['quantity'] = quantity;
      });
      _saveCartToPrefs();
    }
  }

  // Check if product is in cart
  bool _isProductInCart(String productId) {
    return _cartItems.any((item) => item['id'] == productId);
  }

  // Get cart quantity for product
  int _getCartQuantity(String productId) {
    final cartItem = _cartItems.firstWhere(
      (item) => item['id'] == productId,
      orElse: () => {},
    );
    return cartItem.isNotEmpty ? (cartItem['quantity'] ?? 0) : 0;
  }

  // Show cart preview
  void _showCartPreview() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
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
        
        for (var item in _cartItems) {
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
              const Text(
                'Your Cart',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
                      color: Color.fromARGB(255, 116, 190, 119),
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
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _cartItems[index];
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
                        '₹${price.toStringAsFixed(2)} × $quantity = ₹${(price * quantity).toStringAsFixed(2)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: () => _updateQuantity(item['id'], quantity - 1),
                          ),
                          Text('$quantity'),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => _updateQuantity(item['id'], quantity + 1),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeFromCart(item['id']),
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
                        _clearCart();
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
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToCart();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 116, 190, 119),
                      ),
                      child: const Text('Go to Cart'),
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

  // Clear cart
  void _clearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _cartItems.clear();
              });
              _saveCartToPrefs();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart cleared successfully'),
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

  // Build floating cart button
  Widget _buildCartFloatingButton() {
    if (_cartItems.isEmpty) {
      return const SizedBox.shrink();
    }
    
    int totalItems = 0;
    for (var item in _cartItems) {
      final quantity = item['quantity'] is int ? item['quantity'] as int : 0;
      totalItems += quantity;
    }
    
    double totalAmount = 0.0;
    for (var item in _cartItems) {
      final price = item['offerPrice'] ?? item['price'] ?? 0.0;
      final quantity = item['quantity'] is int ? item['quantity'] as int : 0;
      totalAmount += (price * quantity);
    }
    
    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton.extended(
        onPressed: _navigateToCart,
        backgroundColor: const Color.fromARGB(255, 116, 190, 119),
        foregroundColor: Colors.white,
        icon: Badge(
          label: Text('$totalItems'),
          isLabelVisible: true,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          child: const Icon(Icons.shopping_cart),
        ),
        label: Text(
          '₹${totalAmount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

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
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
              childAspectRatio: 0.70,
            ),
            itemCount: cats.length,
            itemBuilder: (_, idx) {
              final cat = cats[idx];
              return GestureDetector(
                onTap: () {
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
                        style: const TextStyle(fontSize: 8),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /* ---------- All Products Grid ---------- */
  Widget _buildAllProductsGrid() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
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
                  childAspectRatio: 0.65,
                ),
                itemCount: items.length,
                itemBuilder: (_, idx) {
                  final doc = items[idx];
                  final product = doc.data() as Map<String, dynamic>;
                  final productId = doc.id;
                  final bool isInCart = _isProductInCart(productId);
                  final int cartQuantity = isInCart ? _getCartQuantity(productId) : 0;
                  
                  // Parse prices for ProductCard
                  final double discountedPrice = _parseToDouble(product['discountedprice']);
                  final double? offerPrice = product['offerprice'] != null 
                      ? _parseToDouble(product['offerprice'])
                      : null;
                  
                  // Determine which price to show as discounted/offer
                  final String discountedPriceStr;
                  final String offerPriceStr;
                  
                  if (offerPrice != null && offerPrice < discountedPrice) {
                    // If there's a lower offer price
                    discountedPriceStr = discountedPrice.toStringAsFixed(2);
                    offerPriceStr = offerPrice.toStringAsFixed(2);
                  } else {
                    // If no offer price or offer price is higher (use discounted price as offer)
                    discountedPriceStr = '';
                    offerPriceStr = discountedPrice.toStringAsFixed(2);
                  }

                  return Stack(
                    children: [
                      ProductCard(
                        name: product['name']?.toString() ?? 'Product Name',
                        imageUrl: product['image_url']?.toString() ?? '',
                        discountedPrice: discountedPriceStr,
                        offerPrice: offerPriceStr,
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
                      ),
                      
                      // Add to cart button overlay
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: isInCart
                            ? Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 116, 190, 119),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove,
                                          size: 18, color: Colors.white),
                                      onPressed: () {
                                        _updateQuantity(productId, cartQuantity - 1);
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '$cartQuantity',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add,
                                          size: 18, color: Colors.white),
                                      onPressed: () {
                                        _updateQuantity(productId, cartQuantity + 1);
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              )
                            : FloatingActionButton.small(
                                onPressed: () => _addToCart({
                                  ...product,
                                  'id': productId,
                                }),
                                backgroundColor: const Color.fromARGB(255, 116, 190, 119),
                                foregroundColor: Colors.white,
                                child: const Icon(Icons.add_shopping_cart, size: 20),
                              ),
                      ),
                      
                      // In Cart badge
                      if (isInCart)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'In Cart',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
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
    int totalCartItems = 0;
    for (var item in _cartItems) {
      final quantity = item['quantity'] is int ? item['quantity'] as int : 0;
      totalCartItems += quantity;
    }

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
        actions: [
          // Cart button with badge
          IconButton(
            icon: Badge(
              label: Text('$totalCartItems'),
              isLabelVisible: totalCartItems > 0,
              backgroundColor: Colors.orange,
              textColor: Colors.white,
              child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            ),
            onPressed: _showCartPreview,
            tooltip: 'View Cart',
          ),
          
          // Clear cart button (only shown when cart has items)
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
              onPressed: _clearCart,
              tooltip: 'Clear Cart',
            ),
        ],
      ),
      body: Stack(
        children: [
          _isLoadingCart
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 116, 190, 119),
                  ),
                )
              : SingleChildScrollView(
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
          
          // Floating Cart Button
          _buildCartFloatingButton(),
        ],
      ),
    );
  }
}