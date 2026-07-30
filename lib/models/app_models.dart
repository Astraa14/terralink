import 'package:flutter/material.dart';

class SensorLog {
  final String timeLabel;
  final double value;
  final String status;

  SensorLog({
    required this.timeLabel,
    required this.value,
    required this.status,
  });
}

class AutomationRule {
  final String id;
  final String title;
  final String description;
  bool isEnabled;
  final IconData icon;
  final Color activeColor;

  AutomationRule({
    required this.id,
    required this.title,
    required this.description,
    this.isEnabled = true,
    required this.icon,
    required this.activeColor,
  });
}

class UserProfile {
  final String uid;
  final String displayName;
  final String? email;
  final String? photoUrl;

  UserProfile({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
  });
}
