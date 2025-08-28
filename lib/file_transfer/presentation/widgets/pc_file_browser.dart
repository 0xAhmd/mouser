import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mouser/file_transfer/data/models/pc_file_info.dart';
import 'package:mouser/mouse/presentation/widgets/glass_card.dart';

class PCFileBrowser extends StatelessWidget {
  final String? currentPath;
  final String? parentPath;
  final List<PCFileInfo> directories;
  final List<PCFileInfo> files;
  final List<PCFileInfo> selectedFiles;
  final bool isLoading;
  final VoidCallback onNavigateToParent;
  final Function(PCFileInfo) onNavigateToDirectory;
  final Function(PCFileInfo) onFileSelect;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onRefresh;

  const PCFileBrowser({
    super.key,
    this.currentPath,
    this.parentPath,
    required this.directories,
    required this.files,
    required this.selectedFiles,
    required this.isLoading,
    required this.onNavigateToParent,
    required this.onNavigateToDirectory,
    required this.onFileSelect,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onRefresh,
  });

  IconData _getFileIcon(String? extension) {
    if (extension == null) return Icons.insert_drive_file;

    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
      case 'svg':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
        return Icons.audio_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip;
      case 'txt':
      case 'log':
        return Icons.text_snippet;
      case 'json':
      case 'xml':
      case 'csv':
        return Icons.code;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(PCFileInfo file, BuildContext context) {
    final theme = Theme.of(context);

    if (!file.isFile) return theme.colorScheme.primary;

    if (!file.canDownload) {
      return Colors.grey;
    }

    switch (file.extension?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
      case 'svg':
        return Colors.blue;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Colors.red;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
        return Colors.green;
      case 'pdf':
        return Colors.redAccent;
      case 'doc':
      case 'docx':
        return Colors.blueAccent;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.orange;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloadableFiles = files.where((f) => f.canDownload).length;
    final totalFiles = files.length;

    return Column(
      children: [
        // Path and controls
        SizedBox(height: 4.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: GlassCard(
            child: Column(
              children: [
                // Current path
                Row(
                  children: [
                    Icon(Icons.folder,
                        size: 20.sp, color: theme.colorScheme.primary),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        currentPath ?? 'Home',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (parentPath != null && parentPath != currentPath)
                      IconButton(
                        onPressed: onNavigateToParent,
                        icon: Icon(Icons.arrow_upward, size: 20.sp),
                        tooltip: 'Go up',
                      ),
                    IconButton(
                      onPressed: isLoading ? null : onRefresh,
                      icon: isLoading
                          ? SizedBox(
                              width: 16.sp,
                              height: 16.sp,
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : Icon(Icons.refresh, size: 20.sp),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),

                // File selection controls
                if (totalFiles > 0) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Text(
                        '$totalFiles file${totalFiles == 1 ? '' : 's'} ($downloadableFiles downloadable)',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const Spacer(),
                      if (downloadableFiles > 0) ...[
                        TextButton(
                          onPressed: onSelectAll,
                          child: Text(
                            'Select All',
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        ),
                        SizedBox(width: 8.w),
                      ],
                      if (selectedFiles.isNotEmpty)
                        TextButton(
                          onPressed: onClearSelection,
                          child: Text(
                            'Clear',
                            style:
                                TextStyle(fontSize: 12.sp, color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        SizedBox(height: 12.h),

        // File list
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : directories.isEmpty && files.isEmpty
                  ? _buildEmptyView()
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: directories.length + files.length,
                      itemBuilder: (context, index) {
                        if (index < directories.length) {
                          return _buildDirectoryItem(
                              directories[index], context);
                        } else {
                          final fileIndex = index - directories.length;
                          return _buildFileItem(files[fileIndex], context);
                        }
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 16.h),
            Text(
              'Empty Folder',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'This folder contains no files or directories',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectoryItem(PCFileInfo directory, BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onNavigateToDirectory(directory),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder,
                  size: 32.sp,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        directory.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        directory.modified.split('T').first,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 24.sp,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileItem(PCFileInfo file, BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selectedFiles.contains(file);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: file.isFile ? () => onFileSelect(file) : null,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 2.w : 1.w,
              ),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Icon(
                      _getFileIcon(file.extension),
                      size: 32.sp,
                      color: _getFileIconColor(file, context),
                    ),
                    if (isSelected)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 16.sp,
                          height: 16.sp,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 10.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: file.canDownload ? null : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          if (file.sizeFormatted != null) ...[
                            Text(
                              file.sizeFormatted!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                            SizedBox(width: 8.w),
                          ],
                          Text(
                            file.modified.split('T').first,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      if (!file.canDownload && file.skipReason != null) ...[
                        SizedBox(height: 4.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            file.skipReason!,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (file.canDownload)
                  Icon(
                    Icons.download,
                    size: 20.sp,
                    color: isSelected ? theme.colorScheme.primary : Colors.grey,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
