import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../localization/app_strings.dart';

/// Full-screen map. The pin stays in the middle; the user moves the map under
/// it, or taps "my location". Returns the chosen point, or null on back.
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initial;
  const LocationPickerScreen({super.key, this.initial});

  static const erbil = LatLng(36.1911, 44.0092);

  static Future<LatLng?> open(BuildContext context, {LatLng? initial}) =>
      Navigator.push<LatLng>(
        context,
        MaterialPageRoute(
          builder: (_) => LocationPickerScreen(initial: initial),
        ),
      );

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _map = MapController();
  late LatLng _center = widget.initial ?? LocationPickerScreen.erbil;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToMe(quiet: true));
    }
  }

  Future<void> _goToMe({bool quiet = false}) async {
    final s = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _locating = true);
    void say(String message) {
      if (!quiet) messenger.showSnackBar(SnackBar(content: Text(message)));
    }

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        say(s.turnOnLocation);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        say(s.locationPermissionNeeded);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      final me = LatLng(pos.latitude, pos.longitude);
      setState(() => _center = me);
      _map.move(me, 17);
    } catch (_) {
      say(s.locationPermissionNeeded);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(s.pickLocation)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: widget.initial == null ? 13 : 17,
              minZoom: 5,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (camera, _) => _center = camera.center,
              onTap: (_, point) {
                setState(() => _center = point);
                _map.move(point, _map.camera.zoom);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.zankoswap.app',
              ),
              const SimpleAttributionWidget(
                source: Text('OpenStreetMap contributors'),
              ),
            ],
          ),
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 44),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 48,
                  color: scheme.error,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              color: scheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(s.pickLocationHint, textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.small(
          heroTag: 'locate-me',
          onPressed: _locating ? null : () => _goToMe(),
          tooltip: s.myLocation,
          child: _locating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location_rounded),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: () => Navigator.pop(context, _center),
            icon: const Icon(Icons.check_rounded),
            label: Text(s.confirmLocation),
          ),
        ),
      ),
    );
  }
}
