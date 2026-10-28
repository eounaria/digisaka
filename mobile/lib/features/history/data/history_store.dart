import 'package:flutter/foundation.dart';

import 'package:digisaka/shared/models/history_cycle.dart';

/// In-memory store of saved scan cycles, keyed by (line, isoWeek).
/// TODO: persist to local storage / backend so cycles survive a restart.
class HistoryStore extends ChangeNotifier {
  HistoryStore._();

  static final HistoryStore instance = HistoryStore._();

  final List<HistoryCycle> _cycles = [];

  /// All cycles, newest week first.
  List<HistoryCycle> get cycles => List.unmodifiable(_cycles);

  /// Upserts [cycle] keyed by (line, isoWeek). Re-scanning the same line and
  //  week replaces the existing cycle instead of duplicating it.
  void upsertCycle(HistoryCycle cycle) {
    final idx = _cycles.indexWhere(
      (c) => c.line == cycle.line && c.isoWeek == cycle.isoWeek,
    );
    if (idx == -1) {
      _cycles.add(cycle);
    } else {
      _cycles[idx] = cycle;
    }
    _cycles.sort((a, b) => b.isoWeek.compareTo(a.isoWeek));
    // Notify after the current frame so a screen that is still building
    // doesn't get rebuilt mid-build.
    Future.microtask(notifyListeners);
  }

  /// The cycle for (line, isoWeek), or null if none exists.
  HistoryCycle? cycleFor(String line, String isoWeek) {
    try {
      return cyclesForLine(line).firstWhere((c) => c.isoWeek == isoWeek);
    } on StateError {
      return null;
    }
  }

  /// Cycles for [line], newest week first.
  List<HistoryCycle> cyclesForLine(String line) {
    return _cycles
        .where((c) => c.line == line)
        .toList()
      ..sort((a, b) => b.isoWeek.compareTo(a.isoWeek));
  }

  /// The most recent cycle for [line], or null.
  HistoryCycle? lastCycleForLine(String line) {
    final list = cyclesForLine(line);
    return list.isEmpty ? null : list.first;
  }

  /// Removes all cycles for [line].
  void clearLine(String line) {
    _cycles.removeWhere((c) => c.line == line);
    Future.microtask(notifyListeners);
  }
}
