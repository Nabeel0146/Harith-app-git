import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/Products/99deals.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/Products/Productspage.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/Products/singleproductpage.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/searchresults.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/utils/appbar.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/utils/sidebar.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/widgets/widgets.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? bannerImageUrl;
  String? selectedCity;
  List<String> cities = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _checkForUpdate(); // Check for updates
  }

  void _loadInitialData() {
    _fetchBannerImage();
    _fetchCities();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForUpdate(); // Check for updates
  }

  List<String> bannerImages = [];

  Future<void> _checkForUpdate() async {
    try {
      // Initialize the In-App Update API
      final updateInfo = await InAppUpdate.checkForUpdate();

      // Check if an update is available
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Show the update dialog
        showUpdateDialog();
      } else {
        print("No update available.");
      }
    } catch (e) {
      print("Error checking for update: $e");
    }
  }

  void showUpdateDialog() {
    // Ensure the dialog is shown on the current context
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible:
            false, // Prevent closing the dialog by tapping outside
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('Update Available'),
            content: Text(
                'A new version of the app is available. Please update to the latest version.'),
            actions: <Widget>[
              TextButton(
                child: Text('Update'),
                onPressed: () async {
                  // Simulate update process
                  print('Simulating update process...');
                  Navigator.of(dialogContext).pop(); // Close the dialog
                },
              ),
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  print('Update cancelled by user.');
                  Navigator.of(dialogContext).pop(); // Close the dialog
                },
              ),
            ],
          );
        },
      );
    } else {
      print('Context is not mounted. Cannot show dialog.');
    }
  }

  Future<void> _fetchBannerImage() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Homepage_banner')
          .doc('banner')
          .get();

      // Extract banners and filter out null or empty values
      setState(() {
        bannerImages = [
          snapshot.data()?['banner1'] as String?,
          snapshot.data()?['banner2'] as String?,
          snapshot.data()?['banner3'] as String?,
          snapshot.data()?['banner4'] as String?,
          snapshot.data()?['banner5'] as String?,
          snapshot.data()?['banner6'] as String?,
          snapshot.data()?['banner7'] as String?,
          snapshot.data()?['banner8'] as String?,
          snapshot.data()?['banner9'] as String?,
          snapshot.data()?['banner10'] as String?,
          snapshot.data()?['banner11'] as String?,
          snapshot.data()?['banner12'] as String?,
          snapshot.data()?['banner13'] as String?,
          snapshot.data()?['banner14'] as String?,
          snapshot.data()?['banner15'] as String?,
          snapshot.data()?['banner16'] as String?,
          snapshot.data()?['banner17'] as String?,
          snapshot.data()?['banner18'] as String?,
          snapshot.data()?['banner19'] as String?,
          snapshot.data()?['banner20'] as String?,
          snapshot.data()?['banner21'] as String?,
          snapshot.data()?['banner22'] as String?,
          snapshot.data()?['banner23'] as String?,
          snapshot.data()?['banner24'] as String?,
          snapshot.data()?['banner25'] as String?,
          snapshot.data()?['banner26'] as String?,
          snapshot.data()?['banner27'] as String?,
          snapshot.data()?['banner28'] as String?,
          snapshot.data()?['banner29'] as String?,
          snapshot.data()?['banner30'] as String?,
        ].where((url) => url != null && url.isNotEmpty).cast<String>().toList();
      });
    } catch (error) {
      print("Error fetching banner: $error");
    }
  }

 
