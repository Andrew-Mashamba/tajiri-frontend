// flutter_downloader not available — download functionality stubbed
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class ImageDownloaderPage extends StatefulWidget {
  const ImageDownloaderPage({super.key});

  @override
  _ImageDownloaderPageState createState() => _ImageDownloaderPageState();
}

class _ImageDownloaderPageState extends State<ImageDownloaderPage> {
  final int _progress = 0;
  String? _downloadTaskId;

  Future<void> _downloadFile() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      await getExternalStorageDirectory();
      // Download functionality stubbed — flutter_downloader not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Download not available")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission denied")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Image Downloader")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Download Progress: $_progress%"),
            ElevatedButton(
              onPressed: _downloadFile,
              child: const Text("Download Image"),
            ),
          ],
        ),
      ),
    );
  }
}
