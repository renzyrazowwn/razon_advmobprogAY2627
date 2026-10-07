import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  String? _currentUserEmail;

  String? _currentUserId;

  final Map<String, Stream<QuerySnapshot>> _unreadStreams = {};

  Stream<QuerySnapshot>? _unreadStreamFor(String otherUserId) {
    if (_currentUserId == null || _currentUserId!.isEmpty) return null;
    return _unreadStreams.putIfAbsent(
      otherUserId,
      () => _chatService.getUnreadMessages(_currentUserId!, otherUserId),
    );
  }
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
  }

  Future<void> _loadCurrentUserEmail() async {
    final userData = await userService.value.getUserData();
    if (!mounted) return;
    setState(() {
      _currentUserEmail = userData['email'];
      // Lab Act 6 - Unread highlight
      _currentUserId = userData['uid'];
    });
  }

  String _latestMessage(List<QueryDocumentSnapshot> docs) {
    final sorted = [...docs]..sort((a, b) {
        final aTime = (a.data() as Map<String, dynamic>)['timestamp'];
        final bTime = (b.data() as Map<String, dynamic>)['timestamp'];
        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime);
        }
        return 0;
      });
    final data = sorted.first.data() as Map<String, dynamic>;
    return (data['message'] ?? '').toString();
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  // Enhancement 2
  // returns true if the user's name, username or email contains the search text
  bool _matchesSearch(Map<String, dynamic> user) {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) return true;

    final searchable = [
      user['firstName'],
      user['lastName'],
      '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
      user['username'],
      user['email'],
    ].map((value) => (value ?? '').toString().toLowerCase());

    return searchable.any((value) => value.contains(query));
  }

  String _displayName(Map<String, dynamic> user) {
    final fullName =
        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    if (fullName.isNotEmpty) return fullName;
    final username = (user['username'] ?? '').toString();
    if (username.isNotEmpty) return username;
    return 'Unknown';
  }

  String _initial(Map<String, dynamic> user) {
    final name = _displayName(user);
    return name == 'Unknown' ? '?' : name[0].toUpperCase();
  }

  Widget _messageBox(String text, IconData icon) {
    return Container(
      height: ScreenUtil().screenHeight * 0.6,
      padding: EdgeInsets.all(16.sp),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48.sp, color: Theme.of(context).disabledColor),
            SizedBox(height: 8.h),
            CustomText(text: text, fontSize: 16.sp),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Chats',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20.h),

            // Enhancement 2
            // search bar at the top of the chat list
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 23.w),
              child: TextField(
                controller: _searchChatController,
                textInputAction: TextInputAction.search,
                // filters the list while typing
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchChatController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.cancel),
                          onPressed: () {
                            setState(() {
                              _searchChatController.clear();
                              _searchText = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),

            // Users Stream
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getOtherUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: ScreenUtil().screenHeight * 0.6,
                    padding: EdgeInsets.all(16.sp),
                    child: const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _messageBox(
                    'Error loading users',
                    Icons.error_outline,
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _messageBox(
                    'No users found',
                    Icons.people_outline,
                  );
                }

                // Enhancement 2
                // applies the search filter (name/username/email)
                final users = snapshot.data!.where(_matchesSearch).toList();

                if (users.isEmpty) {
                  return _messageBox(
                    'No users match "${_searchText.trim()}"',
                    Icons.search_off,
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return GestureDetector(
                      onTap: () {
                        if (_currentUserEmail == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              currentUserEmail: _currentUserEmail!,
                              tappedUser: user,
                            ),
                          ),
                        );
                      },
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _unreadStreamFor(
                          (user['uid'] ?? '').toString(),
                        ),
                        builder: (context, unreadSnapshot) {
                          final unreadDocs = unreadSnapshot.data?.docs ?? [];
                          final unreadCount = unreadDocs.length;
                          final hasUnread = unreadCount > 0;
                          final colorScheme = Theme.of(context).colorScheme;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: EdgeInsets.symmetric(vertical: 4.h),
                            decoration: BoxDecoration(
                              color: hasUnread
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: hasUnread
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: ListTile(
                              leading: Hero(
                                tag: 'chat_avatar_${user['uid']}',
                                child: CircleAvatar(
                                  backgroundColor: hasUnread
                                      ? colorScheme.primary
                                      : null,
                                  foregroundColor: hasUnread
                                      ? colorScheme.onPrimary
                                      : null,
                                  child: CustomText(
                                    text: _initial(user),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: CustomText(
                                text: _displayName(user),
                                fontSize: 20,
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                              // shows the newest unread message instead of
                              // the email when there are unseen messages
                              subtitle: CustomText(
                                text: hasUnread
                                    ? _latestMessage(unreadDocs)
                                    : user['email'] ?? 'No email',
                                fontSize: 12,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w300,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: hasUnread
                                  ? Badge(
                                      backgroundColor: colorScheme.primary,
                                      textColor: colorScheme.onPrimary,
                                      largeSize: 22,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 7.w,
                                      ),
                                      label: Text(
                                        unreadCount > 99
                                            ? '99+'
                                            : '$unreadCount',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.chevron_right),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}