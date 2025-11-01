
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'listing_page.dart';

class SubcategoryGridPage extends StatelessWidget {
  final String collectionName;

  SubcategoryGridPage({required this.collectionName});

  Future<List<Map<String, dynamic>>> _fetchSubcategories() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection(collectionName).get();
      return querySnapshot.docs
          .map((doc) => {
                'name': doc['name'], // Subcategory name
                'icon': doc['icon'], // Subcategory icon URL
              })
          .toList();
    } catch (e) {
      print('Error fetching subcategories: $e');
      return [];
    }
  }

  Future<List<String>> _fetchBannerImageUrls() async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('shoppagebanners')
        .doc('banner')
        .get();
    final data = querySnapshot.data();
    List<String> bannerUrls = [];
    for (int i = 1; i <= 30; i++) { // Update the loop to fetch up to 30 images
      final key = 'ad$i';
      if (data != null && data.containsKey(key) && data[key] is String) {
        bannerUrls.add(data[key] as String);
      }
    }
    return bannerUrls;
  } catch (e) {
    print('Error fetching banner images: $e');
    return [];
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent to allow gradient
        toolbarHeight: 70,
        elevation: 0, // Remove shadow if not needed
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 255, 185, 41), // Yellow at the top
                Colors.white, // White at the bottom
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                const SizedBox(width: 45),
                ClipRRect(
                  child:
                      Image.asset("assets/onshopnewcurvedlogo.png", width: 50),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'On Shop',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<String>>(
        future: _fetchBannerImageUrls(),
        builder: (context, bannerSnapshot) {
          if (bannerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bannerUrls = bannerSnapshot.data ?? [];

          return SingleChildScrollView(
            child: Column(
              children: [
                // Carousel of banners
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: bannerUrls.isNotEmpty
                      ? CarouselSlider(
                          items: bannerUrls.map((url) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit
                                    .contain, // Ensure the image fits within the container without being cut off
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
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
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          options: CarouselOptions(
                            height: 340,
                            enlargeCenterPage: true,
                            autoPlay: true,
                            aspectRatio: 16 / 9,
                            autoPlayCurve: Curves.fastOutSlowIn,
                            enableInfiniteScroll: true,
                            autoPlayAnimationDuration:
                                const Duration(milliseconds: 800),
                            viewportFraction: 1,
                          ),
                        )
                      : Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 1),
                // Subcategories grid
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchSubcategories(),
                  builder: (context, subcategorySnapshot) {
                    if (subcategorySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (subcategorySnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${subcategorySnapshot.error}'));
                    } else if (!subcategorySnapshot.hasData ||
                        subcategorySnapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('No subcategories found.'));
                    }

                    final subcategories = subcategorySnapshot.data!;
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1, // Adjusted for images
                        ),
                        itemCount: subcategories.length,
                        itemBuilder: (context, index) {
                          final subcategory = subcategories[index];
                          return GestureDetector(
                            onTap: () {
                              print(
                                  'Selected Subcategory: ${subcategory['name']}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ListingPage(
                                    subcategory: subcategory['name'],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    width: .5,
                                    color: const Color.fromARGB(
                                        255, 217, 217, 217)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Image or placeholder
                                  CachedNetworkImage(
                                    imageUrl: subcategory['icon'] ?? '',
                                    height: 33,
                                    width: 33,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(
                                        height: 45,
                                        width: 45,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Text with fixed height to ensure uniform alignment
                                  Container(
                                    height:
                                        36, // Adjust height as per your design
                                    alignment: Alignment.center,
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: AutoSizeText(
                                          subcategory['name'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 10,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          minFontSize:
                                              8, // Minimum font size if the text needs to be resized
                                          stepGranularity:
                                              1, // Step size for font size reduction
                                        )),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
