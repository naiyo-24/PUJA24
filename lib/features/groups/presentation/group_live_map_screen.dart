import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_config.dart';
import '../data/group_websocket_service.dart';
import 'group_info_screen.dart';

class GroupLiveMapScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupLiveMapScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupLiveMapScreen> createState() => _GroupLiveMapScreenState();
}

class _GroupLiveMapScreenState extends ConsumerState<GroupLiveMapScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;
  LatLng _initialPosition = const LatLng(22.5726, 88.3639); // Default to Kolkata
  
  // Cache for custom marker icons
  final Map<String, BitmapDescriptor> _customIcons = {};

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      setState(() {
        _initialPosition = LatLng(pos.latitude, pos.longitude);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _centerOnMe() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 15),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get your location.')),
        );
      }
    }
  }

  Future<ui.Image?> _loadImageFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Completer<ui.Image> completer = Completer();
        ui.decodeImageFromList(response.bodyBytes, (ui.Image img) {
          return completer.complete(img);
        });
        return await completer.future;
      }
    } catch (_) {}
    return null;
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(String name, String snippet, bool isMe, {double? speed, int? battery, String? imageUrl}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 150.0;
    
    // Draw glowing border if me
    if (isMe) {
      final Paint glowPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(const Offset(75, 75), 60, glowPaint);
      
      final Paint borderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
      canvas.drawCircle(const Offset(75, 75), 53, borderPaint);
    }
    
    // Draw white background
    final Paint bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(75, 75), 50, bgPaint);
    
    // Clip circle for image
    canvas.save();
    Path clipPath = Path()..addOval(Rect.fromCircle(center: const Offset(75, 75), radius: 50));
    canvas.clipPath(clipPath);

    ui.Image? profileImg;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      profileImg = await _loadImageFromUrl(imageUrl);
    }

    if (profileImg != null) {
      // Draw image filling the circle
      paintImage(
        canvas: canvas,
        rect: const Rect.fromLTWH(25, 25, 100, 100),
        image: profileImg,
        fit: BoxFit.cover,
      );
    } else {
      // Draw initial fallback
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(
        text: name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 40, color: Colors.black, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(75 - (textPainter.width / 2), 75 - (textPainter.height / 2)));
    }
    
    canvas.restore(); // Restore clip
    
    // Draw pill below
    final pillRect = RRect.fromLTRBR(10, 130, 140, 175, const Radius.circular(25));
    canvas.drawRRect(pillRect, Paint()..color = Colors.white);
    
    // Pill shadow/border
    canvas.drawRRect(pillRect, Paint()..color = Colors.black.withOpacity(0.1)..style = PaintingStyle.stroke..strokeWidth = 2);
    
    final nameLabel = isMe ? '$name (you)' : name;
    final namePainter = TextPainter(textDirection: TextDirection.ltr);
    namePainter.text = TextSpan(
      text: nameLabel,
      style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
    );
    namePainter.layout(maxWidth: 120);
    namePainter.paint(canvas, Offset(75.0 - (namePainter.width / 2), 135.0));
    
    if (snippet.isNotEmpty) {
      String fullSnippet = snippet;
      if (speed != null) fullSnippet += ' • ${speed.toStringAsFixed(0)} km/h';
      if (battery != null) fullSnippet += ' • $battery% 🔋';
      
      final subTextPainter = TextPainter(textDirection: TextDirection.ltr);
      subTextPainter.text = TextSpan(
        text: fullSnippet,
        style: TextStyle(
          fontSize: 12, 
          color: battery != null && battery < 20 ? Colors.red : Colors.green[700], 
          fontWeight: FontWeight.w700
        ),
      );
      subTextPainter.layout(maxWidth: 130);
      subTextPainter.paint(canvas, Offset(75.0 - (subTextPainter.width / 2), 155.0));
    }
    
    final ui.Picture p = pictureRecorder.endRecording();
    final ui.Image image = await p.toImage(150, 185);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final liveLocationsAsync = ref.watch(groupLocationsProvider(widget.groupId));
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
    final wsService = ref.watch(groupWebsocketServiceProvider(widget.groupId));

    // Build markers from the stream
    _markers.clear();
    
    Map<String, String> userNames = {};
    Map<String, String?> userImages = {};
    
    membersAsync.whenData((members) {
      for (var member in members) {
        if (member['user_id'] != null) {
          final uId = member['user_id'].toString();
          userNames[uId] = member['full_name'] ?? 'Unknown User';
          
          // Try fetching the profile picture from the API response payload
          String? pfp = member['profile_image_url'];
          if (pfp == null && member['user'] != null) {
             pfp = member['user']['profile_image_url'];
          }
          if (pfp != null && pfp.startsWith('/')) {
            pfp = '${ApiConfig.baseUrl}$pfp';
          }
          userImages[uId] = pfp;
        }
      }
    });

    liveLocationsAsync.whenData((locations) {
      locations.forEach((userId, locData) {
        final lat = locData['lat'];
        final lng = locData['lng'];
        final isMe = locData['isMe'] == true;
        final timestampStr = locData['timestamp'];
        
        DateTime? timestamp;
        if (timestampStr != null) {
          try {
            timestamp = DateTime.parse(timestampStr).toLocal();
          } catch (_) {}
        }
        
        String snippet = 'Live';
        if (timestamp != null) {
          final diff = DateTime.now().difference(timestamp);
          if (diff.inMinutes > 0) {
            snippet = 'Updated ${diff.inMinutes}m ago';
          }
        }

        if (lat != null && lng != null) {
          final userName = userNames[userId] ?? 'Unknown User';
          final userImageUrl = userImages[userId];
          
          final speed = locData['speed'];
          final battery = locData['battery'];
          
          final cacheKey = '${userId}_${snippet}_${isMe}_${speed}_${battery}_$userImageUrl';
          
          if (!_customIcons.containsKey(cacheKey)) {
            // Generate it asynchronously but don't block
            _createCustomMarkerBitmap(
              userName, 
              snippet, 
              isMe,
              speed: speed != null ? (speed as num).toDouble() : null,
              battery: battery != null ? (battery as num).toInt() : null,
              imageUrl: userImageUrl,
            ).then((bmp) {
              if (mounted) {
                setState(() {
                  _customIcons[cacheKey] = bmp;
                });
              }
            });
          }

          final marker = Marker(
            markerId: MarkerId(userId),
            position: LatLng(lat, lng),
            icon: _customIcons[cacheKey] ?? BitmapDescriptor.defaultMarkerWithHue(isMe ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueRed),
            zIndex: isMe ? 2 : 1,
            onTap: () {
              if (!isMe) {
                ref.read(groupWebsocketServiceProvider(widget.groupId)).setRouteTarget(userId, userName);
              }
            },
          );
          _markers.add(marker);
        }
      });
    });
    
    final routeAsync = ref.watch(routeStreamProvider(widget.groupId));
    
    _polylines.clear();
    routeAsync.whenData((routePoints) {
      if (routePoints.isNotEmpty) {
        _polylines.add(Polyline(
          polylineId: const PolylineId('live_route'),
          points: routePoints.map((p) => LatLng(p['lat'], p['lng'])).toList(),
          color: Colors.blue,
          width: 5,
          geodesic: true,
          jointType: JointType.round,
        ));
      }
    });

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition,
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
                _buildFloatingTopBar(context, membersAsync, liveLocationsAsync, wsService),
                if (wsService.targetUserId != null)
                  Positioned(
                    top: 110,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.directions_walk, color: Colors.white),
                              const SizedBox(width: 12),
                              Text(
                                'Routing to ${wsService.targetUserName}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              wsService.cancelRoute();
                            },
                            child: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'center_me',
            backgroundColor: AppColors.pureWhite,
            child: const Icon(Icons.my_location, color: AppColors.textPrimary),
            onPressed: _centerOnMe,
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'toggle_live',
            backgroundColor: wsService.isSharingLocation ? Colors.red : AppColors.pujaRed,
            icon: Icon(
              wsService.isSharingLocation ? Icons.stop_rounded : Icons.share_location_rounded,
              color: Colors.white,
            ),
            label: Text(
              wsService.isSharingLocation ? 'Stop Sharing' : 'Share Live Location',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              final started = await wsService.toggleLiveLocationSharing();
              if (mounted) {
                if (started) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Started broadcasting live location')),
                  );
                }
                setState(() {}); // Trigger rebuild to update button state
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTopBar(
    BuildContext context, 
    AsyncValue<List<Map<String, dynamic>>> membersAsync,
    AsyncValue<Map<String, Map<String, dynamic>>> locationsAsync,
    GroupWebsocketService wsService
  ) {
    int totalMembers = 0;
    int liveMembers = 0;
    
    membersAsync.whenData((members) => totalMembers = members.length);
    locationsAsync.whenData((locations) => liveMembers = locations.length);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
                onPressed: () => context.pop(),
              ),
            ),
            
            // Group Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  // Placeholder for group icon (could fetch from group details provider if needed)
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.orange[200],
                    child: const Text('📍', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Live Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Row(
                        children: [
                          Text('$totalMembers members • ', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          Text('$liveMembers live', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.black, size: 20),
                onPressed: () => _showPrivacySettingsSheet(context, ref, wsService),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacySettingsSheet(BuildContext context, WidgetRef ref, GroupWebsocketService wsService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Sharing & privacy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Control what this group can see. You\'re always in charge.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 24),
                  
                  // Toggles
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pause my location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text('Freeze your sharing without leaving', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    value: wsService.isLocationPaused,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.black,
                    inactiveThumbColor: Colors.grey[400],
                    inactiveTrackColor: Colors.grey[200],
                    onChanged: (val) {
                      setModalState(() => wsService.isLocationPaused = val);
                      wsService.forceRefresh();
                      setState(() {});
                    },
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hide my battery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text('Don\'t show my battery level', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    value: wsService.hideBattery,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.black,
                    inactiveThumbColor: Colors.grey[400],
                    inactiveTrackColor: Colors.grey[200],
                    onChanged: (val) {
                      setModalState(() => wsService.hideBattery = val);
                      wsService.forceRefresh();
                      setState(() {});
                    },
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hide my speed', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text('Don\'t reveal how fast I\'m moving', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    value: wsService.hideSpeed,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.black,
                    inactiveThumbColor: Colors.grey[400],
                    inactiveTrackColor: Colors.grey[200],
                    onChanged: (val) {
                      setModalState(() => wsService.hideSpeed = val);
                      wsService.forceRefresh();
                      setState(() {});
                    },
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  
                  const SizedBox(height: 24),
                  const Text('Share for', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 16),
                  
                  // Duration Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildDurationPill('2 hours', () {
                          wsService.setShareDurationString('2 hours');
                          wsService.setShareDuration(const Duration(hours: 2));
                          setModalState(() {});
                        }, isSelected: wsService.shareDurationString == '2 hours'),
                        const SizedBox(width: 8),
                        _buildDurationPill('4 hours', () {
                          wsService.setShareDurationString('4 hours');
                          wsService.setShareDuration(const Duration(hours: 4));
                          setModalState(() {});
                        }, isSelected: wsService.shareDurationString == '4 hours'),
                        const SizedBox(width: 8),
                        _buildDurationPill('Tonight', () {
                          wsService.setShareDurationString('Tonight');
                          final now = DateTime.now();
                          final tonight = DateTime(now.year, now.month, now.day, 23, 59, 59);
                          wsService.setShareDuration(tonight.difference(now));
                          setModalState(() {});
                        }, isSelected: wsService.shareDurationString == 'Tonight'),
                        const SizedBox(width: 8),
                        _buildDurationPill('Until I stop', () {
                          wsService.setShareDurationString('Until I stop');
                          wsService.setShareDuration(null);
                          setModalState(() {});
                        }, isSelected: wsService.shareDurationString == 'Until I stop' || wsService.shareDurationString == null),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDurationPill(String label, VoidCallback onTap, {bool isSelected = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pujaRed.withOpacity(0.1) : Colors.white,
          border: Border.all(color: isSelected ? AppColors.pujaRed : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.pujaRed : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
