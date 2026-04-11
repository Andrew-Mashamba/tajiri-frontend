// lib/events/models/event_strings.dart
// Bilingual strings for the Events module (Swahili primary, English secondary)

class EventStrings {
  final bool isSwahili;
  const EventStrings({this.isSwahili = true});

  // ── Navigation ──
  String get events => isSwahili ? 'Matukio' : 'Events';
  String get myEvents => isSwahili ? 'Matukio Yangu' : 'My Events';
  String get myTickets => isSwahili ? 'Tiketi Zangu' : 'My Tickets';
  String get browseEvents => isSwahili ? 'Tafuta Matukio' : 'Browse Events';
  String get createEvent => isSwahili ? 'Unda Tukio' : 'Create Event';
  String get editEvent => isSwahili ? 'Hariri Tukio' : 'Edit Event';
  String get eventDetail => isSwahili ? 'Maelezo ya Tukio' : 'Event Detail';
  String get search => isSwahili ? 'Tafuta' : 'Search';
  String get calendar => isSwahili ? 'Kalenda' : 'Calendar';

  // ── Tabs ──
  String get forYou => isSwahili ? 'Kwako' : 'For You';
  String get friends => isSwahili ? 'Marafiki' : 'Friends';
  String get nearby => isSwahili ? 'Karibu Nawe' : 'Nearby';
  String get trending => isSwahili ? 'Maarufu' : 'Trending';
  String get hosting => isSwahili ? 'Ninaandaa' : 'Hosting';
  String get attending => isSwahili ? 'Ninahudhuria' : 'Attending';
  String get saved => isSwahili ? 'Zilizohifadhiwa' : 'Saved';

  // ── RSVP ──
  String get going => isSwahili ? 'Nahudhuria' : 'Going';
  String get interested => isSwahili ? 'Napendezwa' : 'Interested';
  String get notGoing => isSwahili ? 'Sihudhuri' : 'Not Going';
  String get rsvp => 'RSVP';

  // ── Ticketing ──
  String get getTickets => isSwahili ? 'Pata Tiketi' : 'Get Tickets';
  String get buyTicket => isSwahili ? 'Nunua Tiketi' : 'Buy Ticket';
  String get buyTickets => isSwahili ? 'Nunua Tiketi' : 'Buy Tickets';
  String get free => isSwahili ? 'Bure' : 'Free';
  String get soldOut => isSwahili ? 'Tiketi Zimeisha' : 'Sold Out';
  String get joinWaitlist => isSwahili ? 'Jiunge na Orodha ya Kusubiri' : 'Join Waitlist';
  String get leaveWaitlist => isSwahili ? 'Ondoka kwenye Orodha' : 'Leave Waitlist';
  String get selectTier => isSwahili ? 'Chagua Aina ya Tiketi' : 'Select Ticket Tier';
  String get quantity => isSwahili ? 'Idadi' : 'Quantity';
  String get addons => isSwahili ? 'Vongeza' : 'Add-ons';
  String get promoCode => isSwahili ? 'Msimbo wa Punguzo' : 'Promo Code';
  String get applyCode => isSwahili ? 'Tumia' : 'Apply';
  String get total => isSwahili ? 'Jumla' : 'Total';
  String get paymentMethod => isSwahili ? 'Njia ya Malipo' : 'Payment Method';
  String get ticketPurchased => isSwahili ? 'Tiketi imenunuliwa!' : 'Ticket purchased!';
  String get transferTicket => isSwahili ? 'Hamisha Tiketi' : 'Transfer Ticket';
  String get giftTicket => isSwahili ? 'Toa Tiketi Zawadi' : 'Gift Ticket';
  String get requestRefund => isSwahili ? 'Omba Kurudishiwa' : 'Request Refund';
  String get remaining => isSwahili ? 'zimebaki' : 'remaining';

  // ── Social ──
  String get friendsGoing => isSwahili ? 'Marafiki wanahudhuria' : 'Friends going';
  String get invite => isSwahili ? 'Alika' : 'Invite';
  String get inviteFriends => isSwahili ? 'Alika Marafiki' : 'Invite Friends';
  String get share => isSwahili ? 'Shiriki' : 'Share';
  String get save => isSwahili ? 'Hifadhi' : 'Save';
  String get unsave => isSwahili ? 'Ondoa Kuhifadhi' : 'Unsave';
  String get report => isSwahili ? 'Ripoti' : 'Report';
  String get wall => isSwahili ? 'Ukuta' : 'Wall';
  String get details => isSwahili ? 'Maelezo' : 'Details';
  String get agenda => isSwahili ? 'Ratiba' : 'Agenda';
  String get photos => isSwahili ? 'Picha' : 'Photos';
  String get reviews => isSwahili ? 'Maoni' : 'Reviews';
  String get attendees => isSwahili ? 'Washiriki' : 'Attendees';
  String get comments => isSwahili ? 'Maoni' : 'Comments';
  String get writeComment => isSwahili ? 'Andika maoni...' : 'Write a comment...';
  String get writeSomething => isSwahili ? 'Andika kitu...' : 'Write something...';
  String get addToCalendar => isSwahili ? 'Ongeza kwenye Kalenda' : 'Add to Calendar';

