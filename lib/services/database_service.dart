import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sell_n_buy_updated/models/product.dart';
import 'package:sell_n_buy_updated/models/user_profile.dart';
import 'package:sell_n_buy_updated/models/activity_log.dart';

// Cache entry class for storing data with expiration
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  static const Duration _cacheDuration = Duration(minutes: 5);

  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool get isExpired => DateTime.now().difference(timestamp) > _cacheDuration;
}

class DatabaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://sell-n-buy-rent-7ca04-default-rtdb.asia-southeast1.firebasedatabase.app'
  );
  
  // Cache duration
  static const cacheDuration = Duration(minutes: 5);
  
  // In-memory cache
  final Map<String, _CacheEntry<UserProfile>> _userCache = {};
  final Map<String, _CacheEntry<Product>> _productCache = {};
  
  // Database references
  DatabaseReference get _users => _database.ref('users');
  DatabaseReference get _products => _database.ref('products');
  DatabaseReference get _activities => _database.ref('activities');

  DatabaseService() {
    // Enable persistence for offline capabilities
    _database.setPersistenceEnabled(true);
    // Keep synced for real-time updates
    _users.keepSynced(true);
    _products.keepSynced(true);
    _activities.keepSynced(true);
  }

  // Validate user profile data
  bool _validateUserProfile(UserProfile profile) {
    return profile.name.isNotEmpty && 
           profile.email.isNotEmpty && 
           profile.uid.isNotEmpty;
  }

  // Validate product data
  bool _validateProduct(Product product) {
    return product.title.isNotEmpty && 
           product.price > 0 &&
           product.sellerId.isNotEmpty &&
           product.brand.isNotEmpty &&
           product.size.isNotEmpty;
  }

  // User Profile Operations
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      if (!_validateUserProfile(profile)) {
        throw Exception('Invalid user profile data');
      }

      await _users.child(profile.uid).set(profile.toMap());
      _userCache[profile.uid] = _CacheEntry(profile);
      
      await logActivity(ActivityLog(
        id: '', // Will be set by Firebase
        type: ActivityType.userRegistration,
        userId: profile.uid,
        description: 'New user registration: ${profile.name}',
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      print('Error creating user profile: $e');
      throw Exception('Failed to create user profile: $e');
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      // Check cache first
      final cachedUser = _userCache[uid];
      if (cachedUser != null && !cachedUser.isExpired) {
        return cachedUser.data;
      }

      final snapshot = await _users.child(uid).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final profile = UserProfile.fromMap(data);
        // Update cache
        _userCache[uid] = _CacheEntry(profile);
        return profile;
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      if (!_validateUserProfile(profile)) {
        throw Exception('Invalid user profile data');
      }

      await _users.child(profile.uid).update(profile.toMap());
      // Update cache
      _userCache[profile.uid] = _CacheEntry(profile);
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Product Operations
  Future<String> createProduct(Product product) async {
    try {
      if (!_validateProduct(product)) {
        throw Exception('Invalid product data');
      }

      final productRef = _products.push();
      final productId = productRef.key!;
      
      final productWithId = product.copyWith(id: productId);
      await productRef.set(productWithId.toMap());
      
      // Update cache
      _productCache[productId] = _CacheEntry(productWithId);
      
      await logActivity(ActivityLog(
        id: '', // Will be set by Firebase
        type: ActivityType.productListed,
        userId: product.sellerId,
        targetId: productId,
        description: 'New product listed: ${product.title}',
        timestamp: DateTime.now(),
      ));
      
      return productId;
    } catch (e) {
      print('Error creating product: $e');
      throw Exception('Failed to create product: $e');
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      if (!_validateProduct(product)) {
        throw Exception('Invalid product data');
      }

      await _products.child(product.id).update(product.toMap());
      // Update cache
      _productCache[product.id] = _CacheEntry(product);
    } catch (e) {
      print('Error updating product: $e');
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _products.child(productId).remove();
      // Remove from cache
      _productCache.remove(productId);
    } catch (e) {
      print('Error deleting product: $e');
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<Product?> getProduct(String productId) async {
    try {
      // Check cache first
      final cachedProduct = _productCache[productId];
      if (cachedProduct != null && !cachedProduct.isExpired) {
        return cachedProduct.data;
      }

      final snapshot = await _products.child(productId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final product = Product.fromMap(data);
        // Update cache
        _productCache[productId] = _CacheEntry(product);
        return product;
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      throw Exception('Failed to get product: $e');
    }
  }

  // Get all products with optional brand filter
  Stream<List<Product>> getAllProducts({String? brandFilter}) {
    return _products.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <Product>[];
      
      final productsMap = Map<String, dynamic>.from(data as Map);
      final products = productsMap.entries.map((entry) {
        final productData = Map<String, dynamic>.from(entry.value as Map);
        productData['id'] = entry.key;
        return Product.fromMap(productData);
      }).toList();

      if (brandFilter != null && brandFilter.isNotEmpty) {
        return products.where((product) => product.brand == brandFilter).toList();
      }
      
      return products;
    });
  }

  // Get available products with optional brand filter
  Stream<List<Product>> getAvailableProducts({String? brandFilter}) {
    return getAllProducts(brandFilter: brandFilter).map((products) {
      return products.where((product) => product.status == ProductStatus.available).toList();
    });
  }

  // Get all unique brands from products
  Stream<List<String>> getAvailableBrands() {
    return getAllProducts().map((products) {
      final brands = products.map((product) => product.brand).toSet().toList();
      brands.sort();
      return brands;
    });
  }

  // Get products available for rent
  Stream<List<Product>> getRentableProducts() {
    return getAvailableProducts().map((products) {
      return products.where((product) => product.type == ProductType.rent).toList();
    });
  }

  // Get user's listings
  Stream<List<Product>> getUserListings(String userId) {
    return getAllProducts().map((products) {
      return products.where((product) => product.sellerId == userId).toList();
    });
  }

  // Like/Unlike a product
  Future<void> toggleProductLike(String productId, String userId) async {
    try {
      if (productId.isEmpty || userId.isEmpty) {
        throw Exception('Invalid product ID or user ID');
      }

      final snapshot = await _products.child(productId).get();
      if (!snapshot.exists) {
        throw Exception('Product not found');
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final product = Product.fromMap(data);
      
      // Verify product is available for liking
      if (product.status != ProductStatus.available) {
        throw Exception('Cannot like a product that is not available');
      }

      final likes = List<String>.from(product.likes);
      final isLiking = !likes.contains(userId);
      
      if (isLiking) {
        likes.add(userId);
      } else {
        likes.remove(userId);
      }

      await _products.child(productId).update({'likes': likes});
      
      // Update cache
      _productCache[productId] = _CacheEntry(product.copyWith(likes: likes));
      
      if (isLiking) {
        await logActivity(ActivityLog(
          id: '', // Will be set by Firebase
          type: ActivityType.productLiked,
          userId: userId,
          targetId: productId,
          description: 'Product liked: ${product.title}',
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      print('Error toggling product like: $e');
      throw Exception('Failed to toggle product like: $e');
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    query = query.toLowerCase();
    
    final snapshot = await _products.get();
    if (!snapshot.exists) return [];

    final productsMap = Map<String, dynamic>.from(snapshot.value as Map);
    return productsMap.entries
        .map((entry) {
          final productData = Map<String, dynamic>.from(entry.value as Map);
          productData['id'] = entry.key;
          return Product.fromMap(productData);
        })
        .where((product) =>
            product.status == ProductStatus.available &&
            (product.title.toLowerCase().contains(query) ||
             product.brand.toLowerCase().contains(query) ||
             product.description.toLowerCase().contains(query)))
        .toList();
  }

  // Admin Operations
  Future<List<UserProfile>> getAllUsers() async {
    final snapshot = await _users.get();
    if (!snapshot.exists) return [];

    final usersMap = Map<String, dynamic>.from(snapshot.value as Map);
    return usersMap.entries.map((entry) {
      final userData = Map<String, dynamic>.from(entry.value as Map);
      userData['uid'] = entry.key;
      return UserProfile.fromMap(userData);
    }).toList();
  }

  Future<void> deleteUser(String uid) async {
    try {
      if (uid.isEmpty) {
        throw Exception('Invalid user ID');
      }

      // Get user's products first
      final products = await getUserListings(uid).first;
      
      // Delete all user's products
      for (final product in products) {
        await deleteProduct(product.id);
      }

      // Delete user profile
      await _users.child(uid).remove();
      
      // Clear from cache
      _userCache.remove(uid);

      await logActivity(ActivityLog(
        id: '',
        type: ActivityType.userDeletion,
        userId: uid,
        description: 'User account deleted',
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  // Admin Product Operations
  Future<List<Product>> getAllProductsForAdmin() async {
    final snapshot = await _products.orderByChild('createdAt').get();
    if (!snapshot.exists) return [];

    final productsMap = Map<String, dynamic>.from(snapshot.value as Map);
    final products = productsMap.entries.map((entry) {
      final productData = Map<String, dynamic>.from(entry.value as Map);
      productData['id'] = entry.key;
      return Product.fromMap(productData);
    }).toList();

    // Sort by createdAt descending
    products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return products;
  }

  Future<void> updateProductStatus(String productId, ProductStatus status) async {
    try {
      if (productId.isEmpty) {
        throw Exception('Invalid product ID');
      }

      final product = await getProduct(productId);
      if (product == null) {
        throw Exception('Product not found');
      }

      // Validate status transition
      if (product.status == ProductStatus.sold && status != ProductStatus.available) {
        throw Exception('Cannot change status of a sold product');
      }

      await _products.child(productId).update({'status': status.index});
      
      // Update cache with new status
      _productCache[productId] = _CacheEntry(product.copyWith(status: status));
      
      // Log appropriate activity based on status change
      ActivityType activityType;
      String description;
      
      switch (status) {
        case ProductStatus.sold:
          activityType = ActivityType.productSold;
          description = 'Product sold: ${product.title}';
          break;
        case ProductStatus.rented:
          activityType = ActivityType.productListed;
          description = 'Product rented: ${product.title}';
          break;
        case ProductStatus.available:
          activityType = ActivityType.productListed;
          description = 'Product status updated to available: ${product.title}';
          break;
      }

      await logActivity(ActivityLog(
        id: '',
        type: activityType,
        userId: product.sellerId,
        targetId: productId,
        description: description,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      print('Error updating product status: $e');
      throw Exception('Failed to update product status: $e');
    }
  }

  Future<void> deleteProductAsAdmin(String productId) async {
    try {
      if (productId.isEmpty) {
        throw Exception('Invalid product ID');
      }

      // Get product first to log the deletion
      final product = await getProduct(productId);
      if (product == null) {
        throw Exception('Product not found');
      }

      await _products.child(productId).remove();
      
      // Clear from cache
      _productCache.remove(productId);

      await logActivity(ActivityLog(
        id: '',
        type: ActivityType.productDeletion,
        userId: product.sellerId,
        targetId: productId,
        description: 'Product deleted by admin: ${product.title}',
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      print('Error deleting product as admin: $e');
      throw Exception('Failed to delete product as admin: $e');
    }
  }

  // Activity Logging Operations
  Future<void> logActivity(ActivityLog activity) async {
    final activityRef = _activities.push();
    final activityWithId = activity.copyWith(id: activityRef.key!);
    await activityRef.set(activityWithId.toMap());
    print('Activity logged: ${activity.type} - ${activity.description}');
  }

  // Get all activities as a real-time stream
  Stream<List<ActivityLog>> getAllActivities() {
    return _activities.orderByChild('timestamp').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <ActivityLog>[];
      
      final activitiesMap = Map<String, dynamic>.from(data as Map);
      final activities = activitiesMap.entries.map((entry) {
        final activityData = Map<String, dynamic>.from(entry.value as Map);
        return ActivityLog.fromMap(activityData, entry.key);
      }).toList();

      // Sort by timestamp descending (most recent first)
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return activities;
    });
  }

  // Get activities by date as a real-time stream
  Stream<List<ActivityLog>> getActivitiesByDateStream(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    return _activities
        .orderByChild('timestamp')
        .startAt(startOfDay.millisecondsSinceEpoch)
        .endAt(endOfDay.millisecondsSinceEpoch)
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null) return <ActivityLog>[];
      
      final activitiesMap = Map<String, dynamic>.from(data as Map);
      final activities = activitiesMap.entries.map((entry) {
        final activityData = Map<String, dynamic>.from(entry.value as Map);
        return ActivityLog.fromMap(activityData, entry.key);
      }).toList();

      // Sort by timestamp descending
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return activities;
    });
  }

  Future<List<ActivityLog>> getActivitiesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final snapshot = await _activities
        .orderByChild('timestamp')
        .startAt(startOfDay.millisecondsSinceEpoch)
        .endAt(endOfDay.millisecondsSinceEpoch)
        .get();

    if (!snapshot.exists) return [];

    final activitiesMap = Map<String, dynamic>.from(snapshot.value as Map);
    final activities = activitiesMap.entries.map((entry) {
      final activityData = Map<String, dynamic>.from(entry.value as Map);
      return ActivityLog.fromMap(activityData, entry.key);
    }).toList();

    // Sort by timestamp descending
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities;
  }

  Future<Map<ActivityType, int>> getActivityStatsByDate(DateTime date) async {
    final activities = await getActivitiesByDate(date);
    
    return {
      for (var type in ActivityType.values)
        type: activities.where((activity) => activity.type == type).length
    };
  }
}
