// lib/Screens/search_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:harithapp/Screens/Whatsappcart/catgeoryProducts.dart';
import 'package:harithapp/Screens/harithsingleproduct.dart';
import 'package:harithapp/models/search_result.dart';


class SearchPage extends StatefulWidget {
  final String initialQuery;
  
  const SearchPage({
    super.key,
    this.initialQuery = '',
  });
  
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _currentQuery = '';
  
  // Recent searches storage
  List<String> _recentSearches = [];
  
  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    if (widget.initialQuery.isNotEmpty) {
      _searchController.text = widget.initialQuery;
      _performSearch(widget.initialQuery);
    }
  }
  
  Future<void> _loadRecentSearches() async {
    // You can store recent searches in SharedPreferences or Firebase
    // For now, we'll use a simple list
    setState(() {
      _recentSearches = [
        'Rice',
        'Oil',
        'Vegetables',
        'Snacks',
        'Beverages',
      ];
    });
  }
  
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _hasSearched = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _currentQuery = query;
      _hasSearched = true;
    });
    
    try {
      // Search in multiple collections simultaneously
      final results = await Future.wait([
        _searchProducts(query),
        _searchCategories(query),
      ]);
      
      // Combine all results
      List<SearchResult> allResults = [];
      for (var resultList in results) {
        allResults.addAll(resultList);
      }
      
      // Add to recent searches
      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches.removeLast();
        }
      }
      
      setState(() {
        _searchResults = allResults;
        _isSearching = false;
      });
      
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }
  
  Future<List<SearchResult>> _searchProducts(String query) async {
    try {
      final productsSnapshot = await _firestore
          .collection('harith-products')
          .where('display', isEqualTo: true)
          .get();
      
      final queryLower = query.toLowerCase();
      final List<SearchResult> results = [];
      
      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        final name = data['name']?.toString() ?? '';
        final category = data['category']?.toString();
        
        // Search in name and category
        if (name.toLowerCase().contains(queryLower) || 
            (category != null && category.toLowerCase().contains(queryLower))) {
          
          results.add(SearchResult(
            id: doc.id,
            type: 'product',
            name: name,
            imageUrl: data['image_url']?.toString(),
            category: category,
            price: _parseDouble(data['discountedprice']),
            offerPrice: _parseDouble(data['offerprice']),
          ));
        }
      }
      
      return results;
    } catch (e) {
      print('Product search error: $e');
      return [];
    }
  }
  
  Future<List<SearchResult>> _searchCategories(String query) async {
    try {
      final categoriesSnapshot = await _firestore
          .collection('harith_product_categories')
          .get();
      
      final queryLower = query.toLowerCase();
      final List<SearchResult> results = [];
      
      for (var doc in categoriesSnapshot.docs) {
        final data = doc.data();
        final name = data['name']?.toString() ?? '';
        
        if (name.toLowerCase().contains(queryLower)) {
          results.add(SearchResult(
            id: doc.id,
            type: 'category',
            name: name,
            imageUrl: data['image']?.toString(),
          ));
        }
      }
      
      return results;
    } catch (e) {
      print('Category search error: $e');
      return [];
    }
  }
  
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      _performSearch(query);
    }
  }
  
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _hasSearched = false;
      _currentQuery = '';
    });
  }
  
  void _navigateToResult(SearchResult result) {
    if (result.type == 'product') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SingleProductPage(
            product: {
              'id': result.id,
              'name': result.name,
              'image_url': result.imageUrl,
              'discountedprice': result.price,
              'offerprice': result.offerPrice,
              'category': result.category,
            },
          ),
        ),
      );
    } else if (result.type == 'category') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryProductsPage(
            categoryName: result.name,
          ),
        ),
      );
    }
  }
  
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search products, categories...',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onSubmitted: _onSearchSubmitted,
                      onChanged: (value) {
                        if (value.isEmpty) {
                          _clearSearch();
                        }
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: _clearSearch,
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color.fromARGB(255, 116, 190, 119),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentSearches() {
    if (_hasSearched || _recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Searches',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((search) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = search;
                  _performSearch(search);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        search,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults() {
    if (!_hasSearched) return const SizedBox.shrink();
    
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 116, 190, 119),
          ),
        ),
      );
    }
    
    if (_searchResults.isEmpty && _currentQuery.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$_currentQuery"',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildResultItem(result);
      },
    );
  }
  
  Widget _buildResultItem(SearchResult result) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: () => _navigateToResult(result),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: result.imageUrl?.isNotEmpty == true
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: result.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Center(
                      child: CircularProgressIndicator(
                        color: Colors.green[400],
                      ),
                    ),
                    errorWidget: (_, __, ___) => Center(
                      child: Icon(
                        result.type == 'product' 
                            ? Icons.shopping_bag 
                            : Icons.category,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Icon(
                    result.type == 'product' 
                        ? Icons.shopping_bag 
                        : Icons.category,
                    color: Colors.grey[400],
                  ),
                ),
        ),
        title: Text(
          result.name,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: result.type == 'product'
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.category != null)
                    Text(
                      result.category!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  if (result.price != null)
                    Row(
                      children: [
                        Text(
                          '₹${result.price!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        if (result.offerPrice != null && 
                            result.offerPrice! < result.price!)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              '₹${result.offerPrice!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              )
            : Text(
                'Category',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
      ),
    );
  }
  
  Widget _buildByCategory() {
    if (_hasSearched || _recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return FutureBuilder<QuerySnapshot>(
      future: _firestore.collection('harith_product_categories').limit(8).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final categories = snapshot.data!.docs;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Browse by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final name = category['name']?.toString() ?? 'Category';
                  final image = category['image']?.toString();
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryProductsPage(
                            categoryName: name,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: image?.isNotEmpty == true
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: image!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Center(
                                        child: Icon(
                                          Icons.category,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.category,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRecentSearches(),
                    const SizedBox(height: 24),
                    _buildByCategory(),
                    const SizedBox(height: 24),
                    _buildSearchResults(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}