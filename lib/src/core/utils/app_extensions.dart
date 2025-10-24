import 'package:flutter/material.dart';

extension StringExtensions on String {
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  bool get isValidPassword {
    return length >= 8;
  }

  String get capitalizeFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String get truncateWithEllipsis {
    if (length <= 50) return this;
    return '${substring(0, 47)}...';
  }
}

extension ContextExtensions on BuildContext {
  bool get isKeyboardOpen {
    return MediaQuery.of(this).viewInsets.bottom > 0;
  }

  double get screenHeight {
    return MediaQuery.of(this).size.height;
  }

  double get screenWidth {
    return MediaQuery.of(this).size.width;
  }

  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}

extension DateTimeExtensions on DateTime {
  String get timeAgo {
    final difference = DateTime.now().difference(this);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String get formattedDate {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }

  String get formattedDateTime {
    return '$formattedDate ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}