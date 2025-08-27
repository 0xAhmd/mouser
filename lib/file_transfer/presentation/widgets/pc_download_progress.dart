import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mouser/file_transfer/data/repo/pc_transfer_info_repo.dart';
import 'package:mouser/mouse/presentation/widgets/glass_card.dart';

class PCDownloadProgress extends StatelessWidget {
  final double progress;
  final bool isDownloading;
  final String? currentFile;
  final int currentIndex;
  final int totalFiles;
  final List<DownloadResult> downloadResults;

  const PCDownloadProgress({
    super.key,
    required this.progress,
    required this.isDownloading,
    this.currentFile,
    required this.currentIndex,
    required this.totalFiles,
    required this.downloadResults,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final successfulDownloads = downloadResults.where((r) => r.success).length;
    final failedDownloads = downloadResults.where((r) => !r.success).length;

    return Container(
      margin: EdgeInsets.all(16.w),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isDownloading ? Icons.download : Icons.check_circle,
                  size: 20.sp,
                  color:
                      isDownloading ? theme.colorScheme.primary : Colors.green,
                ),
                SizedBox(width: 8.w),
                Text(
                  isDownloading ? 'Downloading Files...' : 'Download Complete',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isDownloading)
                  SizedBox(
                    width: 16.sp,
                    height: 16.sp,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 16.h),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '$currentIndex of $totalFiles files',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                    minHeight: 8.h,
                  ),
                ),
                if (currentFile != null && isDownloading) ...[
                  SizedBox(height: 8.h),
                  Text(
                    'Downloading: $currentFile',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),

            // Results summary
            if (!isDownloading && downloadResults.isNotEmpty) ...[
              SizedBox(height: 16.h),

              // Success/failure summary
              Row(
                children: [
                  if (successfulDownloads > 0) ...[
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 12.sp, color: Colors.green),
                          SizedBox(width: 4.w),
                          Text(
                            '$successfulDownloads downloaded',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  if (failedDownloads > 0) ...[
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error, size: 12.sp, color: Colors.red),
                          SizedBox(width: 4.w),
                          Text(
                            '$failedDownloads failed',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: 12.h),

              // File results list
              Container(
                constraints: BoxConstraints(maxHeight: 150.h),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: downloadResults.length,
                  separatorBuilder: (context, index) => SizedBox(height: 4.h),
                  itemBuilder: (context, index) {
                    final result = downloadResults[index];
                    return _buildResultItem(result, theme);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(DownloadResult result, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: result.success
            ? Colors.green.withOpacity(0.05)
            : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: result.success
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            result.success ? Icons.check_circle : Icons.error,
            size: 16.sp,
            color: result.success ? Colors.green : Colors.red,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.fileName ?? 'Unknown file',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (result.success && result.fileSize != null)
                  Text(
                    result.formattedSize,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                if (!result.success && result.error != null)
                  Text(
                    result.error!,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
