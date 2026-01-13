// lib/test_lobby.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'features/video/video_provider.dart';
import 'features/video/ui/video_screen.dart';

class TestLobby extends ConsumerWidget {
  const TestLobby({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("DIBS Video Test"),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // HOST BUTTON
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              icon: const Icon(Icons.videocam, color: Colors.black),
              label: const Text("Start as HOST", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              onPressed: () async {
                // 1. Request permissions
                await [Permission.camera, Permission.microphone].request();
                
                // 2. Join the channel via Provider
                // Channel: "test_room", isHost: true, uid: 100
                await ref.read(videoProvider.notifier).join("test_room", true, 100);

                // 3. Navigate to Video Screen
                if (context.mounted) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const VideoScreen(channelId: "test_room", isHost: true),
                  ));
                }
              },
            ),

            const SizedBox(height: 30),

            // VIEWER BUTTON
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              icon: const Icon(Icons.visibility, color: Colors.white),
              label: const Text("Join as VIEWER", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                // Viewers don't strictly need mic/cam, but good for testing
                await [Permission.camera, Permission.microphone].request();

                // Channel: "test_room", isHost: false, uid: 200 (random ID)
                await ref.read(videoProvider.notifier).join("test_room", false, 200);

                if (context.mounted) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const VideoScreen(channelId: "test_room", isHost: false),
                  ));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}