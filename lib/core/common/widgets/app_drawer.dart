import 'package:bus_tracker/core/cubits/app_user/app_user_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bus_tracker/core/theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.76,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
            decoration: const BoxDecoration(color: AppTheme.kBlueColor),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 24, backgroundColor: Colors.white24, child: Icon(Icons.directions_bus_rounded, color: Colors.white, size: 28)),
                SizedBox(height: 16),
                Text('Sajilo Yatra', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Colors.white)),
                SizedBox(height: 4),
                Text('Smart bus tracking for Kathmandu', style: TextStyle(color: Color(0xFFDCEAFF))),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text('ACCOUNT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.kMutedColor, letterSpacing: 1.1)),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.kRedColor),
            title: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              context.read<AppUserCubit>().requestLogout();
            },
          ),
        ],
      ),
    );
  }
}
