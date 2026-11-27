class BaseApiResponse {
  bool? success;
  int? status_code;
  String? method;
  String? status;
  dynamic data;
  String? message;

  BaseApiResponse({this.success, this.status_code, this.method,this.status, this.data, this.message});

  BaseApiResponse.fromJson(Map<String, dynamic> json) {
    success = json["success"];
    status_code = json["status_code"];
    method = json["method"];
    status = json["status"];
    final jsonData = json["data"];
    if (jsonData != null) {
      if (jsonData is Map<String, dynamic>) {
        data = jsonData;
      } else if (jsonData is List<dynamic>) {
        data = jsonData;
      } else if(jsonData is String) {
        data = jsonData;
      }else{
        data = null;
      }
    } else {
      data = null;
    }
    message = json["message"];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    "success": success,
    "status_code": status_code,
    "method": method,
    "status": status,
    "data": data,
    "message": message,
  };
}
