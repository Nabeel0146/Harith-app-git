import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/Hospitals/hospitalcategory.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/jobs/jobs.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/offers_page.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/subcategory_page.dart';

Widget buildUserCard() {
  return Container(
    color: Colors.orange,
    padding: EdgeInsets.all(16),
    child: Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white,
          child: Icon(Icons.shopping_bag, color: Colors.orange),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Muhammed Nabeel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Card No: OS2799760143',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildSearchBar() {
  return Padding(
    padding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 8), // Adjust vertical padding
    child: TextField(
      decoration: InputDecoration(
        hintText: 'Search City or Shop',
        prefixIcon: const Icon(Icons.search),
        contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12), // Adjust padding inside the TextField
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}

Widget buildBanner(List<String> bannerImages) {
  if (bannerImages.isNotEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 150,
          viewportFraction: 0.9,
          enableInfiniteScroll: true,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 3),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          enlargeCenterPage: true,
        ),
        items: bannerImages.map((imageUrl) {
          return Builder(
            builder: (BuildContext context) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, color: Colors.red),
                    );
                  },
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  } else {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[300],
        ),
        child: const Center(
          child: Text(
            'No banners available.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

Widget buildOfferSection(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OffersPage()),
      );
    },
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4), // Light shadow
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
        color: Color.fromARGB(255, 78, 197, 96),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Text(
            'Latest Offers',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    ),
  );
}

Widget buildLargeCategoryTile(BuildContext context, String title,
    String subtitle, String iconPath, Color color, String collectionName) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SubcategoryGridPage(collectionName: collectionName),
        ),
      );
    },
    child: Container(
      width: MediaQuery.of(context).size.width * 0.90, // Large size
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white, // White background
        border: Border.all(color: Color.fromARGB(255, 215, 215, 215)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 255, 225, 0).withOpacity(0.4), // Light shadow
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3), // Shadow direction
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            iconPath, // Path to the icon asset
            height: 55, // Adjusted icon size
            width: 55,
          ),
        ],
      ),
    ),
  );
}

Widget buildSmallCategoryTile(BuildContext context, String title,
    String assetImagePath, String collectionName) {
  return GestureDetector(
    onTap: () {
      if (title == 'Job Vacancy') {
        // Navigate to the JobsListingPage when "Jobs" is clicked
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobsListingPage(),
          ),
        );
      } else if (title == 'Hospitals') {
        // Navigate to the HospitalsPage when "Hospitals" is clicked
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HospitalsPage(),
          ),
        );
      } else {
        // Otherwise, navigate to the SubcategoryGridPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SubcategoryGridPage(collectionName: collectionName),
          ),
        );
      }
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // Shadow position
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            assetImagePath,
            height: 30, // Adjust size as needed
            width: 30,
          ),
          SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(right:3, left: 3),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
