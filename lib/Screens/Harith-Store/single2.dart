// lib/Screens/harith_single_product.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HarithSingleProductPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final List<Map<String, dynamic>>? initialCartItems;
  final Function(List<Map<String, dynamic>>)? onCartUpdate;

  const HarithSingleProductPage({
    super.key,
    required this.product,
    this.initialCartItems,
    this.onCartUpdate,
  });

  @override
  State<HarithSingleProductPage> createState() => _HarithSingleProductPageState();
}

class _HarithSingleProductPageState extends State<HarithSingleProductPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late Map<String, dynamic> _product;
  int _quantity = 1;
  bool _isAddingToCart = false;
  bool _hasMembership = false;
  String? _membershipId;
  double _memberPurchasedQuantity = 0.0;
  bool _isEligibleForLastPrice = false;
  double _remainingLastPriceQuantity = 0.0;
  List<Map<String, dynamic>> _cartItems = [];
  
  @override
  void initState() {
    super.initState();
    _product = Map<String, dynamic>.from(widget.product);
    if (widget.initialCartItems != null) {
      _cartItems = List.from(widget.initialCartItems!);
    }
    _checkCartStatus();
    _loadUserData();
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
          final userData = userDoc.data() as Map<String, dynamic>;
          _membershipId = userData['membershipId']?.toString();
          _hasMembership = _membershipId != null && 
                          _membershipId!.isNotEmpty && 
                          _membershipId != 'null';
          
          if (_hasMembership) {
            await _fetchMemberPurchasedQuantity();
            _calculateEligibility();
          }
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _fetchMemberPurchasedQuantity() async {
    try {
      final now = DateTime.now();
      final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
      final productId = _product['id'];
      
      final salesQuery = await _firestore
          .collection('harith-sales')
          .where('customerId', isEqualTo: _auth.currentUser?.uid)
          .where('createdAt', isGreaterThanOrEqualTo: oneMonthAgo)
          .where('isMembershipApplied', isEqualTo: true)
          .get();

      double totalPurchased = 0.0;
      
      for (var sale in salesQuery.docs) {
        final items = sale.data()['items'] as List<dynamic>;
        for (var item in items) {
          if (item['id']?.toString() == productId && item['lastPrice'] != null) {
            final breakdown = item['priceBreakdown'] as Map<String, dynamic>?;
            if (breakdown != null && breakdown['memberQty'] != null) {
              final double memberQty = _parseToDouble(breakdown['memberQty']);
              totalPurchased += memberQty;
            }
          }
        }
      }
      
      setState(() {
        _memberPurchasedQuantity = totalPurchased;
      });
    } catch (e) {
      print('Error fetching member purchases: $e');
    }
  }

  void _calculateEligibility() {
    final double lastPriceQuantity = _parseToDouble(_product['lastPriceQuantity'] ?? 0);
    if (lastPriceQuantity > 0) {
      _remainingLastPriceQuantity = (lastPriceQuantity - _memberPurchasedQuantity)
          .clamp(0.0, lastPriceQuantity);
      _isEligibleForLastPrice = _remainingLastPriceQuantity > 0;
      
      // Update product data
      _product['remainingLastPriceQuantity'] = _remainingLastPriceQuantity;
      _product['alreadyPurchased'] = _memberPurchasedQuantity;
      _product['isEligibleForLastPrice'] = _isEligibleForLastPrice;
    }
  }

  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _checkCartStatus() {
    final productId = _product['id'];
    final cartItem = _cartItems.firstWhere(
      (item) => item['id'] == productId,
      orElse: () => {},
    );
    
    if (cartItem.isNotEmpty) {
      setState(() {
        _quantity = cartItem['quantity'] ?? 1;
        _product['isInCart'] = true;
        _product['cartQuantity'] = _quantity;
      });
    }
  }

  void _addToCart() async {
    if (_isAddingToCart) return;
    
    setState(() {
      _isAddingToCart = true;
    });

    try {
      final productId = _product['id'];
      final existingIndex = _cartItems.indexWhere((item) => item['id'] == productId);
      
      if (existingIndex != -1) {
        // Update existing item
        _cartItems[existingIndex]['quantity'] = _quantity;
      } else {
        // Add new item to cart
        _cartItems.add({
          'id': productId,
          'name': _product['name'],
          'category': _product['category'],
          'price': _parseToDouble(_product['discountedprice']),
          'offerPrice': _product['offerprice'] != null ? _parseToDouble(_product['offerprice']) : null,
          'lastPrice': _product['lastprice'] != null ? _parseToDouble(_product['lastprice']) : null,
          'lastPriceQuantity': _parseToDouble(_product['lastpricequantity'] ?? 0),
          'remainingLastPriceQuantity': _remainingLastPriceQuantity,
          'alreadyPurchased': _memberPurchasedQuantity,
          'isEligibleForLastPrice': _isEligibleForLastPrice,
          'image': _product['image_url'],
          'details': _product['details'] ?? '',
          'quantity': _quantity,
          'addedAt': DateTime.now().toIso8601String(),
        });
      }

      // Update product status
      setState(() {
        _product['isInCart'] = true;
        _product['cartQuantity'] = _quantity;
      });

      // Notify parent about cart update
      if (widget.onCartUpdate != null) {
        widget.onCartUpdate!(_cartItems);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_product['name']} added to cart'),
          backgroundColor: const Color.fromARGB(255, 116, 190, 119),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              // Navigation to cart page would be handled by parent
            },
          ),
        ),
      );
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isAddingToCart = false;
      });
    }
  }

  void _removeFromCart() async {
    final productId = _product['id'];
    _cartItems.removeWhere((item) => item['id'] == productId);
    
    setState(() {
      _product['isInCart'] = false;
      _product['cartQuantity'] = 0;
      _quantity = 1;
    });

    if (widget.onCartUpdate != null) {
      widget.onCartUpdate!(_cartItems);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_product['name']} removed from cart'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildPriceSection() {
    final double price = _parseToDouble(_product['discountedprice']);
    final double? offerPrice = _product['offerprice'] != null 
        ? _parseToDouble(_product['offerprice']) 
        : null;
    final double? lastPrice = _product['lastprice'] != null 
        ? _parseToDouble(_product['lastprice']) 
        : null;
    final double lastPriceQuantity = _parseToDouble(_product['lastpricequantity'] ?? 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Price Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_hasMembership)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.card_membership, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'MEMBER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Original Price
          Row(
            children: [
              const Text(
                'MRP: ',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                '₹${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  decoration: (offerPrice != null && offerPrice > 0) || 
                             (lastPrice != null && lastPrice > 0 && _hasMembership)
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Offer Price
          if (offerPrice != null && offerPrice > 0)
            Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Offer Price: ',
                      style: TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                    Text(
                      '₹${offerPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          
          // Member Price
          if (_hasMembership && lastPrice != null && lastPrice > 0)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.card_membership, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(
                            'Member Price: ',
                            style: TextStyle(fontSize: 14, color: Colors.orange),
                          ),
                          Text(
                            '₹${lastPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Member quota info
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isEligibleForLastPrice 
                              ? Colors.green[50] 
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _isEligibleForLastPrice 
                                ? Colors.green 
                                : Colors.grey,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isEligibleForLastPrice 
                                      ? 'Monthly Quota Available' 
                                      : 'Monthly Quota Used',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _isEligibleForLastPrice 
                                        ? Colors.green 
                                        : Colors.grey,
                                  ),
                                ),
                                Text(
                                  '${_remainingLastPriceQuantity.toStringAsFixed(2)}/${lastPriceQuantity.toStringAsFixed(2)} kg',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _isEligibleForLastPrice 
                                        ? Colors.green 
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isEligibleForLastPrice
                                  ? 'You can purchase ${_remainingLastPriceQuantity.toStringAsFixed(2)} kg at member price this month'
                                  : 'You have used ${_memberPurchasedQuantity.toStringAsFixed(2)} kg of your monthly quota',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      if (!_isEligibleForLastPrice && offerPrice != null && offerPrice > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'Now at offer price: ₹${offerPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          
          // Regular price if no offer or member price
          if ((offerPrice == null || offerPrice <= 0) && 
              (!_hasMembership || lastPrice == null || lastPrice <= 0 || !_isEligibleForLastPrice))
            Row(
              children: [
                const Text(
                  'Price: ',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  '₹${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          
          // Savings info
          const SizedBox(height: 16),
         
        ],
      ),
    );
  }

  Widget _buildSavingsInfo(double price, double? offerPrice, double? lastPrice) {
    double savings = 0.0;
    String savingsType = '';
    
    if (_hasMembership && lastPrice != null && lastPrice > 0 && _isEligibleForLastPrice) {
      savings = price - lastPrice;
      savingsType = 'Member Savings';
    } else if (offerPrice != null && offerPrice > 0) {
      savings = price - offerPrice;
      savingsType = 'Offer Savings';
    }
    
    if (savings > 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          children: [
            const Icon(Icons.savings, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    savingsType,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'Save ₹${savings.toStringAsFixed(2)} (${((savings / price) * 100).toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildProductImage() {
    final imageUrl = _product['image_url']?.toString() ?? '';
    
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(
                  color: const Color.fromARGB(255, 116, 190, 119),
                ),
              ),
              errorWidget: (context, url, error) => Center(
                child: Icon(
                  Icons.shopping_bag,
                  size: 80,
                  color: Colors.grey[400],
                ),
              ),
            )
          : Center(
              child: Icon(
                Icons.shopping_bag,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
    );
  }

  Widget _buildProductDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _product['name']?.toString() ?? 'Product Name',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _product['category']?.toString() ?? 'Uncategorized',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          if (_product['details']?.toString().isNotEmpty == true)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _product['details']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          
          // Stock info
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.inventory, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Availability: ',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                _product['stock'] == -1 
                    ? 'In Stock' 
                    : (_product['stock'] ?? 0) > 0 
                        ? 'In Stock' 
                        : 'Out of Stock',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _product['stock'] == -1 || (_product['stock'] ?? 0) > 0
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    final bool isInCart = _product['isInCart'] == true;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quantity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _quantity > 1 ? () {
                        setState(() {
                          _quantity--;
                        });
                      } : null,
                      color: _quantity > 1 ? Colors.black : Colors.grey,
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          _quantity++;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              if (isInCart)
                OutlinedButton.icon(
                  onPressed: _removeFromCart,
                  icon: const Icon(Icons.remove_shopping_cart),
                  label: const Text('Remove from Cart'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _isAddingToCart ? null : _addToCart,
                  icon: _isAddingToCart
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_shopping_cart),
                  label: Text(_isAddingToCart ? 'Adding...' : 'Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 116, 190, 119),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and cart
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Product Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Badge(
                      label: Text('${_cartItems.length}'),
                      isLabelVisible: _cartItems.isNotEmpty,
                      child: const Icon(Icons.shopping_cart_outlined),
                    ),
                    onPressed: () {
                      // Cart navigation would be handled by parent
                    },
                  ),
                ],
              ),
            ),
            
            // Product content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProductImage(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildPriceSection(),
                          const SizedBox(height: 16),
                          _buildProductDetails(),
                          const SizedBox(height: 16),
                          _buildQuantitySelector(),
                          const SizedBox(height: 32),
                        ],
                      ),
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
}