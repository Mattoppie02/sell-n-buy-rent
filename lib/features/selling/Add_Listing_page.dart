import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:sell_n_buy_updated/models/product.dart';
import 'package:sell_n_buy_updated/services/database_service.dart';
import 'package:sell_n_buy_updated/services/storage_service.dart';
import 'package:sell_n_buy_updated/services/auth_service.dart';
import 'package:sell_n_buy_updated/features/buying/buying_homepage.dart';
import 'package:sell_n_buy_updated/theme/app_theme.dart';

class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  DatabaseService? _databaseService;
  StorageService? _storageService;
  AuthService? _authService;
  final ImagePicker _picker = ImagePicker();

  void _initServices() {
    _databaseService = context.read<DatabaseService>();
    _storageService = context.read<StorageService>();
    _authService = context.read<AuthService>();
  }
  
  List<File> _selectedImages = [];
  ProductCondition? _selectedCondition;
  String? _selectedSize;
  String? _selectedBrand;
  bool _isForSale = false;
  bool _isForRent = false;
  bool _isLoading = false;

  final List<ProductCondition> _conditions = [
    ProductCondition.new_,
    ProductCondition.likeNew,
    ProductCondition.good,
    ProductCondition.fair,
  ];

  final List<String> _sizes = [
    'US 6', 'US 6.5', 'US 7', 'US 7.5', 'US 8', 'US 8.5',
    'US 9', 'US 9.5', 'US 10', 'US 10.5', 'US 11', 'US 11.5',
    'US 12', 'US 12.5', 'US 13', 'US 13.5', 'US 14'
  ];

  final List<String> _brands = [
    'Nike',
    'Adidas',
    'New Balance',
    'Salomon',
    'Puma',
    'Converse',
    'Vans',
    'Jordan',
    'Asics',
    'Reebok',
    'Under Armour',
    'Other'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((image) => File(image.path)).toList();
      });
    }
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      _showErrorDialog('Please add at least one image');
      return;
    }
    if (_selectedCondition == null) {
      _showErrorDialog('Please select a condition');
      return;
    }
    if (_selectedSize == null) {
      _showErrorDialog('Please select a size');
      return;
    }
    if (_selectedBrand == null) {
      _showErrorDialog('Please select a brand');
      return;
    }
    if (!_isForSale && !_isForRent) {
      _showErrorDialog('Please select if the item is for sale or rent');
      return;
    }

    // Initialize services if not already initialized
    if (_databaseService == null || _storageService == null || _authService == null) {
      _initServices();
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check authentication
      final user = _authService!.currentUser;
      if (user == null) {
        throw Exception('Please log in to create a listing');
      }

      print('User authenticated: ${user.uid}');
      print('Starting image upload for ${_selectedImages.length} images');

      // Create a unique product ID for image upload
      final productId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Upload images with better error handling
      List<String> imageUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        try {
          print('Uploading image ${i + 1}/${_selectedImages.length}');
          final url = await _storageService!.uploadProductImage(productId, _selectedImages[i]);
          imageUrls.add(url);
          print('Successfully uploaded image ${i + 1}: $url');
        } catch (e) {
          print('Failed to upload image ${i + 1}: $e');
          throw Exception('Failed to upload image ${i + 1}: $e');
        }
      }

      print('All images uploaded successfully. Creating product...');

      // Create product
      final product = Product(
        id: '', // Will be set by database service
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        type: _isForRent ? ProductType.rent : ProductType.sale,
        images: imageUrls,
        sellerId: user.uid,
        condition: _selectedCondition!,
        size: _selectedSize!,
        brand: _selectedBrand!,
        status: ProductStatus.available,
        createdAt: DateTime.now(),
        likes: [],
      );

      await _databaseService!.createProduct(product);
      print('Product created successfully');

      setState(() {
        _isLoading = false;
      });

      _showSuccessDialog();
    } catch (e) {
      print('Error creating listing: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to create listing: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text(
                'Success!',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
          content: const Text(
            'Your listing has been successfully added and is now live!',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Simply pop back to previous page instead of trying to pop to first route
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'Error',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Add Listing',
          style: AppTheme.headingMedium.copyWith(
            letterSpacing: 1.5,
            color: Colors.green,
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image picker section
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[600]!),
                        ),
                        child: _selectedImages.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: Colors.green,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Add Images',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(8),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedImages[index],
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Item Details Section
                    const Text(
                      'Item Details',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title field
                    Container(
                      height: 56,
                      child: TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Name your listing',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Condition dropdown
                    Container(
                      height: 56,
                      child: DropdownButtonFormField<ProductCondition>(
                        value: _selectedCondition,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Condition',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          isDense: true,
                        ),
                        dropdownColor: Colors.grey[800],
                        items: _conditions.map((condition) {
                          return DropdownMenuItem(
                            value: condition,
                            child: Text(condition.displayName, style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCondition = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a condition';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Size dropdown
                    Container(
                      height: 56,
                      child: DropdownButtonFormField<String>(
                        value: _selectedSize,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Select the shoe size',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          isDense: true,
                        ),
                        dropdownColor: Colors.grey[800],
                        items: _sizes.map((size) {
                          return DropdownMenuItem(
                            value: size,
                            child: Text(size, style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSize = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a size';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Brand dropdown
                    Container(
                      height: 56,
                      child: DropdownButtonFormField<String>(
                        value: _selectedBrand,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Brands',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          isDense: true,
                        ),
                        dropdownColor: Colors.grey[800],
                        items: _brands.map((brand) {
                          return DropdownMenuItem(
                            value: brand,
                            child: Text(brand, style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBrand = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a brand';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description section
                    const Text(
                      'Description (Optional)',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Include any other details helpful to buyers. Or share about the story behind this item!',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Price section
                    const Text(
                      'Price',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sale/Rent toggle buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (!_isForSale) {
                                  _isForSale = true;
                                  _isForRent = false;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isForSale ? Colors.green : Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isForSale ? Colors.green : Colors.grey[600]!,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'For Sale',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (!_isForRent) {
                                  _isForSale = false;
                                  _isForRent = true;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isForRent ? Colors.green : Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isForRent ? Colors.green : Colors.grey[600]!,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'For Rent',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Price input
                    TextFormField(
                      controller: _priceController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Price (RM)',
                        labelStyle: TextStyle(color: Colors.grey[500]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Bottom buttons
                    Row(
                      children: [
                        // Back button
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[600]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.pop(context);
                              }
                            },
                            child: const Text(
                              'Back',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Post button
                        ElevatedButton(
                          onPressed: _submitListing,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Post!',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
