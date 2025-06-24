import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_n_buy_updated/services/database_service.dart';
import 'package:sell_n_buy_updated/services/data_seeding_service.dart';
import 'package:sell_n_buy_updated/services/auth_service.dart';
import 'package:sell_n_buy_updated/models/user_profile.dart';
import 'package:sell_n_buy_updated/models/product.dart';
import 'package:sell_n_buy_updated/models/activity_log.dart';
import 'package:sell_n_buy_updated/features/authentication/auth_wrapper.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  DatabaseService? _databaseService;
  
  List<UserProfile> _users = [];
  bool _isLoadingUsers = false;
  List<Product> _products = [];
  bool _isLoadingProducts = false;
  List<ActivityLog> _activities = [];
  bool _isLoadingActivities = false;
  DateTime _selectedDate = DateTime.now();
  Stream<List<ActivityLog>>? _activitiesStream;

  // Helper widget to handle both local assets and network images
  Widget _buildProductImage(String imagePath, {double? width, double? height, BoxFit? fit}) {
    // Check if it's a network URL (starts with http/https)
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image: $error');
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.image_not_supported, color: Colors.grey),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else {
      // It's a local asset
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading asset image: $error');
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.image_not_supported, color: Colors.grey),
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initServices();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
      _loadProducts();
      _loadActivities();
    });
  }

  Future<void> _loadActivities() async {
    if (_databaseService == null) return;
    
    setState(() {
      _isLoadingActivities = true;
    });
  }

  Widget _buildActivitiesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity Log',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && picked != _selectedDate) {
                        setState(() {
                          _selectedDate = picked;
                        });
                        _loadActivities();
                      }
                    },
                    icon: Icon(Icons.calendar_today),
                    tooltip: 'Select Date',
                  ),
                  IconButton(
                    onPressed: _loadActivities,
                    icon: Icon(Icons.refresh),
                    tooltip: 'Refresh Activities',
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<ActivityLog>>(
              key: ValueKey('activities_stream_${_selectedDate.toIso8601String()}'),
              stream: _databaseService?.getActivitiesByDateStream(_selectedDate).asBroadcastStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error loading activities',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadActivities,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                final activities = snapshot.data ?? [];
                
                if (activities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No activities found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No activities recorded for ${_selectedDate.toLocal().toString().split(' ')[0]}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _getActivityColor(activity.type),
                              radius: 24,
                              child: Icon(
                                _getActivityIcon(activity.type), 
                                color: Colors.white, 
                                size: 24
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity.typeDisplay,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    activity.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'User: ${_getSellerName(activity.userId)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    'Time: ${_formatActivityTime(activity.timestamp)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
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
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.userRegistration:
        return Colors.green;
      case ActivityType.userLogin:
        return Colors.blue;
      case ActivityType.userDeletion:
        return Colors.red;
      case ActivityType.productListed:
        return Colors.orange;
      case ActivityType.productSold:
        return Colors.purple;
      case ActivityType.productViewed:
        return Colors.teal;
      case ActivityType.productLiked:
        return Colors.pink;
      case ActivityType.productDeletion:
        return Colors.redAccent;
      case ActivityType.messagesSent:
        return Colors.indigo;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.userRegistration:
        return Icons.person_add;  // Person with plus sign for registration
      case ActivityType.userLogin:
        return Icons.login;  // Login arrow icon
      case ActivityType.userDeletion:
        return Icons.person_remove_alt_1;  // Person with minus sign for deletion
      case ActivityType.productListed:
        return Icons.add_box;  // Box with plus sign for new listings
      case ActivityType.productSold:
        return Icons.attach_money;  // Dollar sign for sales
      case ActivityType.productViewed:
        return Icons.visibility;  // Eye icon for views
      case ActivityType.productLiked:
        return Icons.favorite;  // Heart for likes
      case ActivityType.productDeletion:
        return Icons.delete_forever;  // Delete icon for product removal
      case ActivityType.messagesSent:
        return Icons.message;  // Message bubble for communications
    }
  }

  Future<void> _loadProducts() async {
    if (_databaseService == null) return;
    
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final products = await _databaseService!.getAllProductsForAdmin();
      setState(() {
        _products = products;
      });
    } catch (e) {
      print('Error loading products: $e');
    } finally {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _databaseService != null) {
      try {
        await _databaseService!.deleteProductAsAdmin(product.id);
        _loadProducts(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product "${product.title}" deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    }
  }

  Future<void> _updateProductStatus(Product product, ProductStatus newStatus) async {
    try {
      await _databaseService?.updateProductStatus(product.id, newStatus);
      _loadProducts(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product status updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating product status: $e')),
      );
    }
  }

  void _showProductDetails(Product product) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Product Details'),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (product.images.isNotEmpty)
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildProductImage(
                        product.images[0],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                _buildDetailRow('Title', product.title),
                _buildDetailRow('Brand', product.brand),
                _buildDetailRow('Price', product.priceDisplay),
                _buildDetailRow('Type', product.type.displayName),
                _buildDetailRow('Status', product.status.displayName),
                _buildDetailRow('Condition', product.condition.displayName),
                _buildDetailRow('Size', product.size),
                _buildDetailRow('Seller', _getSellerName(product.sellerId)),
                _buildDetailRow('Likes', '${product.likes.length}'),
                _buildDetailRow('Created', product.createdAt.toString()),
                _buildDetailRow('Description', product.description),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _loadProducts,
                icon: Icon(Icons.refresh),
                tooltip: 'Refresh Products',
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Total Products: ${_products.length}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: _isLoadingProducts
                ? Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(
                        child: Text(
                          'No products found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: product.images.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: _buildProductImage(
                                        product.images[0],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                                    ),
                              title: Text(
                                product.title,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.brand),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: product.status == ProductStatus.available
                                              ? Colors.green[100]
                                              : product.status == ProductStatus.sold
                                                  ? Colors.red[100]
                                                  : Colors.orange[100],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          product.status.displayName,
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(product.priceDisplay),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility),
                                        SizedBox(width: 8),
                                        Text('View Details'),
                                      ],
                                    ),
                                  ),
                                  if (product.status != ProductStatus.available)
                                    PopupMenuItem(
                                      value: 'mark_available',
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('Mark as Available'),
                                        ],
                                      ),
                                    ),
                                  if (product.status != ProductStatus.sold)
                                    PopupMenuItem(
                                      value: 'mark_sold',
                                      child: Row(
                                        children: [
                                          Icon(Icons.money, color: Colors.orange),
                                          SizedBox(width: 8),
                                          Text('Mark as Sold'),
                                        ],
                                      ),
                                    ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  switch (value) {
                                    case 'view':
                                      _showProductDetails(product);
                                      break;
                                    case 'mark_available':
                                      _updateProductStatus(product, ProductStatus.available);
                                      break;
                                    case 'mark_sold':
                                      _updateProductStatus(product, ProductStatus.sold);
                                      break;
                                    case 'delete':
                                      _deleteProduct(product);
                                      break;
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _initServices() {
    _databaseService = context.read<DatabaseService>();
  }

  Future<void> _loadUsers() async {
    if (_databaseService == null) return;
    
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final users = await _databaseService!.getAllUsers();
      setState(() {
        _users = users;
      });
    } catch (e) {
      print('Error loading users: $e');
    } finally {
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _deleteUser(UserProfile user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _databaseService != null) {
      try {
        await _databaseService!.deleteUser(user.uid);
        _loadUsers(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${user.name} deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: $e')),
        );
      }
    }
  }

  void _showUserDetails(UserProfile user) {
    final actualListingCount = _getUserListingCount(user.uid);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', user.name),
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Phone', user.phoneNumber ?? 'Not provided'),
              _buildDetailRow('User ID', user.uid),
              _buildDetailRow('Listings', '$actualListingCount'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showUserListings(UserProfile user) {
    final userProducts = _products.where((product) => product.sellerId == user.uid).toList();
    
    showDialog(
      context: context,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final dialogWidth = screenSize.width * 0.9;
        final dialogHeight = screenSize.height * 0.7;
        
        return Dialog(
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${user.name}\'s Listings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Content
                Expanded(
                  child: userProducts.isEmpty
                      ? Center(
                          child: Text(
                            'No listings found for this user',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: userProducts.length,
                          itemBuilder: (context, index) {
                            final product = userProducts[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    // Product Image
                                    Container(
                                      width: 60,
                                      height: 60,
                                      child: product.images.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: _buildProductImage(
                                                product.images[0],
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Icon(Icons.image_not_supported, color: Colors.grey),
                                            ),
                                    ),
                                    SizedBox(width: 12),
                                    
                                    // Product Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            product.brand,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: product.status == ProductStatus.available
                                                      ? Colors.green[100]
                                                      : product.status == ProductStatus.sold
                                                          ? Colors.red[100]
                                                          : Colors.orange[100],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  product.status.displayName,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  product.priceDisplay,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // View Button
                                    IconButton(
                                      icon: Icon(Icons.visibility, color: Colors.blue),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Future.microtask(() {
                                          if (mounted) {
                                            _showProductDetails(product);
                                          }
                                        });
                                      },
                                      tooltip: 'View Details',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                // Footer
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // Helper method to get actual listing count for a user
  int _getUserListingCount(String userId) {
    return _products.where((product) => product.sellerId == userId).length;
  }

  // Helper method to get seller name from user ID
  String _getSellerName(String sellerId) {
    final seller = _users.firstWhere(
      (user) => user.uid == sellerId,
      orElse: () => UserProfile(
        uid: sellerId,
        name: 'Unknown Seller',
        email: '',
        phoneNumber: '',
      ),
    );
    return seller.name;
  }

  // Helper method to format activity timestamp
  String _formatActivityTime(DateTime timestamp) {
    final localTime = timestamp.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localTime);

    if (difference.inDays > 0) {
      return '${localTime.year}-${localTime.month.toString().padLeft(2, '0')}-${localTime.day.toString().padLeft(2, '0')} ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}:${localTime.second.toString().padLeft(2, '0')}';
    } else {
      return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}:${localTime.second.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildUsersTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _loadUsers,
                icon: Icon(Icons.refresh),
                tooltip: 'Refresh Users',
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Total Users: ${_users.length}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: _isLoadingUsers
                ? Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final actualListingCount = _getUserListingCount(user.uid);
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(0xFF004D40), // Dark Green
                                child: Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                user.name,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.email),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.list, size: 16, color: Colors.grey),
                                      SizedBox(width: 4),
                                      Text('$actualListingCount listings'),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility),
                                        SizedBox(width: 8),
                                        Text('View Details'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'listings',
                                    child: Row(
                                      children: [
                                        Icon(Icons.list_alt),
                                        SizedBox(width: 8),
                                        Text('View Listings'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete User', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'view') {
                                    _showUserDetails(user);
                                  } else if (value == 'listings') {
                                    _showUserListings(user);
                                  } else if (value == 'delete') {
                                    _deleteUser(user);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      key: ValueKey<String>('admin_tab_controller'),
      length: 3,
      child: Scaffold(
        key: ValueKey<String>('admin_scaffold'),
        appBar: AppBar(
          title: Text('Admin Panel'),
          backgroundColor: Color(0xFF004D40), // Dark Green
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              tooltip: 'Log Out',
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
                  // Sign out the user and navigate back to AuthWrapper
                  await context.read<AuthService>().signOut();
                  // Clear the entire navigation stack and go back to AuthWrapper
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => AuthWrapper()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            isScrollable: false,
            tabAlignment: TabAlignment.fill,
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Products'),
              Tab(text: 'Activities'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUsersTab(),
            _buildProductsTab(),
            _buildActivitiesTab(),
          ],
        ),
      ),
    );
  }
}
