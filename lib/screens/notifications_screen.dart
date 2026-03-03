import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  String _selectedFilter = 'All'; // All, Unread, Read
  
  final List<String> _filters = ['All', 'Unread', 'Read'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadUserAndNotifications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndNotifications() async {
    final user = await _authService.getCurrentUserDetails();
    if (user != null) {
      setState(() {
        _currentUser = user;
      });
      _loadNotifications();
    }
  }

  void _loadNotifications() {
    if (_currentUser == null) return;

    _notificationService.getAllNotifications(_currentUser!.storeId).listen((notifications) {
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
        _animationController.reset();
        _animationController.forward();
      }
    });
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'All') return _notifications;
    if (_selectedFilter == 'Unread') {
      return _notifications.where((n) => !(n['read'] ?? false)).toList();
    }
    return _notifications.where((n) => n['read'] ?? false).toList();
  }

  int get _unreadCount => _notifications.where((n) => !(n['read'] ?? false)).length;

  Future<void> _markAsRead(String id) async {
    await _notificationService.markAsRead(id);
    ScaffoldMessenger.of(context).showSnackBar(
      _buildSnackBar('Notification marked as read', Icons.done, Colors.green),
    );
  }

  Future<void> _markAllAsRead() async {
    if (_currentUser == null) return;
    await _notificationService.markAllAsRead(_currentUser!.storeId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar('All notifications marked as read', Icons.done_all, Colors.green),
      );
    }
  }

  Future<void> _deleteNotification(String id) async {
    await _notificationService.deleteNotification(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar('Notification deleted', Icons.delete_outline, Colors.red),
      );
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true && _currentUser != null) {
      await _notificationService.clearAllNotifications(_currentUser!.storeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar('All notifications cleared', Icons.delete_sweep, Colors.red),
        );
      }
    }
  }

  SnackBar _buildSnackBar(String message, IconData icon, Color color) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      duration: const Duration(seconds: 2),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'low_stock':
        return AppTheme.warningColor;
      case 'sale':
        return AppTheme.successColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'low_stock':
        return Icons.inventory_2_outlined;
      case 'sale':
        return Icons.shopping_cart_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _getNotificationTitle(String type) {
    switch (type) {
      case 'low_stock':
        return 'Low Stock Alert';
      case 'sale':
        return 'New Sale';
      default:
        return 'Notification';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final padding = mediaQuery.padding;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stats bar
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _notifications.length > 99 ? '99+' : _notifications.length.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Total Notifications',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const Spacer(),
                    if (_unreadCount > 0)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: isSmallScreen ? 2 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: isSmallScreen ? 6 : 8,
                              height: isSmallScreen ? 6 : 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${_unreadCount > 99 ? '99+' : _unreadCount} unread',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmallScreen ? 10 : 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Filter chips and actions
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 6 : 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filters.map((filter) {
                            final isSelected = filter == _selectedFilter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: FilterChip(
                                label: Text(
                                  filter,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 13,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                },
                                backgroundColor: Colors.grey.shade100,
                                selectedColor: AppTheme.primaryColor,
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: isSmallScreen ? 11 : 13,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 8 : 12,
                                  vertical: isSmallScreen ? 4 : 8,
                                ),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                elevation: isSelected ? 2 : 0,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    if (_notifications.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: AppTheme.primaryColor,
                          size: isSmallScreen ? 20 : 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'mark_all') {
                            _markAllAsRead();
                          } else if (value == 'clear_all') {
                            _clearAll();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'mark_all',
                            height: isSmallScreen ? 40 : 48,
                            child: Row(
                              children: [
                                Icon(Icons.done_all, size: isSmallScreen ? 16 : 18, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'Mark all as read',
                                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'clear_all',
                            height: isSmallScreen ? 40 : 48,
                            child: Row(
                              children: [
                                Icon(Icons.delete_sweep, size: isSmallScreen ? 16 : 18, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                  'Clear all',
                                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState(isSmallScreen)
            : _filteredNotifications.isEmpty
                ? _buildEmptyState(isSmallScreen)
                : _buildNotificationsList(isSmallScreen),
      ),
    );
  }

  Widget _buildLoadingState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: isSmallScreen ? 40 : 50,
            height: isSmallScreen ? 40 : 50,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    String message = '';
    String subMessage = '';
    IconData icon = Icons.notifications_none;
    
    if (_selectedFilter == 'Unread') {
      message = 'No unread notifications';
      subMessage = 'All caught up!';
      icon = Icons.mark_chat_read;
    } else if (_selectedFilter == 'Read') {
      message = 'No read notifications';
      subMessage = 'Notifications you read will appear here';
      icon = Icons.drafts;
    } else {
      message = 'No notifications yet';
      subMessage = 'You\'re all caught up!';
      icon = Icons.notifications_off_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0, end: 1),
              curve: Curves.elasticOut,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: isSmallScreen ? 80 : 100,
                    height: isSmallScreen ? 80 : 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: isSmallScreen ? 35 : 45,
                      color: AppTheme.primaryColor.withOpacity(0.5),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subMessage,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(bool isSmallScreen) {
    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      itemCount: _filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = _filteredNotifications[index];
        final isRead = notification['read'] ?? false;
        final color = _getNotificationColor(notification['type'] ?? '');
        
        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.easeOut,
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Dismissible(
            key: Key(notification['id']),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 8),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete, color: Colors.white, size: isSmallScreen ? 18 : 20),
                  const SizedBox(width: 4),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ],
              ),
            ),
            onDismissed: (direction) {
              _deleteNotification(notification['id']);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                elevation: isRead ? 1 : 2,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: InkWell(
                  onTap: () {
                    if (!isRead) {
                      _markAsRead(notification['id']);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: !isRead
                          ? Border(
                              left: BorderSide(
                                color: color,
                                width: 3,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Animated icon
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isSmallScreen ? 36 : 40,
                          height: isSmallScreen ? 36 : 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isRead
                                  ? [Colors.grey.shade300, Colors.grey.shade400]
                                  : [color.withOpacity(0.7), color],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              _getNotificationIcon(notification['type'] ?? ''),
                              color: Colors.white,
                              size: isSmallScreen ? 18 : 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getNotificationTitle(notification['type'] ?? ''),
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 13 : 14,
                                        fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                        color: isRead ? Colors.grey.shade700 : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (!isRead)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'NEW',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 8 : 9,
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification['message'] ?? '',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  color: Colors.grey.shade800,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (notification['product_name'] != null && 
                                  notification['product_name'].isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Product: ${notification['product_name']}',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 9 : 10,
                                      color: color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: isSmallScreen ? 10 : 11,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      DateFormat('MMM d, yyyy • h:mm a').format(
                                        DateTime.parse(notification['created_at']),
                                      ),
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 9 : 10,
                                        color: Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Action buttons
                        if (!isRead)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: IconButton(
                              icon: Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: isSmallScreen ? 18 : 20,
                              ),
                              onPressed: () => _markAsRead(notification['id']),
                              tooltip: 'Mark as read',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}