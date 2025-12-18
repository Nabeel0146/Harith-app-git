// lib/Screens/harith_cart.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:harithapp/Screens/Harith-Store/orderspage.dart';

class HarithCartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(List<Map<String, dynamic>>) onCartUpdate;

  const HarithCartPage({
    super.key,
    required this.cartItems,
    required this.onCartUpdate,
  });

  @override
  State<HarithCartPage> createState() => _HarithCartPageState();
}

class _HarithCartPageState extends State<HarithCartPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> _cartItems = [];
  Map<String, dynamic>? _userData;
  bool _hasMembership = false;
  bool _isPlacingOrder = false;
  String _deliveryAddress = '';
  String _wardNo = '';
  
  // Price tracking
  double _subTotal = 0.0;
  double _grandTotal = 0.0;
  double _memberTotal = 0.0;
  double _offerTotal = 0.0;
  double _regularTotal = 0.0;
  double _totalSavings = 0.0;
  double _totalOriginalValue = 0.0; // Total of discountedprice (original)
  
  // Item counts
  int _memberItemsCount = 0;
  int _offerItemsCount = 0;
  int _regularItemsCount = 0;
  
  @override
  void initState() {
    super.initState();
    _cartItems = List.from(widget.cartItems);
    _loadUserData();
    _calculateTotals();
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
            final membershipId = _userData?['membershipId']?.toString();
            _hasMembership = membershipId != null && 
                            membershipId.isNotEmpty && 
                            membershipId != 'null';
            _deliveryAddress = _userData?['deliveryAddress']?.toString() ?? '';
            _wardNo = _userData?['wardNo']?.toString() ?? '';
          });
          _calculateTotals();
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _calculateTotals() {
    _subTotal = 0.0;
    _memberTotal = 0.0;
    _offerTotal = 0.0;
    _regularTotal = 0.0;
    _totalSavings = 0.0;
    _totalOriginalValue = 0.0;
    
    _memberItemsCount = 0;
    _offerItemsCount = 0;
    _regularItemsCount = 0;
    
    for (var item in _cartItems) {
      final double discountedPrice = item['price'] ?? 0.0; // This is the discountedprice from product
      final double? offerPrice = item['offerPrice']; // offerprice from product
      final double? lastPrice = item['lastPrice']; // lastprice from product
      final int quantity = item['quantity'] is int ? item['quantity'] as int : 0;
      
      // Track original value (based on discountedprice)
      _totalOriginalValue += (discountedPrice * quantity);
      
      double finalPrice;
      
      // Determine which price applies
      if (_hasMembership && 
          lastPrice != null && 
          lastPrice > 0 && 
          item['isEligibleForLastPrice'] == true) {
        // Member price applies
        finalPrice = lastPrice;
        _memberTotal += (lastPrice * quantity);
        _memberItemsCount += quantity;
        _totalSavings += (discountedPrice - lastPrice) * quantity;
      } else if (offerPrice != null && offerPrice > 0) {
        // Offer price applies
        finalPrice = offerPrice;
        _offerTotal += (offerPrice * quantity);
        _offerItemsCount += quantity;
        _totalSavings += (discountedPrice - offerPrice) * quantity;
      } else {
        // Regular price applies (discountedprice)
        finalPrice = discountedPrice;
        _regularTotal += (discountedPrice * quantity);
        _regularItemsCount += quantity;
      }
      
      _subTotal += (finalPrice * quantity);
    }
    
    _grandTotal = _subTotal; // No delivery charge
    
    setState(() {});
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeItem(index);
      return;
    }
    
    setState(() {
      _cartItems[index]['quantity'] = newQuantity;
    });
    
    _calculateTotals();
    widget.onCartUpdate(List.from(_cartItems));
  }

  void _removeItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove ${_cartItems[index]['name']} from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _cartItems.removeAt(index);
              });
              _calculateTotals();
              widget.onCartUpdate(List.from(_cartItems));
              Navigator.pop(context);
              
              if (_cartItems.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cart is now empty'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(int index) {
    final item = _cartItems[index];
    final String name = item['name']?.toString() ?? 'Unknown';
    final String? imageUrl = item['image']?.toString();
    final int quantity = item['quantity'] is int ? item['quantity'] as int : 0;
    final double discountedPrice = item['price'] ?? 0.0; // This is discountedprice
    final double? offerPrice = item['offerPrice']; // offerprice
    final double? lastPrice = item['lastPrice']; // lastprice
    final bool isEligibleForLastPrice = item['isEligibleForLastPrice'] ?? false;
    
    double finalPrice;
    String priceType = 'Regular';
    Color priceColor = Colors.green;
    
    // Determine which price applies
    if (_hasMembership && lastPrice != null && lastPrice > 0 && isEligibleForLastPrice) {
      finalPrice = lastPrice;
      priceType = 'Member';
      priceColor = Colors.orange;
    } else if (offerPrice != null && offerPrice > 0) {
      finalPrice = offerPrice;
      priceType = 'Offer';
      priceColor = Colors.blue;
    } else {
      finalPrice = discountedPrice;
      priceType = 'Regular';
      priceColor = Colors.green;
    }
    
    final double itemTotal = finalPrice * quantity;
    final double originalItemTotal = discountedPrice * quantity;
    final double savings = originalItemTotal - itemTotal;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: Colors.green[400],
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(
                                Icons.shopping_bag,
                                size: 32,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.shopping_bag,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                        ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // All Three Prices Display
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Regular Price (discountedprice)
                          _buildPriceRow(
                            'Regular Price:',
                            '₹${discountedPrice.toStringAsFixed(2)}',
                            isApplied: priceType == 'Regular',
                            color: priceType == 'Regular' ? Colors.green : Colors.grey,
                          ),
                          
                          // Offer Price (offerprice)
                          if (offerPrice != null && offerPrice > 0)
                            _buildPriceRow(
                              'Offer Price:',
                              '₹${offerPrice.toStringAsFixed(2)}',
                              isApplied: priceType == 'Offer',
                              color: priceType == 'Offer' ? Colors.blue : Colors.grey,
                            ),
                          
                          // Member Price (lastprice)
                          if (lastPrice != null && lastPrice > 0)
                            _buildPriceRow(
                              _hasMembership ? 'Your Member Price:' : 'Member Price:',
                              '₹${lastPrice.toStringAsFixed(2)}',
                              isApplied: priceType == 'Member',
                              color: priceType == 'Member' ? Colors.orange : Colors.grey,
                              isMemberPrice: true,
                            ),
                          
                          // If no lastprice available
                          if (lastPrice == null || lastPrice <= 0)
                            _buildPriceRow(
                              'Member Price:',
                              'Not Available',
                              color: Colors.grey,
                              isNotAvailable: true,
                            ),
                        ],
                      ),
                      
                      // Applied Price Tag
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: priceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: priceColor),
                        ),
                        child: Text(
                          'Applied: $priceType Price',
                          style: TextStyle(
                            fontSize: 12,
                            color: priceColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      // Savings if any
                      if (savings > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'You save: ₹${savings.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 12),
                      
                      // Quantity Controls
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => _updateQuantity(index, quantity - 1),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.red),
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  size: 18,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            
                            Text(
                              '$quantity',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            InkWell(
                              onTap: () => _updateQuantity(index, quantity + 1),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 18,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Delete Button
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            
            // Item Total
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Item Total: ₹${itemTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  if (savings > 0)
                    Text(
                      'Original: ₹${originalItemTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {
    bool isApplied = false,
    Color color = Colors.grey,
    bool isMemberPrice = false,
    bool isNotAvailable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: isApplied ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: isApplied ? FontWeight.bold : FontWeight.normal,
              fontStyle: isNotAvailable ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      )
    );
  }

  Future<void> _placeOrder() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_deliveryAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set your delivery address in profile'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final orderId = 'HARITH-${DateTime.now().millisecondsSinceEpoch}';
      
      final List<Map<String, dynamic>> orderItems = _cartItems.map((item) {
        final double discountedPrice = item['price'] ?? 0.0; // discountedprice
        final double? offerPrice = item['offerPrice']; // offerprice
        final double? lastPrice = item['lastPrice']; // lastprice
        final int quantity = item['quantity'] is int ? item['quantity'] as int : 0;
        
        double finalPrice;
        String priceType = 'regular';
        
        // Determine which price was applied
        if (_hasMembership && 
            lastPrice != null && 
            lastPrice > 0 && 
            item['isEligibleForLastPrice'] == true) {
          finalPrice = lastPrice;
          priceType = 'member';
        } else if (offerPrice != null && offerPrice > 0) {
          finalPrice = offerPrice;
          priceType = 'offer';
        } else {
          finalPrice = discountedPrice;
          priceType = 'regular';
        }
        
        return {
          'productId': item['id'],
          'name': item['name'],
          'image': item['image'],
          'quantity': quantity,
          'discountedPrice': discountedPrice, // Regular price
          'offerPrice': offerPrice, // Offer price
          'lastPrice': lastPrice, // Member price
          'isEligibleForLastPrice': item['isEligibleForLastPrice'] ?? false,
          'unitPrice': finalPrice,
          'priceType': priceType,
          'itemTotal': finalPrice * quantity,
          'originalValue': discountedPrice * quantity, // Value at regular price
        };
      }).toList();

      final orderData = {
        'orderId': orderId,
        'userId': user.uid,
        'userName': _userData?['fullName'] ?? 'User',
        'userEmail': _userData?['email'] ?? '',
        'userPhone': _userData?['mobile'] ?? '',
        'deliveryAddress': _deliveryAddress,
        'wardNo': _wardNo,
        'membershipId': _userData?['membershipId'] ?? '',
        'hasMembership': _hasMembership,
        'items': orderItems,
        'subTotal': _subTotal,
        'originalTotalValue': _totalOriginalValue, // Total at regular prices
        'grandTotal': _grandTotal,
        'memberItemsCount': _memberItemsCount,
        'offerItemsCount': _offerItemsCount,
        'regularItemsCount': _regularItemsCount,
        'memberPriceTotal': _memberTotal,
        'offerPriceTotal': _offerTotal,
        'regularPriceTotal': _regularTotal,
        'totalSavings': _totalSavings,
        'paymentMethod': 'Cash on Delivery',
        'paymentStatus': 'pending',
        'orderStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'storeType': 'harith_gramam_store',
      };

      await _firestore.collection('harith-orders').doc(orderId).set(orderData);

      // Clear cart after successful order
      setState(() {
        _cartItems.clear();
      });
      widget.onCartUpdate([]);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order $orderId placed successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, true);

    } catch (e) {
      print('Error placing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isPlacingOrder = false;
      });
    }
  }

  // Update the order confirmation dialog
  void _showOrderConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPriceBreakdown(),
              
              const SizedBox(height: 16),
              
              // Delivery Address
              if (_deliveryAddress.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Address:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(_deliveryAddress),
                    if (_wardNo.isNotEmpty)
                      Text(
                        'Ward No: $_wardNo',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              
              const SizedBox(height: 16),
              
              // Payment Method
              const Text(
                'Payment Method:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Cash on Delivery',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 116, 190, 119),
            ),
            child: _isPlacingOrder
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Confirm Order'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdownRow(String label, String value, {
    Color? color,
    bool isBold = false,
    bool isDiscount = false,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              color: color ?? Colors.black,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            isDiscount ? '-$value' : value,
            style: TextStyle(
              fontSize: fontSize,
              color: isDiscount ? Colors.green : (color ?? Colors.black),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

Widget _buildPriceBreakdown() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Price Summary',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      const SizedBox(height: 16),
      
      // Summary by Price Type
      if (_memberItemsCount > 0)
        _buildSimplePriceRow(
          'Member Price Items',
          '${_memberItemsCount} items × ₹${_memberTotal.toStringAsFixed(2)}',
          color: Colors.orange,
        ),
      
      if (_offerItemsCount > 0)
        _buildSimplePriceRow(
          'Offer Price Items',
          '${_offerItemsCount} items × ₹${_offerTotal.toStringAsFixed(2)}',
          color: Colors.blue,
        ),
      
      if (_regularItemsCount > 0)
        _buildSimplePriceRow(
          'Regular Price Items',
          '${_regularItemsCount} items × ₹${_regularTotal.toStringAsFixed(2)}',
          color: Colors.green,
        ),
      
      const SizedBox(height: 12),
      const Divider(),
      const SizedBox(height: 8),
      
      // Simple Total Breakdown
      Column(
        children: [
          _buildSimplePriceRow(
            'Total Items',
            '${_cartItems.length} items',
            fontSize: 14,
          ),
          
          const SizedBox(height: 4),
          
          _buildSimplePriceRow(
            'Subtotal',
            '₹${_subTotal.toStringAsFixed(2)}',
            fontSize: 14,
          ),
          
          if (_totalSavings > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _buildSimplePriceRow(
                'You Save',
                '-₹${_totalSavings.toStringAsFixed(2)}',
                color: Colors.green,
                fontSize: 14,
              ),
            ),
          
          const SizedBox(height: 8),
          const Divider(thickness: 1.5),
          const SizedBox(height: 8),
          
          // Grand Total
          _buildSimplePriceRow(
            'Total Amount',
            '₹${_grandTotal.toStringAsFixed(2)}',
            isBold: true,
            fontSize: 20,
            color: Colors.green,
          ),
        ],
      ),
      
      // Savings note
      if (_totalSavings > 0)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.discount, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You saved ₹${_totalSavings.toStringAsFixed(2)} on this order!',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      
      // Member note
      if (_hasMembership && _memberItemsCount > 0)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Member price applied to ${_memberItemsCount} items',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      
      // Offer note
      if (_offerItemsCount > 0)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Offer price applied to ${_offerItemsCount} items',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

Widget _buildSimplePriceRow(String label, String value, {
  Color? color,
  bool isBold = false,
  double fontSize = 14,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: color ?? Colors.black,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            color: color ?? Colors.black,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildPriceBreakdown(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: const Color.fromARGB(255, 116, 190, 119),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HarithOrdersPage(),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long),
            tooltip: 'My Orders',
          ),
          
          if (_cartItems.isNotEmpty)
            IconButton(
              onPressed: () {
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
                          _calculateTotals();
                          widget.onCartUpdate([]);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cart cleared'),
                              backgroundColor: Colors.orange,
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
              },
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear Cart',
            ),
        ],
      ),
      body: Column(
        children: [
          // User info banner
          if (_userData != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.green[50],
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color.fromARGB(255, 116, 190, 119),
                    child: Text(
                      _userData?['fullName']?[0] ?? 'U',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userData?['fullName'] ?? 'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_wardNo.isNotEmpty)
                          Text(
                            'Ward No: $_wardNo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_hasMembership)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'MEMBER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          // Cart items or empty state
          Expanded(
            child: _cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add items from Harith Gramam Store',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 116, 190, 119),
                          ),
                          child: const Text('Continue Shopping'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Cart Items
                        Column(
                          children: List.generate(
                            _cartItems.length,
                            (index) => _buildCartItem(index),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Price Breakdown
                        _buildOrderSummary(),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
          
          // Checkout button
          if (_cartItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${_grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '${_cartItems.length} items',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_totalSavings > 0)
                          Text(
                            'You save: ₹${_totalSavings.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _isPlacingOrder ? null : _showOrderConfirmation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 116, 190, 119),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isPlacingOrder
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'PLACE ORDER',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}