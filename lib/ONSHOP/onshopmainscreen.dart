import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/Discount%20card/Discountcard.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/Products/Productcategoriespage.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/Products/fridaybazaar.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/subcategory_page.dart';
import 'package:harithapp/ONSHOP/homeonshop.dart';

class MainScreen extends StatefulWidget {
  


  const MainScreen({super.key,});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);

  late List<Widget> _pages; // will be filled in initState()

  @override
  void initState() {
    super.initState();

    // ✅ initialize _pages here (widget is available)
    _pages = [
      HomePage(),
       ProductCategoriesPage(),
      SubcategoryGridPage(collectionName: 'shopcategories'),
      DiscountCardPage(),
      FridayBazaarSale(),
      // Friday Bazaar Sale Page
    ];

    _showPopupAfterDelay(); // check and show popup
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  Future<void> _showPopupAfterDelay() async {
    await Future.delayed(const Duration(seconds: 5));

    try {
      final popupDoc = await FirebaseFirestore.instance
          .collection('Popup')
          .doc('welcomePopup')
          .get();

      final popupData = popupDoc.data();
      final imageUrl = popupData?['imageUrl'] as String?;
      final isActive = popupData?['isActive'] as bool? ?? false;

      if (isActive && imageUrl != null && imageUrl.isNotEmpty && mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 400,
                      height: 500,
                      fit: BoxFit.cover,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (error) {
      print("Error fetching popup data: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: _pages,
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(child: _buildNavItem('asset/home.png', 'Home', 0)),
            const VerticalDivider(width: .5, color: Color.fromARGB(255, 148, 148, 148)),
            Expanded(child: _buildNavItem('asset/grocery.png', 'Categories', 1)),
            const VerticalDivider(width: .5, color: Color.fromARGB(255, 148, 148, 148)),
            Expanded(child: _buildNavItem('asset/online-shop.png', 'Shops', 2)),
            const VerticalDivider(width: .5, color: Color.fromARGB(255, 148, 148, 148)),
            Expanded(child: _buildNavItem('asset/credit-card.png', 'DiscountCard', 3)),
            const VerticalDivider(width: .5, color: Color.fromARGB(255, 148, 148, 148)),
            Expanded(child: _buildNavItem('asset/friday.png', 'Friday Bazaar', 4)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String assetImage, String label, int index) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Container(
        height: double.infinity,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(assetImage, width: 24, height: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: _selectedIndex == index
                    ? Colors.black
                    : const Color.fromARGB(255, 105, 105, 105),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}