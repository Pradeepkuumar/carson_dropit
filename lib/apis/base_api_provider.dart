import 'dart:async';
import 'dart:convert';

import 'dart:io';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/request/request.dart';

class ApiProvider extends GetConnect {
  final String acceptEncoding = 'gzip, deflate';
  final String accept = '*/*';
  final String noCache = 'no-cache';
  String token = "";


  File? file;

  ApiProvider() {
    ///DEV
     baseUrl = "https://devcargo.coderootz.com/api/v2/";
    /// LIVE
    //  baseUrl = "https://cargo.carsonlogistics.net/api/v2/";
    timeout = const Duration(minutes: 5);
    maxAuthRetries = 3;
    httpClient.addAuthenticator((Request<dynamic> request) async {
     // final dynamic token = "Bearer " + box.read("api_token");
      request.headers['Authorization'] = "$token";
      return request;
    });
    httpClient.addRequestModifier((Request<dynamic> request) {
  //    final token = box.read("api_token") ?? "no_token";
      request.headers['Authorization'] = "Bearer $token";
      request.headers['accept-encoding'] = acceptEncoding;
      request.headers['accept'] = accept;
      // request.headers['cache-control'] = noCache;
      return request;
    });
  }

  @override
  void onInit() {
    super.onInit();
    //token = "Bearer " + box.read("api_token");
  }

  Future<dynamic> getRequest(String endpoint) async {
    dynamic responseJson;
    try {
      final response = await get(
        baseUrl! + endpoint,
        headers: {
          'content-type': 'application/json; charset=UTF-8',
        },
      );
      responseJson = returnResponse(response);
    } on SocketException {
     // throw FetchDataException("internal server error");
    }
    return responseJson;
  }

  Future<dynamic> getRequestWithQueryParams(
      String endpoint, Map<String, dynamic> queryParameters) async {
    dynamic responseJson;
    try {
      final response = await get(
        baseUrl! + endpoint,
        query: queryParameters,
        headers: {
          'content-type': 'application/json; charset=UTF-8',
        },
      );
      responseJson = returnResponse(response);
    } on SocketException {
     // throw FetchDataException("internal server error");
    }
    return responseJson;
  }

  Future<dynamic> postRequest(String endpoint, Map<String, dynamic> map) async {
    dynamic responseJson;
    try {
      final response = await post(baseUrl! + endpoint, map,headers: {
        'content-type': 'application/json; charset=UTF-8',
      },);

      responseJson = returnResponse(response);
    } on TimeoutException {
      //throw FetchDataException('Request timed out');
    } on SocketException {
     // throw FetchDataException('no internet connection');
    }
    return responseJson;
  }

  Future<dynamic> putRequest(String endpoint, Map<String, dynamic> map) async {
    dynamic responseJson;
    try {
      final response = await put(baseUrl! + endpoint, map,
        headers: {
          'content-type': 'application/json; charset=UTF-8',
        },
      );
      responseJson = returnResponse(response);
    } on TimeoutException {
     // throw FetchDataException('Request timed out');
    } on SocketException {
      //throw FetchDataException('no internet connection');
    }
    return responseJson;
  }

  Future<dynamic> postRequestWithImages(String endpoint,
      Map<String, dynamic> data, List<Map<String, dynamic>> images) async {
    dynamic responseJson;
    try {
      FormData form = FormData({
        ...data,
      });

      for (var imageMap in images) {
        String key = imageMap['key'];
        File image = imageMap['file'];

        form.files.add(MapEntry(
            key, MultipartFile(image, filename: image.path.split('/').last)));
      }

      final response = await post(
        baseUrl! + endpoint,
        form
      );

      responseJson = returnResponse(response);
    } on TimeoutException {
      //throw FetchDataException('Request timed out');
    } on SocketException {
     // throw FetchDataException('No internet connection');
    }

    return responseJson;
  }

  // Future<Response> postRequestFromData(
  //     String endpoint, Map<String, dynamic> data, File file) async {
  //   dynamic responseJson;
  //   try {
  //     FormData form = FormData({
  //       'file': MultipartFile(file, filename: 'image.png'),
  //       ...data,
  //     });
  //    // 'otherFile': MultipartFile(back, filename: 'image.png'),
  //     // formData.files.add(MapEntry('qatar_id_accept_image_front',
  //     //     MultipartFile(idImageFront.absolute.path, filename: "")));
  //     // formData.files.add(MapEntry('qatar_id_accept_image_back',
  //     //     MultipartFile(idkImageBack.absolute.path, filename: "")));
  //     // formData = formData;
  //     final response = await post(
  //       baseUrl + endpoint,
  //       form,
  //
  //     );
  //     responseJson = returnResponse(response);
  //   } on TimeoutException {
  //     throw FetchDataException('Request timed out');
  //   } on SocketException {
  //     throw FetchDataException('no internet connection');
  //   }
  //   return responseJson;
  // }

  Future<dynamic> uploadImage(String endpoint, File? file) async {
    final form = FormData({
      'image': MultipartFile(file, filename: file!.path.split('/').last),
    });

    final response = await post(
      baseUrl! + endpoint,
      form,
    );
    return returnResponse(response);
  }

  dynamic returnResponse(Response response) {
    switch (response.statusCode) {
      case 200:
        var responseJson = json.decode(response.bodyString!);
        // final Response Function(Map<String, dynamic>) parser;
        // Map<String, dynamic> responseJson = jsonDecode(response.body);
       //  final jsonBody = json.decode(response.body);
        // var data = jsonBody["data"];
        return responseJson;
      case 400:
       // throw BadRequestException(response.hasError.toString());
      case 403:
       // throw UnauthorizedException(response.hasError.toString());
      case 404:
        //throw UnauthorizedException(response.hasError.toString());
      case 500:
      default:
       // throw FetchDataException("server error${response.statusCode}");
    }
  }
}
