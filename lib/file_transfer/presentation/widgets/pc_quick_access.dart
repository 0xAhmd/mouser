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
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          SizedBox(
            height: 92.h, // Fixed height that accommodates content
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
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
      width: 90.w, // Slightly reduced width to prevent overflow
      margin: EdgeInsets.only(right: 8.w), // Reduced margin
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onFolderTap(folder),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(6.w), // Reduced padding
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon container
                Container(
                  width: 32.sp, // Slightly smaller
                  height: 32.sp,
                  decoration: BoxDecoration(
                    color: folderColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    _getFolderIcon(folder.name),
                    size: 18.sp, // Slightly smaller
                    color: folderColor,
                  ),
                ),

                SizedBox(height: 6.h), // Reduced spacing

                // Folder name - with proper text overflow handling
                Flexible(
                  child: Text(
                    folder.name,
                    style: TextStyle(
                      fontSize: 10.sp, // Slightly smaller
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Item count - only show if there are items and space allows
                if (folder.fileCount > 0 || folder.dirCount > 0) ...[
                  SizedBox(height: 2.h),
                  Flexible(
                    child: Text(
                      '${folder.fileCount + folder.dirCount} items',
                      style: TextStyle(
                        fontSize: 8.sp, // Smaller font
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
