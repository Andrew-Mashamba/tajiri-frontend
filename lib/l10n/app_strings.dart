/// App-wide display strings: Spoken/Street English (default) and Spoken/Street Swahili.
/// Use via [AppStringsScope.of(context)] after wrapping app in [AppStringsScope].
class AppStrings {
  AppStrings(this.languageCode) : isSwahili = languageCode == 'sw' || languageCode.startsWith('sw');

  final String languageCode;
  final bool isSwahili;

  // ——— General ———
  String get appName => isSwahili ? 'TAJIRI' : 'TAJIRI';
  String get appTagline => isSwahili ? 'Jifunze. Jikuze. Jitajiri.' : 'Learn. Grow. Get rich.';
  String get loading => isSwahili ? 'Inapakia...' : 'Loading...';
  String get cancel => isSwahili ? 'Ghairi' : 'Cancel';
  String get save => isSwahili ? 'Hifadhi' : 'Save';
  String get done => isSwahili ? 'Sawa' : 'Done';
  String get continueBtn => isSwahili ? 'Endelea' : 'Continue';
  String get next => isSwahili ? 'Ifuatayo' : 'Next';
  String get back => isSwahili ? 'Rudi' : 'Back';
  String get yes => isSwahili ? 'Ndiyo' : 'Yes';
  String get no => isSwahili ? 'Hapana' : 'No';
  String get ok => isSwahili ? 'Sawa' : 'OK';
  String get error => isSwahili ? 'Hitilafu' : 'Error';
  String get retry => isSwahili ? 'Jaribu tena' : 'Retry';
  String get close => isSwahili ? 'Funga' : 'Close';
  String get delete => isSwahili ? 'Futa' : 'Delete';
  String get edit => isSwahili ? 'Hariri' : 'Edit';
  String get search => isSwahili ? 'Tafuta' : 'Search';
  String get share => isSwahili ? 'Shiriki' : 'Share';
  String get viewAll => isSwahili ? 'Tazama zote' : 'View all';
  String get noResults => isSwahili ? 'Hakuna matokeo' : 'No results';
  String get noData => isSwahili ? 'Hakuna data' : 'No data';

  // ——— Home (bottom nav) ———
  String get homeTab => isSwahili ? 'Nyumbani' : 'Home';
  String get peopleTab => isSwahili ? 'Watu' : 'People';
  String get friendsTab => isSwahili ? 'Marafiki' : 'Friends';
  String get messagesTab => isSwahili ? 'Ujumbe' : 'Messages';
  String get photosTab => isSwahili ? 'Picha' : 'Photos';
  String get shopTab => isSwahili ? 'Duka' : 'Shop';
  String get profileTab => isSwahili ? 'Mimi' : 'Me';

  // ——— Settings ———
  String get settings => isSwahili ? 'Mipangilio' : 'Settings';
  String get account => isSwahili ? 'Akaunti' : 'Account';
  String get profile => isSwahili ? 'Wasifu' : 'Profile';
  String get editProfileSubtitle => isSwahili ? 'Badilisha picha na maelezo yako' : 'Change your photo and details';
  String get username => isSwahili ? 'Jina la Mtumiaji' : 'Username';
  String get usernameSubtitle => isSwahili ? 'Weka au badilisha @handle yako' : 'Set or change your @handle';
  String get profileTabs => isSwahili ? 'Tabo za Wasifu' : 'Profile tabs';
  String get profileTabsSubtitle => isSwahili ? 'Panga na uwashe/uzime tabo' : 'Arrange and show/hide tabs';
  String get notifications => isSwahili ? 'Arifa' : 'Notifications';
  String get pushNotifications => isSwahili ? 'Arifa za Push' : 'Push notifications';
  String get pushNotificationsSubtitle => isSwahili ? 'Pokea arifa za ujumbe na shughuli' : 'Get message and activity alerts';
  String get privacy => isSwahili ? 'Faragha' : 'Privacy';
  String get privacySubtitle => isSwahili ? 'Usimamie nani anakuona' : 'Control who sees you';
  String get security => isSwahili ? 'Usalama' : 'Security';
  String get securitySubtitle => isSwahili ? 'Nenosiri na uthibitisho' : 'Password and verification';
  String get display => isSwahili ? 'Mwonekano' : 'Display';
  String get darkMode => isSwahili ? 'Hali ya Giza' : 'Dark mode';
  String get darkModeSubtitleDark => isSwahili ? 'Giza' : 'Dark';
  String get darkModeSubtitleLight => isSwahili ? 'Nuru (Light)' : 'Light';
  String get language => isSwahili ? 'Lugha' : 'Language';
  String get languageEnglish => isSwahili ? 'English' : 'English';
  String get languageSwahili => isSwahili ? 'Kiswahili' : 'Kiswahili';
  String get chooseLanguage => isSwahili ? 'Chagua Lugha' : 'Choose language';
  String get logout => isSwahili ? 'Ondoka' : 'Log out';
  String get deleteAccount => isSwahili ? 'Futa Akaunti' : 'Delete account';
  String get logoutConfirmTitle => isSwahili ? 'Ondoka' : 'Log out';
  String get logoutConfirmMessage => isSwahili ? 'Una uhakika unataka kuondoka kwenye akaunti yako?' : 'Are you sure you want to log out?';
  String get deleteAccountConfirmTitle => isSwahili ? 'Futa Akaunti' : 'Delete account';
  String get deleteAccountConfirmMessage => isSwahili ? 'Hatua hii haiwezi kutenduliwa. Data yako yote itafutwa kabisa. Una uhakika?' : 'This cannot be undone. All your data will be permanently deleted. Are you sure?';
  String get deleteAccountRequestSent => isSwahili ? 'Ombi la kufuta limetumwa' : 'Delete request sent';
  String get appVersion => isSwahili ? 'Tajiri v1.0.0' : 'Tajiri v1.0.0';

  // ——— Login & Registration ———
  String get welcome => isSwahili ? 'Karibu' : 'Welcome';
  String get welcomeSubtitle => isSwahili ? 'Ingia au jisajili kwa simu' : 'Sign in or register with your phone';
  String get createAccount => isSwahili ? 'Jisajili' : 'Create account';
  String get signIn => isSwahili ? 'Ingia' : 'Sign in';
  String get welcomeToTajiri => isSwahili ? 'Karibu Tajiri!' : 'Welcome to Tajiri!';
  String get tellUsAboutYou => isSwahili ? 'Tuambie kuhusu wewe' : 'Tell us about you';
  String get firstName => isSwahili ? 'Jina la Kwanza' : 'First name';
  String get lastName => isSwahili ? 'Jina la Ukoo' : 'Last name';
  String get firstNameHint => isSwahili ? 'Mfano: Juma' : 'e.g. Juma';
  String get lastNameHint => isSwahili ? 'Mfano: Mohamed' : 'e.g. Mohamed';
  String get dateOfBirth => isSwahili ? 'Tarehe ya Kuzaliwa' : 'Date of birth';
  String get selectDate => isSwahili ? 'Chagua tarehe' : 'Select date';
  String get selectDateOfBirth => isSwahili ? 'Chagua tarehe ya kuzaliwa' : 'Select date of birth';
  String get choose => isSwahili ? 'Chagua' : 'Choose';
  String get gender => isSwahili ? 'Jinsia' : 'Gender';
  String get male => isSwahili ? 'Mwanaume' : 'Male';
  String get female => isSwahili ? 'Mwanamke' : 'Female';
  String get firstNameRequired => isSwahili ? 'Jina la kwanza linahitajika' : 'First name is required';
  String get lastNameRequired => isSwahili ? 'Jina la ukoo linahitajika' : 'Last name is required';
  String get dateOfBirthRequired => isSwahili ? 'Chagua tarehe ya kuzaliwa' : 'Date of birth is required';
  String get genderRequired => isSwahili ? 'Chagua jinsia' : 'Please select gender';
  String get enterFirstName => isSwahili ? 'Ingiza jina la kwanza' : 'Enter first name';
  String get enterLastName => isSwahili ? 'Ingiza jina la mwisho' : 'Enter last name';
  String get bioLabel => isSwahili ? 'Wasifu (bio)' : 'Bio';
  String get usernameLabel => isSwahili ? 'Jina la mtumiaji (@username)' : 'Username (@username)';
  String get interestsLabel => isSwahili ? 'Masilahi (tenganisha kwa comma)' : 'Interests (comma-separated)';
  String get relationshipStatus => isSwahili ? 'Hali ya uhusiano' : 'Relationship status';
  String get single => isSwahili ? 'Sijaoa/Sijaolewa' : 'Single';
  String get married => isSwahili ? 'Nimeoa/Nimeolewa' : 'Married';
  String get engaged => isSwahili ? 'Nimechumbiwa' : 'Engaged';
  String get complicated => isSwahili ? 'Ni ngumu' : 'Complicated';
  String get profileSaved => isSwahili ? 'Wasifu umehifadhiwa' : 'Profile saved';
  String get phoneUnknown => isSwahili ? 'Nambari ya simu haijulikani' : 'Phone number unknown';
  String get failedToLoadProfile => isSwahili ? 'Imeshindwa kupakia wasifu' : 'Failed to load profile';
  String get photoUpdated => isSwahili ? 'Picha imebadilishwa' : 'Photo updated';
  String get photoUpdateFailed => isSwahili ? 'Imeshindwa kubadilisha picha' : 'Failed to update photo';
  String get coverPhotoUpdated => isSwahili ? 'Picha ya jalada imebadilishwa' : 'Cover photo updated';
  String get coverPhotoUpdateFailed => isSwahili ? 'Imeshindwa kubadilisha picha' : 'Failed to update photo';
  String get friendRequestSent => isSwahili ? 'Ombi la urafiki limetumwa' : 'Friend request sent';
  String get friendRequestFailed => isSwahili ? 'Imeshindwa kutuma ombi la urafiki. Jaribu tena.' : 'Failed to send friend request. Try again.';
  String get nowFriends => isSwahili ? 'Sasa ni marafiki!' : 'Now friends!';
  String get requestCancelled => isSwahili ? 'Ombi limefutwa' : 'Request cancelled';
  String get removeFriendTitle => isSwahili ? 'Ondoa Rafiki' : 'Remove friend';
  String removeFriendMessage(String name) => isSwahili ? 'Una uhakika unataka kumuondoa $name kama rafiki?' : 'Are you sure you want to remove $name as a friend?';
  String get noButton => isSwahili ? 'Hapana' : 'No';
  String get yesButton => isSwahili ? 'Ndiyo' : 'Yes';
  String get friendRemoved => isSwahili ? 'Urafiki umeondolewa' : 'Friend removed';
  String get editProfileComingSoon => isSwahili ? 'Kubadilisha wasifu - Inakuja hivi karibuni' : 'Edit profile - Coming soon';
  String get yesLogout => isSwahili ? 'Ndiyo, Toka' : 'Yes, log out';
  String get calls => isSwahili ? 'Simu' : 'Calls';
  String get tajiriPay => isSwahili ? 'Tajiri Pay' : 'Tajiri Pay';
  String get changeProfilePhoto => isSwahili ? 'Badilisha picha ya wasifu' : 'Change profile photo';
  String get sending => isSwahili ? 'Inatumwa...' : 'Sending...';
  String get message => isSwahili ? 'Ujumbe' : 'Message';
  String get subscribe => isSwahili ? 'Jisajili' : 'Subscribe';
  String get tips => isSwahili ? 'Tuzo' : 'Tips';
  String get joined => isSwahili ? 'Alijiunga' : 'Joined';
  String get mutualFriendsCount => isSwahili ? 'Marafiki wa pamoja' : 'mutual friends';
  String get storyHighlights => isSwahili ? 'Viango vya Hadithi' : 'Story highlights';
  String get storyDefaultTitle => isSwahili ? 'Hadithi' : 'Story';
  String get phoneNumber => isSwahili ? 'Namba ya Simu' : 'Phone number';
  String get enterCode => isSwahili ? 'Ingiza Kodi' : 'Enter code';
  String get weSentSms => isSwahili ? 'Tumekutumia SMS na kodi ya kuthibitisha' : 'We sent you an SMS with a verification code';
  String get weWillSendSms => isSwahili ? 'Tutakutumia SMS ya kuthibitisha' : 'We will send you an SMS to verify';
  String get sendCode => isSwahili ? 'Tuma Kodi' : 'Send code';
  String get change => isSwahili ? 'Badilisha' : 'Change';
  String get verify => isSwahili ? 'Thibitisha' : 'Verify';
  String resendInSeconds(int n) => isSwahili ? 'Tuma tena baada ya $n sekunde' : 'Resend in $n seconds';
  String get resendCode => isSwahili ? 'Tuma kodi tena' : 'Resend code';
  String get codeIncorrect => isSwahili ? 'Kodi si sahihi. Jaribu 111111' : 'Code is incorrect. Try 111111';
  String get phoneAlreadyRegistered => isSwahili ? 'Nambari hii ya simu imeshasajiliwa' : 'This phone number is already registered';
  String get phoneAvailable => isSwahili ? 'Nambari inapatikana. Tuma kodi.' : 'Number is available. Sending code.';
  String get phoneRequired => isSwahili ? 'Namba ya simu inahitajika' : 'Phone number is required';
  String stepLabelFormat(int current, int total) => isSwahili ? 'Hatua $current / $total' : 'Step $current of $total';
  String get stepBio => isSwahili ? 'Taarifa Binafsi' : 'Personal info';
  String get stepPhoto => isSwahili ? 'Picha ya Uso' : 'Face Photo';
  String get takeYourPhoto => isSwahili ? 'Piga picha yako' : 'Take your photo';
  String get takeYourPhotoDesc => isSwahili
      ? 'Tunahitaji picha inayoonyesha uso wako vizuri'
      : 'We need a photo that clearly shows your face';
  String get faceNotDetected => isSwahili
      ? 'Picha yako haionyeshi uso. Tafadhali piga picha inayoonyesha uso wako vizuri'
      : 'Your photo doesn\'t show a face. Please take a photo that clearly shows your face';
  String get multipleFacesDetected => isSwahili
      ? 'Picha ina watu wengi. Tafadhali piga picha yako peke yako'
      : 'Photo has multiple people. Please take a photo of just yourself';
  String get takePhotoBtn => isSwahili ? 'Piga Picha' : 'Take Photo';
  String get chooseFromGallery => isSwahili ? 'Chagua kutoka Picha' : 'Choose from Gallery';
  String get faceDetected => isSwahili ? 'Uso umegunduliwa!' : 'Face detected!';
  String get stepPhone => isSwahili ? 'Thibitisha Simu' : 'Verify phone';
  String get stepLocation => isSwahili ? 'Mahali Unapoishi' : 'Where you live';
  String get stepPrimary => isSwahili ? 'Shule ya Msingi' : 'Primary school';
  String get stepSecondary => isSwahili ? 'Sekondari (O-Level)' : 'Secondary (O-Level)';
  String get stepEducation => isSwahili ? 'Elimu Zaidi' : 'Further education';
  String get stepAlevel => isSwahili ? 'A-Level (Form 5-6)' : 'A-Level (Form 5-6)';
  String get stepPostSecondary => isSwahili ? 'Chuo/Taasisi' : 'College/Institution';
  String get stepUniversity => isSwahili ? 'Chuo Kikuu' : 'University';
  String get stepEmployer => isSwahili ? 'Mwajiri' : 'Employer';
  String get educationPathTitle => isSwahili ? 'Safari Yako ya Elimu' : 'Your education path';
  String get educationPathSubtitle => isSwahili ? 'Baada ya Form 4, ulifanya nini?' : 'After Form 4, what did you do?';
  String get optionAlevel => isSwahili ? 'Niliendelea na A-Level' : 'I continued with A-Level';
  String get optionNoAlevel => isSwahili ? 'Sikuendelea na A-Level' : 'I did not do A-Level';
  String get saving => isSwahili ? 'Inahifadhi taarifa...' : 'Saving...';
  String get congratulations => isSwahili ? 'Hongera!' : 'Congratulations!';
  String get registrationComplete => isSwahili ? 'Usajili wako umekamilika. Karibu Tajiri!' : 'Your registration is complete. Welcome to Tajiri!';
  String get viewProfile => isSwahili ? 'Tazama Wasifu' : 'View profile';
  String get saveFailed => isSwahili ? 'Imeshindwa kuhifadhi' : 'Failed to save';

