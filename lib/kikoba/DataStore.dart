
import 'vicoba.dart';

class DataStore {
  static int defaultTab = 0;
  static String? pendingVoteRequestId; // Set by notification click to show voting bottom sheet
  static bool showVotingSheetOnLoad = false; // Set to true to auto-open voting sheet on tabshome load
  static String otp ="";
  static String userNumber ="";
  static String userNumberMNO ="";
  static String userCheo ="";
  static String? currentUserRole; // User's role: chairman, secretary, accountant, member
  static String userAccountNumber ="";
  static String currentKikobaId ="";
  static String currentKikobaName ="";
  static String currentKikobaImage ="";
  static String currentUserName  ="";
  static String currentUserId ="";
  static String currentUserProfilePhoto = "";
  static String? lastRegisteredUserId;
  static String visitedKikobaId ="";
  static Null theDatabase;
  static String dialogTitle = "Unknow Action";
  static String dialogDescriptions = "There was an error performing this action";
  static String dialogOkButtonText = "OK";
  static String dialogNoButtonText = "HAPANA";
  static String createKikobaName = "";
  static String createKikobaMaelezo = "";
  static String createKikobaEneo = "";
  static String kiingilio = "0";

  static String ada = "0";

  static String Hisa ="0";

  static String fainiVikao ="0";

  static String faini_ada ="0";

  static String faini_hisa = "0";

  static String faini_michango ="0";

  static String paymentService ="ada";
  static String paymentChanel ="VISA";
  static String paymentInstitution ="VODACOM";

  static String payingBIN ="684023";
  static String payingBank ="AZANIA COMMERCIAL BANK";
  static String payingAccount ="11800018791";

  static String maelezoYaMalipo="Malipo";

  static List<vicoba> myVikobaList = [];
  static var transactionsList;

  static var adaListList;

  static var kiingilioStatus;

  static var adaStatus;

  static var hisaStatus;

  static var faini_adaStatus;

  static var faini_hisaStatus;

  static var fainiVikaoStatus;

  static var faini_michangoStatus;

  static var chini;

  static var mikopo;

  static var tenure;

  static var fainiyamikopo;

  static var riba;
  static var ribaStatus;

  static var jumlaYaAda =0.0;

  static var hisaList;

  static List<dynamic>? akibaList;

  static var membersList;

  static var ratibaYaMkopo;

  static var majukumuList;

  static var mikopoList;

  static List<dynamic>? loanProducts;

  static var vikaoList;

  static var maamuzimList;

  static var barazaList;

  static var casesList;

  static var paymentAmount;

  static var adaPaymentMap;

  static var adaPaymentMapx;

  static var adaPaymentMapxy;

  static var michangoList;

  static var ainayaMchango;

  static var michangoxList;

  static var paidServiceId;

  static var personPaidId;

  static var katiba;

  static var mikopoStatus;

  static bool userPresent = false;

  static var profileImage = "noimage";

  static String waitDescription ="Una unganishwa";

  static String waitTitle = "Tafadhali subiri";

  static var invitingKikobaId ="";

  static var bankServicesList;

  static var bankServiceId;

  static var bankServiceName;

  static var currentUserIdid;

  static var currentUserReg_date;

  static var currentUserUserStatus;

  static var currentUserIdUdid;

  static var currentUserIdOtp;

  static var currentKikobaIs_expired;

  static var currentUserLocalpostImage = "assets/no-avatar.png";

  static String currentUserIdRemotepostImage = "";

  static var currentUserCreate_at;

  static String loanInfoID ="";

  static String paymentTopUpAmount ="";

  static var fainiList;

  static var kwaniabaName;

  static var kwaniabaId;

  static var currentDeni;

  static var currentDeniFloat;

  static var currentDeniFloatStore;

  static List adapaymentTogo = [];

  // Payment control numbers
  static List<dynamic> controlNumbersAda = [];
  static List<dynamic> controlNumbersHisa = [];
  static List<dynamic> controlNumbersAkiba = [];

  // Helper to get control numbers by type
  static List<dynamic> getControlNumbers(String type) {
    switch (type.toLowerCase()) {
      case 'ada':
        return controlNumbersAda;
      case 'hisa':
        return controlNumbersHisa;
      case 'akiba':
        return controlNumbersAkiba;
      default:
        return [];
    }
  }

  // Helper to get pending payments count
  static int getPendingPaymentsCount() {
    int count = 0;
    for (var item in controlNumbersAda) {
      if (item['status'] == 'pending') count++;
    }
    for (var item in controlNumbersHisa) {
      if (item['status'] == 'pending') count++;
    }
    for (var item in controlNumbersAkiba) {
      if (item['status'] == 'pending') count++;
    }
    return count;
  }

}