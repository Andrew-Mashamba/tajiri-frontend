/// Adaptive Bitrate Streaming Service
/// Dynamically adjusts stream quality based on network conditions
///
/// Features:
/// - Multiple quality levels (360p/720p/1080p)
/// - Automatic quality switching
/// - Bandwidth monitoring
/// - Network type detection

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Quality presets for adaptive streaming
class StreamQuality {
  final String name;
  final int width;
  final int height;
  final int bitrate; // kbps
  final int fps;
  final int audioBitrate; // kbps

  const StreamQuality({
    required this.name,
    required this.width,
    required this.height,
    required this.bitrate,
    required this.fps,
    required this.audioBitrate,
  });

  static const low = StreamQuality(
    name: 'low',
    width: 640,
    height: 360,
    bitrate: 800,
    fps: 30,
    audioBitrate: 64,
  );

  static const medium = StreamQuality(
    name: 'medium',
    width: 1280,
    height: 720,
    bitrate: 2500,
    fps: 30,
    audioBitrate: 128,
  );

  static const high = StreamQuality(
    name: 'high',
    width: 1920,
    height: 1080,
    bitrate: 5000,
    fps: 60,
    audioBitrate: 192,
  );

  static const ultra = StreamQuality(
    name: 'ultra',
    width: 1920,
    height: 1080,
    bitrate: 8000,
    fps: 60,
    audioBitrate: 256,
  );

  static const List<StreamQuality> all = [low, medium, high, ultra];

  @override
  String toString() => '$name (${width}x$height @ ${fps}fps, ${bitrate}kbps)';
}

class AdaptiveBitrateService {
  static final AdaptiveBitrateService _instance = AdaptiveBitrateService._internal();
  factory AdaptiveBitrateService() => _instance;
  AdaptiveBitrateService._internal();

  // Current quality
  StreamQuality _currentQuality = StreamQuality.high;

  // Network monitoring
  final Connectivity _connectivity = Connectivity();
  Timer? _networkMonitor;
  double _estimatedBandwidth = 5000; // kbps
  ConnectivityResult _connectionType = ConnectivityResult.none;

  // Stream controllers
  final _qualityController = StreamController<StreamQuality>.broadcast();
  final _bandwidthController = StreamController<double>.broadcast();

  // Public streams
  Stream<StreamQuality> get qualityStream => _qualityController.stream;
  Stream<double> get bandwidthStream => _bandwidthController.stream;

  // Getters
  StreamQuality get currentQuality => _currentQuality;
  double get estimatedBandwidth => _estimatedBandwidth;
  ConnectivityResult get connectionType => _connectionType;

  /// Start adaptive bitrate monitoring
  Future<void> startMonitoring() async {
    print('[ABR] 🚀 Starting adaptive bitrate monitoring');

    // Get initial connection type
    final connectivityResults = await _connectivity.checkConnectivity();
    _connectionType = connectivityResults.isNotEmpty ? connectivityResults.first : ConnectivityResult.none;
    print('[ABR] Initial connection: $_connectionType');

    // Start periodic network quality checks
    _networkMonitor = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkNetworkQuality(),
    );

