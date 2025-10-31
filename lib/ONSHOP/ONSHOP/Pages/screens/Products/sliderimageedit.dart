import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SliderImagesEdit extends StatefulWidget {
  final String shopId;
  final Map<String, dynamic>? shopDetails;

  const SliderImagesEdit({Key? key, required this.shopId, this.shopDetails})
      : super(key: key);

  @override
  _SliderImagesEditState createState() => _SliderImagesEditState();
}

class _SliderImagesEditState extends State<SliderImagesEdit> {
  Map<String, File?> selectedImages = {};

  Future<void> _pickAndUploadImage(String field) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      selectedImages[field] = imageFile;

      try {
        // Upload the image to Firebase Storage
        Reference storageReference = FirebaseStorage.instance.ref().child(
            'shop_images/${widget.shopId}/$field/${DateTime.now().millisecondsSinceEpoch}');
        UploadTask uploadTask = storageReference.putFile(imageFile);
        TaskSnapshot taskSnapshot = await uploadTask;

        // Get the download URL of the uploaded image
        String imageUrl = await taskSnapshot.ref.getDownloadURL();

        // Update the Firestore document with the new image URL
        await FirebaseFirestore.instance.collection('shops').doc(widget.shopId).update({
          field: imageUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image uploaded successfully")),
        );

        // Print the document ID after uploading the image
        print('Document ID after uploading image: ${widget.shopId}');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error uploading image: $e")),
        );
      }
    }
  }

  Future<void> _deleteImage(String field) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this image?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Return false if cancel is pressed
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Return true if delete is pressed
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        // Update the Firestore document to remove the image URL
        await FirebaseFirestore.instance.collection('shops').doc(widget.shopId).update({
          field: FieldValue.delete(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image deleted successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting image: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Print the document ID when the page is opened
    print('Document ID when opening the page: ${widget.shopId}');

    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Slider Images"),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('shops').doc(widget.shopId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("No shop data found"));
          }

          Map<String, dynamic> shopDetails = snapshot.data!.data() as Map<String, dynamic>;

          // Extract image fields dynamically from the document
          List<String> imageFields = shopDetails.keys.where((key) => key.startsWith('image')).toList();

          return ListView.builder(
            itemCount: imageFields.length,
            itemBuilder: (context, index) {
              String field = imageFields[index];
              String? imageUrl = shopDetails[field];

              return ListTile(
                title: Text(field),
                leading: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : Icon(Icons.image, size: 50),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.add_a_photo),
                      onPressed: () => _pickAndUploadImage(field),
                    ),
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteImage(field),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}