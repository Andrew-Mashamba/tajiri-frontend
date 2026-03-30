// Models for the Shangazi Tea feature — AI gossip partner.
// Spec: docs/superpowers/specs/2026-03-30-shangazi-tea-design.md §6, §7

class TeaConversation {
  final String id;
  final String? title;
  final String? lastMessagePreview;
  final int messageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeaConversation({
    required this.id,
    this.title,
    this.lastMessagePreview,
    this.messageCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeaConversation.fromJson(Map<String, dynamic> json) {
    return TeaConversation(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString(),
      lastMessagePreview: json['last_message_preview']?.toString(),
      messageCount: _parseInt(json['message_count']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class TeaMessage {
  final String id;
  final String role; // 'user' | 'shangazi'
  final String type; // 'text' | 'tea_card' | 'action_card' | 'action_result' | 'web_search_result'
  final Map<String, dynamic> content;
  final DateTime createdAt;

  TeaMessage({
    required this.id,
    required this.role,
    required this.type,
    required this.content,
    required this.createdAt,
  });

  factory TeaMessage.fromJson(Map<String, dynamic> json) {
    return TeaMessage(
      id: json['id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'shangazi',
      type: json['type']?.toString() ?? 'text',
      content: json['content'] is Map<String, dynamic>
          ? json['content'] as Map<String, dynamic>
          : {'text': json['content']?.toString() ?? ''},
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String get textContent => content['text']?.toString() ?? content.toString();
  bool get isFromShangazi => role == 'shangazi';
  bool get isTeaCard => type == 'tea_card';
  bool get isActionCard => type == 'action_card';
  bool get isActionResult => type == 'action_result';
  bool get isWebSearchResult => type == 'web_search_result';
}

class TeaCard {
  final String id;
  final String headline;
  final String summary;
  final String urgency; // fire | hot | warm | cold
  final String? category;
  final List<int> sourcePosts;
  final List<String> actions;
  final String? topReaction;

  TeaCard({
    required this.id,
    required this.headline,
    required this.summary,
    this.urgency = 'warm',
    this.category,
    this.sourcePosts = const [],
    this.actions = const [],
    this.topReaction,
  });

  factory TeaCard.fromJson(Map<String, dynamic> json) {
    return TeaCard(
      id: json['id']?.toString() ?? '',
      headline: json['headline']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      urgency: json['urgency']?.toString() ?? 'warm',
      category: json['category']?.toString(),
      sourcePosts: (json['source_posts'] as List<dynamic>?)
              ?.map((e) => _parseInt(e))
              .toList() ??
          [],
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      topReaction: json['top_reaction']?.toString(),
    );
  }

  bool get isFire => urgency == 'fire';
  bool get isHot => urgency == 'hot';
}

class ActionCard {
  final String actionCardId;
  final String action;
  final Map<String, dynamic> preview;
  final String confirmPrompt;
  final String status;

  ActionCard({
    required this.actionCardId,
    required this.action,
    required this.preview,
    required this.confirmPrompt,
    this.status = 'pending',
  });

  factory ActionCard.fromJson(Map<String, dynamic> json) {
    return ActionCard(
      actionCardId: json['action_card_id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      preview: json['preview'] is Map<String, dynamic>
          ? json['preview'] as Map<String, dynamic>
          : {},
      confirmPrompt: json['confirm_prompt']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
    );
  }

  bool get isPending => status == 'pending';
}

class TeaStreamEvent {
  final String eventType;
  final Map<String, dynamic> data;

  TeaStreamEvent({required this.eventType, required this.data});

  bool get isDone => eventType == 'done';
  bool get isText => eventType == 'text';
  bool get isTeaCard => eventType == 'tea_card';
  bool get isActionCard => eventType == 'action_card';

  String get textChunk => data['content']?.toString() ?? '';
  bool get textDone => data['done'] == true;
  String get conversationId => data['conversation_id']?.toString() ?? '';
}

class TeaChatResponse {
  final String conversationId;
  final String streamUrl;

  TeaChatResponse({required this.conversationId, required this.streamUrl});

  factory TeaChatResponse.fromJson(Map<String, dynamic> json) {
    return TeaChatResponse(
      conversationId: json['conversation_id']?.toString() ?? '',
      streamUrl: json['stream_url']?.toString() ?? '',
    );
  }
}

int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}
