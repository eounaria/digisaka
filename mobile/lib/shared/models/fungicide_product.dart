import 'package:digisaka/shared/models/leaf_assessment.dart';

/// A single fungicide product (mock data; TODO: backend).
class FungicideProduct {
  final String name;              // e.g. "Mancozeb 80 WP"
  final String formulation;       // e.g. "Mancozeb 80 WP"
  final String? manufacturer;
  final double price;
  final String priceUnit;         // e.g. "kg" / "L"
  final String fracCode;          // e.g. "M03"
  final String mode;              // "Contact" / "Systemic"
  final String activeIngredient;
  final String chemicalGroup;
  final String mobility;          // e.g. "Contact"
  final String rate;              // e.g. "2 kg/ha in water"
  final String rainfast;          // e.g. "4 hours"
  final String interval;          // e.g. "7 days"
  final List<String> eligibilityLabels;
  final List<String> badges;      // short badge labels, e.g. ["Recommended"]

  const FungicideProduct({
    required this.name,
    required this.formulation,
    this.manufacturer,
    required this.price,
    required this.priceUnit,
    required this.fracCode,
    required this.mode,
    required this.activeIngredient,
    required this.chemicalGroup,
    required this.mobility,
    required this.rate,
    required this.rainfast,
    required this.interval,
    required this.eligibilityLabels,
    this.badges = const [],
  });
}

/// One fungicide option presented to the user (recommended / eligible / excluded).
class FungicideOption {
  final List<FungicideProduct> products;
  final bool recommended;
  final bool eligible;
  final bool excluded;
  final String reason;
  final String? caution;
  final String? priceConcern;

  const FungicideOption({
    required this.products,
    this.recommended = false,
    this.eligible = false,
    this.excluded = false,
    required this.reason,
    this.caution,
    this.priceConcern,
  });
}

/// A restricted FRAC group with the reason it blocks today's recommendation.
/// `code` is the full label (e.g. "FRAC 3") and is never split into "FRAC" + "3".
class RestrictedGroup {
  final String code;   // e.g. "FRAC 3"
  final String reason; // e.g. "Used in 2 consecutive cycles"

  const RestrictedGroup({required this.code, required this.reason});
}

/// One historical spray entry for the spray-log timeline.
class SprayLogEntry {
  final DateTime date;
  final String product;
  final String productType;   // "Systemic" / "Contact"
  final String fracCode;
  final bool restricted;

  const SprayLogEntry({
    required this.date,
    required this.product,
    required this.productType,
    required this.fracCode,
    required this.restricted,
  });
}

/// Weather snapshot driving the infection-risk card.
class WeatherSnapshot {
  final double rainfallMm;          // mm / 7 days
  final double humidityPct;         // % average
  final double leafMoistureHours;   // hours / day
  final List<double> fiveDayRainMm; // Mon..Fri
  final String riskLevel;           // "Low" / "Moderate" / "High"

  const WeatherSnapshot({
    required this.rainfallMm,
    required this.humidityPct,
    required this.leafMoistureHours,
    required this.fiveDayRainMm,
    required this.riskLevel,
  });

  int get rainDays => fiveDayRainMm.where((r) => r > 0).length;
}

/// Mock provider for the whole treatment decision flow.
class TreatmentDecisionData {
  final String line;
  final String isoWeek;
  final List<LeafAssessment> leaves;
  final WeatherSnapshot weather;
  final List<SprayLogEntry> sprayLog;
  final List<RestrictedGroup> restrictedFracGroups;
  final FungicideOption recommended;
  final List<FungicideOption> eligible;
  final List<FungicideOption> excluded;
  final FungicideProduct? selectedProduct;

  const TreatmentDecisionData({
    required this.line,
    required this.isoWeek,
    required this.leaves,
    required this.weather,
    required this.sprayLog,
    required this.restrictedFracGroups,
    required this.recommended,
    required this.eligible,
    required this.excluded,
    this.selectedProduct,
  });

