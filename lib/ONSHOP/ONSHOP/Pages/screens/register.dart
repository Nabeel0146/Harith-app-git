// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:flutter/services.dart';
// import 'package:harithagramam/1SCREENS/ONSHOP/Pages/mainscree.dart';


// class RegisterPage extends StatefulWidget {
//   @override
//   _RegisterPageState createState() => _RegisterPageState();
// }

// class _RegisterPageState extends State<RegisterPage> {
//   final _nameController = TextEditingController();
//   final _mobileController = TextEditingController();
//   final _addressController = TextEditingController(); // Added for address
//   final _auth = FirebaseAuth.instance;
//   final _firestore = FirebaseFirestore.instance;

//   String? _selectedCity; // Variable to store selected city
//   List<String> _cities = []; // List of cities fetched from Firestore
//   bool _isLoading = false; // Variable to track loading state

//   @override
//   void initState() {
//     super.initState();
//     _checkIfUserIsAlreadyRegistered();
//     _fetchCities();
//   }

//   Future<void> _fetchCities() async {
//     try {
//       QuerySnapshot snapshot = await _firestore.collection('cities').get();
//       List<String> cities =
//           snapshot.docs.map((doc) => doc['name'] as String).toList();
//       setState(() {
//         _cities = cities;
//       });
//     } catch (e) {
//       print("Error fetching cities: $e");
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Failed to load cities.')));
//     }
//   }

//   Future<void> _checkIfUserIsAlreadyRegistered() async {
//     User? user = _auth.currentUser;

//     if (user != null) {
//       DocumentSnapshot userDoc =
//           await _firestore.collection('users').doc(user.uid).get();

//       if (userDoc.exists) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => MainScreen(secondApp: null,)),
//         );
//       }
//     }
//   }

//   Future<void> _register() async {
//   setState(() {
//     _isLoading = true; // Start loading
//   });

//   final name = _nameController.text.trim();
//   final mobile = _mobileController.text.trim();
//   final address = _addressController.text.trim();

//   if (_selectedCity == null) {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text('Please select a city.')));
//     setState(() {
//       _isLoading = false; // Stop loading
//     });
//     return;
//   }

//   if (mobile.length != 10) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Mobile number must be exactly 10 digits.')),
//     );
//     setState(() {
//       _isLoading = false; // Stop loading
//     });
//     return;
//   }

//   try {
//     UserCredential userCredential = await _auth.signInAnonymously();
//     User? user = userCredential.user;