  // ——— Feed ———
  String get feed => isSwahili ? 'Ujumbe' : 'Feed';
  String get friendsFeed => isSwahili ? 'Marafiki' : 'Friends';
  String get discover => isSwahili ? 'Gundua' : 'Discover';
  String get live => isSwahili ? 'Moja kwa moja' : 'Live';
  String get createPost => isSwahili ? 'Tengeneza Chapisho' : 'Create post';
  String get post => isSwahili ? 'Chapisho' : 'Post';
  String get posts => isSwahili ? 'Machapisho' : 'Posts';
  String get savedPosts => isSwahili ? 'Chapisho Zilizohifadhiwa' : 'Saved posts';
  String get noNotifications => isSwahili ? 'Hakuna arifa bado' : 'No notifications yet';
  String get notificationsHint => isSwahili ? 'Utakapopata likes, maoni, na wafuatiliaji wataonekana hapa' : 'When you get likes, comments, and follows they will show up here';
  String get noPosts => isSwahili ? 'Hakuna machapisho' : 'No posts';
  String get noPostsFromFriends => isSwahili ? 'Hakuna machapisho kutoka kwa marafiki' : 'No posts from friends';
  String get friendsFeedEmptyHint => isSwahili ? 'Ongeza marafiki ili kuona machapisho yao hapa' : 'Add friends to see their posts here';
  String get like => isSwahili ? 'Penda' : 'Like';
  String get comment => isSwahili ? 'Maoni' : 'Comment';
  String get comments => isSwahili ? 'Maoni' : 'Comments';
  String get addComment => isSwahili ? 'Ongeza maoni' : 'Add comment';
  String get writeComment => isSwahili ? 'Andika maoni...' : 'Write a comment...';
  String get send => isSwahili ? 'Tuma' : 'Send';
  String get likes => isSwahili ? 'Wapenda' : 'Likes';
  String get savePost => isSwahili ? 'Hifadhi' : 'Save';
  String get unsavePost => isSwahili ? 'Ondoa kwenye hifadhi' : 'Unsave';
  String get schedulePost => isSwahili ? 'Panga chapisho' : 'Schedule post';
  String get editPost => isSwahili ? 'Hariri chapisho' : 'Edit post';
  String get deletePost => isSwahili ? 'Futa chapisho' : 'Delete post';
  String get reportPost => isSwahili ? 'Ripoti' : 'Report';
  String get textPost => isSwahili ? 'Maandishi' : 'Text';
  String get photoPost => isSwahili ? 'Picha' : 'Photo';
  String get audioPost => isSwahili ? 'Sauti' : 'Audio';
  String get shortVideo => isSwahili ? 'Video fupi' : 'Short video';
  String get poll => isSwahili ? 'Kura' : 'Poll';
  String get whatOnYourMind => isSwahili ? 'Unafikiri nini?' : "What's on your mind?";
  String get writeSomething => isSwahili ? 'Andika kitu...' : 'Write something...';
  String get drafts => isSwahili ? 'Rasimu' : 'Drafts';
  String get scheduled => isSwahili ? 'Iliyopangwa' : 'Scheduled';
  String get noDrafts => isSwahili ? 'Hakuna rasimu' : 'No drafts';
  String get noScheduled => isSwahili ? 'Hakuna yaliyopangwa' : 'No scheduled posts';
  String get createNew => isSwahili ? 'Tengeneza mpya' : 'Create new';
  String get shortVideoSubtitle => isSwahili ? 'Hadi sekunde 60' : 'Up to 60 seconds';
  String get sharePhotos => isSwahili ? 'Shiriki picha' : 'Share photos';
  String get shareThoughts => isSwahili ? 'Shiriki mawazo' : 'Share thoughts';
  String get voiceMessage => isSwahili ? 'Ujumbe wa sauti' : 'Voice message';
  String get createPollSubtitle => isSwahili ? 'Unda kura' : 'Create poll';
  String get continueEditing => isSwahili ? 'Endelea kuhariri' : 'Continue editing';
  String get seeAll => isSwahili ? 'Tazama zote' : 'See all';
  String get proTips => isSwahili ? 'Vidokezo' : 'Pro tips';
  String get schedulePostsTip => isSwahili ? 'Panga machapisho kwa wakati unaofaa' : 'Schedule posts for optimal engagement times';
  String get shortVideosTip => isSwahili ? 'Video fupi zinapata umaarufu zaidi' : 'Short videos get 3x more reach';
  String get draftsAutoSaveTip => isSwahili ? 'Rasimu zinahifadhiwa wakati unapoandika' : 'Drafts auto-save as you type';
  String get tapToViewAndManage => isSwahili ? 'Bonyeza kuona na kusimamia' : 'Tap to view and manage';
  String get deleteDraftTitle => isSwahili ? 'Futa Rasimu?' : 'Delete draft?';
  String get deleteDraftMessage => isSwahili ? 'Hatua hii haiwezi kutenduliwa.' : 'This action cannot be undone.';
  String get draftDeleted => isSwahili ? 'Rasimu imefutwa' : 'Draft deleted';
  String get allDrafts => isSwahili ? 'Rasimu zote' : 'All drafts';
  String get allTypes => isSwahili ? 'Aina zote' : 'All types';
  String get schedulePostsSubtitle => isSwahili ? 'Panga machapisho kuchapishwa wakati unaofaa' : 'Schedule posts to publish at optimal times';
  String get scheduledPost => isSwahili ? 'Chapisho lililopangwa' : 'Scheduled post';
  String get scheduledPosts => isSwahili ? 'Machapisho yaliyopangwa' : 'Scheduled posts';
  String get publishNow => isSwahili ? 'Chapisha sasa' : 'Publish now';
  String get reschedule => isSwahili ? 'Panga tena' : 'Reschedule';
  String get published => isSwahili ? 'Imechapishwa!' : 'Published!';
  String get createPostTitle => isSwahili ? 'Tengeneza chapisho' : 'Create post';
  String get wasifu => isSwahili ? 'Wasifu' : 'Profile';
  String get userProfile => isSwahili ? 'Wasifu wa mtumiaji' : 'User profile';
  String get forYouTab => isSwahili ? 'Kwa Wewe' : 'For you';
  String get postsTab => isSwahili ? 'Machapisho' : 'Posts';
  String get savedTitle => isSwahili ? 'Iliyohifadhiwa' : 'Saved';
  String get noSavedPosts => isSwahili ? 'Hakuna machapisho yaliyohifadhiwa' : 'No saved posts';
  String get noSavedPostsHint => isSwahili ? 'Bofya ikoni ya bookmark kwenye chapisho ili kuhifadhi' : 'Tap bookmark on a post to save it';
  String get saveUpdateFailed => isSwahili ? 'Imeshindwa kusasisha hifadhi' : 'Failed to update save';
  String get removedFromSaved => isSwahili ? 'Imeondolewa kwenye hifadhi' : 'Removed from saved';
  String get savedSuccess => isSwahili ? 'Imehifadhiwa' : 'Saved';
  String get postDeleted => isSwahili ? 'Chapisho limefutwa' : 'Post deleted';
  String get deletePostConfirmTitle => isSwahili ? 'Futa Chapisho' : 'Delete post';
  String get deletePostConfirmMessage => isSwahili ? 'Una uhakika unataka kufuta chapisho hili?' : 'Are you sure you want to delete this post?';
  String get deletePostFailed => isSwahili ? 'Imeshindwa kufuta chapisho' : 'Failed to delete post';
  String get addButton => isSwahili ? 'Ongeza' : 'Add';
  String get viewClips => isSwahili ? 'Tazama Klipu' : 'View clips';
  String get noShorts => isSwahili ? 'Hakuna shorts' : 'No shorts';
  String get noShortsHint => isSwahili ? 'Ona video fupi baadaye' : 'Watch short videos later';
  String get followPeopleHint => isSwahili ? 'Fuata watu ili kuona machapisho yao' : 'Follow people to see their posts';
  String get postNotFound => isSwahili ? 'Chapisho haikupatikana' : 'Post not found';
  String get clipsTooltip => isSwahili ? 'Klipu' : 'Clips';
  String get savedTooltip => isSwahili ? 'Iliyohifadhiwa' : 'Saved';
  String get commentsNotFound => isSwahili ? 'Maoni hayakupatikana' : 'Comments could not be loaded';
  String get addCommentFailed => isSwahili ? 'Imeshindwa kuongeza maoni' : 'Failed to add comment';
  String get likeUpdateFailed => isSwahili ? 'Imeshindwa kusasisha pendo' : 'Failed to update like';
  String get noCommentsYet => isSwahili ? 'Hakuna maoni bado. Kuwa wa kwanza kutoa maoni.' : 'No comments yet. Be the first to comment.';
  String get postUpdated => isSwahili ? 'Chapisho limebadilishwa' : 'Post updated';
  String get postUpdateFailed => isSwahili ? 'Imeshindwa kubadilisha chapisho' : 'Failed to update post';
  String get editTimeExpired => isSwahili ? 'Muda wa kuhariri chapisho umekwisha.' : 'Time to edit this post has expired.';
  String get discardChangesTitle => isSwahili ? 'Ondoa Mabadiliko?' : 'Discard changes?';
  String get discardChangesMessage => isSwahili ? 'Una uhakika unataka kuondoka bila kuhifadhi mabadiliko?' : 'Are you sure you want to leave without saving changes?';
  String get whoCanSee => isSwahili ? 'Badilisha nani anaweza kuona' : 'Change who can see';
  String get public => isSwahili ? 'Hadharani' : 'Public';
  String get publicSubtitle => isSwahili ? 'Kila mtu anaweza kuona' : 'Everyone can see';
  String get friendsSubtitle => isSwahili ? 'Marafiki wako tu wanaweza kuona' : 'Only your friends can see';
  String get private => isSwahili ? 'Binafsi' : 'Only me';
  String get privateSubtitle => isSwahili ? 'Wewe tu unaweza kuona' : 'Only you can see';
  String get editPostTitle => isSwahili ? 'Hariri Chapisho' : 'Edit post';
  String get filesAttached => isSwahili ? 'faili zilizounganishwa' : 'files attached';
  String get fileAttached => isSwahili ? 'faili iliyounganishwa' : 'file attached';
  String get file => isSwahili ? 'Faili' : 'File';
  String get cannotBeChanged => isSwahili ? 'Haiwezi kubadilishwa' : 'Cannot be changed';
  String get editHistoryNote => isSwahili ? 'Historia ya mabadiliko itaonyeshwa kwenye chapisho (Iliyohaririwa).' : 'Edit history will be shown on the post (Edited).';
  String get userLabel => isSwahili ? 'Mtumiaji' : 'User';

  // ——— Profile & Me ———
  String get editProfile => isSwahili ? 'Hariri Wasifu' : 'Edit profile';
  String get profilePhoto => isSwahili ? 'Picha ya wasifu' : 'Profile photo';
  String get coverPhoto => isSwahili ? 'Picha ya jalada' : 'Cover photo';
  /// Me page: empty state when you have no posts yet.
  String get noPostsMe => isSwahili ? 'Hujachapisha chochote bado' : "You haven't posted yet";
  /// Me page: CTA to create first post.
  String get createPostNow => isSwahili ? 'Chapisha Sasa' : 'Post now';
  /// Me page: empty state when you have no groups.
  String get noGroupsMe => isSwahili ? 'Hujajiunga na kikundi chochote' : "You haven't joined any groups";
  /// Me page: empty state when you have no documents.
  String get noDocsMe => isSwahili ? 'Hujapakia nyaraka bado' : "You haven't uploaded any documents";
  /// Me page: empty state when you have no shop items.
  String get noShopMe => isSwahili ? 'Hujaweka bidhaa bado' : "You haven't listed any items";
  /// Me page: empty state when you have no videos.
  String get noVideosMe => isSwahili ? 'Hujapakia video bado' : "You haven't uploaded any videos";
  /// Me page: empty state when you have no music.
  String get noMusicMe => isSwahili ? 'Hujapakia muziki bado' : "You haven't uploaded any music";
  /// Me page: empty state when you have no photos.
  String get noPhotosMe => isSwahili ? 'Hujapakia picha bado' : "You haven't uploaded any photos";
  // Note: tajiriPay defined above in profile quick actions section
  String get callHistory => isSwahili ? 'Simu' : 'Calls';
  String get machapisho => isSwahili ? 'Machapisho' : 'Posts';
  String get picha => isSwahili ? 'Picha' : 'Photos';
  String get video => isSwahili ? 'Video' : 'Video';
  String get muziki => isSwahili ? 'Muziki' : 'Music';
  String get liveGallery => isSwahili ? 'Live' : 'Live';
  String get michango => isSwahili ? 'Michango' : 'Campaigns';
  String get vikundi => isSwahili ? 'Vikundi' : 'Groups';
  String get documents => isSwahili ? 'Nyaraka' : 'Documents';
  String get about => isSwahili ? 'Kuhusu' : 'About';
  String get goLive => isSwahili ? 'Enda Moja kwa Moja' : 'Go live';
  String get uploadMusic => isSwahili ? 'Pakia muziki' : 'Upload music';
  String get createCampaign => isSwahili ? 'Anzisha kampeni' : 'Create campaign';
  String get donate => isSwahili ? 'Changia' : 'Donate';
  String get withdraw => isSwahili ? 'Ondoa' : 'Withdraw';
  String get musicLibrary => isSwahili ? 'Maktaba ya muziki' : 'Music library';

  /// Own-profile tab labels (same pattern as myOrders, myProducts, etc.)
  String get myPosts => isSwahili ? 'Machapisho yangu' : 'My Posts';
  String get myPhotos => isSwahili ? 'Picha zangu' : 'My Photos';
  String get myVideos => isSwahili ? 'Video zangu' : 'My Videos';
  String get myMusic => isSwahili ? 'Muziki wangu' : 'My Music';
  String get myLive => isSwahili ? 'Mistari yangu' : 'My Streams';
  String get contributions => isSwahili ? 'Michango' : 'Contributions';
  String get myGroups => isSwahili ? 'Vikundi vyangu' : 'My Groups';
  String get myFiles => isSwahili ? 'Faili zangu' : 'My Files';
  String get myShop => isSwahili ? 'Duka langu' : 'My Shop';
  String get myFriends => isSwahili ? 'Marafiki wangu' : 'My Friends';

  /// Localized label for profile tab by id. Use for profile tab bar and tab settings.
  String profileTabLabel(String id) {
    switch (id) {
      case 'posts': return machapisho;
      case 'photos': return picha;
      case 'videos': return video;
      case 'music': return muziki;
      case 'live': return liveGallery;
      case 'michango': return michango;
      case 'groups': return vikundi;
      case 'documents': return documents;
      case 'shop': return shopTab;
      case 'friends': return friends;
      case 'about': return about;
      default: return id;
    }
  }

  /// For own profile: uses the same "My X" getters as myOrders, myProducts, etc.
  String profileTabLabelOwn(String id) {
    switch (id) {
      case 'posts': return myPosts;
      case 'photos': return myPhotos;
      case 'videos': return myVideos;
      case 'music': return myMusic;
      case 'live': return myLive;
      case 'michango': return contributions;
      case 'groups': return myGroups;
      case 'documents': return myFiles;
      case 'shop': return myShop;
      case 'friends': return myFriends;
      case 'about': return about;
      default: return isSwahili ? '$id yangu' : 'My $id';
    }
  }

