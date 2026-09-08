import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import '../../../core/network/api_config.dart';

// Provides the websocket service instance for a group
final groupWebsocketServiceProvider = Provider.autoDispose.family<GroupWebsocketService, String>((ref, groupId) {
  final service = GroupWebsocketService(groupId);
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

// Provides the messages stream for a specific group
final groupMessagesProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, groupId) {
  final wsService = ref.watch(groupWebsocketServiceProvider(groupId));
  return wsService.messagesStream;
});

// Provides the live locations stream for a specific group
final groupLocationsProvider = StreamProvider.autoDispose.family<Map<String, Map<String, dynamic>>, String>((ref, groupId) {
  final wsService = ref.watch(groupWebsocketServiceProvider(groupId));
  return wsService.locationsStream;
});

// Provides the route stream
final routeStreamProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, groupId) {
  final wsService = ref.watch(groupWebsocketServiceProvider(groupId));
  return wsService.routeStream;
});

class GroupWebsocketService {
  final String groupId;
  WebSocketChannel? _channel;
  String? _userId;
  String? _userName;
  
  final List<Map<String, dynamic>> _messages = [];
  
  // Live Locations state map (userId -> location info)
  final Map<String, Map<String, dynamic>> _liveLocations = {};
  
  // Streams
  final StreamController<List<Map<String, dynamic>>> _controller = StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<Map<String, Map<String, dynamic>>> _locationController = StreamController<Map<String, Map<String, dynamic>>>.broadcast();
  
  // Location sharing subscription
  StreamSubscription<Position>? _positionSubscription;
  bool _isSharingLocation = false;
  
  // Privacy & Sharing Settings
  bool isLocationPaused = false;
  bool hideBattery = false;
  bool hideSpeed = false;
  Timer? _shareTimer;
  String? shareDurationString = 'Until I stop';
  final Battery _battery = Battery();
  
  // Routing state
  String? targetUserId;
  String? targetUserName;
  final StreamController<List<Map<String, dynamic>>> _routeController = StreamController<List<Map<String, dynamic>>>.broadcast();
  DateTime? _lastRouteFetchTime;
  
  bool get isSharingLocation => _isSharingLocation;

  Stream<List<Map<String, dynamic>>> get messagesStream {
    // Immediately emit current state when someone listens
    Future.microtask(() {
      if (!_controller.isClosed) {
        _controller.add(List.from(_messages));
      }
    });
    return _controller.stream;
  }

  Stream<Map<String, Map<String, dynamic>>> get locationsStream {
    Future.microtask(() {
      if (!_locationController.isClosed) {
        _locationController.add(Map.from(_liveLocations));
      }
    });
    return _locationController.stream;
  }

  Stream<List<Map<String, dynamic>>> get routeStream => _routeController.stream;

  GroupWebsocketService(this.groupId) {
    _initAndConnect();
  }

