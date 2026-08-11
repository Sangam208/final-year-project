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
  String _eta = '~';
  bool _nearUserNotified = false;
  bool _isAtStop = false;
  String? _dynamicCrowdLevel;

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
      showToast('Please enable your location');
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<MapCubit>().loadCrowdData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() {
        setState(() {
          final userState = context.read<UserLocationCubit>().state;
          if (userState is UserLocationLoaded && userState.location != null) {
            if (mapState != null &&
                mapState!.route.isNotEmpty &&
                mapState!.isTracking) {
              final totalPoints = mapState!.route.length - 1;
              _busIndex = (_animation.value * totalPoints).floor().clamp(
                0,
                totalPoints,
              );

              if (_busIndex >= totalPoints) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showToast('Bus has reached your destination!');
                });
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (mounted) {
                    context.read<MapCubit>().stopBusTracking();
                    _destinationController.clear();
                  }
                });
              }

              const double avgBusSpeedKmh = 25.0;
              final userIndex = mapState!.userLocationIndex;

              // Bus stop simulation
              if (!_nearUserNotified && _busIndex >= userIndex) {
                _nearUserNotified = true;
                _isAtStop = true;
                _animationController.stop();

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showToast('Bus is near your location!');
                });

                Future.delayed(const Duration(seconds: 4), () {
                  if (mounted && mapState?.isTracking == true) {
                    setState(() {
                      _isAtStop = false;
                    });
                    _animationController.forward();
                  }
                });
              }

              // ETA + Crowd Level
              if (_isAtStop) {
                _eta = '---';
              } else if (_busIndex < userIndex) {
                // Still approaching user -> use original static crowd
                _dynamicCrowdLevel = null;

                _currentDistance = _distanceCalculator.distance(
                  mapState!.route[_busIndex],
                  mapState!.route[userIndex],
                );
                final timeHours = _currentDistance / 1000 / avgBusSpeedKmh;
                final timeMins = (timeHours * 60).round();
                _eta = timeMins > 0 ? '~$timeMins min' : 'Arriving';
              } else {
                // Bus moving forward of the user
                final destination =
                    mapState!.destination ?? mapState!.route.last;

                _currentDistance = _distanceCalculator.distance(
                  mapState!.route[_busIndex],
                  destination,
                );
                final timeHours = _currentDistance / 1000 / avgBusSpeedKmh;
                final timeMins = (timeHours * 60).round();
                _eta = timeMins > 0 ? '~$timeMins min' : 'Arriving...';

                final traveledKm =
                    _distanceCalculator.distance(
                      mapState!.route.first,
                      mapState!.route[_busIndex],
                    ) /
                    1000;

                if (traveledKm < 2.0) {
                  _dynamicCrowdLevel = 'High';
                } else {
                  _dynamicCrowdLevel = context
                      .read<MapCubit>()
                      .predictCrowdLevel(
                        hour: DateTime.now().hour,
                        dayOfWeek:
                            (mapState!.selectedBus?['dayOfWeek'] as int?) ?? 6,
                        distanceKm: traveledKm,
                        routeId:
                            (mapState!.selectedBus?['routeId'] as int?) ?? 1,
                      );
                }
              }
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
    return atan2(y, x);
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
          if (state is MapLoading) {
            const Loader();
          }
          if (state is MapFailure) {
            showToast(state.message);
          }
          if (state is MapLoaded) {
            if (state.showRoute && state.route.isNotEmpty) {
              final locationState = context.read<UserLocationCubit>().state;
              final currentLocation = locationState is UserLocationLoaded
                  ? locationState.location
                  : null;

              if (currentLocation != null) {
                final bounds = LatLngBounds.fromPoints(state.route);
                Future.delayed(const Duration(milliseconds: 200), () {
                  _mapController.fitCamera(
                    CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(50.0),
                    ),
                  );
                });
              }
            }

            if (state.isTracking == true && !_animationController.isAnimating) {
              _animationController.forward();
              _nearUserNotified = false;
              _isAtStop = false;
              _dynamicCrowdLevel = null;
            }

            if (state.isTracking == false) {
              _busIndex = 0;
              _animationController.reset();
              _nearUserNotified = false;
              _isAtStop = false;
              _dynamicCrowdLevel = null;
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
                  if (currentLocation != null)
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
                        markerSize: const Size(35, 35),
                      ),
                    ),
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
                  if (currentLocation != null &&
                      mapState is MapLoaded &&
                      mapState?.route.isNotEmpty == true &&
                      mapState?.showRoute == true)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points:
                              (mapState!.isTracking &&
                                  _busIndex < mapState!.route.length)
                              ? mapState!.route.sublist(_busIndex)
                              : mapState!.route,
                          strokeWidth: 8.0,
                          borderStrokeWidth: 2.5,
                          borderColor: AppTheme.kWhiteColor,
                          color: AppTheme.kRedColor,
                          useStrokeWidthInMeter: true,
                        ),
                      ],
                    ),
                  if (mapState?.showRoute == true &&
                      mapState?.route.isNotEmpty == true &&
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
                  top: 120,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 6,
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
                              Icon(
                                Icons.directions_bus,
                                color: mapState?.selectedBus?['color'],
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                mapState?.selectedBus?['name'] ?? 'Unavailable',
                                style: const TextStyle(
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ETA',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _eta,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Distance',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _isAtStop
                                        ? '---'
                                        : '~${(_currentDistance / 1000).toStringAsFixed(1)} km',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Crowd',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final displayedCrowd = _isAtStop
                                          ? '---'
                                          : (_dynamicCrowdLevel ??
                                                mapState
                                                    ?.selectedBus?['crowdLevel'] ??
                                                'Unavailable');

                                      final crowdColor = _isAtStop
                                          ? Colors.grey
                                          : displayedCrowd == 'Low'
                                          ? AppTheme.kGreenColor
                                          : displayedCrowd == 'High'
                                          ? AppTheme.kRedColor
                                          : AppTheme.kOrangeColor;

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: crowdColor,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          displayedCrowd,
                                          style: TextStyle(
                                            color: AppTheme.kWhiteColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
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

              // Destination field + menu
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
                            onSubmitted: (location) async {
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
                              final success = await context
                                  .read<MapCubit>()
                                  .searchDestination(
                                    location.trim(),
                                  );

                              // Available buses bottom sheet
                              if (!success || !context.mounted) return;
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
                                            child: state is MapLoading
                                                ? const Loader()
                                                : ListView.builder(
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
                                                            '${bus['time']} min • ${bus['crowdLevel']} crowd',
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
                    IconButton(
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                      icon: Icon(
                        Icons.menu,
                        color: AppTheme.kBlackColor,
                        size: 28.0,
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
                  child: GestureDetector(
                    onTap: () {
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
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: mapState?.isTracking == true
                            ? Colors.red
                            : AppTheme.kBlueColor,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        mapState?.isTracking == true
                            ? Icons.stop
                            : Icons.power_settings_new,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      endDrawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.kBlueColor,
        onPressed: _userCurrentLocation,
        child: Icon(Icons.my_location, color: AppTheme.kWhiteColor),
      ),
    );
  }
}
