import 'dart:async';
import 'dart:convert';

import 'dart:io';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:get/get_connect/http/src/request/request.dart';

import '../global/global.dart';
import 'package:http/http.dart' as http;
 import 'package:dio/dio.dart' show FormData, Dio, DioException, Options,MultipartFile,IOHttpClientAdapter;

class ApiProvider extends GetConnect {
  final String acceptEncoding = 'gzip, deflate';
  final String accept = '*/*';
  final String noCache = 'no-cache';
  File? file;
  final String devBaseUrl = "https://dev.zyppy.qa/api/v1/";
  final String liveBaseUrl = "https://zyppy.qa/api/v1/";
  

  ApiProvider() {
    timeout = const Duration(seconds: 120);
    maxAuthRetries = 3;

    if (kDebugMode) {
      baseUrl = devBaseUrl;
    } else if (kReleaseMode) {
      baseUrl = liveBaseUrl;
    }

    httpClient.addAuthenticator((Request<dynamic> request) async {
    final dynamic token = "Bearer "+box.read(apiKeys.apiToken);
      request.headers['Authorization'] = "$token";
      return request;
    });
    httpClient.addRequestModifier((Request<dynamic> request) {
      request.headers['accept-encoding'] = acceptEncoding;
      request.headers['accept'] = accept;
      request.headers.remove('content-length');
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
      final response = await post(endpoint, jsonEncode(map),headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': '*/*',
        'Accept-Encoding': 'gzip, deflate',
        'Connection': 'keep-alive',
      });

      responseJson = returnResponse(response);
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
    } on TimeoutException {
      //throw FetchDataException('Request timed out');
    } on SocketException {
     // throw FetchDataException('no internet connection');
    }catch(e){
      if (kDebugMode) {
        print(e.toString());
      }
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

  // Future<dynamic> postRequestWithImages(String endpoint,
  //     Map<String, dynamic> data, List<Map<String, dynamic>>? images) async {
  //   dynamic responseJson;
  //   try {
  //     FormData form = FormData({
  //       ...data,
  //     });

  //     if(images!.isNotEmpty) {
  //     for (var imageMap in images) {
  //       String key = imageMap['key'];
  //       File image = imageMap['file'];

  //       form.files.add(MapEntry(
  //           key, MultipartFile(image, filename: image.path.split('/').last)));
  //     }
  //     }

  //     final response = await post(endpoint,
  //       form
  //     );

  //     responseJson = returnResponse(response);
  //     print(responseJson);
  //   } on TimeoutException {
  //     //throw FetchDataException('Request timed out');
  //   } on SocketException {
  //    // throw FetchDataException('No internet connection');
  //   }

  //   return responseJson;
  // }





Future<dynamic> postRequestWithImages(
  String endpoint,
  Map<String, dynamic> data, 
  List<Map<String, dynamic>>? images,
) async {
  try {

    var request = http.MultipartRequest('POST', Uri.parse("$baseUrl$endpoint"));
      dynamic responseJson;

    data.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    if (images != null && images.isNotEmpty) {
      for (final imageMap in images) {
        final String key = imageMap['key'];
        final File image = imageMap['file'];
        
        if (await image.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            key,
            image.path,
            filename: image.path.split('/').last,
          ));
        }
      }
    }

    print('🚀 Making POST request to: $endpoint');
    
    // Send request
   // Send request
    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    
    // Convert streamed response to regular response
    final response = await http.Response.fromStream(streamedResponse);
    
    print('✅ Request successful: ${response.statusCode}');
    
    responseJson = returnHttpResponse(response);
    return responseJson;

  } on TimeoutException catch (e) {
    print('❌ Request timed out: $e');
    throw Exception('Request timed out');
  } catch (e) {
    print('❌ Error: $e');
    throw Exception('Request failed: $e');
  }
}

dynamic returnHttpResponse(http.Response response) {
  print('📡 Response status: ${response.statusCode}');
  print('📡 Response body: ${response.body}');
  
  switch (response.statusCode) {
    case 200:
    case 201:
      try {
        var responseJson = json.decode(response.body);
        print('✅ Success response: $responseJson');
        return responseJson;
      } catch (e) {
        print('❌ JSON decode error: $e');
        return {'success': true, 'message': 'Request successful', 'data': response.body};
      }
    case 400:
      throw Exception('Bad Request: ${response.body}');
    case 401:
      throw Exception('Unauthorized: ${response.body}');
    case 403:
      throw Exception('Forbidden: ${response.body}');
    case 404:
      throw Exception('Not Found: ${response.body}');
    case 500:
      throw Exception('Internal Server Error: ${response.body}');
    default:
      throw Exception('Error occurred with status code: ${response.statusCode}');
  }
}


   

Future<dynamic> postRequestWithImagesDio(
  String endpoint,
  Map<String, dynamic> data, 
  List<Map<String, dynamic>>? images,
) async {
  try {
    // Create FormData using dio's fromMap method
    final form = FormData.fromMap(data);

    if (images != null && images.isNotEmpty) {
      for (final imageMap in images) {
        final String key = imageMap['key'];
        final File image = imageMap['file'];
        
        if (await image.exists()) {
          form.files.add(MapEntry(
            key, 
            await MultipartFile.fromFile(
              image.path,
              filename: image.path.split('/').last,
            ),
          ));
        }
      }
    }

    print('🚀 Making POST request to: $endpoint');
    
    // Use Dio for the request
    final dio = Dio();
    
    // Bypass SSL for development
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final HttpClient client = HttpClient();
      client.badCertificateCallback = 
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    final response = await dio.post(
      endpoint,
      data: form,
      options: Options(
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    print('✅ Request successful: ${response.statusCode}');
    return response.data;

  } on DioException catch (e) {
    print('❌ Dio Error: ${e.type} - ${e.message}');
    throw Exception('Request failed: ${e.message}');
  } catch (e) {
    print('❌ Error: $e');
    throw Exception('Request failed: $e');
  }
}

 

  // Future<dynamic> uploadImage(String endpoint, File? file) async {
  //   final form = FormData({
  //     'image': MultipartFile(file, filename: file!.path.split('/').last),
  //   });

  //   final response = await post(endpoint,
  //     form,
  //   );
  //   return returnResponse(response);
  // }



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
