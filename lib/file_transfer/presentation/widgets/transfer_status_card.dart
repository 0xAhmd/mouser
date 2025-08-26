
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mouser/file_transfer/data/models/disk_space_info.dart';
import 'package:mouser/file_transfer/data/models/transfer_status.dart';
import 'package:mouser/mouse/presentation/widgets/glass_card.dart';

class TransferStatusCard extends StatelessWidget {
  final TransferStatus? transferStatus;
  final DiskSpaceInfo? diskSpaceInfo;
  final VoidCallback? onRefresh;

  const TransferStatusCard({
    super.key,
    this.transferStatus,
    this.diskSpaceInfo,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transfer Status',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  onPressed: onRefresh,
                  icon: Icon(Icons.refresh, size: 20.sp),
                  tooltip: 'Refresh status',
                ),
            ],
          ),
          SizedBox(height: 12.h),
          
          if (transferStatus != null) ...[
            // Server info
            _buildInfoRow(
              icon: Icons.cloud_done,
              label: 'Server Status',
              value: transferStatus!.status == 'active' ? 'Active' : 'Inactive',
              valueColor: transferStatus!.status == 'active' ? Colors.green : Colors.red,
            ),
            
            _buildInfoRow(
              icon: Icons.info,
              label: 'Version',
              value: transferStatus!.version,
            ),
            
            _buildInfoRow(
              icon: Icons.file_upload,
              label: 'Max File Size',
              value: transferStatus!.maxFileSize,
            ),
            
            // Supported file types
            SizedBox(height: 8.h),
            Text(
              'Supported File Types:',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Wrap(
              spacing: 4.w,
              runSpacing: 4.h,
              children: transferStatus!.allowedExtensions.take(10).map((ext) => 
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '.$ext',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ).toList(),
            ),
            if (transferStatus!.allowedExtensions.length > 10)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  '... and ${transferStatus!.allowedExtensions.length - 10} more',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
          ] else ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Unable to load transfer status. Check connection.',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Disk space info
          if (diskSpaceInfo != null) ...[
            SizedBox(height: 12.h),
            Divider(color: theme.colorScheme.outline.withOpacity(0.3)),
            SizedBox(height: 8.h),
            
            Text(
              'Disk Space',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            
            // Disk usage bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Free: ${diskSpaceInfo!.freeGb.toStringAsFixed(1)} GB',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    Text(
                      'Total: ${diskSpaceInfo!.totalGb.toStringAsFixed(1)} GB',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: diskSpaceInfo!.usagePercent / 100,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      diskSpaceInfo!.usagePercent > 90 
                          ? Colors.red 
                          : diskSpaceInfo!.usagePercent > 75 
                              ? Colors.orange 
                              : Colors.green,
                    ),
                    minHeight: 6.h,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${diskSpaceInfo!.usagePercent.toStringAsFixed(1)}% used',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: Colors.grey),
          SizedBox(width: 8.w),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}