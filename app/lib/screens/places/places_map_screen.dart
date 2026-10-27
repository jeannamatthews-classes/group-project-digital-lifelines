import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../database/db_helper.dart';
import '../../models/photo_location.dart';

class PlacesMapScreen extends StatefulWidget {
  const PlacesMapScreen({super.key});

  @override
  State<PlacesMapScreen> createState() => _PlacesMapScreenState();
}

class _PlacesMapScreenState extends State<PlacesMapScreen> {
  final MapController _mapController = MapController();
  final DBHelper _dbHelper = DBHelper.instance;

  List<PhotoLocation> _locations = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locations = await _dbHelper.getPhotoLocations();

      if (!mounted) return;

      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Places'),
        actions: [
          IconButton(
            onPressed: _loadLocations,
            tooltip: 'Refresh locations',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          'Could not load places:\n$_errorMessage',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_locations.isEmpty) {
      return const Center(
        child: Text(
          'No location data found.\n'
          'Import a Digital Lifelines JSON file containing '
          'latitude and longitude.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(
              _locations.first.latitude,
              _locations.first.longitude,
            ),
            initialZoom: 5,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.digital_lifelines.app',
            ),
            MarkerLayer(
              markers: _locations.map((location) {
                return Marker(
                  point: LatLng(
                    location.latitude,
                    location.longitude,
                  ),
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () {
                      _showLocationDetails(location);
                    },
                    child: const Icon(
                      Icons.location_pin,
                      size: 44,
                      color: Colors.red,
                    ),
                  ),
                );
              }).toList(),
            ),
            SimpleAttributionWidget(
              source: const Text(
                '© OpenStreetMap contributors',
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          top: 20,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'zoomIn',
                onPressed: () {
                  final camera = _mapController.camera;

                  _mapController.move(
                    camera.center,
                    camera.zoom + 1,
                  );
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoomOut',
                onPressed: () {
                  final camera = _mapController.camera;

                  _mapController.move(
                    camera.center,
                    camera.zoom - 1,
                  );
                },
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLocationDetails(PhotoLocation location) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(location.displayName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (location.country != null &&
                  location.country!.trim().isNotEmpty)
                Text(
                  'Country: ${location.country}',
                ),
              if (location.date != null &&
                  location.date!.trim().isNotEmpty)
                Text(
                  'Date: ${location.date}',
                ),
              Text(
                'Latitude: ${location.latitude}',
              ),
              Text(
                'Longitude: ${location.longitude}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}