  // ——— Friends ———
  String get friends => isSwahili ? 'Marafiki' : 'Friends';
  String get followers => isSwahili ? 'Wafuatao' : 'Followers';
  String get following => isSwahili ? 'Wanafuata' : 'Following';
  String get subscribers => isSwahili ? 'Wanachukua huduma' : 'Subscribers';
  String get friendRequests => isSwahili ? 'Maombi ya rafiki' : 'Friend requests';
  String get suggestions => isSwahili ? 'Mapendekezo' : 'Suggestions';
  String get addFriend => isSwahili ? 'Ongeza rafiki' : 'Add friend';
  String get accept => isSwahili ? 'Kubali' : 'Accept';
  String get decline => isSwahili ? 'Kataa' : 'Decline';
  String get noFriends => isSwahili ? 'Hakuna marafiki' : 'No friends yet';
  String get noFollowers => isSwahili ? 'Hakuna wafuatao' : 'No followers yet';
  String get noFollowing => isSwahili ? 'Hafuatii mtu yeyote' : 'Not following anyone yet';
  String get noSubscribers => isSwahili ? 'Hakuna wanachukua huduma' : 'No subscribers yet';
  String get follow => isSwahili ? 'Fuata' : 'Follow';
  String get unfollow => isSwahili ? 'Acha kufuata' : 'Unfollow';
  String get followed => isSwahili ? 'Unafuata' : 'Following';
  String get unfollowed => isSwahili ? 'Umeacha kufuata' : 'Unfollowed';
  String get requested => isSwahili ? 'Imeomba' : 'Requested';

  // ——— Messages ———
  String get messages => isSwahili ? 'Ujumbe' : 'Messages';
  String get chats => isSwahili ? 'Mazungumzo' : 'Chats';
  String get conversations => isSwahili ? 'Mazungumzo' : 'Conversations';
  String get chat => isSwahili ? 'Soga' : 'Chat';
  String get typeMessage => isSwahili ? 'Andika ujumbe...' : 'Type a message...';
  String get noConversations => isSwahili ? 'Hakuna mazungumzo' : 'No conversations';
  String get startNewConversation => isSwahili ? 'Anza mazungumzo mapya' : 'Start new conversations';
  String get startConversation => isSwahili ? 'Anza mazungumzo' : 'Start conversation';
  String get newMessage => isSwahili ? 'Ujumbe mpya' : 'New message';
  String get createGroup => isSwahili ? 'Unda kikundi' : 'Create group';
  String get noGroups => isSwahili ? 'Hakuna vikundi' : 'No groups';
  String get noCalls => isSwahili ? 'Hakuna simu' : 'No calls';
  String get requests => isSwahili ? 'Maombi' : 'Requests';
  String get call => isSwahili ? 'Simu' : 'Call';
  String get groupCall => isSwahili ? 'Simu ya kikundi' : 'Group call';
  String get typing => isSwahili ? 'Anaandika...' : 'Typing...';
  String get yesterday => isSwahili ? 'Jana' : 'Yesterday';
  String get draft => isSwahili ? 'Rasimu' : 'Draft';
  String get markAsRead => isSwahili ? 'Weka kama usomaji' : 'Mark as read';
  String get markUnread => isSwahili ? 'Weka kama usiyesomwa' : 'Mark as unread';
  String get archive => isSwahili ? 'Hifadhi' : 'Archive';
  String get unarchive => isSwahili ? 'Ondoa kwenye hifadhi' : 'Unarchive';
  String get recordingAudio => isSwahili ? 'Inarekodi sauti...' : 'Recording audio...';
  String get pin => isSwahili ? 'Bandika' : 'Pin';
  String get unpin => isSwahili ? 'Ondoa bandiko' : 'Unpin';
  String get more => isSwahili ? 'Zaidi' : 'More';
  String get archived => isSwahili ? 'Iliyohifadhiwa' : 'Archived';
  String get leaveChat => isSwahili ? 'Ondoka kwenye mazungumzo' : 'Leave chat';
  String get leaveChatConfirm => isSwahili ? 'Ondoka kwenye mazungumzo haya?' : 'Leave this conversation?';
  String get moveToFolder => isSwahili ? 'Hamisha kwenye kikasha' : 'Move to folder';

  // ——— Photos ———
  String get photos => isSwahili ? 'Picha' : 'Photos';
  String get albums => isSwahili ? 'Albamu' : 'Albums';
  String get uploadPhotos => isSwahili ? 'Pakia picha' : 'Upload photos';
  String get album => isSwahili ? 'Albamu' : 'Album';
  String get noPhotos => isSwahili ? 'Hakuna picha' : 'No photos';

  // ——— Clips / Shorts ———
  String get clips => isSwahili ? 'Video fupi' : 'Clips';
  String get shorts => isSwahili ? 'Video fupi' : 'Shorts';
  String get createClip => isSwahili ? 'Tengeneza video fupi' : 'Create clip';
  String get createHighlight => isSwahili ? 'Tengeneza kipengele' : 'Create highlight';
  String get highlights => isSwahili ? 'Viashiria' : 'Highlights';
  String get addToHighlight => isSwahili ? 'Ongeza kwenye kipengele' : 'Add to highlight';
  String get stories => isSwahili ? 'Hadithi' : 'Stories';
  String get createStory => isSwahili ? 'Tengeneza hadithi' : 'Create story';
  String get viewStory => isSwahili ? 'Tazama hadithi' : 'View story';
  String get yourStory => isSwahili ? 'Hadithi yako' : 'Your story';
  String get noStories => isSwahili ? 'Hakuna hadithi' : 'No stories';
  String get streams => isSwahili ? 'Mistari' : 'Streams';
  String get liveStreams => isSwahili ? 'Mistari ya moja kwa moja' : 'Live streams';
  String get noLiveStreams => isSwahili ? 'Hakuna mistari sasa' : 'No live streams now';
  String get battleMode => isSwahili ? 'Modi ya vita' : 'Battle mode';
  String get videoSearch => isSwahili ? 'Tafuta video' : 'Video search';
  String get uploadVideo => isSwahili ? 'Pakia video' : 'Upload video';
  String get musicUpload => isSwahili ? 'Pakia muziki' : 'Music upload';
  String get artist => isSwahili ? 'Msanii' : 'Artist';
  String get artists => isSwahili ? 'Wasanii' : 'Artists';

  // ——— Music ———
  String get music => isSwahili ? 'Muziki' : 'Music';
  String get play => isSwahili ? 'Cheza' : 'Play';
  String get pause => isSwahili ? 'Simama' : 'Pause';
  String get track => isSwahili ? 'Wimbo' : 'Track';
  String get tracks => isSwahili ? 'Nyimbo' : 'Tracks';
  String get category => isSwahili ? 'Kategoria' : 'Category';
  String get categories => isSwahili ? 'Makategoria' : 'Categories';

  // ——— Wallet & Payments ———
  String get wallet => isSwahili ? 'Pochi' : 'Wallet';
  String get creator => isSwahili ? 'Mwandishi' : 'Creator';
  String get tajiriPayWallet => isSwahili ? 'Tajiri Pay' : 'Tajiri Pay';
  String get balance => isSwahili ? 'Salio' : 'Balance';
  String get topUp => isSwahili ? 'Ongeza salio' : 'Top up';
  String get sendTip => isSwahili ? 'Tuma bahshishi' : 'Send tip';
  String get subscribeWallet => isSwahili ? 'Jiandikishe' : 'Subscribe';
  String get subscribeToCreator => isSwahili ? 'Jisajili kwa Mwandishi' : 'Subscribe to Creator';
  String get subscriptionTiers => isSwahili ? 'Ngazi za usajili' : 'Subscription tiers';
  String get transactionHistory => isSwahili ? 'Historia ya shughuli' : 'Transaction history';
  String get mobileAccounts => isSwahili ? 'Akaunti za simu' : 'Mobile money';
  String get payWithWallet => isSwahili ? 'Lipa kwa Pochi' : 'Pay with Wallet';
  String get confirmWithPin => isSwahili ? 'Thibitisha kwa PIN' : 'Confirm with PIN';
  String get pinFourDigits => isSwahili ? 'PIN (tarakimu 4)' : 'PIN (4 digits)';
  String get enterWalletPin => isSwahili ? 'Ingiza PIN ya pochi (tarakimu 4)' : 'Enter wallet PIN (4 digits)';
  String get chooseTierAndPay => isSwahili ? 'Chagua kiwango na lipa kwa pochi. Utafikia maudhui maalum.' : 'Choose a tier and pay with wallet. You will access exclusive content.';
  String get chooseTier => isSwahili ? 'Chagua kiwango cha usajili' : 'Choose subscription tier';
  String get insufficientBalance => isSwahili ? 'Salio la pochi halitoshi. Ingiza pesa kwanza.' : 'Insufficient wallet balance. Top up first.';
  String get balanceInsufficient => isSwahili ? 'Salio halitoshi' : 'Insufficient balance';
  String get subscriptionSuccess => isSwahili ? 'Umefanikiwa kujisajili' : 'Successfully subscribed';
  String subscriptionSuccessMessage(String creator) => isSwahili
      ? 'Umefanikiwa kujisajili. Sasa una ufikiaji wa maudhui maalum ya $creator.'
      : 'Successfully subscribed. You now have access to exclusive content from $creator.';
  String get subscriptionFailed => isSwahili ? 'Imeshindwa kujisajili' : 'Failed to subscribe';
  String get loadingTiersFailed => isSwahili ? 'Imeshindwa kupakia viwango' : 'Failed to load tiers';
  String get loadingFailed => isSwahili ? 'Imeshindwa kupakia' : 'Failed to load';
  String get alreadySubscribed => isSwahili ? 'Tayari umesajiliwa' : 'Already subscribed';
  String get alreadySubscribedMessage => isSwahili ? 'Una ufikiaji wa maudhui maalum ya mwandishi huyu.' : 'You have access to this creator\'s exclusive content.';
  String noTiersYet(String creator) => isSwahili
      ? '$creator hajaweka viwango vya usajili bado.'
      : '$creator hasn\'t set up subscription tiers yet.';
  String pricePerPeriod(String price, String period) => '$price $period';
  String get yearly => isSwahili ? 'mwaka' : 'yr';
  String get monthly => isSwahili ? 'mwezi' : 'mo';

  // ——— My Subscriptions ———
  String get mySubscriptions => isSwahili ? 'Usajili Wangu' : 'My Subscriptions';
  String get activeSubscriptions => isSwahili ? 'Zinazoendelea' : 'Active';
  String get expiredSubscriptions => isSwahili ? 'Zilizoisha' : 'Expired';
  String get allSubscriptions => isSwahili ? 'Zote' : 'All';
  String get renewsOn => isSwahili ? 'Inafanywa upya' : 'Renews on';
  String get expiresOn => isSwahili ? 'Inaisha' : 'Expires on';
  String get autoRenewal => isSwahili ? 'Upyaishwaji wa Kiotomatiki' : 'Auto-Renewal';
  String get autoRenewalOn => isSwahili ? 'Upyaishwaji umewashwa' : 'Auto-renewal enabled';
  String get autoRenewalOff => isSwahili ? 'Upyaishwaji umezimwa' : 'Auto-renewal disabled';
  String get daysRemaining => isSwahili ? 'siku zilizobaki' : 'days remaining';
  String daysRemainingCount(int days) => isSwahili ? 'Siku $days zilizobaki' : '$days days remaining';
  String get noSubscriptionsYet => isSwahili ? 'Hujajisajili kwa mwandishi yeyote' : 'You have no subscriptions yet';
  String get discoverCreators => isSwahili ? 'Gundua Waandishi' : 'Discover Creators';
  String get subscriptionDetails => isSwahili ? 'Maelezo ya Usajili' : 'Subscription Details';
  String get viewCreatorProfile => isSwahili ? 'Tazama Wasifu' : 'View Profile';
  String get startedOn => isSwahili ? 'Ilianza' : 'Started on';
  String get amountPaid => isSwahili ? 'Kiasi Kilicholipwa' : 'Amount Paid';
  String get cancelSubscription => isSwahili ? 'Sitisha Usajili' : 'Cancel Subscription';
  String get cancelSubscriptionConfirm => isSwahili
      ? 'Una uhakika unataka kusitisha usajili huu? Utapoteza ufikiaji wa maudhui maalum.'
      : 'Are you sure you want to cancel this subscription? You will lose access to exclusive content.';
  String get subscriptionCancelled => isSwahili ? 'Usajili umesitishwa' : 'Subscription cancelled';
  String get subscriptionCancelFailed => isSwahili ? 'Imeshindwa kusitisha usajili' : 'Failed to cancel subscription';
  String get tierBenefits => isSwahili ? 'Faida za Kiwango' : 'Tier Benefits';
  String get subscribedTo => isSwahili ? 'Umejisajili kwa' : 'Subscribed to';

  // ——— Creator Earnings ———
  String get earnings => isSwahili ? 'Mapato' : 'Earnings';
  String get contentEarnings => isSwahili ? 'Mapato ya Maudhui' : 'Content Earnings';
  String get totalEarnings => isSwahili ? 'Mapato Yote' : 'Total Earnings';
  String get netEarnings => isSwahili ? 'Mapato Halisi' : 'Net Earnings';
  String get thisMonth => isSwahili ? 'Mwezi Huu' : 'This Month';
  String get pendingEarnings => isSwahili ? 'Yanayosubiri' : 'Pending';
  String get recentEarnings => isSwahili ? 'Mapato ya Hivi Karibuni' : 'Recent Earnings';
  String get noEarningsYet => isSwahili ? 'Hakuna mapato bado' : 'No earnings yet';
  String get earningType => isSwahili ? 'Aina' : 'Type';
  String get earningSubscription => isSwahili ? 'Usajili' : 'Subscription';
  String get earningTip => isSwahili ? 'Bahshishi' : 'Tip';
  String get earningGift => isSwahili ? 'Zawadi' : 'Gift';
  String get platformFee => isSwahili ? 'Ada ya Jukwaa' : 'Platform Fee';
  String get grossAmount => isSwahili ? 'Kiasi Kamili' : 'Gross Amount';
  String get netAmount => isSwahili ? 'Kiasi Halisi' : 'Net Amount';

  // ——— Subscribers ———
  String get mySubscribers => isSwahili ? 'Wasajili Wangu' : 'My Subscribers';
  String get viewSubscribers => isSwahili ? 'Tazama Wasajili' : 'View Subscribers';
  String get allTiers => isSwahili ? 'Viwango Vyote' : 'All Tiers';
  String get subscribedOn => isSwahili ? 'Alijisajili' : 'Subscribed on';
  String get noSubscribersYet => isSwahili ? 'Hakuna wasajili bado' : 'No subscribers yet';
  String get subscriberCount => isSwahili ? 'Wasajili' : 'Subscribers';
  String subscriberCountNum(int count) => isSwahili ? 'Wasajili $count' : '$count Subscribers';

  // ——— Payouts ———
  String get requestPayout => isSwahili ? 'Omba Malipo' : 'Request Payout';
  String get payoutHistory => isSwahili ? 'Historia ya Malipo' : 'Payout History';
  String get viewPayouts => isSwahili ? 'Tazama Malipo' : 'View Payouts';
  String get payoutAmount => isSwahili ? 'Kiasi cha Malipo' : 'Payout Amount';
  String get availableForPayout => isSwahili ? 'Inapatikana kwa Malipo' : 'Available for Payout';
  String get minimumPayout => isSwahili ? 'Kiwango cha chini' : 'Minimum amount';
  String get selectProvider => isSwahili ? 'Chagua Mtoa Huduma' : 'Select Provider';
  String get accountName => isSwahili ? 'Jina la Akaunti' : 'Account Name';
  String get payoutRequested => isSwahili ? 'Ombi la malipo limetumwa' : 'Payout request submitted';
  String get payoutRequestFailed => isSwahili ? 'Imeshindwa kutuma ombi la malipo' : 'Failed to submit payout request';
  String get noPayoutsYet => isSwahili ? 'Hakuna malipo bado' : 'No payouts yet';
  String get payoutStatus => isSwahili ? 'Hali' : 'Status';
  String get payoutPending => isSwahili ? 'Inasubiri' : 'Pending';
  String get payoutProcessing => isSwahili ? 'Inashughulikiwa' : 'Processing';
  String get payoutCompleted => isSwahili ? 'Imekamilika' : 'Completed';
  String get payoutFailed => isSwahili ? 'Imeshindwa' : 'Failed';
  String get requestedOn => isSwahili ? 'Iliombwa' : 'Requested on';
  String get processedOn => isSwahili ? 'Ilishughulikiwa' : 'Processed on';
  String get failureReason => isSwahili ? 'Sababu ya Kushindwa' : 'Failure Reason';
  String get payoutRequestSubmitted => isSwahili ? 'Ombi limetumwa kikamilifu' : 'Payout request submitted successfully';
  String get selectPaymentProvider => isSwahili ? 'Chagua mtoa huduma wa malipo' : 'Select a payment provider';
  String get enterValidAmount => isSwahili ? 'Ingiza kiasi sahihi' : 'Enter a valid amount';
  String get amountExceedsBalance => isSwahili ? 'Kiasi kinazidi salio' : 'Amount exceeds available balance';
  String get availableBalance => isSwahili ? 'Salio Linalopatikana' : 'Available Balance';
  String get amount => isSwahili ? 'Kiasi' : 'Amount';
  String get enterAmount => isSwahili ? 'Ingiza kiasi' : 'Enter amount';
  String get paymentProvider => isSwahili ? 'Mtoa Huduma wa Malipo' : 'Payment Provider';
  String get enterPhoneNumber => isSwahili ? 'Ingiza namba ya simu' : 'Enter phone number';
  String get invalidPhoneNumber => isSwahili ? 'Namba ya simu si sahihi' : 'Invalid phone number';
  String get enterAccountName => isSwahili ? 'Ingiza jina la mmiliki wa akaunti' : 'Enter account holder name';
  String get submitRequest => isSwahili ? 'Tuma Ombi' : 'Submit Request';
  String get requestPayoutToSee => isSwahili ? 'Omba malipo ili kuona historia yako hapa' : 'Request a payout to see your history here';

