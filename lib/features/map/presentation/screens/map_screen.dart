import 'dart:math';

import 'package:bus_tracker/core/common/widgets/loader.dart';
import 'package:bus_tracker/core/theme/app_theme.dart';
import 'package:bus_tracker/core/utils/show_toast.dart';
import 'package:bus_tracker/features/map/presentation/cubit/map/map_cubit.dart';
import 'package:bus_tracker/features/map/presentation/cubit/user_location/user_location_cubit.dart';
import 'package:bus_tracker/core/common/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  static MaterialPageRoute<dynamic> route() => MaterialPageRoute(
    builder: (context) => const MapScreen(),
  );
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _destinationController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _animation;
  int _busIndex = 0;

  final Distance _distanceCalculator = const Distance();
  double _currentDistance = 0.0;
  String _eta = '~'; // fallback

  final List<Map<String, dynamic>> _buses = [
    {
      'name': 'Fast Bus',
      'time': 10,
      'color': Colors.blue,
      'hour': 9,
      'dayOfWeek': 6,
      'distanceKm': 4.5,
      'routeId': 1,
    },
    {
      'name': 'Regular Bus',
      'time': 18,
      'color': Colors.orange,
      'hour': 10,
      'dayOfWeek': 6,
      'distanceKm': 7.2,
      'routeId': 2,
    },
    {
      'name': 'Economy Bus',
      'time': 25,
      'color': Colors.green,
      'hour': 11,
      'dayOfWeek': 6,
      'distanceKm': 12.0,
      'routeId': 3,
    },
  ];

  MapLoaded? mapState;

  void _userCurrentLocation() {
    final locationState = context.read<UserLocationCubit>().state;
    if (locationState is UserLocationLoaded) {
      _mapController.move(locationState.location!, 13.0);
    } else {
      showToast('Location not available');
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<MapCubit>().loadCrowdData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35), // reasonable speed for testing
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() {
        setState(() {
          final userState = context.read<UserLocationCubit>().state;
          if (userState is UserLocationLoaded && userState.location != null) {
            if (mapState != null &&
                mapState!.route.isNotEmpty &&
                mapState!.isTracking) {
              // Bus index update
              final totalPoints = mapState!.route.length - 1;
              _busIndex = (_animation.value * totalPoints).floor().clamp(
                0,
                totalPoints,
              );
              if (_busIndex >= totalPoints) {
                Future.delayed(Duration(milliseconds: 800), () {
                  if (mounted) {
                    context.read<MapCubit>().stopBusTracking();
                    _destinationController.clear();
                  }
                });
              }

              final destination = mapState!.destination ?? mapState!.route.last;

              // Live distance update and ETA calculation
              _currentDistance = _distanceCalculator.distance(
                mapState!.route[_busIndex],
                destination,
              );

              const double avgBusSpeedKmh = 25.0;
              final timeHours = _currentDistance / 1000 / avgBusSpeedKmh;
              final timeMins = (timeHours * 60).round();

              _eta = timeMins > 0 ? '~$timeMins min' : 'Arriving...';
            }
          }
        });
      });
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final dLon = (end.longitude - start.longitude) * pi / 180;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final bearing = atan2(y, x);

    return bearing; // in radians (Transform.rotate expects radians)
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<MapCubit, MapState>(
        listener: (context, state) {
          if (state is MapFailure) {
            showToast(state.message);
          }
          // Start animation when tracking begins
          if (state is MapLoaded) {
            if (state.showRoute && state.route.isNotEmpty) {
              final locationState = context.read<UserLocationCubit>().state;
              final currentLocation = locationState is UserLocationLoaded
                  ? locationState.location
                  : null;

              if (currentLocation != null) {
                final bounds = LatLngBounds.fromPoints(state.route);
                Future.delayed(Duration(milliseconds: 300), () {
                  _mapController.fitCamera(
                    CameraFit.bounds(
                      bounds: bounds,
                      padding: EdgeInsets.all(50.0),
                    ),
                  );
                });
              }
            }

            if (state.isTracking == true && !_animationController.isAnimating) {
              _animationController.forward();
            }

            // reset bus index and animation controller when tracker is stopped
            if (state.isTracking == false) {
              _busIndex = 0;
              _animationController.reset();
            }
          }
        },
        builder: (context, state) {
          mapState = state is MapLoaded ? state : null;

          final locationState = context.watch<UserLocationCubit>().state;
          final currentLocation = locationState is UserLocationLoaded
              ? locationState.location
              : null;

          if (currentLocation != null && state is MapInitial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(currentLocation, 15.0);
            });
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      currentLocation ?? const LatLng(27.7172, 85.3240),
                  initialZoom: mapState?.showRoute == true ? 13.0 : 16.0,
                  minZoom: 0,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                  ),

                  // Current location marker
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

                  // Destination marker
                  if (mapState is MapLoaded &&
                      mapState?.destination != null &&
                      mapState?.route.isNotEmpty == true)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: mapState!.destination!,
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

                  // Polyline layer
                  if (currentLocation != null &&
                      mapState is MapLoaded &&
                      mapState?.route.isNotEmpty == true &&
                      mapState?.showRoute == true)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: mapState!.route,
                          strokeWidth: 8.0,
                          borderStrokeWidth: 2.5,
                          borderColor: AppTheme.kWhiteColor,
                          color: AppTheme.kRedColor,
                          useStrokeWidthInMeter: true,
                        ),
                      ],
                    ),

                  // Moving Bus Icon
                  if (mapState?.showRoute == true &&
                      mapState?.route.isNotEmpty == true &&
                      mapState?.isTracking == true &&
                      _busIndex < mapState!.route.length - 1)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: mapState!.route[_busIndex],
                          width: 40,
                          height: 40,
                          child: Transform.rotate(
                            angle:
                                _calculateBearing(
                                  mapState!.route[_busIndex],
                                  mapState!.route[_busIndex + 1],
                                ) +
                                pi +
                                (pi / 4),
                            child: Image.asset(
                              'assets/images/bus_icon.png',
                              width: 30,
                              height: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Info card
              if (mapState?.isTracking == true)
                Positioned(
                  top: 124,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 2,
                    color: Colors.white.withValues(alpha: .96),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(color: (mapState?.selectedBus?['color'] as Color? ?? AppTheme.kBlueColor).withValues(alpha: .14), borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.directions_bus_rounded, color: mapState?.selectedBus?['color'], size: 25),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                mapState?.selectedBus?['name'] ?? 'Unavailable',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ETA (dummy for now)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ETA',
                                    style: TextStyle(
                                      fontSize: 12, color: AppTheme.kMutedColor,
                                    ),
                                  ),
                                  Text(
                                    _eta,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              // Distance from bus to you (dummy for now)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Distance',
                                    style: TextStyle(
                                      fontSize: 12, color: AppTheme.kMutedColor,
                                    ),
                                  ),
                                  Text(
                                    '~${(_currentDistance / 1000).toStringAsFixed(1)} km',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              // Crowd Level - NOW DYNAMIC with KNN
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Crowd',
                                    style: TextStyle(
                                      fontSize: 12, color: AppTheme.kMutedColor,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          mapState?.selectedBus?['crowdLevel'] ==
                                              'Low'
                                          ? AppTheme.kGreenColor
                                          : mapState?.selectedBus?['crowdLevel'] ==
                                                'High'
                                          ? AppTheme.kRedColor
                                          : AppTheme.kOrangeColor,
                                      borderRadius: BorderRadius.circular(
                                        20,
                                      ),
                                    ),
                                    child: Text(
                                      mapState?.selectedBus?['crowdLevel'] ?? 'Unknown',
                                      style: TextStyle(
                                        color: AppTheme.kWhiteColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Destination TextField Overlay
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: AppTheme.kWhiteColor,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: TextField(
                            controller: _destinationController,
                            decoration: InputDecoration(
                              hintText: 'Where are you going?',
                              prefixIcon: const Icon(Icons.search_rounded),
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
                              filled: true, fillColor: Colors.white,
                            ),
                            onSubmitted: (location) {
                              for (var bus in _buses) {
                                bus['crowdLevel'] = context
                                    .read<MapCubit>()
                                    .predictCrowdLevel(
                                      hour: bus['hour'] as int,
                                      dayOfWeek: bus['dayOfWeek'] as int,
                                      distanceKm: bus['distanceKm'] as double,
                                      routeId: bus['routeId'] as int,
                                    );
                              }
                              context.read<MapCubit>().searchDestination(
                                location.trim(),
                              );
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) => DraggableScrollableSheet(
                                  initialChildSize: 0.45,
                                  minChildSize: 0.35,
                                  maxChildSize: 0.7,
                                  expand: false,
                                  builder: (context, scrollController) => SizedBox(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ListTile(
                                            title: Text(
                                              'Available Buses',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                    color: AppTheme.kBlackColor,
                                                  ),
                                            ),
                                            subtitle: Text(
                                              'Heading To ${_destinationController.text.trim()}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                            ),
                                          ),
                                          const Divider(),
                                          Expanded(
                                            child: BlocBuilder<MapCubit, MapState>(
                                              builder: (context, sheetState) {
                                                if (sheetState is MapLoading || sheetState is MapInitial) {
                                                  return const Loader();
                                                }
                                                if (sheetState is MapFailure) {
                                                  return Center(child: Text(sheetState.message));
                                                }
                                                if (sheetState is! MapLoaded || sheetState.route.isEmpty) {
                                                  return const Loader();
                                                }
                                                return ListView.builder(
                                                    itemCount: _buses.length,
                                                    itemBuilder: (context, index) {
                                                      final bus = _buses[index];
                                                      return Card(
                                                        child: ListTile(
                                                          leading: Icon(
                                                            Icons
                                                                .directions_bus_sharp,
                                                            color:
                                                                bus['color']
                                                                    as Color,
                                                          ),
                                                          title: Text(
                                                            bus['name'],
                                                          ),
                                                          subtitle: Text(
                                                            '$_eta • ${bus['crowdLevel']} crowd',
                                                          ),
                                                          trailing: const Icon(
                                                            Icons
                                                                .arrow_forward_ios,
                                                          ),
                                                          onTap: () {
                                                            context
                                                                .read<
                                                                  MapCubit
                                                                >()
                                                                .confirmRouteSelection(
                                                                  bus,
                                                                );

                                                            Navigator.pop(
                                                              context,
                                                            );
                                                          },
                                                        ),
                                                      );
                                                    },
                                                  );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Menu button to open end drawer
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
                      child: IconButton(
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                        icon: const Icon(Icons.menu_rounded, color: AppTheme.kBlackColor),
                      ),
                    ),
                  ],
                ),
              ),

              // Tracker button
              if (mapState?.showRoute == true)
                Positioned(
                  bottom: 30,
                  left: 16,
                  right: 16,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                    onPressed: () {
                      if (mapState?.isTracking == false) {
                        context.read<MapCubit>().startBusTracking();
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Stop Tracking?'),
                            content: const Text(
                              'Are you sure you want to stop tracking this bus?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.read<MapCubit>().stopBusTracking();
                                  _destinationController.clear();
                                  Navigator.pop(context);
                                },
                                child: const Text('Yes'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                      style: ElevatedButton.styleFrom(backgroundColor: mapState?.isTracking == true ? AppTheme.kRedColor : AppTheme.kBlueColor, foregroundColor: Colors.white, elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      icon: Icon(
                        mapState?.isTracking == true
                            ? Icons.stop
                            : Icons.power_settings_new,
                        color: Colors.white,
                        size: 22,
                      ),
                      label: Text(mapState?.isTracking == true ? 'Stop live tracking' : 'Start live tracking', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      endDrawer: AppDrawer(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.kBlueColor,
        onPressed: _userCurrentLocation,
        child: Icon(Icons.my_location, color: AppTheme.kWhiteColor),
      ),
    );
  }
}
