enum ProductCondition {
  new_,
  likeNew,
  good,
  fair;

  String get displayName {
    switch (this) {
      case ProductCondition.new_:
        return 'New';
      case ProductCondition.likeNew:
        return 'Like New';
      case ProductCondition.good:
        return 'Good';
      case ProductCondition.fair:
        return 'Fair';
    }
  }
}

enum ProductStatus {
  available,
  sold,
  rented;

  String get displayName {
    switch (this) {
      case ProductStatus.available:
        return 'Available';
      case ProductStatus.sold:
        return 'Sold';
      case ProductStatus.rented:
        return 'Rented';
    }
  }
}

enum ProductType {
  sale,
  rent;

  String get displayName {
    switch (this) {
      case ProductType.sale:
        return 'For Sale';
      case ProductType.rent:
        return 'For Rent';
    }
  }
}

class Product {
  final String id;
  final String sellerId;
  final String title;
  final String brand;
  final String description;
  final double price;
  final ProductType type;
  final List<String> images;
  final String size;
  final ProductCondition condition;
  final ProductStatus status;
  final DateTime createdAt;
  final List<String> likes;

  Product({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.brand,
    required this.description,
    required this.price,
    required this.type,
    required this.images,
    required this.size,
    required this.condition,
    this.status = ProductStatus.available,
    DateTime? createdAt,
    List<String>? likes,
  })  : this.createdAt = createdAt ?? DateTime.now(),
        this.likes = likes ?? [];

  // Helper getters for backward compatibility and clarity
  bool get isForSale => type == ProductType.sale;
  bool get isForRent => type == ProductType.rent;
  
  // For rent products, price represents daily rent price
  // For sale products, price represents sale price
  String get priceDisplay {
    if (type == ProductType.rent) {
      return 'RM ${price.toStringAsFixed(2)}/day';
    } else {
      return 'RM ${price.toStringAsFixed(2)}';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'title': title,
      'brand': brand,
      'description': description,
      'price': price,
      'type': type.index,
      'images': images,
      'size': size,
      'condition': condition.index,
      'status': status.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'likes': likes,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    DateTime createdAt;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int);
      } else if (map['createdAt'] is String) {
        createdAt = DateTime.parse(map['createdAt'] as String);
      } else {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    return Product(
      id: map['id'] ?? '',
      sellerId: map['sellerId'] ?? '',
      title: map['title'] ?? '',
      brand: map['brand'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      type: ProductType.values[map['type'] ?? 0],
      images: List<String>.from(map['images'] ?? []),
      size: map['size'] ?? '',
      condition: ProductCondition.values[map['condition'] ?? 0],
      status: ProductStatus.values[map['status'] ?? 0],
      createdAt: createdAt,
      likes: List<String>.from(map['likes'] ?? []),
    );
  }

  Product copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? brand,
    String? description,
    double? price,
    ProductType? type,
    List<String>? images,
    String? size,
    ProductCondition? condition,
    ProductStatus? status,
    DateTime? createdAt,
    List<String>? likes,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      price: price ?? this.price,
      type: type ?? this.type,
      images: images ?? this.images,
      size: size ?? this.size,
      condition: condition ?? this.condition,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
    );
  }
}
