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
  
  // Payment methods
  final List<String> _paymentMethods = ['Cash on Delivery'];
  String _selectedPaymentMethod = 'Cash on Delivery';
  
  // Order summary
  double _subTotal = 0.0;
  double _grandTotal = 0.0;
  double _memberTotal = 0.0;
  double _offerTotal = 0.0;
  double _regularTotal = 0.0;
  double _totalSavings = 0.0;

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
    
    for (var item in _cartItems) {
      final double originalPrice = item['price'] ?? 0.0;
      final double? offerPrice = item['offerPrice'];
      final double? lastPrice = item['lastPrice'];
      final int quantity = item['quantity'] is int ? item['quantity'] as int : 0;
      
      double finalPrice;
      double itemSavings = 0.0;
      
      // Calculate price based on membership eligibility
      if (_hasMembership && 
          lastPrice != null && 
          lastPrice > 0 && 
          item['isEligibleForLastPrice'] == true) {
        finalPrice = lastPrice;
        _memberTotal += (lastPrice * quantity);
        itemSavings = (originalPrice - lastPrice) * quantity;
      } else if (offerPrice != null && offerPrice > 0) {
        finalPrice = offerPrice;
        _offerTotal += (offerPrice * quantity);
        itemSavings = (originalPrice - offerPrice) * quantity;
      } else {
        finalPrice = originalPrice;
        _regularTotal += (originalPrice * quantity);
      }
      
      final double itemTotal = finalPrice * quantity;
      _subTotal += itemTotal;
      _totalSavings += itemSavings;
    }
    
    // Calculate grand total (no delivery charge, no tax)
    _grandTotal = _subTotal;
    
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
    final double originalPrice = item['price'] ?? 0.0;
    final double? offerPrice = item['offerPrice'];
    final double? lastPrice = item['lastPrice'];
    final bool isEligibleForLastPrice = item['isEligibleForLastPrice'] ?? false;
    
    double finalPrice;
    String priceType = 'Regular';
    Color priceColor = Colors.green;
    List<Widget> priceDetails = [];
    
    // Determine which price to use
    if (_hasMembership && lastPrice != null && lastPrice > 0 && isEligibleForLastPrice) {
      finalPrice = lastPrice;
      priceType = 'Member';
      priceColor = Colors.orange;
      
      // Show original price strikethrough
      if (originalPrice > lastPrice) {
        priceDetails.add(
          Text(
            '₹${originalPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              decoration: TextDecoration.lineThrough,
            ),
          ),
        );
      }
      
      // Show member price
      priceDetails.add(
        Text(
          '₹${lastPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            color: priceColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      
      // Show savings if any
      if (originalPrice > lastPrice) {
        final double savings = (originalPrice - lastPrice) * quantity;
        priceDetails.add(
          Text(
            'Save: ₹${savings.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.green,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }
    } else if (offerPrice != null && offerPrice > 0) {
      finalPrice = offerPrice;
      priceType = 'Offer';
      priceColor = Colors.blue;
      
      // Show original price strikethrough
      priceDetails.add(
        Text(
          '₹${originalPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            decoration: TextDecoration.lineThrough,
          ),
        ),
      );
      
      // Show offer price
      priceDetails.add(
        Text(
          '₹${offerPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            color: priceColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      
      // Show savings
      final double savings = (originalPrice - offerPrice) * quantity;
      priceDetails.add(
        Text(
          'Save: ₹${savings.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.green,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
      
      // Show member price hint if available
      if (_hasMembership && lastPrice != null && lastPrice > 0) {
        priceDetails.add(
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange, width: 1),
            ),
            child: Text(
              'Member: ₹${lastPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 9,
                color: Colors.orange,
              ),
            ),
          ),
        );
      }
    } else {
      finalPrice = originalPrice;
      priceType = 'Regular';
      priceColor = Colors.green;
      
      priceDetails.add(
        Text(
          '₹${originalPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            color: priceColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      
      // Show member price hint if available
      if (_hasMembership && lastPrice != null && lastPrice > 0) {
        priceDetails.add(
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange, width: 1),
            ),
            child: Text(
              'Member: ₹${lastPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 9,
                color: Colors.orange,
              ),
            ),
          ),
        );
      }
    }
    
    final double itemTotal = finalPrice * quantity;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Show all three prices
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Original Price
                          Row(
                            children: [
                              const Text(
                                'MRP: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '₹${originalPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  decoration: _hasMembership || (offerPrice != null && offerPrice > 0)
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                          
                          // Offer Price
                          if (offerPrice != null && offerPrice > 0)
                            Row(
                              children: [
                                const Text(
                                  'Offer: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  '₹${offerPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          
                          // Member Price
                          if (lastPrice != null && lastPrice > 0)
                            Row(
                              children: [
                                Text(
                                  '${_hasMembership ? 'Your' : 'Member'}: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _hasMembership ? Colors.orange : Colors.grey,
                                  ),
                                ),
                                Text(
                                  '₹${lastPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _hasMembership ? Colors.orange : Colors.grey,
                                    fontWeight: _hasMembership ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          
                          // Current price being applied
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: priceColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: priceColor),
                            ),
                            child: Text(
                              'Applied: $priceType Price',
                              style: TextStyle(
                                fontSize: 10,
                                color: priceColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
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
                
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Item Total: ₹${itemTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
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
        final double originalPrice = item['price'] ?? 0.0;
        final double? offerPrice = item['offerPrice'];
        final double? lastPrice = item['lastPrice'];
        final int quantity = item['quantity'] is int ? item['quantity'] as int : 0;
        
        double finalPrice;
        String priceType = 'regular';
        
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
          finalPrice = originalPrice;
          priceType = 'regular';
        }
        
        return {
          'productId': item['id'],
          'name': item['name'],
          'image': item['image'],
          'quantity': quantity,
          'originalPrice': originalPrice,
          'offerPrice': offerPrice,
          'lastPrice': lastPrice,
          'lastPriceQuantity': item['lastPriceQuantity'] ?? 0.0,
          'remainingLastPriceQuantity': item['remainingLastPriceQuantity'] ?? 0.0,
          'alreadyPurchased': item['alreadyPurchased'] ?? 0.0,
          'isEligibleForLastPrice': item['isEligibleForLastPrice'] ?? false,
          'unitPrice': finalPrice,
          'priceType': priceType,
          'itemTotal': finalPrice * quantity,
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
        'isMembershipApplied': _hasMembership,
        'items': orderItems,
        'subTotal': _subTotal,
        'deliveryCharge': 0.0, // Always 0
        'grandTotal': _grandTotal,
        'memberPriceTotal': _memberTotal,
        'offerPriceTotal': _offerTotal,
        'regularPriceTotal': _regularTotal,
        'totalSavings': _totalSavings,
        'paymentMethod': _selectedPaymentMethod,
        'paymentStatus': _selectedPaymentMethod == 'Cash on Delivery' 
            ? 'pending' 
            : 'pending_payment',
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
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Price Breakdown
              if (_memberTotal > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPriceBreakdownRow(
                      'Member Price Items',
                      _memberTotal,
                      color: Colors.orange,
                    ),
                    if (_hasMembership && _totalSavings > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8),
                        child: Text(
                          'You saved: ₹${_totalSavings.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              
              if (_offerTotal > 0)
                _buildPriceBreakdownRow(
                  'Offer Price Items',
                  _offerTotal,
                  color: Colors.blue,
                ),
              
              if (_regularTotal > 0)
                _buildPriceBreakdownRow(
                  'Regular Price Items',
                  _regularTotal,
                  color: Colors.green,
                ),
              
              const SizedBox(height: 8),
              
              // Subtotal
              _buildSummaryRow('Subtotal', '₹${_subTotal.toStringAsFixed(2)}'),
              
              // No Delivery Charge
             
              
              const Divider(),
              
              // Total Amount
              _buildSummaryRow(
                'Total Amount',
                '₹${_grandTotal.toStringAsFixed(2)}',
                isBold: true,
                color: Colors.green,
              ),
              
              const SizedBox(height: 16),
              
              // Savings Summary
             
              
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
              Text(
                _selectedPaymentMethod,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Order Note
             
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

  Widget _buildPriceBreakdownRow(String label, double amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, 
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

void _navigateToOrders() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const HarithOrdersPage(),
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
          // Orders button
          IconButton(
            onPressed: _navigateToOrders,
            icon: const Icon(Icons.receipt_long),
            tooltip: 'My Orders',
          ),
          
          // Clear cart button
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
                        Column(
                          children: List.generate(
                            _cartItems.length,
                            (index) => _buildCartItem(index),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Detailed Order Summary
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Price Breakdown',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Member Price Breakdown
                                if (_memberTotal > 0)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildPriceBreakdownRow(
                                        'Member Price Items',
                                        _memberTotal,
                                        color: Colors.orange,
                                      ),
                                      if (_hasMembership && _totalSavings > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16, bottom: 8),
                                          child: Text(
                                            'Member Savings: ₹${_totalSavings.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                
                                // Offer Price Breakdown
                                if (_offerTotal > 0)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildPriceBreakdownRow(
                                        'Offer Price Items',
                                        _offerTotal,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                
                                // Regular Price Breakdown
                                if (_regularTotal > 0)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildPriceBreakdownRow(
                                        'Regular Price Items',
                                        _regularTotal,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                
                                const Divider(),
                                
                                // Subtotal
                                _buildSummaryRow('Subtotal', '₹${_subTotal.toStringAsFixed(2)}'),
                                
                                // No Delivery Charge
                               
                                
                                
                                const Divider(),
                                
                                // Grand Total
                                _buildSummaryRow(
                                  'Total Amount',
                                  '₹${_grandTotal.toStringAsFixed(2)}',
                                  isBold: true,
                                  color: Colors.green,
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Savings Summary
                               
                                
                                const SizedBox(height: 24),
                                
                                // Payment Method
                                const Text(
                                  'Payment Method',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                
                                const SizedBox(height: 8),
                                
                                Column(
                                  children: _paymentMethods.map((method) {
                                    return RadioListTile<String>(
                                      title: Text(method),
                                      value: method,
                                      groupValue: _selectedPaymentMethod,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedPaymentMethod = value!;
                                        });
                                      },
                                      contentPadding: EdgeInsets.zero,
                                    );
                                  }).toList(),
                                ),
                                
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
                                        Text('Ward No: $_wardNo'),
                                    ],
                                  ),
                                
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
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
                        Row(
                          children: [
                            Text(
                              '${_cartItems.length} items',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            
                            
                           
                            const SizedBox(width: 4),
                            
                          ],
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