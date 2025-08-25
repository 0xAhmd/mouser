import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../constants/api_constants.dart';

part 'api_client.g.dart';

@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  @GET(ApiConstants.pingEndpoint)
  Future<HttpResponse<void>> ping();

  @POST(ApiConstants.mouseEndpoint)
  Future<HttpResponse<void>> sendMouseCommand(
    @Body() Map<String, dynamic> command,
  );
}
