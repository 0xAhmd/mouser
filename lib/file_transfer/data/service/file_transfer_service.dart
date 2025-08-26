import 'package:dio/dio.dart';
import 'package:mouser/file_transfer/data/models/directory_info.dart';
import 'package:mouser/file_transfer/data/models/file_transfer_request.dart';
import 'package:mouser/file_transfer/data/models/file_transfer_response.dart';
import 'package:mouser/file_transfer/data/models/transfer_status.dart';
import 'package:mouser/file_transfer/data/models/disk_space_info.dart';
import 'package:retrofit/retrofit.dart';

part 'file_transfer_service.g.dart';

@RestApi()
abstract class FileTransferService {
  factory FileTransferService(Dio dio) = _FileTransferService;

  @POST('/file-transfer/upload')
  @MultiPart()
  Future<FileTransferResponse> uploadFiles(
    @Part(name: "target_directory") String? targetDirectory,
    @Part(name: "files") List<MultipartFile> files,
  );

  @GET('/file-transfer/directories')
  Future<DirectoriesResponse> getDirectories();

  @POST('/file-transfer/create-directory')
  Future<FileTransferResponse> createDirectory(
    @Body() FileTransferRequest request,
  );

  @GET('/file-transfer/status')
  Future<TransferStatus> getTransferStatus();

  @GET('/file-transfer/disk-space')
  Future<DiskSpaceInfo> getDiskSpace(
    @Query('directory') String? directory,
  );
}