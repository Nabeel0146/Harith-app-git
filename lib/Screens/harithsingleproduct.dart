// lib/1SCREENS/Products/single_product_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:harithapp/Services/whatsappcartservice.dart';
import 'package:shimmer/shimmer.dart';
import 'package:harithapp/Screens/Whatsappcart/whatsappcart.dart'; // ADD THIS IMPORT


class SingleProductPage extends StatefulWidget {
  final Map<String, dynamic> product;
  const SingleProductPage({super.key, required this.product});

  @override
  State<SingleProductPage> createState() => _SingleProductPageState();
}

class _SingleProductPageState extends State<SingleProductPage> {
  final WhatsAppCartService _cartService = WhatsAppCartService();
  bool _isInCart = false;
  int _cartQuantity = 0;

  @override
  void initState() {
    super.initState();
    _checkCartStatus();
    _cartService.addListener(_onCartUpdated);
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartUpdated);
    super.dispose();
  }

  void _checkCartStatus() {
    final productId = widget.product['id'];
    if (productId != null) {
      setState(() {
        _isInCart = _cartService.isInCart(productId);
        _cartQuantity = _isInCart ? _cartService.getQuantity(productId) : 0;
      });
    }
  }

  void _onCartUpdated(List<Map<String, dynamic>> cartItems) {
    _checkCartStatus();
  }

  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _addToCart() async {
    final productId = widget.product['id'];
    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _cartService.addToCart({
      'id': productId,
      'name': widget.product['name'],
      'discountedprice': _parseToDouble(widget.product['discountedprice']),
      'offerprice': widget.product['offerprice'] != null 
          ? _parseToDouble(widget.product['offerprice'])
          : null,
      'image_url': widget.product['image_url'],
      'category': widget.product['category'] ?? 'All Products',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product['name']} added to WhatsApp Cart'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _removeFromCart() async {
    final productId = widget.product['id'];
    if (productId != null) {
      await _cartService.removeFromCart(productId);
    }
  }

  Future<void> _updateQuantity(int quantity) async {
    final productId = widget.product['id'];
    if (productId != null) {
      await _cartService.updateQuantity(productId, quantity);
    }
  }

  // ADD THIS METHOD: Navigate to WhatsApp Cart page
  void _navigateToWhatsAppCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WhatsAppCartPage(
          cartItems: _cartService.cartItems,
          onCartUpdate: (updatedCart) {
            // Handle cart updates if needed
            // The cart service already updates automatically
          },
          onPlaceOrder: (cartItems) {
            // This will be handled by the WhatsAppCartPage
            // You might want to pass a callback from parent if needed
          },
        ),
      ),
    );
  }

  // ADD THIS METHOD: Place order via WhatsApp
  Future<void> _placeOrderViaWhatsApp() async {
    // You'll need to implement this method based on your WhatsAppCartPage logic
    // Or you can navigate to WhatsAppCartPage and let user place order from there
    _navigateToWhatsAppCart();
  }

  Widget _buildPriceSection() {
    final discountedPrice = widget.product['discountedprice']?.toString() ?? '';
    final offerPrice = widget.product['offerprice']?.toString() ?? '';
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
    final heroTag = 'product_${widget.product['image_url']}';
    final productId = widget.product['id'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.product['name'] ?? 'Product'),
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 116, 190, 119),
        actions: [
          // Cart indicator in app bar - UPDATED
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Stream.periodic(const Duration(seconds: 1))
                .asyncMap((_) => _cartService.cartItems),
            builder: (context, snapshot) {
              final cartItems = snapshot.data ?? _cartService.cartItems;
              final totalItems = _cartService.totalItems;
              
              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.white),
                    if (totalItems > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            totalItems.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: _navigateToWhatsAppCart, // UPDATED: Use the new method
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Hero(
                    tag: heroTag,
                    child: CachedNetworkImage(
                      imageUrl: widget.product['image_url'] ?? '',
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
                          widget.product['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        if (widget.product['category'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.product['category'],
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
                  if (widget.product['details'] != null &&
                      (widget.product['details'] as String).trim().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.product['details'],
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                    ),

                  // Info section about cart
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 232, 245, 233),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.shopping_cart,
                              color: Color.fromARGB(255, 116, 190, 119),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'WhatsApp Cart',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add items to your WhatsApp Cart. When ready, you can send all items together via WhatsApp to place your order.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isInCart 
                            ? 'This item is in your cart ($_cartQuantity pcs)'
                            : 'This item is not in your cart',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _isInCart ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // ADDED: Quick cart summary
                        if (_cartService.totalItems > 0)
                          GestureDetector(
                            onTap: _navigateToWhatsAppCart,
                            child: Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'View WhatsApp Cart',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${_cartService.totalItems} items',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: Colors.green[700],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Add extra space at bottom to prevent overlap
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          
          // Bottom cart controls
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: _isInCart
                  ? Row(
                      children: [
                        Expanded(
                          child: _buildQuantityControls(),
                        ),
                        const SizedBox(width: 12),
                        // ADDED: Quick view cart button
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: IconButton(
                            onPressed: _navigateToWhatsAppCart,
                            icon: Stack(
                              children: [
                                const Icon(Icons.shopping_cart, color: Colors.green),
                                if (_cartService.totalItems > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        _cartService.totalItems.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildAddToCartButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _addToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 116, 190, 119),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_shopping_cart),
            SizedBox(width: 8),
            Text(
              'Add to WhatsApp Cart',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => _updateQuantity(_cartQuantity - 1),
            icon: Icon(
              _cartQuantity > 1 ? Icons.remove : Icons.delete_outline,
              color: _cartQuantity > 1 ? Colors.green : Colors.red,
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _cartQuantity > 1 ? Colors.green[300]! : Colors.red[300]!,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'In Cart',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                ),
              ),
              Text(
                '$_cartQuantity',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          IconButton(
            onPressed: () => _updateQuantity(_cartQuantity + 1),
            icon: const Icon(Icons.add, color: Colors.green, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.green[300]!, width: 1),
              ),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}