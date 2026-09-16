import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  List<ConnectivityResult>? _results;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then((res) {
      if (mounted) setState(() => _results = res);
    });
    _subscription = Connectivity().onConnectivityChanged.listen((res) {
      if (mounted) setState(() => _results = res);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_results == null) return const SizedBox.shrink();

    if (_results!.contains(ConnectivityResult.none)) {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          bottom: false,
          child: Container(
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 16,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Offline Mode',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
