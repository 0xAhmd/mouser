import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mouser/file_transfer/data/models/file_transfer_response.dart';
import 'package:mouser/mouse/presentation/widgets/glass_card.dart';

class UploadProgressWidget extends StatelessWidget {
  final double progress;
  final bool isUploading;
  final List<UploadedFile> uploadedFiles;
  final List<SkippedFile> skippedFiles;

  const UploadProgressWidget({
    super.key,
    required this.progress,
    required this.isUploading,
    required this.uploadedFiles,
    required this.skippedFiles,
  });

  String _formatFileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${units[unitIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUploading ? 'Uploading Files...' : 'Upload Complete',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          
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
                  if (isUploading)
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
            ],
          ),
          
          if (!isUploading && (uploadedFiles.isNotEmpty || skippedFiles.isNotEmpty)) ...[
            SizedBox(height: 16.h),
            
            // Success summary
            if (uploadedFiles.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Successfully Uploaded (${uploadedFiles.length})',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ...uploadedFiles.take(3).map((file) => Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Row(
                        children: [
                          Icon(Icons.file_present, size: 14.sp, color: Colors.green),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              file.originalName,
                              style: TextStyle(fontSize: 12.sp),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatFileSize(file.size),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (uploadedFiles.length > 3)
                      Text(
                        '... and ${uploadedFiles.length - 3} more',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontStyle: FontStyle.italic,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
            ],
            
            // Skipped files summary
            if (skippedFiles.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Skipped Files (${skippedFiles.length})',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ...skippedFiles.take(3).map((file) => Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Row(
                        children: [
                          Icon(Icons.block, size: 14.sp, color: Colors.orange),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.filename,
                                  style: TextStyle(fontSize: 12.sp),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  file.reason,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.orange,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (skippedFiles.length > 3)
                      Text(
                        '... and ${skippedFiles.length - 3} more',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontStyle: FontStyle.italic,
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
