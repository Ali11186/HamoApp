class AppConstants {
  // App info
  static const String appName = '𝐇𝐚𝐦𝐨';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.mohammed.store';
  static const String adminUid = 'QHMQtobX65V64nIyxNUkGSybvEB3';
  static const List<String> cashNumbers = ['01153787930', '01070339762'];

  // Firebase collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  static const String reviewsCollection = 'reviews';
  static const String chatsCollection = 'chats';
  static const String messagesSubcollection = 'messages';
  static const String messagesCollection = 'messages';
  static const String verificationsCollection = 'verifications';
  static const String notificationsCollection = 'notifications';

  // Storage paths
  static const String usersStoragePath = 'users';
  static const String productsStoragePath = 'products';
  static const String chatsStoragePath = 'chats';
  static const String verificationsStoragePath = 'verifications';

  // Chapa
  static const String chapaPublicKey =
      'CHAPUBK_TEST-QmCIBhWYIsdp2tgG0sPr67h5fozBbSz3';
  static const String chapaBaseUrl = 'https://api.chapa.co/v1';
  static const String chapaCheckoutBase =
      'https://api.chapa.co/v1/transaction/initialize?';
  static const String chapaCallbackSuccess =
      'mohammedstore://payment-callback/success';
  static const String chapaCallbackCancel =
      'mohammedstore://payment-callback/cancel';
  static const String chapaReturnUrl =
      'mohammedstore://payment-callback/return';

  // Timeouts
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration requestTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxProductImages = 6;

  // Shipping
  static const double defaultShippingFee = 50.0;
  static const double freeShippingThreshold = 1000.0;

  static double getShippingFee(String city) {
    const fees = {
      'Addis Ababa': 50.0,
      'Adama': 80.0,
      'Hawassa': 120.0,
      'Dire Dawa': 150.0,
      'Bahir Dar': 180.0,
      'Gondar': 200.0,
      'Mekelle': 220.0,
      'Jimma': 130.0,
      'Dessie': 170.0,
    };
    return fees[city] ?? 100.0;
  }

  // Product
  static const double lowStockThreshold = 5.0;
  static const int maxReviewImages = 3;

  // Ethiopian cities
  static const List<String> ethiopianCities = [
    'Addis Ababa',
    'Adama',
    'Hawassa',
    'Dire Dawa',
    'Bahir Dar',
    'Gondar',
    'Mekelle',
    'Jimma',
    'Dessie',
    'Harar',
    'Dilla',
    'Shashemene',
    'Arba Minch',
  ];

  // Product categories: a visible parent group and a stable Firestore value
  // for each selectable child section.
  static const List<String> productCategories = ['اتصالات', 'فودافون', 'فواتير'];

  static const Map<String, String> productCategoryRootValues = {
    'اتصالات': 'Etisalat',
    'فودافون': 'Vodafone',
    'فواتير': 'Bills',
  };

  static const Map<String, Map<String, String>> productSubcategories = {
    'اتصالات': {
      'رصيد صافي': 'Etisalat_balance',
      'حكاية ميكسات (نت ومكالمات)': 'Etisalat_mix',
      'حكاية إنترنت (نت فقط)': 'Etisalat_internet',
      'باقات اتصالات الإضافية': 'Etisalat_extra',
      'كروت الشحن': 'Etisalat_recharge',
    },
    'فودافون': {
      'رصيد صافي': 'Vodafone_balance',
      'باقات فليكس الأساسية': 'Vodafone_flex_basic',
      'باقات الإنترنت الأساسية': 'Vodafone_internet_basic',
      'باقات فليكس الإضافية': 'Vodafone_flex_extra',
      'كروت الشحن': 'Vodafone_recharge',
    },
    'فواتير': {
      'فواتير اتصالات': 'Bills_Etisalat',
      'فواتير فودافون': 'Bills_Vodafone',
    },
  };

  static String get defaultProductCategory =>
      productSubcategories['اتصالات']!['رصيد صافي']!;

  static List<String> get productSubcategoryValues => productSubcategories.values
      .expand((subcategories) => subcategories.values)
      .toList(growable: false);

  static String productCategoryOptionLabel(String value) {
    for (final group in productSubcategories.entries) {
      for (final subsection in group.value.entries) {
        if (subsection.value == value) {
          return '${group.key} • ${subsection.key}';
        }
      }
    }
    return categoryLabel(value);
  }

  /// Converts older Arabic section names to the values already stored in
  /// Firestore. New child sections keep their stable IDs unchanged.
  static String categoryForQuery(String category) {
    for (final group in productSubcategories.values) {
      if (group.values.contains(category)) return category;
    }

    switch (category) {
      case 'اتصالات':
      case 'عروض اتصالات':
        return 'Etisalat';
      case 'فودافون':
      case 'عروض فودافون':
        return 'Vodafone';
      case 'فواتير':
      case 'دفع الفواتير':
        return 'Bills';
      case 'عروض أخرى':
        return 'Other';
      default:
        return category;
    }
  }

  /// Returns all persisted values belonging to a parent group. The legacy
  /// root value is included so existing products remain visible after upgrade.
  static List<String>? categoryQueryValues(String category) {
    if (category == 'الكل' || category.toLowerCase() == 'all') return null;

    for (final group in productSubcategories.entries) {
      final rootValue = productCategoryRootValues[group.key]!;
      final legacyLabel = switch (group.key) {
        'اتصالات' => 'عروض اتصالات',
        'فودافون' => 'عروض فودافون',
        _ => 'دفع الفواتير',
      };
      if (category == group.key ||
          category == rootValue ||
          category == legacyLabel) {
        return [rootValue, ...group.value.values];
      }
    }

    return [categoryForQuery(category)];
  }

  /// A legacy category can still be edited; choose a child in that same group
  /// as the initial selection rather than losing it to the default group.
  static String editableProductCategory(String category) {
    final normalized = categoryForQuery(category);
    if (productSubcategoryValues.contains(normalized)) return normalized;

    for (final group in productSubcategories.entries) {
      if (productCategoryRootValues[group.key] == normalized) {
        return group.value.values.first;
      }
    }
    return normalized;
  }

  static String categoryLabel(String category) {
    for (final group in productSubcategories.entries) {
      for (final subsection in group.value.entries) {
        if (subsection.value == category) {
          return '${group.key} • ${subsection.key}';
        }
      }
    }

    switch (category.toLowerCase()) {
      case 'etisalat':
        return 'اتصالات';
      case 'vodafone':
        return 'فودافون';
      case 'bills':
      case 'bill payment':
        return 'فواتير';
      case 'other':
        return 'عروض أخرى';
      case 'all':
        return 'الكل';
      default:
        return category;
    }
  }
}
