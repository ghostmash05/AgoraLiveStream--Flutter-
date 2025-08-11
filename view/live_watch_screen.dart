import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:jules4tim/feature/pastor_flow/live_stream_screen/controller/live_watch_controller.dart';

class LiveWatchScreen extends StatefulWidget {
  LiveWatchScreen({super.key, required this.token, required this.channelName}) {
    assert(token.isNotEmpty, 'Token cannot be empty');
    assert(channelName.isNotEmpty, 'Channel name cannot be empty');
  }

  final String token;
  final String channelName;
  final String title = Get.arguments;

  @override
  State<LiveWatchScreen> createState() => _LiveWatchScreenState();
}

class _LiveWatchScreenState extends State<LiveWatchScreen> {
  late final LiveWatchController controller;
  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(LiveWatchController());
    controller.initializeStream(widget.token, widget.channelName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        // Loading state
        if (controller.isLoading.value) {
          return _buildLoadingScreen();
        }

        // Error state
        if (controller.hasError) {
          return _buildErrorScreen(controller);
        }

        // Main live stream UI
        return _buildLiveStreamUI(context, controller, commentController);
      }),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 16),
          Text('Joining live stream...', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(LiveWatchController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Error: ${controller.errorMessage.value}',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.retry,
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
    );
  }

  Widget _buildLiveStreamUI(
    BuildContext context,
    LiveWatchController controller,
    TextEditingController commentController,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Main video view (remote broadcaster)
          _buildVideoView(controller),

          // Top bar with back button and viewer count
          _buildTopBar(context),

          // Comments section
          _buildCommentsSection(controller),

          // Heart button
          _buildHeartButton(controller),

          // Comment input
          _buildCommentInput(controller, commentController),
        ],
      ),
    );
  }

  Widget _buildVideoView(LiveWatchController controller) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Obx(() {
        if (controller.remoteUid.value != 0) {
          return AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: controller.agoraEngine!,
              canvas: VideoCanvas(
                uid: controller.remoteUid.value,
                renderMode: RenderModeType.renderModeHidden,
              ),
              connection: RtcConnection(channelId: controller.channelName),
            ),
          );
        } else {
          return Container(
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
                    'Waiting for broadcaster...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        }
      }),
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
              children: [
                // Back button
                GestureDetector(
                  onTap: Get.back,
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFBFE91F).withValues(alpha: 0.15),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Profile section
                Stack(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/live.png'),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 10.w),

                // Streamer name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                const Spacer(),

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

  Widget _buildCommentsSection(LiveWatchController controller) {
    return Positioned(
      bottom:
          100 +
          MediaQuery.of(
            Get.context!,
          ).padding.bottom, // Above input with safe area
      left: 16,
      right: 80, // Leave space for heart button
      child: Container(
        height: 200,
        child: Obx(() {
          final displayComments = controller.getDisplayComments();
          return ListView.builder(
            reverse: true,
            itemCount: displayComments.length,
            itemBuilder: (context, index) {
              final commentIndex = displayComments.length - 1 - index;
              final comment = displayComments[commentIndex];
              return _buildCommentBubble(comment['user']!, comment['message']!);
            },
          );
        }),
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

  Widget _buildHeartButton(LiveWatchController controller) {
    return Positioned(
      bottom:
          110 +
          MediaQuery.of(
            Get.context!,
          ).padding.bottom, // Above input with safe area
      right: 16,
      child: GestureDetector(
        onTap: () {
          controller.sendHeartComment();
          // Show visual feedback
          Get.showSnackbar(
            GetSnackBar(
              message: '❤️ sent!',
              duration: const Duration(milliseconds: 800),
              backgroundColor: Colors.pink.withOpacity(0.8),
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(16),
              borderRadius: 8,
            ),
          );
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.pink.withOpacity(0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildCommentInput(
    LiveWatchController controller,
    TextEditingController commentController,
  ) {
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
                      controller: commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (message) {
                        controller.sendComment(message);
                        commentController.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      controller.sendComment(commentController.text);
                      commentController.clear();
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

  void _showTroubleshootingDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Troubleshooting Tips'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Check if your token is valid and not expired'),
            SizedBox(height: 8),
            Text('2. Ensure microphone permission is granted'),
            SizedBox(height: 8),
            Text('3. Verify your internet connection'),
            SizedBox(height: 8),
            Text('4. Try using a different channel name'),
            SizedBox(height: 8),
            Text('5. Make sure the broadcaster is live'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }
}
