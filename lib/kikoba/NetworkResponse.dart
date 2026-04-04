class NetworkResponse {
  int code = 1;
  String message ="";
  String description  ="";

  NetworkResponse.from(Map<String, dynamic> data)
      : code = data['response']['code'],
        message = data['response']['message'],
        description = data['response']['description'];

  NetworkResponse(this.code, this.message);
}
