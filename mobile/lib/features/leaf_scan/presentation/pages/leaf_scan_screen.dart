import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/components/app_bar_widget.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/widgets/assessment_stepper.dart';
import 'package:digisaka/features/notification/presentation/pages/notifications_screen.dart';
import 'validation_screen.dart';
import '../widgets/week_context_card.dart';

/// One leaf in the grid: either a mock placeholder or a real photo.
/// (This must live OUTSIDE the State class - Dart doesn't allow a class
/// to be declared inside another class.)
class _LeafPhoto {
  final bool isMock;
  final File? file; // null for mock leaves
  final String? scenario; // tag for sample-leaf chip additions

  const _LeafPhoto({required this.isMock, this.file, this.scenario});
}

class LeafScanScreen extends StatefulWidget {
  const LeafScanScreen({super.key});

  @override
  State<LeafScanScreen> createState() => _LeafScanScreenState();
}

class _LeafScanScreenState extends State<LeafScanScreen> {
  final ImagePicker _picker = ImagePicker();

  // true  = tapping the green button instantly adds a mock leaf (no camera).
  // false = use the real camera / gallery.
  static const bool _useMockCapture = true;

  // Mock mode stops at this many leaves.
  static const int _maxLeaves = 8;

  final List<_LeafPhoto> _selectedLeaves = [];

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _goToNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  /// Sample-leaf scenario chips shown in mock capture mode.
  static const List<String> _kSampleLeafScenarios = <String>[
    'Stage 2 leaf',
    'Healthy leaf',
    'Rescan needed',
    'Referral',
    'Not a leaf',
    'QA unavailable',
  ];

  /// Adds a mock leaf to the grid, respecting the maximum of 8.
  /// The 8th leaf is the "alert" one, so it also shows a SnackBar.
  /// [scenario] tags the leaf with the sample-leaf chip label (if any).
  void _addMockLeaf({String? scenario}) {
    if (_selectedLeaves.length >= _maxLeaves) {
      _showMessage('Maximum of 8 leaves reached');
      return;
    }

    final bool isAlertLeaf = _selectedLeaves.length == _maxLeaves - 1;

    setState(() {
      _selectedLeaves.add(_LeafPhoto(isMock: true, scenario: scenario));
    });

    if (isAlertLeaf) {
      _showMessage('Leaf 8 looks unclear. Retake the photo.');
    }
  }

  /// Opens the camera. Whatever photo is taken gets added to the grid.
  Future<void> _captureFromCamera() async {
    if (_useMockCapture) {
      _addMockLeaf();
      return;
    }

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85, // keeps file size reasonable without losing much detail
    );
    if (photo == null) return; // user cancelled

