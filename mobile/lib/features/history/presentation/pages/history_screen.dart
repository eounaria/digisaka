import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Simple model for one bulk record (replace with your real data later).
class BulkRecord {
  final String name;
  final String date;
  final int leavesScanned;
  final String status;

  const BulkRecord({
    required this.name,
    required this.date,
    required this.leavesScanned,
    required this.status,
  });
}

class HistoryScreen extends StatefulWidget {
  /// Called when the close (X) button is tapped. MainShell switches to Home.
  final VoidCallback? onGoHome;

  const HistoryScreen({super.key, this.onGoHome});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Empty for now -> shows the "no bulk assessments" message.
  // Fill this list with real data later.
  final List<BulkRecord> _records = [];

  // Ask the MainShell to switch back to the Home tab.
  void _goHome() => widget.onGoHome?.call();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F2),
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent bulk assessments grouped by plant, bulk ID, date, and Black Sigatoka stage.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textGrey,
                  height: 1.4,
                ),
              ),
              Expanded(
                child: _records.isEmpty ? _buildEmptyState() : _buildList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top bar: "Bulk Recent Scanned" title on the left, close (X) button on the right.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      title: const Text(
        'Bulk Recent Scanned',
        style: TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFF3F5F2),
            child: IconButton(
              icon: const Icon(Icons.close, color: AppColors.primaryGreen, size: 20),
              onPressed: _goHome,
            ),
          ),
        ),
      ],
    );
  }

  /// Centered message shown when there are no bulk assessments yet.
  Widget _buildEmptyState() {
    return const Align(
      alignment: Alignment(0, -0.6),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          'No bulk assessments have been completed yet. Run a bulk assessment to see it here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textGrey,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  /// Simple list used once there are records.
  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 16),
      itemCount: _records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = _records[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${r.date} · ${r.leavesScanned} leaves',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              Text(
                r.status,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}