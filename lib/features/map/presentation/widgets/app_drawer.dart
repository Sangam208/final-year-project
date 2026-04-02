import 'package:bus_tracker/core/cubits/app_user/app_user_cubit.dart';
import 'package:bus_tracker/features/auth/presentation/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.6, // 60% width
      child: Column(
        children: [
          SizedBox(
            height: 100,
            child: DrawerHeader(
              decoration: BoxDecoration(color: Colors.redAccent),
              child: Center(
                child: Text(
                  "Menu",
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text("Logout"),
            onTap: () {
              Navigator.pop(context);
              context.read<AppUserCubit>().requestLogout();
              Navigator.pushAndRemoveUntil(
                context,
                AuthScreen.route(),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