Widget buildBanner(List<String> bannerImages) {
  final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);
  final PageController pageController = PageController();

  if (bannerImages.isNotEmpty) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CarouselSlider(
          items: bannerImages.map((imageUrl) {
            return Builder(
              builder: (BuildContext context) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                );
              },
            );
          }).toList(),
          options: CarouselOptions(
            height: 190,
            viewportFraction: 1.0,
            enableInfiniteScroll: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            enlargeCenterPage: false,
            onPageChanged: (index, reason) {
              currentIndex.value = index;
            },
          ),
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<int>(
          valueListenable: currentIndex,
          builder: (context, index, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: bannerImages.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () {
                    pageController.animateToPage(
                      entry.key,
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.ease,
                    );
                  },
                  child: Container(
                    width: 6.0,
                    height: 6.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == entry.key
                          ? Colors.black
                          : Colors.grey[400],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  } else {
    // Show empty shimmer-like placeholder layout
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 190,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }
}

  Widget _buildFridayBazaarSection() {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: fetchFridayBazaarItems(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      final items = snapshot.data ?? [];

      // Check if today is Friday
      final isFriday = DateTime.now().weekday == DateTime.friday;

      if (!isFriday || items.isEmpty) {
        return const Center(
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                Text(
                  "Friday Bazaar",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Divider()
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.55, // Adjust this value to give more height to each grid item
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SingleProductPage(product: item),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey, // You can change the border color as needed
                      width: 0.5, // Set the border width to 0.5
                    ),
                    borderRadius: BorderRadius.circular(8), // Optional: Add rounded corners
                  ),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (item['image_url'] != null && item['image_url'].toString().isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AspectRatio(
                                    aspectRatio: 4 / 4,
                                    child: CachedNetworkImage(
                                      imageUrl: item['image_url'],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Container(
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.error),
                                          ),
                                    ),
                                  ),
                                )
                              else
                                AspectRatio(
                                  aspectRatio: 3 / 3,
                                  child: Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  item['name'] ?? 'No Name',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: Container(
                                  padding: const EdgeInsets.only(left: 6.0, right: 6, top: 2, bottom: 2),
                                  child: Text(
                                    item['description'] ?? 'No Description',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color.fromARGB(255, 107, 160, 107),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  'MRP ₹${item['price'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  '₹${item['discountedprice'] ?? 'N/A'}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 2.0),
                          child: ElevatedButton(
                            onPressed: () {
                              if (item['whatsappnumber'] != null) {
                                _openWhatsApp(
                                  item['whatsappnumber'],
                                  item['name'] ?? 'No Name',
                                  item['price'] ?? 0,
                                  item['discountedprice'] ?? 0,
                                  item['description'] ?? 'No Description',
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'asset/whatsapp.png',
                                  width: 16,
                                  height: 16,
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  'Order on Whatsapp',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    },
  );
}

  Future<List<Map<String, dynamic>>> fetchFridayBazaarItems() async {
    try {
      print('Fetching Friday Bazaar items...');
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('fridaybazaar', isEqualTo: true)
          .where('display', isEqualTo: true)
          .get();

      print('Number of items fetched: ${querySnapshot.docs.length}');
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching items: $e');
      return [];
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, String productName, int price,
    int discountedPrice, String description) async {
  final userAddress = await getUserAddress();
  final formattedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  final productDetails = """
Hello! I am interested in your product:

*Product:* $productName
*Price:* ₹$price
*Discounted Price:* ₹$discountedPrice
*Description:* $description
*Address:* $userAddress

Please process this order. Thank you!
  """.trim();

  final uri = Uri.parse(
      'https://wa.me/$formattedPhoneNumber?text=${Uri.encodeComponent(productDetails)}');

  if (!await launchUrl(uri)) {
    print('Could not launch $uri');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open WhatsApp for $phoneNumber')),
    );
  }
}

Future<String> getUserAddress() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return 'No address provided';
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users') // Keep original collection name
        .doc(user.uid)
        .get();
    if (!userDoc.exists) {
      return 'No address provided';
    }

    return userDoc.data()?['address'] ?? 'No address provided'; // Keep original field name
  } catch (e) {
    print('Error fetching user address: $e');
    return 'No address provided';
  }
}

  Future<void> _fetchCities() async {
    try {
      final cityDocs =
          await FirebaseFirestore.instance.collection('cities').get();
      final cityNames =
          cityDocs.docs.map((doc) => doc['name'] as String).toList();

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final userCity = userSnapshot.data()?['city'] as String?;

      setState(() {
        cities = cityNames;
        selectedCity =
            cityNames.contains(userCity) ? userCity : cityNames.firstOrNull;
      });
    } catch (error) {
      print("Error fetching cities: $error");
    }
  }

  void _navigateToSearchResults() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchResultsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        cities: cities,
        selectedCity: selectedCity,
        onCityChanged: (city) {
          setState(() {
            selectedCity = city;
          });
        },
      ),
      endDrawer: Sidebar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchButton(),

             
            buildBanner(bannerImages),
            const SizedBox(height: 26),
            _buildProductCategories(), // New section for scrollable rectangles
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left:8.0, right: 8, bottom: 20),
              child: GestureDetector(
                onTap: () {
                  // Navigate to 99deals page
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NinetyNineDealsPage()));
                },
                child: Image.asset(
                  'asset/99deals.png', // Replace with your actual image path
                  width: double.infinity, // Make the image take full width
                  // Adjust the height as needed
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),

            _buildCategoryTiles(),
            const SizedBox(height: 16),
          
            _buildAdsSection(),
            const SizedBox(height: 10),
           
            _buildFridayBazaarSection(), // Add the Friday Bazaar section here
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildProductsSection(context),
            )
          ],
        ),
      ),
    );
  }

  
