import 'package:dio/dio.dart';
import 'package:mouser/file_transfer/data/models/pc_file_info.dart';
import 'package:retrofit/retrofit.dart';

part 'pc_transfer_service.g.dart';

@RestApi()
abstract class PCTransferService {
  factory PCTransferService(Dio dio) = _PCTransferService;

  @GET('/pc-transfer/browse')
  Future<PCBrowseResponse> browsePath(@Query('path') String? path);

  @POST('/pc-transfer/file-info')
  Future<PCFileInfoResponse> getFileInfo(@Body() Map<String, dynamic> request);

  @POST('/pc-transfer/download')
  Future<PCDownloadResponse> prepareDownload(@Body() Map<String, dynamic> request);

  @GET('/pc-transfer/quick-access')
  Future<QuickAccessResponse> getQuickAccessFolders();
}
