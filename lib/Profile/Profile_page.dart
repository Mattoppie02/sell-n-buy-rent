import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sell_n_buy_updated/Profile/Edit_profile.dart';
import 'package:sell_n_buy_updated/features/buying/buying_homepage.dart';
import 'package:sell_n_buy_updated/features/renting/Renting_page.dart';
import 'package:sell_n_buy_updated/features/selling/Add_Listing_page.dart';
import 'package:sell_n_buy_updated/features/authentication/login_page.dart';
import 'package:sell_n_buy_updated/features/buying/product_detail_page.dart';
import 'package:sell_n_buy_updated/features/selling/manage_listing_page.dart';
import 'package:sell_n_buy_updated/features/home/homepage.dart';
import 'package:sell_n_buy_updated/services/auth_service.dart';
import 'package:sell_n_buy_updated/services/database_service.dart';
import 'package:sell_n_buy_updated/models/product.dart';
import 'package:sell_n_buy_updated/models/user_profile.dart';
import 'package:sell_n_buy_updated/widget/Sneaker_card.dart';
import 'package:sell_n_buy_updated/widget/bottom_navigation.dart';
import 'package:sell_n_buy_updated/theme/app_theme.dart';



class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  // Helper method to display images (handles both local files and assets)
  Widget _buildProductImage(String? imagePath) {
    if (imagePath == null) {
      return _buildPlaceholderImage();
    }

    // Check if it's a local file path (starts with '/' or contains full path)
    if (imagePath.startsWith('/') || imagePath.contains('Documents')) {
      final file = File(imagePath);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              file,
              width: double.infinity,
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
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    } else {
      // It's a network URL
      return Image.network(
        imagePath,
        width: double.infinity,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'ACCOUNT',
                  style: AppTheme.headingMedium.copyWith(
                    letterSpacing: 1.5,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Profile Card with navigation to EditProfilePage
              StreamBuilder<UserProfile?>(
                stream: Stream.fromFuture(
                  context.read<DatabaseService>().getUserProfile(
                    FirebaseAuth.instance.currentUser?.uid ?? '',
                  ),
                ),
                builder: (context, snapshot) {
                  final userProfile = snapshot.data;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfilePage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: AppTheme.cardDecoration,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: userProfile?.photoUrl != null
                                ? NetworkImage(userProfile!.photoUrl!)
                                : null,
                            child: userProfile?.photoUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 35,
                                    color: Colors.grey[600],
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userProfile?.name.toUpperCase() ?? 'Loading...',
                                  style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userProfile?.email ?? '',
                                  style: AppTheme.caption,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Email Subscription Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite_border, color: AppTheme.primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Did you cop what you wanted yet? Dont worry, in here, no raffle, no proxy, easy deal. Just enjoy your snicks!',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Logout Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Log Out'),
                        content: Text('Are you sure you want to log out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: Text('Log Out'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      try {
                        await context.read<AuthService>().signOut();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                          (route) => false,
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error signing out: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

            Text(
              'Listings',
              style: AppTheme.headingMedium.copyWith(
                color: Colors.green, 
              ),
            ),
              const SizedBox(height: 10),

              // User's Listings
              StreamBuilder<List<Product>>(
                stream: context.read<DatabaseService>().getUserListings(
                  FirebaseAuth.instance.currentUser?.uid ?? '',
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Container(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red),
                            SizedBox(height: 8),
                            Text(
                              'Error loading listings',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final userProducts = snapshot.data ?? [];

                  if (userProducts.isEmpty) {
                    return Container(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'No listings yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tap the + button to add your first listing',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: userProducts.length,
                    itemBuilder: (context, index) {
                      final product = userProducts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageListingPage(product: product),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            // boxShadow: [
                            //   BoxShadow(
                            //     color: Colors.grey.shade300,
                            //     blurRadius: 4,
                            //     offset: Offset(0, 2),
                            //   ),
                            // ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: _buildProductImage(product.images.isNotEmpty ? product.images.first : null),
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
                                      Row(
                                        children: [
                                          Text(
                                            'RM ${product.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                              fontSize: 12,
                                            ),
                                          ),
                          if (product.type == ProductType.rent) ...[
                                            SizedBox(width: 4),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'RENT',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(top: 4),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: product.status == ProductStatus.available
                                              ? Colors.green
                                              : product.status == ProductStatus.sold
                                                  ? Colors.red
                                                  : Colors.orange,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          product.status.displayName.toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                  );
                },
              ),
              const SizedBox(height: 80), // Extra space to prevent FAB overlap on last item
            ],
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddListingPage()),
            );
        },
        child: Icon(Icons.add, color: AppTheme.secondaryColor),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Custom Bottom Navigation Bar
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Homepage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => BuyingHomepage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AddListingPage()),
            );
          }
        },
      ),
    );
  }
}
