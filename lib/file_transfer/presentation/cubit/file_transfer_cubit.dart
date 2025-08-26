import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'file_transfer_state.dart';

class FileTransferCubit extends Cubit<FileTransferState> {
  FileTransferCubit() : super(FileTransferInitial());
}
