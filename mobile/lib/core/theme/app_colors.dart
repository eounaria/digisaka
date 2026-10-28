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
  static const Color chartBarColor = Color(0xFFBFE3D8); // light-teal rainfall bars
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

  // ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
  // Line Insights redesign tokens (screenshots 3-5)
  // ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈

  /// Infection risk tiles: Low = green, Medium = yellow, High = amber.
  static const Color infectionLowBackground = Color(0xFFECFDF3);
  static const Color infectionLowBorder = Color(0xFF15803D);
  static const Color infectionLowText = Color(0xFF15803D);
  static const Color infectionMediumBackground = Color(0xFFFFF7ED);
  static const Color infectionMediumBorder = Color(0xFFD97706);
  static const Color infectionMediumText = Color(0xFF92400E);
  static const Color infectionHighBackground = Color(0xFFFFF0E0);
  static const Color infectionHighBorder = Color(0xFFE65100);
  static const Color infectionHighText = Color(0xFF9C3B1E);

  /// Progression tiles: Worsening = pink/red, Improving = green, Stable = grey.
  static const Color progressionWorseningBackground = Color(0xFFFDECEA);
  static const Color progressionWorseningBorder = Color(0xFFB3261E);
  static const Color progressionImprovingBackground = Color(0xFFECFDF3);
  static const Color progressionImprovingBorder = Color(0xFF15803D);
  static const Color progressionStableBackground = Color(0xFFF3F4F6);
  static const Color progressionStableBorder = Color(0xFF6B7280);

  /// Canopy check bar: grey track, olive/gold fill, red critical + green target markers.
  static const Color canopyTrackColor = Color(0xFFE3E6E1);
  static const Color canopyFillOliveGold = Color(0xFF8A6A00);
  static const Color canopyCriticalMarker = Color(0xFFB3261E);
  static const Color canopyTargetMarker = Color(0xFF15803D);

  /// Demo banner: amber/yellow background with dark-brown text.
  static const Color demoBannerBackground = Color(0xFFFFF0E0);
  static const Color demoBannerText = Color(0xFF9C3B1E);

  /// Badges used in Why management rows.
  static const Color badgeGreyBackground = Color(0xFFE6E8E4);
  static const Color badgeGreyText = Color(0xFF4B5563);
  static const Color badgeAmberBackground = Color(0xFFFBE9C6);
  static const Color badgeAmberText = Color(0xFF9C3B1E);
  static const Color badgeConcerningBackground = Color(0xFFFADADA);
  static const Color badgeConcerningText = Color(0xFFC62828);

  // ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
  // Treatment decision flow tokens (Weather → Spray log → Fungicides → Decision)
  // ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈

  /// Sample-data demo banner (amber fill, dark-brown text).
  static const Color sampleDataBannerBackground = Color(0xFFFBEFC8);
  static const Color sampleDataBannerText = Color(0xFF6B4A00);

  /// Selected fungicide chip fill (light blue/green).
  static const Color selectedChipBackground = Color(0xFFE3F2FD);
  /// Restricted / red-tint card outline.
  static const Color restrictedOutline = Color(0xFFB3261E);
}
