// lib/Screens/harith_orders.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
  String _selectedFilter = 'all';
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    print('=== INIT HARITH ORDERS PAGE ===');
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      print('\n=== LOADING USER ORDERS ===');
      final user = _auth.currentUser;
      if (user == null) {
        print('User is not authenticated');
        setState(() => _isLoading = false);
        return;
      }

      print('User ID: ${user.uid}');
      
      setState(() => _isLoading = true);

      // Query for user's orders
      final querySnapshot = await _firestore
          .collection('harith-orders')
          .where('userId', isEqualTo: user.uid)
          .get(); // Removed orderBy to avoid index issues

      print('Query executed successfully');
      print('Found ${querySnapshot.docs.length} documents');

      final List<Map<String, dynamic>> loadedOrders = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final orderId = data['orderId'] ?? doc.id;
        final status = data['orderStatus']?.toString() ?? 'pending';
        
        print('Order: $orderId, Status: $status');

        Map<String, dynamic> orderData = {
          'id': doc.id,
          ...data,
        };

        // Handle timestamps
        if (data['createdAt'] is Timestamp) {
          orderData['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        if (data['updatedAt'] is Timestamp) {
          orderData['updatedAt'] = (data['updatedAt'] as Timestamp).toDate();
        }

        loadedOrders.add(orderData);
      }

      // Sort manually by createdAt (newest first)
      loadedOrders.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate is DateTime && bDate is DateTime) {
          return bDate.compareTo(aDate);
        }
        return 0;
      });

      print('Total orders loaded: ${loadedOrders.length}');

      setState(() {
        _orders = loadedOrders;
        _isLoading = false;
        _expandedIndex = -1;
      });

      print('=== LOADING COMPLETE ===\n');

    } catch (e) {
      print('ERROR loading orders: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${e.toString()}');
      
      setState(() => _isLoading = false);
      
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
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'processing': return Colors.purple;
      case 'out_for_delivery': return Colors.deepOrange;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'processing': return 'Processing';
      case 'out_for_delivery': return 'Out for Delivery';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return 'Unknown';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_empty;
      case 'confirmed': return Icons.check_circle_outline;
      case 'processing': return Icons.autorenew;
      case 'out_for_delivery': return Icons.local_shipping;
      case 'delivered': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      default: return Icons.help_outline;
    }
  }

  Widget _buildOrderCard(int index, Map<String, dynamic> order) {
    final orderId = order['orderId']?.toString() ?? order['id'] ?? '';
    final status = order['orderStatus']?.toString() ?? 'pending';
    final total = (order['grandTotal'] ?? 0).toDouble();
    final savings = (order['totalSavings'] ?? 0).toDouble();
    final items = order['items'] is List ? order['items'] as List<dynamic> : [];
    final deliveryAddress = order['deliveryAddress']?.toString() ?? '';
    final wardNo = order['wardNo']?.toString() ?? '';
    final paymentMethod = order['paymentMethod']?.toString() ?? 'Cash';
    final paymentStatus = order['paymentStatus']?.toString() ?? 'pending';
    
    DateTime? createdAt;
    if (order['createdAt'] is Timestamp) {
      createdAt = (order['createdAt'] as Timestamp).toDate();
    } else if (order['createdAt'] is DateTime) {
      createdAt = order['createdAt'];
    }

    final isExpanded = _expandedIndex == index;
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedIndex = isExpanded ? -1 : index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
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
                        '${items.length} ${items.length == 1 ? 'item' : 'items'}',
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
                      color: Color.fromARGB(255, 116, 190, 119),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Expand indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                    size: 20,
                  ),
                ],
              ),

              // Expanded details
              if (isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // Payment info
                Row(
                  children: [
                    const Icon(Icons.payment, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment: $paymentMethod',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: paymentStatus == 'paid' 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: paymentStatus == 'paid' 
                              ? Colors.green 
                              : Colors.orange,
                        ),
                      ),
                      child: Text(
                        paymentStatus == 'paid' ? 'Paid' : 'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          color: paymentStatus == 'paid' 
                              ? Colors.green 
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Delivery info
                if (deliveryAddress.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Delivery Address',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deliveryAddress,
                              style: const TextStyle(fontSize: 13),
                            ),
                            if (wardNo.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Ward No: $wardNo',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                // Order items
                const Text(
                  'Order Items:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                ..._buildOrderItems(items),

                const SizedBox(height: 16),

                // Cancel button for pending orders
                if (status == 'pending' || status == 'confirmed')
                  SizedBox(
                    width: double.infinity,
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
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOrderItems(List<dynamic> items) {
    if (items.isEmpty) {
      return [
        const Text(
          'No items in this order',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        )
      ];
    }

    return items.map<Widget>((item) {
      final itemMap = item is Map<String, dynamic> 
          ? item 
          : (item is Map ? Map<String, dynamic>.from(item) : {});
      
      final name = itemMap['name']?.toString() ?? 'Unknown Product';
      final quantity = (itemMap['quantity'] is num ? itemMap['quantity'].toInt() : 0);
      final price = (itemMap['unitPrice'] ?? itemMap['price'] ?? 0).toDouble();
      final itemTotal = price * quantity;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Product icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: Icon(
                  Icons.shopping_bag,
                  size: 20,
                  color: Colors.grey,
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Qty: $quantity × ₹${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Item total
            Text(
              '₹${itemTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 116, 190, 119),
              ),
            ),
          ],
        ),
      );
    }).toList();
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

        _loadOrders();
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

  @override
  Widget build(BuildContext context) {
    print('=== BUILDING UI ===');
    print('Is loading: $_isLoading');
    print('Total orders: ${_orders.length}');
    print('Filtered orders: ${_filteredOrders.length}');

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
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color.fromARGB(255, 116, 190, 119),
                  ),
                  SizedBox(height: 16),
                  Text('Loading your orders...'),
                ],
              ),
            )
          : Column(
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

                // Orders list
                Expanded(
                  child: _filteredOrders.isEmpty
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
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _loadOrders,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 116, 190, 119),
                                ),
                                child: const Text('Refresh'),
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
                            itemBuilder: (context, index) {
                              return _buildOrderCard(index, _filteredOrders[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _selectedFilter == value;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? value : 'all';
            _expandedIndex = -1;
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
}