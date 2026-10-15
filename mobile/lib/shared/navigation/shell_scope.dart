import 'package:flutter/material.dart';

/// An InheritedWidget that provides access to the tab change function
/// from anywhere in the widget tree (specifically for use in the Scan tab).
class ShellScope extends InheritedWidget {
  final void Function(int tab) changeTab;

  const ShellScope({
    super.key,
    required this.changeTab,
    required super.child,
  });

  /// Returns the nearest [ShellScope] ancestor, or null if none exists.
  static ShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellScope>();
  }

  @override
  bool updateShouldNotify(covariant ShellScope oldWidget) =>
      oldWidget.changeTab != changeTab;
}