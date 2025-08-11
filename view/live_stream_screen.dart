import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/live_stream_controller.dart';

class LiveStreamScreen extends StatefulWidget {
  LiveStreamScreen({
    super.key,
    required this.token,
    required this.channelName,
  }) {
    assert(token.isNotEmpty, 'Token cannot be empty');
    assert(channelName.isNotEmpty, 'Channel name cannot be empty');
  }

  final String token;
  final String channelName;

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  late final LiveStreamController _controller;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = Get.put(LiveStreamController());
    _controller.initializeStream(widget.token, widget.channelName);
  }

  // Sample comments for demonstration
  final List<Map<String, String>> _comments = [

  ];

  @override
  void dispose() {
    _commentController.dispose();
    Get.delete<LiveStreamController>();
    super.dispose();
  }

  void _sendComment(String message) {
    if (message.trim().isEmpty) return;

    setState(() {
      _comments.add({'user': 'You', 'message': message.trim()});
    });

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Initializing video call...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      }

      if (_controller.errorMessage.value.isNotEmpty) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Error: ${_controller.errorMessage.value}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _controller.initializeAgora,
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _showTroubleshootingDialog,
                  child: const Text(
                    'Troubleshooting Tips',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Main video view (local or remote) - Full screen
              _buildMainVideoView(),

              // Remote user video (picture-in-picture)
              _buildRemoteVideoView(),

              // Top bar with end live button and viewer count
              _buildTopBar(context),

              // Comments section - positioned just above the input
              _buildCommentsSection(),

              // Right side controls (mute and camera toggle)
              _buildControlButtons(),

              // Comment input at the bottom
              _buildCommentInput(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMainVideoView() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child:
          _controller.isJoined.value
              ? AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _controller.agoraEngine!,
                  canvas: const VideoCanvas(
                    uid: 0,
                    renderMode: RenderModeType.renderModeHidden,
                  ),
                ),
              )
              : Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Connecting to live stream...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildRemoteVideoView() {
    if (_controller.remoteUid.value <= 0) return const SizedBox.shrink();

    return Positioned(
      top: 60,
      right: 16,
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _controller.agoraEngine!,
              canvas: VideoCanvas(
                uid: _controller.remoteUid.value,
                renderMode: RenderModeType.renderModeHidden,
              ),
              connection: RtcConnection(channelId: _controller.channelName),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).padding.top + 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // End Live button
                GestureDetector(
                  onTap: _showEndLiveDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 8),
                        SizedBox(width: 4),
                        Text(
                          'End LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Viewer count
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '1826',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Positioned(
      bottom:
          100 +
          MediaQuery.of(context).padding.bottom, // Above input with safe area
      left: 16,
      right: 80, // Leave space for controls on the right
      child: Container(
        height: 200, // Fixed height for 4-5 comments
        child: ListView.builder(
          reverse: true, // Start from bottom
          itemCount:
              _comments.length > 5
                  ? 5
                  : _comments.length, // Show last 5 comments
          itemBuilder: (context, index) {
            final commentIndex = _comments.length - 1 - index;
            final comment = _comments[commentIndex];
            return _buildCommentBubble(comment['user']!, comment['message']!);
          },
        ),
      ),
    );
  }

  Widget _buildCommentBubble(String username, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white, fontSize: 14),
            children: [
              TextSpan(
                text: '$username ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: username == 'You' ? Colors.yellow : Colors.blue,
                ),
              ),
              TextSpan(text: message),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      bottom:
          110 +
          MediaQuery.of(context).padding.bottom, // Above input with safe area
      right: 16,
      child: Column(
        children: [
          // Mute button
          GestureDetector(
            onTap: _controller.toggleMute,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _controller.isMuted.value ? Icons.mic_off : Icons.mic,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Camera toggle button
          GestureDetector(
            onTap: _controller.switchCamera,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.switch_camera,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16,
            ), // Reduced top padding
            child: Container(
              height: 50, // Fixed height for input
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type your comment...',
                        hintStyle: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (message) {
                        _sendComment(message);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _sendComment(_commentController.text);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEndLiveDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('End Live Stream'),
            content: const Text(
              'Are you sure you want to end this live stream?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close live stream
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('End Live'),
              ),
            ],
          ),
    );
  }

  void _showTroubleshootingDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Troubleshooting Tips'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTroubleshootingItem('Check your internet connection'),
                _buildTroubleshootingItem(
                  'Make sure you have granted camera and microphone permissions',
                ),
                _buildTroubleshootingItem('Restart the app'),
                _buildTroubleshootingItem('Try again later'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildTroubleshootingItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
