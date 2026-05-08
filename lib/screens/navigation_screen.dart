import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mgrs_dart/mgrs_dart.dart';
import 'package:provider/provider.dart';
import '../theme/catppuccin.dart';
import '../utils/location_utils.dart';
import '../utils/app_state.dart';
import '../widgets/compass_painter.dart';

enum DestinationType { mgrs, latlon, address }

class NavigationScreen extends StatefulWidget {
  final double currentLat;
  final double currentLon;
  final double currentHeading;

  const NavigationScreen({
    super.key,
    required this.currentLat,
    required this.currentLon,
    required this.currentHeading,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  DestinationType _inputType = DestinationType.address;
  final _inputController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  double? _destLat;
  double? _destLon;
  double _heading = 0.0;
  double _currentLat = 0.0;
  double _currentLon = 0.0;
  String _destLabel = '';
  String _destAddress = '';
  String _destMGRS = '';
  String _destLatDMS = '';
  String _destLonDMS = '';
  String _errorMessage = '';
  bool _navigationActive = false;

  @override
  void initState() {
    super.initState();
    _currentLat = widget.currentLat;
    _currentLon = widget.currentLon;
    _heading = widget.currentHeading;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.hasDestination) {
        setState(() {
          _destLat = appState.destLat;
          _destLon = appState.destLon;
          _destLabel = appState.destLabel;
          _destAddress = appState.destAddress;
          _destMGRS = appState.destMGRS;
          _destLatDMS = appState.destLatDMS;
          _destLonDMS = appState.destLonDMS;
          _navigationActive = true;
          _inputController.text = appState.destLabel;
        });
      }
    });

