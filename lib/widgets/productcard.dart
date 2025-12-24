// lib/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:harithapp/Services/whatsappcartservice.dart';
import 'package:shimmer/shimmer.dart';


class ProductCard extends StatefulWidget {
  final String productId;
  final String name;
  final String imageUrl;
  final String discountedPrice;
  final String offerPrice;
  final VoidCallback? onTap;
  final bool isGridItem;
  final String? category;

  const ProductCard({
    super.key,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.discountedPrice,
    required this.offerPrice,
    this.onTap,
    this.isGridItem = false,
    this.category,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
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
    setState(() {
      _isInCart = _cartService.isInCart(widget.productId);
      _cartQuantity = _isInCart ? _cartService.getQuantity(widget.productId) : 0;
    });
  }

  void _onCartUpdated(List<Map<String, dynamic>> cartItems) {
    _checkCartStatus();
  }

  Future<void> _addToCart() async {
    await _cartService.addToCart({
      'id': widget.productId,
      'name': widget.name,
      'discountedprice': double.tryParse(widget.discountedPrice) ?? 0.0,
      'offerprice': widget.offerPrice.isNotEmpty 
          ? double.tryParse(widget.offerPrice)
          : null,
      'image_url': widget.imageUrl,
      'category': widget.category ?? 'All Products',
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.name} added to WhatsApp Cart'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _removeFromCart() async {
    await _cartService.removeFromCart(widget.productId);
  }

  Future<void> _updateQuantity(int quantity) async {
    await _cartService.updateQuantity(widget.productId, quantity);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
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
        child: widget.isGridItem ? _buildGridItem() : _buildListItem(),
      ),
    );
  }

  Widget _buildListItem() {
    return Container(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image - Square aspect ratio
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: AspectRatio(
              aspectRatio: 1.08,
              child: Stack(
                children: [
                  _buildProductImage(),
                  // In Cart badge
                  if (_isInCart)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
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
                              '$_cartQuantity',
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
            ),
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
                      Text(
                        widget.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildPriceSection(),
                    ],
                  ),
                  // Cart Button - Full Width
                  _buildCartButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image - Square aspect ratio
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(12),
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                _buildProductImage(),
                // In Cart badge
                if (_isInCart)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
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
                            '$_cartQuantity',
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
          ),
        ),
        // Product Details with Cart Button
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
                    Text(
                      widget.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildPriceSection(),
                  ],
                ),
                // Cart Button - Full Width
                _buildCartButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage() {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(color: Colors.white),
      ),
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.discountedPrice.isNotEmpty && 
            widget.discountedPrice != widget.offerPrice)
          Row(
            children: [
              Text(
                '₹${widget.discountedPrice}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${((1 - double.parse(widget.offerPrice) / double.parse(widget.discountedPrice)) * 100).toStringAsFixed(0)}% OFF',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        Text(
          '₹${widget.offerPrice}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildCartButton() {
    if (_isInCart && _cartQuantity > 0) {
      // Quantity Controls
      return Container(
        height: 32,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Decrease Button
            IconButton(
              onPressed: () => _updateQuantity(_cartQuantity - 1),
              icon: Icon(
                _cartQuantity > 1 ? Icons.remove : Icons.delete_outline,
                size: 16,
                color: _cartQuantity > 1 ? Colors.green : Colors.red,
              ),
              padding: const EdgeInsets.only(left: 8),
              constraints: const BoxConstraints(),
            ),
            
            // Quantity Display
            Text(
              '$_cartQuantity',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            
            // Increase Button
            IconButton(
              onPressed: () => _updateQuantity(_cartQuantity + 1),
              icon: const Icon(
                Icons.add,
                size: 16,
                color: Colors.green,
              ),
              padding: const EdgeInsets.only(right: 8),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    } else {
      // Add to Cart Button
      return SizedBox(
        height: 32,
        child: ElevatedButton.icon(
          onPressed: _addToCart,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          icon: const Icon(
            Icons.add_shopping_cart,
            size: 16,
          ),
          label: const Text(
            'Add to Cart',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
  }
}