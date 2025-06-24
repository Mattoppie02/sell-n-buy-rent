import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload a product image to Firebase Storage
  Future<String> uploadProductImage(String productId, File imageFile) async {
    try {
      // Generate a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = '${timestamp}_${path.basenameWithoutExtension(imageFile.path)}$extension';
      
      // Create reference to the file location in Firebase Storage
      final ref = _storage.ref().child('products/$productId/$fileName');
      
      // Upload the file
      final uploadTask = ref.putFile(imageFile);
      
      // Wait for the upload to complete and get the download URL
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Image uploaded successfully. URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Firebase Storage error: $e');
      throw 'Failed to upload image: $e';
    }
  }

  // Upload multiple product images
  Future<List<String>> uploadProductImages(String productId, List<File> imageFiles) async {
    try {
      final uploadTasks = imageFiles.map(
        (file) => uploadProductImage(productId, file)
      );
      
      return await Future.wait(uploadTasks);
    } catch (e) {
      throw 'Failed to upload images: $e';
    }
  }

  // Upload a profile picture to Firebase Storage
  Future<String> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = 'profile_${timestamp}$extension';
      
      // Create reference to the file location
      final ref = _storage.ref().child('users/$userId/profile/$fileName');
      
      // Upload the file
      final uploadTask = ref.putFile(imageFile);
      
      // Get the download URL
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload profile picture: $e';
    }
  }

  // Delete a product image from Firebase Storage
  Future<void> deleteProductImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw 'Failed to delete image: $e';
    }
  }

  // Delete multiple product images
  Future<void> deleteProductImages(List<String> imageUrls) async {
    try {
      final deleteTasks = imageUrls.map(
        (url) => deleteProductImage(url)
      );
      
      await Future.wait(deleteTasks);
    } catch (e) {
      throw 'Failed to delete images: $e';
    }
  }

  // Delete all images in a product folder
  Future<void> deleteProductFolder(String productId) async {
    try {
      final ref = _storage.ref().child('products/$productId');
      final result = await ref.listAll();
      
      // Delete all files in the folder
      await Future.wait(
        result.items.map((item) => item.delete())
      );
      
      // Note: Firebase Storage automatically removes empty folders
    } catch (e) {
      throw 'Failed to delete product folder: $e';
    }
  }

  // Get list of all images in a product folder
  Future<List<String>> getProductImages(String productId) async {
    try {
      final ref = _storage.ref().child('products/$productId');
      final result = await ref.listAll();
      
      // Get download URLs for all images
      final urls = await Future.wait(
        result.items.map((item) => item.getDownloadURL())
      );
      
      return urls;
    } catch (e) {
      throw 'Failed to get product images: $e';
    }
  }

  // Check if an image exists in Firebase Storage
  Future<bool> imageExists(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.getDownloadURL();
      return true;
    } catch (e) {
      return false;
    }
  }
}
