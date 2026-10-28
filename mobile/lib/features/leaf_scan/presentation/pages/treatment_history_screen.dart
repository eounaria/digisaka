import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:digisaka/shared/models/treatment_history.dart';
import 'package:digisaka/shared/models/leaf_assessment.dart';
import 'package:digisaka/features/leaf_scan/presentation/pages/treatment_proposal_screen.dart';

const Color _kBorder = Color(0xFFE3E8E1);

/// Screen for collecting treatment history information.
///
/// The UI is restyled per the Figma "Treatment History" frame: a header card
/// with the leaf logo, three selectable radio cards, and both follow-up fields
/// that are always visible (enabled only when "Yes" is selected). The business
/// logic and the [TreatmentHistory] result are unchanged.
class TreatmentHistoryScreen extends StatefulWidget {
  /// Called when Continue is pressed. If null, the screen pushes a
  /// [TreatmentProposalScreen] with the collected history.
  final ValueChanged<TreatmentHistory>? onContinue;
  final List<LeafAssessment>? leaves;
  final String? bulkId;
  final String? line;
  final String? isoWeek;

  const TreatmentHistoryScreen({
    super.key,
    this.onContinue,
    this.leaves,
    this.bulkId,
    this.line,
    this.isoWeek,
  });

  @override
  State<TreatmentHistoryScreen> createState() => _TreatmentHistoryScreenState();
}

class _TreatmentHistoryScreenState extends State<TreatmentHistoryScreen> {
  // 0 = Yes, 1 = No, 2 = Not sure, -1 = nothing selected
  int _selectedOption = -1;

  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _typeController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    if (_selectedOption == -1) return false;
    if (_selectedOption == 0) {
      return _typeController.text.trim().isNotEmpty && _selectedDate != null;
    }
    return true;
  }

  void _onContinuePressed() {
    if (!_canContinue) return;

    final result = TreatmentHistory(
      answer: const [
        'Yes, I have treated it',
        'No, I have not treated it',
        "I'm not sure",
      ][_selectedOption],
      treatmentType: _selectedOption == 0 ? _typeController.text.trim() : null,
      treatmentDate: _selectedOption == 0 ? _selectedDate : null,
    );

    if (widget.onContinue != null) {
      widget.onContinue!(result);
    } else {
      _goToProposal(result);
    }
  }

  void _goToProposal(TreatmentHistory result) {
    if (widget.leaves == null ||
        widget.bulkId == null ||
        widget.line == null ||
        widget.isoWeek == null) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TreatmentProposalScreen(
          leaves: widget.leaves!,
          bulkId: widget.bulkId!,
          line: widget.line!,
          isoWeek: widget.isoWeek!,
          treatmentHistory: result,
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now, // a previous treatment can't be in the future
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final yes = _selectedOption == 0;
    final enabled = _canContinue;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card: leaf logo + title + X close.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: AppColors.primaryGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Treatment History',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Have you treated this plant recently?',
                style: TextStyle(fontSize: 15, color: AppColors.textGrey),
              ),
              const SizedBox(height: 16),

              _buildRadioCard('Yes, I have treated it', 0),
              const SizedBox(height: 12),
              _buildRadioCard('No, I have not treated it', 1),
              const SizedBox(height: 12),
              _buildRadioCard("I'm not sure", 2),

              const SizedBox(height: 24),
              const _FieldLabel('WHAT TYPE OF TREATMENT WAS LAST USED?'),
              const SizedBox(height: 8),
              TextField(
                controller: _typeController,
                onChanged: (_) => setState(() {}), // re-check Continue
                enabled: yes,
                decoration: _inputDecoration(hint: 'e.g., oil', enabled: yes),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('APPROXIMATE DATE OF PREVIOUS TREATMENT'),
              const SizedBox(height: 8),
              TextField(
                controller: _dateController,
                readOnly: true,
                onTap: yes ? _selectDate : null,
                enabled: yes,
                decoration: _inputDecoration(
                  hint: 'mm/dd/yyyy',
                  enabled: yes,
                  suffix: const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),

              const SizedBox(height: 28),
              _buildContinueButton(enabled),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffix, bool enabled = true}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: enabled ? AppColors.white : AppColors.placeholderFieldFill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(_kBorder),
      enabledBorder: border(enabled ? _kBorder : AppColors.textGrey.withValues(alpha: 0.5)),
      focusedBorder: border(AppColors.primaryGreen, 2),
      disabledBorder: border(AppColors.textGrey.withValues(alpha: 0.5)),
    );
  }

  Widget _buildContinueButton(bool enabled) {
    return GestureDetector(
      onTap: enabled ? _onContinuePressed : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: enabled
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF22A055), AppColors.darkGreen],
                )
              : null,
          color: enabled ? null : AppColors.textGrey.withValues(alpha: 0.35),
        ),
        child: const Text(
          'Continue',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildRadioCard(String label, int value) {
    final selected = _selectedOption == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F1E8) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : _kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primaryGreen : _kBorder,
                  width: 2,
                ),
              ),
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGreen,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? AppColors.textDark : AppColors.textGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryGreen,
        height: 1.3,
      ),
    );
  }
}
