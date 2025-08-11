import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class LiveStreamController extends GetxController {
  static const String _appId = "";
  String _token = "";
  String _channelName = '';

  // Initialize stream with token and channel name
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
  final isMuted = false.obs;
  final remoteUid = RxInt(0);

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
      final statuses =
          await [Permission.microphone, Permission.camera].request();

      if (statuses[Permission.camera] != PermissionStatus.granted ||
          statuses[Permission.microphone] != PermissionStatus.granted) {
        throw Exception('Camera and microphone permissions are required');
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

      await _agoraEngine?.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 360),
          frameRate: 15,
          bitrate: 0,
          minBitrate: -1,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );

      _setupEventHandlers();
      await _joinChannel();
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
        errorMessage.value = 'Agora Error: ${_getErrorMessage(err)}';
      },
      onTokenPrivilegeWillExpire: (connection, token) {
        // Token refresh logic can be implemented here
      },
      onConnectionStateChanged: (connection, state, reason) {
        if (state == ConnectionStateType.connectionStateFailed) {
          errorMessage.value = 'Connection failed. Reason: $reason';
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
    await _agoraEngine?.setClientRole(
      role: ClientRoleType.clientRoleBroadcaster,
    );

    await _agoraEngine?.joinChannel(
      token: _token.isEmpty ? '' : _token,
      channelId: _channelName,
      uid: _uid,
      options: const ChannelMediaOptions(
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );
  }

  Future<void> switchCamera() async {
    try {
      await _agoraEngine?.switchCamera();
    } catch (e) {
      errorMessage.value = 'Failed to switch camera: $e';
    }
  }

  Future<void> toggleMute() async {
    try {
      await _agoraEngine?.muteLocalAudioStream(!isMuted.value);
      isMuted.toggle();
    } catch (e) {
      errorMessage.value = 'Failed to toggle mute: $e';
    }
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

  // Getter for Agora engine instance
  RtcEngine? get agoraEngine => _agoraEngine;

  // Getter for channel name
  String get channelName => _channelName;
}
