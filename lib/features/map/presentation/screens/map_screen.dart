import 'package:bus_tracker/core/theme/app_theme.dart';
import 'package:bus_tracker/core/utils/show_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(
    builder: (context) => const MapScreen(),
  );
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool isLoading = true;
  final MapController _mapController = MapController();
  final TextEditingController _destinationController = TextEditingController();
  final Location _location = Location();

  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> _route = [];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // initialize location when app starts
  Future<void> _initLocation() async {
    if (!await _checkRequestPermission()) return;

    // listen to location changes and update current location
    _location.onLocationChanged.listen(
      (LocationData locationData) {
        setState(() {
          _currentLocation = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );
        });
        isLoading = false; // Stop loading once location is obtained
      },
    );
  }

  // check if location is enabled and permission is granted
  Future<bool> _checkRequestPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return false;
      }
    }
    return true;
  }

  Future<void> _fetchCoordinates(String queryLocation) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$queryLocation&format=json&limit=1',
      );

      // Create an instance of dio and pass URI
      final dio = Dio();
      dio.options.headers['User-Agent'] =
          'BusTrackerApp/1.0 (Flutter) - Academic Project - sangam.dhital72@gmail.com';

      // Send get request
      final response = await dio.get('$uri');

      if (response.statusCode == 200) {
        final coordinatesData = List<Map<String, dynamic>>.from(response.data);
        // Extract latitude and longitude from response
        final lat = double.parse(coordinatesData[0]['lat']);
        final lon = double.parse(coordinatesData[0]['lon']);
        setState(() {
          _destination = LatLng(lat, lon);
        });
        await _fetchRoute();
      }

      if (response.statusCode != 200) showToast('${response.statusMessage}');
    } catch (e) {
      showToast(e.toString());
    }
  }

  // Fetch route using lat & long of current and destination location from OSRM API
  Future<void> _fetchRoute() async {
    try {
      if (_currentLocation == null || _destination == null) return;

      final uri = Uri.parse(
        "http://router.project-osrm.org/route/v1/driving/"
        '${_currentLocation!.longitude},${_currentLocation!.latitude};'
        '${_destination!.longitude},${_destination!.latitude}?overview=full&geometries=polyline',
      );
      final dio = Dio();
      final response = await dio.get('$uri');

      if (response.statusCode == 200) {
        final geometryData = Map<String, dynamic>.from(response.data);

        final geometry = geometryData['routes'][0]['geometry'];
        _decodePolyline(geometry);
      }
      if (response.statusCode != 200) showToast('${response.statusMessage}');
    } catch (e) {
      showToast(e.toString());
    }
  }

  // Decode polyline geometry obtained from OSRM API
  Future<void> _decodePolyline(String encodedPolyline) async {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(
      encodedPolyline,
    );

    setState(() {
      _route = decodedPoints
          .map(
            (point) => LatLng(point.latitude, point.longitude),
          )
          .toList();
    });
  }

  // Check user's current location
  Future<void> _userCurrentLocation() async {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 17);
    } else {
      showToast('Location not available');
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? LatLng(27.7172, 85.3240),
              initialZoom: 15.0,
              minZoom: 0,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: ['a', 'b', 'c', 'd'],
              ),

              CurrentLocationLayer(
                style: LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    color: AppTheme.kWhiteColor,
                    child: Icon(
                      Icons.location_pin,
                      size: 35,
                      color: AppTheme.kBlueColor,
                    ),
                  ),
                  markerSize: Size(35, 35),
                ),
              ),

              // Destination Marker
              if (_destination != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _destination!,
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.location_pin,
                        size: 35,
                        color: AppTheme.kRedColor,
                      ),
                    ),
                  ],
                ),

              // Polyline Layer
              if (_currentLocation != null &&
                  _destination != null &&
                  _route.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _route,
                      strokeWidth: 5.0,
                      color: AppTheme.kRedColor,
                    ),
                  ],
                ),
            ],
          ),

          // Destination TextField Overlay (Top Center)
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Card(
              color: AppTheme.kWhiteColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    hintText: 'Enter destination location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        width: 2.0,
                        color: AppTheme.kBlueColor,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (value) {
                    _fetchCoordinates(value.trim());
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.kBlueColor,
        onPressed: _userCurrentLocation,
        child: Icon(
          Icons.my_location,
          color: AppTheme.kWhiteColor,
        ),
      ),
    );
  }
}
