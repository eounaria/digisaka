import 'package:flutter/material.dart';

/// All colors used in Digisaka live here.
/// If the branding changes, you only edit this file.
class AppColors {
  AppColors._(); // prevents creating an object of this class

  static const Color primaryGreen = Color(0xFF1A7A3C); // logo + sign up button
  static const Color darkGreen = Color(0xFF14682F); // pressed state
  static const Color accentYellow = Color(0xFFFFC72C); // login button
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280); // hints, secondary text
  static const Color borderGrey = Color(0xFFD9DDE3); // input outline
  static const Color white = Color(0xFFFFFFFF);

  /// Light grey-green page background; also the bell icon's circle background.
  static const Color pageBackground = Color(0xFFF3F5F2);

  /// Light grey circle behind the home avatar.
  static const Color avatarBackground = Color(0xFFEFEFEF);

  /// Farm Overview stat cards: pale chip background + saturated chip icon.
  static const Color chipBlueBackground = Color(0xFFE3F2FD);
  static const Color chipBlueIcon = Color(0xFF1976D2);
  static const Color chipPurpleBackground = Color(0xFFF3E5F5);
  static const Color chipPurpleIcon = Color(0xFF7B1FA2);
  static const Color chipOrangeBackground = Color(0xFFFFF0E0);
  static const Color chipOrangeIcon = Color(0xFFE65100);

  /// Recent proposals status pills: tinted background + colored text.
  static const Color pillAwaitingDecisionBackground = Color(0xFFFDECEA);
  static const Color pillAwaitingDecisionText = Color(0xFFB3261E);
  static const Color pillAppliedBackground = Color(0xFFECFDF3);
  static const Color pillAppliedText = Color(0xFF15803D);

  /// Week context card chart colors.
  static const Color chartYliLineColor = Color(0xFF8FD6BC); // lighter green YLI line
  static const Color chartBarColor = Color(0xFF2E9E8B); // teal/green rainfall bars
  static const Color chartGridlineColor = Color(0xFFE3EDEA); // faint horizontal gridlines

  /// Mock leaf tile colors.
  static const Color mockLeafTileBackground = Color(0xFFE8F5EC); // pale green mock tile
  static const Color mockLeafTileIconColor = Color(0xFF2E7D4A); // darker green leaf icon

  /// Disabled placeholder field fill.
  static const Color placeholderFieldFill = Color(0xFFF2F6F3); // muted disabled-field fill

  /// Bulk Assessment Result screen — leaf rows.
  static const Color leafRowFill = Color(0xFFF1F3EF); // light grey-green unconfirmed row
  static const Color leafRowConfirmedFill = Color(0xFFE3F3E6); // green tint confirmed row
  static const Color leafRowBorder = Color(0xFFDDE3DB); // unconfirmed row border
  static const Color leafRowConfirmedBorder = Color(0xFF8FCFA0); // confirmed row border

  /// Bulk Assessment Result screen — status / group cards.
  static const Color verificationCardFill = Color(0xFFF8F0D6); // yellow human-verification card
  static const Color verificationCardBorder = Color(0xFFF0DFA0); // yellow card border
  static const Color unvalidatedCardFill = Color(0xFFEDEFEB); // grey unvalidated card fill
  static const Color emptyPhotoTileFill = Color(0xFFE8F5EC); // light green no-photo tile
}
