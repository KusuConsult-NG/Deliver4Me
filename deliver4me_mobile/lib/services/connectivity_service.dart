import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { isConnected, isDisconnected, isChecking }

class ConnectivityService extends StateNotifier<ConnectivityStatus> {
  ConnectivityService() : super(ConnectivityStatus.isChecking) {
    _checkConnectivity();
    _timer =
        Timer.periodic(const Duration(seconds: 5), (_) => _checkConnectivity());
  }

  Timer? _timer;

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (state != ConnectivityStatus.isConnected) {
          state = ConnectivityStatus.isConnected;
        }
      } else {
        if (state != ConnectivityStatus.isDisconnected) {
          state = ConnectivityStatus.isDisconnected;
        }
      }
    } catch (_) {
      if (state != ConnectivityStatus.isDisconnected) {
        state = ConnectivityStatus.isDisconnected;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityService, ConnectivityStatus>((ref) {
  return ConnectivityService();
});
