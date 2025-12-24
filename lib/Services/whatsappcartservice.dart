// lib/services/whatsapp_cart_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WhatsAppCartService {
  static final WhatsAppCartService _instance = WhatsAppCartService._internal();
  factory WhatsAppCartService() => _instance;
  WhatsAppCartService._internal();

  static const String _cartKey = 'harith_whatsapp_cart';
  
  List<Map<String, dynamic>> _cartItems = [];
  List<Function(List<Map<String, dynamic>>)> _listeners = [];

  // Initialize from shared preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);
    
    if (cartJson != null && cartJson.isNotEmpty) {
      final cartData = (jsonDecode(cartJson) as List).cast<Map<String, dynamic>>();
      _cartItems = cartData;
    }
  }

  // Get all cart items
  List<Map<String, dynamic>> get cartItems => List.from(_cartItems);

  // Get total items count
  int get totalItems {
    int count = 0;
    for (var item in _cartItems) {
      count += item['quantity'] as int;
    }
    return count;
  }

  // Get total amount
  double get totalAmount {
    double amount = 0.0;
    for (var item in _cartItems) {
      final price = item['offerPrice'] ?? item['price'] ?? 0.0;
      final quantity = item['quantity'] as int;
      amount += (price * quantity);
    }
    return amount;
  }

  // Add item to cart
  Future<void> addToCart(Map<String, dynamic> product) async {
    final String productId = product['id'];
    final int existingIndex = 
        _cartItems.indexWhere((item) => item['id'] == productId);

    if (existingIndex != -1) {
      // Update quantity
      _cartItems[existingIndex]['quantity'] = 
          (_cartItems[existingIndex]['quantity'] as int) + 1;
    } else {
      // Add new item
      _cartItems.add({
        'id': productId,
        'name': product['name'],
        'price': _parseToDouble(product['discountedprice'] ?? 0.0),
        'offerPrice': product['offerprice'] != null 
            ? _parseToDouble(product['offerprice'])
            : null,
        'image': product['image_url'] ?? '',
        'quantity': 1,
        'category': product['category'] ?? 'All Products',
        'addedAt': DateTime.now().toIso8601String(),
      });
    }

    await _saveCart();
    _notifyListeners();
  }

  // Remove item from cart
  Future<void> removeFromCart(String productId) async {
    _cartItems.removeWhere((item) => item['id'] == productId);
    await _saveCart();
    _notifyListeners();
  }

  // Update quantity
  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(productId);
      return;
    }

    final cartIndex = _cartItems.indexWhere((item) => item['id'] == productId);
    if (cartIndex != -1) {
      _cartItems[cartIndex]['quantity'] = quantity;
      await _saveCart();
      _notifyListeners();
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    _cartItems.clear();
    await _saveCart();
    _notifyListeners();
  }

  // Check if product is in cart
  bool isInCart(String productId) {
    return _cartItems.any((item) => item['id'] == productId);
  }

  // Get quantity for product
  int getQuantity(String productId) {
    final cartItem = _cartItems.firstWhere(
      (item) => item['id'] == productId,
      orElse: () => {},
    );
    return cartItem.isNotEmpty ? (cartItem['quantity'] as int) : 0;
  }

  // Subscribe to cart changes
  void addListener(Function(List<Map<String, dynamic>>) listener) {
    _listeners.add(listener);
  }

  // Remove listener
  void removeListener(Function(List<Map<String, dynamic>>) listener) {
    _listeners.remove(listener);
  }

  // Private methods
  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = jsonEncode(_cartItems);
    await prefs.setString(_cartKey, cartJson);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener(List.from(_cartItems));
    }
  }
}