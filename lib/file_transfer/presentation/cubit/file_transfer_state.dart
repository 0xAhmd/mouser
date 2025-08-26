part of 'file_transfer_cubit.dart';

sealed class FileTransferState extends Equatable {
  const FileTransferState();

  @override
  List<Object> get props => [];
}

final class FileTransferInitial extends FileTransferState {}
