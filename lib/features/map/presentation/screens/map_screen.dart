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

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _destinationController = TextEditingController();

  void _userCurrentLocation() {
    final locationState = context.read<UserLocationCubit>().state;
    if (locationState is UserLocationLoaded) {
      _mapController.move(locationState.location!, 13.0);
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
      body: BlocConsumer<MapCubit, MapState>(
        listener: (context, state) {
          if (state is MapFailure) {
            showToast(state.message);
          }
        },
        builder: (context, mapState) {
          final locationState = context.watch<UserLocationCubit>().state;
          final currentLocation = locationState is UserLocationLoaded
              ? locationState.location
              : null;
          if (currentLocation != null && mapState is MapInitial) {
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
                  initialZoom: 15.0,
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
                  if (mapState is MapLoaded && mapState.destination != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: mapState.destination!,
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
                      mapState.route.isNotEmpty &&
                      mapState.showRoute)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: mapState.route,
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
                                    Text(
                                      'Available Buses',
                                      textAlign: TextAlign.center,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium!.copyWith(
                                            color: AppTheme.kBlackColor,
                                          ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: 2,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                              return ListTile(
                                                leading: const Icon(
                                                  Icons.directions_bus_sharp,
                                                ),
                                                title: Text('Bus $index'),
                                                subtitle: Text(
                                                  '12 min • Low crowd',
                                                ),
                                                trailing: const Icon(
                                                  Icons.arrow_forward_ios,
                                                ),
                                                onTap: () {
                                                  context
                                                      .read<MapCubit>()
                                                      .confirmRouteSelection();
                                                  Navigator.pop(context);
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
