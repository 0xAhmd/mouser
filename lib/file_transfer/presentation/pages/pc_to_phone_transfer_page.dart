import 'package:flutter/foundation.dart';
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
import 'package:mouser/settings/settings_page.dart';

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

  void _showDebugDialog() {
    final cubit = context.read<PCTransferCubit>();
    final state = cubit.state;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Selected Files: ${state.selectedFiles.length}'),
                Text('Can Download: ${state.canDownload}'),
                Text('Status: ${state.status}'),
                const SizedBox(height: 16),
                const Text('Selected Files Details:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...state.selectedFiles.map((file) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ${file.name}'),
                          Text('  Downloadable: ${file.downloadable}'),
                          Text('  Can Download: ${file.canDownload}'),
                          if (file.skipReason != null)
                            Text('  Skip Reason: ${file.skipReason}'),
                        ],
                      ),
                    ))
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              cubit.debugSelection();
              Navigator.of(context).pop();
            },
            child: const Text('Print to Console'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('PC Transfer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Debug button (only show in debug mode)
          if (kDebugMode)
            IconButton(
              onPressed: _showDebugDialog,
              icon: const Icon(Icons.bug_report),
              tooltip: 'Debug Info',
            ),
        ],
      ),
      body: BlocListener<PCTransferCubit, PCTransferState>(
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
            // Connection status - Fixed at top
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
              child: _buildConnectionStatus(),
            ),

            // Main scrollable content
            Expanded(
              child: BlocBuilder<PCTransferCubit, PCTransferState>(
                builder: (context, state) {
                  if (!context.watch<ConnectionCubit>().state.isConnected) {
                    return _buildNotConnectedView();
                  }

                  return CustomScrollView(
                    slivers: [
                      // Selection info (when files are selected)
                      if (state.selectedFiles.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                            child: _buildSelectionInfo(),
                          ),
                        ),

                      // Download progress (when downloading/completed)
                      if (state.status == PCTransferStatus.downloading ||
                          state.downloadResults.isNotEmpty)
                        SliverToBoxAdapter(
                          child: PCDownloadProgress(
                            progress: state.downloadProgress,
                            isDownloading:
                                state.status == PCTransferStatus.downloading,
                            currentFile: state.currentDownloadFile,
                            currentIndex: state.currentDownloadIndex,
                            totalFiles: state.totalDownloads,
                            downloadResults: state.downloadResults,
                          ),
                        ),

                      // Quick access folders
                      if (state.quickAccessFolders.isNotEmpty)
                        SliverToBoxAdapter(
                          child: PCQuickAccess(
                            folders: state.quickAccessFolders,
                            onFolderTap: (folder) {
                              context
                                  .read<PCTransferCubit>()
                                  .goToPath(folder.path);
                            },
                          ),
                        ),

                      // File browser
                      SliverFillRemaining(
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
                            context
                                .read<PCTransferCubit>()
                                .goToPath(directory.path);
                          },
                          onFileSelect: (file) {
                            context.read<PCTransferCubit>().selectFile(file);
                          },
                          onSelectAll: () {
                            context
                                .read<PCTransferCubit>()
                                .selectAllDownloadableFiles();
                          },
                          onClearSelection: () {
                            context.read<PCTransferCubit>().clearSelection();
                          },
                          onRefresh: () {
                            context
                                .read<PCTransferCubit>()
                                .browsePath(state.currentPath);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Fixed bottom button
            SafeArea(
              top: false,
              child: _buildDownloadButton(),
            ),
          ],
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
            // Settings button
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
                size: 24.sp,
              ),
              tooltip: 'Settings',
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

        final downloadableCount =
            state.selectedFiles.where((f) => f.canDownload).length;
        final hasNonDownloadable =
            downloadableCount < state.selectedFiles.length;

        return GlassCard(
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        state.selectedFilesInfo,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Show warning if some files can't be downloaded
                if (hasNonDownloadable) ...[
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange,
                          size: 14.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '${state.selectedFiles.length - downloadableCount} files cannot be downloaded',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.orange[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 16.h),
            Text(
              'Not Connected to PC',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Connect to your PC first to browse and download files',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
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

        final downloadableCount =
            state.selectedFiles.where((f) => f.canDownload).length;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Debug info (only in debug mode)
              if (kDebugMode && state.selectedFiles.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 14.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Debug: ${state.selectedFiles.length} selected, $downloadableCount downloadable, canDownload: ${state.canDownload}',
                          style: TextStyle(
                              fontSize: 10.sp, color: Colors.blue[800]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
              ],

              // Download button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton.icon(
                  onPressed: state.canDownload
                      ? () {
                          context
                              .read<PCTransferCubit>()
                              .downloadSelectedFiles();
                        }
                      : null,
                  icon: state.status == PCTransferStatus.downloading
                      ? SizedBox(
                          width: 14.sp,
                          height: 14.sp,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.download, size: 18.sp),
                  label: Flexible(
                    child: Text(
                      state.status == PCTransferStatus.downloading
                          ? 'Downloading...'
                          : state.selectedFiles.isEmpty
                              ? 'Select Files to Download'
                              : downloadableCount == 0
                                  ? 'No Files Available for Download'
                                  : 'Download $downloadableCount File${downloadableCount == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.canDownload
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
