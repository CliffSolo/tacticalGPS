import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/catppuccin.dart';
import '../utils/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _emailController = TextEditingController();
  bool _exporting = false;
  String _exportStatus = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _exportData() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _exportStatus = 'Please enter an email address');
      return;
    }
    setState(() {
      _exporting = true;
      _exportStatus = '';
    });
    // Simulate export — future implementation
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _exporting = false;
      _exportStatus = 'Export sent to ${_emailController.text.trim()}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isGreen = appState.themeMode == AppThemeMode.tacticalGreen;
    final isImperial = appState.unitSystem == UnitSystem.imperial;

    // Use appropriate colors based on theme
    final bg = isGreen ? TacticalGreen.base : CatppuccinMocha.base;
    final mantle = isGreen ? TacticalGreen.mantle : CatppuccinMocha.mantle;
    final surface0 = isGreen ? TacticalGreen.surface0 : CatppuccinMocha.surface0;
    final surface1 = isGreen ? TacticalGreen.surface1 : CatppuccinMocha.surface1;
    final primary = isGreen ? TacticalGreen.primary : CatppuccinMocha.blue;
    final textColor = isGreen ? TacticalGreen.text : CatppuccinMocha.text;
    final subtext = isGreen ? TacticalGreen.subtext0 : CatppuccinMocha.subtext0;
    final overlay = isGreen ? TacticalGreen.overlay0 : CatppuccinMocha.overlay0;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: mantle,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('SETTINGS',
            style: TextStyle(
                color: primary,
                letterSpacing: 4,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── THEME
              _sectionLabel('THEME', subtext),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: mantle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: surface1),
                ),
                child: Column(
                  children: [
                    _themeOption(
                      context,
                      appState,
                      label: 'Catppuccin',
                      subtitle: 'Default dark purple theme',
                      mode: AppThemeMode.catppuccin,
                      previewColor: CatppuccinMocha.blue,
                      bgColor: CatppuccinMocha.base,
                      isSelected: !isGreen,
                      textColor: textColor,
                      subtext: subtext,
                      surface0: surface0,
                      primary: primary,
                    ),
                    Divider(color: surface1, height: 1),
                    _themeOption(
                      context,
                      appState,
                      label: 'Tactical Green',
                      subtitle: 'NVG/night vision green display',
                      mode: AppThemeMode.tacticalGreen,
                      previewColor: TacticalGreen.primary,
                      bgColor: TacticalGreen.base,
                      isSelected: isGreen,
                      textColor: textColor,
                      subtext: subtext,
                      surface0: surface0,
                      primary: primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── UNITS
              _sectionLabel('UNITS OF MEASURE', subtext),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: mantle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: surface1),
                ),
                child: Column(
                  children: [
                    _unitOption(
                      appState,
                      label: 'Imperial',
                      subtitle: 'mph, feet, miles',
                      system: UnitSystem.imperial,
                      isSelected: isImperial,
                      textColor: textColor,
                      subtext: subtext,
                      surface0: surface0,
                      primary: primary,
                    ),
                    Divider(color: surface1, height: 1),
                    _unitOption(
                      appState,
                      label: 'Metric',
                      subtitle: 'km/h, meters, kilometers',
                      system: UnitSystem.metric,
                      isSelected: !isImperial,
                      textColor: textColor,
                      subtext: subtext,
                      surface0: surface0,
                      primary: primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── EXPORT
              _sectionLabel('EXPORT DATA', subtext),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: mantle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: surface1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export your waypoints, pins and locations to email.',
                      style: TextStyle(
                          color: subtext, fontSize: 12, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: textColor, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'Enter email address',
                        hintStyle: TextStyle(color: overlay, fontSize: 13),
                        filled: true,
                        fillColor: surface0,
                        prefixIcon: Icon(Icons.email_outlined, color: primary, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: surface1)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: surface1)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: primary, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _exporting ? null : _exportData,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primary),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_exporting)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: primary),
                              )
                            else
                              Icon(Icons.upload_rounded, color: primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _exporting ? 'EXPORTING...' : 'EXPORT',
                              style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_exportStatus.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _exportStatus,
                        style: TextStyle(
                            color: _exportStatus.contains('sent')
                                ? CatppuccinMocha.green
                                : CatppuccinMocha.red,
                            fontSize: 12,
                            fontFamily: 'monospace'),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── ABOUT
              _sectionLabel('ABOUT', subtext),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: mantle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: surface1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tactical GPS',
                        style: TextStyle(
                            color: primary,
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text('Version 1.0.0',
                        style: TextStyle(
                            color: subtext,
                            fontFamily: 'monospace',
                            fontSize: 13)),
                    Text('Catppuccin Mocha + Tactical Green',
                        style: TextStyle(
                            color: overlay,
                            fontFamily: 'monospace',
                            fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, Color color) {
    return Text(label,
        style: TextStyle(
            color: color,
            fontSize: 11,
            letterSpacing: 3,
            fontWeight: FontWeight.bold));
  }

  Widget _themeOption(
    BuildContext context,
    AppState appState, {
    required String label,
    required String subtitle,
    required AppThemeMode mode,
    required Color previewColor,
    required Color bgColor,
    required bool isSelected,
    required Color textColor,
    required Color subtext,
    required Color surface0,
    required Color primary,
  }) {
    return GestureDetector(
      onTap: () => appState.setTheme(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Color preview circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                border: Border.all(color: previewColor, width: 2),
              ),
              child: Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: previewColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: textColor,
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: TextStyle(
                          color: subtext,
                          fontFamily: 'monospace',
                          fontSize: 11)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primary, size: 22)
            else
              Icon(Icons.circle_outlined, color: subtext, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _unitOption(
    AppState appState, {
    required String label,
    required String subtitle,
    required UnitSystem system,
    required bool isSelected,
    required Color textColor,
    required Color subtext,
    required Color surface0,
    required Color primary,
  }) {
    return GestureDetector(
      onTap: () => appState.setUnitSystem(system),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              system == UnitSystem.imperial
                  ? Icons.flag_rounded
                  : Icons.public_rounded,
              color: isSelected ? primary : subtext,
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: textColor,
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: TextStyle(
                          color: subtext,
                          fontFamily: 'monospace',
                          fontSize: 11)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primary, size: 22)
            else
              Icon(Icons.circle_outlined, color: subtext, size: 22),
          ],
        ),
      ),
    );
  }
}
