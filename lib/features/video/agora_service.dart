import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

// Replace with your actual App ID from core/constants/constants.dart
// For now, hardcode it to test
const String appId = "YOUR_AGORA_APP_ID"; 

class AgoraService {
  RtcEngine? _engine;
  
  // Events exposed to the UI (via Riverpod later)
  final void Function(int localUid) onJoined;
  final void Function(int remoteUid) onUserJoined;
  final void Function(int remoteUid) onUserOffline;

  AgoraService({
    required this.onJoined,
    required this.onUserJoined,
    required this.onUserOffline,
  });

  /// 1. Initialize the Engine
  Future<void> initialize() async {
    // Request permissions first
    await [Permission.microphone, Permission.camera].request();

    if (_engine != null) return;

    // Create the engine
    _engine = createAgoraRtcEngine();
    
    await _engine!.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // Enable Video
    await _engine!.enableVideo();
    await _engine!.startPreview();

    // Register Event Handlers
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("✅ Local User ${connection.localUid} joined");
          onJoined(connection.localUid!);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("🎥 Remote User $remoteUid joined");
          onUserJoined(remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("❌ Remote User $remoteUid left");
          onUserOffline(remoteUid);
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("🚨 Agora Error $err: $msg");
        },
      ),
    );
  }

  /// 2. Join Channel
  Future<void> joinChannel({
    required String channelId,
    required bool isHost,
    required int uid, // User ID (must be int)
  }) async {
    if (_engine == null) await initialize();

    final options = ChannelMediaOptions(
      // HOST = Broadcaster, VIEWER = Audience
      clientRoleType: isHost 
          ? ClientRoleType.clientRoleBroadcaster 
          : ClientRoleType.clientRoleAudience,
      
      // CRITICAL: Low Latency for Viewers (Sub-second delay)
      audienceLatencyLevel: AudienceLatencyLevelType.audienceLatencyLevelLowLatency,
      
      // Auto-publish if host, Auto-subscribe if viewer
      publishCameraTrack: isHost,
      publishMicrophoneTrack: isHost,
      autoSubscribeVideo: true,
      autoSubscribeAudio: true,
    );

    // Join with "token" set to null (Insecure mode for Dev)
    await _engine!.joinChannel(
      token: "", 
      channelId: channelId,
      uid: uid,
      options: options,
    );
  }

  /// 3. Leave Channel
  Future<void> leaveChannel() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
    }
  }

  /// 4. Switch Role (e.g. Viewer becomes Host)
  Future<void> setRole({required bool isHost}) async {
    await _engine!.setClientRole(
      role: isHost 
          ? ClientRoleType.clientRoleBroadcaster 
          : ClientRoleType.clientRoleAudience,
    );
  }

  // Getter for the Engine (Used by the VideoView widget)
  RtcEngine? get engine => _engine;
}