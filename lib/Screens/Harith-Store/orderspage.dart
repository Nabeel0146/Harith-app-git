// lib/Screens/harith_orders.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HarithOrdersPage extends StatefulWidget {
  const HarithOrdersPage({super.key});

  @override
  State<HarithOrdersPage> createState() => _HarithOrdersPageState();
}

class _HarithOrdersPageState extends State<HarithOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, pending, confirmed, delivered, cancelled
  int _selectedOrderIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      setState(() {
        _isLoading = true;
      });

      final querySnapshot = await _firestore
          .collection('harith-orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> loadedOrders = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        loadedOrders.add({
          'id': doc.id,
          ...data,
          'createdAt': data['createdAt']?.toDate(),
        });
      }

      setState(() {
        _orders = loadedOrders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load orders: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'all') return _orders;
    return _orders.where((order) {
      final status = order['orderStatus']?.toString();
      return status == _selectedFilter;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'out_for_delivery':
        return Colors.deepOrange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Processing';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.autorenew;
      case 'out_for_delivery':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildOrderCard(int index) {
    final order = _filteredOrders[index];
    final String orderId = order['orderId']?.toString() ?? order['id'] ?? '';
    final String status = order['orderStatus']?.toString() ?? 'pending';
    final dynamic totalValue = order['grandTotal'];
    final double total = (totalValue is num) ? totalValue.toDouble() : 0.0;
    
    final dynamic createdAtValue = order['createdAt'];
    final DateTime? createdAt = (createdAtValue is Timestamp) 
        ? createdAtValue.toDate()
        : (createdAtValue is DateTime)
            ? createdAtValue
            : null;
    
    final dynamic itemsValue = order['items'];
    final int itemCount = (itemsValue is List) ? itemsValue.length : 0;
    
    final dynamic savingsValue = order['totalSavings'];
    final double savings = (savingsValue is num) ? savingsValue.toDouble() : 0.0;
    
    final Color statusColor = _getStatusColor(status);
    final String statusText = _getStatusText(status);
    final IconData statusIcon = _getStatusIcon(status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedOrderIndex = _selectedOrderIndex == index ? -1 : index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (createdAt != null)
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Order summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (savings > 0)
                        Text(
                          'Saved: ₹${savings.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                  
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              
              // Expanded order details
              if (_selectedOrderIndex == index) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // Payment method
                Row(
                  children: [
                    const Icon(Icons.payment, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Payment: ${order['paymentMethod']?.toString() ?? 'Cash on Delivery'}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: order['paymentStatus'] == 'paid' ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: order['paymentStatus'] == 'paid' ? Colors.green : Colors.orange,
                        ),
                      ),
                      child: Text(
                        order['paymentStatus'] == 'paid' ? 'Paid' : 'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          color: order['paymentStatus'] == 'paid' ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Delivery address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delivery Address:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order['deliveryAddress']?.toString() ?? 'Not specified',
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (order['wardNo']?.toString().isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Ward No: ${order['wardNo']}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Order items preview
                const Text(
                  'Items in this order:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                
                ..._buildOrderItemsPreview(order['items']),
                
                const SizedBox(height: 16),
                
                // Price breakdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price Breakdown:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    
                    // Member price
                    if (((order['memberPriceTotal'] as num?)?.toDouble() ?? 0.0) > 0)
                      _buildPriceRow(
                        'Member Price', 
                        (order['memberPriceTotal'] as num?)?.toDouble() ?? 0.0, 
                        Colors.orange
                      ),
                    
                    // Offer price
                    if (((order['offerPriceTotal'] as num?)?.toDouble() ?? 0.0) > 0)
                      _buildPriceRow(
                        'Offer Price', 
                        (order['offerPriceTotal'] as num?)?.toDouble() ?? 0.0, 
                        Colors.blue
                      ),
                    
                    // Regular price
                    if (((order['regularPriceTotal'] as num?)?.toDouble() ?? 0.0) > 0)
                      _buildPriceRow(
                        'Regular Price', 
                        (order['regularPriceTotal'] as num?)?.toDouble() ?? 0.0, 
                        Colors.green
                      ),
                    
                    const SizedBox(height: 8),
                    
                    _buildPriceRow(
                      'Subtotal', 
                      (order['subTotal'] as num?)?.toDouble() ?? 0.0, 
                      null
                    ),
                    
                    _buildPriceRow(
                      'Delivery', 
                      0.0, 
                      Colors.green, 
                      isFree: true
                    ),
                    
                    const Divider(),
                    
                    _buildPriceRow(
                      'Total Amount', 
                      total, 
                      Colors.green, 
                      isBold: true
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Actions
                if (status == 'pending' || status == 'confirmed')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelOrder(order['id']?.toString() ?? ''),
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Cancel Order'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _contactSupport(orderId),
                          icon: const Icon(Icons.support_agent, size: 16),
                          label: const Text('Support'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 116, 190, 119),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, Color? color, 
      {bool isBold = false, bool isFree = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            isFree ? 'FREE' : '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              color: color ?? (isFree ? Colors.green : Colors.black),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrderItemsPreview(dynamic items) {
    if (items == null || !(items is List) || items.isEmpty) {
      return [const Text('No items found', style: TextStyle(fontSize: 13))];
    }
    
    final List<dynamic> itemsList = items;
    final previewItems = itemsList.take(3).toList();
    final bool hasMore = itemsList.length > 3;
    
    return [
      ...previewItems.map((item) {
        final Map<String, dynamic> itemData = {};
        
        if (item is Map<String, dynamic>) {
          itemData.addAll(item);
        } else if (item is Map) {
          itemData.addAll(Map<String, dynamic>.from(item));
        }
        
        final String name = itemData['name']?.toString() ?? 'Unknown';
        final dynamic quantityValue = itemData['quantity'];
        final int quantity = (quantityValue is num) ? quantityValue.toInt() : 0;
        
        final dynamic priceValue = itemData['unitPrice'];
        final double price = (priceValue is num) ? priceValue.toDouble() : 0.0;
        
        final String? imageUrl = itemData['image']?.toString();
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Product image
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: Colors.green[400],
                              strokeWidth: 1,
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Icon(
                              Icons.shopping_bag,
                              size: 20,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.shopping_bag,
                          size: 20,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
              
              const SizedBox(width: 12),
              
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$quantity × ₹${price.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              
              // Item total
              Text(
                '₹${(price * quantity).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
      
      if (hasMore)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '+ ${itemsList.length - 3} more items',
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
          ),
        ),
    ];
  }

  Future<void> _cancelOrder(String orderId) async {
    if (orderId.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('harith-orders').doc(orderId).update({
          'orderStatus': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _loadOrders(); // Refresh the list
      } catch (e) {
        print('Error cancelling order: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _contactSupport(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('For any queries regarding your order, please contact:'),
            const SizedBox(height: 16),
            const Text(
              '📞 Customer Support:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('+91 1234567890'),
            const SizedBox(height: 8),
            const Text(
              '📧 Email:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('support@harithgramam.com'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Order ID: $orderId',
                style: const TextStyle(fontFamily: 'Monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening phone dialer...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 116, 190, 119),
            ),
            child: const Text('Call Support'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: const Color.fromARGB(255, 116, 190, 119),
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.grey[50],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  _buildFilterChip('Pending', 'pending'),
                  _buildFilterChip('Confirmed', 'confirmed'),
                  _buildFilterChip('Processing', 'processing'),
                  _buildFilterChip('Out for Delivery', 'out_for_delivery'),
                  _buildFilterChip('Delivered', 'delivered'),
                  _buildFilterChip('Cancelled', 'cancelled'),
                ],
              ),
            ),
          ),
          
          // Orders list or empty state
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 116, 190, 119),
                    ),
                  )
                : _filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.receipt_long_outlined,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No orders found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFilter == 'all'
                                  ? 'You haven\'t placed any orders yet'
                                  : 'No ${_selectedFilter} orders',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 24),
                            if (_selectedFilter != 'all')
                              ElevatedButton(
                                onPressed: () => setState(() {
                                  _selectedFilter = 'all';
                                }),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 116, 190, 119),
                                ),
                                child: const Text('View All Orders'),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        color: const Color.fromARGB(255, 116, 190, 119),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) => _buildOrderCard(index),
                        ),
                      ),
          ),
        ],
      ),
      
      // Stats bar
      bottomNavigationBar: _orders.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Total Orders',
                    _orders.length.toString(),
                    Icons.shopping_bag,
                  ),
                  _buildStatItem(
                    'Total Spent',
                    '₹${_orders.fold<double>(0, (sum, order) {
                      final value = order['grandTotal'];
                      return sum + ((value is num) ? value.toDouble() : 0.0);
                    }).toStringAsFixed(2)}',
                    Icons.currency_rupee,
                    color: Colors.green,
                  ),
                  _buildStatItem(
                    'Total Savings',
                    '₹${_orders.fold<double>(0, (sum, order) {
                      final value = order['totalSavings'];
                      return sum + ((value is num) ? value.toDouble() : 0.0);
                    }).toStringAsFixed(2)}',
                    Icons.savings,
                    color: Colors.green,
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final bool isSelected = _selectedFilter == value;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? value : 'all';
            _selectedOrderIndex = -1; // Collapse all expanded items
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color.fromARGB(255, 116, 190, 119),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color.fromARGB(255, 116, 190, 119) : Colors.grey[300]!,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[700]),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}