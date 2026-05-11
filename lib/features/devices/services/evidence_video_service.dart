import 'dart:io';


import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class EvidenceVideoService {
  EvidenceVideoService._();

  static final EvidenceVideoService instance = EvidenceVideoService._();

  Future<String?> createAndUploadVideo({
    required String uid,
    required String alertId,
    required String streamUrl,
    required String audioUrl,
  }) async {
    try {
      debugPrint('VIDEO: start create video');

      if (streamUrl.trim().isEmpty || audioUrl.trim().isEmpty) {
        debugPrint('VIDEO: missing stream/audio url');
        return null;
      }

      final tempDir = await getTemporaryDirectory();

      final audioPath = '${tempDir.path}/seen_audio_$alertId.wav';
      final videoPath = '${tempDir.path}/seen_video_$alertId.mp4';

      final oldAudio = File(audioPath);
      final oldVideo = File(videoPath);

      if (await oldAudio.exists()) await oldAudio.delete();
      if (await oldVideo.exists()) await oldVideo.delete();

      debugPrint('VIDEO: downloading audio from $audioUrl');

      final audioResponse = await http.get(Uri.parse(audioUrl));

      if (audioResponse.statusCode != 200 || audioResponse.bodyBytes.isEmpty) {
        debugPrint('VIDEO: audio download failed ${audioResponse.statusCode}');
        return null;
      }

      await File(audioPath).writeAsBytes(audioResponse.bodyBytes);

      debugPrint('VIDEO: audio saved bytes=${audioResponse.bodyBytes.length}');
      debugPrint('VIDEO: recording stream from $streamUrl');

      



      

      final videoFile = File(videoPath);

      if (!await videoFile.exists()) {
        debugPrint('VIDEO: mp4 not generated');
        return null;
      }

      final size = await videoFile.length();
      debugPrint('VIDEO: mp4 size=$size');

      if (size <= 0) {
        debugPrint('VIDEO: empty mp4');
        return null;
      }

      final safeUid = uid.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final safeAlertId = alertId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('evidence')
          .child(safeUid)
          .child(safeAlertId)
          .child('video.mp4');

      debugPrint('VIDEO: uploading firebase');

      await storageRef.putFile(
        videoFile,
        SettableMetadata(
          contentType: 'video/mp4',
          customMetadata: {
            'uid': uid,
            'alertId': alertId,
            'source': 'necklace',
            'type': 'sos_video',
            'streamUrl': streamUrl,
            'audioUrl': audioUrl,
          },
        ),
      );

      final downloadUrl = await storageRef.getDownloadURL();

      debugPrint('VIDEO: uploaded $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('VIDEO ERROR: $e');
      return null;
    }
  }
}