    setState(() {
      _selectedLeaves.add(_LeafPhoto(isMock: false, file: File(photo.path)));
    });
  }

  /// Opens the gallery so the user can pick one or more existing photos.
  Future<void> _pickFromGallery() async {
    if (_useMockCapture) {
      _addMockLeaf();
      return;
    }

    final List<XFile> photos = await _picker.pickMultiImage(imageQuality: 85);
    if (photos.isEmpty) return; // user cancelled

    setState(() {
      _selectedLeaves.addAll(
        photos.map((x) => _LeafPhoto(isMock: false, file: File(x.path))),
      );
    });
  }

  void _removeLeaf(int index) {
    setState(() => _selectedLeaves.removeAt(index));
  }

  void _clearAll() {
    setState(() => _selectedLeaves.clear());
  }

  // Updated hook: navigate to validation screen when leaves are present.
  void _handleAssessAllLeaves() {
    if (_selectedLeaves.isEmpty) {
      _showMessage('No leaves added yet');
      return;
    }
    // Navigate to the Black Sigatoka Validation screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlackSigatokaValidationScreen(
              leafCount: _selectedLeaves.length,
              leafPhotos: _selectedLeaves.map((p) => p.file).toList(),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Leaf Scan',
        onNotificationsPressed: _goToNotifications,
      ),
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scan or select banana leaves to check for signs of Black Sigatoka',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              AssessmentStepper(currentStepIndex: 0),
              const SizedBox(height: 20),
              WeekContextCard(
                initialLine: 'L04',
                demoToday: DateTime(2026, 6, 14),
              ),
              const SizedBox(height: 20),
              _buildScanFrame(),
              const SizedBox(height: 10),
              _buildHintRow(),
              const SizedBox(height: 20),
              _buildCaptureRow(),
              const SizedBox(height: 24),
              if (_useMockCapture) ...[
                _buildSampleLeavesSection(),
                const SizedBox(height: 24),
              ],
              _buildSelectedLeavesHeader(),
              const SizedBox(height: 12),
              _buildLeavesGrid(),
              const SizedBox(height: 28),
              _buildAssessButton(),
              const SizedBox(height: 20),
              _buildPlaceholderFieldsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Dark green frame with corner brackets and a faint leaf outline guide.
  /// Fixed AspectRatio, so it never shrinks when leaves are added.
  Widget _buildScanFrame() {
    return AspectRatio(
      aspectRatio: 1.5,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.darkGreen, Color(0xFF0D3D1E)],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.eco_outlined,
                size: 90,
                color: AppColors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Four corner brackets.
          const _CornerBracket(alignment: Alignment.topLeft),
          const _CornerBracket(alignment: Alignment.topRight),
          const _CornerBracket(alignment: Alignment.bottomLeft),
          const _CornerBracket(alignment: Alignment.bottomRight),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: Text(
                'Position the banana leaf inside the frame',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintRow() {
    return const Center(
      child: Text(
        'Good lighting • Clear leaf • Symptoms visible',
        style: TextStyle(fontSize: 12, color: AppColors.textGrey),
      ),
    );
  }

  /// Gallery button on the left, big green camera-capture circle on the right.
  Widget _buildCaptureRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _pickFromGallery,
          child: Column(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E9D8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.image_outlined, color: AppColors.accentYellow, size: 26),
              ),
              const SizedBox(height: 6),
              const Text(
                'Gallery',
                style: TextStyle(fontSize: 12, color: AppColors.textDark),
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
        GestureDetector(
          onTap: _captureFromCamera,
          child: Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryGreen, width: 3),
            ),
            padding: const EdgeInsets.all(6),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// "N leaves selected" on the left, "Clear all" on the right.
  Widget _buildSelectedLeavesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_selectedLeaves.length} leaves selected',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        if (_selectedLeaves.isNotEmpty)
          GestureDetector(
            onTap: _clearAll,
            child: const Text(
              'Clear all',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
            ),
          ),
      ],
    );
  }

  /// Grid of leaf thumbnails, each with a red remove (x) button,
  /// plus one dashed "+" tile at the end to add more.
  Widget _buildLeavesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedLeaves.length + 1, // +1 for the add tile
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        if (index == _selectedLeaves.length) {
          return _buildAddTile();
        }
        return _buildLeafThumbnail(index, _selectedLeaves[index]);
      },
    );
  }

  Widget _buildLeafThumbnail(int index, _LeafPhoto leaf) {
    // The mock leaf sitting in the 8th spot is the alert one.
    final bool isAlert = leaf.isMock && index == _maxLeaves - 1;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Tile (green mock tile, or the real photo).
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _buildLeafImage(leaf, isAlert),
          ),
        ),

        // "Leaf N" pill at the bottom center (grey for the alert tile).
        Positioned(
          bottom: 6,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isAlert ? Colors.grey : AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Leaf ${index + 1}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // Red remove (x) button at the top-right corner.
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removeLeaf(index),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// Real photo for picked/captured leaves, green tile for mock leaves.
  Widget _buildLeafImage(_LeafPhoto leaf, bool isAlert) {
    if (!leaf.isMock && leaf.file != null) {
      return Image.file(
        leaf.file!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        // If the photo can't be read, show the warning tile instead.
        errorBuilder: (context, error, stackTrace) => _buildMockTile(warning: true),
      );
    }
    return _buildMockTile(warning: isAlert);
  }

  /// Light-green mock leaf tile with a darker-green leaf icon, or an orange warning icon.
  Widget _buildMockTile({required bool warning}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mockLeafTileBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Icon(
          warning ? Icons.warning_amber_rounded : Icons.eco,
          size: 30,
          color: warning ? Colors.orange : AppColors.mockLeafTileIconColor,
        ),
      ),
    );
  }

  Widget _buildAddTile() {
    return GestureDetector(
      onTap: _pickFromGallery,
      child: DottedBorderBox(
        child: const Icon(Icons.add, color: AppColors.textGrey, size: 26),
      ),
    );
  }

  /// Stays clickable even with 0 leaves.
  Widget _buildAssessButton() {
    final String label = _selectedLeaves.isEmpty
        ? 'Assess All Leaves'
        : 'Assess All Leaves (${_selectedLeaves.length})';

    final Color buttonColor = _selectedLeaves.isEmpty
        ? AppColors.primaryGreen.withValues(alpha: 0.5)
        : AppColors.primaryGreen;

    return AppButton(
      label: label,
      onPressed: _handleAssessAllLeaves,
      backgroundColor: buttonColor,
      textColor: AppColors.white,
    );
  }

  /// "Sample leaves" section shown in mock capture mode:
  /// a grey label plus a Wrap of scenario chips.
  Widget _buildSampleLeavesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sample leaves',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _kSampleLeafScenarios
                  .map(
                    (scenario) => ChoiceChip(
                      label: Text(
                        scenario,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textDark,
                        ),
                      ),
                      selected: false,
                      onSelected: (_) => _addMockLeaf(scenario: scenario),
                      backgroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.borderGrey, width: 1),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      elevation: 0,
                      pressElevation: 0,
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  /// "Not available yet" section with two disabled placeholder fields.
  Widget _buildPlaceholderFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Not available yet',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        _buildPlaceholderField('Stage override', "Use QA's stage"),
        const SizedBox(height: 10),
        _buildPlaceholderField('Treatment history', 'Not available yet'),
      ],
    );
  }

  /// A disabled dropdown-style placeholder field with muted fill.
  Widget _buildPlaceholderField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        IgnorePointer(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.placeholderFieldFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: AppColors.textGrey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Small green corner-bracket mark used on each of the 4 corners of the scan frame.
class _CornerBracket extends StatelessWidget {
  final Alignment alignment;

  const _CornerBracket({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final bool isTop = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final bool isLeft = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomPaint(
          size: const Size(28, 28),
          painter: _BracketPainter(isTop: isTop, isLeft: isLeft),
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;

  _BracketPainter({required this.isTop, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentYellow
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double x = isLeft ? 0 : size.width;
    final double y = isTop ? 0 : size.height;
    final double dx = isLeft ? size.width : -size.width;
    final double dy = isTop ? size.height : -size.height;

    path.moveTo(x + dx, y);
    path.lineTo(x, y);
    path.lineTo(x, y + dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A dashed-border square used for the "add more" tile.
class DottedBorderBox extends StatelessWidget {
  final Widget child;

  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Center(child: child),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textGrey
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(14),
    );

    const double dashWidth = 5;
    const double dashSpace = 4;
    final Path dashPath = Path();

    // Trace the rounded-rectangle outline and chop it into short dashes.
    final Path outline = Path()..addRRect(rrect);
    for (final metric in outline.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}