Widget _buildAdsSection() {
  final ValueNotifier<int> currentAdIndex = ValueNotifier<int>(0);

  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance.collection('homepageads').doc('ads').get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data == null || snapshot.data!.data() == null) {
        return const Center(child: Text("No ads available"));
      }

      Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;

      List<String> adImages = [
        for (int i = 1; i <= 30; i++) data['ad$i'] as String?,
      ].where((url) => url != null && url.isNotEmpty).cast<String>().toList();

      if (adImages.isEmpty) {
        return const Center(child: Text("No ads available"));
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sponsored Ads",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            CarouselSlider.builder(
              itemCount: adImages.length,
              itemBuilder: (context, index, realIndex) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: adImages[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 380,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 380,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                );
              },
              options: CarouselOptions(
                height: 380,
                viewportFraction: 1,
                enableInfiniteScroll: true,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 3),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                enlargeCenterPage: true,
                onPageChanged: (index, reason) {
                  currentAdIndex.value = index;
                },
              ),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<int>(
              valueListenable: currentAdIndex,
              builder: (context, index, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: adImages.asMap().entries.map((entry) {
                    return Container(
                      width: 6.0,
                      height: 6.0,
                      margin: const EdgeInsets.symmetric(horizontal: 3.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == entry.key
                            ? Colors.black
                            : Colors.grey[400],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}

  Widget _buildProductCategories() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('productcategories').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5, // Number of placeholders to show
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 62,
                      height: 65,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox(
            height: 75,
            child: Center(child: Text("No categories available")),
          );
        }

        final categories = snapshot.data!.docs;

        return SizedBox(
          height: 80, // Fixed height for the scrollable section
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index].data() as Map<String, dynamic>;
              final imageUrl = category['image_url'] as String?;
              final name = category['name'] as String?;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductsPage(category: name ?? 'Category'),
                      ),
                    );
                  },
                  child: Container(
                    width: 61,
                    height: 69,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        imageUrl != null && imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 80,
                                height: 69,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              )
                            : const Icon(Icons.category, size: 32),
                        const SizedBox(height: 3),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: ElevatedButton(
        onPressed: _navigateToSearchResults,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          elevation: 0,
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Icon(Icons.search, color: Colors.grey),
            ),
            const SizedBox(width: 10),
            Text(
              'Search Shop code/name..',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTiles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: SizedBox(
        height: 90,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            buildLargeCategoryTile(
              context,
              'Shops',
              'Find Product Stores',
              'assets/onsapplogo.jpg',
              Colors.red,
              'shopcategories',
            ),
          ],
        ),
      ),
    );
  }

 

 Widget buildSmallCategoryTile(
    BuildContext context, String name, String imageUrl, Widget page) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    },
    child: Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white, // White background for the small category tiles
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imageUrl,
            width: 75,
            height: 75,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 1),
          // Text(
          //   name,
          //   style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          //   textAlign: TextAlign.center,
          // ),
          SizedBox(
            height: 2,
          )
        ],
      ),
    ),
  );
}

  Widget _buildProductsSection(BuildContext context) {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: _fetchAllProducts(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      final items = snapshot.data ?? [];

      if (items.isEmpty) {
        return const Center(
          child: Text('No items found.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: const [
                Text(
                  "Featured Products",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Divider()
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.55,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SingleProductPage(product: item),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (item['image_url'] != null &&
                                  item['image_url'].toString().isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AspectRatio(
                                    aspectRatio: 4 / 4,
                                    child: CachedNetworkImage(
                                      imageUrl: item['image_url'],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                AspectRatio(
                                  aspectRatio: 3 / 3,
                                  child: Container(
                                    color: Colors.grey[300],
                                    child:
                                        const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  item['name'] ?? 'No Name',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: Container(
                                  padding: const EdgeInsets.only(
                                      left: 6.0, right: 6, top: 2, bottom: 2),
                                  child: Text(
                                    item['description'] ?? 'No Description',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color.fromARGB(255, 107, 160, 107),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  'MRP ₹${item['price'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  '₹${item['discountedprice'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 1.0, vertical: 2.0),
                          child: ElevatedButton(
                            onPressed: () async {
                              if (item['whatsappnumber'] != null) {
                                await _openWhatsApp(
                                  item['whatsappnumber'],
                                  item['name'] ?? 'No Name',
                                  item['price'] ?? 0,
                                  item['discountedprice'] ?? 0,
                                  item['description'] ?? 'No Description',
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('WhatsApp number not found')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'asset/whatsapp.png',
                                  width: 16,
                                  height: 16,
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  'Order on Whatsapp',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    },
  );
}

  Future<List<Map<String, dynamic>>> _fetchAllProducts() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('display', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching items: $e');
      return [];
    }
  }
}