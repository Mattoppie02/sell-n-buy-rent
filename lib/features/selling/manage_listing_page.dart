import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:sell_n_buy_updated/models/product.dart';
import 'package:sell_n_buy_updated/services/database_service.dart';
import 'package:sell_n_buy_updated/services/storage_service.dart';

class ManageListingPage extends StatefulWidget {
  final Product product;

  const ManageListingPage({super.key, required this.product});

  @override
  State<ManageListingPage> createState() => _ManageListingPageState();
}

class _ManageListingPageState extends State<ManageListingPage> {
  late DatabaseService _databaseService;
  late StorageService _storageService;
  bool _isLoading = false;
  bool _isEditMode = false;

  // Form controllers for edit mode
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  
  final ImagePicker _picker = ImagePicker();
  List<String> _imageUrls = [];
  List<File> _newImages = [];
  ProductCondition? _selectedCondition;
  String? _selectedSize;
  String? _selectedBrand;
  ProductType? _selectedType;
  ProductStatus? _selectedStatus;

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
  void initState() {
    super.initState();
    _databaseService = context.read<DatabaseService>();
    _storageService = context.read<StorageService>();
    
    // Initialize form with current product data
    _titleController = TextEditingController(text: widget.product.title);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _imageUrls = List.from(widget.product.images);
    _selectedCondition = widget.product.condition;
    _selectedSize = widget.product.size;
    _selectedBrand = widget.product.brand;
    _selectedType = widget.product.type;
    _selectedStatus = widget.product.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Widget _buildProductImage(String imagePath) {
    if (imagePath.startsWith('/') || imagePath.contains('Documents')) {
      final file = File(imagePath);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderImage();
              },
            );
          } else {
            return _buildPlaceholderImage();
          }
        },
      );
    } else if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    } else {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.image_not_supported,
        color: Colors.grey[600],
        size: 40,
      ),
    );
  }

  Future<void> _markAsSold() async {
    await _updateProductStatus(ProductStatus.sold);
  }

  Future<void> _markAsRented() async {
    await _updateProductStatus(ProductStatus.rented);
  }

  Future<void> _markAsAvailable() async {
    if (widget.product.status == ProductStatus.sold) {
      // Show confirmation dialog explaining that sold items cannot be marked as available
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Action Not Allowed'),
          content: Text(
            'Sold items cannot be marked as available again. Please create a new listing if you want to sell similar items.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else if (widget.product.status == ProductStatus.rented) {
      // Allow rented items to be marked as available again
      await _updateProductStatus(ProductStatus.available);
    }
  }

  Future<void> _updateProductStatus(ProductStatus status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProduct = widget.product.copyWith(status: status);
      await _databaseService.updateProduct(updatedProduct);
      
      setState(() {
        _selectedStatus = status;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product marked as ${status.displayName.toLowerCase()}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _newImages.addAll(images.map((image) => File(image.path)).toList());
      });
    }
  }

  Future<void> _updateListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<String> finalImageUrls = List.from(_imageUrls);

      // Upload new images if any
      if (_newImages.isNotEmpty) {
        for (int i = 0; i < _newImages.length; i++) {
          final url = await _storageService.uploadProductImage(
            widget.product.id, 
            _newImages[i]
          );
          finalImageUrls.add(url);
        }
      }

      // Create updated product
      final updatedProduct = widget.product.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        type: _selectedType!,
        images: finalImageUrls,
        condition: _selectedCondition!,
        size: _selectedSize!,
        brand: _selectedBrand!,
        status: _selectedStatus!,
      );

      await _databaseService.updateProduct(updatedProduct);

      setState(() {
        _isLoading = false;
        _isEditMode = false;
        _newImages.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Listing updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update listing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.black),
              onPressed: () {
                setState(() {
                  _isEditMode = true;
                });
              },
            ),
          if (_isEditMode)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditMode = false;
                  _newImages.clear();
                });
              },
              child: Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _isEditMode
              ? _buildEditMode()
              : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image carousel
          Container(
            height: 300,
            child: PageView.builder(
              itemCount: widget.product.images.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildProductImage(widget.product.images[index]),
                  ),
                );
              },
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedStatus == ProductStatus.available
                        ? Colors.green
                        : _selectedStatus == ProductStatus.sold
                            ? Colors.red
                            : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _selectedStatus?.displayName.toUpperCase() ?? 'UNKNOWN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                
                // Brand
                Text(
                  widget.product.brand.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                
                // Title
                Text(
                  widget.product.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                
                // Price
                Text(
                  widget.product.priceDisplay,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 16),
                
                // Product details
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem('Size', widget.product.size),
                    ),
                    Expanded(
                      child: _buildDetailItem('Condition', widget.product.condition.displayName),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Description
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.product.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32),
                
                // Action button based on product type and status
                if (_selectedStatus == ProductStatus.available) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.product.type == ProductType.sale ? _markAsSold : _markAsRented,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.product.type == ProductType.sale ? Colors.red : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        widget.product.type == ProductType.sale ? 'Mark as Sold' : 'Mark as Rented',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ] else if (_selectedStatus == ProductStatus.rented) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _markAsAvailable,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Mark as Available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ] else if (_selectedStatus == ProductStatus.sold) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Text(
                      'Sold items cannot be marked as available',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Images
            Text(
              'Current Images',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imageUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 120,
                    margin: EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 120,
                            height: 120,
                            child: _buildProductImage(_imageUrls[index]),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _imageUrls.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),

            // Add new images
            if (_newImages.isNotEmpty) ...[
              Text(
                'New Images to Add',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _newImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 120,
                      margin: EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _newImages[index],
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _newImages.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
            ],

            // Add images button
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, color: Colors.grey[600], size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Add More Images',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Title field
            Text(
              'Title',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Product title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Brand dropdown
            Text(
              'Brand',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedBrand,
              decoration: InputDecoration(
                hintText: 'Select brand',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _brands.map((brand) {
                return DropdownMenuItem(
                  value: brand,
                  child: Text(brand),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBrand = value;
                });
              },
            ),
            SizedBox(height: 16),

            // Size dropdown
            Text(
              'Size',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSize,
              decoration: InputDecoration(
                hintText: 'Select size',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _sizes.map((size) {
                return DropdownMenuItem(
                  value: size,
                  child: Text(size),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSize = value;
                });
              },
            ),
            SizedBox(height: 16),

            // Condition dropdown
            Text(
              'Condition',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<ProductCondition>(
              value: _selectedCondition,
              decoration: InputDecoration(
                hintText: 'Select condition',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _conditions.map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: Text(condition.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCondition = value;
                });
              },
            ),
            SizedBox(height: 16),

            // Type selection
            Text(
              'Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedType = ProductType.sale;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedType == ProductType.sale ? Colors.green : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedType == ProductType.sale ? Colors.green : Colors.grey[400]!,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'For Sale',
                          style: TextStyle(
                            color: _selectedType == ProductType.sale ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedType = ProductType.rent;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedType == ProductType.rent ? Colors.green : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedType == ProductType.rent ? Colors.green : Colors.grey[400]!,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'For Rent',
                          style: TextStyle(
                            color: _selectedType == ProductType.rent ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Price field
            Text(
              'Price',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter price',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixText: 'RM ',
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
            SizedBox(height: 16),

            // Description field
            Text(
              'Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Product description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 32),

            // Update button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Update Listing',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
