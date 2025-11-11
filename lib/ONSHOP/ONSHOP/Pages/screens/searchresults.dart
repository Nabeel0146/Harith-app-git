import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:harithapp/ONSHOP/ONSHOP/Pages/screens/Products/Shopprofile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/* =====================================================
 *  MAIN SEARCH RESULTS PAGE
 * ===================================================== */
class SearchResultsPage extends StatefulWidget {
  const SearchResultsPage({Key? key}) : super(key: key);

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Shop> _shops = [];
  List<City> _cities = [];

  List<String> cities = [];
  String? selectedCity;

  @override
  void initState() {
    super.initState();
    _fetchCities();
  }

  /* ----------  CITY LIST FOR DROPDOWN  ---------- */
  Future<void> _fetchCities() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('cities').limit(50).get();
      cities = snap.docs.map((d) => d['name'] as String).toList();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('fetchCities error: $e');
    }
  }

  /* ----------  SEARCH SHOPS + CITIES  ---------- */
  Future<void> _search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _shops = [];
        _cities = [];
      });
      return;
    }

    try {
      final shopSnap = await FirebaseFirestore.instance
          .collection('shops')
          .where('display', isEqualTo: true)
          .limit(1550)
          .get();

      final shops = shopSnap.docs
          .map((d) => Shop.fromFirestore(d.id, d.data()))
          .where((shop) =>
              shop.name.toLowerCase().contains(q) ||
              shop.shopcode.toLowerCase().contains(q)) // <-- Searching both name and shopcode
          .toList();

      final citySnap =
          await FirebaseFirestore.instance.collection('cities').limit(15).get();

      final citiesResult = citySnap.docs
          .map((d) => City.fromFirestore(d.id, d.data()))
          .where((city) => city.name.toLowerCase().contains(q))
          .toList();

      setState(() {
        _shops = shops;
        _cities = citiesResult;
      });
    } catch (e) {
      debugPrint('search error: $e');
    }
  }

  /* ----------  LOCKED-SHOP LOGIC  ---------- */
  Future<void> _checkCustomerID(Shop shop) async {
    // 1.  Not associated → open directly
    if (!shop.associate) {
      _openShopProfile(shop);
      return;
    }

    // 2.  Associated but not locked → open directly
    if (!shop.lock) {
      _openShopProfile(shop);
      return;
    }

    // 3.  Locked & associated → ask for customerID
    final prefs = await SharedPreferences.getInstance();
    Map<String, String> storedMap = {};

    final raw = prefs.getString('customerIDs');
    if (raw != null && raw.isNotEmpty) {
      storedMap = Map<String, String>.from(jsonDecode(raw));
    }

    final storedId = storedMap[shop.id];
    if (storedId != null && storedId == shop.customerid) {
      _openShopProfile(shop); // already validated
      return;
    }

    // ---------- show dialog ----------
    String? enteredId;
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter Shop ID'),
            SizedBox(height: 4),
            Text(
              'Enter the shop id to view Business Profile',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Shop ID',
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (v) => enteredId = v,
        ),
        actions: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(_, enteredId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );

    // ---------- validate ----------
    if (enteredId == null || enteredId!.isEmpty) return;
    if (enteredId != shop.customerid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Customer ID')),
      );
      return;
    }

    // ---------- store & open ----------
    storedMap[shop.id] = enteredId!;
    await prefs.setString('customerIDs', jsonEncode(storedMap));
    _openShopProfile(shop);
  }

  /* ----------  ROUTE HELPER  ---------- */
  void _openShopProfile(Shop shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopProfilePage(shopData: shop.toMap()),
      ),
    );
  }

  /* ----------  HELPERS  ---------- */
  void _makeCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(uri)) debugPrint('could not launch $uri');
  }

  void _openWhatsApp(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    final clean = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  void _shareDetails(String title, String description, String phoneNumber) {
    final footer =
        '\n\nShared from Onshop App. Download Onshop App now from Google Playstore / App Store';
    // Share.share('$title\n\n$description\n\nContact: $phoneNumber$footer',
    //     subject: 'Check out this shop on Onshop!');
  }

  /* ----------  UI  ---------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 255, 185, 41), Colors.white],
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
                      Image.asset("asset/onshopnewcurvedlogo.png", width: 50),
                ),
                const SizedBox(width: 10),
                const Text('On Shop',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          /* ----------  SEARCH BAR  ---------- */
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search shops by name or shop code...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          /* ----------  RESULTS  ---------- */
          Expanded(
            child: _shops.isEmpty && _cities.isEmpty
                ? const Center(child: Text('No results found'))
                : ListView(
                    children: [
                      if (_shops.isNotEmpty) ...[
                        const _SectionTitle('Shops'),
                        ..._shops.map((shop) => _ShopTile(
                              shop: shop,
                              onTap: () => _checkCustomerID(shop),
                              onCall: () => _makeCall(shop.mobile),
                              onWhatsApp: () => _openWhatsApp(shop.whatsapp),
                              onShare: () => _shareDetails(
                                  shop.name, shop.description, shop.mobile),
                            )),
                      ],
                      if (_cities.isNotEmpty) ...[
                        const _SectionTitle('Cities'),
                        ..._cities.map((city) => _CityTile(
                              city: city,
                              onTap: () {
                                debugPrint('selected city: ${city.name}');
                                // You can add navigation to city-specific shops here
                              },
                            )),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/* =====================================================
 *  DATA MODELS
 * ===================================================== */
class Shop {
  final String id;
  final String name;
  final String description;
  final String mobile;
  final String whatsapp;
  final String? imageUrl;
  final String city;
  final bool associate;
  final bool lock;
  final String customerid;
  final String shopcode;

  Shop({
    required this.id,
    required this.name,
    required this.description,
    required this.mobile,
    required this.whatsapp,
    this.imageUrl,
    required this.city,
    required this.associate,
    required this.lock,
    required this.customerid,
    required this.shopcode,
  });

  factory Shop.fromFirestore(String id, Map<String, dynamic> json) => Shop(
        id: id,
        name: json['name'] ?? 'No name',
        description: json['description'] ?? 'No description',
        mobile: json['mobile'] ?? '',
        whatsapp: json['whatsapp'] ?? '',
        imageUrl: json['image_url'],
        city: json['city'] ?? '',
        associate: json['associate'] ?? false,
        lock: json['lock'] ?? false,
        shopcode: json['shopcode'] ?? '',
        customerid: json['customerid'] ?? '',
      );

  Map<String, dynamic> toMap() {
    return {
      'documentId': id,
      'name': name,
      'description': description,
      'mobile': mobile,
      'whatsapp': whatsapp,
      'image_url': imageUrl,
      'city': city,
      'associate': associate,
      'lock': lock,
      'shopcode': shopcode,
      'customerid': customerid,
      'shopid': id,
    };
  }
}

class City {
  final String id;
  final String name;

  City({required this.id, required this.name});

  factory City.fromFirestore(String id, Map<String, dynamic> json) =>
      City(id: id, name: json['name'] ?? 'No name');
}

/* =====================================================
 *  WIDGET HELPERS
 * ===================================================== */
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  final Shop shop;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onShare;

  const _ShopTile({
    required this.shop,
    required this.onTap,
    required this.onCall,
    required this.onWhatsApp,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[400]!, width: 1),
        ),
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 22, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: shop.imageUrl ??
                      'https://onshop.in/categories/unnamed.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 30),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- shop code ----
                    if (shop.shopcode.isNotEmpty)
                      Text(
                        'Shop Code: ${shop.shopcode}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    // ---- shop name ----
                    Text(
                      shop.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // ---- description ----
                    if (shop.description.isNotEmpty)
                      Text(
                        shop.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    const SizedBox(height: 4),
                    // ---- mobile & actions row ----
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mobile: ${shop.mobile}',
                            style: const TextStyle(fontSize: 12)),
                        Row(
                          children: [
                            _iconButton('asset/phone-call.png', onCall),
                            const SizedBox(width: 10),
                            if (shop.whatsapp.isNotEmpty)
                              _iconButton('asset/whatsapp2.png', onWhatsApp),
                            const SizedBox(width: 10),
                            _iconButton('asset/share2.png', onShare),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton(String asset, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Image.asset(asset, width: 20),
      );
}

class _CityTile extends StatelessWidget {
  final City city;
  final VoidCallback onTap;

  const _CityTile({required this.city, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.location_city, color: Colors.teal),
      title: Text(city.name),
      onTap: onTap,
    );
  }
}