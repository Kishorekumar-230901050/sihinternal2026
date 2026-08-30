import 'package:flutter/widgets.dart';

class Validators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static FormFieldValidator<String> minLength(int min) {
    return (String? value) {
      if (value == null || value.trim().length < min) {
        return 'Minimum $min characters required';
      }
      return null;
    };
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? employeeId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Employee ID is required';
    }
    return null;
  }
}
