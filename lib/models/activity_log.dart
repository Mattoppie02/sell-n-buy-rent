enum ActivityType {
  userRegistration,
  userLogin,
  userDeletion,
  productListed,
  productSold,
  productViewed,
  productLiked,
  productDeletion,
  messagesSent
}

class ActivityLog {
  final String id;
  final ActivityType type;
  final String userId;
  final String? targetId; // Could be productId, messageId, etc.
  final String description;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.type,
    required this.userId,
    this.targetId,
    required this.description,
    required this.timestamp,
  });

  factory ActivityLog.fromMap(Map<String, dynamic> data, String id) {
    DateTime timestamp;
    if (data['timestamp'] != null) {
      if (data['timestamp'] is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
      } else if (data['timestamp'] is String) {
        timestamp = DateTime.parse(data['timestamp'] as String);
      } else {
        timestamp = DateTime.now();
      }
    } else {
      timestamp = DateTime.now();
    }

    // Handle both old format (ActivityType.enumName) and new format (enumName)
    String typeString = data['type'] ?? '';
    if (typeString.startsWith('ActivityType.')) {
      typeString = typeString.substring('ActivityType.'.length);
    }
    
    ActivityType activityType;
    try {
      activityType = ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == typeString,
      );
    } catch (e) {
      print('Failed to parse activity type: ${data['type']}, defaulting to productViewed');
      activityType = ActivityType.productViewed;
    }

    return ActivityLog(
      id: id,
      type: activityType,
      userId: data['userId'] ?? '',
      targetId: data['targetId'],
      description: data['description'] ?? '',
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'userId': userId,
      'targetId': targetId,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  ActivityLog copyWith({
    String? id,
    ActivityType? type,
    String? userId,
    String? targetId,
    String? description,
    DateTime? timestamp,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      targetId: targetId ?? this.targetId,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  String get typeDisplay {
    switch (type) {
      case ActivityType.userRegistration:
        return 'New Registration';
      case ActivityType.userLogin:
        return 'User Login';
      case ActivityType.userDeletion:
        return 'User Deletion';
      case ActivityType.productListed:
        return 'Product Listed';
      case ActivityType.productSold:
        return 'Product Sold';
      case ActivityType.productViewed:
        return 'Product Viewed';
      case ActivityType.productLiked:
        return 'Product Liked';
      case ActivityType.productDeletion:
        return 'Product Deleted';
      case ActivityType.messagesSent:
        return 'Message Sent';
    }
  }
}
