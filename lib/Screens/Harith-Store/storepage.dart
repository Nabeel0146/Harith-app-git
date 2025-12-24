// lib/Screens/harith_store.dart - Updated with integrated product card
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:harithapp/Screens/Harith-Store/single2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:harithapp/Screens/Harith-Store/cartpage.dart';
import 'package:harithapp/Screens/harithsingleproduct.dart';

class HarithStorePage extends StatefulWidget {
  const HarithStorePage({super.key});

  @override
  State<HarithStorePage> createState() => _HarithStorePageState();
}

class _HarithStorePageState extends State<HarithStorePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  
  // Cart state
  List<Map<String, dynamic>> _cartItems = [];
  
  // User membership info
  Map<String, dynamic>? _userData;
  bool _hasMembership = false;
  String? _membershipId;
  Map<String, double> _memberPurchasedQuantities = {};
  
  // SharedPreferences instance
  late SharedPreferences _prefs;

  // Helper methods
  double _safeParseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _safeParseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();
      
      // Load user data
      await _loadUserData();
      
      // Load cart from storage
      await _loadCartFromPrefs();
      
      // Fetch products
      await _fetchProducts();
    } catch (e) {
      print('Error initializing app: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

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
            _fetchProducts(); // Refresh product display
          },
        ),
      ),
    );
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore
            .collection('harith-users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data();
            _membershipId = _userData?['membershipId']?.toString();
            _hasMembership = _membershipId != null && 
                            _membershipId!.isNotEmpty && 
                            _membershipId != 'null';
          });
          
          if (_hasMembership) {
            await _fetchMemberPurchasedQuantities();
          }
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _fetchMemberPurchasedQuantities() async {
    try {
      final now = DateTime.now();
      final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
      
      final salesQuery = await _firestore
          .collection('harith-sales')
          .where('customerId', isEqualTo: _auth.currentUser?.uid)
          .where('createdAt', isGreaterThanOrEqualTo: oneMonthAgo)
          .where('isMembershipApplied', isEqualTo: true)
          .get();

      _memberPurchasedQuantities.clear();
      
      for (var sale in salesQuery.docs) {
        final items = sale.data()['items'] as List<dynamic>;
        for (var item in items) {
          final productId = item['id']?.toString();
          if (productId != null && item['lastPrice'] != null) {
            final breakdown = item['priceBreakdown'] as Map<String, dynamic>?;
            if (breakdown != null && breakdown['memberQty'] != null) {
              final double memberQty = _safeParseToDouble(breakdown['memberQty']);
              _memberPurchasedQuantities[productId] = 
                  (_memberPurchasedQuantities[productId] ?? 0.0) + memberQty;
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching member purchases: $e');
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
      // Clear invalid cart data
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

  // Clear cart from SharedPreferences
  Future<void> _clearCartFromPrefs() async {
    await _prefs.remove('harith_store_cart');
    setState(() {
      _cartItems.clear();
    });
    _fetchProducts(); // Refresh product display
  }

  Future<void> _fetchProducts() async {
    try {
      print('Fetching products for Harith Store...');
      print('User has membership: $_hasMembership');
      print('Cart items before fetch: ${_cartItems.length}');

      final QuerySnapshot snapshot = await _firestore
          .collection('harith-store-products')
          .where('display', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _products = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final productId = doc.id;

          final double price = _safeParseToDouble(data['discountedprice'] ?? 0);
          final double? offerPrice = data['offerprice'] != null
              ? _safeParseToDouble(data['offerprice'])
              : null;
          final double? lastPrice = data['lastprice'] != null
              ? _safeParseToDouble(data['lastprice'])
              : null;
          final double lastPriceQuantity = _safeParseToDouble(
              data['lastpricequantity'] ?? 0);
          
          // Calculate remaining last price quantity for member
          double remainingLastPriceQuantity = lastPriceQuantity;
          double alreadyPurchased = 0.0;
          bool isEligibleForLastPrice = false;
          
          if (_hasMembership && lastPrice != null && lastPrice > 0 && lastPriceQuantity > 0) {
            alreadyPurchased = _memberPurchasedQuantities[productId] ?? 0.0;
            remainingLastPriceQuantity = (lastPriceQuantity - alreadyPurchased).clamp(0.0, lastPriceQuantity);
            isEligibleForLastPrice = remainingLastPriceQuantity > 0;
          }

          // Check if product is in cart (from stored cart)
          final cartItem = _cartItems.firstWhere(
            (item) => item['id'] == productId,
            orElse: () => {},
          );
          final bool isInCart = cartItem.isNotEmpty;
          final int cartQuantity = isInCart ? (cartItem['quantity'] ?? 0) : 0;

          // Adjust remaining last price based on cart quantity
          if (isInCart && _hasMembership && lastPrice != null && lastPrice > 0) {
            final double totalInCart = alreadyPurchased + cartQuantity;
            remainingLastPriceQuantity = (lastPriceQuantity - totalInCart).clamp(0.0, lastPriceQuantity);
            isEligibleForLastPrice = remainingLastPriceQuantity > 0;
          }

          return {
            'id': productId,
            'name': data['name'] as String? ?? 'Unknown',
            'category': data['category'] as String? ?? 'Uncategorized',
            'price': price,
            'offerPrice': offerPrice,
            'lastPrice': lastPrice,
            'lastPriceQuantity': lastPriceQuantity,
            'remainingLastPriceQuantity': remainingLastPriceQuantity,
            'alreadyPurchased': alreadyPurchased,
            'isEligibleForLastPrice': isEligibleForLastPrice,
            'image': data['image_url'] as String? ?? '',
            'details': data['details'] as String? ?? '',
            'isWeightProduct': data['isWeightProduct'] ?? false,
            'isInCart': isInCart,
            'cartQuantity': cartQuantity,
          };
        }).toList();

        // Extract unique categories
        final categoriesSet =
            _products.map((p) => p['category'] as String).toSet();
        _categories = ['All'] + categoriesSet.toList();

        _filteredProducts = List.from(_products);
        _isLoading = false;

        print('Loaded ${_products.length} products for Harith Store');
      });
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        if (_selectedCategory != 'All' &&
            product['category'] != _selectedCategory) {
          return false;
        }

        if (_searchQuery.isNotEmpty) {
          final name = product['name'].toString().toLowerCase();
          final category = product['category'].toString().toLowerCase();
          final details = product['details'].toString().toLowerCase();
          return name.contains(_searchQuery.toLowerCase()) ||
              category.contains(_searchQuery.toLowerCase()) ||
              details.contains(_searchQuery.toLowerCase());
        }

        return true;
      }).toList();
    });
  }

  void _addToCart(Map<String, dynamic> product) {
    final String productId = product['id'];
    final int existingIndex = _cartItems.indexWhere((item) => item['id'] == productId);
    final double? lastPrice = product['lastPrice'];
    final double lastPriceQuantity = product['lastPriceQuantity'];
    final double remainingLastPriceQuantity = product['remainingLastPriceQuantity'];

    // Check if user is still eligible for last price
    bool shouldUseLastPrice = _hasMembership && 
        lastPrice != null && 
        lastPrice > 0 && 
        remainingLastPriceQuantity > 0;

    if (existingIndex != -1) {
      // Get current quantity in cart
      final int currentQuantity = _cartItems[existingIndex]['quantity'] ?? 0;
      
      // Check if we should still use last price for this addition
      final bool useLastPriceForThisItem = shouldUseLastPrice && 
          (currentQuantity < lastPriceQuantity.floor());
      
      // Update quantity
      setState(() {
        _cartItems[existingIndex]['quantity'] = currentQuantity + 1;
        
        // If this addition crosses the last price threshold, update the price
        if (useLastPriceForThisItem && (currentQuantity + 1) > lastPriceQuantity.floor()) {
          // Switch to regular price for future additions
          _cartItems[existingIndex]['isEligibleForLastPrice'] = false;
        }
      });
    } else {
      // Add new item to cart
      setState(() {
        _cartItems.add({
          'id': productId,
          'name': product['name'],
          'price': product['price'],
          'offerPrice': product['offerPrice'],
          'lastPrice': lastPrice,
          'lastPriceQuantity': lastPriceQuantity,
          'remainingLastPriceQuantity': remainingLastPriceQuantity,
          'alreadyPurchased': product['alreadyPurchased'],
          'isEligibleForLastPrice': shouldUseLastPrice,
          'image': product['image'],
          'quantity': 1,
          'addedAt': DateTime.now().toIso8601String(),
        });
      });
    }

    // Update product's cart status
    final productIndex = _products.indexWhere((p) => p['id'] == productId);
    if (productIndex != -1) {
      setState(() {
        _products[productIndex]['isInCart'] = true;
        _products[productIndex]['cartQuantity'] = 
            (_products[productIndex]['cartQuantity'] ?? 0) + 1;
        
        // Update remaining last price quantity
        if (shouldUseLastPrice) {
          _products[productIndex]['remainingLastPriceQuantity'] = 
              (_products[productIndex]['remainingLastPriceQuantity'] ?? 0) - 1;
        }
      });
    }

    _saveCartToPrefs();
    _filterProducts();

    String message = '${product['name']} added to cart';
    if (shouldUseLastPrice) {
      message += ' at member price';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: shouldUseLastPrice ? Colors.orange : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeFromCart(String productId) {
    setState(() {
      _cartItems.removeWhere((item) => item['id'] == productId);
    });

    // Update product's cart status
    final productIndex = _products.indexWhere((p) => p['id'] == productId);
    if (productIndex != -1) {
      setState(() {
        _products[productIndex]['isInCart'] = false;
        _products[productIndex]['cartQuantity'] = 0;
      });
    }

    _saveCartToPrefs();
    _filterProducts();
  }

  void _updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      _removeFromCart(productId);
      return;
    }

    final cartIndex = _cartItems.indexWhere((item) => item['id'] == productId);
    if (cartIndex != -1) {
      final double? lastPrice = _cartItems[cartIndex]['lastPrice'];
      final double lastPriceQuantity = _cartItems[cartIndex]['lastPriceQuantity'] ?? 0;
      
      // Update quantity
      setState(() {
        _cartItems[cartIndex]['quantity'] = quantity;
        
        // Check if we should switch between last price and regular price
        if (lastPrice != null && lastPrice > 0 && lastPriceQuantity > 0) {
          _cartItems[cartIndex]['isEligibleForLastPrice'] = 
              quantity <= lastPriceQuantity.floor();
        }
      });
    }

    // Update product's cart quantity and remaining last price
    final productIndex = _products.indexWhere((p) => p['id'] == productId);
    if (productIndex != -1) {
      setState(() {
        _products[productIndex]['cartQuantity'] = quantity;
        
        // Update remaining last price quantity
        final double lastPriceQuantity = _products[productIndex]['lastPriceQuantity'] ?? 0;
        final double alreadyPurchased = _products[productIndex]['alreadyPurchased'] ?? 0;
        final double totalPurchased = alreadyPurchased + quantity;
        
        _products[productIndex]['remainingLastPriceQuantity'] = 
            (lastPriceQuantity - totalPurchased).clamp(0.0, lastPriceQuantity);
      });
    }

    _saveCartToPrefs();
    _filterProducts();
  }

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
            onPressed: () async {
              await _clearCartFromPrefs();
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

  // ========================================
  // HARITH STORE PRODUCT CARD WIDGET
  // ========================================
  Widget _buildHarithStoreProductCard(Map<String, dynamic> product) {
    final double price = product['price'];
    final double? offerPrice = product['offerPrice'];
    final double? lastPrice = product['lastPrice'];
    final double lastPriceQuantity = product['lastPriceQuantity'];
    final double remainingLastPriceQuantity = product['remainingLastPriceQuantity'];
    final double alreadyPurchased = product['alreadyPurchased'];
    final bool isEligibleForLastPrice = product['isEligibleForLastPrice'];
    final bool isInCart = product['isInCart'];
    final int cartQuantity = product['cartQuantity'];

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HarithSingleProductPage(
              product: {
                ...product,
                'id': product['id'],
                'category': product['category'],
                'discountedprice': product['price'],
                'offerprice': product['offerPrice'],
                'lastprice': product['lastPrice'],
                'lastpricequantity': product['lastPriceQuantity'],
                'image_url': product['image'],
                'details': product['details'],
                'stock': product['stock'] ?? -1,
              },
              initialCartItems: _cartItems,
              onCartUpdate: (updatedCart) {
                setState(() {
                  _cartItems = updatedCart;
                });
                _saveCartToPrefs();
                _fetchProducts();
              },
            ),
          ),
        );
      },
      child: Container(
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
            // Product Image with Member Badge
            Stack(
              children: [
                // Product Image
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: product['image'] != null && product['image'].isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: product['image'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: Colors.green[400],
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
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

                // Member badge
                if (_hasMembership && lastPrice != null && lastPrice > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isEligibleForLastPrice 
                            ? Colors.orange 
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isEligibleForLastPrice 
                            ? 'MEMBER' 
                            : 'QUOTA USED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Cart Badge (if item is in cart)
                if (isInCart)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check, size: 10, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            '$cartQuantity',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
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
                        // Product Name
                        Text(
                          product['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Category
                        Text(
                          product['category'],
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Price Display
                        _buildPriceDisplay(
                          price: price,
                          offerPrice: offerPrice,
                          lastPrice: lastPrice,
                          lastPriceQuantity: lastPriceQuantity,
                          remainingLastPriceQuantity: remainingLastPriceQuantity,
                          alreadyPurchased: alreadyPurchased,
                          isEligibleForLastPrice: isEligibleForLastPrice,
                          cartQuantity: cartQuantity,
                        ),
                      ],
                    ),

                    // Cart Button
                    _buildCartButton(
                      isInCart: isInCart,
                      cartQuantity: cartQuantity,
                      lastPriceQuantity: lastPriceQuantity,
                      remainingLastPriceQuantity: remainingLastPriceQuantity,
                      isEligibleForLastPrice: isEligibleForLastPrice,
                      onAddToCart: () => _addToCart(product),
                      onIncreaseQuantity: () => _updateQuantity(product['id'], cartQuantity + 1),
                      onDecreaseQuantity: () => _updateQuantity(product['id'], cartQuantity - 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cart Button Builder
  Widget _buildCartButton({
    required bool isInCart,
    required int cartQuantity,
    required double lastPriceQuantity,
    required double remainingLastPriceQuantity,
    required bool isEligibleForLastPrice,
    required VoidCallback onAddToCart,
    required VoidCallback onIncreaseQuantity,
    required VoidCallback onDecreaseQuantity,
  }) {
    // Calculate how many items the user can still add at last price
    final int remainingAtLastPrice = remainingLastPriceQuantity.floor();
    
    // Check if user is still eligible for last price based on current cart quantity
    final bool canAddAtLastPrice = isEligibleForLastPrice && 
        cartQuantity < remainingAtLastPrice;

    // If item is in cart and we're still within last price quantity
    if (isInCart && cartQuantity > 0) {
      // Check if we should still show last price or switch to regular price
      final bool showLastPriceInCart = _hasMembership && 
          lastPriceQuantity > 0 && 
          cartQuantity <= remainingAtLastPrice;

      return Container(
        height: 32,
        decoration: BoxDecoration(
          color: showLastPriceInCart ? Colors.orange.shade50 : Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: showLastPriceInCart ? Colors.orange.shade200 : Colors.green.shade200, 
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Decrease Button
            IconButton(
              onPressed: onDecreaseQuantity,
              icon: Icon(
                cartQuantity > 1 ? Icons.remove : Icons.delete_outline,
                size: 16,
                color: cartQuantity > 1 ? 
                  (showLastPriceInCart ? Colors.orange : Colors.green) : 
                  Colors.red,
              ),
              padding: const EdgeInsets.only(left: 8),
              constraints: const BoxConstraints(),
            ),
            
            // Quantity Display with price indicator
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$cartQuantity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: showLastPriceInCart ? Colors.orange : Colors.green,
                  ),
                ),
                if (showLastPriceInCart && remainingAtLastPrice > 0)
                  Text(
                    '${remainingAtLastPrice - cartQuantity} more at member price',
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),
            
            // Increase Button
            IconButton(
              onPressed: onIncreaseQuantity,
              icon: Icon(
                Icons.add,
                size: 16,
                color: showLastPriceInCart ? Colors.orange : Colors.green,
              ),
              padding: const EdgeInsets.only(right: 8),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    } else {
      // Add to Cart Button - Show different text based on eligibility
      final String buttonText = canAddAtLastPrice 
          ? 'Add at Member Price'
          : 'Add to Cart';
      
      final Color buttonColor = canAddAtLastPrice 
          ? Colors.orange 
          : const Color.fromARGB(255, 116, 190, 119);
      
      return SizedBox(
        height: 32,
        child: ElevatedButton.icon(
          onPressed: onAddToCart,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          icon: Icon(
            canAddAtLastPrice ? Icons.card_membership : Icons.add_shopping_cart,
            size: 16,
          ),
          label: Text(
            buttonText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildPriceDisplay({
    required double price,
    required double? offerPrice,
    required double? lastPrice,
    required double lastPriceQuantity,
    required double remainingLastPriceQuantity,
    required double alreadyPurchased,
    required bool isEligibleForLastPrice,
    required int cartQuantity,
  }) {
    // Check if item is in cart and if we're still within last price quantity
    final bool showLastPrice = _hasMembership && 
        lastPrice != null && 
        lastPrice > 0 && 
        (remainingLastPriceQuantity > 0 || cartQuantity <= lastPriceQuantity.floor());
    
    if (showLastPrice) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (price > lastPrice)
            Text(
              '₹${price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                decoration: TextDecoration.lineThrough,
              ),
            ),
          
          Row(
            children: [
              const Icon(Icons.card_membership, size: 12, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                '₹${lastPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: remainingLastPriceQuantity > 0 
                  ? Colors.orange[50] 
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: remainingLastPriceQuantity > 0 
                    ? Colors.orange 
                    : Colors.grey,
                width: 1,
              ),
            ),
            child: Text(
              remainingLastPriceQuantity > 0
                  ? '${remainingLastPriceQuantity.toStringAsFixed(2)}/${lastPriceQuantity.toStringAsFixed(2)} left at member price'
                  : 'Member price used',
              style: TextStyle(
                fontSize: 9,
                color: remainingLastPriceQuantity > 0 
                    ? Colors.orange[800] 
                    : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          if (offerPrice != null && offerPrice > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'After quota: ₹${offerPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      );
    } else if (offerPrice != null && offerPrice > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '₹${price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Text(
            '₹${offerPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '₹${price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildProductGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No products found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            if (_searchQuery.isNotEmpty)
              Text(
                'Try a different search term',
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.56,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildHarithStoreProductCard(product);
      },
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 16 : 8,
              right: index == _categories.length - 1 ? 16 : 8,
            ),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = category;
                  _filterProducts();
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: const Color.fromARGB(255, 116, 190, 119),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      )
    );
  }

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
      double price;
      if (_hasMembership && 
          item['lastPrice'] != null && 
          item['lastPrice'] > 0 && 
          item['isEligibleForLastPrice'] == true) {
        price = item['lastPrice'];
      } else {
        price = item['offerPrice'] ?? item['price'] ?? 0.0;
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harith Gramam Store'),
        backgroundColor: const Color.fromARGB(255, 116, 190, 119),
        actions: [
          // Clear cart button
          if (_cartItems.isNotEmpty)
            IconButton(
              onPressed: _clearCart,
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear Cart',
            ),
          
          // Membership badge
          if (_hasMembership)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_membership, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    'MEMBER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          
          // Cart button
          IconButton(
            icon: Badge(
              label: Text('${_cartItems.length}'),
              isLabelVisible: _cartItems.isNotEmpty,
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: _cartItems.isNotEmpty ? _navigateToCart : null,
            tooltip: 'View Cart',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // User info and membership status
              if (_hasMembership)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange[50],
                  child: Row(
                    children: [
                      Icon(Icons.verified_user, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Member Benefits Active',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'ID: $_membershipId',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Member Prices',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _filterProducts();
                    });
                  },
                ),
              ),

              // Category Filter
              _buildCategoryChips(),
              const SizedBox(height: 8),

              // Product Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredProducts.length} Products',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    if (_cartItems.isNotEmpty)
                      Text(
                        '${_cartItems.length} items in cart',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Product Grid
              Expanded(
                child: _buildProductGrid(),
              ),
            ],
          ),

          // Floating Cart Button
          _buildCartFloatingButton(),
        ],
      ),
    );
  }
}