  // ——— Additional Subscription Strings ———
  String get creatorEarnings => isSwahili ? 'Mapato ya Maudhui' : 'Creator Earnings';
  String get viewYourSubscriptions => isSwahili ? 'Angalia usajili wako kwa waundaji' : 'View your subscriptions to creators';
  String get viewYourEarnings => isSwahili ? 'Angalia mapato na wasajili wako' : 'View your earnings and subscribers';
  String get startCreatingContent => isSwahili ? 'Anza kuunda maudhui ili kupata mapato kutoka kwa wasajili wako' : 'Start creating content to earn from your subscribers';
  String get totalSubscribers => isSwahili ? 'Jumla' : 'Total';
  String get createContentToAttract => isSwahili ? 'Unda maudhui mazuri ili kuvutia wasajili' : 'Create great content to attract subscribers';
  String get subscription => isSwahili ? 'Usajili' : 'Subscription';
  String get tip => isSwahili ? 'Bahshishi' : 'Tip';
  String get gift => isSwahili ? 'Zawadi' : 'Gift';
  String get confirm => isSwahili ? 'Thibitisha' : 'Confirm';

  // ——— Campaigns (Michango) ———
  String get campaigns => isSwahili ? 'Michango' : 'Campaigns';
  String get donateToCampaign => isSwahili ? 'Changia kampeni' : 'Donate to campaign';
  String get campaignWithdraw => isSwahili ? 'Ondoa pesa za kampeni' : 'Withdraw campaign funds';
  String get createCampaignTitle => isSwahili ? 'Anzisha kampeni' : 'Create campaign';
  String get campaignUpdates => isSwahili ? 'Sasisho za kampeni' : 'Campaign updates';

  // ——— Groups, Events, Pages ———
  String get groups => isSwahili ? 'Vikundi' : 'Groups';
  // Note: createGroup defined above in Messages section
  String get groupDetail => isSwahili ? 'Taarifa za kikundi' : 'Group detail';
  String get createGroupPost => isSwahili ? 'Chapisho kwenye kikundi' : 'Create group post';
  String get events => isSwahili ? 'Matukio' : 'Events';
  String get createEvent => isSwahili ? 'Anzisha tukio' : 'Create event';
  String get eventDetail => isSwahili ? 'Taarifa za tukio' : 'Event detail';
  String get attendees => isSwahili ? 'Washiriki' : 'Attendees';
  String get pages => isSwahili ? 'Kurasa' : 'Pages';
  String get createPage => isSwahili ? 'Anzisha ukurasa' : 'Create page';
  String get pageDetail => isSwahili ? 'Taarifa za ukurasa' : 'Page detail';
  String get createPoll => isSwahili ? 'Tengeneza kura' : 'Create poll';
  String get polls => isSwahili ? 'Kura' : 'Polls';
  String get pollDetail => isSwahili ? 'Taarifa za kura' : 'Poll detail';
  String get vote => isSwahili ? 'Piga kura' : 'Vote';

  // ——— Search ———
  String get searchUsers => isSwahili ? 'Tafuta watumiaji' : 'Search users';
  String get searchGroups => isSwahili ? 'Tafuta vikundi' : 'Search groups';
  String get hashtags => isSwahili ? 'Vitambulisho' : 'Hashtags';
  String get hashtag => isSwahili ? 'Vitambulisho' : 'Hashtag';

  // ——— Live / Streaming ———
  String get backstage => isSwahili ? 'Jukwaa' : 'Backstage';
  /// Backstage screen title badge ("Nyuma ya pazia" / "Backstage")
  String get backstageBadge => isSwahili ? 'Nyuma ya pazia' : 'Backstage';
  String get standby => isSwahili ? 'Subiri' : 'Standby';
  // Backstage screen (preparation before going live)
  String get cameraReady => isSwahili ? 'Kamera Iko Tayari' : 'Camera ready';
  String get checkingCamera => isSwahili ? 'Inaangalia Kamera...' : 'Checking camera...';
  String get flipCamera => isSwahili ? 'Geuza' : 'Flip';
  String get turnOff => isSwahili ? 'Zima' : 'Off';
  String get turnOn => isSwahili ? 'Washa' : 'On';
  String get areYouReady => isSwahili ? 'Uko Tayari?' : 'Are you ready?';
  String get camera => isSwahili ? 'Kamera' : 'Camera';
  String get microphone => isSwahili ? 'Maikrofoni' : 'Microphone';
  String get network => isSwahili ? 'Mtandao' : 'Network';
  String get quality => isSwahili ? 'Ubora' : 'Quality';
  String get beautyMode => isSwahili ? 'Hali ya Urembo' : 'Beauty mode';
  String get publicLabel => isSwahili ? 'Wazi' : 'Public';
  String get recording => isSwahili ? 'Inarekodi' : 'Recording';
  String get waitForSystemsReady => isSwahili ? 'Subiri hadi mifumo yote iwe tayari...' : 'Wait for all systems to be ready...';
  String get goLiveButton => isSwahili ? 'Enda Moja kwa Moja' : 'Go live';
  String get waiting => isSwahili ? 'Inasubiri...' : 'Waiting...';
  String get startLive => isSwahili ? 'Anza live' : 'Start live';
  String get endLive => isSwahili ? 'Maliza live' : 'End live';
  String get viewers => isSwahili ? 'Watazamaji' : 'Viewers';
  String get liveBroadcast => isSwahili ? 'Tanga moja kwa moja' : 'Live broadcast';
  String get noViewers => isSwahili ? 'Hakuna watazamaji' : 'No viewers yet';
  // Me → Live tab (profile live gallery)
  String get liveBroadcasts => isSwahili ? 'Matangazo' : 'Broadcasts';
  String get liveEarnings => isSwahili ? 'Mapato' : 'Earnings';
  String get liveGifts => isSwahili ? 'Zawadi' : 'Gifts';
  String get youAreLiveNow => isSwahili ? 'Uko live sasa' : "You're live now";
  String get manage => isSwahili ? 'Dhibiti' : 'Manage';
  String get allTab => isSwahili ? 'Yote' : 'All';
  String get scheduledTab => isSwahili ? 'Yamepangwa' : 'Scheduled';
  String get recordingsTab => isSwahili ? 'Rekodi' : 'Recordings';
  String get startBroadcastingTooltip => isSwahili ? 'Anza kutangaza' : 'Start broadcasting';
  String get noBroadcasts => isSwahili ? 'Hakuna matangazo' : 'No broadcasts';
  String get noScheduledBroadcasts => isSwahili ? 'Hakuna matangazo yaliyopangwa' : 'No scheduled broadcasts';
  String get scheduleBroadcastHint => isSwahili ? 'Panga tangazo lako lijalo ili wafuasi wako wajue wakati wa kukutazama.' : 'Schedule your broadcast so followers know when to watch.';
  String get scheduleBroadcast => isSwahili ? 'Panga tangazo' : 'Schedule broadcast';
  String get noRecordings => isSwahili ? 'Hakuna rekodi' : 'No recordings';
  String get recordingsHint => isSwahili ? 'Matangazo yako yatahifadhiwa hapa ukiwasha chaguo la kurekodi.' : 'Your broadcasts will be saved here when you enable recording.';
  String get startFirstBroadcast => isSwahili ? 'Anza tangazo la kwanza' : 'Start first broadcast';
  String get recordingBadge => isSwahili ? 'REKODI' : 'RECORDING';
  String get analytics => isSwahili ? 'Takwimu' : 'Analytics';
  String get download => isSwahili ? 'Pakua' : 'Download';
  String get downloadRecording => isSwahili ? 'Pakua rekodi' : 'Download recording';
  String get deleteBroadcast => isSwahili ? 'Futa tangazo' : 'Delete broadcast';
  String deleteBroadcastConfirmMessage(String title) => isSwahili ? 'Una uhakika unataka kufuta "$title"?\n\nHatua hii haiwezi kutenduliwa.' : 'Are you sure you want to delete "$title"?\n\nThis cannot be undone.';
  String get yesDelete => isSwahili ? 'Ndiyo, futa' : 'Yes, delete';
  String get broadcastDeleted => isSwahili ? 'Tangazo limefutwa' : 'Broadcast deleted';
  String get totalViewers => isSwahili ? 'Watazamaji wote' : 'Total viewers';
  String get peakViewers => isSwahili ? 'Kilele' : 'Peak';
  String get liveUserInfoUnavailable => isSwahili ? 'Hitilafu: Taarifa za mtumiaji hazipatikani' : 'Error: User info unavailable';
  String get today => isSwahili ? 'Leo' : 'Today';
  String get tomorrow => isSwahili ? 'Kesho' : 'Tomorrow';
  String daysAgo(int n) => isSwahili ? 'Siku $n zilizopita' : '$n days ago';
  String get underAMinute => isSwahili ? 'Chini ya dakika' : 'Under a minute';
  String timeRemaining(String formatted) => isSwahili ? 'Inabaki: $formatted' : 'Time remaining: $formatted';
  String formatTimeUntilDaysHours(int d, int h) => isSwahili ? '$d siku $h saa' : '$d d $h hr';
  String formatTimeUntilHoursMins(int h, int m) => isSwahili ? '$h saa $m dak' : '$h hr $m min';
  String formatTimeUntilMins(int m) => isSwahili ? '$m dakika' : '$m min';
  String get liveDashboardComingSoon => isSwahili ? 'Dashibodi ya tangazo - Inakuja karibuni' : 'Stream dashboard - Coming soon';
  String get liveEditComingSoon => isSwahili ? 'Kuhariri tangazo - Inakuja karibuni' : 'Edit broadcast - Coming soon';
  String get liveDownloadComingSoon => isSwahili ? 'Kupakua rekodi - Inakuja karibuni' : 'Download recording - Coming soon';
  String get liveShareComingSoon => isSwahili ? 'Kushiriki - Inakuja karibuni' : 'Share - Coming soon';
  String failedToStartStream(String? msg) => isSwahili ? 'Imeshindwa kuanza: ${msg ?? "Kosa"}' : 'Failed to start: ${msg ?? "Error"}';
  // Streams screen (browse live, FAB "Enda Moja kwa Moja")
  String get liveBroadcastsTitle => isSwahili ? 'Matangazo ya Moja kwa Moja' : 'Live broadcasts';
  String get liveNow => isSwahili ? 'Moja kwa Moja Sasa' : 'Live now';
  String get noLiveBroadcastsMessage => isSwahili ? 'Hakuna matangazo ya moja kwa moja' : 'No live broadcasts';
  String get startBroadcast => isSwahili ? 'Anza Tangazo' : 'Start broadcast';
  String get scheduleShort => isSwahili ? 'Panga' : 'Schedule';
  String get streamStatusLive => isSwahili ? 'Moja kwa Moja' : 'Live';
  String get streamStatusScheduled => isSwahili ? 'Imepangwa' : 'Scheduled';
  String get liveStreamsEmptyHint => isSwahili ? 'Wafuasi wako hawajatangaza tangazo la moja kwa moja bado.' : 'Your followers are not live yet.';

  // ——— Go Live screen (full page) ———
  String get goLiveWhen => isSwahili ? 'Unataka kutangaza lini?' : 'When do you want to go live?';
  String get now => isSwahili ? 'Sasa' : 'Now';
  String get goLiveNowDescription => isSwahili ? 'Enda moja kwa moja' : 'Go live now';
  String get scheduleFollowersNotify => isSwahili ? 'Wafuasi watapata tangazo' : 'Followers will get a notification';
  String get broadcastTime => isSwahili ? 'Wakati wa kutangaza' : 'Broadcast time';
  String get tapToChooseDateTime => isSwahili ? 'Bofya kuchagua tarehe na saa' : 'Tap to choose date and time';
  String get addCoverImage => isSwahili ? 'Ongeza picha ya jalada' : 'Add cover image';
  String get broadcastTitle => isSwahili ? 'Kichwa cha Tangazo' : 'Broadcast title';
  String get enterTitleHint => isSwahili ? 'Andika kichwa...' : 'Enter title...';
  String get description => isSwahili ? 'Maelezo' : 'Description';
  String get showMore => isSwahili ? 'Onyesha zaidi' : 'Show more';
  String get showLess => isSwahili ? 'Onyesha kidogo' : 'Show less';
  String get linkCopied => isSwahili ? 'Kiungo kimenakiliwa' : 'Link copied to clipboard';
  String get writeReview => isSwahili ? 'Andika tathmini' : 'Write a review';
  String get yourRating => isSwahili ? 'Kiwango chako' : 'Your rating';
  String get reviewHint => isSwahili ? 'Shiriki uzoefu wako...' : 'Share your experience...';
  String get submitReview => isSwahili ? 'Tuma tathmini' : 'Submit review';
  String get reviewSubmitted => isSwahili ? 'Tathmini imetumwa' : 'Review submitted';
  String get tapToRate => isSwahili ? 'Gusa kutathimini' : 'Tap to rate';
  String get shareProduct => isSwahili ? 'Shiriki bidhaa' : 'Share product';
  String get shareVia => isSwahili ? 'Shiriki kupitia...' : 'Share via...';
  String get shareToApps => isSwahili ? 'Shiriki kwa programu' : 'Share to apps';
  String get sendToFriend => isSwahili ? 'Tuma kwa rafiki' : 'Send to a friend';
  String get copyLink => isSwahili ? 'Nakili kiungo' : 'Copy link';
  String get repost => isSwahili ? 'Chapisha tena' : 'Repost';
  String get broadcastDescriptionHint => isSwahili ? 'Maelezo ya tangazo...' : 'Broadcast description...';
  String get tagLabel => isSwahili ? 'Lebo' : 'Tag';
  String get addTagHint => isSwahili ? 'Ongeza lebo' : 'Add tag';
  String get recordBroadcast => isSwahili ? 'Rekodi Tangazo' : 'Record broadcast';
  String get recordBroadcastSubtitle => isSwahili ? 'Hifadhi tangazo kwa baadaye' : 'Save broadcast for later';
  String get allowComments => isSwahili ? 'Ruhusu Maoni' : 'Allow comments';
  String get allowGifts => isSwahili ? 'Ruhusu Zawadi' : 'Allow gifts';
  String get allowGiftsSubtitle => isSwahili ? 'Watazamaji wanaweza kutuma zawadi' : 'Viewers can send gifts';
  String get privacyFollowersOnly => isSwahili ? 'Wafuasi pekee' : 'Followers only';
  String get privacyOnlyYou => isSwahili ? 'Wewe pekee' : 'Only you';
  String get everyoneCanWatch => isSwahili ? 'Wote wanaweza kutazama' : 'Everyone can watch';
  String get onlyYourFollowers => isSwahili ? 'Wafuasi wako tu' : 'Only your followers';
  String get pleaseEnterTitle => isSwahili ? 'Tafadhali andika kichwa' : 'Please enter a title';
  String get pleaseSelectBroadcastTime => isSwahili ? 'Tafadhali chagua wakati wa kutangaza' : 'Please select broadcast time';
  String get broadcastScheduled => isSwahili ? 'Tangazo Limepangwa!' : 'Broadcast scheduled!';
  String broadcastScheduledMessage(String title) => isSwahili ? 'Tangazo lako "$title" limepangwa kikamilifu.' : 'Your broadcast "$title" has been scheduled.';
  String get followersWillGetNotification => isSwahili ? 'Wafuasi wako watapata tangazo:' : 'Your followers will get a notification:';
  String get stepBroadcastOnLiveTab => isSwahili ? 'Tangazo litaonekana kwenye Live tab' : 'Broadcast will appear on Live tab';
  String get stepViewersSeeCountdown => isSwahili ? 'Watazamaji wataona countdown' : 'Viewers will see countdown';
  String get stepNotificationBeforeTime => isSwahili ? 'Utapata notification kabla ya wakati' : "You'll get a notification before the time";
  String get toStartBroadcasting => isSwahili ? 'Kuanza kutangaza:' : 'To start broadcasting:';
  String get stepGoToProfileLiveScheduled => isSwahili ? 'Nenda kwenye Wasifu > Live > Iliyopangwa' : 'Go to Profile > Live > Scheduled';
  String get stepTapYourBroadcast => isSwahili ? 'Bofya tangazo lako' : 'Tap your broadcast';
  String get stepTapStartNowWhenReady => isSwahili ? 'Bofya "Anza Sasa" unapokuwa tayari' : 'Tap "Start now" when ready';
  String get broadcastAlreadyLive => isSwahili ? 'Tangazo tayari liko Live!' : 'Broadcast is already live!';
  String get youAreAlreadyLive => isSwahili ? 'Tayari Uko Live!' : "You're already live!";
  String get broadcastAlreadyLiveMessage => isSwahili ? 'Tangazo lako tayari liko Live. Huwezi kulianza tena.' : 'Your broadcast is already live. You cannot start it again.';
  String get waitAMoment => isSwahili ? 'Subiri Kidogo' : 'Wait a moment';
  String get broadcastReadyBackendPreparing => isSwahili ? 'Tangazo lako lipo tayari, lakini backend inahitaji kuandaliwa kwa kutangaza moja kwa moja.' : 'Your broadcast is ready, but the backend is still preparing for live streaming.';
  String get goToProfileLiveScheduledTapStart => isSwahili ? 'Kwa sasa, nenda kwenye Wasifu > Live > Iliyopangwa na ubofye "Anza Sasa".' : 'For now, go to Profile > Live > Scheduled and tap "Start now".';
  String get failedToCreateBroadcast => isSwahili ? 'Imeshindwa kuunda tangazo' : 'Failed to create broadcast';
  /// Category label for Go Live dropdown. [id] one of: music, sports, education, talk, entertainment, business, technology, other
  String goLiveCategory(String id) {
    switch (id) {
      case 'music': return isSwahili ? 'Muziki' : 'Music';
      case 'sports': return isSwahili ? 'Michezo' : 'Sports';
      case 'education': return isSwahili ? 'Elimu' : 'Education';
      case 'talk': return isSwahili ? 'Mazungumzo' : 'Talk';
      case 'entertainment': return isSwahili ? 'Burudani' : 'Entertainment';
      case 'business': return isSwahili ? 'Biashara' : 'Business';
      case 'technology': return isSwahili ? 'Teknolojia' : 'Technology';
      case 'other': return isSwahili ? 'Nyingine' : 'Other';
      default: return id;
    }
  }
  /// Short month name for date formatting (1-based index). Go Live schedule display.
  String goLiveMonthShort(int month) {
    if (month < 1 || month > 12) return '';
    const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const sw = ['Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'];
    return isSwahili ? sw[month - 1] : en[month - 1];
  }