    _initStreams();
  }

  void _initStreams() {
    FlutterCompass.events?.listen((event) {
      if (event.heading != null && mounted) {
        setState(() => _heading = (event.heading! + 360) % 360);
      }
    });
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 2,
      ),
    ).listen((pos) {
      if (mounted) {
        setState(() {
          _currentLat = pos.latitude;
          _currentLon = pos.longitude;
        });
      }
    });
  }

  double get _bearing {
    if (_destLat == null || _destLon == null) return 0;
    return LocationUtils.calculateBearing(
        _currentLat, _currentLon, _destLat!, _destLon!);
  }

  double get _distance {
    if (_destLat == null || _destLon == null) return 0;
    return LocationUtils.calculateDistance(
        _currentLat, _currentLon, _destLat!, _destLon!);
  }

  Future<void> _resolveDestination() async {
    setState(() => _errorMessage = '');
    try {
      switch (_inputType) {
        case DestinationType.address:
          final input = _inputController.text.trim();
          if (input.isEmpty) {
            setState(() => _errorMessage = 'Please enter an address');
            return;
          }
          final locations = await locationFromAddress(input);
          if (locations.isEmpty) {
            setState(() => _errorMessage = 'Address not found');
            return;
          }
          final loc = locations.first;
          final mgrs = LocationUtils.latLonToMGRS(loc.latitude, loc.longitude);
          final latDMS = LocationUtils.decimalToDMS(loc.latitude, true);
          final lonDMS = LocationUtils.decimalToDMS(loc.longitude, false);
          setState(() {
            _destLat = loc.latitude;
            _destLon = loc.longitude;
            _destLabel = input;
            _destAddress = input;
            _destMGRS = mgrs;
            _destLatDMS = latDMS;
            _destLonDMS = lonDMS;
            _navigationActive = true;
          });
          break;

        case DestinationType.latlon:
          final lat = double.tryParse(_latController.text.trim());
          final lon = double.tryParse(_lonController.text.trim());
          if (lat == null || lon == null) {
            setState(() => _errorMessage = 'Invalid coordinates');
            return;
          }
          final mgrs = LocationUtils.latLonToMGRS(lat, lon);
          final latDMS = LocationUtils.decimalToDMS(lat, true);
          final lonDMS = LocationUtils.decimalToDMS(lon, false);
          // Reverse geocode
          String address = '';
          try {
            final placemarks = await placemarkFromCoordinates(lat, lon);
            if (placemarks.isNotEmpty) {
              final p = placemarks.first;
              address = '${p.street ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''} ${p.postalCode ?? ''}'.trim();
            }
          } catch (_) {}
          setState(() {
            _destLat = lat;
            _destLon = lon;
            _destLabel = '$latDMS, $lonDMS';
            _destAddress = address;
            _destMGRS = mgrs;
            _destLatDMS = latDMS;
            _destLonDMS = lonDMS;
            _navigationActive = true;
          });
          break;

        case DestinationType.mgrs:
          final mgrsInput = _inputController.text.trim().replaceAll(' ', '');
          final point = Mgrs.toPoint(mgrsInput);
          final lat = point[1];
          final lon = point[0];
          final latDMS = LocationUtils.decimalToDMS(lat, true);
          final lonDMS = LocationUtils.decimalToDMS(lon, false);
          String address = '';
          try {
            final placemarks = await placemarkFromCoordinates(lat, lon);
            if (placemarks.isNotEmpty) {
              final p = placemarks.first;
              address = '${p.street ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''} ${p.postalCode ?? ''}'.trim();
            }
          } catch (_) {}
          setState(() {
            _destLon = lon;
            _destLat = lat;
            _destLabel = _inputController.text.trim();
            _destAddress = address;
            _destMGRS = LocationUtils.formatMGRS(_inputController.text.trim().replaceAll(' ', ''));
            _destLatDMS = latDMS;
            _destLonDMS = lonDMS;
            _navigationActive = true;
          });
          break;
      }

      if (_destLat != null && _destLon != null) {
        Provider.of<AppState>(context, listen: false).setDestination(
          lat: _destLat!,
          lon: _destLon!,
          label: _destLabel,
          address: _destAddress,
          mgrs: _destMGRS,
          latDMS: _destLatDMS,
          lonDMS: _destLonDMS,
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Could not resolve destination');
    }
  }

  void _clearDestination() {
    setState(() {
      _destLat = null;
      _destLon = null;
      _destLabel = '';
      _destAddress = '';
      _destMGRS = '';
      _destLatDMS = '';
      _destLonDMS = '';
      _navigationActive = false;
      _inputController.clear();
    });
    Provider.of<AppState>(context, listen: false).clearDestination();
  }

  void _showDestinationInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CatppuccinMocha.mantle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: CatppuccinMocha.peach),
        ),
        title: Text('DESTINATION INFO',
            style: TextStyle(
                color: CatppuccinMocha.peach,
                fontFamily: 'monospace',
                fontSize: 14,
                letterSpacing: 3,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoRow(Icons.location_pin, 'ADDRESS',
                _destAddress.isEmpty ? _destLabel : _destAddress,
                CatppuccinMocha.mauve),
            const SizedBox(height: 10),
            _infoRow(Icons.grid_on, 'MGRS', _destMGRS, CatppuccinMocha.green),
            const SizedBox(height: 10),
            _infoRow(Icons.north, 'LATITUDE', _destLatDMS, CatppuccinMocha.peach),
            const SizedBox(height: 10),
            _infoRow(Icons.east, 'LONGITUDE', _destLonDMS, CatppuccinMocha.peach),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CLOSE',
                style: TextStyle(color: CatppuccinMocha.subtext0)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: CatppuccinMocha.text,
                fontSize: 13,
                fontFamily: 'monospace')),
        Divider(color: CatppuccinMocha.surface1, height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CatppuccinMocha.base,
      appBar: AppBar(
        backgroundColor: CatppuccinMocha.mantle,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: CatppuccinMocha.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('NAVIGATION',
            style: TextStyle(
                color: CatppuccinMocha.blue,
                letterSpacing: 4,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold)),
        actions: [
          if (_navigationActive)
            IconButton(
              icon: Icon(Icons.clear, color: CatppuccinMocha.red),
              onPressed: _clearDestination,
              tooltip: 'Clear destination',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInputSection(),
              const SizedBox(height: 16),
              if (_navigationActive) ...[
                // Destination info card — tappable
                GestureDetector(
                  onTap: _showDestinationInfo,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CatppuccinMocha.mantle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CatppuccinMocha.peach.withOpacity(0.6)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                              color: CatppuccinMocha.peach,
                              borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DESTINATION',
                                  style: TextStyle(
                                      color: CatppuccinMocha.peach,
                                      fontSize: 10,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(_destLabel,
                                  style: TextStyle(
                                      color: CatppuccinMocha.text,
                                      fontSize: 13,
                                      fontFamily: 'monospace')),
                              Text(
                                  '${_bearing.toStringAsFixed(0)}°  —  ${LocationUtils.formatDistance(_distance)}',
                                  style: TextStyle(
                                      color: CatppuccinMocha.subtext0,
                                      fontSize: 12,
                                      fontFamily: 'monospace')),
                            ],
                          ),
                        ),
                        Icon(Icons.info_outline_rounded,
                            color: CatppuccinMocha.overlay0, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildNavigationCompass(),
                const SizedBox(height: 16),
                _buildNavigationInfo(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CatppuccinMocha.mantle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CatppuccinMocha.surface1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DESTINATION',
              style: TextStyle(
                  color: CatppuccinMocha.blue,
                  fontSize: 12,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _typeButton('ADDRESS', DestinationType.address),
              const SizedBox(width: 8),
              _typeButton('LAT/LON', DestinationType.latlon),
              const SizedBox(width: 8),
              _typeButton('MGRS', DestinationType.mgrs),
            ],
          ),
          const SizedBox(height: 14),
          if (_inputType == DestinationType.latlon) ...[
            _buildTextField(_latController, 'Latitude (e.g. 40.7128)'),
            const SizedBox(height: 8),
            _buildTextField(_lonController, 'Longitude (e.g. -74.0060)'),
          ] else
            _buildTextField(
              _inputController,
              _inputType == DestinationType.mgrs
                  ? 'MGRS (e.g. 18T WK 1234 5678)'
                  : 'Enter full address',
            ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_errorMessage,
                style: TextStyle(color: CatppuccinMocha.red, fontSize: 12)),
          ],
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _resolveDestination,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: CatppuccinMocha.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CatppuccinMocha.blue),
              ),
              child: Text('SET DESTINATION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: CatppuccinMocha.blue,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeButton(String label, DestinationType type) {
    final isSelected = _inputType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _inputType = type;
          _errorMessage = '';
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? CatppuccinMocha.blue.withOpacity(0.2)
                : CatppuccinMocha.surface0,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isSelected
                    ? CatppuccinMocha.blue
                    : CatppuccinMocha.surface1),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isSelected
                      ? CatppuccinMocha.blue
                      : CatppuccinMocha.subtext0,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: TextStyle(color: CatppuccinMocha.text, fontFamily: 'monospace'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: CatppuccinMocha.overlay0, fontSize: 13),
        filled: true,
        fillColor: CatppuccinMocha.surface0,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: CatppuccinMocha.surface1)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: CatppuccinMocha.surface1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: CatppuccinMocha.blue, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildNavigationCompass() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CatppuccinMocha.mantle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CatppuccinMocha.surface1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendRow(CatppuccinMocha.blue, 'YOUR HEADING'),
              const SizedBox(width: 20),
              _legendRow(CatppuccinMocha.peach, 'DESTINATION'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 260,
            height: 260,
            child: CustomPaint(
              painter: CompassPainter(
                heading: _heading,
                destinationBearing: _bearing,
                showDestination: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('${_heading.toStringAsFixed(1)}°',
              style: TextStyle(
                  color: CatppuccinMocha.blue,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label) {
    return Row(
      children: [
        Container(width: 24, height: 3, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNavigationInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CatppuccinMocha.mantle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CatppuccinMocha.surface1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NAVIGATION',
              style: TextStyle(
                  color: CatppuccinMocha.peach,
                  fontSize: 11,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Head ${_bearing.toStringAsFixed(0)}°',
              style: TextStyle(
                  color: CatppuccinMocha.text,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace')),
          const SizedBox(height: 4),
          Text(LocationUtils.formatDistance(_distance),
              style: TextStyle(
                  color: CatppuccinMocha.peach,
                  fontSize: 18,
                  fontFamily: 'monospace')),
          const SizedBox(height: 12),
          Divider(color: CatppuccinMocha.surface1),
          const SizedBox(height: 8),
          Text('TO: $_destLabel',
              style: TextStyle(
                  color: CatppuccinMocha.subtext0,
                  fontSize: 12,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }
}
