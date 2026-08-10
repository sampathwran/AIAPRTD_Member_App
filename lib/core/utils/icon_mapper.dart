import 'package:flutter/material.dart';

class IconMapper {
  static IconData getIcon(String iconName) {
    switch (iconName) {
      case 'phone_android':
      case 'phone_android_rounded':
        return Icons.phone_android_rounded;
      case 'shopping_cart':
      case 'shopping_cart_rounded':
        return Icons.shopping_cart_rounded;
      case 'flight_takeoff':
      case 'flight_takeoff_rounded':
        return Icons.flight_takeoff_rounded;
      case 'receipt_long':
      case 'receipt_long_rounded':
        return Icons.receipt_long_rounded;
      case 'local_parking':
      case 'local_parking_rounded':
        return Icons.local_parking_rounded;
      case 'account_balance_wallet':
      case 'account_balance_wallet_rounded':
        return Icons.account_balance_wallet_rounded;
      case 'storefront':
      case 'storefront_rounded':
        return Icons.storefront_rounded;
      case 'local_car_wash':
      case 'local_car_wash_rounded':
        return Icons.local_car_wash_rounded;
      case 'settings_suggest':
      case 'settings_suggest_rounded':
        return Icons.settings_suggest_rounded;
      case 'apps':
      case 'apps_rounded':
        return Icons.apps_rounded;
      case 'build':
      case 'build_circle_rounded':
        return Icons.build_circle_rounded;
      default:
        return Icons.apps_rounded;
    }
  }

  static Color getColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.tryParse(hexColor, radix: 16) ?? 0xFF2196F3);
  }
}
