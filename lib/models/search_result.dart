// lib/models/search_result.dart
class SearchResult {
  final String id;
  final String type; // 'product', 'category'
  final String name;
  final String? imageUrl;
  final String? category;
  final double? price;
  final double? offerPrice;
  
  SearchResult({
    required this.id,
    required this.type,
    required this.name,
    this.imageUrl,
    this.category,
    this.price,
    this.offerPrice,
  });
}