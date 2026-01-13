import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'agora_service.dart';

// STATE CLASS: What does the UI need to know?
class VideoState {
  final bool isJoined;
  final int? localUid;
  final int? remoteHostUid; // The Seller's ID
  final RtcEngine? engine;

  VideoState({
    this.isJoined = false,
    this.localUid,
    this.remoteHostUid,
    this.engine,
  });

  VideoState copyWith({
    bool? isJoined,
    int? localUid,
    int? remoteHostUid,
    RtcEngine? engine,
  }) {
    return VideoState(
      isJoined: isJoined ?? this.isJoined,
      localUid: localUid ?? this.localUid,
      remoteHostUid: remoteHostUid ?? this.remoteHostUid,
      engine: engine ?? this.engine,
    );
  }
}

// THE PROVIDER
class VideoNotifier extends StateNotifier<VideoState> {
  late final AgoraService _service;

  VideoNotifier() : super(VideoState()) {
    _service = AgoraService(
      onJoined: (uid) => state = state.copyWith(isJoined: true, localUid: uid),
      
      // We assume the first remote user is the HOST (Seller)
      onUserJoined: (uid) => state = state.copyWith(remoteHostUid: uid),
      
      onUserOffline: (uid) {
        if (state.remoteHostUid == uid) {
          state = state.copyWith(remoteHostUid: null); // Host left
        }
      },
    );
  }

  Future<void> join(String channelId, bool isHost, int userId) async {
    await _service.initialize();
    
    // Update state with engine instance so UI can render video
    state = state.copyWith(engine: _service.engine); 
    
    await _service.joinChannel(
      channelId: channelId, 
      isHost: isHost, 
      uid: userId
    );
  }

  Future<void> leave() async {
    await _service.leaveChannel();
    state = VideoState(); // Reset state
  }
}

// Global Provider Definition
final videoProvider = StateNotifierProvider<VideoNotifier, VideoState>((ref) {
  return VideoNotifier();
});