  String _decodeUserId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return 'unknown_id';
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded);
      return map['sub']?.toString() ?? 'unknown_id';
    } catch (e) {
      return 'unknown_id';
    }
  }

  String _formatTime(DateTime time) {
    final localTime = time.toLocal();
    final hour = localTime.hour > 12 ? localTime.hour - 12 : (localTime.hour == 0 ? 12 : localTime.hour);
    final minute = localTime.minute.toString().padLeft(2, '0');
    final ampm = localTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  Future<void> _initAndConnect() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    
    if (token == null) {
      print('Cannot connect WS: No auth token found.');
      return;
    }

    _userId = _decodeUserId(token);
    _userName = prefs.getString('user_name') ?? 'Me';

    // 1. Fetch historical messages first
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/groups/$groupId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          for (var msg in data) {
            String timeStr = 'Just now';
            DateTime? msgDate;
            if (msg['created_at'] != null) {
              try {
                msgDate = DateTime.parse(msg['created_at']).toLocal();
                timeStr = _formatTime(msgDate);
              } catch (_) {}
            }
            _messages.add({
              'id': msg['id'] ?? '',
              'text': msg['content'] ?? '',
              'senderId': msg['sender_id'] ?? '',
              'senderName': msg['sender_name'] ?? 'Unknown',
              'time': timeStr,
              'timestamp': msgDate ?? DateTime.now(),
              'isMe': msg['sender_id'] == _userId,
              'messageType': (msg['message_type'] ?? 'text').toString().split('.').last.toLowerCase(),
              'metaData': msg['meta_data'],
            });
          }
          _controller.add(List.from(_messages));
        }
      }
    } catch (e) {
      print('Error fetching history: $e');
    }

    // Convert http://... to ws://...
    final wsBase = ApiConfig.baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
    final wsUrl = Uri.parse('$wsBase/ws/groups/$groupId?token=$token');
    
    try {
      _channel = WebSocketChannel.connect(wsUrl);
      
      _channel?.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (data['type'] == 'chat') {
              // Deduplicate optimistic messages
              final msgId = data['id']?.toString() ?? '';
              final content = data['content']?.toString() ?? '';
              final senderId = data['sender_id']?.toString() ?? '';
              
              // Check if we already have this message (from optimistic update)
              final isMe = senderId == _userId;
              final msgType = (data['message_type'] ?? 'text').toString().split('.').last.toLowerCase();
              final metaData = data['meta_data'];
              final existingIndex = _messages.indexWhere((m) => 
                m['isMe'] == true && m['text'] == content && m['messageType'] == msgType &&
                (DateTime.now().millisecondsSinceEpoch - (int.tryParse(m['id'].toString()) ?? 0)) < 5000
              );

              if (existingIndex != -1 && isMe) {
                // Update existing optimistic message with real ID
                _messages[existingIndex]['id'] = msgId;
              } else {
                String timeStr = 'Just now';
                DateTime msgDate = DateTime.now();
                if (data['created_at'] != null) {
                  try {
                    msgDate = DateTime.parse(data['created_at']).toLocal();
                    timeStr = _formatTime(msgDate);
                  } catch (_) {}
                } else {
                  timeStr = _formatTime(msgDate);
                }

                _messages.add({
                  'id': msgId.isNotEmpty ? msgId : DateTime.now().millisecondsSinceEpoch.toString(),
                  'text': content,
                  'senderId': senderId,
                  'senderName': data['sender_name'] ?? 'Unknown',
                  'time': timeStr,
                  'timestamp': msgDate,
                  'isMe': isMe,
                  'messageType': msgType,
                  'metaData': metaData,
                });
              }
              _controller.add(List.from(_messages));
            } else if (data['type'] == 'location' && _userId != null) {
              // Handle live location update
              final uId = data['user_id'].toString();
              // Ignore our own updates from websocket (we update locally instantly)
              if (uId != _userId) {
                _liveLocations[uId] = {
                  'lat': data['lat'],
                  'lng': data['lng'],
                  'timestamp': data['timestamp'],
                  'user_id': uId,
                  'isMe': false,
                  if (data['speed'] != null) 'speed': data['speed'],
                  if (data['battery'] != null) 'battery': data['battery'],
                };
                _locationController.add(Map.from(_liveLocations));
                
                // If this is our target user, update route
                if (targetUserId == uId && _liveLocations.containsKey(_userId)) {
                   _triggerRouteFetch();
                }
              }
            }
          } catch (e) {
            print('Error parsing websocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket Error: $error');
        },
        onDone: () {
          print('WebSocket Closed');
        },
      );
    } catch (e) {
      print('WebSocket Connection Error: $e');
    }
  }

  void sendMessage(String text, {String messageType = 'text', Map<String, dynamic>? metaData}) {
    if (text.isEmpty && metaData == null) return;
    if (_userId == null) return;
    
    final message = {
      'type': 'chat',
      'content': text,
      'message_type': messageType,
      if (metaData != null) 'meta_data': metaData,
    };
    
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
    
    // Optimistic UI update
    final now = DateTime.now();
    _messages.add({
      'id': now.millisecondsSinceEpoch.toString(), // Temp ID
      'text': text,
      'senderId': _userId,
      'senderName': _userName,
      'time': _formatTime(now),
      'timestamp': now,
      'isMe': true,
      'messageType': messageType,
      'metaData': metaData,
    });
    
    _controller.add(List.from(_messages));
  }

  // Live Location Methods
  Future<bool> toggleLiveLocationSharing() async {
    if (_isSharingLocation) {
      stopLiveLocationSharing();
      return false;
    } else {
      return await startLiveLocationSharing();
    }
  }

  void setShareDuration(Duration? duration) {
    _shareTimer?.cancel();
    if (duration != null) {
      _shareTimer = Timer(duration, () {
        stopLiveLocationSharing();
      });
    }
  }

  void setShareDurationString(String? str) {
    shareDurationString = str;
  }

  Future<bool> startLiveLocationSharing() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return false; // Permission denied
      }
    }

    _isSharingLocation = true;
    
    // Broadcast initial location immediately
    forceRefresh();

    // Subscribe to continuous updates
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) {
      _sendLocationUpdate(position.latitude, position.longitude, speed: position.speed);
    });
    
    return true;
  }

  Future<void> forceRefresh() async {
    if (!_isSharingLocation || isLocationPaused) {
      // If paused, we want to broadcast without location, or just update the UI
      // Let's at least update local UI if paused
      if (_userId != null && _liveLocations.containsKey(_userId!)) {
         final currentLoc = _liveLocations[_userId!]!;
         currentLoc['battery'] = hideBattery ? null : await _battery.batteryLevel.catchError((_) => null);
         currentLoc['speed'] = hideSpeed ? null : currentLoc['speed'];
         _locationController.add(Map.from(_liveLocations));
      }
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await _sendLocationUpdate(pos.latitude, pos.longitude, speed: pos.speed);
    } catch (e) {
      print('Refresh fetch failed: $e');
    }
  }

  Future<void> _sendLocationUpdate(double lat, double lng, {double? speed}) async {
    if (isLocationPaused) return;

    int? batteryLevel;
    if (!hideBattery) {
      try {
        batteryLevel = await _battery.batteryLevel;
      } catch (_) {}
    }

    if (_channel != null && _userId != null) {
      final message = {
        'type': 'location',
        'lat': lat,
        'lng': lng,
        if (!hideSpeed && speed != null) 'speed': speed * 3.6, // Convert m/s to km/h
        if (batteryLevel != null) 'battery': batteryLevel,
      };
      _channel!.sink.add(jsonEncode(message));
      
      // Optimistically update our own location on the map
      _liveLocations[_userId!] = {
        'lat': lat,
        'lng': lng,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'user_id': _userId,
        'isMe': true,
        if (!hideSpeed && speed != null) 'speed': speed * 3.6,
        if (batteryLevel != null) 'battery': batteryLevel,
      };
      _locationController.add(Map.from(_liveLocations));
      
      // Update route if we are moving and tracking someone
      if (targetUserId != null && _liveLocations.containsKey(targetUserId)) {
        _triggerRouteFetch();
      }
    }
  }

  void stopLiveLocationSharing() {
    _isSharingLocation = false;
    isLocationPaused = false;
    _shareTimer?.cancel();
    _shareTimer = null;
    shareDurationString = 'Until I stop';
    _positionSubscription?.cancel();
    _positionSubscription = null;
    cancelRoute();
    
    // Remove ourselves from local map
    if (_userId != null) {
      _liveLocations.remove(_userId!);
      _locationController.add(Map.from(_liveLocations));
    }
    
    // Optional: send a 'stop_location' event to backend so others know we stopped
  }

  void setRouteTarget(String uId, String userName) {
    targetUserId = uId;
    targetUserName = userName;
    _triggerRouteFetch(force: true);
  }
  
  void cancelRoute() {
    targetUserId = null;
    targetUserName = null;
    _routeController.add([]);
  }

  Future<void> _triggerRouteFetch({bool force = false}) async {
    if (targetUserId == null || _userId == null) return;
    
    final myLoc = _liveLocations[_userId];
    final targetLoc = _liveLocations[targetUserId];
    if (myLoc == null || targetLoc == null) return;
    
    // Throttle requests to once every 10 seconds to avoid spamming Google API
    if (!force && _lastRouteFetchTime != null) {
      if (DateTime.now().difference(_lastRouteFetchTime!).inSeconds < 10) {
        return;
      }
    }
    
    _lastRouteFetchTime = DateTime.now();
    
    try {
      final origin = '${myLoc['lat']},${myLoc['lng']}';
      final dest = '${targetLoc['lat']},${targetLoc['lng']}';
      
      final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$dest&key=${ApiConfig.googleMapsApiKey}';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final decodedPoints = _decodePolyline(points);
          _routeController.add(decodedPoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList());
        }
      }
    } catch (e) {
      print('Failed to fetch route: $e');
    }
  }

  // Decodes Google Maps polyline string
  List<Position> _decodePolyline(String poly) {
    var list = poly.codeUnits;
    var lList = <Position>[];
    int index = 0;
    int len = poly.length;
    int c = 0;
    
    int shift = 0;
    int result = 0;
    
    int lat = 0;
    int lng = 0;
    
    while (index < len) {
      shift = 0;
      result = 0;
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << shift;
        shift += 5;
        index++;
      } while (c >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << shift;
        shift += 5;
        index++;
      } while (c >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      lList.add(Position(
        latitude: lat / 100000.0,
        longitude: lng / 100000.0,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      ));
    }
    return lList;
  }

  void dispose() {
    stopLiveLocationSharing();
    _channel?.sink.close();
    _controller.close();
    _locationController.close();
  }
}
