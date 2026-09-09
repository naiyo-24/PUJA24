import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../network/api_config.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Background loop
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final token = prefs.getString('jwt_token');
    final activeGroupIdsStr = prefs.getStringList('active_live_groups') ?? [];
    
    if (token == null || activeGroupIdsStr.isEmpty) {
      service.stopSelf();
      timer.cancel();
      return;
    }

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "PUJA24",
          content: "Live location sharing is active in ${activeGroupIdsStr.length} group(s)",
        );
      }
    }

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      for (String groupId in activeGroupIdsStr) {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/groups/$groupId/location'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'latitude': pos.latitude,
            'longitude': pos.longitude,
          }),
        );
      }
    } catch (e) {
      // Ignore background fetch errors
    }
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

class BackgroundLocationService {
  static final BackgroundLocationService _instance = BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  final FlutterBackgroundService _service = FlutterBackgroundService();

  Future<void> initialize() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'puja24_live_location',
      'Live Location Service',
      description: 'Used for live location sharing in PUJA24',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    if (Platform.isIOS || Platform.isAndroid) {
      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          iOS: DarwinInitializationSettings(),
          android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        ),
      );
    }
    
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'puja24_live_location',
        initialNotificationTitle: 'PUJA24',
        initialNotificationContent: 'Initializing live location',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  Future<void> startService(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    List<String> activeGroups = prefs.getStringList('active_live_groups') ?? [];
    if (!activeGroups.contains(groupId)) {
      activeGroups.add(groupId);
      await prefs.setStringList('active_live_groups', activeGroups);
    }
    
    final isRunning = await _service.isRunning();
    if (!isRunning) {
      await _service.startService();
    }
  }

  Future<void> stopService(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    List<String> activeGroups = prefs.getStringList('active_live_groups') ?? [];
    activeGroups.remove(groupId);
    await prefs.setStringList('active_live_groups', activeGroups);
    
    if (activeGroups.isEmpty) {
      _service.invoke("stopService");
    }
  }
}
