class BaseApiResponse {
  bool? success;
  int? status_code;
  String? method;
  String? status;
  dynamic? data;
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
      } else {
        data = null;
      }
    } else {
      data = null;
    }
    message = json["message"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["success"] = success;
    data["status_code"] = status_code;
    data["method"] = method;
    data["status"] = status;
    data["data"] = data;
    data["message"] = message;
    return data;
  }
}
