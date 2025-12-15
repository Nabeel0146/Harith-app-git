// lib/1SCREENS/Products/category_products_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:harithapp/Screens/harithsingleproduct.dart';
import 'package:harithapp/Screens/Harith-Store/cartpage.dart';
import 'package:harithapp/widgets/productcard.dart';

class CategoryProductsPage extends StatefulWidget {
  final String categoryName;
  const CategoryProductsPage({super.key, required this.categoryName});

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
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
        print('Loaded ${_cartItems.length} items from cart');
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
                    color: Color.fromARGB(255, 116, 190, 119),
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
                  childAspectRatio: 0.75,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final doc = filteredProducts[index];
                  final p = doc.data() as Map<String, dynamic>;
                  final productId = doc.id;
                  final bool isInCart = _isProductInCart(productId);
                  final int cartQuantity = isInCart ? _getCartQuantity(productId) : 0;
                  
                  // Safely parse prices
                  final double discountedPrice = _parseToDouble(p['discountedprice']);
                  final double? offerPrice = p['offerprice'] != null 
                      ? _parseToDouble(p['offerprice'])
                      : null;
                  
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            GestureDetector(
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
                              child: Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: p['image_url']?.isNotEmpty == true
                                    ? ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: p['image_url']!,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.green[400],
                                            ),
                                          ),
                                          errorWidget: (_, __, ___) => Center(
                                            child: Icon(
                                              Icons.shopping_bag,
                                              size: 40,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons.shopping_bag,
                                          size: 40,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                              ),
                            ),

                            // Product Info
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Name
                                  GestureDetector(
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
                                    child: Text(
                                      p['name']?.toString() ?? 'Product Name',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  // Price
                                  Text(
                                    '₹${discountedPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),

                                  // Offer price
                                  if (offerPrice != null && offerPrice > 0)
                                    Text(
                                      'Offer: ₹${offerPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Cart button overlay
                        Positioned(
                          bottom: 12,
                          right: 12,
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
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 8),
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
                                    ...p,
                                    'id': productId,
                                  }),
                                  backgroundColor: const Color.fromARGB(255, 116, 190, 119),
                                  foregroundColor: Colors.white,
                                  child: const Icon(Icons.add_shopping_cart, size: 20),
                                ),
                        ),
                      ],
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
                              widget.categoryName,
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
          
          // Floating Cart Button
          _buildCartFloatingButton(),
        ],
      ),
    );
  }
}