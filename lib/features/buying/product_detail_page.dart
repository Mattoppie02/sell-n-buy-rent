import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sell_n_buy_updated/models/product.dart';
import 'package:sell_n_buy_updated/models/user_profile.dart';
import 'package:sell_n_buy_updated/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  UserProfile? sellerProfile;
  bool isLoadingSeller = true;

  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
  }

  Future<void> _loadSellerProfile() async {
    try {
      final databaseService = context.read<DatabaseService>();
      final profile = await databaseService.getUserProfile(widget.product.sellerId);
      setState(() {
        sellerProfile = profile;
        isLoadingSeller = false;
      });
    } catch (e) {
      setState(() {
        isLoadingSeller = false;
      });
      print('Error loading seller profile: $e');
    }
  }

  Future<void> _openWhatsApp(String action) async {
    if (sellerProfile?.phoneNumber == null) {
      _showErrorDialog('Seller phone number not available');
      return;
    }

    String phoneNumber = sellerProfile!.phoneNumber!;
    // Remove any non-digit characters except +
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Ensure phone number starts with country code
    if (!phoneNumber.startsWith('+')) {
      // Assume Malaysian number if no country code
      if (phoneNumber.startsWith('0')) {
        phoneNumber = '+6${phoneNumber.substring(1)}';
      } else {
        phoneNumber = '+60$phoneNumber';
      }
    }

    String message = '';
    if (action == 'buy') {
      message = 'Hi! I\'m interested in buying your ${widget.product.title} (${widget.product.brand}) for ${widget.product.priceDisplay}. Is it still available?';
    } else if (action == 'rent') {
      message = 'Hi! I\'m interested in renting your ${widget.product.title} (${widget.product.brand}) for ${widget.product.priceDisplay}. Is it still available?';
    }

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';

    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog('Could not open WhatsApp. Please make sure WhatsApp is installed.');
      }
    } catch (e) {
      _showErrorDialog('Error opening WhatsApp: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Helper method to display images (handles Firebase Storage URLs, local files, and assets)
  Widget _buildProductImage(String imagePath, int index) {
    return GestureDetector(
      onTap: () => _openImageGallery(index),
      child: _buildImageWidget(imagePath),
    );
  }

  Widget _buildImageWidget(String imagePath) {
    // Check if it's a local file path (starts with '/' or contains full path)
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
      // It's an asset path
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    } else {
      // It's a network URL (Firebase Storage or any other URL)
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return _buildPlaceholderImage();
        },
      );
    }
  }

  void _openImageGallery(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageGalleryPage(
          images: widget.product.images,
          initialIndex: initialIndex,
          productTitle: widget.product.title,
        ),
      ),
    );
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
        title: Text(
          widget.product.brand.toUpperCase(),
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {
              // TODO: Implement like functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images
            Container(
              height: 300,
              child: PageView.builder(
                itemCount: widget.product.images.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildProductImage(widget.product.images[index], index),
                    ),
                  );
                },
              ),
            ),
            
            SizedBox(height: 20),
            
            // Product Info
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.product.brand.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Price Section
                  Row(
                    children: [
                      Text(
                        widget.product.priceDisplay,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: widget.product.isForRent ? Colors.blue : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Product Details
                  _buildDetailRow('Size', widget.product.size),
                  _buildDetailRow('Condition', widget.product.condition.displayName),
                  _buildDetailRow('Status', widget.product.status.displayName),
                  
                  SizedBox(height: 20),
                  
                  // Seller Info
                  if (isLoadingSeller)
                    Center(child: CircularProgressIndicator())
                  else if (sellerProfile != null) ...[
                    Text(
                      'Seller Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildDetailRow('Seller', sellerProfile!.name),
                    SizedBox(height: 20),
                  ],
                  
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
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  
                  SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: isLoadingSeller || widget.product.status != ProductStatus.available 
                    ? null 
                    : () => _openWhatsApp(widget.product.type == ProductType.rent ? 'rent' : 'buy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.product.status != ProductStatus.available
                      ? Colors.grey
                      : widget.product.isForRent ? Colors.blue : Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.message, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      widget.product.status != ProductStatus.available
                          ? widget.product.status == ProductStatus.sold ? 'Sold Out' : 'Currently Rented'
                          : '${widget.product.isForRent ? 'Rent' : 'Buy'} via WhatsApp',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageGalleryPage extends StatelessWidget {
  final List<String> images;
  final int initialIndex;
  final String productTitle;

  const _ImageGalleryPage({
    required this.images,
    required this.initialIndex,
    required this.productTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          productTitle,
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          String imagePath = images[index];
          ImageProvider imageProvider;
          
          if (imagePath.startsWith('https://')) {
            imageProvider = NetworkImage(imagePath);
          } else if (imagePath.startsWith('/') || imagePath.contains('Documents')) {
            imageProvider = FileImage(File(imagePath));
          } else {
            imageProvider = AssetImage(imagePath);
          }

          return PhotoViewGalleryPageOptions(
            imageProvider: imageProvider,
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(tag: 'image_$index'),
          );
        },
        itemCount: images.length,
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(
            value: event == null
                ? null
                : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
          ),
        ),
        backgroundDecoration: BoxDecoration(color: Colors.black),
        pageController: PageController(initialPage: initialIndex),
      ),
    );
  }
}
