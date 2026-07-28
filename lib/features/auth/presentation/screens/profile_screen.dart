import 'package:bus_tracker/core/cubits/app_user/app_user_cubit.dart';
import 'package:bus_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<AppUserCubit>().state;
    final phoneNumber = userState is AppUserLoggedIn
        ? userState.user.phoneNumber
        : 'Not available';

    return Scaffold(
      backgroundColor: AppTheme.kSurfaceColor,
      appBar: AppBar(
        title: const Text('My profile'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.kBlackColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppTheme.kBlueColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bus Tracker User',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              phoneNumber,
              style: const TextStyle(color: AppTheme.kMutedColor),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.verified_user_outlined,
                      color: AppTheme.kGreenColor,
                    ),
                    title: Text('Account verified'),
                    subtitle: Text('Your phone number is used for sign in'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.directions_bus_outlined,
                      color: AppTheme.kBlueColor,
                    ),
                    title: Text('Smart bus tracking'),
                    subtitle: Text('Live ETA, route, and crowd information'),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () {
                  final appUserCubit = context.read<AppUserCubit>();
                  Navigator.pop(context);
                  appUserCubit.requestLogout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.kRedColor,
                  side: const BorderSide(color: AppTheme.kRedColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}