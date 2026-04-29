// TESTING ONLY — fixed bearer for https://tenders.zimasystems.com/api
// Empty [kTendersTestBearer] before production or rely on login/register + JWT cache.
// For private repos: rotate this token if the repo is ever made public.
//
// Priority in [TenderService._getToken]: this value → TENDERS_API_BEARER dart-define → Hive JWT.

const String kTendersTestBearer =
    '413d7cf09d4e70c4d0cad7506a5904b5bd5646b57fea347ca04b92fb39a9a756';
