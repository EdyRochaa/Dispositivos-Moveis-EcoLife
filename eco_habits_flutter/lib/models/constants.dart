import 'package:flutter/material.dart';

const kGreen = Color(0xFF2E8B3E);
const kGreenDark = Color(0xFF1E6B2E);
const kGreenBar = Color(0xFF4CBA5A);
const kBg = Color(0xFFF5F5F5);
const kCardBg = Colors.white;
const kBorder = Color(0xFFDDDDDD);
const kTextMuted = Color(0xFF666666);

const List<String> kMonths = [
  'JAN','FEV','MAR','ABR','MAI','JUN',
  'JUL','AGO','SET','OUT','NOV','DEZ'
];

const List<double> kBarData = [
  42, 68, 52, 28, 72, 44, 88, 58, 32, 65, 56, 80
];

const Map<String, IconData> kCatIcons = {
  'transporte': Icons.directions_bus,
  'energia': Icons.bolt,
  'reciclagem': Icons.recycling,
  'dieta': Icons.eco,
  'agua': Icons.water_drop,
  'lixo': Icons.delete_outline,
};

const Map<String, String> kCatLabels = {
  'transporte': 'Transporte público',
  'energia': 'Economia de energia',
  'reciclagem': 'Reciclagem',
  'dieta': 'Dieta sustentável',
  'agua': 'Redução de água',
  'lixo': 'Redução de lixo',
};
