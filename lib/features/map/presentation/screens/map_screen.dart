import 'package:bus_tracker/core/theme/app_theme.dart';
import 'package:bus_tracker/core/utils/show_toast.dart';
import 'package:bus_tracker/features/map/presentation/cubit/map/map_cubit.dart';
import 'package:bus_tracker/features/map/presentation/cubit/user_location/user_location_cubit.dart';
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
  final List<Map<String, dynamic>> _buses = [
    {
      'name': 'Fast Bus',
      'time': '10 min',
      'crowd': 'Low crowd',
      'color': Colors.blue,
    },
    {
      'name': 'Regular Bus',
      'time': '18 min',
      'crowd': 'Medium crowd',
      'color': Colors.orange,
    },
    {
      'name': 'Economy Bus',
      'time': '25 min',
      'crowd': 'High crowd',
      'color': Colors.green,
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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 30,
      ), // Change this to make bus faster/slower
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() {
        setState(() {
          if (mapState != null && mapState!.route.isNotEmpty) {
            _busIndex = (_animation.value * (mapState!.route.length - 1))
                .floor();
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
          if (state is MapFailure) {
            showToast(state.message);
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

          // Start bus animation when user selects a bus
          if (mapState?.showRoute == true &&
              mapState?.route.isNotEmpty == true) {
            if (!_animationController.isAnimating) {
              _animationController.forward();
            }
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

                  // Current User Location Marker
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

                  // Polyline Layer
                  if (currentLocation != null &&
                      mapState is MapLoaded &&
                      mapState?.route.isNotEmpty == true &&
                      mapState?.showRoute == true)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: mapState!.route,
                          strokeWidth: 5.0,
                          color: AppTheme.kRedColor,
                        ),
                      ],
                    ),

                  // Moving Bus Icon
                  if (mapState?.showRoute == true &&
                      mapState?.route.isNotEmpty == true &&
                      _busIndex < mapState!.route.length &&
                      mapState?.isTracking == true)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: mapState!.route[_busIndex],
                          child: const Icon(
                            Icons.directions_bus_filled_outlined,
                            size: 30,
                            color: Colors.green,
                          ),
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
                      onSubmitted: (location) {
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      title: Text(
                                        'Available Buses',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium!.copyWith(
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
                                      child: ListView.builder(
                                        itemCount: _buses.length,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                              final busName =
                                                  _buses[index]['name'];
                                              final busTime =
                                                  _buses[index]['time'];
                                              final crowdLevel =
                                                  _buses[index]['crowd'];
                                              final busColor =
                                                  _buses[index]['color']
                                                      as Color;

                                              return Card(
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.directions_bus_sharp,
                                                    color: busColor,
                                                  ),
                                                  title: Text(busName),
                                                  subtitle: Text(
                                                    '$busTime • $crowdLevel',
                                                  ),
                                                  trailing: Icon(
                                                    Icons.arrow_forward_ios,
                                                  ),
                                                  onTap: () {
                                                    context
                                                        .read<MapCubit>()
                                                        .confirmRouteSelection();
                                                    Navigator.pop(context);
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

              if (mapState is MapLoaded &&
                  mapState?.route.isNotEmpty == true &&
                  mapState?.showRoute == true)
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
                            title: Text(
                              'Stop Tracking?',
                              style: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(
                                    fontSize: 25,
                                  ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.read<MapCubit>().stopBusTracking();
                                  _destinationController.clear();
                                  Navigator.pop(context);
                                },
                                child: Text('Yes'),
                              ),
                            ],
                            content: Text(
                              'Are you sure you want to stop tracking this bus?',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: mapState?.isTracking == true
                            ? const Color.fromARGB(255, 247, 107, 97)
                            : AppTheme.kBlueColor,
                        shape: BoxShape.circle,
                        boxShadow: [
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
