import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mouser/file_transfer/data/models/directory_info.dart';
import 'package:mouser/mouse/presentation/widgets/glass_card.dart';

class DirectorySelector extends StatelessWidget {
  final List<DirectoryInfo> availableDirectories;
  final DirectoryInfo? selectedDirectory;
  final bool isLoading;
  final Function(DirectoryInfo) onDirectorySelected;
  final VoidCallback onRefreshDirectories;
  final Function(String) onCreateDirectory;

  const DirectorySelector({
    super.key,
    required this.availableDirectories,
    required this.selectedDirectory,
    required this.isLoading,
    required this.onDirectorySelected,
    required this.onRefreshDirectories,
    required this.onCreateDirectory,
  });

  void _showCreateDirectoryDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Create Directory',
          style: TextStyle(fontSize: 18.sp),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter directory path',
            labelText: 'Directory Path',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onCreateDirectory(controller.text);
                Navigator.pop(context);
              }
            },
            child: Text('Create', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

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
                'Select Destination',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: isLoading ? null : onRefreshDirectories,
                    icon: isLoading 
                        ? SizedBox(
                            width: 16.sp,
                            height: 16.sp,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.refresh, size: 20.sp),
                    tooltip: 'Refresh directories',
                  ),
                  IconButton(
                    onPressed: () => _showCreateDirectoryDialog(context),
                    icon: Icon(Icons.create_new_folder, size: 20.sp),
                    tooltip: 'Create new directory',
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          if (availableDirectories.isEmpty && !isLoading)
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'No directories available. Try refreshing or create a new one.',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            )
          else
            ...availableDirectories.map((directory) {
              final isSelected = selectedDirectory?.path == directory.path;
              
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isSelected 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.3),
                    width: isSelected ? 2.w : 1.w,
                  ),
                ),
                child: ListTile(
                  onTap: () => onDirectorySelected(directory),
                  leading: Icon(
                    directory.exists ? Icons.folder : Icons.folder_off,
                    color: directory.exists && directory.writable 
                        ? theme.colorScheme.primary
                        : Colors.grey,
                    size: 24.sp,
                  ),
                  title: Text(
                    directory.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        directory.path,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      if (!directory.exists || !directory.writable)
                        Text(
                          !directory.exists 
                              ? 'Directory does not exist'
                              : 'Not writable',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  trailing: isSelected 
                      ? Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                          size: 20.sp,
                        )
                      : null,
                ),
              );
            }),
            
          if (selectedDirectory != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Files will be uploaded to: ${selectedDirectory!.name}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}