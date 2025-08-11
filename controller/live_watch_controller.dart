import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class LiveWatchController extends GetxController {
  static const String _appId = "your_app_id";
  String _token = "";
  String _channelName = '';

  void initializeStream(String token, String channelName) {
    _token = token;
    _channelName = channelName;
    initializeAgora();
  }

  static const int _uid = 0;

  // Reactive state variables
  final isLoading = true.obs;
  final errorMessage = RxString('');
  final isJoined = false.obs;
  final remoteUid = RxInt(0);

  // Comments functionality
  final RxList<Map<String, String>> comments =
      <Map<String, String>>[
        // {'user': 'Sarah123', 'message': 'Looking amazing today! 💕'},
        // {'user': 'Mike_92', 'message': 'Great content as always'},
        // {
        //   'user': 'Emma_Style',
        //   'message': 'Love that outfit! Where did you get it?',
        // },
        // {'user': 'David_K', 'message': '❤️❤️❤️'},
        // {'user': 'Lisa_M', 'message': 'You inspire me every day ✨'},
        // {'user': 'John_Doe', 'message': '❤️'},
        // {'user': 'Anna_B', 'message': 'Such positive vibes! 🌟'},
        // {'user': 'CurrentUser', 'message': '❤️'},
      ].obs;

  // Agora engine instance
  RtcEngine? _agoraEngine;
  RtcEngineEventHandler? _rtcEngineEventHandler;

  @override
  void onInit() {
    super.onInit();
    initializeAgora();
  }

  @override
  void onClose() {
    _disposeAgora();
    super.onClose();
  }

  Future<void> initializeAgora() async {
    try {
      await _setupVideoSDKEngine();
      isLoading.value = false;
    } catch (e) {
      errorMessage.value = 'Failed to initialize video: $e';
      isLoading.value = false;
    }
  }

  Future<void> retry() async {
    errorMessage.value = '';
    isLoading.value = true;
    await initializeAgora();
  }

  Future<void> _disposeAgora() async {
    try {
      await _agoraEngine?.leaveChannel();
      await _agoraEngine?.release();
      _agoraEngine = null;
    } catch (e) {
      debugPrint('Error disposing Agora engine: $e');
    }
  }

  Future<void> _setupVideoSDKEngine() async {
    try {
      // Only request microphone permission for audience (no camera needed)
      final statuses = await [Permission.microphone].request();

      if (statuses[Permission.microphone] != PermissionStatus.granted) {
        throw Exception('Microphone permission is required');
      }

      _agoraEngine = createAgoraRtcEngine();

      await _agoraEngine?.initialize(
        RtcEngineContext(
          appId: _appId,
          logConfig: const LogConfig(
            filePath: 'agora.log',
            fileSizeInKB: 1024,
            level: LogLevel.logLevelDebug,
          ),
        ),
      );

      await _agoraEngine?.enableVideo();

      _setupEventHandlers();
      await _joinChannel();

      // Set timeout for join failure
      Future.delayed(const Duration(seconds: 10), () {
        if (!isJoined.value) {
          errorMessage.value =
              'Failed to join channel within 10 seconds. Please check your token and network connection.';
        }
      });
    } catch (e) {
      errorMessage.value = 'Failed to initialize: $e';
      isLoading.value = false;
      rethrow;
    }
  }

  void _setupEventHandlers() {
    _rtcEngineEventHandler = RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        isJoined.value = true;
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        this.remoteUid.value = remoteUid;
      },
      onUserOffline: (connection, remoteUid, reason) {
        this.remoteUid.value = 0;
      },
      onError: (err, msg) {
        errorMessage.value =
            'Agora Error (${err.name}): ${_getErrorMessage(err)}';
      },
      onRequestToken: (connection) {
        errorMessage.value = 'Token expired. Please refresh the token.';
      },
      onTokenPrivilegeWillExpire: (connection, token) {
        // Token refresh logic can be implemented here
      },
      onConnectionStateChanged: (connection, state, reason) {
        if (state == ConnectionStateType.connectionStateFailed) {
          errorMessage.value = 'Connection failed. Reason: ${reason.name}';
        }
      },
      onConnectionLost: (connection) {
        errorMessage.value = 'Connection lost. Please try again.';
      },
      onLeaveChannel: (connection, stats) {
        isJoined.value = false;
        remoteUid.value = 0;
      },
    );

    _agoraEngine?.registerEventHandler(_rtcEngineEventHandler!);
  }

  Future<void> _joinChannel() async {
    // Set client role to audience
    await _agoraEngine?.setClientRole(role: ClientRoleType.clientRoleAudience);

    await _agoraEngine?.joinChannel(
      token: _token.isEmpty ? '' : _token,
      channelId: _channelName,
      uid: _uid,
      options: const ChannelMediaOptions(
        publishCameraTrack: false, // Audience doesn't publish
        publishMicrophoneTrack: false, // Audience doesn't publish
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );
  }

  void sendHeartComment() {
    comments.add({'user': 'You', 'message': '❤️'});
  }

  void sendComment(String message) {
    if (message.trim().isEmpty) return;
    comments.add({'user': 'You', 'message': message.trim()});
  }

  List<Map<String, String>> getDisplayComments() {
    return comments.length > 5
        ? comments.sublist(comments.length - 5)
        : comments.toList();
  }

  String _getErrorMessage(ErrorCodeType errorCode) {
    switch (errorCode) {
      case ErrorCodeType.errInvalidToken:
        return 'Invalid or expired token. Please generate a new token.';
      case ErrorCodeType.errTokenExpired:
        return 'Token has expired. Please generate a new token.';
      case ErrorCodeType.errInvalidChannelName:
        return 'Invalid channel name.';
      case ErrorCodeType.errJoinChannelRejected:
        return 'Join channel rejected. Please check your credentials.';
      default:
        return 'Unknown error occurred.';
    }
  }

  // Getters
  RtcEngine? get agoraEngine => _agoraEngine;
  String get channelName => _channelName;
  bool get hasError => errorMessage.value.isNotEmpty;
  bool get isWaitingForBroadcaster => isJoined.value && remoteUid.value == 0;
}
