import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: ImageDownloaderPage());
  }
}

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
      final baseStorage = await getExternalStorageDirectory();
      final taskId = await FlutterDownloader.enqueue(
        url: 'https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/bigsize.jpg',
        savedDir: baseStorage!.path,
        showNotification: true,
        openFileFromNotification: true,
      );

      setState(() {
        _downloadTaskId = taskId;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permission denied")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    FlutterDownloader.registerCallback(downloadCallback as DownloadCallback);
  }

  static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
    // You can implement isolate communication to update progress here
    print("Download progress: $progress%");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flutter Downloader Example")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Download Progress: $_progress%"),
            ElevatedButton(
              onPressed: _downloadFile,
              child: Text("Download Image"),
            ),
          ],
        ),
      ),
    );
  }
}
