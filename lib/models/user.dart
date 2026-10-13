/// Model representing an authenticated user account.
///
/// Encapsulates profile information, access roles, credit balances,
/// and associated subscription tier packages.
library;

/// Represents an authenticated AeroX user profile.
class User {
  /// The unique identifier of the user account.
  final String id;

  /// The primary email address of the user.
  final String email;

  /// The unique handle or username.
  final String username;

  /// The public display name shown in navigation and headers.
  final String displayName;

  /// The access role of the user (e.g. `'user'`, `'admin'`, `'super_admin'`).
  final String role;

  /// The total cumulative credit quota granted to this account.
  final double totalCredits;

  /// The total credits consumed to date.
  final double usedCredits;

  /// The currently available credits for prompts and media generation.
  final double availableCredits;

  /// An optional remote URL pointing to the user's avatar image.
  final String? avatarUrl;

  /// The display title of the user's active subscription tier.
  final String? packageName;

  /// The slug identifier of the user's active subscription tier (e.g. `'pro'`).
  final String? packageSlug;

  /// Whether a Google account is currently connected.
  final bool isGoogleConnected;

  /// The email address of the linked Google account, if connected.
  final String? googleEmail;

  /// Primary authentication provider (`'local'`, `'google'`).
  final String authProvider;

  /// Whether this user account has an active password set.
  final bool hasPassword;

  /// Active subscription status (e.g. `'active'`, `'expired'`, `'canceled'`).
  final String? subscriptionStatus;

  /// Expiration date timestamp of active subscription.
  final String? subscriptionExpiresAt;

  /// Server-calculated human readable remaining duration (e.g. `'28 days remaining'`).
  final String? subscriptionRemaining;

  /// Source of the subscription entitlement (e.g. `'admin'`, `'payment'`, `'redeem'`).
  final String? subscriptionSource;

  /// Creates a new [User] profile instance.
  User({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    required this.role,
    this.totalCredits = 0,
    this.usedCredits = 0,
    this.availableCredits = 0,
    this.avatarUrl,
    this.packageName,
    this.packageSlug,
    this.isGoogleConnected = false,
    this.googleEmail,
    this.authProvider = 'local',
    this.hasPassword = true,
    this.subscriptionStatus,
    this.subscriptionExpiresAt,
    this.subscriptionRemaining,
    this.subscriptionSource,
  });

  /// Deserializes a [User] profile from a backend JSON map.
  factory User.fromJson(Map<String, dynamic> json) {
    final pkg = json['package'] is Map<String, dynamic> ? json['package'] : null;
    final total = (json['totalCredits'] as num?)?.toDouble() ?? 0.0;
    final used = (json['usedCredits'] as num?)?.toDouble() ?? 0.0;
    final available = (json['availableCredits'] as num?)?.toDouble() ?? (total - used);
    final googleConnected = json['isGoogleConnected'] == true ||
        (json['googleId'] != null && json['googleId'].toString().trim().isNotEmpty);

    final entitlement = json['entitlement'] is Map<String, dynamic> ? json['entitlement'] as Map<String, dynamic> : null;
    final sub = entitlement != null && entitlement['subscription'] is Map<String, dynamic>
        ? entitlement['subscription'] as Map<String, dynamic>
        : null;

    final subStatus = json['subscriptionStatus']?.toString() ?? sub?['status']?.toString();
    final subExpiresAt = json['subscriptionExpiresAt']?.toString() ?? sub?['currentPeriodEnd']?.toString();
    final subRemaining = json['subscriptionRemaining']?.toString() ?? sub?['remainingFormatted']?.toString();
    final subSource = sub?['source']?.toString();

    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      totalCredits: total,
      usedCredits: used,
      availableCredits: available > 0 ? available : 0,
      avatarUrl: json['avatarUrl']?.toString(),
      packageName: pkg?['name']?.toString() ?? entitlement?['plan']?['name']?.toString(),
      packageSlug: pkg?['slug']?.toString() ?? entitlement?['plan']?['slug']?.toString(),
      isGoogleConnected: googleConnected,
      googleEmail: json['googleEmail']?.toString() ?? (googleConnected ? json['email']?.toString() : null),
      authProvider: json['authProvider']?.toString() ?? (googleConnected ? 'google' : 'local'),
      hasPassword: json['hasPassword'] == null ? true : (json['hasPassword'] == true),
      subscriptionStatus: subStatus,
      subscriptionExpiresAt: subExpiresAt,
      subscriptionRemaining: subRemaining,
      subscriptionSource: subSource,
    );
  }

  /// Whether the user has an active non-expired subscription.
  bool get isSubscriptionActive => subscriptionStatus == 'active';

  /// Whether the user is currently on an active paid plan tier.
  bool get hasActivePaidPlan =>
      isSubscriptionActive && packageSlug != null && packageSlug != 'free';

  /// Creates a copy of this [User] with the given fields replaced.
  User copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? role,
    double? totalCredits,
    double? usedCredits,
    double? availableCredits,
    String? avatarUrl,
    String? packageName,
    String? packageSlug,
    bool? isGoogleConnected,
    String? googleEmail,
    String? authProvider,
    bool? hasPassword,
    String? subscriptionStatus,
    String? subscriptionExpiresAt,
    String? subscriptionRemaining,
    String? subscriptionSource,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      totalCredits: totalCredits ?? this.totalCredits,
      usedCredits: usedCredits ?? this.usedCredits,
      availableCredits: availableCredits ?? this.availableCredits,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      packageName: packageName ?? this.packageName,
      packageSlug: packageSlug ?? this.packageSlug,
      isGoogleConnected: isGoogleConnected ?? this.isGoogleConnected,
      googleEmail: googleEmail ?? this.googleEmail,
      authProvider: authProvider ?? this.authProvider,
      hasPassword: hasPassword ?? this.hasPassword,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      subscriptionRemaining: subscriptionRemaining ?? this.subscriptionRemaining,
      subscriptionSource: subscriptionSource ?? this.subscriptionSource,
    );
  }

  /// Serializes the user profile into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'displayName': displayName,
      'role': role,
      'totalCredits': totalCredits,
      'usedCredits': usedCredits,
      'availableCredits': availableCredits,
      'avatarUrl': avatarUrl,
      'package': packageName != null ? {'name': packageName, 'slug': packageSlug} : null,
      'isGoogleConnected': isGoogleConnected,
      'googleEmail': googleEmail,
      'authProvider': authProvider,
      'hasPassword': hasPassword,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionExpiresAt': subscriptionExpiresAt,
      'subscriptionRemaining': subscriptionRemaining,
      'subscriptionSource': subscriptionSource,
    };
  }
}
