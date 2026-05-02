// User privacy settings — superset that mirrors the backend
// `user_profiles` privacy columns + the new Faragha extras.

class PrivacySettings {
  // ── Profile per-field visibility ──────────────────────────────────────────
  final String profileVisibility;
  final String profilePhotoVisibility;
  final String aboutVisibility;
  final String statusVisibility;
  final String dobVisibility;
  final String genderVisibility;
  final String phoneVisibility;
  final String emailVisibility;
  final String relationshipVisibility;
  final String locationVisibility;
  final String educationVisibility;
  final String employerVisibility;

  // ── Presence / activity ──────────────────────────────────────────────────
  final String lastSeenVisibility;
  final String onlineStatusVisibility;
  final String readReceiptsVisibility;

  // ── Interaction surface ──────────────────────────────────────────────────
  final String whoCanMessage;
  final String whoCanSeePosts;
  final String whoCanAddToGroups;
  final String whoCanResendStatus;
  final String whoCanCall;

  // ── Discoverability ──────────────────────────────────────────────────────
  final bool searchableByPhone;
  final bool searchableByEmail;
  final bool discoverable;

  // ── Account opt-outs ─────────────────────────────────────────────────────
  final bool optOutSponsored;
  final bool optOutCollaboration;
  final bool optOutBattles;
  final bool optOutThreads;

  // ── Sensitive consent ────────────────────────────────────────────────────
  final bool faceEmbeddingConsent;

  // ── Marketing & alerts ───────────────────────────────────────────────────
  final bool marketingEmailEnabled;
  final bool loginAlertsEnabled;

  const PrivacySettings({
    this.profileVisibility = 'everyone',
    this.profilePhotoVisibility = 'everyone',
    this.aboutVisibility = 'everyone',
    this.statusVisibility = 'everyone',
    this.dobVisibility = 'friends',
    this.genderVisibility = 'everyone',
    this.phoneVisibility = 'friends',
    this.emailVisibility = 'only_me',
    this.relationshipVisibility = 'friends',
    this.locationVisibility = 'everyone',
    this.educationVisibility = 'everyone',
    this.employerVisibility = 'everyone',
    this.lastSeenVisibility = 'everyone',
    this.onlineStatusVisibility = 'everyone',
    this.readReceiptsVisibility = 'everyone',
    this.whoCanMessage = 'everyone',
    this.whoCanSeePosts = 'everyone',
    this.whoCanAddToGroups = 'everyone',
    this.whoCanResendStatus = 'everyone',
    this.whoCanCall = 'everyone',
    this.searchableByPhone = true,
    this.searchableByEmail = false,
    this.discoverable = true,
    this.optOutSponsored = false,
    this.optOutCollaboration = false,
    this.optOutBattles = false,
    this.optOutThreads = false,
    this.faceEmbeddingConsent = false,
    this.marketingEmailEnabled = false,
    this.loginAlertsEnabled = false,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    String s(String k, [String def = 'everyone']) =>
        json[k] is String ? json[k] as String : def;
    bool b(String k, [bool def = false]) {
      final v = json[k];
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return def;
    }

    return PrivacySettings(
      profileVisibility: s('profile_visibility'),
      profilePhotoVisibility: s('profile_photo_visibility'),
      aboutVisibility: s('about_visibility'),
      statusVisibility: s('status_visibility'),
      dobVisibility: s('dob_visibility', 'friends'),
      genderVisibility: s('gender_visibility'),
      phoneVisibility: s('phone_visibility', 'friends'),
      emailVisibility: s('email_visibility', 'only_me'),
      relationshipVisibility: s('relationship_visibility', 'friends'),
      locationVisibility: s('location_visibility'),
      educationVisibility: s('education_visibility'),
      employerVisibility: s('employer_visibility'),
      lastSeenVisibility: s('last_seen_visibility'),
      onlineStatusVisibility: s('online_status_visibility'),
      readReceiptsVisibility: s('read_receipts_visibility'),
      whoCanMessage: s('who_can_message'),
      whoCanSeePosts: s('who_can_see_posts'),
      whoCanAddToGroups: s('who_can_add_to_groups'),
      whoCanResendStatus: s('who_can_resend_status'),
      whoCanCall: s('who_can_call'),
      searchableByPhone: b('searchable_by_phone', true),
      searchableByEmail: b('searchable_by_email'),
      discoverable: b('discoverable', true),
      optOutSponsored: b('opt_out_sponsored'),
      optOutCollaboration: b('opt_out_collaboration'),
      optOutBattles: b('opt_out_battles'),
      optOutThreads: b('opt_out_threads'),
      faceEmbeddingConsent: b('face_embedding_consent'),
      marketingEmailEnabled: b('marketing_email_enabled'),
      loginAlertsEnabled: b('login_alerts_enabled'),
    );
  }

  Map<String, dynamic> toJson() => {
        'profile_visibility': profileVisibility,
        'profile_photo_visibility': profilePhotoVisibility,
        'about_visibility': aboutVisibility,
        'status_visibility': statusVisibility,
        'dob_visibility': dobVisibility,
        'gender_visibility': genderVisibility,
        'phone_visibility': phoneVisibility,
        'email_visibility': emailVisibility,
        'relationship_visibility': relationshipVisibility,
        'location_visibility': locationVisibility,
        'education_visibility': educationVisibility,
        'employer_visibility': employerVisibility,
        'last_seen_visibility': lastSeenVisibility,
        'online_status_visibility': onlineStatusVisibility,
        'read_receipts_visibility': readReceiptsVisibility,
        'who_can_message': whoCanMessage,
        'who_can_see_posts': whoCanSeePosts,
        'who_can_add_to_groups': whoCanAddToGroups,
        'who_can_resend_status': whoCanResendStatus,
        'who_can_call': whoCanCall,
        'searchable_by_phone': searchableByPhone,
        'searchable_by_email': searchableByEmail,
        'discoverable': discoverable,
        'opt_out_sponsored': optOutSponsored,
        'opt_out_collaboration': optOutCollaboration,
        'opt_out_battles': optOutBattles,
        'opt_out_threads': optOutThreads,
        'face_embedding_consent': faceEmbeddingConsent,
        'marketing_email_enabled': marketingEmailEnabled,
        'login_alerts_enabled': loginAlertsEnabled,
      };

  PrivacySettings copyWith(Map<String, dynamic> patch) {
    final merged = {...toJson(), ...patch};
    return PrivacySettings.fromJson(merged);
  }
}

/// Localized label for any visibility-token field.
String privacyVisibilityLabel(String value, {required bool isSwahili}) {
  switch (value) {
    case 'everyone':
      return isSwahili ? 'Kila mtu' : 'Everyone';
    case 'friends':
      return isSwahili ? 'Marafiki tu' : 'Friends only';
    case 'only_me':
      return isSwahili ? 'Mimi tu' : 'Only me';
    case 'nobody':
      return isSwahili ? 'Hakuna mtu' : 'Nobody';
    default:
      return isSwahili ? 'Kila mtu' : 'Everyone';
  }
}
