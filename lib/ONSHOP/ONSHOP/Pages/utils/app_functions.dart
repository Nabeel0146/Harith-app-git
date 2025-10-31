import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

Future<List<Map<String, dynamic>>> fetchItems(String subcategory, String? city) async {
  try {
    final query = FirebaseFirestore.instance
        .collection('shops')
        .where('subcategory', isEqualTo: subcategory);

    // Only filter by city if one is selected
    if (city != null && city.isNotEmpty) {
      query.where('city', isEqualTo: city);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return {
        'name': doc['name'],
        'image_url': doc['image_url'],
        'description': doc['description'],
        'mobile': doc['mobile'],
        'whatsapp': doc['whatsapp'],
      };
    }).toList();
  } catch (error) {
    print("Error fetching items: $error");
    return [];
  }
}

Future<List<String>> fetchCities() async {
  try {
    final citiesSnapshot = await FirebaseFirestore.instance.collection('cities').get();
    return citiesSnapshot.docs.map((doc) => doc['name'] as String).toList();
  } catch (error) {
    print("Error fetching cities: $error");
    return [];
  }
}

void makeCall(String number) async {
  final uri = Uri(scheme: 'tel', path: number);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    print('Could not launch $uri');
  }
}

void openWhatsApp(String number) async {
  final uri = Uri.parse('https://wa.me/$number');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    print('Could not launch $uri');
  }
}

void shareDetails(String details) {
  // Implement share functionality using a plugin like share_plus
  print('Sharing details: $details');
}