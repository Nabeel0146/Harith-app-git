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
  double _totalOriginalValue = 0.0;
  
  // Item counts
  int _memberItemsCount = 0;
  int _offerItemsCount = 0;
  int _regularItemsCount = 0;

  // Track items by price tier for better display
  List<Map<String, dynamic>> _memberPriceItems = [];
  List<Map<String, dynamic>> _offerPriceItems = [];
  List<Map<String, dynamic>> _regularPriceItems = [];
  
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

  void _categorizeItems() {
    _memberPriceItems.clear();
    _offerPriceItems.clear();
    _regularPriceItems.clear();
    
    for (var item in _cartItems) {
      final double discountedPrice = item['price'] ?? 0.0;
      final double? offerPrice = item['offerPrice'];
      final double? lastPrice = item['lastPrice'];
      final double lastPriceQuantity = item['lastPriceQuantity'] ?? 0.0;
      final double remainingLastPriceQuantity = item['remainingLastPriceQuantity'] ?? 0.0;
      final bool isEligibleForLastPrice = item['isEligibleForLastPrice'] ?? false;
      final int quantity = item['quantity'] is int ? item['quantity'] as int : 0;
      
      // Create item copy with additional info
      final itemWithInfo = Map<String, dynamic>.from(item);
      
      if (_hasMembership && 
          lastPrice != null && 
          lastPrice > 0 && 
          isEligibleForLastPrice) {
        // Member price applies
        itemWithInfo['appliedPrice'] = lastPrice;
        itemWithInfo['priceType'] = 'member';
        itemWithInfo['priceTypeLabel'] = 'Member Price';
        itemWithInfo['priceColor'] = Colors.orange;
        itemWithInfo['remainingAtMemberPrice'] = remainingLastPriceQuantity.floor();
        itemWithInfo['atMemberPriceCount'] = quantity.clamp(0, remainingLastPriceQuantity.floor());
        itemWithInfo['atOtherPriceCount'] = quantity - itemWithInfo['atMemberPriceCount'];
        _memberPriceItems.add(itemWithInfo);
      } else if (offerPrice != null && offerPrice > 0) {
        // Offer price applies
        itemWithInfo['appliedPrice'] = offerPrice;
        itemWithInfo['priceType'] = 'offer';
        itemWithInfo['priceTypeLabel'] = 'Offer Price';
        itemWithInfo['priceColor'] = Colors.blue;
        _offerPriceItems.add(itemWithInfo);
      } else {
        // Regular price applies
        itemWithInfo['appliedPrice'] = discountedPrice;
        itemWithInfo['priceType'] = 'regular';
        itemWithInfo['priceTypeLabel'] = 'Regular Price';
        itemWithInfo['priceColor'] = Colors.green;
        _regularPriceItems.add(itemWithInfo);
      }
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
    
    _categorizeItems();
    
    // Calculate for member price items
    for (var item in _memberPriceItems) {
      final double discountedPrice = item['price'] ?? 0.0;
      final double appliedPrice = item['appliedPrice'] ?? 0.0;
      final int quantity = item['quantity'] is int ? item['quantity'] as int : 0;
      final int atMemberPriceCount = item['atMemberPriceCount'] ?? quantity;
      final int atOtherPriceCount = item['atOtherPriceCount'] ?? 0;
      final double? offerPrice = item['offerPrice'];
      
      // Calculate member price portion
      final double memberPricePortion = (appliedPrice * atMemberPriceCount);
      _memberTotal += memberPricePortion;
      _memberItemsCount += atMemberPriceCount;
      _totalSavings += (discountedPrice - appliedPrice) * atMemberPriceCount;
      
      // Calculate other price portion (offer price if available, else regular)
      if (atOtherPriceCount > 0) {
        if (offerPrice != null && offerPrice > 0) {
          final double offerPricePortion = (offerPrice * atOtherPriceCount);
          _offerTotal += offerPricePortion;
          _offerItemsCount += atOtherPriceCount;
          _totalSavings += (discountedPrice - offerPrice) * atOtherPriceCount;
        } else {
          final double regularPricePortion = (discountedPrice * atOtherPriceCount);
          _regularTotal += regularPricePortion;
          _regularItemsCount += atOtherPriceCount;
        }
      }
      
      _subTotal += memberPricePortion + 
          (atOtherPriceCount > 0 ? (offerPrice != null && offerPrice > 0 
              ? (offerPrice * atOtherPriceCount) 
              : (discountedPrice * atOtherPriceCount)) : 0);
      _totalOriginalValue += (discountedPrice * quantity);
    }
    
    // Calculate for offer price items
    for (var item in _offerPriceItems) {
      final double discountedPrice = item['price'] ?? 0.0;
      final double appliedPrice = item['appliedPrice'] ?? 0.0;
      final int quantity = item['quantity'] is int ? item['quantity'] as int : 0;
      
      _offerTotal += (appliedPrice * quantity);
      _offerItemsCount += quantity;
      _totalSavings += (discountedPrice - appliedPrice) * quantity;
      _subTotal += (appliedPrice * quantity);
      _totalOriginalValue += (discountedPrice * quantity);
    }
    
    // Calculate for regular price items
    for (var item in _regularPriceItems) {
      final double discountedPrice = item['price'] ?? 0.0;
      final int quantity = item['quantity'] is int ? item['quantity'] as int : 0;
      
      _regularTotal += (discountedPrice * quantity);
      _regularItemsCount += quantity;
      _subTotal += (discountedPrice * quantity);
      _totalOriginalValue += (discountedPrice * quantity);
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

  Widget _buildCartItemHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            color == Colors.orange ? Icons.card_membership :
            color == Colors.blue ? Icons.local_offer :
            Icons.price_check,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final String name = item['name']?.toString() ?? 'Unknown';
    final String? imageUrl = item['image']?.toString();
    final int quantity = item['quantity'] is int ? item['quantity'] as int : 0;
    final double discountedPrice = item['price'] ?? 0.0;
    final double? offerPrice = item['offerPrice'];
    final double? lastPrice = item['lastPrice'];
    final double lastPriceQuantity = item['lastPriceQuantity'] ?? 0.0;
    final double remainingLastPriceQuantity = item['remainingLastPriceQuantity'] ?? 0.0;
    final double appliedPrice = item['appliedPrice'] ?? discountedPrice;
    final String priceType = item['priceType'] ?? 'regular';
    final String priceTypeLabel = item['priceTypeLabel'] ?? 'Regular Price';
    final Color priceColor = item['priceColor'] ?? Colors.green;
    final int remainingAtMemberPrice = item['remainingAtMemberPrice'] ?? 0;
    final int atMemberPriceCount = item['atMemberPriceCount'] ?? 0;
    final int atOtherPriceCount = item['atOtherPriceCount'] ?? 0;
    
    final double itemTotal = appliedPrice * quantity;
    final double originalItemTotal = discountedPrice * quantity;
    final double savings = originalItemTotal - itemTotal;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      
                      // Price Breakdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Regular Price (discountedprice)
                          _buildPriceComparisonRow(
                            label: 'Standard Price:',
                            price: discountedPrice,
                            isCrossedOut: priceType != 'regular' || (priceType == 'member' && atOtherPriceCount > 0),
                            quantity: priceType == 'member' && atOtherPriceCount > 0 ? atOtherPriceCount : null,
                          ),
                          
                          // Offer Price (offerprice)
                          if (offerPrice != null && offerPrice > 0)
                            _buildPriceComparisonRow(
                              label: 'Offer Price:',
                              price: offerPrice,
                              isApplied: priceType == 'offer' || (priceType == 'member' && atOtherPriceCount > 0),
                              isCrossedOut: priceType == 'member' && atMemberPriceCount > 0,
                              quantity: priceType == 'member' && atOtherPriceCount > 0 ? atOtherPriceCount : null,
                            ),
                          
                          // Member Price (lastprice)
                          if (lastPrice != null && lastPrice > 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPriceComparisonRow(
                                  label: _hasMembership ? 'Your Member Price:' : 'Member Price:',
                                  price: lastPrice,
                                  isApplied: priceType == 'member',
                                  quantity: atMemberPriceCount > 0 ? atMemberPriceCount : null,
                                  isMemberPrice: true,
                                ),
                                
                                // Member price quota info
                                if (_hasMembership && priceType == 'member')
                                  Container(
                                    margin: const EdgeInsets.only(top: 4, left: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.orange[200]!),
                                    ),
                                    child: Text(
                                      atMemberPriceCount > 0
                                          ? '$atMemberPriceCount at member price, ${atOtherPriceCount > 0 ? '$atOtherPriceCount at ${offerPrice != null && offerPrice > 0 ? 'offer' : 'regular'} price' : ''}'
                                          : 'Member quota used',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          
                          // If no lastprice available
                          if (lastPrice == null || lastPrice <= 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Member price not available',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              priceType == 'member' ? Icons.card_membership :
                              priceType == 'offer' ? Icons.local_offer :
                              Icons.price_check,
                              size: 14,
                              color: priceColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Applied: $priceTypeLabel',
                              style: TextStyle(
                                fontSize: 12,
                                color: priceColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Savings if any
                      if (savings > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.savings, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'You save: ₹${savings.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
                              onTap: () => _updateQuantity(_cartItems.indexWhere((i) => i['id'] == item['id']), quantity - 1),
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
                            
                            Column(
                              children: [
                                Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (priceType == 'member' && remainingAtMemberPrice > 0)
                                  Text(
                                    '${remainingAtMemberPrice - atMemberPriceCount} more at member price',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                    ),
                                  ),
                              ],
                            ),
                            
                            InkWell(
                              onTap: () => _updateQuantity(_cartItems.indexWhere((i) => i['id'] == item['id']), quantity + 1),
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
                  onPressed: () => _removeItem(_cartItems.indexWhere((i) => i['id'] == item['id'])),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            
            // Item Total
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Item Total:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${itemTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
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
                    ],
                  ),
                  
                  // Detailed breakdown for mixed pricing
                  if (priceType == 'member' && atMemberPriceCount > 0 && atOtherPriceCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Price Breakdown:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '• $atMemberPriceCount at member price:',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                              Text(
                                '₹${(lastPrice! * atMemberPriceCount).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '• $atOtherPriceCount at ${offerPrice != null && offerPrice > 0 ? 'offer' : 'regular'} price:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: offerPrice != null && offerPrice > 0 ? Colors.blue : Colors.green,
                                ),
                              ),
                              Text(
                                '₹${((offerPrice != null && offerPrice > 0 ? offerPrice : discountedPrice) * atOtherPriceCount).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: offerPrice != null && offerPrice > 0 ? Colors.blue : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildPriceComparisonRow({
    required String label,
    required double price,
    bool isApplied = false,
    bool isCrossedOut = false,
    bool isMemberPrice = false,
    int? quantity,
  }) {
    final Color color = isMemberPrice
        ? Colors.orange
        : isApplied
            ? (isMemberPrice ? Colors.orange : Colors.blue)
            : Colors.grey[600]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMemberPrice ? Icons.card_membership :
            isApplied ? Icons.check_circle :
            Icons.circle_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: isApplied ? FontWeight.bold : FontWeight.normal,
                decoration: isCrossedOut ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            '₹${price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: isApplied ? FontWeight.bold : FontWeight.normal,
              decoration: isCrossedOut ? TextDecoration.lineThrough : null,
            ),
          ),
          if (quantity != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                '×$quantity',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
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
      
      final List<Map<String, dynamic>> orderItems = [];
      
      // Process member price items with mixed pricing
      for (var item in _memberPriceItems) {
        final int atMemberPriceCount = item['atMemberPriceCount'] ?? 0;
        final int atOtherPriceCount = item['atOtherPriceCount'] ?? 0;
        
        if (atMemberPriceCount > 0) {
          orderItems.add({
            'productId': item['id'],
            'name': item['name'],
            'image': item['image'],
            'quantity': atMemberPriceCount,
            'discountedPrice': item['price'],
            'offerPrice': item['offerPrice'],
            'lastPrice': item['lastPrice'],
            'isEligibleForLastPrice': true,
            'unitPrice': item['lastPrice'],
            'priceType': 'member',
            'itemTotal': (item['lastPrice'] ?? 0.0) * atMemberPriceCount,
            'originalValue': (item['price'] ?? 0.0) * atMemberPriceCount,
          });
        }
        
        if (atOtherPriceCount > 0) {
          final priceType = item['offerPrice'] != null && item['offerPrice']! > 0 ? 'offer' : 'regular';
          final unitPrice = priceType == 'offer' ? item['offerPrice'] : item['price'];
          
          orderItems.add({
            'productId': item['id'],
            'name': item['name'],
            'image': item['image'],
            'quantity': atOtherPriceCount,
            'discountedPrice': item['price'],
            'offerPrice': item['offerPrice'],
            'lastPrice': item['lastPrice'],
            'isEligibleForLastPrice': false,
            'unitPrice': unitPrice,
            'priceType': priceType,
            'itemTotal': unitPrice * atOtherPriceCount,
            'originalValue': (item['price'] ?? 0.0) * atOtherPriceCount,
          });
        }
      }
      
      // Process offer and regular price items
      for (var item in _offerPriceItems) {
        orderItems.add({
          'productId': item['id'],
          'name': item['name'],
          'image': item['image'],
          'quantity': item['quantity'],
          'discountedPrice': item['price'],
          'offerPrice': item['offerPrice'],
          'lastPrice': item['lastPrice'],
          'isEligibleForLastPrice': false,
          'unitPrice': item['offerPrice'],
          'priceType': 'offer',
          'itemTotal': (item['offerPrice'] ?? 0.0) * item['quantity'],
          'originalValue': (item['price'] ?? 0.0) * item['quantity'],
        });
      }
      
      for (var item in _regularPriceItems) {
        orderItems.add({
          'productId': item['id'],
          'name': item['name'],
          'image': item['image'],
          'quantity': item['quantity'],
          'discountedPrice': item['price'],
          'offerPrice': item['offerPrice'],
          'lastPrice': item['lastPrice'],
          'isEligibleForLastPrice': false,
          'unitPrice': item['price'],
          'priceType': 'regular',
          'itemTotal': (item['price'] ?? 0.0) * item['quantity'],
          'originalValue': (item['price'] ?? 0.0) * item['quantity'],
        });
      }

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
        'originalTotalValue': _totalOriginalValue,
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
      
      // Price breakdown by type
      if (_memberItemsCount > 0)
        _buildPriceTypeRow(
          label: 'Member Price Items',
          count: _memberItemsCount,
          total: _memberTotal,
          color: Colors.orange,
          icon: Icons.card_membership,
        ),
      
      if (_offerItemsCount > 0)
        _buildPriceTypeRow(
          label: 'Offer Price Items',
          count: _offerItemsCount,
          total: _offerTotal,
          color: Colors.blue,
          icon: Icons.local_offer,
        ),
      
      if (_regularItemsCount > 0)
        _buildPriceTypeRow(
          label: 'Regular Price Items',
          count: _regularItemsCount,
          total: _regularTotal,
          color: Colors.green,
          icon: Icons.price_check,
        ),
      
      const SizedBox(height: 12),
      const Divider(),
      const SizedBox(height: 8),
      
      // Totals
      Column(
        children: [
          _buildSimplePriceRow(
            label: 'Total Items',
            value: '${_memberItemsCount + _offerItemsCount + _regularItemsCount} items',
            fontSize: 14,
          ),
          
          const SizedBox(height: 4),
          
          _buildSimplePriceRow(
            label: 'Subtotal',
            value: '₹${_subTotal.toStringAsFixed(2)}',
            fontSize: 14,
          ),
          
          if (_totalSavings > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _buildSimplePriceRow(
                label: 'Total Savings',
                value: '₹${_totalSavings.toStringAsFixed(2)}',
                color: Colors.green,
                fontSize: 14,
              ),
            ),
          
          const SizedBox(height: 8),
          const Divider(thickness: 1.5),
          const SizedBox(height: 8),
          
          // Grand Total
          _buildSimplePriceRow(
            label: 'Total Amount',
            value: '₹${_grandTotal.toStringAsFixed(2)}',
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
      
      // Member benefits note
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
                    'Member benefits applied to $_memberItemsCount items',
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
                    'Offer price applied to $_offerItemsCount items',
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

Widget _buildPriceTypeRow({
  required String label,
  required int count,
  required double total,
  required Color color,
  required IconData icon,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                '$count items',
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        Text(
          '₹${total.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}

Widget _buildSimplePriceRow({
  required String label,
  required String value,
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
                        // Show member price items first
                        if (_memberPriceItems.isNotEmpty) ...[
                          _buildCartItemHeader('Member Price Items', Colors.orange),
                          const SizedBox(height: 8),
                          ..._memberPriceItems.map((item) => _buildCartItem(item)),
                          const SizedBox(height: 16),
                        ],
                        
                        // Show offer price items
                        if (_offerPriceItems.isNotEmpty) ...[
                          _buildCartItemHeader('Offer Price Items', Colors.blue),
                          const SizedBox(height: 8),
                          ..._offerPriceItems.map((item) => _buildCartItem(item)),
                          const SizedBox(height: 16),
                        ],
                        
                        // Show regular price items
                        if (_regularPriceItems.isNotEmpty) ...[
                          _buildCartItemHeader('Regular Price Items', Colors.green),
                          const SizedBox(height: 8),
                          ..._regularPriceItems.map((item) => _buildCartItem(item)),
                          const SizedBox(height: 16),
                        ],
                        
                        // Price Breakdown
                        _buildPriceBreakdown(),
                        
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