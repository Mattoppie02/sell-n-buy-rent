import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
// import 'package:sell_n_buy_updated/Profile/Profile_page.dart';
import 'package:sell_n_buy_updated/features/renting/Renting_page.dart';
// import 'package:sell_n_buy_updated/features/selling/Add_Listing_page.dart';
import 'package:sell_n_buy_updated/features/buying/product_detail_page.dart';
// import 'package:sell_n_buy_updated/features/buying/buying_page.dart';
// import 'package:sell_n_buy_updated/features/authentication/login_page.dart';
import 'package:sell_n_buy_updated/models/product.dart';
import 'package:sell_n_buy_updated/services/database_service.dart';
import 'package:sell_n_buy_updated/widget/bottom_navigation.dart';
import 'package:sell_n_buy_updated/theme/app_theme.dart';

class BuyingHomepage extends StatefulWidget {
  final String? initialBrand;
  
  const BuyingHomepage({Key? key, this.initialBrand}) : super(key: key);
  
  @override
  _BuyingHomepageState createState() => _BuyingHomepageState();
}

class _BuyingHomepageState extends State<BuyingHomepage> {
  late DatabaseService _databaseService;
  String? _selectedBrand;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _selectedBrand = widget.initialBrand;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    setState(() {
    });
  }

  Widget _buildBrandLogo(String brand, String logoPath) {
    return StreamBuilder<List<Product>>(
      stream: _databaseService.getAllProducts(),
      builder: (context, snapshot) {
        final hasProducts = snapshot.hasData && 
            snapshot.data!.where((p) => 
              p.type == ProductType.sale && 
              p.brand == brand
            ).isNotEmpty;
        
        return GestureDetector(
          onTap: hasProducts ? () {
            setState(() {
              _selectedBrand = brand == _selectedBrand ? null : brand;
            });
          } : null,
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _selectedBrand == brand ? Colors.grey.shade200 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasProducts 
                  ? (_selectedBrand == brand ? Colors.black : Colors.grey.shade300)
                  : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Opacity(
              opacity: hasProducts ? 1.0 : 0.5,
              child: Image.asset(
                logoPath,
                height: 40,
                width: 40,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Buy Products and Renting? button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Buying Shoes",
                        style: AppTheme.headingMedium.copyWith(
                          letterSpacing: 1.5,
                          color: Colors.green,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green,
                            width: 2.0,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RentingShoesPage()),
                            );
                          },
                          child: Text(
                            "Renting?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search",
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Brand Logos
                  Container(
                    height: 70,
                    margin: EdgeInsets.only(bottom: 20),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildBrandLogo('Nike', 'assets/images/nike.png'),
                        SizedBox(width: 20),
                        _buildBrandLogo('Adidas', 'assets/images/adidas.png'),
                        SizedBox(width: 20),
                        _buildBrandLogo('Puma', 'assets/images/puma.png'),
                        SizedBox(width: 20),
                        _buildBrandLogo('New Balance', 'assets/images/Nb.png'),
                        SizedBox(width: 20),
                        _buildBrandLogo('Salomon', 'assets/images/salomon.png'),
                      ],
                    ),
                  ),

                  // Brand Filter Dropdown
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String>(
                      value: ['Nike', 'Adidas', 'Puma', 'New Balance', 'Salomon'].contains(_selectedBrand) ? _selectedBrand : null,
                      dropdownColor: Colors.black,
                      decoration: InputDecoration(
                        labelText: 'Filter by Brand',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: TextStyle(color: Colors.white),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Brands', style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Nike',
                          child: Text('Nike', style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Adidas',
                          child: Text('Adidas', style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Puma',
                          child: Text('Puma', style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem<String>(
                          value: 'New Balance',
                          child: Text('New Balance', style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Salomon',
                          child: Text('Salomon', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedBrand = value;
                        });
                      },
                    ),
                  ),

                  // Buying Products with Brand Filter and Auth Check
                  StreamBuilder<List<Product>>(
                    stream: _databaseService.getAllProducts(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final products = snapshot.data ?? [];
                      print('Number of products loaded: ${products.length}'); // Debug print
                      
                      // Filter products by type first, then apply brand filter and search query
                      var buyingProducts = products.where((p) => p.type == ProductType.sale).toList();
                      print('Number of sale products: ${buyingProducts.length}'); // Debug print
                      
                      if (_selectedBrand != null) {
                        buyingProducts = buyingProducts.where((p) => p.brand == _selectedBrand).toList();
                        print('Number of filtered products by brand: ${buyingProducts.length}'); // Debug print
                      }
                      
                      if (_searchQuery.isNotEmpty) {
                        buyingProducts = buyingProducts.where((p) => 
                          p.title.toLowerCase().contains(_searchQuery) ||
                          p.brand.toLowerCase().contains(_searchQuery) ||
                          p.description.toLowerCase().contains(_searchQuery)
                        ).toList();
                        print('Number of filtered products by search: ${buyingProducts.length}'); // Debug print
                      }

                      if (buyingProducts.isEmpty) {
                        return Container(
                          height: 400,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey[400]),
                                SizedBox(height: 8),
                                Text(
                                  _searchQuery.isNotEmpty
                                    ? 'No products found for "$_searchQuery"'
                                    : _selectedBrand != null 
                                      ? 'No products found for $_selectedBrand'
                                      : 'No products available for buying',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: buyingProducts.map((product) {
                          return SizedBox(
                            width: (MediaQuery.of(context).size.width - 64) / 2,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailPage(product: product),
                                  ),
                                );
                              },
                              child: shoeCard(
                                product.title,
                                product.priceDisplay,
                                product.images.first,
                                product.status,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget shoeCard(String title, String price, String imagePath, ProductStatus status) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: _buildProductImage(
              imagePath,
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  price,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: status == ProductStatus.available
                        ? Colors.green
                        : status == ProductStatus.sold
                            ? Colors.red
                            : Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.displayName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
