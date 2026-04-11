// lib/business/pages/email/email_mock_service.dart
// Mock email service — provides realistic in-memory data for the email client.
// Will be swapped for real IMAP/SMTP when Mailcow is ready.

import 'dart:math';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class MockAttachment {
  final String name;
  final String size;
  final String type; // pdf, docx, jpg, xlsx, etc.

  const MockAttachment({
    required this.name,
    required this.size,
    required this.type,
  });
}

class MockEmail {
  final String id;
  final String from;
  final String fromName;
  final List<String> to;
  final List<String>? cc;
  final String subject;
  final String body;
  final String preview;
  final DateTime date;
  bool isRead;
  bool isFlagged;
  final bool hasAttachments;
  final List<MockAttachment>? attachments;
  String folder; // inbox, sent, drafts, trash, spam

  MockEmail({
    required this.id,
    required this.from,
    required this.fromName,
    required this.to,
    this.cc,
    required this.subject,
    required this.body,
    required this.preview,
    required this.date,
    this.isRead = false,
    this.isFlagged = false,
    this.hasAttachments = false,
    this.attachments,
    this.folder = 'inbox',
  });

  MockEmail copyWith({
    String? id,
    String? from,
    String? fromName,
    List<String>? to,
    List<String>? cc,
    String? subject,
    String? body,
    String? preview,
    DateTime? date,
    bool? isRead,
    bool? isFlagged,
    bool? hasAttachments,
    List<MockAttachment>? attachments,
    String? folder,
  }) {
    return MockEmail(
      id: id ?? this.id,
      from: from ?? this.from,
      fromName: fromName ?? this.fromName,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      preview: preview ?? this.preview,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      isFlagged: isFlagged ?? this.isFlagged,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      attachments: attachments ?? this.attachments,
      folder: folder ?? this.folder,
    );
  }
}

// ---------------------------------------------------------------------------
// Mock Data Store (singleton, in-memory)
// ---------------------------------------------------------------------------

class EmailMockService {
  static final Map<String, List<MockEmail>> _store = {};
  static bool _seeded = false;

  /// Ensure mock data is seeded for the given account.
  static void _ensureSeeded(String emailAddress) {
    if (!_seeded) {
      _seeded = true;
    }
    if (!_store.containsKey(emailAddress)) {
      _store[emailAddress] = _generateEmails(emailAddress);
    }
  }

  // ---- Public API ----------------------------------------------------------

