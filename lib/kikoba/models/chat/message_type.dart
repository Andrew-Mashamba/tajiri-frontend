/// Enum representing different types of chat messages
enum MessageType {
  text,
  image,
  file,
  system;

  /// Parse message type from string
  static MessageType fromString(String? value) {
    switch (value) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  /// Convert to string value for API/storage
  String get value {
    switch (this) {
      case MessageType.image:
        return 'image';
      case MessageType.file:
        return 'file';
      case MessageType.system:
        return 'system';
      default:
        return 'text';
    }
  }

  /// Check if this message type supports attachments
  bool get hasAttachment {
    return this == MessageType.image || this == MessageType.file;
  }

  /// Get display name in Swahili
  String get displayName {
    switch (this) {
      case MessageType.image:
        return 'Picha';
      case MessageType.file:
        return 'Faili';
      case MessageType.system:
        return 'Mfumo';
      default:
        return 'Ujumbe';
    }
  }
}
