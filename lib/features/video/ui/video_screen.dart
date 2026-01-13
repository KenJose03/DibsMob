// lib/features/video/ui/video_screen.dart

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../video_provider.dart'; // Adjust path if needed

class VideoScreen extends ConsumerWidget {
  final String channelId;
  final bool isHost;

  const VideoScreen({
    super.key,
    required this.channelId,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the state from your provider
    final videoState = ref.watch(videoProvider);
    final engine = videoState.engine;

    // 2. If engine is not ready, show loading
    if (engine == null || !videoState.isJoined) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    // 3. HOST VIEW: Show Local Camera
    if (isHost) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: engine,
          canvas: const VideoCanvas(uid: 0), // uid 0 = local user
        ),
      );
    }

    // 4. AUDIENCE VIEW: Show Remote Host
    // We wait until we know the Host's UID (from onUserJoined in provider)
    if (videoState.remoteHostUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine,
          canvas: VideoCanvas(uid: videoState.remoteHostUid),
          connection: RtcConnection(channelId: channelId),
        ),
      );
    }

    // 5. WAITING STATE (Audience connected, but Host hasn't joined yet)
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white24),
            const SizedBox(height: 20),
            Text(
              "Waiting for Host to join...",
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}