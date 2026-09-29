/// HR service base URL (no trailing slash).
const String kVmsHrBaseUrl = 'http://111.93.234.134:85';

const String kGetAllVisitorsPath = '/v1/hr-service/get-all-visitors';
const String kGetEmployeesByUnitFromLogsPath =
    '/v1/hr-service/attendance-log/get-employees-by-unit-from-logs';
const String kPurposeMasterListPath = '/v1/hr-service/purpose-master/list';
const String kCreateVisitorLogPath = '/v1/hr-service/create-visitor-log';
const String kCreateVisitorPath = '/v1/hr-service/create-visitor';
const String kAddVisitorPhotoPath = '/v1/hr-service/add-visitor-photo';
const String kGetAllVisitorLogsByEmployeeIdPath =
    '/v1/hr-service/get-all-visitor-logs-by-employee-id';
const String kVerifyOtpVisitorLogPath = '/v1/hr-service/verify-otp-visitor-log';

/// Automate Gate Inward (document OCR + ingestion) service base URL.
/// Tunnelled via ngrok (LAN IP + Windows Firewall was blocking inbound
/// connections from other devices) — update this if the ngrok URL changes.
const String kGateInwardApiBaseUrl = 'https://shanon-unsplattered-hypostatically.ngrok-free.dev';
const String kAutomateGateInwardPath = '/sse/vendor/app-store-document';
