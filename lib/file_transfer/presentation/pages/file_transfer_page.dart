import 'dart:io';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mouser/file_transfer/presentation/cubit/file_transfer_cubit.dart';
import 'package:mouser/file_transfer/presentation/cubit/file_transfer_state.dart';
import 'package:mouser/file_transfer/presentation/widgets/directory_selector.dart';
import 'package:mouser/file_transfer/presentation/widgets/file_list_widget.dart';
import 'package:mouser/file_transfer/presentation/widgets/transfer_status_card.dart';
import 'package:mouser/file_transfer/presentation/widgets/upload_progress_widget.dart';
import 'package:mouser/mouse/presentation/cubit/connecton_cubit.dart';
import 'package:mouser/mouse/presentation/cubit/connecton_state.dart';
import 'package:mouser/mouse/presentation/widgets/glass_card.dart';

class FileTransferPage extends StatefulWidget {
  const FileTransferPage({super.key});

  @override
  State<FileTransferPage> createState() => _FileTransferPageState();
}

class _FileTransferPageState extends State<FileTransferPage> {
  @override
  void initState() {
    super.initState();
    // Initialize file transfer when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<FileTransferCubit>();
      if (cubit.state.isConnected) {
        cubit.loadTransferStatus();
        cubit.loadAvailableDirectories();
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: 14.sp),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final files = result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();

        if (files.isNotEmpty) {
          context.read<FileTransferCubit>().addFiles(files);
          _showSnackBar(
            'Added ${files.length} file${files.length == 1 ? '' : 's'}',
            Colors.green,
          );
        }
      }
    } catch (e) {
      _showSnackBar('Error picking files: $e', Colors.red);
    }
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );

      if (result != null && result.files.isNotEmpty) {
        final files = result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();

        if (files.isNotEmpty) {
          context.read<FileTransferCubit>().addFiles(files);
          _showSnackBar(
            'Added ${files.length} image${files.length == 1 ? '' : 's'}',
            Colors.green,
          );
        }
      }
    } catch (e) {
      _showSnackBar('Error picking images: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: BlocListener<FileTransferCubit, FileTransferState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              _showSnackBar(state.errorMessage!, Colors.red);
              context.read<FileTransferCubit>().clearError();
            }
            if (state.successMessage != null) {
              _showSnackBar(state.successMessage!, Colors.green);
              context.read<FileTransferCubit>().clearSuccess();
            }
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConnectionStatus(),
                SizedBox(height: 16.h),
                _buildTransferStatus(),
                SizedBox(height: 16.h),
                _buildFileSelection(),
                SizedBox(height: 16.h),
                _buildSelectedFiles(),
                SizedBox(height: 16.h),
                _buildDirectorySelection(),
                SizedBox(height: 16.h),
                _buildUploadSection(),
                SizedBox(height: 16.h),
                _buildUploadProgress(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return BlocBuilder<ConnectionCubit, ConnectionState>(
      builder: (context, connectionState) {
        return GlassCard(
          child: Row(
            children: [
              Icon(
                connectionState.isConnected ? Icons.wifi : Icons.wifi_off,
                color: connectionState.isConnected ? Colors.green : Colors.red,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connectionState.isConnected
                          ? 'Connected'
                          : 'Not Connected',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (connectionState.isConnected)
                      Text(
                        connectionState.serverIP,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDirectorySelection() {
    return BlocBuilder<FileTransferCubit, FileTransferState>(
      builder: (context, state) {
        if (!state.isConnected) {
          return const SizedBox.shrink();
        }

        return DirectorySelector(
          availableDirectories: state.availableDirectories,
          selectedDirectory: state.selectedDirectory,
          isLoading: state.directoryStatus == DirectoryStatus.loading,
          onDirectorySelected: (directory) {
            context.read<FileTransferCubit>().selectDirectory(directory);
          },
          onRefreshDirectories: () {
            context.read<FileTransferCubit>().loadAvailableDirectories();
          },
          onCreateDirectory: (path) {
            context.read<FileTransferCubit>().createDirectory(path);
          },
        );
      },
    );
  }

  Widget _buildUploadSection() {
    return BlocBuilder<FileTransferCubit, FileTransferState>(
      builder: (context, state) {
        final theme = Theme.of(context);

        if (!state.isConnected) {
          return const SizedBox.shrink();
        }

        final canUpload = state.canUpload;
        final isUploading = state.isUploading;

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Files',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),

              // Upload info
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16.sp,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Upload Details',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Files: ${state.selectedFilesInfo}',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    Text(
                      'Destination: ${state.selectedDirectoryInfo}',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    if (state.diskSpaceInfo != null)
                      Text(
                        state.diskSpaceInfo! as String,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Upload button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canUpload && !isUploading
                      ? () {
                          context.read<FileTransferCubit>().uploadFiles();
                        }
                      : null,
                  icon: isUploading
                      ? SizedBox(
                          width: 16.sp,
                          height: 16.sp,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.cloud_upload, size: 20.sp),
                  label: Text(
                    isUploading ? 'Uploading...' : 'Upload Files',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),

              if (!canUpload && !isUploading) ...[
                SizedBox(height: 8.h),
                Text(
                  _getUploadDisabledReason(state),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadProgress() {
    return BlocBuilder<FileTransferCubit, FileTransferState>(
      builder: (context, state) {
        if (!state.isConnected ||
            (state.status != FileTransferStatus.uploading &&
                state.uploadProgress == 0.0)) {
          return const SizedBox.shrink();
        }

        return UploadProgressWidget(
          progress: state.uploadProgress,
          isUploading: state.isUploading,
          uploadedFiles: state.lastUploadedFiles,
          skippedFiles: state.lastSkippedFiles,
        );
      },
    );
  }

  Widget _buildTransferStatus() {
    return BlocBuilder<FileTransferCubit, FileTransferState>(
      builder: (context, state) {
        if (!state.isConnected) {
          return const SizedBox.shrink();
        }

        return TransferStatusCard(
          transferStatus: state.transferStatus,
          diskSpaceInfo: state.diskSpaceInfo,
          onRefresh: () {
            context.read<FileTransferCubit>().loadTransferStatus();
            if (state.selectedDirectory != null) {
              context
                  .read<FileTransferCubit>()
                  .loadDiskSpace(state.selectedDirectory!.path);
            }
          },
        );
      },
    );
  }

  Widget _buildFileSelection() {
    return BlocBuilder<ConnectionCubit, ConnectionState>(
      builder: (context, connectionState) {
        final theme = Theme.of(context);

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Files',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          connectionState.isConnected ? _pickFiles : null,
                      icon: Icon(Icons.file_upload, size: 20.sp),
                      label: Text(
                        'Pick Files',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          connectionState.isConnected ? _pickImages : null,
                      icon: Icon(Icons.image, size: 20.sp),
                      label: Text(
                        'Pick Images',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              BlocBuilder<FileTransferCubit, FileTransferState>(
                builder: (context, state) {
                  return Text(
                    state.selectedFilesInfo,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedFiles() {
    return BlocBuilder<FileTransferCubit, FileTransferState>(
      builder: (context, state) {
        if (!state.hasFiles) {
          return const SizedBox.shrink();
        }

        return FileListWidget(
          files: state.selectedFiles,
          onRemoveFile: (file) {
            context.read<FileTransferCubit>().removeFile(file);
          },
          onClearAll: () {
            context.read<FileTransferCubit>().clearFiles();
          },
        );
      },
    );
  }

  String _getUploadDisabledReason(FileTransferState state) {
    if (!state.isConnected) return 'Not connected to server';
    if (state.selectedFiles.isEmpty) return 'No files selected';
    if (state.selectedDirectory == null) {
      return 'No destination directory selected';
    }
    if (state.isUploading) return 'Upload in progress';
    return 'Ready to upload';
  }
}
