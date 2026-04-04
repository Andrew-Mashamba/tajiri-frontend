import UserNotifications
import UIKit

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        // Set thread identifier for iOS notification grouping
        if let conversationId = bestAttemptContent.userInfo["conversation_id"] as? String {
            bestAttemptContent.threadIdentifier = "tajiri_conversation_\(conversationId)"
        } else if let type = bestAttemptContent.userInfo["type"] as? String {
            bestAttemptContent.threadIdentifier = "tajiri_\(type)"
        }

        // Set category for notification actions (quick reply, mark read)
        let notificationType = bestAttemptContent.userInfo["type"] as? String ?? ""
        if notificationType == "new_message" || notificationType == "group_message" {
            bestAttemptContent.categoryIdentifier = "MESSAGE"
        } else if notificationType == "call_incoming" {
            bestAttemptContent.categoryIdentifier = "CALL"
        }

        // Check for media attachment URL
        guard let mediaUrlString = bestAttemptContent.userInfo["media_url"] as? String,
              let mediaUrl = URL(string: mediaUrlString) else {
            // No media — deliver notification as-is
            contentHandler(bestAttemptContent)
            return
        }

        // Determine file extension from URL or media type
        let mediaType = bestAttemptContent.userInfo["media_type"] as? String ?? ""
        let fileExtension = Self.fileExtension(for: mediaUrlString, mediaType: mediaType)

        // Download media attachment
        downloadMedia(from: mediaUrl, fileExtension: fileExtension) { localUrl in
            if let localUrl = localUrl,
               let attachment = try? UNNotificationAttachment(
                   identifier: "media",
                   url: localUrl,
                   options: [UNNotificationAttachmentOptionsThumbnailClippingRectKey: CGRect(x: 0, y: 0, width: 1, height: 1).dictionaryRepresentation]
               ) {
                bestAttemptContent.attachments = [attachment]
            }
            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Deliver the best attempt content before timeout (30 seconds).
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    // MARK: - Media Download

    private func downloadMedia(from url: URL, fileExtension: String, completion: @escaping (URL?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { tempUrl, response, error in
            guard let tempUrl = tempUrl, error == nil else {
                completion(nil)
                return
            }

            // Validate response (2xx status)
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                completion(nil)
                return
            }

            // Check file size — skip attachments larger than 10MB
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: tempUrl.path)[.size] as? Int) ?? 0
            if fileSize > 10 * 1024 * 1024 {
                completion(nil)
                return
            }

            // Move to a file with proper extension (required by UNNotificationAttachment)
            let destUrl = tempUrl.deletingPathExtension().appendingPathExtension(fileExtension)
            try? FileManager.default.moveItem(at: tempUrl, to: destUrl)
            completion(destUrl)
        }
        task.resume()
    }

    // MARK: - File Extension Helpers

    private static func fileExtension(for urlString: String, mediaType: String) -> String {
        // Try to determine from media_type field
        switch mediaType.lowercased() {
        case "image", "photo":
            return "jpg"
        case "gif":
            return "gif"
        case "video":
            return "mp4"
        case "audio", "voice":
            return "m4a"
        case "sticker":
            return "png"
        default:
            break
        }

        // Try to determine from URL extension
        let url = URL(string: urlString)
        let pathExtension = url?.pathExtension.lowercased() ?? ""
        switch pathExtension {
        case "jpg", "jpeg", "png", "gif", "webp", "heic":
            return pathExtension == "jpeg" ? "jpg" : pathExtension
        case "mp4", "mov", "m4v":
            return pathExtension
        case "mp3", "m4a", "aac", "wav", "ogg":
            return pathExtension
        default:
            return "jpg" // Default to image
        }
    }
}
