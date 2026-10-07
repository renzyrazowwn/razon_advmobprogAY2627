import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

final ChatService chatService = ChatService();

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    Key? key,
    required this.currentUserEmail,
    required this.tappedUser,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  late Future<String> _currentUserIdFuture;

  // Enhancement 3
  // the send button only becomes active when there is text to send
  bool _hasText = false;

  final Set<String> _animatedIds = {};

  final Set<String> _markedAsReadIds = {};

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
    _msgCtrl.addListener(() {
      final hasText = _msgCtrl.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  Future<String> _getCurrentUserId() async {
    final userData = await userService.value.getUserData();
    return (userData['uid'] ?? '').toString();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    _msgCtrl.clear();
    _msgFocus.requestFocus();

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }

    try {
      await chatService.sendMessage(receiverId, text);
    } catch (e) {
      if (!mounted) return;
      // puts the text back so the user can try again
      if (_msgCtrl.text.isEmpty) _msgCtrl.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    }
  }

  void _markAsRead(
    List<QueryDocumentSnapshot> docs,
    String currentUserId,
    String tappedUserId,
  ) {
    final unreadIds = docs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['receiverId'] == currentUserId &&
              data['isRead'] != true &&
              !doc.metadata.hasPendingWrites &&
              !_markedAsReadIds.contains(doc.id);
        })
        .map((doc) => doc.id)
        .toList();

    if (unreadIds.isEmpty) return;
    _markedAsReadIds.addAll(unreadIds);

    // runs after the frame is built (no side effects during build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatService
          .markMessagesAsRead(currentUserId, tappedUserId, unreadIds)
          .catchError((_) => _markedAsReadIds.removeAll(unreadIds));
    });
  }

  String _tappedUserName() {
    final fullName =
        '${widget.tappedUser['firstName'] ?? ''} ${widget.tappedUser['lastName'] ?? ''}'
            .trim();
    if (fullName.isNotEmpty) return fullName;
    final username = (widget.tappedUser['username'] ?? '').toString();
    return username.isNotEmpty ? username : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final tappedUserName = _tappedUserName();
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                Hero(
                  tag: 'chat_avatar_$tappedUserId',
                  child: CircleAvatar(
                    radius: 18.r,
                    backgroundColor: colorScheme.primaryContainer,
                    child: CustomText(
                      text: tappedUserName == 'Unknown'
                          ? '?'
                          : tappedUserName[0].toUpperCase(),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: tappedUserName,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      CustomText(
                        text: (widget.tappedUser['email'] ?? '').toString(),
                        fontSize: 11.sp,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.surface,
                  colorScheme.primaryContainer.withAlpha(70),
                ],
              ),
            ),
            child: Column(
              children: [
                // Messages
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: chatService.getMessage(currentUserId, tappedUserId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading messages: ${snapshot.error}',
                          ),
                        );
                      }

                      final List<QueryDocumentSnapshot> docs =
                          snapshot.data?.docs ?? [];

                      _markAsRead(docs, currentUserId, tappedUserId);

                      if (docs.isEmpty) {
                        return _EmptyChat(name: tappedUserName);
                      }

                      final latestMineIndex = docs.indexWhere((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return data['senderId'] == currentUserId;
                      });

                      return ListView.builder(
                        controller: _scrollCtrl,
                        reverse: true,
                        padding: EdgeInsets.symmetric(
                          vertical: 10.h,
                          horizontal: 10.w,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final msgText = (data['message'] ?? '').toString();
                          final senderId = (data['senderId'] ?? '').toString();
                          final isMe = senderId == currentUserId;
                          final time = _toDateTime(data['timestamp']);

                          final newer = index > 0
                              ? docs[index - 1].data() as Map<String, dynamic>
                              : null;
                          final older = index < docs.length - 1
                              ? docs[index + 1].data() as Map<String, dynamic>
                              : null;
                          final isLastInGroup =
                              newer == null || newer['senderId'] != senderId;

                          // date separator above the first message of a day
                          final olderTime =
                              older == null ? null : _toDateTime(older['timestamp']);
                          final showDate =
                              olderTime == null || !_isSameDay(time, olderTime);

                          final status = !isMe
                              ? null
                              : doc.metadata.hasPendingWrites
                                  ? MessageStatus.sending
                                  : data['isRead'] == true
                                      ? MessageStatus.seen
                                      : MessageStatus.delivered;

                          final animate = _animatedIds.add(doc.id);

                          return Column(
                            children: [
                              if (showDate) _DateChip(date: time),
                              _AnimatedMessage(
                                key: ValueKey(doc.id),
                                animate: animate,
                                fromRight: isMe,
                                child: _ChatBubble(
                                  text: msgText.isNotEmpty ? msgText : '[empty]',
                                  time: time,
                                  isMe: isMe,
                                  isLastInGroup: isLastInGroup,
                                  status: status,
                                  showStatusLabel: index == latestMineIndex,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),

                // Composer
                _Composer(
                  controller: _msgCtrl,
                  focusNode: _msgFocus,
                  canSend: _hasText,
                  onSend: () => _send(tappedUserId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum MessageStatus { sending, delivered, seen }

DateTime _toDateTime(dynamic ts) {
  if (ts is Timestamp) return ts.toDate();
  return DateTime.now();
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatTime(DateTime t) {
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${t.hour < 12 ? 'AM' : 'PM'}';
}

String _formatDay(DateTime t) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final now = DateTime.now();
  if (_isSameDay(t, now)) return 'Today';
  if (_isSameDay(t, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  return '${months[t.month - 1]} ${t.day}, ${t.year}';
}

class _AnimatedMessage extends StatefulWidget {
  final bool animate;
  final bool fromRight;
  final Widget child;

  const _AnimatedMessage({
    super.key,
    required this.animate,
    required this.fromRight,
    required this.child,
  });

  @override
  State<_AnimatedMessage> createState() => _AnimatedMessageState();
}

class _AnimatedMessageState extends State<_AnimatedMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(widget.fromRight ? 0.25 : -0.25, 0.15),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final DateTime time;
  final bool isMe;
  final bool isLastInGroup;
  final MessageStatus? status;
  final bool showStatusLabel;

  const _ChatBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.isLastInGroup,
    required this.status,
    required this.showStatusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = isMe ? colorScheme.onPrimary : colorScheme.onSurface;
    final metaColor = textColor.withAlpha(170);
    final radius = Radius.circular(18.r);
    final tail = Radius.circular(isLastInGroup ? 4.r : 18.r);

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              top: 2.h,
              bottom: isLastInGroup ? 8.h : 2.h,
            ),
            padding: EdgeInsets.fromLTRB(14.w, 9.h, 12.w, 7.h),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              gradient: isMe
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colorScheme.primary, colorScheme.tertiary],
                    )
                  : null,
              color: isMe ? null : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: radius,
                topRight: radius,
                bottomLeft: isMe ? radius : tail,
                bottomRight: isMe ? tail : radius,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15.sp,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(time),
                      style: TextStyle(fontSize: 10.sp, color: metaColor),
                    ),
                    if (status != null) ...[
                      SizedBox(width: 4.w),
                      _StatusIcon(status: status!, color: metaColor),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        // "Sending..." / "Delivered" / "Seen" under my newest message
        if (showStatusLabel && status != null)
          Padding(
            padding: EdgeInsets.only(right: 4.w, bottom: 6.h),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                switch (status!) {
                  MessageStatus.sending => 'Sending...',
                  MessageStatus.delivered => 'Delivered',
                  MessageStatus.seen => 'Seen',
                },
                key: ValueKey(status),
                style: TextStyle(
                  fontSize: 10.sp,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final MessageStatus status;
  final Color color;

  const _StatusIcon({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final icon = switch (status) {
      MessageStatus.sending => Icons.schedule,
      MessageStatus.delivered => Icons.done,
      MessageStatus.seen => Icons.done_all,
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Icon(
        icon,
        key: ValueKey(status),
        size: 14.sp,
        color: status == MessageStatus.seen ? Colors.lightBlueAccent : color,
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;

  const _DateChip({required this.date});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          _formatDay(date),
          style: TextStyle(
            fontSize: 11.sp,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final String name;

  const _EmptyChat({required this.name});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.waving_hand_outlined,
              size: 52.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 10.h),
            CustomText(
              text: 'No messages yet',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: 4.h),
            CustomText(text: 'Say hi to $name!', fontSize: 13.sp),
          ],
        ),
      ),
    );
  }
}
class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10.w, 6.h, 10.w, 10.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: const TextStyle(fontFamily: 'Poppins'),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 10.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            AnimatedScale(
              scale: canSend ? 1 : 0.85,
              duration: const Duration(milliseconds: 200),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: canSend
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                ),
                child: IconButton(
                  tooltip: 'Send',
                  icon: Icon(
                    Icons.send_rounded,
                    color: canSend
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                  onPressed: canSend ? onSend : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}