  // ——— Calls ———
  String get incomingCall => isSwahili ? 'Simu inayoingia' : 'Incoming call';
  String get outgoingCall => isSwahili ? 'Simu inayotoka' : 'Outgoing call';
  String get endCall => isSwahili ? 'Maliza simu' : 'End call';
  String get answer => isSwahili ? 'Jibu' : 'Answer';
  String get declineCall => isSwahili ? 'Kataa' : 'Decline';

  // ——— Privacy ———
  String get privacySettings => isSwahili ? 'Mipangilio ya faragha' : 'Privacy settings';
  String get whoCanSeePrivacy => isSwahili ? 'Nani anaweza kuona' : 'Who can see';
  String get blocked => isSwahili ? 'Wazuiwa' : 'Blocked';
  String get blockedUsers => isSwahili ? 'Watumiaji waliozuiliwa' : 'Blocked users';
  String get privacySaved => isSwahili ? 'Mipangilio ya faragha imehifadhiwa' : 'Privacy settings saved';
  String get privacySectionProfile => isSwahili ? 'Uonekano wa Wasifu' : 'Profile visibility';
  String get privacySectionMessages => isSwahili ? 'Ujumbe' : 'Messages';
  String get privacySectionPosts => isSwahili ? 'Machapisho' : 'Posts';
  String get privacySectionLastSeen => isSwahili ? 'Alionekana Mwisho' : 'Last seen';
  String get privacyWhoCanSeeProfile => isSwahili ? 'Nani anaweza kuona wasifu' : 'Who can see your profile';
  String get privacyWhoCanMessage => isSwahili ? 'Nani anaweza kukutumia ujumbe' : 'Who can message you';
  String get privacyWhoCanSeePosts => isSwahili ? 'Nani anaweza kuona machapisho' : 'Who can see your posts';
  String get privacyShowLastSeen => isSwahili ? 'Onyesha "alionekana mwisho"' : 'Show "last seen"';
  String get privacyPickerProfileTitle => isSwahili ? 'Nani anaweza kuona wasifu wako?' : 'Who can see your profile?';
  String get privacyPickerMessageTitle => isSwahili ? 'Nani anaweza kukutumia ujumbe?' : 'Who can message you?';
  String get privacyPickerPostsTitle => isSwahili ? 'Nani anaweza kuona machapisho yako?' : 'Who can see your posts?';
  String get privacyPickerLastSeenTitle => isSwahili ? 'Onyesha "Alionekana mwisho" kwa nani?' : 'Show "last seen" to whom?';
  String get privacyEveryone => isSwahili ? 'Kila mtu' : 'Everyone';
  String get privacyFriendsOnly => isSwahili ? 'Marafiki tu' : 'Friends only';
  String get privacyOnlyMe => isSwahili ? 'Mimi tu' : 'Only me';
  String get privacyNobody => isSwahili ? 'Hakuna mtu' : 'Nobody';
  String get privacyLastSeenDontShow => isSwahili ? 'Usionyeshe' : "Don't show";
  String get privacyProfileSubEveryone => isSwahili ? 'Wasifu wako unaonekana kwa wote' : 'Your profile is visible to everyone';
  String get privacyProfileSubFriends => isSwahili ? 'Wasifu unaonekana kwa marafiki tu' : 'Profile visible to friends only';
  String get privacyProfileSubOnlyMe => isSwahili ? 'Wasifu haunaonekana kwa mtu yeyote' : 'Profile hidden from everyone';
  String get privacyMessageSubEveryone => isSwahili ? 'Wote wanaweza kukutumia ujumbe' : 'Anyone can message you';
  String get privacyMessageSubFriends => isSwahili ? 'Marafiki tu wanaweza kukutumia ujumbe' : 'Only friends can message you';
  String get privacyMessageSubNobody => isSwahili ? 'Hakuna mtu anaweza kukutumia ujumbe' : 'Nobody can message you';
  String get privacyPostsSubEveryone => isSwahili ? 'Machapisho yanaonekana kwa wote' : 'Posts visible to everyone';
  String get privacyPostsSubFriends => isSwahili ? 'Machapisho yanaonekana kwa marafiki tu' : 'Posts visible to friends only';
  String get privacyPostsSubOnlyMe => isSwahili ? 'Machapisho hayaonekani kwa mtu yeyote' : 'Posts hidden from everyone';
  String get privacyLastSeenSubEveryone => isSwahili ? 'Wote wanaweza kuona ulionekana lini' : 'Everyone can see when you were last seen';
  String get privacyLastSeenSubFriends => isSwahili ? 'Marafiki tu wanaweza kuona' : 'Only friends can see';
  String get privacyLastSeenSubDontShow => isSwahili ? 'Usionyeshe "alionekana mwisho" kwa mtu yeyote' : "Don't show last seen to anyone";

  // ——— Post Privacy (Subscribers Only) ———
  String get privacySubscribersOnly => isSwahili ? 'Wasajili Pekee' : 'Subscribers Only';
  String get privacySubscribersOnlyDesc => isSwahili ? 'Wasajili wako tu wanaweza kuona' : 'Only your subscribers can see';
  String get whoCanSeeThis => isSwahili ? 'Nani anaweza kuona hii?' : 'Who can see this?';
  String get whoCanSeeThisPost => isSwahili ? 'Nani anaweza kuona chapisho hili?' : 'Who can see this post?';
  String get privacyPublic => isSwahili ? 'Kila mtu' : 'Public';
  String get privacyPublicDesc => isSwahili ? 'Kila mtu anaweza kuona' : 'Everyone can see';
  String get privacyFriends => isSwahili ? 'Marafiki' : 'Friends';
  String get privacyFriendsDesc => isSwahili ? 'Marafiki tu wanaweza kuona' : 'Only friends can see';
  String get privacyPrivate => isSwahili ? 'Binafsi' : 'Private';
  String get privacyPrivateDesc => isSwahili ? 'Wewe tu unaweza kuona' : 'Only you can see';

  String get saveSettings => isSwahili ? 'Hifadhi Mipangilio' : 'Save settings';
  String get savingSettings => isSwahili ? 'Inahifadhi...' : 'Saving...';
  String get failedToLoadSettings => isSwahili ? 'Imeshindwa kupakia mipangilio' : 'Failed to load settings';

  // ——— Username ———
  String get usernameSettings => isSwahili ? 'Jina la mtumiaji' : 'Username';
  String get setUsername => isSwahili ? 'Weka jina la mtumiaji' : 'Set username';
  String get usernameHint => isSwahili ? '@jina_lako' : '@yourname';
  String get usernameDescription => isSwahili ? 'Jina lako la mtumiaji (@handle) litaonekana kwenye wasifu na machapisho.' : 'Your username (@handle) will appear on your profile and posts.';
  String get usernameRequired => isSwahili ? 'Weka jina la mtumiaji' : 'Enter a username';
  String usernameMinLength(int n) => isSwahili ? 'Jina lazima liwe angalau $n herufi' : 'Username must be at least $n characters';
  String usernameMaxLength(int n) => isSwahili ? 'Jina si zaidi ya $n herufi' : 'Username must be at most $n characters';
  String get usernameInvalidChars => isSwahili ? 'Tumia herufi, nambari na alama ya chini (_) tu' : 'Use only letters, numbers and underscore (_)';
  String get usernameNoChange => isSwahili ? 'Jina halijabadilika' : 'Username unchanged';
  String get usernameSaved => isSwahili ? 'Jina limehifadhiwa' : 'Username saved';
  String usernameSavedAs(String handle) => isSwahili ? 'Jina limehifadhiwa: @$handle' : 'Username saved: @$handle';
  String get usernameSaveFailed => isSwahili ? 'Imeshindwa kuhifadhi jina' : 'Failed to save username';

  // ——— Profile tabs settings ———
  String get profileTabsTitle => isSwahili ? 'Tabo za Wasifu' : 'Profile tabs';
  String get resetSettings => isSwahili ? 'Rejesha Mipangilio' : 'Reset settings';
  String get resetSettingsConfirmTitle => isSwahili ? 'Rejesha Mipangilio' : 'Reset settings';
  String get resetSettingsConfirmMessage => isSwahili ? 'Mipangilio yote ya tabo itarejeshwa kuwa ya awali. Endelea?' : 'All tab settings will be reset to default. Continue?';
  String get settingsSaved => isSwahili ? 'Mipangilio imehifadhiwa' : 'Settings saved';
  String get settingsReset => isSwahili ? 'Mipangilio imerejeshwa' : 'Settings reset';
  String get settingsSaveFailed => isSwahili ? 'Imeshindwa kuhifadhi. Jaribu tena.' : 'Failed to save. Try again.';
  String get saveChanges => isSwahili ? 'Hifadhi Mabadiliko' : 'Save changes';
  String get atLeastOneTab => isSwahili ? 'Lazima kuwe na angalau tabo moja iliyowashwa' : 'At least one tab must be enabled';
  String get profileTabsInstructions => isSwahili ? 'Buruta ili kubadilisha mpangilio. Gusa swichi kuwasha au kuzima tabo.' : 'Drag to reorder. Toggle switch to show or hide tabs.';
  String tabsEnabledCount(int on, int total) => isSwahili ? 'Tabo zilizowashwa: $on/$total' : 'Tabs enabled: $on/$total';
  String get dragToReorder => isSwahili ? 'Buruta kubadilisha mpangilio' : 'Drag to reorder';
  String get tabVisible => isSwahili ? 'Inaonekana' : 'Visible';
  String get tabHidden => isSwahili ? 'Imefichwa' : 'Hidden';
  String get savingEllipsis => isSwahili ? 'Inahifadhiwa...' : 'Saving...';

  // ——— Location / Registration steps ———
  String get selectRegion => isSwahili ? 'Chagua mkoa' : 'Select region';
  String get selectDistrict => isSwahili ? 'Chagua wilaya' : 'Select district';
  String get selectWard => isSwahili ? 'Chagua kata' : 'Select ward';
  String get selectStreet => isSwahili ? 'Chagua mtaa' : 'Select street';
  String get selectSchool => isSwahili ? 'Chagua shule' : 'Select school';
  String get searchSchool => isSwahili ? 'Tafuta shule' : 'Search school';
  String get noSchoolSelected => isSwahili ? 'Hakuna shule iliyochaguliwa' : 'No school selected';
  String get employer => isSwahili ? 'Mwajiri' : 'Employer';
  String get employerName => isSwahili ? 'Jina la mwajiri' : 'Employer name';
  String get unemployed => isSwahili ? 'Sina kazi' : 'Unemployed';
  String get student => isSwahili ? 'Mwanafunzi' : 'Student';

  // ——— Shop / Marketplace ———
  String get shop => isSwahili ? 'Duka' : 'Shop';
  String get marketplace => isSwahili ? 'Soko' : 'Marketplace';
  String get searchProducts => isSwahili ? 'Tafuta bidhaa...' : 'Search products...';
  String get featured => isSwahili ? 'Zilizoangaziwa' : 'Featured';
  String get trending => isSwahili ? 'Zinazovuma' : 'Trending';
  String get forYou => isSwahili ? 'Kwa Ajili Yako' : 'For You';
  String get allProducts => isSwahili ? 'Bidhaa Zote' : 'All Products';
  String get noProducts => isSwahili ? 'Hakuna bidhaa' : 'No products';
  String get noCategoryProducts => isSwahili ? 'Hakuna bidhaa katika kategoria hii' : 'No products in this category';
  String get productsWillAppear => isSwahili ? 'Bidhaa zitaonekana hapa' : 'Products will appear here';
  String get product => isSwahili ? 'Bidhaa' : 'Product';

  // Product types
  String get productTypePhysical => isSwahili ? 'Bidhaa' : 'Physical';
  String get productTypeDigital => isSwahili ? 'Dijitali' : 'Digital';
  String get productTypeService => isSwahili ? 'Huduma' : 'Service';

  // Product conditions
  String get conditionNew => isSwahili ? 'Mpya' : 'New';
  String get conditionUsed => isSwahili ? 'Imetumika' : 'Used';
  String get conditionRefurbished => isSwahili ? 'Imefanyiwa Ukarabati' : 'Refurbished';

  // Product status
  String get statusDraft => isSwahili ? 'Rasimu' : 'Draft';
  String get statusActive => isSwahili ? 'Inauzwa' : 'Active';
  String get statusSoldOut => isSwahili ? 'Imeisha' : 'Sold Out';
  String get statusArchived => isSwahili ? 'Imehifadhiwa' : 'Archived';
  String get outOfStock => isSwahili ? 'Imeisha' : 'Out of Stock';
  String get inStock => isSwahili ? 'Ipo' : 'In Stock';

