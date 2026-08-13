import 'package:bus_tracker/core/common/widgets/loader.dart';
import 'package:bus_tracker/core/theme/app_theme.dart';
import 'package:bus_tracker/core/utils/calculate_bearing.dart';
import 'package:bus_tracker/core/utils/show_toast.dart';
import 'package:bus_tracker/features/map/presentation/cubit/map/map_cubit.dart';
import 'package:bus_tracker/features/map/presentation/cubit/user_location/user_location_cubit.dart';
import 'package:bus_tracker/core/common/widgets/app_drawer.dart';
import 'package:bus_tracker/features/map/presentation/widgets/cards/bus_bottom_sheet.dart';
import 'package:bus_tracker/features/map/presentation/widgets/fields/destination_field.dart';
import 'package:bus_tracker/features/map/presentation/widgets/buttons/geolocator_button.dart';
import 'package:bus_tracker/features/map/presentation/widgets/buttons/open_end_drawer_button.dart';
import 'package:bus_tracker/features/map/presentation/widgets/buttons/tracker_button.dart';
import 'package:bus_tracker/features/map/presentation/widgets/cards/tracking_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' hide Marker;

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

  // Dummy list of available buses
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

    // Listening to bus animation changes
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
              if (state is MapLoading)
                Positioned.fill(
                  child: Container(
                    color: AppTheme.kBlackColor.withValues(alpha: 0.35),
                    child: Center(
                      child: Lottie.asset("assets/lottie/loading.json"),
                    ),
                  ),
                ),

              // Map Layer
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
                                calculateBearing(
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

              // Tracker Info card
              if (mapState?.isTracking == true && currentLocation != null)
                Positioned(
                  top: 120,
                  left: 16,
                  right: 16,
                  child: Builder(
                    builder: (context) {
                      final displayedCrowd = _isAtStop
                          ? '---'
                          : (_dynamicCrowdLevel ??
                                mapState?.selectedBus?['crowdLevel'] ??
                                'Unavailable');
                      return TrackingInfoCard(
                        busIconColor: mapState?.selectedBus?['color'],
                        busName:
                            mapState?.selectedBus?['name'] ?? 'Unavailable',
                        eta: _eta,
                        distanceKm: _isAtStop
                            ? '---'
                            : '~${(_currentDistance / 1000).toStringAsFixed(1)} km',
                        displayedCrowd: displayedCrowd,
                        crowdColor: _isAtStop
                            ? Colors.grey
                            : displayedCrowd == 'Low'
                            ? AppTheme.kGreenColor
                            : displayedCrowd == 'High'
                            ? AppTheme.kRedColor
                            : AppTheme.kOrangeColor,
                      );
                    },
                  ),
                ),

              // Destination field + Menu button
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: DestinationField(
                        destinationController: _destinationController,
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

                          if (currentLocation == null) {
                            showToast("Current location not available");
                            return;
                          }

                          final success = await context
                              .read<MapCubit>()
                              .searchDestination(
                                location.trim(),
                              );

                          // Available buses bottom sheet
                          if (!success || !context.mounted) {
                            return;
                          }

                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => BusBottomSheet(
                              destinationController: _destinationController,
                              mapState: state,
                              buses: _buses,
                            ),
                          );
                        },
                      ),
                    ),

                    // Button to open end drawer
                    OpenEndDrawerButton(
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                    ),
                  ],
                ),
              ),

              // Tracker button
              if (mapState?.showRoute == true && currentLocation != null)
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
                    child: TrackerButton(
                      trackerColor: (mapState!.isTracking) == true
                          ? Colors.red
                          : AppTheme.kBlueColor,
                      trackerIcon: (mapState!.isTracking) == true
                          ? Icons.stop
                          : Icons.power_settings_new,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      endDrawer: const AppDrawer(),

      // Geolocator button for relocating user
      floatingActionButton: GeolocatorButton(
        backgroundColor: AppTheme.kBlueColor,
        onPressed: _userCurrentLocation,
        icon: Icons.my_location,
        iconColor: AppTheme.kWhiteColor,
      ),
    );
  }
}
