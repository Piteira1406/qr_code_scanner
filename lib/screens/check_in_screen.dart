import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../widgets/feedback_dialogs.dart';
import '../theme/app_theme.dart';

/// Screen for scanning QR codes and performing check-ins.
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  bool _hasScanned = false;
  bool _torchEnabled = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_scannerController == null) return;

    switch (state) {
      case AppLifecycleState.paused:
        _scannerController?.stop();
        break;
      case AppLifecycleState.resumed:
        if (_isScanning) {
          _scannerController?.start();
        }
        break;
      default:
        break;
    }
  }

  void _initializeScanner() {
    _scannerController?.dispose();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: _torchEnabled,
    );
    setState(() {
      _isScanning = true;
      _hasScanned = false;
    });
  }

  void _stopScanner() {
    _scannerController?.stop();
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_hasScanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() => _hasScanned = true);
    _stopScanner();

    final checkInProvider = context.read<CheckInProvider>();
    final success = await checkInProvider.processQRCode(barcode.rawValue!);

    if (!mounted) return;

    if (success) {
      await FeedbackDialogs.showSuccessDialog(
        context,
        event: checkInProvider.currentEvent!,
        distance: checkInProvider.distanceToEvent!,
      );
      checkInProvider.reset();
    } else {
      await FeedbackDialogs.showErrorDialog(
        context,
        errorType: checkInProvider.errorType!,
        errorMessage: checkInProvider.errorMessage!,
      );
      checkInProvider.reset();
    }
  }

  void _toggleTorch() {
    _scannerController?.toggleTorch();
    setState(() => _torchEnabled = !_torchEnabled);
  }

  void _switchCamera() {
    _scannerController?.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CheckInProvider>(
        builder: (context, provider, _) {
          if (provider.isProcessing) {
            return _buildProcessingView(provider);
          }

          if (_isScanning) {
            return _buildScannerView();
          }

          return _buildStartView();
        },
      ),
    );
  }

  Widget _buildStartView() {
    return CustomScrollView(
      slivers: [
        // Modern gradient header
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryStart, AppColors.primaryEnd],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Check-in',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Animated QR Code illustration
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withAlpha(51),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.qr_code_2,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  'Registar Presença',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Leia o QR Code do evento ou aula para confirmar a sua presença. Certifique-se de que está no local correto.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                // Start scanning button with gradient
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryStart, AppColors.primaryEnd],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryStart.withAlpha(77),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _initializeScanner,
                    icon: const Icon(Icons.qr_code_scanner, size: 24),
                    label: const Text(
                      'Iniciar Leitura',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Demo button
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryStart.withAlpha(77),
                      width: 1.5,
                    ),
                  ),
                  child: OutlinedButton.icon(
                    onPressed: _performDemoCheckIn,
                    icon: Icon(Icons.science, color: AppColors.primaryStart),
                    label: Text(
                      'Demonstração',
                      style: TextStyle(
                        color: AppColors.primaryStart,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Modern info cards
                _buildInfoCard(
                  icon: Icons.location_on_rounded,
                  title: 'Localização',
                  description:
                      'A sua posição GPS será verificada automaticamente.',
                  color: AppColors.info,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.verified_rounded,
                  title: 'Validação',
                  description: 'Deve estar a menos de 100 metros do evento.',
                  color: AppColors.accent,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.security_rounded,
                  title: 'Segurança',
                  description: 'Os seus dados são protegidos e encriptados.',
                  color: AppColors.primaryEnd,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        // Camera preview
        MobileScanner(
          controller: _scannerController!,
          onDetect: _handleBarcode,
        ),
        // Overlay with scanning frame
        _buildScannerOverlay(),
        // Top controls
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withAlpha(153), Colors.transparent],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _stopScanner,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Row(
                      children: [
                        _buildControlButton(
                          icon: _torchEnabled
                              ? Icons.flash_on
                              : Icons.flash_off,
                          onPressed: _toggleTorch,
                          isActive: _torchEnabled,
                        ),
                        const SizedBox(width: 8),
                        _buildControlButton(
                          icon: Icons.cameraswitch,
                          onPressed: _switchCamera,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Bottom cancel button
        Positioned(
          bottom: 48,
          left: 24,
          right: 24,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _stopScanner,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent : Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return CustomPaint(
      painter: ScannerOverlayPainter(),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 200),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryStart.withAlpha(204),
                    AppColors.primaryEnd.withAlpha(204),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Aponte para o QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingView(CheckInProvider provider) {
    String message;
    IconData icon;
    switch (provider.state) {
      case CheckInState.scanning:
        message = 'A processar QR Code...';
        icon = Icons.qr_code_scanner;
        break;
      case CheckInState.validatingLocation:
        message = 'A validar localização...';
        icon = Icons.location_searching;
        break;
      case CheckInState.processing:
        message = 'A registar presença...';
        icon = Icons.cloud_upload;
        break;
      default:
        message = 'A processar...';
        icon = Icons.hourglass_empty;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background, Colors.white],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryStart, AppColors.primaryEnd],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryStart.withAlpha(77),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryStart,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: AppTextStyles.bodyBold.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performDemoCheckIn() async {
    final checkInProvider = context.read<CheckInProvider>();
    final mockEvent = CheckInProvider.getMockEvent();

    // Show modern info dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryStart, AppColors.primaryEnd],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.science, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'Modo Demonstração',
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                'Este modo simula um check-in para teste.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          size: 16,
                          color: AppColors.primaryStart,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mockEvent.name,
                            style: AppTextStyles.bodyBold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.primaryStart,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mockEvent.location,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'A sua localização atual será comparada com as coordenadas do evento de demonstração.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: AppColors.border),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryStart,
                            AppColors.primaryEnd,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Continuar'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await checkInProvider.processMockCheckIn(
      eventName: mockEvent.name,
      eventLatitude: mockEvent.latitude,
      eventLongitude: mockEvent.longitude,
    );

    if (!mounted) return;

    if (success) {
      await FeedbackDialogs.showSuccessDialog(
        context,
        event: checkInProvider.currentEvent!,
        distance: checkInProvider.distanceToEvent!,
      );
    } else {
      await FeedbackDialogs.showErrorDialog(
        context,
        errorType: checkInProvider.errorType!,
        errorMessage: checkInProvider.errorMessage!,
      );
    }

    checkInProvider.reset();
  }
}

/// Custom painter for the scanner overlay.
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(140)
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.7;
    final scanAreaLeft = (size.width - scanAreaSize) / 2;
    final scanAreaTop = (size.height - scanAreaSize) / 2 - 40;

    // Draw semi-transparent overlay
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(scanAreaLeft, scanAreaTop, scanAreaSize, scanAreaSize),
          const Radius.circular(24),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw gradient corner brackets
    const bracketLength = 40.0;
    const cornerRadius = 24.0;
    const strokeWidth = 5.0;

    // Create gradient shader for brackets
    final rect = Rect.fromLTWH(
      scanAreaLeft,
      scanAreaTop,
      scanAreaSize,
      scanAreaSize,
    );
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primaryStart, AppColors.accent],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanAreaLeft, scanAreaTop + bracketLength + cornerRadius)
        ..lineTo(scanAreaLeft, scanAreaTop + cornerRadius)
        ..arcToPoint(
          Offset(scanAreaLeft + cornerRadius, scanAreaTop),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(scanAreaLeft + bracketLength + cornerRadius, scanAreaTop),
      gradientPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(
          scanAreaLeft + scanAreaSize - bracketLength - cornerRadius,
          scanAreaTop,
        )
        ..lineTo(scanAreaLeft + scanAreaSize - cornerRadius, scanAreaTop)
        ..arcToPoint(
          Offset(scanAreaLeft + scanAreaSize, scanAreaTop + cornerRadius),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(
          scanAreaLeft + scanAreaSize,
          scanAreaTop + bracketLength + cornerRadius,
        ),
      gradientPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(
          scanAreaLeft,
          scanAreaTop + scanAreaSize - bracketLength - cornerRadius,
        )
        ..lineTo(scanAreaLeft, scanAreaTop + scanAreaSize - cornerRadius)
        ..arcToPoint(
          Offset(scanAreaLeft + cornerRadius, scanAreaTop + scanAreaSize),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(
          scanAreaLeft + bracketLength + cornerRadius,
          scanAreaTop + scanAreaSize,
        ),
      gradientPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(
          scanAreaLeft + scanAreaSize - bracketLength - cornerRadius,
          scanAreaTop + scanAreaSize,
        )
        ..lineTo(
          scanAreaLeft + scanAreaSize - cornerRadius,
          scanAreaTop + scanAreaSize,
        )
        ..arcToPoint(
          Offset(
            scanAreaLeft + scanAreaSize,
            scanAreaTop + scanAreaSize - cornerRadius,
          ),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(
          scanAreaLeft + scanAreaSize,
          scanAreaTop + scanAreaSize - bracketLength - cornerRadius,
        ),
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
