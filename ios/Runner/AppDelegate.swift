import Flutter
import UIKit
import AVFoundation
import HaishinKit

// RTMP Streaming Service
class RTMPStreamingService: NSObject {
    private var rtmpConnection: RTMPConnection?
    private var rtmpStream: RTMPStream?
    private(set) var isStreaming = false

    func startStreaming(
        rtmpUrl: String,
        width: Int,
        height: Int,
        fps: Int,
        bitrate: Int,
        completion: @escaping (Bool, String?) -> Void
    ) {
        print("[RTMPStreaming] 🍎 Starting native iOS stream with HaishinKit")
        print("[RTMPStreaming] 📡 RTMP URL: \(rtmpUrl)")
        print("[RTMPStreaming] 📐 Resolution: \(width)x\(height) @ \(fps)fps")
        print("[RTMPStreaming] 📊 Bitrate: \(bitrate/1000)kbps")
        isStreaming = true
        print("[RTMPStreaming] ⚠️ HaishinKit integration in progress")
        completion(true, nil)
    }

    func stopStreaming() {
        print("[RTMPStreaming] 🛑 Stopping stream")
        isStreaming = false
        print("[RTMPStreaming] ✅ Stream stopped")
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var streamingService: RTMPStreamingService?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController

    // Setup streaming method channel
    let streamingChannel = FlutterMethodChannel(
      name: "tz.co.zima.tajiri/streaming",
      binaryMessenger: controller.binaryMessenger
    )

    streamingChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "startStreaming":
        self?.startStreaming(call: call, result: result)
      case "stopStreaming":
        self?.stopStreaming(result: result)
      case "getStreamingStatus":
        self?.getStreamingStatus(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func startStreaming(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let rtmpUrl = args["rtmpUrl"] as? String,
          let width = args["width"] as? Int,
          let height = args["height"] as? Int,
          let fps = args["fps"] as? Int,
          let bitrate = args["bitrate"] as? Int else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }

    if streamingService == nil {
      streamingService = RTMPStreamingService()
    }

    streamingService?.startStreaming(
      rtmpUrl: rtmpUrl,
      width: width,
      height: height,
      fps: fps,
      bitrate: bitrate
    ) { success, error in
      if success {
        result(true)
      } else {
        result(FlutterError(code: "STREAMING_ERROR", message: error ?? "Unknown error", details: nil))
      }
    }
  }

  private func stopStreaming(result: @escaping FlutterResult) {
    streamingService?.stopStreaming()
    result(true)
  }

  private func getStreamingStatus(result: @escaping FlutterResult) {
    let isStreaming = streamingService?.isStreaming ?? false
    result(isStreaming)
  }
}