//     if (user != null) {
//       await _firestore.collection('users').doc(user.uid).set({
//         'name': name,
//         'mobile': mobile,
//         'city': _selectedCity,
//         'address': address,
//         'email': user.email ?? 'anonymous',
//         'createdAt': FieldValue.serverTimestamp(), // Added timestamp
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('User registered successfully!')));

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => MainScreen()),
//       );
//     }
//   } catch (e) {
//     print("Error during registration: $e");
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text('An error occurred.')));
//   } finally {
//     setState(() {
//       _isLoading = false; // Stop loading
//     });
//   }
// }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // appBar: AppBar(title: const Text('Register')), backgroundColor: Colors.transparent,
//       body: Stack(
//         children: [
//           // Gradient background
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Colors.amber, // Top color
//                   Colors.white, // Bottom color
//                 ],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 stops: [
//                   0.0,
//                   0.4
//                 ], // Adjust the stops to control the gradient transition
//               ),
//             ),
//           ),
//           // Content
//           SingleChildScrollView(
//             child: Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     // Logo
//                     Padding(
//                       padding: const EdgeInsets.only(top: 48.0),
//                       child: Center(
//                         child: Image.asset(
//                           'asset/onshopnewcurvedlogo.png',
//                           height: 200,
//                           width: 200,
//                           fit: BoxFit.contain,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     Text(
//                       "Create an Account",
//                       style:
//                           TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
//                     ),
//                     SizedBox(
//                       height: 3,
//                     ),
//                     Text("Please fill the fields to create an account"),
//                     SizedBox(
//                       height: 20,
//                     ),
//                     TextField(
//                       controller: _nameController,
//                       decoration: InputDecoration(
//                         labelText: 'Full Name',
//                         border: OutlineInputBorder(
//                           borderSide: const BorderSide(
//                               color: Colors.black), // Black border
//                           borderRadius:
//                               BorderRadius.circular(8), // Rounded corners
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderSide: const BorderSide(
//                               color: Colors.black), // Black border when focused
//                           borderRadius:
//                               BorderRadius.circular(8), // Rounded corners
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderSide: const BorderSide(
//                               color: Colors.black), // Black border when enabled
//                           borderRadius: BorderRadius.circular(10.0),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     // Mobile number field

//                     TextField(
//                       controller: _mobileController,
//                       keyboardType: TextInputType.number,
//                       inputFormatters: [
//                         FilteringTextInputFormatter
//                             .digitsOnly, // Allow only digits
//                         LengthLimitingTextInputFormatter(
//                             10), // Limit to 10 digits
//                       ],
//                       decoration: InputDecoration(
//                         labelText: 'Mobile Number',
//                         border: OutlineInputBorder(
//                           borderSide: const BorderSide(
//                               color: Colors.black), // Black border
//                           borderRadius:
//                               BorderRadius.circular(8), // Rounded corners
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderSide: const BorderSide(
//                               color: Colors.black), // Black border when focused
//                           borderRadius:
//                               BorderRadius.circular(8), // Rounded corners
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderSide: const BorderSide(
//                               color: Colors.black), // Black border when enabled
//                           borderRadius: BorderRadius.circular(10.0),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     DropdownSearch<String>(
//                       items: _cities..sort(),
//                       selectedItem: _selectedCity,
//                       dropdownDecoratorProps: DropDownDecoratorProps(
//                         dropdownSearchDecoration: InputDecoration(
//                           labelText: "Select City",
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10.0),
//                           ),
//                         ),
//                       ),
//                       popupProps: PopupProps.menu(
//                         showSearchBox: true,
//                         searchFieldProps: TextFieldProps(
//                           decoration: InputDecoration(
//                             hintText: "Search city...",
//                             border: OutlineInputBorder(
//                               borderSide: const BorderSide(
//                                   color: Colors.black), // Black border
//                               borderRadius:
//                                   BorderRadius.circular(8), // Rounded corners
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderSide: const BorderSide(
//                                   color: Colors
//                                       .black), // Black border when focused
//                               borderRadius:
//                                   BorderRadius.circular(8), // Rounded corners
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderSide: const BorderSide(
//                                   color: Colors
//                                       .black), // Black border when enabled
//                             ),
//                           ),
//                         ),
//                       ),
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedCity = value;
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 20),
//                     // Address field
//                     TextField(
//   controller: _addressController,
//   minLines: 2, // Minimum number of lines
//   maxLines: null, // Allow unlimited lines
//   decoration: InputDecoration(
//     hintText: "Delivery Address",

//     border: OutlineInputBorder(
//       borderSide: const BorderSide(color: Colors.black), // Black border
//       borderRadius: BorderRadius.circular(8), // Rounded corners
//     ),
//     focusedBorder: OutlineInputBorder(
//       borderSide: const BorderSide(color: Colors.black), // Black border when focused
//       borderRadius: BorderRadius.circular(8), // Rounded corners
//     ),
//     enabledBorder: OutlineInputBorder(
//       borderSide: const BorderSide(color: Colors.black), // Black border when enabled
//       borderRadius: BorderRadius.circular(10.0),
//     ),
//   ),
// ),
//                     const SizedBox(height: 20),
//                     // Register button
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : _register,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Color.fromARGB(255, 255, 181, 45),
//                           foregroundColor: Colors.black,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10.0),
//                           ),
//                         ),
//                         child: _isLoading
//                             ? CircularProgressIndicator(
//                                 color: Colors.black,
//                               )
//                             : const Text(
//                                 'Register',
//                                 style: TextStyle(fontSize: 18),
//                               ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