  static List<MockEmail> getInbox(String emailAddress) {
    _ensureSeeded(emailAddress);
    return _store[emailAddress]!
        .where((e) => e.folder == 'inbox')
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<MockEmail> getSent(String emailAddress) {
    _ensureSeeded(emailAddress);
    return _store[emailAddress]!
        .where((e) => e.folder == 'sent')
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<MockEmail> getDrafts(String emailAddress) {
    _ensureSeeded(emailAddress);
    return _store[emailAddress]!
        .where((e) => e.folder == 'drafts')
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<MockEmail> getTrash(String emailAddress) {
    _ensureSeeded(emailAddress);
    return _store[emailAddress]!
        .where((e) => e.folder == 'trash')
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<MockEmail> getSpam(String emailAddress) {
    _ensureSeeded(emailAddress);
    return _store[emailAddress]!
        .where((e) => e.folder == 'spam')
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<MockEmail> getFolder(String emailAddress, String folder) {
    switch (folder) {
      case 'inbox':
        return getInbox(emailAddress);
      case 'sent':
        return getSent(emailAddress);
      case 'drafts':
        return getDrafts(emailAddress);
      case 'trash':
        return getTrash(emailAddress);
      case 'spam':
        return getSpam(emailAddress);
      default:
        return getInbox(emailAddress);
    }
  }

  static int getUnreadCount(String emailAddress, String folder) {
    _ensureSeeded(emailAddress);
    return _store[emailAddress]!
        .where((e) => e.folder == folder && !e.isRead)
        .length;
  }

  static Map<String, int> getAllUnreadCounts(String emailAddress) {
    _ensureSeeded(emailAddress);
    return {
      'inbox': getUnreadCount(emailAddress, 'inbox'),
      'sent': 0,
      'drafts': getUnreadCount(emailAddress, 'drafts'),
      'trash': 0,
      'spam': getUnreadCount(emailAddress, 'spam'),
    };
  }

  static MockEmail sendEmail({
    required String from,
    required String fromName,
    required List<String> to,
    List<String>? cc,
    required String subject,
    required String body,
  }) {
    final email = MockEmail(
      id: 'email_${DateTime.now().millisecondsSinceEpoch}',
      from: from,
      fromName: fromName,
      to: to,
      cc: cc,
      subject: subject,
      body: body,
      preview: body.length > 100 ? body.substring(0, 100) : body,
      date: DateTime.now(),
      isRead: true,
      folder: 'sent',
    );
    _ensureSeeded(from);
    _store[from]!.add(email);
    return email;
  }

  static void markAsRead(String emailAddress, String emailId) {
    _ensureSeeded(emailAddress);
    final idx = _store[emailAddress]!.indexWhere((e) => e.id == emailId);
    if (idx != -1) _store[emailAddress]![idx].isRead = true;
  }

  static void markAsUnread(String emailAddress, String emailId) {
    _ensureSeeded(emailAddress);
    final idx = _store[emailAddress]!.indexWhere((e) => e.id == emailId);
    if (idx != -1) _store[emailAddress]![idx].isRead = false;
  }

  static void moveToTrash(String emailAddress, String emailId) {
    _ensureSeeded(emailAddress);
    final idx = _store[emailAddress]!.indexWhere((e) => e.id == emailId);
    if (idx != -1) _store[emailAddress]![idx].folder = 'trash';
  }

  static void archive(String emailAddress, String emailId) {
    // For now archive = move out of inbox (remove from view)
    moveToTrash(emailAddress, emailId);
  }

  static void flagEmail(String emailAddress, String emailId) {
    _ensureSeeded(emailAddress);
    final idx = _store[emailAddress]!.indexWhere((e) => e.id == emailId);
    if (idx != -1) {
      _store[emailAddress]![idx].isFlagged =
          !_store[emailAddress]![idx].isFlagged;
    }
  }

  static void moveToFolder(
      String emailAddress, String emailId, String folder) {
    _ensureSeeded(emailAddress);
    final idx = _store[emailAddress]!.indexWhere((e) => e.id == emailId);
    if (idx != -1) _store[emailAddress]![idx].folder = folder;
  }

  static MockEmail? getEmail(String emailAddress, String emailId) {
    _ensureSeeded(emailAddress);
    final idx = _store[emailAddress]!.indexWhere((e) => e.id == emailId);
    return idx != -1 ? _store[emailAddress]![idx] : null;
  }

  /// Preview for the account picker — last email in inbox.
  static MockEmail? getLastInboxEmail(String emailAddress) {
    final inbox = getInbox(emailAddress);
    return inbox.isNotEmpty ? inbox.first : null;
  }

  static int getTotalUnread(String emailAddress) {
    return getUnreadCount(emailAddress, 'inbox');
  }

  // ---- Data Generation -----------------------------------------------------

  static List<MockEmail> _generateEmails(String accountEmail) {
    final now = DateTime.now();
    final rng = Random(accountEmail.hashCode);

    final emails = <MockEmail>[];

    // -- Inbox emails (15-18) -------------------------------------------------
    final inboxData = <Map<String, dynamic>>[
      {
        'from': 'john.mwanga@crdbbank.co.tz',
        'fromName': 'John Mwanga',
        'subject': 'Invoice #INV-2026-0042 — Payment Confirmation',
        'body':
            'Dear Sir/Madam,\n\nThis is to confirm that payment for Invoice #INV-2026-0042 amounting to TZS 4,500,000 has been received and processed successfully.\n\nThe funds have been credited to your account ending in ***4521. Please allow 24 hours for the transaction to reflect in your statement.\n\nShould you have any questions, please do not hesitate to contact us.\n\nBest regards,\nJohn Mwanga\nRelationship Manager\nCRDB Bank PLC',
        'hasAttachments': true,
        'attachments': [
          const MockAttachment(
              name: 'INV-2026-0042.pdf', size: '245 KB', type: 'pdf'),
          const MockAttachment(
              name: 'payment_receipt.pdf', size: '128 KB', type: 'pdf'),
        ],
        'isRead': false,
        'hoursAgo': 1,
      },
      {
        'from': 'sarah.kimaro@gmail.com',
        'fromName': 'Sarah Kimaro',
        'subject': 'Re: Meeting Tomorrow at 10am',
        'body':
            'Hi,\n\nSure, 10am works perfectly for me. I\'ll bring the updated project proposal and the revised budget breakdown.\n\nCan we also discuss the timeline for the Dodoma expansion? I have some concerns about the construction permits.\n\nSee you tomorrow!\n\nBest,\nSarah',
        'isRead': true,
        'hoursAgo': 3,
      },
      {
        'from': 'procurement@vodacom.co.tz',
        'fromName': 'Vodacom M-Pesa',
        'subject': 'M-Pesa Business Account Statement — March 2026',
        'body':
            'Dear Valued Customer,\n\nPlease find attached your M-Pesa Business account statement for the month of March 2026.\n\nSummary:\n- Total Received: TZS 12,450,000\n- Total Sent: TZS 8,230,000\n- Fees: TZS 45,600\n- Closing Balance: TZS 4,174,400\n\nFor any queries, call 100 or visit your nearest Vodacom shop.\n\nVodacom Tanzania PLC',
        'hasAttachments': true,
        'attachments': [
          const MockAttachment(
              name: 'mpesa_statement_mar2026.pdf',
              size: '1.2 MB',
              type: 'pdf'),
        ],
        'isRead': false,
        'hoursAgo': 5,
      },
      {
        'from': 'notifications@tra.go.tz',
        'fromName': 'TRA Notifications',
        'subject': 'Tax Filing Reminder — Q1 2026 VAT Return',
        'body':
            'Mpendwa Mlipa Kodi,\n\nTunakukumbusha kuwa tarehe ya mwisho ya kuwasilisha taarifa ya VAT kwa robo ya kwanza (Q1) ya mwaka 2026 ni tarehe 20 Aprili 2026.\n\nTafadhali hakikisha unawasilisha taarifa yako kupitia mfumo wa TRA Online kabla ya tarehe iliyotajwa ili kuepuka adhabu.\n\nKwa maswali yoyote, wasiliana nasi kupitia 0800 110 016.\n\nMarikiti ya Kodi Tanzania (TRA)',
        'isRead': false,
        'isFlagged': true,
        'hoursAgo': 8,
      },
      {
        'from': 'legal@brela.go.tz',
        'fromName': 'BRELA Registration',
        'subject': 'BRELA Registration Update — Certificate Ready',
        'body':
            'Dear Applicant,\n\nWe are pleased to inform you that your business registration certificate is now ready for collection.\n\nRegistration Number: BRN-2026-045821\nBusiness Name: As per your application\n\nPlease visit our offices at Lumumba Street, Dar es Salaam with a valid ID to collect your certificate.\n\nOffice Hours: Monday-Friday, 8:00 AM - 3:30 PM\n\nBRELA - Business Registrations and Licensing Agency',
        'hasAttachments': true,
        'attachments': [
          const MockAttachment(
              name: 'registration_notice.pdf', size: '89 KB', type: 'pdf'),
        ],
        'isRead': false,
        'hoursAgo': 12,
      },
      {
        'from': 'amina.hassan@outlook.com',
        'fromName': 'Amina Hassan',
        'subject': 'Quotation Request — Office Furniture',
        'body':
            'Habari,\n\nNinaomba bei za samani za ofisi kama ifuatavyo:\n\n- Meza za kazi (desks) x 10\n- Viti vya ofisi (ergonomic) x 10\n- Kabati za faili (filing cabinets) x 5\n- Meza ya mkutano (conference table, seats 12) x 1\n\nTafadhali tuma quotation na muda wa delivery.\n\nAsante,\nAmina Hassan\nProcurement Officer\nDar es Salaam Water & Sewerage Authority',
        'isRead': true,
        'hoursAgo': 18,
      },
      {
        'from': 'peter.mushi@nmb.co.tz',
        'fromName': 'Peter Mushi',
        'subject': 'Contract Review — NMB Business Loan Agreement',
        'body':
            'Dear Client,\n\nPlease find attached the draft loan agreement for your review. The key terms are:\n\n- Loan Amount: TZS 50,000,000\n- Interest Rate: 16% per annum\n- Tenor: 36 months\n- Collateral: As discussed\n\nKindly review and revert with any comments by Friday, April 11th.\n\nRegards,\nPeter Mushi\nCredit Analyst\nNMB Bank PLC',
        'hasAttachments': true,
        'attachments': [
          const MockAttachment(
              name: 'NMB_Loan_Agreement_Draft.pdf',
              size: '3.4 MB',
              type: 'pdf'),
          const MockAttachment(
              name: 'Terms_and_Conditions.pdf',
              size: '1.1 MB',
              type: 'pdf'),
        ],
        'isRead': false,
        'isFlagged': true,
        'hoursAgo': 26,
      },
      {
        'from': 'grace.shirima@gmail.com',
        'fromName': 'Grace Shirima',
        'subject': 'Employee Training Schedule — April 2026',
        'body':
            'Hi Team,\n\nPlease see the training schedule for April below:\n\nWeek 1: Fire Safety & First Aid (Mon-Tue)\nWeek 2: Customer Service Excellence (Wed)\nWeek 3: Digital Skills & CRM Training (Thu-Fri)\nWeek 4: Leadership Workshop (Management only)\n\nAttendance is mandatory. Please confirm your availability.\n\nThanks,\nGrace Shirima\nHR Manager',
        'hasAttachments': true,
        'attachments': [
          const MockAttachment(
              name: 'training_schedule_apr2026.xlsx',
              size: '567 KB',
              type: 'xlsx'),
        ],
        'isRead': true,
        'hoursAgo': 32,
      },
      {
        'from': 'info@dhl.co.tz',
        'fromName': 'DHL Express Tanzania',
        'subject': 'Shipment Tracking — AWB 4829173650',
        'body':
            'Your shipment is on its way!\n\nAWB Number: 4829173650\nOrigin: Shanghai, China\nDestination: Dar es Salaam, Tanzania\nEstimated Delivery: April 8, 2026\n\nCurrent Status: In Transit — Arrived at Nairobi Hub\n\nTrack your shipment at dhl.com or call +255 22 286 1111.\n\nDHL Express',
        'isRead': true,
        'hoursAgo': 48,
      },
      {
        'from': 'joseph.kazimoto@tanesco.co.tz',
        'fromName': 'Joseph Kazimoto',
        'subject': 'Electricity Bill — Account #7821934',
        'body':
            'Mteja Mpendwa,\n\nHii ni taarifa ya bili yako ya umeme kwa mwezi wa Machi 2026:\n\nNambari ya Akaunti: 7821934\nKiasi cha Kutumia: 2,450 kWh\nBili: TZS 735,000\nTarehe ya Mwisho: Aprili 15, 2026\n\nLipa kupitia M-Pesa: *150*00#\nLipa Luku: *152*00#\n\nTANESCO',
        'isRead': false,
        'hoursAgo': 56,
      },
      {
        'from': 'marketing@alibaba.com',
        'fromName': 'Alibaba.com',
        'subject': 'Your supplier inquiry has new responses (3)',
        'body':
            'Dear Buyer,\n\n3 suppliers have responded to your inquiry for "Industrial Packaging Machines".\n\nSupplier 1: Guangzhou HengFa Machinery — USD 4,500 (MOQ: 1)\nSupplier 2: Shanghai PackTech — USD 3,800 (MOQ: 2)\nSupplier 3: Zhejiang Mingwei — USD 5,200 (MOQ: 1, includes installation)\n\nLog in to view full details and start negotiations.\n\nAlibaba.com Team',
        'isRead': true,
        'hoursAgo': 72,
      },
      {
        'from': 'rashid.mbwana@gmail.com',
        'fromName': 'Rashid Mbwana',
        'subject': 'Karibu sana — Partnership Proposal',
        'body':
            'Ndugu Mfanyabiashara,\n\nNinakuandikia kukutambulisha na fursa ya biashara ya pamoja katika sekta ya usafirishaji.\n\nTunataka kupanua huduma zetu kwenda mikoa ya Mwanza, Arusha na Dodoma. Tunaamini ushirikiano wetu unaweza kuleta faida kubwa.\n\nNingependa kukutana nawe wiki ijayo kujadili zaidi. Je, una nafasi?\n\nHeshima,\nRashid Mbwana\nMkurugenzi\nFast Cargo Ltd',
        'isRead': false,
        'hoursAgo': 80,
      },
      {
        'from': 'security@google.com',
        'fromName': 'Google Security',
        'subject': 'Security Alert — New sign-in from Windows',
        'body':
            'A new sign-in was detected on your Google Account.\n\nDevice: Windows PC\nLocation: Dar es Salaam, Tanzania\nTime: April 3, 2026, 2:15 PM EAT\n\nIf this was you, no action is needed.\nIf not, secure your account immediately.\n\nGoogle LLC',
        'isRead': true,
        'hoursAgo': 96,
      },
      {
        'from': 'fatma.salim@techno.ac.tz',
        'fromName': 'Dr. Fatma Salim',
        'subject': 'Internship Program — Summer 2026',
        'body':
            'Dear Partner,\n\nThe Dar es Salaam Institute of Technology is seeking placement opportunities for our final-year students (July-September 2026).\n\nWe have students specializing in:\n- Software Engineering (8 students)\n- Business Administration (12 students)\n- Accounting & Finance (6 students)\n\nWould your organization be willing to host 2-3 interns?\n\nPlease respond by April 20, 2026.\n\nDr. Fatma Salim\nDean of Students\nDIT',
        'isRead': false,
        'hoursAgo': 110,
      },
      {
        'from': 'noreply@github.com',
        'fromName': 'GitHub',
        'subject': '[tajiri-app] Pull request #247 merged',
        'body':
            'The following pull request has been merged:\n\n#247 feat: add email client module\nMerged by @andrewmashamba into main\n\n+1,245 -32 across 8 files\n\nView on GitHub: https://github.com/tajiri-app/tajiri-frontend/pull/247',
        'isRead': true,
        'hoursAgo': 130,
      },
      {
        'from': 'anna.mwakasege@pwc.co.tz',
        'fromName': 'Anna Mwakasege',
        'subject': 'Audit Report — FY 2025',
        'body':
            'Dear Management,\n\nPlease find attached the final audit report for the financial year ended December 31, 2025.\n\nKey findings:\n1. Clean opinion on financial statements\n2. Minor observations on inventory management\n3. Recommendations for internal controls improvement\n\nWe request a management response by April 30, 2026.\n\nAnna Mwakasege, CPA\nSenior Auditor\nPwC Tanzania',
        'hasAttachments': true,
        'attachments': [
          const MockAttachment(
              name: 'Audit_Report_FY2025.pdf', size: '5.8 MB', type: 'pdf'),
          const MockAttachment(
              name: 'Management_Letter.pdf', size: '2.1 MB', type: 'pdf'),
          const MockAttachment(
              name: 'Financial_Statements.xlsx',
              size: '890 KB',
              type: 'xlsx'),
        ],
        'isRead': false,
        'isFlagged': true,
        'hoursAgo': 150,
      },
    ];

    for (int i = 0; i < inboxData.length; i++) {
      final d = inboxData[i];
      final body = d['body'] as String;
      emails.add(MockEmail(
        id: 'inbox_${i}_${accountEmail.hashCode.abs()}',
        from: d['from'] as String,
        fromName: d['fromName'] as String,
        to: [accountEmail],
        cc: i % 5 == 0 ? ['team@${accountEmail.split('@').last}'] : null,
        subject: d['subject'] as String,
        body: body,
        preview:
            body.length > 100 ? '${body.substring(0, 100)}...' : body,
        date: now.subtract(Duration(hours: d['hoursAgo'] as int)),
        isRead: d['isRead'] as bool? ?? rng.nextBool(),
        isFlagged: d['isFlagged'] as bool? ?? false,
        hasAttachments: d['hasAttachments'] as bool? ?? false,
        attachments:
            (d['attachments'] as List<MockAttachment>?) ?? [],
        folder: 'inbox',
      ));
    }

    // -- Sent emails (4) ------------------------------------------------------
    final sentData = [
      {
        'to': ['sarah.kimaro@gmail.com'],
        'subject': 'Meeting Tomorrow at 10am',
        'body':
            'Hi Sarah,\n\nCan we meet tomorrow at 10am to discuss the Dodoma project? I have the updated financials ready.\n\nRegards',
        'hoursAgo': 6,
      },
      {
        'to': ['amina.hassan@outlook.com'],
        'subject': 'Re: Quotation Request — Office Furniture',
        'body':
            'Habari Amina,\n\nAsante kwa maombi yako. Quotation imeambatishwa hapa chini. Bei ni pamoja na delivery ndani ya Dar es Salaam.\n\nKaribuni.',
        'hoursAgo': 20,
      },
      {
        'to': ['accounts@supplier.co.tz'],
        'subject': 'Purchase Order #PO-2026-089',
        'body':
            'Dear Supplier,\n\nPlease find attached our purchase order for the items discussed. Kindly confirm availability and expected delivery date.\n\nThank you.',
        'hoursAgo': 50,
      },
      {
        'to': ['fatma.salim@techno.ac.tz'],
        'subject': 'Re: Internship Program — Summer 2026',
        'body':
            'Dear Dr. Salim,\n\nThank you for reaching out. We would be happy to host 2 software engineering interns. Please send their CVs for our review.\n\nBest regards',
        'hoursAgo': 115,
      },
    ];

    for (int i = 0; i < sentData.length; i++) {
      final d = sentData[i];
      final body = d['body'] as String;
      emails.add(MockEmail(
        id: 'sent_${i}_${accountEmail.hashCode.abs()}',
        from: accountEmail,
        fromName: 'Me',
        to: d['to'] as List<String>,
        subject: d['subject'] as String,
        body: body,
        preview:
            body.length > 100 ? '${body.substring(0, 100)}...' : body,
        date: now.subtract(Duration(hours: d['hoursAgo'] as int)),
        isRead: true,
        folder: 'sent',
      ));
    }

    // -- Drafts (2) -----------------------------------------------------------
    emails.add(MockEmail(
      id: 'draft_0_${accountEmail.hashCode.abs()}',
      from: accountEmail,
      fromName: 'Me',
      to: ['client@example.com'],
      subject: 'Proposal — Digital Transformation Services',
      body:
          'Dear Client,\n\nFollowing our discussion, I am pleased to present our proposal for...',
      preview: 'Dear Client, Following our discussion, I am pleased to present our proposal for...',
      date: now.subtract(const Duration(hours: 4)),
      isRead: true,
      folder: 'drafts',
    ));
    emails.add(MockEmail(
      id: 'draft_1_${accountEmail.hashCode.abs()}',
      from: accountEmail,
      fromName: 'Me',
      to: [],
      subject: '',
      body: 'Notes from the board meeting:\n- Revenue target Q2...',
      preview: 'Notes from the board meeting: Revenue target Q2...',
      date: now.subtract(const Duration(days: 2)),
      isRead: true,
      folder: 'drafts',
    ));

    // -- Spam (2) -------------------------------------------------------------
    emails.add(MockEmail(
      id: 'spam_0_${accountEmail.hashCode.abs()}',
      from: 'winner@lottery-uk.com',
      fromName: 'UK National Lottery',
      to: [accountEmail],
      subject: 'CONGRATULATIONS! You have won GBP 1,000,000!!!',
      body:
          'Dear Lucky Winner,\n\nYour email was selected in our online draw. You have won ONE MILLION POUNDS! Click here to claim...',
      preview:
          'Dear Lucky Winner, Your email was selected in our online draw...',
      date: now.subtract(const Duration(hours: 14)),
      isRead: false,
      folder: 'spam',
    ));
    emails.add(MockEmail(
      id: 'spam_1_${accountEmail.hashCode.abs()}',
      from: 'deals@cheapmeds.xyz',
      fromName: 'Online Pharmacy',
      to: [accountEmail],
      subject: '80% OFF — Limited Time Offer!!!',
      body: 'Buy now and save big! Special prices just for you...',
      preview: 'Buy now and save big! Special prices just for you...',
      date: now.subtract(const Duration(days: 3)),
      isRead: false,
      folder: 'spam',
    ));

    return emails;
  }
}
