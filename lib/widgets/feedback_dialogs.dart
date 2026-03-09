import 'package:flutter/material.dart';
import '../models/models.dart';
import '../providers/check_in_provider.dart';
import '../theme/app_theme.dart';

/// Utility class for displaying feedback dialogs.
class FeedbackDialogs {
  /// Shows a success dialog after a successful check-in.
  static Future<void> showSuccessDialog(
    BuildContext context, {
    required Event event,
    required double distance,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessDialog(event: event, distance: distance),
    );
  }

  /// Shows an error dialog with the appropriate error message.
  static Future<void> showErrorDialog(
    BuildContext context, {
    required CheckInErrorType errorType,
    required String errorMessage,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _ErrorDialog(errorType: errorType, errorMessage: errorMessage),
    );
  }
}

/// Success dialog widget with animation.
class _SuccessDialog extends StatefulWidget {
  final Event event;
  final double distance;

  const _SuccessDialog({required this.event, required this.distance});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon with gradient background - Hourglass for pending
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warning.withAlpha(51),
                        AppColors.warning.withAlpha(102),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_empty_rounded,
                    size: 48,
                    color: AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                'Presença Pendente',
                style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'O seu check-in foi enviado e aguarda validação do professor.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              // Event details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.event_rounded,
                      'Evento',
                      widget.event.name,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.location_on_rounded,
                      'Local',
                      widget.event.location,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.near_me_rounded,
                      'Distância',
                      '${widget.distance.toStringAsFixed(1)} metros',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.access_time_rounded,
                      'Hora',
                      _formatTime(DateTime.now()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Close button with gradient
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.warning, AppColors.warning.withRed(230)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withAlpha(77),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryStart.withAlpha(26),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryStart),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Error dialog widget with specific error handling.
class _ErrorDialog extends StatefulWidget {
  final CheckInErrorType errorType;
  final String errorMessage;

  const _ErrorDialog({required this.errorType, required this.errorMessage});

  @override
  State<_ErrorDialog> createState() => _ErrorDialogState();
}

class _ErrorDialogState extends State<_ErrorDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 12, end: -12), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 12, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorData = _getErrorData();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated error icon
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        errorData.color.withAlpha(38),
                        errorData.color.withAlpha(77),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(errorData.icon, size: 48, color: errorData.color),
                ),
              ),
              const SizedBox(height: 24),
              // Error title
              Text(
                errorData.title,
                style: AppTextStyles.h2.copyWith(color: errorData.color),
              ),
              const SizedBox(height: 8),
              Text(
                widget.errorMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              // Help text card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: errorData.color.withAlpha(13),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: errorData.color.withAlpha(38)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: errorData.color.withAlpha(26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: errorData.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorData.helpText,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Close button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [errorData.color, errorData.color.withAlpha(204)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: errorData.color.withAlpha(77),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Tentar Novamente',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _ErrorData _getErrorData() {
    switch (widget.errorType) {
      case CheckInErrorType.invalidQRCode:
        return _ErrorData(
          title: 'QR Code Inválido',
          icon: Icons.qr_code_2_rounded,
          color: AppColors.error,
          helpText:
              'Certifique-se de que está a ler um QR Code válido do ISTEC.',
        );
      case CheckInErrorType.invalidLocation:
        return _ErrorData(
          title: 'Localização Incorreta',
          icon: Icons.location_off_rounded,
          color: AppColors.warning,
          helpText:
              'Deve estar a menos de 100 metros do local do evento para fazer check-in.',
        );
      case CheckInErrorType.noConnection:
        return _ErrorData(
          title: 'Sem Conexão',
          icon: Icons.wifi_off_rounded,
          color: AppColors.info,
          helpText: 'Verifique a sua ligação à Internet e tente novamente.',
        );
      case CheckInErrorType.permissionDenied:
        return _ErrorData(
          title: 'Permissões Necessárias',
          icon: Icons.no_accounts_rounded,
          color: AppColors.primaryEnd,
          helpText:
              'Por favor, ative as permissões de localização nas definições do dispositivo.',
        );
      case CheckInErrorType.unknown:
        return _ErrorData(
          title: 'Erro Inesperado',
          icon: Icons.error_outline_rounded,
          color: AppColors.textSecondary,
          helpText: 'Ocorreu um erro inesperado. Por favor, tente novamente.',
        );
    }
  }
}

/// Helper class for error display data.
class _ErrorData {
  final String title;
  final IconData icon;
  final Color color;
  final String helpText;

  _ErrorData({
    required this.title,
    required this.icon,
    required this.color,
    required this.helpText,
  });
}
