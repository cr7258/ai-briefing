/// User subscription model
class UserSubscription {
  final String id;
  final String userId;
  final String? creemCustomerId;
  final String? creemSubscriptionId;
  final String? productId;
  final String status; // active, trialing, canceled, expired, inactive
  final DateTime? currentPeriodEnd;
  final DateTime? canceledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String subscriptionSource; // 'creem' or 'apple'
  final String? appleOriginalTransactionId;
  final String? revenuecatCustomerId;

  UserSubscription({
    required this.id,
    required this.userId,
    this.creemCustomerId,
    this.creemSubscriptionId,
    this.productId,
    required this.status,
    this.currentPeriodEnd,
    this.canceledAt,
    required this.createdAt,
    required this.updatedAt,
    this.subscriptionSource = 'creem',
    this.appleOriginalTransactionId,
    this.revenuecatCustomerId,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      creemCustomerId: json['creem_customer_id'] as String?,
      creemSubscriptionId: json['creem_subscription_id'] as String?,
      productId: json['product_id'] as String?,
      status: json['status'] as String? ?? 'inactive',
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'] as String)
          : null,
      canceledAt: json['canceled_at'] != null
          ? DateTime.parse(json['canceled_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      subscriptionSource: json['subscription_source'] as String? ?? 'creem',
      appleOriginalTransactionId:
          json['apple_original_transaction_id'] as String?,
      revenuecatCustomerId: json['revenuecat_customer_id'] as String?,
    );
  }

  /// Whether the subscription grants access right now
  bool get isActive {
    if (status == 'active' || status == 'trialing') return true;

    // Canceled but still within billing period
    if (status == 'canceled' && currentPeriodEnd != null) {
      return DateTime.now().isBefore(currentPeriodEnd!);
    }

    return false;
  }

  /// Whether the subscription has been canceled (even if still active)
  bool get isCanceled => status == 'canceled';

  /// Whether the subscription is expired
  bool get isExpired => status == 'expired' || status == 'inactive';

  /// Whether this subscription is from Apple IAP
  bool get isApple => subscriptionSource == 'apple';

  /// Whether this subscription is from Creem
  bool get isCreem => subscriptionSource == 'creem';
}