  // Product details
  String get productDetails => isSwahili ? 'Maelezo ya Bidhaa' : 'Product Details';
  String get quantity => isSwahili ? 'Idadi' : 'Quantity';
  String get sold => isSwahili ? 'imeuzwa' : 'sold';
  String get reviews => isSwahili ? 'Maoni' : 'Reviews';
  String reviewsCount(int count) => isSwahili ? '$count maoni' : '$count reviews';
  String get noReviewsYet => isSwahili ? 'Hakuna maoni bado' : 'No reviews yet';
  String get customerReviews => isSwahili ? 'Maoni ya Wateja' : 'Customer Reviews';
  String get relatedProducts => isSwahili ? 'Bidhaa Zinazofanana' : 'Related Products';
  String get viewShop => isSwahili ? 'Tazama Ukurasa' : 'View Page';
  String get seller => isSwahili ? 'Muuzaji' : 'Seller';
  String get sales => isSwahili ? 'mauzo' : 'sales';
  String get helpful => isSwahili ? 'Inasaidia' : 'Helpful';
  String helpfulCount(int count) => isSwahili ? 'Inasaidia ($count)' : 'Helpful ($count)';
  String get verifiedPurchase => isSwahili ? 'Ununuzi Uliothibitishwa' : 'Verified Purchase';

  // Delivery
  String get deliveryOptions => isSwahili ? 'Njia ya Kupata' : 'Delivery Options';
  String get pickup => isSwahili ? 'Kuchukua Mwenyewe' : 'Pickup';
  String get delivery => isSwahili ? 'Kupelekewa' : 'Delivery';
  String get shipping => isSwahili ? 'Kusafirishwa' : 'Shipping';
  String get digitalDownload => isSwahili ? 'Pakua Moja kwa Moja' : 'Digital Download';
  String get sellerLocation => isSwahili ? 'Mahali pa muuzaji' : "Seller's location";
  String get withinCity => isSwahili ? 'Ndani ya mji' : 'Within city';
  String get nationwide => isSwahili ? 'Nchi nzima' : 'Nationwide';
  String get free => isSwahili ? 'Bure' : 'Free';
  String get deliveryAddress => isSwahili ? 'Anwani ya Kupelekewa' : 'Delivery Address';
  String get enterFullAddress => isSwahili ? 'Weka anwani yako kamili...' : 'Enter your full address...';
  String get notesOptional => isSwahili ? 'Maelekezo (Hiari)' : 'Notes (Optional)';
  String get specialInstructions => isSwahili ? 'Maelekezo maalum kwa muuzaji...' : 'Special instructions for seller...';
  String get pleaseEnterAddress => isSwahili ? 'Tafadhali weka anwani ya kupelekewa' : 'Please enter delivery address';

  // Cart
  String get cart => isSwahili ? 'Kikapu' : 'Cart';
  String get myCart => isSwahili ? 'Kikapu Changu' : 'My Cart';
  String get addToCart => isSwahili ? 'Ongeza' : 'Add to Cart';
  String get addedToCart => isSwahili ? 'Imeongezwa kwenye kikapu' : 'Added to cart';
  String get viewCart => isSwahili ? 'Tazama' : 'View';
  String get emptyCart => isSwahili ? 'Kikapu Chako ni Tupu' : 'Your Cart is Empty';
  String get emptyCartSubtitle => isSwahili ? 'Ongeza bidhaa kwenye kikapu kuendelea' : 'Add products to cart to continue';
  String get continueShopping => isSwahili ? 'Endelea Kununua' : 'Continue Shopping';
  String get clearAll => isSwahili ? 'Futa Zote' : 'Clear All';
  String get clearCart => isSwahili ? 'Futa Kikapu' : 'Clear Cart';
  String get clearCartConfirm => isSwahili ? 'Una uhakika unataka kufuta bidhaa zote?' : 'Are you sure you want to clear all items?';
  String get itemRemoved => isSwahili ? 'Bidhaa imeondolewa' : 'Item removed';
  String get cartCleared => isSwahili ? 'Kikapu kimefutwa' : 'Cart cleared';

  // Pricing
  String get subtotal => isSwahili ? 'Jumla ndogo' : 'Subtotal';
  String get deliveryFee => isSwahili ? 'Usafirishaji' : 'Delivery Fee';
  String get total => isSwahili ? 'Jumla' : 'Total';
  String get toBeCalculated => isSwahili ? 'Itahesabiwa' : 'To be calculated';

  // Checkout
  String get checkout => isSwahili ? 'Malipo' : 'Checkout';
  String get proceedToCheckout => isSwahili ? 'Endelea na Malipo' : 'Proceed to Checkout';
  String get orderSummary => isSwahili ? 'Muhtasari wa Oda' : 'Order Summary';
  String get paymentMethod => isSwahili ? 'Njia ya Malipo' : 'Payment Method';
  String get tajiriWallet => isSwahili ? 'TAJIRI Wallet' : 'TAJIRI Wallet';
  String get fastAndSecure => isSwahili ? 'Malipo ya haraka na salama' : 'Fast and secure payment';
  String get enterPin => isSwahili ? 'Weka PIN ya TAJIRI Wallet' : 'Enter TAJIRI Wallet PIN';
  String get enter4DigitPin => isSwahili ? 'Tafadhali weka PIN ya tarakimu 4' : 'Please enter 4-digit PIN';
  String get confirmPayment => isSwahili ? 'Thibitisha Malipo' : 'Confirm Payment';
  String payAmount(String amount) => isSwahili ? 'Lipa $amount' : 'Pay $amount';
  String get buyNow => isSwahili ? 'Nunua Sasa' : 'Buy Now';

  // Order
  String get order => isSwahili ? 'Oda' : 'Order';
  String get orders => isSwahili ? 'Oda' : 'Orders';
  String get myOrders => isSwahili ? 'Oda Zangu' : 'My Orders';
  String orderNumber(String number) => isSwahili ? 'Oda #$number' : 'Order #$number';
  String get paymentSuccess => isSwahili ? 'Malipo Yamefanikiwa!' : 'Payment Successful!';
  String get paymentFailed => isSwahili ? 'Malipo yameshindikana' : 'Payment failed';
  String get sellerWillContact => isSwahili ? 'Muuzaji atawasiliana nawe kuhusu usafirishaji.' : 'Seller will contact you about delivery.';
  String get viewOrder => isSwahili ? 'Tazama Oda' : 'View Order';
  String get buyer => isSwahili ? 'Mnunuzi' : 'Buyer';

  // Order status
  String get orderStatusPending => isSwahili ? 'Inasubiri' : 'Pending';
  String get orderStatusConfirmed => isSwahili ? 'Imethibitishwa' : 'Confirmed';
  String get orderStatusProcessing => isSwahili ? 'Inashughulikiwa' : 'Processing';
  String get orderStatusShipped => isSwahili ? 'Imetumwa' : 'Shipped';
  String get orderStatusDelivered => isSwahili ? 'Imepokelewa' : 'Delivered';
  String get orderStatusCompleted => isSwahili ? 'Imekamilika' : 'Completed';
  String get orderStatusCancelled => isSwahili ? 'Imeghairiwa' : 'Cancelled';
  String get orderStatusRefunded => isSwahili ? 'Imerudishiwa' : 'Refunded';

  // Order management
  String get noOrders => isSwahili ? 'Hakuna oda bado' : 'No orders yet';
  String get noOrdersMessage => isSwahili ? 'Oda mpya zitaonekana hapa' : 'New orders will appear here';
  String get orderDetails => isSwahili ? 'Maelezo ya Oda' : 'Order Details';
  String get confirmOrder => isSwahili ? 'Thibitisha Oda' : 'Confirm Order';
  String get confirmOrderMessage => isSwahili ? 'Thibitisha oda hii na kuanza kuishughulikia?' : 'Confirm this order and start processing?';
  String get markAsShipped => isSwahili ? 'Tuma Oda' : 'Mark as Shipped';
  String get trackingNumber => isSwahili ? 'Nambari ya Ufuatiliaji' : 'Tracking Number';
  String get trackingNumberHint => isSwahili ? 'Ingiza nambari ya ufuatiliaji (hiari)' : 'Enter tracking number (optional)';
  String get cancelOrder => isSwahili ? 'Ghairi Oda' : 'Cancel Order';
  String get cancelOrderMessage => isSwahili ? 'Una uhakika unataka kughairi oda hii?' : 'Are you sure you want to cancel this order?';
  String get cancelReason => isSwahili ? 'Sababu ya kughairi' : 'Reason for cancellation';
  String get orderConfirmed => isSwahili ? 'Oda imethibitishwa' : 'Order confirmed';
  String get orderShipped => isSwahili ? 'Oda imetumwa' : 'Order shipped';
  String get orderCancelled => isSwahili ? 'Oda imeghairiwa' : 'Order cancelled';
  String get orderReceived => isSwahili ? 'Oda imepokelewa' : 'Order received';
  String get confirmReceived => isSwahili ? 'Thibitisha Upokeaji' : 'Confirm Received';
  String get confirmReceivedMessage => isSwahili ? 'Thibitisha umepokea oda hii?' : 'Confirm you have received this order?';
  String get estimatedDelivery => isSwahili ? 'Tarehe ya Kupokea' : 'Estimated Delivery';
  String get statusHistory => isSwahili ? 'Historia ya Hali' : 'Status History';
  String get contactBuyer => isSwahili ? 'Wasiliana na Mnunuzi' : 'Contact Buyer';
  String get contactSeller => isSwahili ? 'Wasiliana na Muuzaji' : 'Contact Seller';
  String get failedToLoadOrders => isSwahili ? 'Imeshindwa kupakia oda' : 'Failed to load orders';
  String get failedToUpdateOrder => isSwahili ? 'Imeshindwa kusasisha oda' : 'Failed to update order';
  String get activeOrders => isSwahili ? 'Oda Zinazoendelea' : 'Active';
  String get completedOrders => isSwahili ? 'Oda Zilizokamilika' : 'Completed';
  // Filters
  String get filter => isSwahili ? 'Chuja' : 'Filter';
  String get filterAndSort => isSwahili ? 'Chuja & Panga' : 'Filter & Sort';
  String get sortBy => isSwahili ? 'Panga kwa' : 'Sort by';
  String get newest => isSwahili ? 'Mpya' : 'Newest';
  String get popular => isSwahili ? 'Maarufu' : 'Popular';
  String get priceLowToHigh => isSwahili ? 'Bei: Chini' : 'Price: Low';
  String get priceHighToLow => isSwahili ? 'Bei: Juu' : 'Price: High';
  String get productType => isSwahili ? 'Aina ya Bidhaa' : 'Product Type';
  String get condition => isSwahili ? 'Hali' : 'Condition';
  String get priceRange => isSwahili ? 'Bei (TZS)' : 'Price (TZS)';
  String get minPrice => isSwahili ? 'Chini' : 'Min';
  String get maxPrice => isSwahili ? 'Juu' : 'Max';
  String get applyFilters => isSwahili ? 'Tumia Vichujio' : 'Apply Filters';
  String get clearFilters => isSwahili ? 'Futa Vyote' : 'Clear All';
  String get all => isSwahili ? 'Zote' : 'All';

  // Misc shop
  String get goBack => isSwahili ? 'Rudi Nyuma' : 'Go Back';
  String get tryAgain => isSwahili ? 'Jaribu Tena' : 'Try Again';
  String get errorOccurred => isSwahili ? 'Kosa limetokea' : 'An error occurred';
  String get productNotFound => isSwahili ? 'Bidhaa haipatikani' : 'Product not found';
  String get failedToAdd => isSwahili ? 'Imeshindwa kuongeza' : 'Failed to add';
  String monthsAgo(int n) => isSwahili ? 'Miezi $n iliyopita' : '$n months ago';

  // Cart
  String get productRemoved => isSwahili ? 'Bidhaa imeondolewa' : 'Product removed';
  String get clearCartConfirmation => isSwahili ? 'Una uhakika unataka kuondoa bidhaa zote?' : 'Are you sure you want to remove all items?';
  String get yesClear => isSwahili ? 'Ndiyo, Ondoa' : 'Yes, Clear';
  String get yourCartIsEmpty => isSwahili ? 'Kikapu Chako Kipo Tupu' : 'Your Cart is Empty';
  String get addProductsToCart => isSwahili ? 'Ongeza bidhaa kwenye kikapu kuendelea' : 'Add products to cart to continue';
  String get proceedToPayment => isSwahili ? 'Endelea Kulipa' : 'Proceed to Payment';

  // Category/Sort/Filter
  String get sortNewest => isSwahili ? 'Mpya Zaidi' : 'Newest';
  String get sortPopular => isSwahili ? 'Maarufu' : 'Popular';
  String get sortPriceLow => isSwahili ? 'Bei: Chini - Juu' : 'Price: Low - High';
  String get sortPriceHigh => isSwahili ? 'Bei: Juu - Chini' : 'Price: High - Low';
  String get price => isSwahili ? 'Bei' : 'Price';
  String get min => isSwahili ? 'Ndogo' : 'Min';
  String get max => isSwahili ? 'Kubwa' : 'Max';

  // Checkout
  String get paymentSuccessful => isSwahili ? 'Malipo Yamefanikiwa!' : 'Payment Successful!';
  String get viewOrders => isSwahili ? 'Tazama Maagizo' : 'View Orders';
  String get instructionsOptional => isSwahili ? 'Maelekezo (Hiari)' : 'Instructions (Optional)';
  String get specialInstructionsHint => isSwahili ? 'Maelekezo maalum ya utoaji...' : 'Special delivery instructions...';
  String get fastSecurePayment => isSwahili ? 'Malipo ya haraka na salama' : 'Fast and secure payment';
  String get pay => isSwahili ? 'Lipa' : 'Pay';
  String get deliveryMethod => isSwahili ? 'Njia ya Utoaji' : 'Delivery Method';
  String get user => isSwahili ? 'Mtumiaji' : 'User';

  // Seller Dashboard
  String get shopSummary => isSwahili ? 'Muhtasari wa Duka' : 'Shop Summary';
  String get products => isSwahili ? 'Bidhaa' : 'Products';
  String get revenue => isSwahili ? 'Mapato' : 'Revenue';
  String get rating => isSwahili ? 'Ukadiriaji' : 'Rating';
  String productsActive(int count) => isSwahili ? '$count inauzwa' : '$count active';
  String ordersPending(int count) => isSwahili ? '$count inasubiri' : '$count pending';
  String ordersCompleted(int count) => isSwahili ? '$count imekamilika' : '$count completed';
  String reviewsCount2(int count) => isSwahili ? '$count maoni' : '$count reviews';
  String get addProduct => isSwahili ? 'Ongeza Bidhaa' : 'Add Product';
  String get pendingOrders => isSwahili ? 'Maagizo Yanayosubiri' : 'Pending Orders';
  String get myProducts => isSwahili ? 'Bidhaa Zangu' : 'My Products';
  String totalCount(int count) => isSwahili ? '$count jumla' : '$count total';
  String get view => isSwahili ? 'Tazama' : 'View';
  String get pauseSales => isSwahili ? 'Simamisha Mauzo' : 'Pause Sales';
  String get resumeSales => isSwahili ? 'Weka Kuuzwa' : 'Resume Sales';
  String get deleteProduct => isSwahili ? 'Futa Bidhaa' : 'Delete Product';
  String deleteProductConfirm(String title) => isSwahili
      ? 'Una uhakika unataka kufuta "$title"?'
      : 'Are you sure you want to delete "$title"?';
  String get productDeleted => isSwahili ? 'Bidhaa imefutwa' : 'Product deleted';
  String get failedToDelete => isSwahili ? 'Imeshindwa kufuta bidhaa' : 'Failed to delete product';
  String get productActivated => isSwahili ? 'Bidhaa imewekwa kuuzwa' : 'Product is now active';
  String get productPaused => isSwahili ? 'Bidhaa imesimamishwa' : 'Product sales paused';
  String get failedToUpdateStatus => isSwahili ? 'Imeshindwa kubadilisha hali' : 'Failed to update status';
  String get errorOccurred2 => isSwahili ? 'Kosa limetokea' : 'An error occurred';
  String get tryAgain2 => isSwahili ? 'Jaribu Tena' : 'Try Again';
  String productNumber(int id) => isSwahili ? 'Bidhaa #$id' : 'Product #$id';
  String get soldOut2 => isSwahili ? 'IMEISHA' : 'SOLD OUT';
  String get noProductsYet => isSwahili ? 'Hakuna Bidhaa Bado' : 'No Products Yet';
  String get noProductsFound => isSwahili ? 'Hakuna Bidhaa' : 'No Products';
  String get startSellingMessage => isSwahili ? 'Anza kuuza kwa kuongeza bidhaa yako ya kwanza' : 'Start selling by adding your first product';
  String get sellerNoProducts => isSwahili ? 'Muuzaji huyu hajaweka bidhaa bado' : 'This seller has no products yet';
  String productsCount(int count) => isSwahili ? '$count bidhaa' : '$count products';

