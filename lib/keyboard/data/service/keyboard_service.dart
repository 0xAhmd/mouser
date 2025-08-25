import 'package:dio/dio.dart';
import 'package:mouser/keyboard/data/models/keyboard_request.dart';
import 'package:mouser/keyboard/data/models/keyboard_response.dart';
import 'package:retrofit/retrofit.dart';

part 'keyboard_service.g.dart';

@RestApi()
abstract class KeyboardService {
  factory KeyboardService(Dio dio) = _KeyboardService;

  @POST('/keyboard')
  Future<KeyboardResponse> sendKeyboardCommand(
    @Body() KeyboardRequest request,
  );
}