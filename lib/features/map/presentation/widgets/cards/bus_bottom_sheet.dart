import 'package:bus_tracker/core/common/widgets/loader.dart';
import 'package:bus_tracker/core/theme/app_theme.dart';
import 'package:bus_tracker/features/map/presentation/cubit/map/map_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BusBottomSheet extends StatelessWidget {
  final TextEditingController destinationController;
  final MapState mapState;
  final List<Map<String, dynamic>> buses;
  const BusBottomSheet({
    super.key,
    required this.destinationController,
    required this.mapState,
    required this.buses,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
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
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: AppTheme.kBlackColor,
                  ),
                ),
                subtitle: Text(
                  'Heading To ${destinationController.text.trim()}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium,
                ),
              ),
              const Divider(),
              mapState is MapLoading
                  ? const Loader()
                  : Expanded(
                      child: mapState is MapLoading
                          ? const Loader()
                          : ListView.builder(
                              itemCount: buses.length,
                              itemBuilder: (context, index) {
                                final bus = buses[index];
                                return Card(
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.directions_bus_sharp,
                                      color: bus['color'] as Color,
                                    ),
                                    title: Text(
                                      bus['name'],
                                    ),
                                    subtitle: Text(
                                      '${bus['time']} min • ${bus['crowdLevel']} crowd',
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                    ),
                                    onTap: () {
                                      context
                                          .read<MapCubit>()
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
    );
  }
}