  // ── Event types ──
  String get inPerson => isSwahili ? 'Ana kwa Ana' : 'In Person';
  String get virtual => isSwahili ? 'Mtandaoni' : 'Virtual';
  String get hybrid => isSwahili ? 'Mseto' : 'Hybrid';

  // ── Create Event ──
  String get eventName => isSwahili ? 'Jina la Tukio' : 'Event Name';
  String get description => isSwahili ? 'Maelezo' : 'Description';
  String get category => isSwahili ? 'Aina' : 'Category';
  String get dateAndTime => isSwahili ? 'Tarehe na Muda' : 'Date & Time';
  String get startDate => isSwahili ? 'Tarehe ya Kuanza' : 'Start Date';
  String get endDate => isSwahili ? 'Tarehe ya Mwisho' : 'End Date';
  String get startTime => isSwahili ? 'Muda wa Kuanza' : 'Start Time';
  String get endTime => isSwahili ? 'Muda wa Mwisho' : 'End Time';
  String get allDay => isSwahili ? 'Siku Nzima' : 'All Day';
  String get recurring => isSwahili ? 'Inarudia' : 'Recurring';
  String get location => isSwahili ? 'Mahali' : 'Location';
  String get address => isSwahili ? 'Anwani' : 'Address';
  String get onlineLink => isSwahili ? 'Kiungo cha Mtandaoni' : 'Online Link';
  String get privacy => isSwahili ? 'Faragha' : 'Privacy';
  String get coverPhoto => isSwahili ? 'Picha ya Jalada' : 'Cover Photo';
  String get ticketing => isSwahili ? 'Tiketi' : 'Ticketing';
  String get freeEvent => isSwahili ? 'Tukio Bure' : 'Free Event';
  String get addTicketTier => isSwahili ? 'Ongeza Aina ya Tiketi' : 'Add Ticket Tier';
  String get tierName => isSwahili ? 'Jina la Aina' : 'Tier Name';
  String get price => isSwahili ? 'Bei' : 'Price';
  String get totalTickets => isSwahili ? 'Tiketi Zote' : 'Total Tickets';
  String get extras => isSwahili ? 'Viongezeo' : 'Extras';
  String get speakers => isSwahili ? 'Wasemaji' : 'Speakers';
  String get sponsors => isSwahili ? 'Wadhamini' : 'Sponsors';
  String get coHosts => isSwahili ? 'Wasaidizi' : 'Co-Hosts';
  String get signupList => isSwahili ? 'Orodha ya Kusajili' : 'Signup List';
  String get reviewAndPublish => isSwahili ? 'Kagua na Chapisha' : 'Review & Publish';
  String get saveAsDraft => isSwahili ? 'Hifadhi Rasimu' : 'Save as Draft';
  String get publishNow => isSwahili ? 'Chapisha Sasa' : 'Publish Now';
  String get next => isSwahili ? 'Endelea' : 'Next';
  String get back => isSwahili ? 'Rudi' : 'Back';
  String get eventCreated => isSwahili ? 'Tukio limeundwa!' : 'Event created!';

