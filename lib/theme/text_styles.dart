import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  /// Theme-aware header style
  static TextStyle header(BuildContext context) => GoogleFonts.roboto(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Theme-aware subtitle style
  static TextStyle subtitle(BuildContext context) => GoogleFonts.roboto(
    fontSize: 14,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    height: 1.5,
  );

  /// Theme-aware label style
  static TextStyle label(BuildContext context) => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  /// Theme-aware input value style
  static TextStyle inputValue(BuildContext context) => GoogleFonts.roboto(
    fontSize: 16,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Theme-aware button text style
  static TextStyle get buttonText =>
      GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold);
}