  // ——— Groups Management (Profile > My Groups) ———
  String get groupInvitations => isSwahili ? 'Mialiko' : 'Invitations';
  String get groupsICreated => isSwahili ? 'Nilivyounda' : 'Created by me';
  String get systemGroups => isSwahili ? 'Vikundi vya Mfumo' : 'System Groups';
  String get systemGroupsSubtitle => isSwahili ? 'Shule, Mahali, Mwajiri' : 'School, Location, Employer';
  String get otherGroups => isSwahili ? 'Vikundi Vingine' : 'Other Groups';
  String get adminBadge => isSwahili ? 'Msimamizi' : 'Admin';
  String get systemBadge => isSwahili ? 'Mfumo' : 'System';
  String membersCount(int count) => isSwahili ? '$count wanachama' : '$count members';
  String get privacySecret => isSwahili ? 'Siri' : 'Secret';
  String invitedBy(String name) => isSwahili ? 'Umealikwa na $name' : 'Invited by $name';
  String get invitedToJoin => isSwahili ? 'Umealikwa kujiunga' : 'You\'ve been invited to join';
  String get acceptInvitation => isSwahili ? 'Kubali' : 'Accept';
  String get declineInvitation => isSwahili ? 'Kataa' : 'Decline';
  String get joinedGroup => isSwahili ? 'Umejiunga na kikundi' : 'You\'ve joined the group';
  String get declinedInvitation => isSwahili ? 'Umekataa mwaliko' : 'Invitation declined';
  String get actionFailed => isSwahili ? 'Imeshindwa. Jaribu tena.' : 'Failed. Try again.';
  String get discoverGroups => isSwahili ? 'Gundua' : 'Discover';
  String get noGroupsYet => isSwahili ? 'Hujajiunga na kikundi chochote bado' : 'You haven\'t joined any groups yet';
  String get somethingWrong => isSwahili ? 'Kuna tatizo' : 'Something went wrong';

  // ——— Files/Documents Management (Dropbox-like) ———
  String get storage => isSwahili ? 'Hifadhi' : 'Storage';
  String get filesCount => isSwahili ? 'faili' : 'files';
  String get foldersCount => isSwahili ? 'folda' : 'folders';
  String get allFiles => isSwahili ? 'Zote' : 'All';
  String get archives => isSwahili ? 'Kumbukumbu' : 'Archives';
  String get recentFiles => isSwahili ? 'Hivi Karibuni' : 'Recent';
  String get starredFiles => isSwahili ? 'Zenye Nyota' : 'Starred';
  String get offlineFiles => isSwahili ? 'Nje ya Mtandao' : 'Offline';
  String get sharedFiles => isSwahili ? 'Zilizoshirikiwa' : 'Shared';
  String get createFolder => isSwahili ? 'Unda Folda' : 'Create Folder';
  String get folderName => isSwahili ? 'Jina la folda' : 'Folder name';
  String get create => isSwahili ? 'Unda' : 'Create';
  String get deleteConfirm => isSwahili ? 'Una uhakika unataka kufuta' : 'Are you sure you want to delete';
  String get addToStarred => isSwahili ? 'Weka nyota' : 'Add star';
  String get removeFromStarred => isSwahili ? 'Ondoa nyota' : 'Remove star';
  String get rename => isSwahili ? 'Badilisha jina' : 'Rename';
  String get moveTo => isSwahili ? 'Hamisha' : 'Move to';
  String get copyTo => isSwahili ? 'Nakili' : 'Copy to';
  String get emptyFolder => isSwahili ? 'Folda tupu' : 'Empty folder';
  String get noFiles => isSwahili ? 'Hakuna faili' : 'No files';
  String get uploadFilesHint => isSwahili ? 'Bonyeza + kupakia faili' : 'Tap + to upload files';
  String get uploadFile => isSwahili ? 'Pakia faili' : 'Upload file';
  String get downloading => isSwahili ? 'Inapakua...' : 'Downloading...';
  String get uploading => isSwahili ? 'Inapakia...' : 'Uploading...';
  String get uploadSuccess => isSwahili ? 'Imepakiwa' : 'Uploaded';
  String get uploaded => isSwahili ? 'Imepakiwa' : 'Uploaded';
  String get failed => isSwahili ? 'Imeshindwa' : 'Failed';
  String get files => isSwahili ? 'faili' : 'files';

  // Product creation
  String get maxImagesReached => isSwahili ? 'Upeo wa picha 10 umefikiwa' : 'Maximum 10 images allowed';
  String get addAtLeastOneImage => isSwahili ? 'Tafadhali ongeza angalau picha moja' : 'Please add at least one image';
  String get productCreated => isSwahili ? 'Bidhaa imeundwa' : 'Product created successfully';
  String get basicInfo => isSwahili ? 'Taarifa za Msingi' : 'Basic Information';
  String get productTitle => isSwahili ? 'Jina la Bidhaa' : 'Product Title';
  String get productTitleHint => isSwahili ? 'Ingiza jina la bidhaa' : 'Enter product name';
  String get requiredField => isSwahili ? 'Sehemu hii inahitajika' : 'This field is required';
  String get descriptionHint => isSwahili ? 'Elezea bidhaa yako...' : 'Describe your product...';
  String get pricing => isSwahili ? 'Bei' : 'Pricing';
  String get invalidPrice => isSwahili ? 'Bei batili' : 'Invalid price';
  String get comparePrice => isSwahili ? 'Bei ya Kulinganisha' : 'Compare Price';
  String get optional => isSwahili ? 'Si lazima' : 'Optional';
  String get stockQuantity => isSwahili ? 'Kiasi cha Hisa' : 'Stock Quantity';
  String get locationDelivery => isSwahili ? 'Mahali na Usafirishaji' : 'Location & Delivery';
  String get locationHint => isSwahili ? 'k.m., Dar es Salaam' : 'e.g., Dar es Salaam';
  String get pickupAddress => isSwahili ? 'Anwani ya Kuchukua' : 'Pickup Address';
  String get pickupAddressHint => isSwahili ? 'Wanunuzi wanaweza kuchukua wapi?' : 'Where can buyers pick up?';
  String get deliveryNotes => isSwahili ? 'Maelezo ya Usafirishaji' : 'Delivery Notes';
  String get deliveryNotesHint => isSwahili ? 'Masharti, maeneo yanayofikiwa, n.k.' : 'Delivery terms, areas covered, etc.';
  String get productImages => isSwahili ? 'Picha za Bidhaa' : 'Product Images';
  String get imagesHint => isSwahili ? 'Ongeza hadi picha 10. Picha ya kwanza itakuwa jalada.' : 'Add up to 10 images. First image will be the cover.';
  String get cover => isSwahili ? 'Jalada' : 'Cover';
  String get location => isSwahili ? 'Mahali' : 'Location';
  String get allowPickup => isSwahili ? 'Ruhusu Kuchukua' : 'Allow Pickup';
  String get allowDelivery => isSwahili ? 'Ruhusu Kupeleka' : 'Allow Delivery';
  String get allowShipping => isSwahili ? 'Ruhusu Kusafirisha' : 'Allow Shipping';
  String get selectCategory => isSwahili ? 'Chagua kategoria' : 'Select category';
  String get noCategory => isSwahili ? 'Bila kategoria' : 'No category';

  // ─── Post Detail Screen ────────────────────────────────────────────
  String get pinToProfile => isSwahili ? 'Bandika kwenye profaili yako' : 'Pin to your profile';
  String get unpinPost => isSwahili ? 'Ondoa bandiko la chapisho' : 'Unpin post';
  String get postPinned => isSwahili ? 'Chapisho limebandikwa kwenye profaili' : 'Post pinned to profile';
  String get postUnpinned => isSwahili ? 'Chapisho limeondolewa bandiko' : 'Post unpinned';
  String get pinUpdateFailed => isSwahili ? 'Imeshindwa kusasisha bandiko' : 'Failed to update pin';
  String get postArchived => isSwahili ? 'Chapisho limehifadhiwa' : 'Post archived';
  String get archiveFailed => isSwahili ? 'Imeshindwa kuhifadhi chapisho' : 'Failed to archive post';
  String get reportSubmitted => isSwahili ? 'Ripoti imetumwa' : 'Report submitted';
  String get pinnedComment => isSwahili ? 'Imebandikwa' : 'Pinned';
  String get replyAction => isSwahili ? 'Jibu' : 'Reply';
  String get replyingTo => isSwahili ? 'Unajibu' : 'Replying to';
  String get replyToHint => isSwahili ? 'Jibu' : 'Reply to';
  String get viewReplies => isSwahili ? 'Ona' : 'View';
  String get hideReplies => isSwahili ? 'Ficha majibu' : 'Hide replies';
  String get repliesLabel => isSwahili ? 'majibu' : 'replies';
  String get unknownUser => isSwahili ? 'Haijulikani' : 'Unknown';
  String get commentNoun => isSwahili ? 'maoni' : 'comment';
  String get removeLike => isSwahili ? 'Ondoa pendo' : 'Unlike';
  String get shareToWall => isSwahili ? 'Shiriki kwenye ukuta wako' : 'Share to your wall';
  String get shareToChat => isSwahili ? 'Shiriki kwenye mazungumzo' : 'Share to chat';
  String get shareToSocial => isSwahili ? 'Shiriki kwenye mitandao mingine' : 'Share to social media';
  String get postShared => isSwahili ? 'Umeshiriki chapisho' : 'Post shared';
  String get shareFailed => isSwahili ? 'Imeshindwa kushiriki' : 'Failed to share';
  String get sentToChat => isSwahili ? 'Imetumwa kwenye mazungumzo' : 'Sent to chat';
  String get selectChat => isSwahili ? 'Chagua mazungumzo' : 'Select a chat';
  String get searchChats => isSwahili ? 'Tafuta mazungumzo...' : 'Search chats...';
  String get noChatsFound => isSwahili ? 'Hakuna mazungumzo yaliyopatikana' : 'No chats found';
  String get edited => isSwahili ? 'Iliyohaririwa' : 'Edited';
  String get audioUnavailable => isSwahili ? 'Sauti haipatikani - hakuna audio_path' : 'Audio unavailable - no audio_path';
  String get audioAndText => isSwahili ? 'Sauti + Maandishi' : 'Audio + Text';
  String get audio => isSwahili ? 'Sauti' : 'Audio';
  String get unsave => isSwahili ? 'Ondoa hifadhi' : 'Unsave';
  String get subscribersOnly => isSwahili ? 'Kwa Wasajili Pekee' : 'Subscribers Only';
  String subscribeTo(String name) => isSwahili ? 'Jisajili kwa $name\nkuona maudhui haya' : 'Subscribe to $name\nto see this content';
  String get thisCreator => isSwahili ? 'msanii huyu' : 'this creator';

  // ——— Gossip / Threads ———
  String get trendingThreads => isSwahili ? 'Mada Zinazovuma' : 'Trending Threads';
  String get gossipDigest => isSwahili ? 'Muhtasari' : 'Digest';
  String get activeThread => isSwahili ? 'Inaendelea' : 'Active';
  String get coolingThread => isSwahili ? 'Inapoa' : 'Cooling';
  String get archivedThread => isSwahili ? 'Imehifadhiwa' : 'Archived';
  String get threadPosts => isSwahili ? 'Machapisho' : 'Posts';
  String get threadParticipants => isSwahili ? 'Washiriki' : 'Participants';
  String get viewThread => isSwahili ? 'Tazama Mada' : 'View Thread';
  String get partOfThread => isSwahili ? 'Sehemu ya mada inayovuma' : 'Part of trending thread';
  String get trendingNow => isSwahili ? 'Vinavyovuma Sasa' : 'Trending Now';
  String get proverbOfTheDay => isSwahili ? 'Methali ya Leo' : 'Proverb of the Day';
  String get morningDigest => isSwahili ? 'Muhtasari wa Asubuhi' : 'Morning Digest';
  String get eveningDigest => isSwahili ? 'Muhtasari wa Jioni' : 'Evening Digest';
  String get noThreadsYet => isSwahili ? 'Hakuna mada bado' : 'No threads yet';
  String get allCategories => isSwahili ? 'Zote' : 'All';
  String get entertainment => isSwahili ? 'Burudani' : 'Entertainment';
  String get business => isSwahili ? 'Biashara' : 'Business';
  // music already defined above
  String get sports => isSwahili ? 'Michezo' : 'Sports';
  String get local => isSwahili ? 'Mtaani' : 'Local';
  String get peopleTalking => isSwahili ? 'watu wanazungumzia' : 'people talking';
  String get postsInThread => isSwahili ? 'machapisho katika mada' : 'posts in thread';
  String get personalizedFeed => isSwahili ? 'Kwako' : 'For You';
  String get loadingThreads => isSwahili ? 'Inapakia mada...' : 'Loading threads...';

  // ——— Creator Payments & Addiction ———
  String get creatorDashboard => isSwahili ? 'Dashibodi ya Muundaji' : 'Creator Dashboard';
  String get thisWeek => isSwahili ? 'Wiki Hii' : 'This Week';
  String get weeklyReport => isSwahili ? 'Ripoti ya Wiki' : 'Weekly Report';
  String get bestPost => isSwahili ? 'Chapisho Bora' : 'Best Post';
  String get postingTip => isSwahili ? 'Kidokezo cha Wiki' : 'Tip of the Week';
  String get defaultPostingTip => isSwahili
      ? 'Chapisha wakati wa kilele ambapo hadhira yako inashiriki zaidi kwa ushiriki bora.'
      : 'Post during peak hours when your audience is most active for better engagement.';
  String get engagementTrend => isSwahili ? 'Mwenendo wa Ushiriki' : 'Engagement Trend';
  String get followerChange => isSwahili ? 'Mabadiliko ya Wafuasi' : 'Follower Change';
  String get threadsTriggered => isSwahili ? 'Mada Zilizoanzishwa' : 'Threads Triggered';
  String get fundPool => isSwahili ? 'Mfuko wa Waundaji' : 'Creator Fund';
  String get projectedPayout => isSwahili ? 'Malipo Yanayotarajiwa' : 'Projected Payout';
  String get tierRising => isSwahili ? 'Anayeinuka' : 'Rising';
  String get tierEstablished => isSwahili ? 'Imara' : 'Established';
  String get tierStar => isSwahili ? 'Nyota' : 'Star';
  String get tierLegend => isSwahili ? 'Hadithi' : 'Legend';
  String get streakDays => isSwahili ? 'siku mfululizo' : 'day streak';
  String get postingStreak => isSwahili ? 'Mfululizo wa Kuchapisha' : 'Posting Streak';
  String get viewingStreak => isSwahili ? 'Mfululizo wa Kutazama' : 'Viewing Streak';
  String get streakFrozen => isSwahili ? 'Mfululizo umegandishwa' : 'Streak frozen';
  String get resumeStreak => isSwahili ? 'Endelea na mfululizo wako wa siku' : 'Resume your streak';
  String get welcomeBackStreak => isSwahili ? 'Karibu tena! Endelea na mfululizo wako?' : 'Welcome back! Resume your streak?';
  String get multipliers => isSwahili ? 'Vizidishi' : 'Multipliers';
  String get tierMultiplier => isSwahili ? 'Kizidishi cha Ngazi' : 'Tier Multiplier';
  String get streakMultiplier => isSwahili ? 'Kizidishi cha Mfululizo' : 'Streak Multiplier';
  String get digest => isSwahili ? 'Muhtasari' : 'Digest';
  String get goodMorning => isSwahili ? 'Asubuhi Njema!' : 'Good Morning!';
  String get goodEvening => isSwahili ? 'Usiku Mwema!' : 'Good Evening!';
  String get topThreadsToday => isSwahili ? 'Mada Kuu za Leo' : 'Top Threads Today';
  String get milestone => isSwahili ? 'Hatua Muhimu!' : 'Milestone!';
  String get followersReached => isSwahili ? 'wafuasi umefika!' : 'followers reached!';
  String get keepGoing => isSwahili ? 'Endelea hivyo!' : 'Keep going!';
  String get trendUp => isSwahili ? 'Inaongezeka' : 'Trending Up';
  String get trendDown => isSwahili ? 'Inapungua' : 'Trending Down';
  String get trendStable => isSwahili ? 'Imara' : 'Stable';
  String get viralAssists => isSwahili ? 'Msaada wa Viral' : 'Viral Assists';
  String get viralAlert => isSwahili ? 'Chapisho kinachoenea!' : 'Post going viral!';
  String get viralPostAlert => isSwahili ? 'Chapisho kinachoenea sasa!' : 'A post is going viral right now!';

