/// Registration screen labels in Swahili and English.
/// Use [RegistrationStrings.get] with [languageCode] from context
/// (e.g. Localizations.localeOf(context).languageCode) for 'sw' or 'en'.
class RegistrationStrings {
  RegistrationStrings(this.languageCode)
      : isSwahili = languageCode == 'sw' || languageCode.startsWith('sw');

  final String languageCode;
  final bool isSwahili;

  static RegistrationStrings of(String languageCode) {
    return RegistrationStrings(languageCode);
  }

  // Bio step
  String get welcome => isSwahili ? 'Karibu Tajiri!' : 'Welcome to Tajiri!';
  String get tellUsAboutYou =>
      isSwahili ? 'Tuambie kuhusu wewe' : 'Tell us about you';
  String get firstName => isSwahili ? 'Jina la Kwanza' : 'First name';
  String get lastName => isSwahili ? 'Jina la Ukoo' : 'Last name';
  String get firstNameHint => isSwahili ? 'Mfano: Juma' : 'e.g. Juma';
  String get lastNameHint => isSwahili ? 'Mfano: Mohamed' : 'e.g. Mohamed';
  String get dateOfBirth => isSwahili ? 'Tarehe ya Kuzaliwa' : 'Date of birth';
  String get selectDate => isSwahili ? 'Chagua tarehe' : 'Select date';
  String get selectDateOfBirth =>
      isSwahili ? 'Chagua tarehe ya kuzaliwa' : 'Select date of birth';
  String get cancel => isSwahili ? 'Ghairi' : 'Cancel';
  String get choose => isSwahili ? 'Chagua' : 'Choose';
  String get gender => isSwahili ? 'Jinsia' : 'Gender';
  String get male => isSwahili ? 'Mwanaume' : 'Male';
  String get female => isSwahili ? 'Mwanamke' : 'Female';
  String get continueBtn => isSwahili ? 'Endelea' : 'Continue';

  String get firstNameRequired =>
      isSwahili ? 'Jina la kwanza linahitajika' : 'First name is required';
  String get lastNameRequired =>
      isSwahili ? 'Jina la ukoo linahitajika' : 'Last name is required';
  String get dateOfBirthRequired =>
      isSwahili ? 'Chagua tarehe ya kuzaliwa' : 'Date of birth is required';
  String get genderRequired =>
      isSwahili ? 'Chagua jinsia' : 'Please select gender';

  // Phone step
  String get phoneNumber => isSwahili ? 'Namba ya Simu' : 'Phone number';
  String get enterCode => isSwahili ? 'Ingiza Kodi' : 'Enter code';
  String get weSentSms =>
      isSwahili
          ? 'Tumekutumia SMS na kodi ya kuthibitisha'
          : 'We sent you an SMS with a verification code';
  String get weWillSendSms =>
      isSwahili
          ? 'Tutakutumia SMS ya kuthibitisha'
          : 'We will send you an SMS to verify';
  String get sendCode => isSwahili ? 'Tuma Kodi' : 'Send code';
  String get change => isSwahili ? 'Badilisha' : 'Change';
  String get verify => isSwahili ? 'Thibitisha' : 'Verify';
  String resendInSeconds(int n) =>
      isSwahili ? 'Tuma tena baada ya $n sekunde' : 'Resend in $n seconds';
  String get resendCode => isSwahili ? 'Tuma kodi tena' : 'Resend code';
  String get codeIncorrect =>
      isSwahili ? 'Kodi si sahihi. Jaribu 111111' : 'Code is incorrect. Try 111111';
  String get phoneAlreadyRegistered =>
      isSwahili
          ? 'Nambari hii ya simu imeshasajiliwa'
          : 'This phone number is already registered';
  String get phoneAvailable =>
      isSwahili
          ? 'Nambari inapatikana. Tuma kodi.'
          : 'Number is available. Sending code.';

  String get phoneRequired =>
      isSwahili ? 'Namba ya simu inahitajika' : 'Phone number is required';

  // Registration screen
  String stepLabelFormat(int current, int total) =>
      isSwahili ? 'Hatua $current / $total' : 'Step $current of $total';
  String get stepBio => isSwahili ? 'Taarifa Binafsi' : 'Personal info';
  String get stepPhone => isSwahili ? 'Thibitisha Simu' : 'Verify phone';
  String get stepLocation => isSwahili ? 'Mahali Unapoishi' : 'Where you live';
  String get stepPrimary => isSwahili ? 'Shule ya Msingi' : 'Primary school';
  String get stepSecondary =>
      isSwahili ? 'Sekondari (O-Level)' : 'Secondary (O-Level)';
  String get stepEducation => isSwahili ? 'Elimu Zaidi' : 'Further education';
  String get stepAlevel => isSwahili ? 'A-Level (Form 5-6)' : 'A-Level (Form 5-6)';
  String get stepPostSecondary =>
      isSwahili ? 'Chuo/Taasisi' : 'College/Institution';
  String get stepUniversity => isSwahili ? 'Chuo Kikuu' : 'University';
  String get stepEmployer => isSwahili ? 'Mwajiri' : 'Employer';

  String get saving => isSwahili ? 'Inahifadhi taarifa...' : 'Saving...';
  String get congratulations => isSwahili ? 'Hongera!' : 'Congratulations!';
  String get registrationComplete =>
      isSwahili
          ? 'Usajili wako umekamilika. Karibu Tajiri!'
          : 'Your registration is complete. Welcome to Tajiri!';
  String get viewProfile => isSwahili ? 'Tazama Wasifu' : 'View profile';
  String get saveFailed => isSwahili ? 'Imeshindwa kuhifadhi' : 'Failed to save';

  // Login screen (path: Splash → Login → Registration)
  String get loginScreenTitle => isSwahili ? 'Karibu' : 'Welcome';
  String get loginScreenSubtitle =>
      isSwahili ? 'Ingia au jisajili kwa simu' : 'Sign in or register with your phone';
  String get createAccount => isSwahili ? 'Jisajili' : 'Create account';
  String get signIn => isSwahili ? 'Ingia' : 'Sign in';
}
