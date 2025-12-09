import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final result = await ChatService.getChatList();
    if (mounted) {
      setState(() {
        if (result['success']) {
          _chats = result['chats'] ?? [];
        }
        _isLoading = false;
      });
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays > 0) {
        return '${diff.inDays}h lalu';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}j lalu';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pesan',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada pesan',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  child: ListView.builder(
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      return _buildChatItem(chat);
                    },
                  ),
                ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final userName = chat['user_name'] ?? 'User';
    final schoolName = chat['school_name'] ?? '';
    final lastMessage = chat['last_message'] ?? '';
    final unreadCount = chat['unread_count'] ?? 0;
    final lastTime = chat['last_time'] as String?;
    final userId = chat['user_id'] as String?;

    return ListTile(
      onTap: () async {
        if (userId != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatRoomScreen(
                otherUserId: userId,
                otherUserName: userName,
              ),
            ),
          );
          _loadChats(); // Refresh after returning
        }
      },
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: const Color(0xFF10B981),
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              userName,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            _formatTime(lastTime),
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastMessage.isEmpty ? schoolName : lastMessage,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF86812),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
