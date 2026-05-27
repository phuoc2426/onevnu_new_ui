import 'package:dio/dio.dart';
import 'package:vnu_core/data/api_reponse_domitory.dart';
import '../constants/config.dart';
import '../data/app_api.dart';
import '../globals.dart';
import '../models/model.dart';
import '../services/dio_options.dart';

class ApiDormitoryRepository {
  ApiDormitoryRepository._internal() {
    _dio = DioOptions().createDio(kBaseUrlDormitory);
    _apiClient = AppApiProvider(_dio);
  }

  static final ApiDormitoryRepository _singleton =
      ApiDormitoryRepository._internal();

  factory ApiDormitoryRepository() {
    return _singleton;
  }

  ///dio safe http client
  late Dio _dio;

  ///eCabinet api client
  late AppApiProvider _apiClient;

  void setToken(String token) {
    Globals().token = token;
    ApiDormitoryRepository._internal();
  }

  Future<APIResponseDomitory<ThongTinSinhVienModel>> getUserInfo(
    String CMND_CCCD,
  ) {
    return _apiClient.getUserInfo(CMND_CCCD);
  }

  void dispose() {
    this.dispose();
  }
}
