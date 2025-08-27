import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mouser/file_transfer/presentation/cubit/pc_transfer_cubit.dart';
import 'package:mouser/file_transfer/presentation/cubit/pc_transfer_state.dart';
import 'package:mouser/file_transfer/presentation/widgets/pc_download_progress.dart';
import 'package:mouser/file_transfer/presentation/widgets/pc_file_browser.dart';
import 'package:mouser/file_transfer/presentation/widgets/pc_quick_access.dart';

import 'package:mouser/mouse/presentation/cubit/connecton_cubit.dart';
import 'package:mouser/mouse/presentation/cubit/connecton_state.dart';
import 'package:mouser/mouse/presentation/widgets/glass_card.dart';

class PCTransferPage extends StatefulWidget {
  const PCTransferPage({super.key});

  @override
  State<PCTransferPage> createState() => _PCTransferPageState();
}

class _PCTransferPageState extends State<PCTransferPage> {
  @override
  void initState() {
    super.initState();
    // Initialize PC transfer when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<PCTransferCubit>();
      if (context.read<ConnectionCubit>().state.isConnected) {
        cubit.loadQuickAccessFolders();
        cubit.browsePath(null); // Browse default path
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: BlocListener<PCTransferCubit, PCTransferState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              _showSnackBar(state.errorMessage!, Colors.red);
              context.read<PCTransferCubit>().clearError();
            }
            if (state.successMessage != null) {
              _showSnackBar(state.successMessage!, Colors.green);
              context.read<PCTransferCubit>().clearSuccess();
            }
          },
          child: Column(
            children: [
              // Header and connection status
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    _buildConnectionStatus(),
                    SizedBox(height: 16.h),
                    _buildSelectionInfo(),
                  ],
                ),
              ),
              
              // Main content
              Expanded(
                child: BlocBuilder<PCTransferCubit, PCTransferState>(
                  builder: (context, state) {
                    if (!context.watch<ConnectionCubit>().state.isConnected) {
                      return _buildNotConnectedView();
                    }

                    return Column(
                      children: [
                        // Quick access folders
                        if (state.quickAccessFolders.isNotEmpty) ...[
                          PCQuickAccess(
                            folders: state.quickAccessFolders,
                            onFolderTap: (folder) {
                              context.read<PCTransferCubit>().goToPath(folder.path);
                            },
                          ),
                          SizedBox(height: 8.h),
                        ],
                        
                        // File browser
                        Expanded(
                          child: PCFileBrowser(
                            currentPath: state.currentPath,
                            parentPath: state.parentPath,
                            directories: state.directories,
                            files: state.files,
                            selectedFiles: state.selectedFiles,
                            isLoading: state.isLoading,
                            onNavigateToParent: () {
                              context.read<PCTransferCubit>().goToParent();
                            },
                            onNavigateToDirectory: (directory) {
                              context.read<PCTransferCubit>().goToPath(directory.path);
                            },
                            onFileSelect: (file) {
                              context.read<PCTransferCubit>().selectFile(file);
                            },
                            onSelectAll: () {
                              context.read<PCTransferCubit>().selectAllDownloadableFiles();
                            },
                            onClearSelection: () {
                              context.read<PCTransferCubit>().clearSelection();
                            },
                            onRefresh: () {
                              context.read<PCTransferCubit>().browsePath(state.currentPath);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              // Download progress (when downloading)
              BlocBuilder<PCTransferCubit, PCTransferState>(
                builder: (context, state) {
                  if (state.status == PCTransferStatus.downloading || 
                      state.downloadResults.isNotEmpty) {
                    return PCDownloadProgress(
                      progress: state.downloadProgress,
                      isDownloading: state.status == PCTransferStatus.downloading,
                      currentFile: state.currentDownloadFile,
                      currentIndex: state.currentDownloadIndex,
                      totalFiles: state.totalDownloads,
                      downloadResults: state.downloadResults,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              // Download button
              _buildDownloadButton(),
            ],
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
                          ? 'Connected to PC'
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
              if (connectionState.isConnected)
                Icon(
                  Icons.download,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20.sp,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectionInfo() {
    return BlocBuilder<PCTransferCubit, PCTransferState>(
      builder: (context, state) {
        if (state.selectedFiles.isEmpty) {
          return const SizedBox.shrink();
        }

        return GlassCard(
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  state.selectedFilesInfo,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotConnectedView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 16.h),
            Text(
              'Not Connected to PC',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Connect to your PC first to browse and download files',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () {
                //TODO Navigate to connection page or show connection dialog
                // You can implement this based on your app's navigation
              },
              icon: Icon(Icons.settings, size: 20.sp),
              label: const Text('Go to Connection Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    return BlocBuilder<PCTransferCubit, PCTransferState>(
      builder: (context, state) {
        if (!context.watch<ConnectionCubit>().state.isConnected) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.all(16.w),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.canDownload
                  ? () {
                      context.read<PCTransferCubit>().downloadSelectedFiles();
                    }
                  : null,
              icon: state.status == PCTransferStatus.downloading
                  ? SizedBox(
                      width: 16.sp,
                      height: 16.sp,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.download, size: 20.sp),
              label: Text(
                state.status == PCTransferStatus.downloading
                    ? 'Downloading...'
                    : state.selectedFiles.isEmpty
                        ? 'Select Files to Download'
                        : 'Download ${state.selectedFiles.where((f) => f.canDownload).length} Files',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: state.canDownload
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}