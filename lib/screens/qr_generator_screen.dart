import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Screen for professors to generate QR codes for their classes.
class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '120');

  final LocationService _locationService = LocationService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  bool _isGenerating = false;
  Position? _currentPosition;
  String? _errorMessage;
  Event? _generatedEvent;
  String? _qrCodeData;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _locationNameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _currentPosition = await _locationService.getCurrentPosition();
      setState(() => _isLoading = false);
    } on LocationServiceException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao obter localização';
      });
    }
  }

  Future<void> _generateQRCode() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) {
      _showError('Localização não disponível. Por favor, aguarde.');
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final now = DateTime.now();
      final duration = int.tryParse(_durationController.text) ?? 120;

      _generatedEvent = Event(
        id: 'class_${now.millisecondsSinceEpoch}',
        name: _classNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? 'Aula gerada via QR Code'
            : _descriptionController.text.trim(),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        startTime: now,
        endTime: now.add(Duration(minutes: duration)),
        location: _locationNameController.text.trim(),
      );

      // Save event to Firestore
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        await _firebaseService.saveEvent(_generatedEvent!, user.id);
      }

      _qrCodeData = _generatedEvent!.toQRCodeData();

      setState(() => _isGenerating = false);
    } catch (e) {
      setState(() => _isGenerating = false);
      _showError('Erro ao gerar QR Code');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _generatedEvent = null;
      _qrCodeData = null;
      _classNameController.clear();
      _locationNameController.clear();
      _descriptionController.clear();
      _durationController.text = '120';
    });
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
                              'Gerar QR Code',
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
                      const SizedBox(height: 16),
                      // Location status
                      _buildLocationStatus(),
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
              child: _qrCodeData != null ? _buildQRCodeDisplay() : _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(38),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'A obter localização...',
              style: TextStyle(color: Colors.white.withAlpha(230)),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return GestureDetector(
        onTap: _getCurrentLocation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.error.withAlpha(77),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '$_errorMessage (toque para tentar novamente)',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentPosition != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(77),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Localização obtida',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(204),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalhes da Aula',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Preencha os dados para gerar o QR Code de presença.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          // Class name field
          _buildTextField(
            controller: _classNameController,
            label: 'Nome da Aula',
            hint: 'Ex: Programação Web',
            icon: Icons.class_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor, insira o nome da aula';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Location name field
          _buildTextField(
            controller: _locationNameController,
            label: 'Local',
            hint: 'Ex: Sala A1 - Campus ISTEC',
            icon: Icons.room_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor, insira o local';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Description field
          _buildTextField(
            controller: _descriptionController,
            label: 'Descrição (opcional)',
            hint: 'Ex: Aula prática de Flutter',
            icon: Icons.description_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          // Duration field
          _buildTextField(
            controller: _durationController,
            label: 'Duração (minutos)',
            hint: '120',
            icon: Icons.timer_rounded,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira a duração';
              }
              final duration = int.tryParse(value);
              if (duration == null || duration < 1) {
                return 'Duração inválida';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.info.withAlpha(77)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Os alunos devem estar num raio de 100 metros da sua localização atual para fazer check-in.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Generate button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: _currentPosition != null
                  ? const LinearGradient(
                      colors: [AppColors.primaryStart, AppColors.primaryEnd],
                    )
                  : null,
              color: _currentPosition == null ? AppColors.textTertiary : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _currentPosition != null
                  ? [
                      BoxShadow(
                        color: AppColors.primaryStart.withAlpha(77),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: _currentPosition != null && !_isGenerating
                  ? _generateQRCode
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Gerar QR Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primaryStart,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeDisplay() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Success badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'QR Code Gerado',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: QrImageView(
                  data: _qrCodeData!,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.textPrimary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Event details
              Text(
                _generatedEvent!.name,
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _generatedEvent!.location,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Valid time
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Válido até ${_formatTime(_generatedEvent!.endTime)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Radius info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryStart.withAlpha(26),
                AppColors.primaryEnd.withAlpha(26),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryStart, AppColors.primaryEnd],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raio de 100 metros',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Os alunos devem estar dentro desta área para fazer check-in.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Generate new button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _resetForm,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Gerar Novo QR Code'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.primaryStart),
              foregroundColor: AppColors.primaryStart,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
