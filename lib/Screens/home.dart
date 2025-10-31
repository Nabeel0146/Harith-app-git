// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:harithapp/ONSHOP/onshopmainscreen.dart';
import 'package:harithapp/Screens/harithsingleproduct.dart';

import 'package:harithapp/widgets/productcard.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /* ---------- AppBar with Drawer ---------- */
  PreferredSizeWidget get appBar {
    return PreferredSize(
      preferredSize: const Size.fromHeight(147),
      child: AppBar(
        backgroundColor: const Color.fromARGB(255, 116, 190, 119),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        flexibleSpace: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset('assets/harithagramamlogowhite.png',
                        height: 48, errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 48,
                        width: 48,
                        color: Colors.white,
                        child: const Icon(Icons.error),
                      );
                    }),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Harithagramam App',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Your village, greener than ever',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* ---------- Sidebar Drawer ---------- */
  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 116, 190, 119),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset('assets/harithagramamlogogreen.png', 
                    height: 60,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 60,
                        width: 60,
                        color: Colors.white,
                        child: const Icon(Icons.eco, color: Colors.green),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Harithagramam',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Green Living Platform',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _drawerItem(
              icon: Icons.home,
              title: 'Home',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _drawerItem(
              icon: Icons.shopping_bag,
              title: 'Products',
              onTap: () {
                Navigator.pop(context);
                // Navigate to products page
              },
            ),
            _drawerItem(
              icon: Icons.eco,
              title: 'Homemade',
              onTap: () {
                Navigator.pop(context);
                // Navigate to homemade page
              },
            ),
            _drawerItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile page
              },
            ),
            _drawerItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings page
              },
            ),
            _drawerItem(
              icon: Icons.help,
              title: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
                // Navigate to help page
              },
            ),
            const Divider(),
            _drawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 116, 190, 119)),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  /* ---------- Banner ---------- */
  Widget _buildBanner() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('harith-homepage_banners')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Banner Error: ${snapshot.error}');
          return _buildErrorWidget('Failed to load banners');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildBannerShimmer();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildPlaceholderBanner();
        }

        final docs = snapshot.data!.docs;
        final urls = docs
            .expand((doc) => [
                  doc['banner1'] as String?,
                  doc['banner2'] as String?,
                ])
            .whereType<String>()
            .where((u) => u.isNotEmpty)
            .toList();

        if (urls.isEmpty) {
          return _buildPlaceholderBanner();
        }

        return CarouselSlider.builder(
          itemCount: urls.length,
          options: CarouselOptions(
            height: 210,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.97,
            autoPlayInterval: const Duration(seconds: 4),
          ),
          itemBuilder: (_, idx, __) => ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: urls[idx],
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, __) => _buildBannerShimmer(),
              errorWidget: (_, __, ___) => _buildPlaceholderBanner(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBannerShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildPlaceholderBanner() {
    return Container(
      height: 210,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text('No banners available', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      height: 210,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  /* ---------- OnShop Banner ---------- */
  Widget _buildOnShopBanner() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appsettings')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('OnShop Banner Error: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildOnShopBannerShimmer();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;
        
        // Check if onshopinharithagramam is true in any document
        bool showOnShopBanner = false;
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['onshopinharithagramam'] == true) {
            showOnShopBanner = true;
            break;
          }
        }

        if (!showOnShopBanner) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MainScreen(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/onshopbanner.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'On Shop',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOnShopBannerShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  /* ---------- Category Grid ---------- */
  Widget _buildCategoryGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('harith_product_categories')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Category Error: ${snapshot.error}');
          return _buildErrorWidget('Failed to load categories');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No categories found')),
          );
        }

        final cats = snapshot.data!.docs
            .map((d) => {
                  'name': d['name'] as String? ?? 'Unnamed',
                  'image': d['image'] as String? ?? '',
                })
            .toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: cats.length,
            itemBuilder: (_, idx) {
              final cat = cats[idx];
              return GestureDetector(
                onTap: () {
                  // TODO: Navigate to category
                  print('Tapped category: ${cat['name']}');
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey, width: 0.5),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: cat['image']!.isEmpty
                            ? Container(
                                width: 45,
                                height: 45,
                                color: Colors.grey[300],
                                child: const Icon(Icons.category,
                                    color: Colors.grey),
                              )
                            : CachedNetworkImage(
                                imageUrl: cat['image']!,
                                width: 45,
                                height: 45,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 45,
                                  height: 45,
                                  color: Colors.grey[300],
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  width: 45,
                                  height: 45,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error,
                                      color: Colors.grey),
                                ),
                              ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        cat['name']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /* ---------- Promo Banner ---------- */
  Widget _buildPromoBanner() => const SizedBox.shrink(); // Placeholder for now

  /* ---------- Featured Products ---------- */
  Widget _buildProducts() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('harith-products')
          .where('display', isEqualTo: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Products Error: ${snapshot.error}');
          return _buildSectionError('Failed to load products');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildProductsShimmer();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final items = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Featured Products',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 220,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, idx) {
                  final doc = items[idx];
                  final p = doc.data() as Map<String, dynamic>;
                  final productId = doc.id;

                  return ProductCard(
                    name: p['name'] ?? 'Product Name',
                    imageUrl: p['image_url'] ?? '',
                    discountedPrice: p['discountedprice']?.toString() ?? '',
                    offerPrice: p['offerprice']?.toString() ??
                        p['discountedprice']?.toString() ??
                        '',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SingleProductPage(
                            product: {
                              ...p,
                              'id': productId,
                            },
                          ),
                        ),
                      );
                    },
                    isGridItem: false,
                  );
                },
              ),
            ),
            const SizedBox(height: 20)
          ],
        );
      },
    );
  }

  Widget _buildProductsShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Featured Products',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, idx) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionError(String message) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  /* ---------- All Products Grid ---------- */
  Widget _buildAllProductsGrid() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('harith-products')
          .where('display', isEqualTo: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('All Products Error: ${snapshot.error}');
          return _buildSectionError('Failed to load all products');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'No products available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        final items = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  'All Products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.68,
                ),
                itemCount: items.length,
                itemBuilder: (_, idx) {
                  final doc = items[idx];
                  final p = doc.data() as Map<String, dynamic>;
                  final productId = doc.id;

                  return ProductCard(
                    name: p['name'] ?? 'Product Name',
                    imageUrl: p['image_url'] ?? '',
                    discountedPrice: p['discountedprice']?.toString() ?? '',
                    offerPrice: p['offerprice']?.toString() ??
                        p['discountedprice']?.toString() ??
                        '',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SingleProductPage(
                            product: {
                              ...p,
                              'id': productId,
                            },
                          ),
                        ),
                      );
                    },
                    isGridItem: true,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /* ---------- Sponsored Ads ---------- */
  Widget _buildSponsoredAds() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('harith-sponsored-ads')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Sponsored Ads Error: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;
        final urls = docs
            .expand((doc) => [
                  doc['ad1'] as String?,
                  doc['ad2'] as String?,
                ])
            .whereType<String>()
            .where((u) => u.isNotEmpty)
            .toList();

        if (urls.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sponsored Ads',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CarouselSlider.builder(
                itemCount: urls.length,
                options: CarouselOptions(
                  height: 280,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.97,
                  autoPlayInterval: const Duration(seconds: 4),
                ),
                itemBuilder: (_, idx, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: urls[idx],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (_, __) => _buildBannerShimmer(),
                    errorWidget: (_, __, ___) => _buildPlaceholderBanner(),
                  ),
                ),
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
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: appBar,
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildBanner(),
            const SizedBox(height: 16),
            _buildCategoryGrid(),
            _buildOnShopBanner(), // Added OnShop banner between categories and featured products
            _buildPromoBanner(),
            _buildProducts(),
            _buildSponsoredAds(),
            _buildAllProductsGrid(),
          ],
        ),
      ),
    );
  }
}