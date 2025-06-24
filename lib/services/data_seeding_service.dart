import 'package:sell_n_buy_updated/models/product.dart';
import 'package:sell_n_buy_updated/services/database_service.dart';

class DataSeedingService {
  final DatabaseService _databaseService = DatabaseService();

  Future<void> seedInitialProducts() async {
    // Sample products based on the existing assets
    final sampleProducts = [
      // Products for sale
      Product(
        id: '',
        sellerId: 'admin',
        title: 'Nike Air Max TN',
        brand: 'Nike',
        description: 'Classic Nike Air Max TN in excellent condition. Perfect for casual wear and sports activities.',
        price: 450.00,
        type: ProductType.sale,
        images: ['assets/images/airmax tn.png'],
        size: '42',
        condition: ProductCondition.likeNew,
      ),
      Product(
        id: '',
        sellerId: 'admin',
        title: 'Adidas Campus',
        brand: 'Adidas',
        description: 'Vintage Adidas Campus sneakers in great condition. A timeless classic.',
        price: 330.00,
        type: ProductType.sale,
        images: ['assets/images/campus.jpg'],
        size: '41',
        condition: ProductCondition.good,
      ),
      Product(
        id: '',
        sellerId: 'admin',
        title: 'New Balance 2002R',
        brand: 'New Balance',
        description: 'Modern New Balance 2002R with premium materials and comfort.',
        price: 380.00,
        type: ProductType.sale,
        images: ['assets/images/2002r.jpg'],
        size: '43',
        condition: ProductCondition.new_,
      ),
      Product(
        id: '',
        sellerId: 'admin',
        title: 'Nike TN Plus',
        brand: 'Nike',
        description: 'Nike TN Plus in pristine condition. Limited edition colorway.',
        price: 520.00,
        type: ProductType.sale,
        images: ['assets/images/tn plus.jpg'],
        size: '42',
        condition: ProductCondition.new_,
      ),
      // Products for rent
      Product(
        id: '',
        sellerId: 'admin',
        title: 'Adidas Samba (Rental)',
        brand: 'Adidas',
        description: 'Classic Adidas Samba football shoes. Perfect for indoor sports. Available for daily rental.',
        price: 35.00, // Daily rental price
        type: ProductType.rent,
        images: ['assets/images/samba.jpg'],
        size: '40',
        condition: ProductCondition.good,
      ),
      Product(
        id: '',
        sellerId: 'admin',
        title: 'New Balance Wolfstone (Rental)',
        brand: 'New Balance',
        description: 'Rugged outdoor sneakers with premium materials. Great for outdoor activities.',
        price: 40.00, // Daily rental price
        type: ProductType.rent,
        images: ['assets/images/wolfstone.jpg'],
        size: '43',
        condition: ProductCondition.good,
      ),
      Product(
        id: '',
        sellerId: 'admin',
        title: 'Adidas Preloved Yellow',
        brand: 'Adidas',
        description: 'Unique yellow Adidas sneakers in good preloved condition.',
        price: 250.00,
        type: ProductType.sale,
        images: ['assets/images/preloved yellow.png'],
        size: '41',
        condition: ProductCondition.fair,
      ),
    ];

    // Add each product to Firestore
    for (final product in sampleProducts) {
      try {
        await _databaseService.createProduct(product);
        print('Added product: ${product.title}');
      } catch (e) {
        print('Error adding product ${product.title}: $e');
      }
    }
  }
}
