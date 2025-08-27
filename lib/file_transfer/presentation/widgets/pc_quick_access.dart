import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mouser/file_transfer/data/models/pc_file_info.dart';

class PCQuickAccess extends StatelessWidget {
  final List<QuickAccessFolder> folders;
  final Function(QuickAccessFolder) onFolderTap;

  const PCQuickAccess({
    super.key,
    required this.folders,
    required this.onFolderTap,
  });

  IconData _getFolderIcon(String folderName) {
    switch (folderName.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'desktop':
        return Icons.desktop_mac;
      case 'documents':
        return Icons.description;
      case 'downloads':
        return Icons.download;
      case 'pictures':
        return Icons.photo_library;
      case 'videos':
        return Icons.video_library;
      case 'music':
        return Icons.library_music;
      default:
        return Icons.folder;
    }
  }

  Color _getFolderColor(String folderName) {
    switch (folderName.toLowerCase()) {
      case 'home':
        return Colors.blue;
      case 'desktop':
        return Colors.purple;
      case 'documents':
        return Colors.indigo;
      case 'downloads':
        return Colors.green;
      case 'pictures':
        return Colors.pink;
      case 'videos':
        return Colors.red;
      case 'music':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibleFolders = folders.where((f) => f.accessible).toList();

    if (accessibleFolders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 100.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
            child: Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: accessibleFolders.length,
              itemBuilder: (context, index) {
                final folder = accessibleFolders[index];
                return _buildQuickAccessItem(folder, context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessItem(QuickAccessFolder folder, BuildContext context) {
    final theme = Theme.of(context);
    final folderColor = _getFolderColor(folder.name);

    return Container(
      width: 80.w,
      margin: EdgeInsets.only(right: 12.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onFolderTap(folder),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36.sp,
                  height: 36.sp,
                  decoration: BoxDecoration(
                    color: folderColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    _getFolderIcon(folder.name),
                    size: 20.sp,
                    color: folderColor,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  folder.name,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (folder.fileCount > 0 || folder.dirCount > 0) ...[
                  SizedBox(height: 2.h),
                  Text(
                    '${folder.fileCount + folder.dirCount} items',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
