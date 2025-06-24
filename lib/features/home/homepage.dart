import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:sell_n_buy_updated/features/buying/buying_homepage.dart';
import 'package:sell_n_buy_updated/features/renting/Renting_page.dart';
import 'package:sell_n_buy_updated/features/selling/Add_Listing_page.dart';
import 'package:sell_n_buy_updated/features/buying/product_detail_page.dart';
import 'package:sell_n_buy_updated/models/product.dart';
import 'package:sell_n_buy_updated/services/database_service.dart';
import 'package:sell_n_buy_updated/widget/bottom_navigation.dart';
import 'package:sell_n_buy_updated/Profile/Profile_page.dart';
import 'package:sell_n_buy_updated/theme/app_theme.dart';

class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late final DatabaseService _databaseService;

  // Helper method to display images (handles local files, assets, and network URLs)
  Widget _buildProductImage(String imagePath, {double? height, double? width, BoxFit? fit}) {
    // Check if it's a local file path (starts with '/' or contains full path)
    if (imagePath.startsWith('/') || imagePath.contains('Documents')) {
      final file = File(imagePath);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              file,
              height: height,
              width: width,
              fit: fit ?? BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderImage(height, width);
              },
            );
          } else {
            return _buildPlaceholderImage(height, width);
          }
        },
      );
    } else if (imagePath.startsWith('assets/')) {
      // It's an asset path
      return Image.asset(
        imagePath,
        height: height,
        width: width,
        fit: fit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage(height, width);
        },
      );
    } else {
      // It's a network URL (Firebase Storage)
      return Image.network(
        imagePath,
        height: height,
        width: width,
        fit: fit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage(height, width);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: height,
            width: width,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildPlaceholderImage(double? height, double? width) {
    return Container(
      height: height ?? 120,
      width: width ?? 120,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_not_supported,
        color: Colors.grey[600],
        size: 40,
      ),
    );
  }

  Widget _getBrandLogo(String brand) {
    // Map brand names to their corresponding asset files
    String getAssetPath(String brandName) {
      switch (brandName.toLowerCase()) {
        case 'nike':
          return 'assets/images/nike.png';
        case 'adidas':
          return 'assets/images/adidas.png';
        case 'puma':
          return 'assets/images/puma.png';
        case 'new balance':
          return 'assets/images/Nb.png';
        case 'asics':
          return 'assets/images/asics.png';
        case 'salomon':
          return 'assets/images/salomon.png';
        default:
          return '';
      }
    }

    final assetPath = getAssetPath(brand);
    
    if (assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to brand name text if logo fails to load
          return Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF50C878).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              brand.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF50C878),
              ),
              textAlign: TextAlign.center,
            ),
          );
        },
      );
    } else {
      // Fallback to brand initial for unknown brands
      return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFF50C878).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          brand.isNotEmpty ? brand.substring(0, 1).toUpperCase() : '?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF50C878),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _databaseService = context.read<DatabaseService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 9, 69, 29), // Emerald green color
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome to",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "SellnBuy/Rent?",
                          style: AppTheme.headingMedium.copyWith(
                            letterSpacing: 3.0,
                            color: Colors.white,
                          ),
                        ),
                        Image.asset(
                          'assets/images/slnb logo.png',
                          height: 80,
                          width: 80,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfilePage()),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "View Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buying Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Buying?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BuyingHomepage()),
                      );
                    },
                    child: Text(
                      "See All",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF50C878), // Emerald green to match banner
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Brand Categories Preview
              StreamBuilder<List<String>>(
                stream: _databaseService.getAvailableBrands(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final allBrands = snapshot.data ?? [];
                  
                  // Filter to only show predefined brands
                  final allowedBrands = ['Nike', 'Adidas', 'Puma', 'New Balance', 'Asics', 'Salomon'];
                  final brands = allBrands.where((brand) => allowedBrands.contains(brand)).toList();

                  if (brands.isEmpty) {
                    return Container(
                      height: 200,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              "Click here\nfor more",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Container(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: brands.length,
                      itemBuilder: (context, index) {
                        final brand = brands[index];
                        return GestureDetector(
                          onTap: () {
                            // Navigate to buying page with brand filter
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BuyingHomepage(initialBrand: brand),
                              ),
                            );
                          },
                          child: Container(
                            width: 160,
                            margin: EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFF50C878), width: 2),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Brand logo
                                Container(
                                  width: 80,
                                  height: 80,
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF50C878).withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: _getBrandLogo(brand),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  brand.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF50C878),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Click here\nfor more",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Renting Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Renting?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RentingShoesPage()),
                      );
                    },
                    child: Text(
                      "See All",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF50C878), // Emerald green to match banner
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Renting Products Preview
              StreamBuilder<List<Product>>(
                stream: _databaseService.getAllProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final products = snapshot.data ?? [];
                  final rentingProducts = products.where((p) => p.type == ProductType.rent).take(3).toList();

                  return Container(
                    height: 200,
                    child: rentingProducts.isEmpty
                        ? Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.home_outlined, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    "No rental products available",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: rentingProducts.length,
                            itemBuilder: (context, index) {
                              final product = rentingProducts[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailPage(product: product),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 160,
                                  margin: EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                          child: _buildProductImage(
                                            product.images.isNotEmpty ? product.images.first : '',
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.brand.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                product.title,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Spacer(),
                                              Text(
                                                product.priceDisplay,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                  fontSize: 12,
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
                            },
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
