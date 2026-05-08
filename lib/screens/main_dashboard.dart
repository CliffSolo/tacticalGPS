import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geocoding/geocoding.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:provider/provider.dart';
import '../theme/catppuccin.dart';
import '../theme/app_colors.dart';
import '../utils/location_utils.dart';
import '../utils/waypoint.dart';
import '../utils/app_state.dart';
import '../widgets/compass_painter.dart';
import 'navigation_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  double? _latitude;
  double? _longitude;
  double? _accuracy;
  double _heading = 0.0;
  double _speed = 0.0;
  String _mgrs = '--';
  String _latDMS = '--';
  String _lonDMS = '--';
  String _address = 'Acquiring location...';
  String _elevation = '--';
  bool _screenOn = false;
  bool _loading = true;
  double _currentAltitude = 0.0;

  final List<Color> _waypointColors = [
    CatppuccinMocha.pink,
    CatppuccinMocha.teal,
    CatppuccinMocha.yellow,
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
    _initCompass();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _address = 'Location services disabled');
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _address = 'Location permission denied');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _address = 'Location permission permanently denied');
      return;
    }
    try {
      final roughPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 3),
      );
      _updatePosition(roughPosition);
    } catch (_) {}
    try {
      final precisePosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 60),
      );
      _updatePosition(precisePosition);
    } catch (_) {}
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen(_updatePosition);
  }

  void _initCompass() {
    FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        setState(() => _heading = (event.heading! + 360) % 360);
      }
    });
  }

  Future<void> _updatePosition(position) async {
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _currentAltitude = position.altitude;
      _accuracy = position.accuracy;
      _speed = position.speed < 0 ? 0.0 : position.speed;
      _mgrs = LocationUtils.latLonToMGRS(position.latitude, position.longitude);
      _latDMS = LocationUtils.decimalToDMS(position.latitude, true);
      _lonDMS = LocationUtils.decimalToDMS(position.longitude, false);
      _elevation = LocationUtils.formatElevation(position.altitude);
      _loading = false;
    });
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        setState(() {
          _address = '${p.street ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''} ${p.postalCode ?? ''}';
        });
      }
    } catch (_) {
      setState(() => _address = 'Address unavailable');
    }
  }

  void _toggleScreenOn() {
    setState(() => _screenOn = !_screenOn);
    if (_screenOn) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  void _openAddDestination() {
    if (_latitude == null || _longitude == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigationScreen(
          currentLat: _latitude!,
          currentLon: _longitude!,
          currentHeading: _heading,
        ),
      ),
    );
  }


  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openMap() {
    if (_latitude == null || _longitude == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(
          currentLat: _latitude!,
          currentLon: _longitude!,
          heading: _heading,
        ),
      ),
    );
  }


  void _dropPin() {
    if (_latitude == null || _longitude == null) return;
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.pins.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: CatppuccinMocha.surface0,
          content: Text('Maximum 3 pins — clear one first',
              style: TextStyle(color: CatppuccinMocha.red)),
        ),
      );
      return;
    }
    final List<Color> pinColors = [
      CatppuccinMocha.maroon,
      CatppuccinMocha.sky,
      CatppuccinMocha.flamingo,
    ];
    final color = pinColors[appState.pins.length];
    final pinNumber = appState.pins.length + 1;
    final autoName = 'Pin $pinNumber';

    // Show rename dialog before saving
    final controller = TextEditingController(text: autoName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CatppuccinMocha.mantle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color),
        ),
        title: Text('NAME PIN',
            style: TextStyle(
                color: color,
                fontFamily: 'monospace',
                fontSize: 14,
                letterSpacing: 3,
                fontWeight: FontWeight.bold)),
        content: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              );
            });
            return TextField(
          controller: controller,
          autofocus: true,
          onTap: () {
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            );
          },
          style: TextStyle(color: CatppuccinMocha.text, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: 'e.g. Parked Car, Tent, Start',
            hintStyle: TextStyle(color: CatppuccinMocha.overlay0),
            filled: true,
            fillColor: CatppuccinMocha.surface0,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 2)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: CatppuccinMocha.surface1)),
          ),
            );
          }),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: TextStyle(color: CatppuccinMocha.subtext0)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim().isEmpty
                  ? autoName
                  : controller.text.trim();
              appState.addPin(DroppedPin(
                name: name,
                latitude: _latitude!,
                longitude: _longitude!,
                altitude: _currentAltitude,
                color: color,
                timestamp: DateTime.now(),
                address: _address,
                mgrs: _mgrs,
                latDMS: _latDMS,
                lonDMS: _lonDMS,
              ));
              Navigator.pop(ctx);
            },
            child: Text('SAVE',
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _markWaypoint() {
    if (_latitude == null || _longitude == null) return;
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.waypoints.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: CatppuccinMocha.surface0,
          content: Text('Maximum 3 waypoints — clear one first',
              style: TextStyle(color: CatppuccinMocha.red)),
        ),
      );
      return;
    }
    final color = _waypointColors[appState.waypoints.length];
    final wpNumber = appState.waypoints.length + 1;
    final defaultName = 'Waypoint $wpNumber';
    final controller = TextEditingController(text: defaultName);

    showDialog(
      context: context,
      builder: (ctx) => _WaypointNameDialog(
        color: color,
        controller: controller,
        defaultName: defaultName,
        currentLat: _latitude!,
        currentLon: _longitude!,
        currentAltitude: _currentAltitude,
        wpNumber: wpNumber,
        onSave: (name) async {
          final wp = Waypoint(
            name: name,
            latitude: _latitude!,
            longitude: _longitude!,
            altitude: _currentAltitude,
            color: color,
            timestamp: DateTime.now(),
            address: _address,
            mgrs: _mgrs,
            latDMS: _latDMS,
            lonDMS: _lonDMS,
          );
          appState.addWaypoint(wp);
          // Fetch road distance in background
          final roadDist = await LocationUtils.getRoadDistance(
              _latitude!, _longitude!, wp.latitude, wp.longitude);
          if (roadDist != null && mounted) {
            final idx = appState.waypoints.indexWhere(
                (w) => w.timestamp == wp.timestamp);
            if (idx >= 0) {
              appState.waypoints[idx] = Waypoint(
                name: wp.name,
                latitude: wp.latitude,
                longitude: wp.longitude,
                altitude: wp.altitude,
                color: wp.color,
                timestamp: wp.timestamp,
                address: wp.address,
                mgrs: wp.mgrs,
                latDMS: wp.latDMS,
                lonDMS: wp.lonDMS,
                roadDistance: roadDist,
              );
              appState.notifyListeners();
            }
          }
        },
      ),
    );
  }

  void _showWaypointInfo(wp) {
    final elevation = LocationUtils.formatElevation(wp.altitude);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CatppuccinMocha.mantle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: wp.color),
        ),
        title: Text(wp.name.toUpperCase(),
            style: TextStyle(
                color: wp.color,
                fontFamily: 'monospace',
                fontSize: 14,
                letterSpacing: 3,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _wpInfoRow(Icons.location_pin, 'ADDRESS',
                wp.address.isEmpty ? 'Not available' : wp.address,
                CatppuccinMocha.mauve),
            const SizedBox(height: 10),
            _wpInfoRow(Icons.grid_on, 'MGRS',
                wp.mgrs.isEmpty
                    ? LocationUtils.latLonToMGRS(wp.latitude, wp.longitude)
                    : wp.mgrs,
                CatppuccinMocha.green),
            const SizedBox(height: 10),
            _wpInfoRow(Icons.north, 'LATITUDE',
                wp.latDMS.isEmpty
                    ? LocationUtils.decimalToDMS(wp.latitude, true)
                    : wp.latDMS,
                CatppuccinMocha.peach),
            const SizedBox(height: 10),
            _wpInfoRow(Icons.east, 'LONGITUDE',
                wp.lonDMS.isEmpty
                    ? LocationUtils.decimalToDMS(wp.longitude, false)
                    : wp.lonDMS,
                CatppuccinMocha.peach),
            const SizedBox(height: 10),
            _wpInfoRow(Icons.terrain, 'ELEVATION', elevation, CatppuccinMocha.red),
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

  Widget _wpInfoRow(IconData icon, String label, String value, Color color) {
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

  void _renameWaypoint(int index) {
    final appState = Provider.of<AppState>(context, listen: false);
    final wp = appState.waypoints[index];
    final controller = TextEditingController(text: wp.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CatppuccinMocha.mantle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: wp.color),
        ),
        title: Text('RENAME WAYPOINT',
            style: TextStyle(
                color: wp.color,
                fontFamily: 'monospace',
                fontSize: 14,
                letterSpacing: 3,
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: CatppuccinMocha.text, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: 'Enter new name',
            hintStyle: TextStyle(color: CatppuccinMocha.overlay0),
            filled: true,
            fillColor: CatppuccinMocha.surface0,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: wp.color)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: wp.color, width: 2)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: CatppuccinMocha.surface1)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: TextStyle(color: CatppuccinMocha.subtext0)),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim().isEmpty
                  ? wp.name
                  : controller.text.trim();
              appState.renameWaypoint(index, newName);
              Navigator.pop(ctx);
            },
            child: Text('RENAME',
                style: TextStyle(color: wp.color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<WaypointArrow> _buildWaypointArrows(AppState appState) {
    if (_latitude == null || _longitude == null) return [];
    final List<WaypointArrow> arrows = [];
    for (final wp in appState.waypoints) {
      final bearing = LocationUtils.calculateBearing(
          _latitude!, _longitude!, wp.latitude, wp.longitude);
      final distance = LocationUtils.calculateDistance(
          _latitude!, _longitude!, wp.latitude, wp.longitude);
      arrows.add(WaypointArrow(
          bearing: bearing, color: wp.color, label: wp.name, distance: distance));
    }
    for (final pin in appState.pins) {
      final bearing = LocationUtils.calculateBearing(
          _latitude!, _longitude!, pin.latitude, pin.longitude);
      final distance = LocationUtils.calculateDistance(
          _latitude!, _longitude!, pin.latitude, pin.longitude);
      arrows.add(WaypointArrow(
          bearing: bearing, color: pin.color, label: pin.name, distance: distance));
    }
    return arrows;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final waypointArrows = _buildWaypointArrows(appState);
        double? destBearing;
        if (appState.hasDestination && _latitude != null && _longitude != null) {
          destBearing = LocationUtils.calculateBearing(
              _latitude!, _longitude!, appState.destLat!, appState.destLon!);
        }
        final c = AppColors.of(appState.themeMode);
        return Scaffold(
          backgroundColor: c.base,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildCompass(waypointArrows, destBearing),
                  const SizedBox(height: 10),
                  _buildWaypointRow(appState),
                  if (appState.waypoints.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildWaypointSummary(appState),
                  ],
                  const SizedBox(height: 16),
                  _buildAddress(),
                  const SizedBox(height: 10),
                  _buildInfoGrid(),
                  const SizedBox(height: 16),
                  _buildButtons(),
                  if (appState.waypoints.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildWaypointCards(appState),
                  ],
                  if (appState.pins.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildPinCards(appState),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final appState = Provider.of<AppState>(context, listen: false);
    final c = AppColors.of(appState.themeMode);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _openSettings,
              child: Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: c.surface0,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.surface1),
                ),
                child: Icon(Icons.settings_rounded,
                    color: c.subtext0, size: 20),
              ),
            ),
            Text('TACTICAL GPS',
            style: TextStyle(
                color: CatppuccinMocha.blue,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                fontFamily: 'monospace')),
          ],
        ),
        Row(
          children: [
            if (_accuracy != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CatppuccinMocha.surface0,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+-${_accuracy!.toStringAsFixed(0)}m',
                  style: TextStyle(
                    color: _accuracy! < 10
                        ? CatppuccinMocha.green
                        : _accuracy! < 30
                            ? CatppuccinMocha.yellow
                            : CatppuccinMocha.red,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            GestureDetector(
              onTap: _openMap,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: CatppuccinMocha.surface0,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.teal),
                ),
                child: Icon(Icons.map_rounded, color: c.teal, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompass(List<WaypointArrow> waypoints, double? destBearing) {
    final appState = Provider.of<AppState>(context, listen: false);
    final c = AppColors.of(appState.themeMode);
    return Container(
      decoration: BoxDecoration(
        color: c.mantle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.surface1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(
              painter: CompassPainter(
                heading: _heading,
                waypoints: waypoints,
                destinationBearing: destBearing,
                showDestination: destBearing != null,
                primaryColor: c.primary,
                surfaceColor: c.surface0,
                surface1Color: c.surface1,
                overlay0Color: c.overlay0,
                textColor: c.text,
                subtext0Color: c.subtext0,
                surface2Color: c.surface2,
                northColor: c.red,
              ),
            ),
          ),
          if (waypoints.isNotEmpty || destBearing != null) ...[
            const SizedBox(height: 8),
            _buildCompassLegend(waypoints, destBearing != null),
          ],
        ],
      ),
    );
  }

  Widget _buildCompassLegend(List<WaypointArrow> waypoints, bool hasDestination) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        _legendItem(CatppuccinMocha.blue, 'YOU'),
        ...waypoints.map((wp) => _legendItem(wp.color, wp.label)),
        if (hasDestination) _legendItem(CatppuccinMocha.peach, 'DEST'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 3, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _headingLabel(double heading) {
    if (heading < 22.5 || heading >= 337.5) return 'NORTH';
    if (heading < 67.5) return 'NORTHEAST';
    if (heading < 112.5) return 'EAST';
    if (heading < 157.5) return 'SOUTHEAST';
    if (heading < 202.5) return 'SOUTH';
    if (heading < 247.5) return 'SOUTHWEST';
    if (heading < 292.5) return 'WEST';
    return 'NORTHWEST';
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildInfoCard('MGRS', _mgrs, CatppuccinMocha.green, Icons.grid_on)),
            const SizedBox(width: 10),
            Expanded(child: _buildInfoCard('ELEVATION', _elevation, CatppuccinMocha.red, Icons.terrain)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildInfoCard('LATITUDE', _latDMS, CatppuccinMocha.peach, Icons.north)),
            const SizedBox(width: 10),
            Expanded(child: _buildInfoCard('LONGITUDE', _lonDMS, CatppuccinMocha.peach, Icons.east)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildInfoCard(
                'SPEED',
                _loading ? '...' : LocationUtils.formatSpeed(_speed),
                CatppuccinMocha.sapphire,
                Icons.speed)),
            const SizedBox(width: 10),
            Expanded(child: _buildInfoCard(
                'ACCURACY',
                _accuracy != null ? '+-${_accuracy!.toStringAsFixed(1)} m' : '--',
                CatppuccinMocha.teal,
                Icons.gps_fixed)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, Color accent, IconData icon) {
    final appState = Provider.of<AppState>(context, listen: false);
    final c = AppColors.of(appState.themeMode);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.mantle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.surface1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 14),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_loading ? '...' : value,
              style: TextStyle(
                  color: c.text,
                  fontSize: 13,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CatppuccinMocha.mantle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: CatppuccinMocha.mauve),
        ),
        title: Text(
          'MY LOCATION',
          style: TextStyle(
            color: CatppuccinMocha.mauve,
            fontFamily: 'monospace',
            fontSize: 14,
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogRow(Icons.location_pin, 'ADDRESS', _address, CatppuccinMocha.mauve),
            const SizedBox(height: 12),
            _dialogRow(Icons.grid_on, 'MGRS', _mgrs, CatppuccinMocha.green),
            const SizedBox(height: 12),
            _dialogRow(Icons.north, 'LATITUDE', _latDMS, CatppuccinMocha.peach),
            const SizedBox(height: 12),
            _dialogRow(Icons.east, 'LONGITUDE', _lonDMS, CatppuccinMocha.peach),
            const SizedBox(height: 12),
            _dialogRow(Icons.terrain, 'ELEVATION', _elevation, CatppuccinMocha.red),
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

  Widget _dialogRow(IconData icon, String label, String value, Color color) {
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
        Divider(color: CatppuccinMocha.surface1, height: 1),
      ],
    );
  }

  Widget _buildAddress() {
    final appState = Provider.of<AppState>(context, listen: false);
    final c = AppColors.of(appState.themeMode);
    return GestureDetector(
      onTap: _showLocationDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.mantle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.surface1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_pin, color: CatppuccinMocha.mauve, size: 14),
                const SizedBox(width: 6),
                Text('ADDRESS',
                    style: TextStyle(
                        color: CatppuccinMocha.mauve,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Icon(Icons.info_outline_rounded,
                    color: c.overlay0, size: 14),
              ],
            ),
            const SizedBox(height: 8),
            Text(_address,
                style: TextStyle(
                    color: CatppuccinMocha.text,
                    fontSize: 14,
                    fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    final appState = Provider.of<AppState>(context, listen: false);
    final c = AppColors.of(appState.themeMode);
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _toggleScreenOn,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _screenOn
                    ? CatppuccinMocha.green.withOpacity(0.2)
                    : CatppuccinMocha.surface0,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _screenOn ? CatppuccinMocha.green : CatppuccinMocha.surface1,
                  width: _screenOn ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _screenOn ? Icons.brightness_high : Icons.brightness_low,
                    color: _screenOn ? CatppuccinMocha.green : CatppuccinMocha.subtext0,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _screenOn ? 'SCREEN ON' : 'KEEP SCREEN ON',
                    style: TextStyle(
                        color: _screenOn ? CatppuccinMocha.green : CatppuccinMocha.subtext0,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: _openAddDestination,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: c.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.primary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_location_alt, color: c.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('ADD DESTINATION',
                      style: TextStyle(
                          color: c.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaypointRow(AppState appState) {
    final bool atMax = appState.waypoints.length >= 3;
    final bool pinsAtMax = appState.pins.length >= 3;
    final Color wpColor = atMax
        ? CatppuccinMocha.surface1
        : CatppuccinMocha.green;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _markWaypoint,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: wpColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: wpColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_rounded, color: wpColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    atMax ? 'MAX (3)' : 'SET WAYPOINT',
                    style: TextStyle(
                        color: wpColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: pinsAtMax ? null : _dropPin,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: pinsAtMax
                    ? CatppuccinMocha.surface0
                    : CatppuccinMocha.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: pinsAtMax
                        ? CatppuccinMocha.surface1
                        : CatppuccinMocha.green),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on_rounded,
                      color: pinsAtMax
                          ? CatppuccinMocha.surface2
                          : CatppuccinMocha.green,
                      size: 16),
                  const SizedBox(width: 6),
                  Text(
                    pinsAtMax ? 'MAX PINS (3)' : 'DROP PIN',
                    style: TextStyle(
                        color: pinsAtMax
                            ? CatppuccinMocha.surface2
                            : CatppuccinMocha.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaypointButton(AppState appState) {
    final bool atMax = appState.waypoints.length >= 3;
    final Color btnColor = atMax
        ? CatppuccinMocha.surface1
        : appState.waypoints.isEmpty
            ? CatppuccinMocha.pink
            : _waypointColors[appState.waypoints.length];
    return GestureDetector(
      onTap: _markWaypoint,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: btnColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: btnColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_rounded, color: btnColor, size: 18),
            const SizedBox(width: 8),
            Text(
              atMax ? 'MAX WAYPOINTS (3)' : 'SET WAYPOINT',
              style: TextStyle(
                  color: btnColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5),
            ),
            if (appState.waypoints.isNotEmpty && !atMax) ...[
              const SizedBox(width: 8),
              Text('${appState.waypoints.length}/3',
                  style: TextStyle(
                      color: btnColor.withOpacity(0.7),
                      fontSize: 11,
                      fontFamily: 'monospace')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWaypointSummary(AppState appState) {
    return Column(
      children: appState.waypoints.map((wp) {
        final distance = _latitude != null
            ? LocationUtils.calculateDistance(
                _latitude!, _longitude!, wp.latitude, wp.longitude)
            : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: wp.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(wp.name,
                    style: TextStyle(
                        color: wp.color,
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold)),
              ),
              Text(LocationUtils.formatDistance(distance),
                  style: TextStyle(
                      color: CatppuccinMocha.text,
                      fontSize: 13,
                      fontFamily: 'monospace')),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWaypointCards(AppState appState) {
    final c = AppColors.of(appState.themeMode);
    return Column(
      children: appState.waypoints.asMap().entries.map((entry) {
        final index = entry.key;
        final wp = entry.value;
        final bearing = _latitude != null
            ? LocationUtils.calculateBearing(
                _latitude!, _longitude!, wp.latitude, wp.longitude)
            : 0.0;
        final distance = _latitude != null
            ? LocationUtils.calculateDistance(
                _latitude!, _longitude!, wp.latitude, wp.longitude)
            : 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.mantle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: wp.color.withOpacity(0.6)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                    color: wp.color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showWaypointInfo(wp),
                            child: Text(wp.name.toUpperCase(),
                                style: TextStyle(
                                    color: wp.color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2)),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showWaypointInfo(wp),
                          child: Icon(Icons.info_outline_rounded,
                              color: wp.color.withOpacity(0.6), size: 16),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _renameWaypoint(index),
                          child: Icon(Icons.edit_rounded,
                              color: wp.color.withOpacity(0.7), size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Head ${bearing.toStringAsFixed(0)}°',
                      style: TextStyle(
                          color: CatppuccinMocha.text,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.flight, color: CatppuccinMocha.sapphire, size: 12),
                        const SizedBox(width: 4),
                        Text(LocationUtils.formatDistance(distance),
                            style: TextStyle(
                                color: CatppuccinMocha.sapphire,
                                fontSize: 12,
                                fontFamily: 'monospace')),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.directions_car, color: CatppuccinMocha.green, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          wp.roadDistance != null
                              ? LocationUtils.formatDistance(wp.roadDistance!)
                              : 'Road: fetching...',
                          style: TextStyle(
                              color: CatppuccinMocha.green,
                              fontSize: 12,
                              fontFamily: 'monospace')),
                      ],
                    ),
                    Text(
                      'Set at ${wp.timestamp.hour.toString().padLeft(2, '0')}:${wp.timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                          color: CatppuccinMocha.subtext0,
                          fontSize: 11,
                          fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    Provider.of<AppState>(context, listen: false).removeWaypoint(index),
                icon: Icon(Icons.close_rounded,
                    color: CatppuccinMocha.subtext0, size: 20),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget _buildPinCards(AppState appState) {
    final c = AppColors.of(appState.themeMode);
    return Column(
      children: appState.pins.asMap().entries.map((entry) {
        final index = entry.key;
        final pin = entry.value;
        final bearing = _latitude != null
            ? LocationUtils.calculateBearing(
                _latitude!, _longitude!, pin.latitude, pin.longitude)
            : 0.0;
        final distance = _latitude != null
            ? LocationUtils.calculateDistance(
                _latitude!, _longitude!, pin.latitude, pin.longitude)
            : 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.mantle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: pin.color.withOpacity(0.6)),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 60,
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: 0.785,
                      child: Container(
                          width: 18, height: 3,
                          decoration: BoxDecoration(
                              color: pin.color,
                              borderRadius: BorderRadius.circular(2))),
                    ),
                    Transform.rotate(
                      angle: -0.785,
                      child: Container(
                          width: 18, height: 3,
                          decoration: BoxDecoration(
                              color: pin.color,
                              borderRadius: BorderRadius.circular(2))),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(pin.name.toUpperCase(),
                              style: TextStyle(
                                  color: pin.color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2)),
                        ),
                        GestureDetector(
                          onTap: () => _renamePinDialog(index, appState),
                          child: Icon(Icons.edit_rounded,
                              color: pin.color.withOpacity(0.7), size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Head \${bearing.toStringAsFixed(0)}°  —  \${LocationUtils.formatDistance(distance)}',
                      style: TextStyle(
                          color: CatppuccinMocha.text,
                          fontSize: 13,
                          fontFamily: 'monospace'),
                    ),
                    Text(
                      'Pinned \${pin.timestamp.hour.toString().padLeft(2, "0")}:\${pin.timestamp.minute.toString().padLeft(2, "0")}',
                      style: TextStyle(
                          color: CatppuccinMocha.subtext0,
                          fontSize: 11,
                          fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    Provider.of<AppState>(context, listen: false).removePin(index),
                icon: Icon(Icons.close_rounded,
                    color: CatppuccinMocha.subtext0, size: 20),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _renamePinDialog(int index, AppState appState) {
    final pin = appState.pins[index];
    final controller = TextEditingController(text: pin.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CatppuccinMocha.mantle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: pin.color),
        ),
        title: Text('RENAME PIN',
            style: TextStyle(
                color: pin.color,
                fontFamily: 'monospace',
                fontSize: 14,
                letterSpacing: 3,
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          onTap: () {
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            );
          },
          style: TextStyle(color: CatppuccinMocha.text, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: 'e.g. Parked Car, Tent',
            hintStyle: TextStyle(color: CatppuccinMocha.overlay0),
            filled: true,
            fillColor: CatppuccinMocha.surface0,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: pin.color)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: pin.color, width: 2)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: CatppuccinMocha.surface1)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: TextStyle(color: CatppuccinMocha.subtext0)),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim().isEmpty
                  ? pin.name
                  : controller.text.trim();
              appState.renamePin(index, newName);
              Navigator.pop(ctx);
            },
            child: Text('RENAME',
                style: TextStyle(color: pin.color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }
}

// ── Waypoint name dialog with auto-select and address autocomplete
class _WaypointNameDialog extends StatefulWidget {
  final Color color;
  final TextEditingController controller;
  final String defaultName;
  final double currentLat;
  final double currentLon;
  final double currentAltitude;
  final int wpNumber;
  final Function(String) onSave;

  final List<String> recentNames;

  const _WaypointNameDialog({
    required this.color,
    required this.controller,
    required this.defaultName,
    required this.currentLat,
    required this.currentLon,
    required this.currentAltitude,
    required this.wpNumber,
    required this.onSave,
    this.recentNames = const [],
  });

  @override
  State<_WaypointNameDialog> createState() => _WaypointNameDialogState();
}

class _WaypointNameDialogState extends State<_WaypointNameDialog> {
  // Address lookup fields
  final _addressController = TextEditingController();
  List<Location> _suggestions = [];
  List<Placemark> _placemarks = [];
  bool _searching = false;
  bool _showAddressLookup = false;
  bool _showRecent = false;

  // Resolved coords from address
  double? _resolvedLat;
  double? _resolvedLon;
  String _resolvedMGRS = '';
  String _resolvedLatDMS = '';
  String _resolvedLonDMS = '';

  @override
  void initState() {
    super.initState();
    // Auto-select all text when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.controller.text.length,
      );
    });
  }


  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress(String query) async {
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final locations = await locationFromAddress(query);
      final placemarks = await Future.wait(
        locations.take(5).map((loc) =>
            placemarkFromCoordinates(loc.latitude, loc.longitude)
                .then((p) => p.first)),
      );
      setState(() {
        _suggestions = locations.take(5).toList();
        _placemarks = placemarks;
        _searching = false;
      });
    } catch (_) {
      setState(() {
        _suggestions = [];
        _searching = false;
      });
    }
  }

  void _selectSuggestion(int index) {
    final loc = _suggestions[index];
    final pm = _placemarks[index];
    final label = '${pm.street ?? ''}, ${pm.locality ?? ''}, ${pm.administrativeArea ?? ''} ${pm.postalCode ?? ''}'.trim();

    setState(() {
      _resolvedLat = loc.latitude;
      _resolvedLon = loc.longitude;
      _resolvedMGRS = LocationUtils.latLonToMGRS(loc.latitude, loc.longitude);
      _resolvedLatDMS = LocationUtils.decimalToDMS(loc.latitude, true);
      _resolvedLonDMS = LocationUtils.decimalToDMS(loc.longitude, false);
      _addressController.text = label;
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CatppuccinMocha.mantle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: widget.color),
      ),
      title: Text('SET WAYPOINT',
          style: TextStyle(
              color: widget.color,
              fontFamily: 'monospace',
              fontSize: 14,
              letterSpacing: 3,
              fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Name field with auto-select
            Text('NAME',
                style: TextStyle(
                    color: widget.color,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: widget.controller,
              autofocus: true,
              style: TextStyle(color: CatppuccinMocha.text, fontFamily: 'monospace'),
              onTap: () {
                widget.controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: widget.controller.text.length,
                );
              },
              onEditingComplete: () {},
              decoration: InputDecoration(
                hintText: 'e.g. My Car, Camp, Start',
                hintStyle: TextStyle(color: CatppuccinMocha.overlay0),
                filled: true,
                fillColor: CatppuccinMocha.surface0,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: widget.color)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: widget.color, width: 2)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: CatppuccinMocha.surface1)),
              ),
            ),

            const SizedBox(height: 14),

            // ── Address lookup toggle
            // Recent waypoints dropdown
            if (widget.recentNames.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _showRecent = !_showRecent),
                child: Row(
                  children: [
                    Icon(
                      _showRecent ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: widget.color, size: 16),
                    const SizedBox(width: 4),
                    Text('RECENT WAYPOINTS',
                        style: TextStyle(
                            color: widget.color,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (_showRecent)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: CatppuccinMocha.surface0,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.color.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: widget.recentNames.asMap().entries.map((entry) {
                      final i = entry.key;
                      final name = entry.value;
                      return InkWell(
                        onTap: () {
                          widget.controller.text = name;
                          widget.controller.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: name.length,
                          );
                          setState(() => _showRecent = false);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: i < widget.recentNames.length - 1
                                ? Border(bottom: BorderSide(
                                    color: CatppuccinMocha.surface1))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.history_rounded,
                                  color: widget.color.withOpacity(0.6), size: 14),
                              const SizedBox(width: 8),
                              Text(name,
                                  style: TextStyle(
                                      color: CatppuccinMocha.text,
                                      fontSize: 13,
                                      fontFamily: 'monospace')),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
            const SizedBox(height: 14),
            // ── Address lookup toggle
            GestureDetector(
              onTap: () => setState(() => _showAddressLookup = !_showAddressLookup),
              child: Row(
                children: [
                  Icon(
                    _showAddressLookup
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: widget.color,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LOOK UP ADDRESS',
                    style: TextStyle(
                        color: widget.color,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            if (_showAddressLookup) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                style: TextStyle(
                    color: CatppuccinMocha.text, fontFamily: 'monospace', fontSize: 13),
                onChanged: _searchAddress,
                decoration: InputDecoration(
                  hintText: 'Type an address...',
                  hintStyle:
                      TextStyle(color: CatppuccinMocha.overlay0, fontSize: 12),
                  filled: true,
                  fillColor: CatppuccinMocha.surface0,
                  suffixIcon: _searching
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: widget.color),
                          ),
                        )
                      : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: CatppuccinMocha.surface1)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: CatppuccinMocha.surface1)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: widget.color, width: 2)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),

              // Suggestions list
              if (_suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: CatppuccinMocha.surface0,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CatppuccinMocha.surface1),
                  ),
                  child: Column(
                    children: _suggestions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final pm = _placemarks[i];
                      final label =
                          '${pm.street ?? ''}, ${pm.locality ?? ''}, ${pm.administrativeArea ?? ''}'
                              .trim();
                      return InkWell(
                        onTap: () => _selectSuggestion(i),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: i < _suggestions.length - 1
                                ? Border(
                                    bottom: BorderSide(
                                        color: CatppuccinMocha.surface1))
                                : null,
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                                color: CatppuccinMocha.text,
                                fontSize: 12,
                                fontFamily: 'monospace'),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Resolved coordinates
              if (_resolvedLat != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CatppuccinMocha.surface0,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.color.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _coordRow('MGRS', _resolvedMGRS, CatppuccinMocha.green),
                      const SizedBox(height: 4),
                      _coordRow('LAT', _resolvedLatDMS, CatppuccinMocha.peach),
                      const SizedBox(height: 4),
                      _coordRow('LON', _resolvedLonDMS, CatppuccinMocha.peach),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL',
              style: TextStyle(color: CatppuccinMocha.subtext0)),
        ),
        TextButton(
          onPressed: () {
            final name = widget.controller.text.trim().isEmpty
                ? widget.defaultName
                : widget.controller.text.trim();
            widget.onSave(name);
            Navigator.pop(context);
          },
          child: Text('SAVE',
              style:
                  TextStyle(color: widget.color, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _coordRow(String label, String value, Color color) {
    return Row(
      children: [
        Text('$label  ',
            style: TextStyle(
                color: color,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace')),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  color: CatppuccinMocha.text,
                  fontSize: 11,
                  fontFamily: 'monospace')),
        ),
      ],
    );
  }
}