  // ── Organizer ──
  String get dashboard => isSwahili ? 'Dashibodi' : 'Dashboard';
  String get analytics => isSwahili ? 'Takwimu' : 'Analytics';
  String get salesReport => isSwahili ? 'Ripoti ya Mauzo' : 'Sales Report';
  String get checkIn => isSwahili ? 'Sajili Kuingia' : 'Check In';
  String get scanQR => isSwahili ? 'Changanua QR' : 'Scan QR';
  String get team => isSwahili ? 'Timu' : 'Team';
  String get announce => isSwahili ? 'Tangazo' : 'Announcement';
  String get sendAnnouncement => isSwahili ? 'Tuma Tangazo' : 'Send Announcement';
  String get survey => isSwahili ? 'Utafiti' : 'Survey';
  String get payout => isSwahili ? 'Malipo' : 'Payout';
  String get requestPayout => isSwahili ? 'Omba Malipo' : 'Request Payout';
  String get revenue => isSwahili ? 'Mapato' : 'Revenue';
  String get views => isSwahili ? 'Matazamio' : 'Views';
  String get ticketsSold => isSwahili ? 'Tiketi Zilizouzwa' : 'Tickets Sold';
  String get organizerDashboard => isSwahili ? 'Dashibodi ya Mpanga' : 'Organizer Dashboard';
  String get overview => isSwahili ? 'Muhtasari' : 'Overview';
  String get quickActions => isSwahili ? 'Vitendo vya Haraka' : 'Quick Actions';
  String get recentSales => isSwahili ? 'Mauzo ya Hivi Karibuni' : 'Recent Sales';
  String get checkInRate => isSwahili ? 'Kiwango cha Kuingia' : 'Check-in Rate';
  String get shares => isSwahili ? 'Tuma kwa Wengine' : 'Shares';
  String get announcements => isSwahili ? 'Matangazo' : 'Announcements';
  String get teamManagement => isSwahili ? 'Usimamizi wa Timu' : 'Team Management';
  String get ticketManagement => isSwahili ? 'Usimamizi wa Tiketi' : 'Ticket Management';
  String get ticketTiers => isSwahili ? 'Aina za Tiketi' : 'Ticket Tiers';
  String get tickets => isSwahili ? 'Tiketi' : 'Tickets';
  String get promoCodes => isSwahili ? 'Misimbo ya Punguzo' : 'Promo Codes';
  String get announcementHint => isSwahili ? 'Andika tangazo lako hapa...' : 'Write your announcement here...';
  String get searchAttendees => isSwahili ? 'Tafuta washiriki...' : 'Search attendees...';
  String get noAttendeesYet => isSwahili ? 'Hakuna washiriki bado' : 'No attendees yet';
  String get noTeamMembersYet => isSwahili ? 'Hakuna wanachama wa timu bado' : 'No team members yet';
  String get grossRevenue => isSwahili ? 'Mapato Jumla' : 'Gross Revenue';
  String get platformFees => isSwahili ? 'Ada za Jukwaa' : 'Platform Fees';
  String get netRevenue => isSwahili ? 'Mapato Halisi' : 'Net Revenue';
  String get pendingPayout => isSwahili ? 'Malipo Yanayosubiri' : 'Pending Payout';
  String get paidOut => isSwahili ? 'Yaliyolipwa' : 'Paid Out';
  String get surveyBuilder => isSwahili ? 'Jenga Utafiti' : 'Survey Builder';
  String get submit => isSwahili ? 'Wasilisha' : 'Submit';
  String get addQuestion => isSwahili ? 'Ongeza Swali' : 'Add Question';

  // ── Filters ──
  String get all => isSwahili ? 'Zote' : 'All';
  String get today => isSwahili ? 'Leo' : 'Today';
  String get tomorrow => isSwahili ? 'Kesho' : 'Tomorrow';
  String get thisWeekend => isSwahili ? 'Wikendi Hii' : 'This Weekend';
  String get thisWeek => isSwahili ? 'Wiki Hii' : 'This Week';
  String get thisMonth => isSwahili ? 'Mwezi Huu' : 'This Month';
  String get happeningNow => isSwahili ? 'Inaendelea Sasa' : 'Happening Now';
  String get justAnnounced => isSwahili ? 'Mpya' : 'Just Announced';
  String get upcoming => isSwahili ? 'Zinazokuja' : 'Upcoming';
  String get past => isSwahili ? 'Zilizopita' : 'Past';

  // ── Empty States ──
  String get noEvents => isSwahili ? 'Hakuna matukio' : 'No events';
  String get noTickets => isSwahili ? 'Huna tiketi bado' : 'No tickets yet';
  String get noResults => isSwahili ? 'Hakuna matokeo' : 'No results';
  String get noComments => isSwahili ? 'Hakuna maoni bado' : 'No comments yet';
  String get noPhotos => isSwahili ? 'Hakuna picha bado' : 'No photos yet';
  String get noReviews => isSwahili ? 'Hakuna maoni bado' : 'No reviews yet';

  // ── Errors ──
  String get loadError => isSwahili ? 'Imeshindwa kupakia' : 'Failed to load';
  String get tryAgain => isSwahili ? 'Jaribu tena' : 'Try again';
  String get networkError => isSwahili ? 'Hakuna mtandao' : 'No connection';

  // ── Date in Swahili ──
  static const swahiliDays = ['Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi', 'Jumapili'];
  static const swahiliMonths = ['Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni', 'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'];

  String formatDate(DateTime date) {
    if (isSwahili) {
      return '${swahiliDays[date.weekday - 1]}, ${date.day} ${swahiliMonths[date.month - 1]} ${date.year}';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String formatDateShort(DateTime date) {
    if (isSwahili) {
      return '${date.day} ${swahiliMonths[date.month - 1].substring(0, 3)} ${date.year}';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String formatPrice(double amount, String currency) {
    if (amount <= 0) return free;
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currency $formatted';
  }

  String formatFriendsGoing(int count, List<String> names) {
    if (count == 0) return '';
    if (names.isEmpty) return '$count $friendsGoing';
    if (names.length == 1) return '${names[0]} ${isSwahili ? "anahudhuria" : "is going"}';
    if (names.length == 2) return '${names[0]} ${isSwahili ? "na" : "&"} ${names[1]}';
    final others = count - 2;
    return '${names[0]}, ${names[1]} ${isSwahili ? "na $others wengine" : "& $others others"}';
  }
}