    // Initial quality determination
    await _checkNetworkQuality();
  }

  /// Stop monitoring
  void stopMonitoring() {
    print('[ABR] 🛑 Stopping adaptive bitrate monitoring');
    _networkMonitor?.cancel();
    _networkMonitor = null;
  }

  /// Check network quality and adjust stream quality
  Future<void> _checkNetworkQuality() async {
    try {
      // Update connection type
      final connectivityResults = await _connectivity.checkConnectivity();
      _connectionType = connectivityResults.isNotEmpty ? connectivityResults.first : ConnectivityResult.none;

      // Estimate bandwidth
      _estimatedBandwidth = await _estimateBandwidth();
      _bandwidthController.add(_estimatedBandwidth);

      print('[ABR] 📊 Bandwidth estimate: ${_estimatedBandwidth.toStringAsFixed(0)} kbps');

      // Determine optimal quality
      final optimalQuality = _determineOptimalQuality();

      // Switch quality if needed
      if (optimalQuality != _currentQuality) {
        _currentQuality = optimalQuality;
        _qualityController.add(_currentQuality);

        print('[ABR] 🔄 Quality changed to: $_currentQuality');
      }
    } catch (e) {
      print('[ABR] ❌ Error checking network quality: $e');
    }
  }

  /// Determine optimal quality based on network conditions
  StreamQuality _determineOptimalQuality() {
    // Safety margin (use 70% of estimated bandwidth)
    final safeBandwidth = _estimatedBandwidth * 0.7;

    // Connection type multipliers
    double multiplier = 1.0;
    if (_connectionType == ConnectivityResult.mobile) {
      multiplier = 0.8; // Be more conservative on cellular
    } else if (_connectionType == ConnectivityResult.wifi) {
      multiplier = 1.0; // Full bandwidth on WiFi
    } else {
      multiplier = 0.5; // Very conservative on unknown
    }

    final adjustedBandwidth = safeBandwidth * multiplier;

    // Select quality level
    if (adjustedBandwidth >= 9000) {
      return StreamQuality.ultra; // 8000kbps + margin
    } else if (adjustedBandwidth >= 6000) {
      return StreamQuality.high; // 5000kbps + margin
    } else if (adjustedBandwidth >= 3000) {
      return StreamQuality.medium; // 2500kbps + margin
    } else {
      return StreamQuality.low; // 800kbps + margin
    }
  }

  /// Estimate bandwidth using multiple methods
  Future<double> _estimateBandwidth() async {
    // Method 1: Connection type heuristics (primary - fast, no network usage)
    double estimate = _estimateByConnectionType();

    // Method 2: Try speed test with your backend (optional)
    // Uncomment to use actual speed test with your backend
    // final speedTest = await _performSpeedTest();
    // if (speedTest > 0) {
    //   estimate = speedTest;
    // }

    return estimate;
  }

  /// Estimate bandwidth based on connection type (fast, no network usage)
  double _estimateByConnectionType() {
    switch (_connectionType) {
      case ConnectivityResult.wifi:
        // WiFi - assume good bandwidth
        // Most WiFi: 10-100 Mbps
        return 10000; // 10 Mbps (conservative)

      case ConnectivityResult.mobile:
        // Mobile data - try to detect generation
        // 3G: 0.5-2 Mbps
        // 4G: 5-50 Mbps
        // 5G: 50-1000+ Mbps
        // Conservative estimate for 4G
        return 5000; // 5 Mbps

      case ConnectivityResult.ethernet:
        // Wired connection - excellent
        return 50000; // 50 Mbps

      case ConnectivityResult.bluetooth:
        // Bluetooth tethering - poor
        return 1000; // 1 Mbps

      case ConnectivityResult.vpn:
        // VPN - variable, be conservative
        return 3000; // 3 Mbps

      default:
        // Unknown - very conservative
        return 2000; // 2 Mbps
    }
  }

  /// Perform actual speed test (OPTION 1: Using your backend)
  /// Call this if you want real bandwidth measurement
  // ignore: unused_element
  Future<double> _performSpeedTestWithBackend(String backendUrl) async {
    try {
      print('[ABR] 🔬 Running speed test...');

      final stopwatch = Stopwatch()..start();

      // Download a small file from your backend
      // You can create a static file like: /public/speedtest-100kb.bin
      final response = await http.get(
        Uri.parse('$backendUrl/speedtest-100kb.bin'),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 5));

      stopwatch.stop();

      if (response.statusCode != 200) {
        print('[ABR] ❌ Speed test failed: ${response.statusCode}');
        return 0; // Fallback to heuristic
      }

      final bytes = response.bodyBytes.length;
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final kbps = (bytes * 8) / seconds / 1000;

      print('[ABR] ✅ Speed test: ${kbps.toStringAsFixed(0)} kbps (${bytes} bytes in ${seconds.toStringAsFixed(2)}s)');

      return kbps;
    } catch (e) {
      print('[ABR] ❌ Speed test error: $e');
      return 0; // Return 0 to use heuristic fallback
    }
  }

  /// Perform actual speed test (OPTION 2: Using public CDN)
  /// Uses a public, reliable CDN for speed testing
  // ignore: unused_element
  Future<double> _performSpeedTestWithCDN() async {
    try {
      print('[ABR] 🔬 Running CDN speed test...');

      final stopwatch = Stopwatch()..start();

      // Use a public, fast CDN with small test file
      // jsdelivr CDN is free and reliable
      final response = await http.get(
        Uri.parse('https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js'),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 5));

      stopwatch.stop();

      if (response.statusCode != 200) {
        print('[ABR] ❌ CDN speed test failed: ${response.statusCode}');
        return 0;
      }

      final bytes = response.bodyBytes.length;
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final kbps = (bytes * 8) / seconds / 1000;

      print('[ABR] ✅ CDN speed test: ${kbps.toStringAsFixed(0)} kbps');

      return kbps;
    } catch (e) {
      print('[ABR] ❌ CDN speed test error: $e');
      return 0;
    }
  }

  /// Perform actual speed test (OPTION 3: Progressive monitoring)
  /// Monitors actual streaming performance over time
  void updateBandwidthFromStreamStats({
    required int currentBitrate,
    required int droppedFrames,
    required double fps,
  }) {
    // If stream is performing well, we have good bandwidth
    if (droppedFrames == 0 && fps >= 30) {
      // Stream is smooth, we can handle current bitrate
      _estimatedBandwidth = currentBitrate * 1.2; // 20% headroom
    } else if (droppedFrames > 10) {
      // Stream is struggling, reduce bandwidth estimate
      _estimatedBandwidth = currentBitrate * 0.8; // Reduce by 20%
    }

    _bandwidthController.add(_estimatedBandwidth);

    print('[ABR] 📊 Updated bandwidth from stream stats: ${_estimatedBandwidth.toStringAsFixed(0)} kbps');

    // Re-check quality with updated bandwidth
    final optimalQuality = _determineOptimalQuality();
    if (optimalQuality != _currentQuality) {
      _currentQuality = optimalQuality;
      _qualityController.add(_currentQuality);
      print('[ABR] 🔄 Quality adjusted based on stream performance: $_currentQuality');
    }
  }

  /// Get FFmpeg command for current quality (iOS)
  String getFFmpegCommandIOS(String rtmpUrl) {
    final q = _currentQuality;

    return '-f avfoundation '
        // Input settings
        '-framerate ${q.fps} '
        '-video_size ${q.width}x${q.height} '
        '-i "0:0" '
        // Hardware encoding (iOS VideoToolbox)
        '-c:v h264_videotoolbox '
        // Ultra-low latency settings
        '-profile:v baseline '
        '-preset ultrafast '
        '-tune zerolatency '
        // Bitrate settings
        '-b:v ${q.bitrate}k '
        '-maxrate ${(q.bitrate * 1.2).toInt()}k '
        '-bufsize ${(q.bitrate * 0.5).toInt()}k '
        // GOP settings (1 second keyframe interval)
        '-g ${q.fps} '
        '-keyint_min ${q.fps} '
        // Audio settings
        '-c:a aac '
        '-b:a ${q.audioBitrate}k '
        '-ar 48000 '
        '-ac 2 '
        // RTMP reconnection settings (NEW!)
        '-reconnect 1 '                      // Enable reconnection
        '-reconnect_at_eof 1 '               // Reconnect at end of file
        '-reconnect_streamed 1 '             // Reconnect on stream errors
        '-reconnect_delay_max 10 '           // Max 10 seconds between retries
        // Output format
        '-f flv '
        '-flvflags no_duration_filesize '
        '$rtmpUrl';
  }

  /// Get FFmpeg command for current quality (Android)
  String getFFmpegCommandAndroid(String rtmpUrl) {
    final q = _currentQuality;

    return '-f android_camera '
        // Input settings
        '-framerate ${q.fps} '
        '-video_size ${q.width}x${q.height} '
        '-i 0 '
        // Hardware encoding (Android MediaCodec)
        '-c:v h264_mediacodec '
        // Ultra-low latency settings
        '-profile:v baseline '
        '-tune zerolatency '
        // Bitrate settings
        '-b:v ${q.bitrate}k '
        '-maxrate ${(q.bitrate * 1.2).toInt()}k '
        '-bufsize ${(q.bitrate * 0.5).toInt()}k '
        // GOP settings
        '-g ${q.fps} '
        '-keyint_min ${q.fps} '
        // Audio settings
        '-c:a aac '
        '-b:a ${q.audioBitrate}k '
        '-ar 48000 '
        '-ac 2 '
        // RTMP reconnection settings (NEW!)
        '-reconnect 1 '                      // Enable reconnection
        '-reconnect_at_eof 1 '               // Reconnect at end of file
        '-reconnect_streamed 1 '             // Reconnect on stream errors
        '-reconnect_delay_max 10 '           // Max 10 seconds between retries
        // Output format
        '-f flv '
        '-flvflags no_duration_filesize '
        '$rtmpUrl';
  }

  /// Manually set quality (user override)
  void setQuality(StreamQuality quality) {
    if (quality != _currentQuality) {
      _currentQuality = quality;
      _qualityController.add(_currentQuality);

      print('[ABR] 👤 User set quality to: $_currentQuality');
    }
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _qualityController.close();
    _bandwidthController.close();
  }
}
