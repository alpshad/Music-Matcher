import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import 'channel_page.dart';

class ChannelListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('Own id: ${StreamChat.of(context).currentUser!.id}');
    return Scaffold(
      body: ChannelListView(
        filter: Filter.in_('members', [StreamChat.of(context).currentUser!.id]),
        sort: [SortOption('last_message_at')],
        limit: 20,
        channelWidget: ChannelPage(),
      ),
    );
  }
}