  // ——— Phase 4: Sponsored, Battles, Collaboration, Analytics ———
  String get sponsored => isSwahili ? 'Imedhaminiwa' : 'Sponsored';
  String get sponsoredPost => isSwahili ? 'Chapisho cha Udhamini' : 'Sponsored Post';
  String get createSponsoredPost => isSwahili ? 'Unda Chapisho cha Udhamini' : 'Create Sponsored Post';
  String get browseSponsorableCreators => isSwahili ? 'Tafuta Waundaji' : 'Browse Creators';
  String get sponsorshipBudget => isSwahili ? 'Bajeti ya Udhamini' : 'Sponsorship Budget';
  String get impressionsTarget => isSwahili ? 'Lengo la Maonyesho' : 'Impressions Target';
  String get impressionsDelivered => isSwahili ? 'Maonyesho Yaliyofikiwa' : 'Impressions Delivered';
  String get starLegendOnly => isSwahili ? 'Star na Legend tu' : 'Star & Legend only';
  String get collaborationRadar => isSwahili ? 'Rada ya Ushirikiano' : 'Collaboration Radar';
  String get suggestedCollaborators => isSwahili ? 'Washirika Wanaopendekezwa' : 'Suggested Collaborators';
  String get collaborate => isSwahili ? 'Shirikiana' : 'Collaborate';
  String get dismissSuggestion => isSwahili ? 'Ondoa' : 'Dismiss';
  String get sharedCategory => isSwahili ? 'Aina Inayoshirikiana' : 'Shared Category';
  String get creatorBattles => isSwahili ? 'Mashindano ya Waundaji' : 'Creator Battles';
  String get battleTopic => isSwahili ? 'Mada ya Mashindano' : 'Battle Topic';
  String get sideA => isSwahili ? 'Upande A' : 'Side A';
  String get sideB => isSwahili ? 'Upande B' : 'Side B';
  String get castVote => isSwahili ? 'Piga Kura' : 'Cast Vote';
  String get voteCast => isSwahili ? 'Kura imepigwa!' : 'Vote cast!';
  String get battleOpen => isSwahili ? 'Wazi' : 'Open';
  String get battleVoting => isSwahili ? 'Kupigia Kura' : 'Voting';
  String get battleClosed => isSwahili ? 'Imefungwa' : 'Closed';
  String get analyticsDashboard => isSwahili ? 'Dashibodi ya Takwimu' : 'Analytics Dashboard';
  String get avgEngagement => isSwahili ? 'Wastani wa Ushiriki' : 'Avg Engagement';
  String get postsThisMonth => isSwahili ? 'Machapisho Mwezi Huu' : 'Posts This Month';
  String get bestTime => isSwahili ? 'Muda Bora' : 'Best Time';
  String get topFormat => isSwahili ? 'Umbizo Bora' : 'Top Format';
  String get audienceInsights => isSwahili ? 'Maoni ya Hadhira' : 'Audience Insights';
  String get topCity => isSwahili ? 'Jiji Kuu' : 'Top City';
  String get activeFollowers => isSwahili ? 'Wafuasi Hai' : 'Active Followers';
  String get peakActivity => isSwahili ? 'Kilele cha Shughuli' : 'Peak Activity';
  String get last30Days => isSwahili ? 'Siku 30 Zilizopita' : 'Last 30 Days';
  String get topPosts => isSwahili ? 'Machapisho Bora' : 'Top Posts';
  String get viewAnalytics => isSwahili ? 'Tazama Takwimu' : 'View Analytics';
  String get creatorSettings => isSwahili ? 'Mipangilio ya Muundaji' : 'Creator Settings';
  String get optOutSponsored => isSwahili ? 'Sitaki machapisho ya udhamini' : 'Opt out of sponsored posts';
  String get optOutCollaboration => isSwahili ? 'Sitaki mapendekezo ya ushirikiano' : 'Opt out of collaboration suggestions';
  String get optOutBattles => isSwahili ? 'Sitaki mashindano' : 'Opt out of battles';
  String get optOutThreads => isSwahili ? 'Sitaki machapisho yangu kwenye mada' : 'Don\'t include my posts in threads';
  String get votes => isSwahili ? 'kura' : 'votes';
  String get vs => 'vs';

  // ——— Feature 5: Smart posting nudge ———
  String get smartNudge => isSwahili ? 'Kidokezo' : 'Tip';

  // ——— Feature 6: Evening digest ———
  String get eveningRecap => isSwahili ? 'Muhtasari wa Jioni' : 'Evening Recap';
  String get postsViewedToday => isSwahili ? 'Machapisho uliyotazama leo' : 'Posts you viewed today';
  String get newThreadsToday => isSwahili ? 'Mada mpya leo' : 'New threads today';

  // ——— Feature 7: Content calendar ———
  String get contentCalendar => isSwahili ? 'Kalenda ya Maudhui' : 'Content Calendar';
  String get bestTimeToPost => isSwahili ? 'Wakati bora wa kuchapisha' : 'Best time to post';

  // ——— PostCard Instagram-style strings ———
  String get justNow => isSwahili ? 'Sasa hivi' : 'Just now';
  String minutesAgoShort(int n) => isSwahili ? 'Dakika $n' : '${n}m';
  String hoursAgoShort(int n) => isSwahili ? 'Saa $n' : '${n}h';
  String daysAgoShort(int n) => isSwahili ? 'Siku $n' : '${n}d';
  String get views => isSwahili ? 'maoni' : 'views';
  String likesCount(String n) => isSwahili ? 'Wapendaji $n' : '$n likes';
  String viewsCount(String n) => isSwahili ? 'Watazamaji $n' : '$n views';
  String viewAllComments(String n) => isSwahili ? 'Tazama maoni yote $n' : 'View all $n comments';
  String get whatDoYouThink => isSwahili ? 'Unafikiri nini?' : 'What do you think?';
  String get beenQuietToday => isSwahili ? 'Umekuwa kimya leo \u2014 unafikiri nini?' : 'You\'ve been quiet today \u2014 what do you think?';
  String get someone => isSwahili ? 'Mtu fulani' : 'Someone';
  String shortDate(int day, int month, int year) => '$day/$month/$year';

  // Reaction labels (i18n-aware)
  String get reactionLike => isSwahili ? 'Penda' : 'Like';
  String get reactionLove => isSwahili ? 'Upendo' : 'Love';
  String get reactionHaha => isSwahili ? 'Haha' : 'Haha';
  String get reactionWow => isSwahili ? 'Wow' : 'Wow';
  String get reactionSad => isSwahili ? 'Huzuni' : 'Sad';
  String get reactionAngry => isSwahili ? 'Hasira' : 'Angry';
  String reactionLabel(String reaction) {
    switch (reaction) {
      case 'like': return reactionLike;
      case 'love': return reactionLove;
      case 'haha': return reactionHaha;
      case 'wow': return reactionWow;
      case 'sad': return reactionSad;
      case 'angry': return reactionAngry;
      default: return reaction;
    }
  }

  // ——— Content Engine ———
  String get whatsHappeningNow => isSwahili ? 'Kinachoendelea Sasa' : "What's Happening Now";
  String get searchEverything => isSwahili ? 'Tafuta kila kitu...' : 'Search everything...';
  String get ceAllTypes => isSwahili ? 'Zote' : 'All';
  String get musicType => isSwahili ? 'Muziki' : 'Music';
  String get people => isSwahili ? 'Watu' : 'People';
  String get eventsType => isSwahili ? 'Matukio' : 'Events';
  String get groupsType => isSwahili ? 'Makundi' : 'Groups';
  String get productsType => isSwahili ? 'Bidhaa' : 'Products';
  String get campaignsType => isSwahili ? 'Michango' : 'Campaigns';
  String get notInterestedInThis => isSwahili ? 'Sipendezwi na hii' : 'Not interested in this';
  String get showingYouThis => isSwahili ? 'Tunakuonyesha hii kwa sababu' : 'Showing you this because';
  String get trendingContent => isSwahili ? 'Inavuma' : 'Trending';
  String get forYouContent => isSwahili ? 'Kwa ajili yako' : 'For you';
  String get friendsLikeThis => isSwahili ? 'Marafiki wako wanapenda' : 'Your friends like this';
  String get discoverSomethingNew => isSwahili ? 'Gundua kitu kipya' : 'Discover something new';
  String get moreLikeThis => isSwahili ? 'Zaidi kama hii' : 'More like this';
  String get trendingSearches => isSwahili ? 'Tafuta zinazovuma' : 'Trending searches';
  String get recentSearches => isSwahili ? 'Ulizotafuta hivi karibuni' : 'Recent searches';
  String get nGoingCount => isSwahili ? 'wanaenda' : 'going';
  String get ceMembersCount => isSwahili ? 'wanachama' : 'members';
  String get followersCount => isSwahili ? 'wafuasi' : 'followers';
  String get joinGroup => isSwahili ? 'Jiunge' : 'Join';
  String get followPage => isSwahili ? 'Fuata' : 'Follow';
  String get ceDaysRemaining => isSwahili ? 'siku zimebaki' : 'days remaining';
  String get funded => isSwahili ? 'imekusanywa' : 'funded';
  String get viewerCount => isSwahili ? 'watazamaji' : 'viewers';

  // ——— Biashara (Ads) ———
  String get biashara => isSwahili ? 'Biashara' : 'Business';
  String get tangazo => isSwahili ? 'Tangazo' : 'Advertisement';
  String get kampeni => isSwahili ? 'Kampeni' : 'Campaign';
  String get tengenezaKampeni => isSwahili ? 'Tengeneza Kampeni' : 'Create Campaign';
  String get salio => isSwahili ? 'Salio la Matangazo' : 'Ad Balance';
  String get ongezaSalio => isSwahili ? 'Ongeza Salio' : 'Top Up Balance';
  String get haliYaKampeni => isSwahili ? 'Hali ya Kampeni' : 'Campaign Status';
  String get rasimu => isSwahili ? 'Rasimu' : 'Draft';
  String get inakaguliwa => isSwahili ? 'Inakaguliwa' : 'Under Review';
  String get inatumika => isSwahili ? 'Inatumika' : 'Active';
  String get imesimamishwa => isSwahili ? 'Imesimamishwa' : 'Paused';
  String get imekamilika => isSwahili ? 'Imekamilika' : 'Completed';
  String get imekataliwa => isSwahili ? 'Imekataliwa' : 'Rejected';
  String get imefutwa => isSwahili ? 'Imefutwa' : 'Cancelled';
  String get bajeti => isSwahili ? 'Bajeti' : 'Budget';
  String get maonyesho => isSwahili ? 'Maonyesho' : 'Impressions';
  String get mibofyo => isSwahili ? 'Mibofyo' : 'Clicks';
  String get matumizi => isSwahili ? 'Matumizi' : 'Spend';
  String get wasilisha => isSwahili ? 'Wasilisha' : 'Submit';
  String get imedhaminiwa => isSwahili ? 'Imedhaminiwa' : 'Sponsored';
  String get muhtasariWaLeo => isSwahili ? 'Muhtasari wa Leo' : "Today's Summary";
  String get hakupaKampeni => isSwahili ? 'Huna kampeni bado' : 'No campaigns yet';
  String get anzaKutangaza => isSwahili ? 'Anza kutangaza biashara yako!' : 'Start advertising your business!';
  String get ainaNyaKampeni => isSwahili ? 'Aina ya Kampeni' : 'Campaign Type';
  String get cpm => 'CPM';
  String get cpc => 'CPC';
  String get cpmDesc => isSwahili ? 'Lipa kwa maonyesho 1,000' : 'Pay per 1,000 impressions';
  String get cpcDesc => isSwahili ? 'Lipa kwa kila mbofyo' : 'Pay per click';
  String get tangazoLako => isSwahili ? 'Tangazo Lako' : 'Your Creative';
  String get umboPicha => isSwahili ? 'Picha' : 'Image';
  String get umboVideo => isSwahili ? 'Video' : 'Video';
  String get umboNative => isSwahili ? 'Native' : 'Native';
  String get kichwaChaTangazo => isSwahili ? 'Kichwa cha Tangazo' : 'Ad Headline';
  String get maelezoYaTangazo => isSwahili ? 'Maelezo ya Tangazo' : 'Ad Body Text';
  String get ainaCTA => isSwahili ? 'Aina ya Kitufe' : 'CTA Type';
  String get linkYaCTA => isSwahili ? 'Link ya Kitufe' : 'CTA URL';
  String get walengwa => isSwahili ? 'Walengwa' : 'Targeting';
  String get eneo => isSwahili ? 'Eneo' : 'Location';
  String get umriRange => isSwahili ? 'Umri' : 'Age Range';
  String get jinsia => isSwahili ? 'Jinsia' : 'Gender';
  String get woteGender => isSwahili ? 'Wote' : 'All';
  String get meGender => isSwahili ? 'Wanaume' : 'Male';
  String get keGender => isSwahili ? 'Wanawake' : 'Female';
  String get maeneo => isSwahili ? 'Maeneo ya Kuonyesha' : 'Placements';
  String get bajetiNaRatiba => isSwahili ? 'Bajeti na Ratiba' : 'Budget & Schedule';
  String get jina => isSwahili ? 'Jina la Kampeni' : 'Campaign Title';
  String get bajetiKwaiku => isSwahili ? 'Bajeti ya Kila Siku (TZS)' : 'Daily Budget (TZS)';
  String get bajetiJumla => isSwahili ? 'Bajeti Jumla (TZS)' : 'Total Budget (TZS)';
  String get kiasi => isSwahili ? 'Kiasi cha Bid (TZS)' : 'Bid Amount (TZS)';
  String get tarikhiKuanza => isSwahili ? 'Tarehe ya Kuanza' : 'Start Date';
  String get tarikhiKumalizika => isSwahili ? 'Tarehe ya Kumalizika (Hiari)' : 'End Date (Optional)';
  String get kagua => isSwahili ? 'Kagua na Wasilisha' : 'Review & Submit';
  String get ongezaKiasi => isSwahili ? 'Ongeza Kiasi' : 'Enter Amount';
  String get karoYaHuduma => isSwahili ? 'Karo ya huduma' : 'Service fee';
  String get salioLitakaloongezwa => isSwahili ? 'Salio litakaloongezwa' : 'Balance to be added';
  String get thibitisha => isSwahili ? 'Thibitisha' : 'Confirm';
  String get amanaImefanikiwa => isSwahili ? 'Amana imefanikiwa!' : 'Deposit successful!';
  String get simamisha => isSwahili ? 'Simamisha' : 'Pause';
  String get endeleza => isSwahili ? 'Endeleza' : 'Resume';
  String get ghairi => isSwahili ? 'Ghairi' : 'Cancel';
  String get ctr => 'CTR';

  // ——— Shangazi Tea ———
  String get teaTab => isSwahili ? 'Chai' : 'Tea';
  String get shangaziTeaRoom => isSwahili ? 'Chumba cha Chai cha Shangazi' : "Shangazi's Tea Room";
  String get askShangazi => isSwahili ? 'Uliza Shangazi...' : 'Ask Shangazi...';
  String get shangaziBrewing => isSwahili ? 'Shangazi anapika chai...' : 'Shangazi is brewing tea...';
  String get confirmAction => isSwahili ? 'Thibitisha' : 'Confirm';
  String get cancelAction => isSwahili ? 'Ghairi' : 'Cancel';
}
