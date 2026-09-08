import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:geolocator/geolocator.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_config.dart';
import '../data/group_websocket_service.dart';
import '../data/groups_api_service.dart';

// Provider to fetch details for this screen
final groupDetailsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, groupId) async {
  final apiService = ref.watch(groupsApiServiceProvider);
  return apiService.fetchGroupDetails(groupId);
});

class GroupDetailsScreen extends ConsumerStatefulWidget {
  final String groupId;
  
  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  List<Map<String, dynamic>> _messages = [];
  bool _isEmojiVisible = false;
  double _keyboardHeight = 300.0; // default height if keyboard hasn't opened yet
  
  // Local state to track which option the user voted for (by message ID)
  final Map<String, String> _pollVotes = {}; 
  
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _isEmojiVisible) {
        // Delay hiding the emoji picker until the keyboard has fully expanded
        // so the layout doesn't instantly jump
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) setState(() => _isEmojiVisible = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    // Send via websocket provider
    ref.read(groupWebsocketServiceProvider(widget.groupId)).sendMessage(
      _messageController.text.trim(), 
    );
    
    setState(() {
      _messageController.clear();
    });
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendAttachmentMessage(String text, String type, Map<String, dynamic> metaData) {
    ref.read(groupWebsocketServiceProvider(widget.groupId)).sendMessage(
      text, 
      messageType: type,
      metaData: metaData,
    );
    _scrollToBottom();
  }

  Future<void> _cropAndSendImage(String path) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: AppColors.pujaRed,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
        ),
      ],
    );

    if (croppedFile != null) {
      final apiService = ref.read(groupsApiServiceProvider);
      final uploadResult = await apiService.uploadChatFile(croppedFile.path);
      
      if (uploadResult != null) {
        _sendAttachmentMessage('Shared a photo', 'image', {
          'url': uploadResult['url'],
          'filename': uploadResult['filename'],
          'size': uploadResult['size'],
          'mime': 'image/jpeg',
        });
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image')));
      }
    }
  }

  Future<void> _handleGalleryAttachment() async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      await _cropAndSendImage(xfile.path);
    }
  }

  Future<void> _handleCameraAttachment() async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.camera);
    if (xfile != null) {
      await _cropAndSendImage(xfile.path);
    }
  }

  Future<void> _handleDocumentAttachment() async {
    Navigator.pop(context);
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.any,
    );

    if (result.isNotEmpty) {
      final file = result.first;
      if (file.path == null) return;
      
      final apiService = ref.read(groupsApiServiceProvider);
      final uploadResult = await apiService.uploadChatFile(file.path!);
      
      if (uploadResult != null) {
        _sendAttachmentMessage('Shared a document', 'document', {
          'url': uploadResult['url'],
          'filename': uploadResult['filename'],
          'size': uploadResult['size'],
          'extension': file.extension,
        });
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload document')));
      }
    }
  }

  Future<void> _handleLocationAttachment() async {
    Navigator.pop(context);
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied')));
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _sendAttachmentMessage('Shared a location', 'location', {
        'lat': position.latitude,
        'lng': position.longitude,
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    }
  }

  void _handlePollAttachment() {
    Navigator.pop(context);
    final questionController = TextEditingController();
    final opt1Controller = TextEditingController();
    final opt2Controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Poll'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: questionController, decoration: const InputDecoration(labelText: 'Question')),
            TextField(controller: opt1Controller, decoration: const InputDecoration(labelText: 'Option 1')),
            TextField(controller: opt2Controller, decoration: const InputDecoration(labelText: 'Option 2')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (questionController.text.isNotEmpty && opt1Controller.text.isNotEmpty && opt2Controller.text.isNotEmpty) {
                Navigator.pop(ctx);
                _sendAttachmentMessage(questionController.text, 'poll', {
                  'question': questionController.text,
                  'options': [
                    {'id': '1', 'text': opt1Controller.text, 'votes': []},
                    {'id': '2', 'text': opt2Controller.text, 'votes': []},
                  ]
                });
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _handleMockAttachment(String title, String type) {
    Navigator.pop(context);
    _sendAttachmentMessage('Shared a $title', type, {});
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    // Only capture the maximum keyboard height. This prevents the height from shrinking 
    // when the keyboard animates closed (which sends shrinking values like 150, 100, etc.)
    if (bottomInset > _keyboardHeight) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _keyboardHeight = bottomInset;
          });
        }
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupDetailsAsync = ref.watch(groupDetailsProvider(widget.groupId));
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.charcoal : AppColors.ivory,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: groupDetailsAsync.when(
          data: (group) {
            if (group == null) return const Text('Group not found');
            String emoji = '🥁';
            Color color = const Color(0xFFE53935);
            if (group['picture_url'] != null && group['picture_url'].toString().startsWith('{')) {
              try {
                final picData = jsonDecode(group['picture_url']);
                emoji = picData['emoji'] ?? emoji;
                if (picData['colorHex'] != null) {
                  color = Color(int.parse(picData['colorHex'].replaceAll('#', '0xFF')));
                }
              } catch (e) {}
            }

            return InkWell(
              onTap: () {
                context.push('/groups/info/${widget.groupId}');
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color.withOpacity(0.8), color],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group['name'] ?? 'Group', 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                        Text(
                          'Tap for info', 
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[500], fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Text('Loading...'),
          error: (e, s) => const Text('Error'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_rounded, color: AppColors.pujaRed),
            onPressed: () {
              context.push('/groups/live-map/${widget.groupId}');
            },
            tooltip: 'Live Tracking',
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded, color: AppColors.saffron),
            onPressed: () {
              // TODO: Open Itinerary
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Itinerary coming soon!')));
            },
            tooltip: 'Itinerary',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              context.push('/groups/info/${widget.groupId}');
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
                ? [const Color(0xFF121212), const Color(0xFF1A1A1A)] 
                : [const Color(0xFFFBF8F1), const Color(0xFFF2ECE0)],
          ),
        ),
        child: Column(
          children: [
          // Chat Messages
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final messagesAsyncValue = ref.watch(groupMessagesProvider(widget.groupId));
                
                return messagesAsyncValue.when(
                  data: (messages) {
                    final reversedMessages = messages.reversed.toList();
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: reversedMessages.length,
                      itemBuilder: (context, index) {
                        final message = reversedMessages[index];
                        final isMe = message['isMe'] as bool;
                        
                        bool showAvatar = true;
                        if (index < reversedMessages.length - 1 && reversedMessages[index + 1]['senderId'] == message['senderId']) {
                          showAvatar = false;
                        }
                        
                        bool showDateSeparator = false;
                        if (index == reversedMessages.length - 1) {
                          showDateSeparator = true;
                        } else {
                          final prevMsg = reversedMessages[index + 1];
                          final prevTime = prevMsg['timestamp'] as DateTime?;
                          final currTime = message['timestamp'] as DateTime?;
                          if (prevTime != null && currTime != null) {
                            if (prevTime.year != currTime.year || prevTime.month != currTime.month || prevTime.day != currTime.day) {
                              showDateSeparator = true;
                            }
                          }
                        }

                        final bubble = _buildMessageBubble(message, isMe, showAvatar, isDark);
                        
                        if (showDateSeparator) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDateSeparator(message['timestamp'] as DateTime?, isDark),
                              bubble,
                            ],
                          );
                        }
                        
                        return bubble;
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.pujaRed)),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                );
              },
            ),
          ),
          
          // Message Input Area
          SafeArea(
            bottom: !_isEmojiVisible, // Remove bottom safe area if emoji is showing to eliminate double gap
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      offset: const Offset(0, 4),
                      blurRadius: 24,
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isEmojiVisible ? Icons.keyboard : Icons.emoji_emotions_outlined, 
                        color: isDark ? Colors.white70 : Colors.black54
                      ),
                      onPressed: () async {
                        if (_isEmojiVisible) {
                          _focusNode.requestFocus();
                        } else {
                          FocusScope.of(context).unfocus();
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (mounted) {
                            setState(() => _isEmojiVisible = true);
                          }
                        }
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add_rounded, color: isDark ? Colors.white70 : Colors.black54),
                        onPressed: () {
                          // ... bottom sheet code remains same
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[900] : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 32,
                                runSpacing: 24,
                                children: [
                                  _buildAttachmentIcon(Icons.image_rounded, 'Gallery', Colors.purple, _handleGalleryAttachment),
                                  _buildAttachmentIcon(Icons.camera_alt_rounded, 'Camera', Colors.pink, _handleCameraAttachment),
                                  _buildAttachmentIcon(Icons.insert_drive_file_rounded, 'Document', Colors.orange, _handleDocumentAttachment),
                                  _buildAttachmentIcon(Icons.poll_rounded, 'Poll', Colors.teal, _handlePollAttachment),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE53935), Color(0xFFC62828)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53935).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isEmojiVisible)
            SizedBox(
              // Dynamically shrink the emoji picker container exactly as the keyboard grows
              // This perfectly balances the Scaffold resizing, holding the text field completely still!
              height: math.max(0.0, _keyboardHeight - MediaQuery.of(context).viewInsets.bottom),
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1.0,
                  child: SizedBox(
                    height: _keyboardHeight,
                    child: Container(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F2F5),
                      child: EmojiPicker(
                        textEditingController: _messageController,
                        config: Config(
                          bottomActionBarConfig: const BottomActionBarConfig(showBackspaceButton: false, showSearchViewButton: false),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  String _formatDateSeparator(DateTime? date) {
    if (date == null) return 'Unknown Date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      return 'Today';
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  Widget _buildDateSeparator(DateTime? date, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _formatDateSeparator(date),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe, bool showAvatar, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: showAvatar ? 16.0 : 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            if (showAvatar)
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.saffron.withOpacity(0.2),
                child: Text(
                  message['senderName'][0],
                  style: const TextStyle(color: AppColors.saffron, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              )
            else
              const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showAvatar && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message['senderName'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.pujaRed : (isDark ? Colors.grey[800] : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isMe || !showAvatar ? 20 : 4),
                      topRight: Radius.circular(!isMe || !showAvatar ? 20 : 4),
                      bottomLeft: const Radius.circular(20),
                      bottomRight: const Radius.circular(20),
                    ),
                    boxShadow: [
                      if (!isMe)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: _buildMessageContent(message, isMe, isDark),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Text(
                    message['time'] ?? '',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
          
          if (isMe) const SizedBox(width: 32), // Add spacing for 'isMe' so it matches avatar padding logic visually
        ],
      ),
    );
  }

  Widget _buildMessageContent(Map<String, dynamic> message, bool isMe, bool isDark) {
    final type = message['messageType'] ?? 'text';
    final metaData = message['metaData'] as Map<String, dynamic>?;
    final textColor = isMe ? Colors.white : (isDark ? Colors.white : Colors.black87);

    if (type == 'image' && metaData != null) {
      final base64Image = metaData['base64'];
      final url = metaData['url'];
      
      Widget? thumbnailWidget;
      Widget? fullScreenWidget;
      
      if (base64Image != null) {
        try {
          final bytes = base64Decode(base64Image);
          thumbnailWidget = Image.memory(bytes, width: 220, fit: BoxFit.cover);
          fullScreenWidget = Image.memory(bytes, fit: BoxFit.contain);
        } catch (_) {}
      } else if (url != null) {
        thumbnailWidget = Image.network('${ApiConfig.baseUrl}$url', width: 220, fit: BoxFit.cover);
        fullScreenWidget = Image.network('${ApiConfig.baseUrl}$url', fit: BoxFit.contain);
      }

      if (thumbnailWidget != null && fullScreenWidget != null) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  backgroundColor: Colors.black,
                  extendBodyBehindAppBar: true,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent, 
                    iconTheme: const IconThemeData(color: Colors.white, shadows: [Shadow(color: Colors.black87, blurRadius: 10)]),
                    elevation: 0,
                  ),
                  body: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: Center(
                      child: fullScreenWidget!,
                    ),
                  ),
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: thumbnailWidget,
              ),
              if (message['text'] != null && message['text'].toString().isNotEmpty && message['text'] != 'Shared an image' && message['text'] != 'Shared a photo')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(message['text'], style: TextStyle(color: textColor, fontSize: 15)),
                ),
            ],
          ),
        );
      }
    }

    if (type == 'location' && metaData != null) {
      final lat = metaData['lat'];
      final lng = metaData['lng'];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: isMe ? Colors.white : AppColors.pujaRed),
                const SizedBox(width: 8),
                Text('Location\n$lat, $lng', style: TextStyle(fontSize: 12, color: textColor)),
              ],
            ),
          ),
        ],
      );
    }

    if (type == 'poll' && metaData != null) {
      final question = metaData['question'] ?? 'Poll';
      final options = metaData['options'] as List<dynamic>? ?? [];
      final msgId = message['id']?.toString() ?? '';
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.poll, color: textColor, size: 20),
              const SizedBox(width: 8),
              Flexible(child: Text(question, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15))),
            ],
          ),
          const SizedBox(height: 12),
          ...options.map((opt) {
            final optId = opt['id']?.toString() ?? '';
            final optText = opt['text'] ?? '';
            final isSelected = _pollVotes[msgId] == optId;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _pollVotes[msgId] = optId;
                });
                // Note: Actual implementation would send the vote to the WebSocket here.
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 200,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AppColors.pujaRed.withOpacity(isMe ? 1.0 : 0.8) 
                    : (isMe ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.white.withOpacity(0.5) : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            optText, 
                            style: TextStyle(
                              color: isSelected ? Colors.white : textColor, 
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                            )
                          ),
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(top: 4.0),
                              child: Text('Voted: You', style: TextStyle(fontSize: 10, color: Colors.white70)),
                            ),
                        ],
                      ),
                    ),
                    if (isSelected) 
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    }

    if (type == 'document' && metaData != null) {
      final docName = metaData['filename'] ?? metaData['name'] ?? 'Document';
      final ext = metaData['extension']?.toString().toUpperCase() ?? 'FILE';
      final url = metaData['url'];
      
      return GestureDetector(
        onTap: () async {
          if (url != null) {
            final uri = Uri.parse('${ApiConfig.baseUrl}$url');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMe ? Colors.white.withOpacity(0.3) : AppColors.pujaRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(ext, style: TextStyle(color: isMe ? Colors.white : AppColors.pujaRed, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  docName,
                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500, decoration: url != null ? TextDecoration.underline : null),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (type == 'contact') {
       return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, color: textColor),
          const SizedBox(width: 8),
          Text(message['text'], style: TextStyle(color: textColor, fontSize: 15)),
        ],
      );
    }

    // Default text
    return Text(
      message['text'],
      style: TextStyle(color: textColor, fontSize: 15),
    );
  }

  Widget _buildAttachmentIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
