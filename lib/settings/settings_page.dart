import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mouser/core/cache_manager.dart';
import 'package:mouser/mouse/presentation/cubit/connecton_cubit.dart';
import 'package:mouser/mouse/presentation/cubit/mouse_cubit.dart';
import 'package:mouser/mouse/presentation/cubit/mouse_state.dart'
    show MouseState;
import 'package:mouser/mouse/presentation/widgets/glass_card.dart';
import 'package:mouser/mouse/presentation/widgets/custom_text_field.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final prefs = await UserPreferences.getAllPreferences();

      setState(() {
        _ipController.text = prefs['serverIP'] ?? '192.168.1.1';
        _portController.text = (prefs['serverPort'] ?? 8080).toString();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAllSettings() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Validate port number
      final port = int.tryParse(_portController.text);
      if (port == null || port < 1 || port > 65535) {
        throw Exception('Invalid port number. Must be between 1 and 65535.');
      }

      // Save connection settings
      await UserPreferences.saveConnectionSettings(
        serverIP: _ipController.text,
        serverPort: port,
      );

      // Update cubits with new values
      if (mounted) {
        context.read<ConnectionCubit>().updateServerIP(_ipController.text);
        // You might need to add updateServerPort method to ConnectionCubit
      }

      HapticFeedback.lightImpact();
      _showSnackBar('Settings saved successfully!', Colors.green);
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showSnackBar('Error saving settings: $e', Colors.red);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await _showConfirmDialog(
      'Reset Settings',
      'Are you sure you want to reset all settings to defaults? This action cannot be undone.',
    );

    if (!confirmed) return;

    try {
      // Clear all preferences
      await UserPreferences.clearAllPreferences();

      // Reset cubits
      if (mounted) {
        await context.read<ConnectionCubit>().resetToDefaults();
        await context.read<MouseCubit>().resetSensitivityToDefaults();
      }

      // Reload settings
      await _loadCurrentSettings();

      HapticFeedback.lightImpact();
      _showSnackBar('Settings reset to defaults', Colors.blue);
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showSnackBar('Error resetting settings: $e', Colors.red);
    }
  }

  Future<void> _exportSettings() async {
    try {
      final prefs = await UserPreferences.getAllPreferences();
      final settingsText = '''
Mouse Controller Settings Export
==============================

Connection Settings:
- Server IP: ${prefs['serverIP']}
- Server Port: ${prefs['serverPort']}

Sensitivity Settings:
- Mouse Sensitivity: ${prefs['mouseSensitivity']}
- Scroll Sensitivity: ${prefs['scrollSensitivity']}

Export Date: ${DateTime.now().toIso8601String()}
''';

      await Clipboard.setData(ClipboardData(text: settingsText));
      _showSnackBar('Settings copied to clipboard', Colors.blue);
    } catch (e) {
      _showSnackBar('Error exporting settings: $e', Colors.red);
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 14.sp)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveAllSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Connection Settings
                    _buildConnectionSettings(theme),
                    SizedBox(height: 20.h),

                    // Sensitivity Settings
                    _buildSensitivitySettings(theme),
                    SizedBox(height: 20.h),

                    // App Settings
                    _buildAppSettings(theme),
                    SizedBox(height: 20.h),

                    // Action Buttons
                    _buildActionButtons(theme),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildConnectionSettings(ThemeData theme) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi, color: theme.colorScheme.primary, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                'Connection Settings',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            controller: _ipController,
            label: 'PC IP Address',
            hint: '192.168.1.1',
            prefixIcon: Icons.router,
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            controller: _portController,
            label: 'Port',
            hint: '8080',
            prefixIcon: Icons.network_check,
            onChanged: (value) {
              // Validate port number as user types
              final port = int.tryParse(value);
              if (port != null && (port < 1 || port > 65535)) {
                // You could add validation feedback here
              }
            },
          ),
          SizedBox(height: 12.h),
          Text(
            'Current connection settings will be saved automatically when you connect successfully.',
            style: TextStyle(
              fontSize: 12.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensitivitySettings(ThemeData theme) {
    return BlocBuilder<MouseCubit, MouseState>(
      builder: (context, mouseState) {
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune,
                      color: theme.colorScheme.primary, size: 24.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Sensitivity Settings',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Current values display
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mouse Sensitivity:',
                            style: TextStyle(fontSize: 14.sp)),
                        Text(mouseState.sensitivity.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 14.sp, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Scroll Sensitivity:',
                            style: TextStyle(fontSize: 14.sp)),
                        Text(
                            mouseState.scrollSensitivity.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 14.sp, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),
              Text(
                'Sensitivity settings are automatically saved when changed in the main screen.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppSettings(ThemeData theme) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings,
                  color: theme.colorScheme.primary, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                'App Settings',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // App version info
          ListTile(
            leading: Icon(Icons.info, color: theme.colorScheme.primary),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0+1'),
            contentPadding: EdgeInsets.zero,
          ),

          // Storage info
          ListTile(
            leading: Icon(Icons.storage, color: theme.colorScheme.primary),
            title: const Text('Data Storage'),
            subtitle: const Text('Local preferences only'),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),

          // Export settings button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exportSettings,
              icon: const Icon(Icons.download),
              label: const Text('Export Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),

          SizedBox(height: 12.h),

          // Reset settings button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resetToDefaults,
              icon: const Icon(Icons.restore),
              label: const Text('Reset to Defaults'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
