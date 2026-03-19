import 'package:flutter/material.dart';

class NavigationItem {
  final String title;
  final String description;
  final IconData icon;
  
  // CRITICAL CHANGE: This property now holds the string identifier 
  // (e.g., '/shipments_fridges') used for named navigation in main.dart.
  final String routeName; 
  
  final Color color;

  const NavigationItem({
    required this.title,
    required this.description,
    required this.icon,
    // The parameter name matches the property
    required this.routeName, 
    this.color = Colors.blue, // Default color
  });
}