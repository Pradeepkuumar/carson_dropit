import 'dart:async';
import 'dart:convert';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/request/request.dart';

import '../global/global.dart';

class ApiProvider extends GetConnect {
  final String acceptEncoding = 'gzip, deflate';
  final String accept = '*/*';
  final String noCache = 'no-cache';
  File? file;

  ApiProvider() {
    timeout = const Duration(minutes: 5);
    maxAuthRetries = 3;
    if (kDebugMode) {
      baseUrl = "https://dev.zyppy.qa/api/v1/";
    } else if (kReleaseMode) {
      baseUrl = "https://dev.zyppy.qa/api/v1/";
    }
    httpClient.addAuthenticator((Request<dynamic> request) async {
    final dynamic token = "Bearer "+box.read(apiKeys.apiToken);
      request.headers['Authorization'] = "$token";
      return request;
    });
    httpClient.addRequestModifier((Request<dynamic> request) {
      request.headers['accept-encoding'] = acceptEncoding;
      request.headers['accept'] = accept;
      return request;
    });
  }


  Future<dynamic> getRequest(String endpoint) async {
    dynamic responseJson;
    try {
      final response = await get(endpoint,
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
      final response = await get(endpoint,
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
      final response = await post(endpoint, map,headers: {
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
      final response = await put(endpoint, map,
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

      final response = await post(endpoint,
        form
      );

      responseJson = returnResponse(response);
      print(responseJson);
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

    final response = await post(endpoint,
      form,
    );
    return returnResponse(response);
  }



  dynamic returnResponse(Response response) {
    switch (response.statusCode) {
      case 200:
        var responseJson = json.decode(response.bodyString!);
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