  /// Mock June 2026 data keyed by line/week (TODO: replace with backend).
  static TreatmentDecisionData mockDecisionFor(
    String line,
    String isoWeek,
    List<LeafAssessment> leaves,
  ) {
    final weather = const WeatherSnapshot(
      rainfallMm: 42,
      humidityPct: 88,
      leafMoistureHours: 11,
      fiveDayRainMm: <double>[2, 8, 12, 0, 10],
      riskLevel: 'High',
    );

    final sprayLog = <SprayLogEntry>[
      SprayLogEntry(
        date: DateTime(2026, 10, 14),
        product: 'Propiconazole',
        productType: 'Systemic',
        fracCode: 'FRAC 3',
        restricted: true,
      ),
      SprayLogEntry(
        date: DateTime(2026, 9, 29),
        product: 'Propiconazole',
        productType: 'Systemic',
        fracCode: 'FRAC 3',
        restricted: true,
      ),
      SprayLogEntry(
        date: DateTime(2026, 9, 15),
        product: 'Mancozeb',
        productType: 'Contact',
        fracCode: 'FRAC M03',
        restricted: false,
      ),
      SprayLogEntry(
        date: DateTime(2026, 9, 1),
        product: 'Azoxystrobin',
        productType: 'Systemic',
        fracCode: 'FRAC 11',
        restricted: true,
      ),
    ];

    final mancozeb = FungicideProduct(
      name: 'Mancozeb',
      formulation: 'Mancozeb 80 WP',
      price: 1270,
      priceUnit: 'per kg',
      fracCode: 'M03',
      mode: 'Contact',
      activeIngredient: 'Mancozeb',
      chemicalGroup: 'Dithiocarbamate',
      mobility: 'Contact',
      rate: '2 kg/ha in water',
      rainfast: '4 hours',
      interval: '7 days',
      eligibilityLabels: const ['Passed'],
      badges: const ['Recommended'],
    );
    final chlorothalonil = FungicideProduct(
      name: 'Chlorothalonil',
      formulation: 'Chlorothalonil 720 SC',
      price: 1100,
      priceUnit: 'per kg',
      fracCode: 'M05',
      mode: 'Contact',
      activeIngredient: 'Chlorothalonil',
      chemicalGroup: 'Chloronitrile',
      mobility: 'Contact',
      rate: '–',
      rainfast: '–',
      interval: '–',
      eligibilityLabels: const ['Eligible'],
      badges: const [],
    );
    final chlorothalonilL = FungicideProduct(
      name: 'Chlorothalonil',
      formulation: 'Chlorothalonil 720 SC',
      price: 1780,
      priceUnit: 'per L',
      fracCode: 'M05',
      mode: 'Contact',
      activeIngredient: 'Chlorothalonil',
      chemicalGroup: 'Chloronitrile',
      mobility: 'Contact',
      rate: '–',
      rainfast: '–',
      interval: '–',
      eligibilityLabels: const ['Eligible'],
      badges: const [],
    );

    final recommended = FungicideOption(
      products: [mancozeb, chlorothalonil],
      recommended: true,
      eligible: true,
      reason: 'Protect young leaves and remove heavily infected leaves. '
          'Reassess the week of June 15.',
      caution:
          'This combination is recommended. Caution: used 2 times this season, 1 left.',
    );
    final eligible = FungicideOption(
      products: [chlorothalonilL],
      eligible: true,
      reason: 'Chlorothalonil 720 SC is eligible.',
      priceConcern: 'Price concern: about 40% above the top pick.',
    );
    final excluded = FungicideOption(
      products: [chlorothalonilL],
      excluded: true,
      reason: 'Tilt 250 EC (FRAC 3), Amistar (FRAC 11), Opus 12.5 SC (FRAC 3)',
    );

    return TreatmentDecisionData(
      line: line,
      isoWeek: isoWeek,
      leaves: leaves,
      weather: weather,
      sprayLog: sprayLog,
      restrictedFracGroups: const [
        RestrictedGroup(code: 'FRAC 3', reason: 'Used in 2 consecutive cycles'),
        RestrictedGroup(code: 'FRAC 11', reason: 'Season cap reached'),
      ],
      recommended: recommended,
      eligible: <FungicideOption>[eligible],
      excluded: <FungicideOption>[excluded],
      selectedProduct: mancozeb,
    );
  }
}
