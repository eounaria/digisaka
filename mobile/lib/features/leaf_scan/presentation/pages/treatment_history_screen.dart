import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:digisaka/shared/models/treatment_history.dart';

const Color _kBorder = Color(0xFFE3E8E1);

/// Screen for collecting treatment history information.
class TreatmentHistoryScreen extends StatefulWidget {
  /// Called when Continue is pressed. If null, the screen pops with the
  /// [TreatmentHistory] as its result.
  final ValueChanged<TreatmentHistory>? onContinue;

  const TreatmentHistoryScreen({super.key, this.onContinue});

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
      Navigator.of(context).pop(result);
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Treatment History',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
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

              _buildRadioOption('Yes, I have treated it', 0),
              const SizedBox(height: 12),
              _buildRadioOption('No, I have not treated it', 1),
              const SizedBox(height: 12),
              _buildRadioOption("I'm not sure", 2),

              if (_selectedOption == 0) ...[
                const SizedBox(height: 24),
                const _FieldLabel('WHAT TYPE OF TREATMENT WAS LAST USED?'),
                const SizedBox(height: 8),
                TextField(
                  controller: _typeController,
                  onChanged: (_) => setState(() {}), // re-check Continue
                  decoration: _inputDecoration(hint: 'e.g., Oil'),
                ),
                const SizedBox(height: 16),
                const _FieldLabel('APPROXIMATE DATE OF PREVIOUS TREATMENT'),
                const SizedBox(height: 8),
                TextField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: _inputDecoration(
                    hint: 'mm/dd/yyyy',
                    suffix: const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],

              // Continue button appears once an option is picked
              if (_selectedOption != -1) ...[
                const SizedBox(height: 28),
                _buildContinueButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(_kBorder),
      enabledBorder: border(_kBorder),
      focusedBorder: border(AppColors.primaryGreen, 2),
    );
  }

  Widget _buildContinueButton() {
    final enabled = _canContinue;
    return GestureDetector(
      onTap: enabled ? _onContinuePressed : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF22A055), AppColors.darkGreen],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'Continue',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(String label, int value) {
    final selected = _selectedOption == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F1E8) : AppColors.white,
          borderRadius: BorderRadius.circular(14),
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
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
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