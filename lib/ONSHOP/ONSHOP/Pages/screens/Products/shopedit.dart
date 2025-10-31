import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class ShopEditPage extends StatefulWidget {
  final String shopId;
  final Map<String, dynamic> shopData;

  const ShopEditPage({Key? key, required this.shopId, required this.shopData})
      : super(key: key);

  @override
  _ShopEditPageState createState() => _ShopEditPageState();
}

class _ShopEditPageState extends State<ShopEditPage> {
  String? documentId;
  Map<String, dynamic>? shopDetails;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();

  List<String> categories = [];
  String? selectedCategory;

  File? _selectedImage; // For shop image
  File? productImage; // For product image

  @override
  void initState() {
    super.initState();
    _fetchShopDocument();
    _fetchCategories();
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickProductImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        productImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadProductImage(File imageFile) async {
    if (imageFile == null) {
      throw 'No image selected';
    }

    Reference storageReference = FirebaseStorage.instance.ref().child(
        'product_images/${widget.shopId}/${DateTime.now().millisecondsSinceEpoch}');
    UploadTask uploadTask = storageReference.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;

    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> _uploadImageAndUpdateUrl() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select an image")),
      );
      return;
    }

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Uploading image...")),
      );

      // Upload the image to Firebase Storage
      Reference storageReference = FirebaseStorage.instance.ref().child(
          'shop_images/${widget.shopId}/${DateTime.now().millisecondsSinceEpoch}');
      UploadTask uploadTask = storageReference.putFile(_selectedImage!);
      TaskSnapshot taskSnapshot = await uploadTask;

      // Get the download URL of the uploaded image
      String imageUrl = await taskSnapshot.ref.getDownloadURL();

      // Update the image_url field in Firestore
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(documentId)
          .update({
        'image_url': imageUrl,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image updated successfully")),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: $e")),
      );
      print("Error uploading image: $e");
    }
  }

  Future<void> _fetchShopDocument() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('shops')
          .where('shopid', isEqualTo: widget.shopId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        setState(() {
          documentId = doc.id;
          shopDetails = doc.data() as Map<String, dynamic>;

          // Populate text fields with fetched data
          nameController.text = shopDetails?['name'] ?? '';
          descriptionController.text = shopDetails?['description'] ?? '';
          mobileController.text = shopDetails?['mobile'] ?? '';
          whatsappController.text = shopDetails?['whatsapp'] ?? '';
        });
      } else {
        print("Shop not found with shopid: ${widget.shopId}");
      }
    } catch (e) {
      print("Error fetching shop document: $e");
    }
  }

  Future<void> _fetchCategories() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('productcategories')
          .get();

      List<String> fetchedCategories =
          querySnapshot.docs.map((doc) => doc['name'] as String).toList();
      setState(() {
        categories = fetchedCategories;
      });
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Future<void> _updateShopData() async {
    if (documentId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(documentId)
          .update({
        'name': nameController.text,
        'description': descriptionController.text,
        'mobile': mobileController.text,
        'whatsapp': whatsappController.text,
      });

      print("Shop data updated successfully!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Shop updated successfully")),
      );
    } catch (e) {
      print("Error updating shop: $e");
    }
  }

  void _deleteProduct(String productId) async {
    // Show a confirmation dialog
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this product?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(false), // Return false if cancel is pressed
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(true), // Return true if delete is pressed
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    // Check if the user confirmed the deletion
    if (confirmDelete == true) {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Product deleted")));
    }
  }

  void _editProduct(String productId, Map<String, dynamic> productData) {
    TextEditingController nameController =
        TextEditingController(text: productData['name']);
    TextEditingController descController =
        TextEditingController(text: productData['description']);
    TextEditingController priceController =
        TextEditingController(text: productData['price']?.toString() ?? '');
    TextEditingController discountedPriceController = TextEditingController(
        text: productData['discountedprice']?.toString() ?? '');
    String? selectedCategory = productData['category'];
    File?
        localProductImage; // Local variable to hold the selected product image
    String? currentImageUrl =
        productData['image_url']; // Current image URL from Firestore
    bool isSaving = false; // Flag to track if the save operation is in progress

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Edit Product"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField("Product Name", nameController),
                  _buildTextField("Description", descController),
                  _buildTextField("Price", priceController, isNumeric: true),
                  _buildTextField("Discounted Price", discountedPriceController,
                      isNumeric: true),
                  DropdownButton<String>(
                    value: selectedCategory,
                    hint: Text("Select Category"),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCategory = newValue;
                      });
                    },
                    items: categories
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  // Display current image or a placeholder
                  currentImageUrl != null && currentImageUrl.isNotEmpty
                      ? Image.network(
                          currentImageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : Icon(Icons.image, size: 100),
                  ElevatedButton(
                    onPressed: () async {
                      final ImagePicker _picker = ImagePicker();
                      final XFile? pickedFile =
                          await _picker.pickImage(source: ImageSource.gallery);

                      if (pickedFile != null) {
                        setState(() {
                          localProductImage = File(pickedFile.path);
                        });
                      }
                    },
                    child: Text("Change Image"),
                  ),

                  if (localProductImage != null)
                    Image.file(localProductImage!,
                        width: 100, height: 100, fit: BoxFit.cover),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() {
                            isSaving =
                                true; // Set the flag to true to show the progress indicator
                          });

                          if (selectedCategory == null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("Please select a category")));
                            setState(() {
                              isSaving =
                                  false; // Reset the flag if validation fails
                            });
                            return;
                          }

                          String imageUrl = currentImageUrl ?? '';
                          if (localProductImage != null) {
                            try {
                              imageUrl =
                                  await _uploadProductImage(localProductImage!);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text("Error uploading image: $e")));
                              setState(() {
                                isSaving =
                                    false; // Reset the flag if upload fails
                              });
                              return;
                            }
                          }

                          await FirebaseFirestore.instance
                              .collection('products')
                              .doc(productId)
                              .update({
                            'name': nameController.text,
                            'description': descController.text,
                            'image_url': imageUrl,
                            'price': priceController.text.isNotEmpty
                                ? int.tryParse(priceController.text)
                                : null,
                            'discountedprice': discountedPriceController
                                    .text.isNotEmpty
                                ? int.tryParse(discountedPriceController.text)
                                : null,
                            'category': selectedCategory,
                          });

                          setState(() {
                            isSaving =
                                false; // Reset the flag after successful save
                          });

                          Navigator.pop(context);
                        },
                  child: isSaving
                      ? CircularProgressIndicator()
                      : Text("Save Changes"),
                ),
              ],
            );
          },
        );
      },
    );
  }

 Future<void> _addProduct() async {
  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController discountedPriceController = TextEditingController();
  String? selectedCategory;

  File? localProductImage; // Local variable to hold the selected product image
  bool isSaving = false; // Flag to track if the save operation is in progress

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Add New Product"),
            content: SingleChildScrollView( // Wrap the content with SingleChildScrollView
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField("Product Name", nameController),
                  _buildTextField("Description", descController),
                  _buildTextField("Price", priceController, isNumeric: true),
                  _buildTextField("Discounted Price", discountedPriceController,
                      isNumeric: true),
                  DropdownButton<String>(
                    value: selectedCategory,
                    hint: Text("Select Category"),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCategory = newValue;
                      });
                    },
                    items: categories
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final ImagePicker _picker = ImagePicker();
                      final XFile? pickedFile =
                          await _picker.pickImage(source: ImageSource.gallery);

                      if (pickedFile != null) {
                        setState(() {
                          localProductImage = File(pickedFile.path);
                        });
                      }
                    },
                    child: Text("Pick Product Image"),
                  ),
                  if (localProductImage != null)
                    Image.file(localProductImage!,
                        width: 100, height: 100, fit: BoxFit.cover),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setState(() {
                          isSaving =
                              true; // Set the flag to true to show the progress indicator
                        });

                        if (selectedCategory == null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Please select a category")));
                          setState(() {
                            isSaving =
                                false; // Reset the flag if validation fails
                          });
                          return;
                        }

                        if (localProductImage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Please select an image")));
                          setState(() {
                            isSaving =
                                false; // Reset the flag if validation fails
                          });
                          return;
                        }

                        String imageUrl;
                        try {
                          imageUrl =
                              await _uploadProductImage(localProductImage!);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Error uploading image: $e")));
                          setState(() {
                            isSaving =
                                false; // Reset the flag if upload fails
                          });
                          return;
                        }

                        await FirebaseFirestore.instance
                            .collection('products')
                            .add({
                          'shopid': widget.shopId,
                          'name': nameController.text,
                          'description': descController.text,
                          'image_url': imageUrl,
                          'price': priceController.text.isNotEmpty
                              ? int.tryParse(priceController.text)
                              : null,
                          'discountedprice': discountedPriceController
                              .text.isNotEmpty
                              ? int.tryParse(discountedPriceController.text)
                              : null,
                          'city': shopDetails?['city'] ?? '',
                          'display': true,
                          'category': selectedCategory,
                          'whatsappnumber': shopDetails?['whatsapp'] ?? '',
                        });

                        setState(() {
                          isSaving =
                              false; // Reset the flag after successful save
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Product added successfully")));
                      },
                child: isSaving
                    ? CircularProgressIndicator()
                    : Text("Add Product"),
              ),
            ],
          );
        },
      );
    },
  );
}

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text(
                        'Edit Business Profile',
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
        backgroundColor: Colors.amber,
      ),
      body: shopDetails == null || categories.isEmpty
          ? Center(
              child:
                  CircularProgressIndicator()) // Show loader while fetching data
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Display the current image
                  if (shopDetails?['image_url'] != null &&
                      shopDetails!['image_url'].isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        shopDetails!['image_url'],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Icon(Icons.image, size: 100),

                  // Button to pick a new image
                  SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text("Change Image"),
                  ),
                  if (_selectedImage != null)
                    Image.file(_selectedImage!,
                        width: 100, height: 100, fit: BoxFit.cover),
                  SizedBox(height: 10),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => SliderImagesEdit(
                  //           shopId: widget.shopId,
                  //           shopDetails: shopDetails,
                  //         ),
                  //       ),
                  //     );
                  //   },
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor:
                  //         Colors.amber, // Set the background color to amber
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(
                  //           10), // Set the border radius for rounded corners
                  //     ),
                  //   ),
                  //   child: SizedBox(
                  //     width: 180,
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         Text(
                  //           "Change Slider Images",
                  //           style: TextStyle(color: Colors.white),
                  //         ),
                  //         Icon(
                  //           Icons.arrow_right,
                  //           color: Colors.white,
                  //         )
                  //       ],
                  //     ),
                  //   ),
                  // ),

                  // Display the selected image
                  

                  SizedBox(height: 20),

                  _buildTextField("Shop Name", nameController),
                  _buildTextField("Description", descriptionController),
                  _buildTextField("Mobile", mobileController),
                  _buildTextField("WhatsApp", whatsappController),

                  SizedBox(height: 20),
                  Container(
                    width: double
                        .infinity, // Make the button width fill the available space
                    height: 50, // Set a fixed height for the button
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(10), // Rounded corners
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        await _uploadImageAndUpdateUrl();
                        await _updateShopData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10), // Rounded corners
                        ),
                      ),
                      child: Text(
                        "Save Changes",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Products",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: _addProduct,
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.add, color: Colors.blue),
                              onPressed: _addProduct,
                            ),
                            Text("Add new",
                                style: TextStyle(color: Colors.blue))
                          ],
                        ),
                      ),
                    ],
                  ),

                  _buildProductList(),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumeric = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
            labelText: label,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('shopid', isEqualTo: widget.shopId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No products found."));
        }

        var products = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            var product = products[index].data() as Map<String, dynamic>;
            String productId = products[index].id;

            return Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border:
                    Border.all(color: Colors.grey, width: 1), // Add a border
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
              child: Card(
                margin:
                    EdgeInsets.zero, // Remove the default margin of the Card
                child: ListTile(
                  leading: product['image_url'] != null &&
                          product['image_url'].isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                              10), // Rounded corners for the image
                          child: Image.network(
                            product['image_url'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.image, size: 50),
                  title: Text(product['name'] ?? 'Unnamed Product'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['description'] ?? ''),
                      Text(product['category'] ?? ''),
                      if (product['price'] != null)
                        Text("Price: ${product['price']}"),
                      if (product['discountedprice'] != null)
                        Text("Discounted Price: ${product['discountedprice']}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editProduct(productId, product),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteProduct(productId),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
