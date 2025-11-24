import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionAwareBody extends StatelessWidget {
  final Widget child;

  const ConnectionAwareBody({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      
      stream: Connectivity().onConnectivityChanged, 
      builder: (context, snapshot) {
        
        if (snapshot.hasData) {
          final result = snapshot.data!;
          if (result.contains(ConnectivityResult.none)) {
            return _buildOfflineView();
          }
        }
        
        return child;
      },
    );
  }

  Widget _buildOfflineView() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // wifi icon pwede niyo iremove
          const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "You're Offline.",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}