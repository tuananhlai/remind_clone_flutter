import 'package:flutter/material.dart';
import 'package:bubble/bubble.dart';
import 'package:provider/provider.dart';
import 'package:remind_clone_flutter/models/classroom/conversation.dart';
import 'package:remind_clone_flutter/stores/classroom_store.dart';
import 'package:remind_clone_flutter/stores/user_store.dart';

class MessageTab extends StatefulWidget {
  @override
  _MessageTabState createState() => _MessageTabState();
}

class _MessageTabState extends State<MessageTab> {
  Future<List<Conversation>> futureFetchConvos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final classroomStore = Provider.of<ClassroomStore>(context);
    final userStore = Provider.of<UserStore>(context, listen: false);
    futureFetchConvos = classroomStore.fetchConversations(
        userStore.getToken(), classroomStore.currentClassroom.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureFetchConvos,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<_ConversationListTile> children = [];

          for (var conversation in snapshot.data) {
            children.add(
              _ConversationListTile(conversation),
            );
          }
          return ListView(
            children: children,
          );
        } else if (snapshot.hasError) {
          // TODO: show error dialog here.
          return Text("${snapshot.error}");
        }
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}

class _ConversationListTile extends StatelessWidget {
  final Conversation conversation;

  _ConversationListTile(this.conversation);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.black12,
        child: Icon(
          Icons.group,
          color: Colors.black,
        ),
      ),
      title: Text(conversation.name),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ConversationScreen(conversation),
          ),
        );
      },
    );
  }
}

class ConversationScreen extends StatefulWidget {
  final Conversation conversation;

  ConversationScreen(this.conversation);

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final messageInputController = TextEditingController();
  Future<List<Message>> futureFetchMessages;

  List<Widget> _buildMessageList(List<Message> messages) {
    final List<MessageBubble> messageBubbles = [];

    for (var message in messages) {
      messageBubbles.add(
        MessageBubble(
          message: message,
        ),
      );
    }

    return messageBubbles;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final classroomStore = Provider.of<ClassroomStore>(context);
    final userStore = Provider.of<UserStore>(context, listen: false);
    futureFetchMessages =
        classroomStore.fetchMessages(userStore.getToken(), widget.conversation);
  }

  @override
  Widget build(BuildContext context) {
    final conversation = widget.conversation;
    return Scaffold(
      appBar: AppBar(
        title: Text(conversation.name),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {},
            splashRadius: 20.0,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return FutureBuilder(
        future: futureFetchMessages,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ListView(
                      children: _buildMessageList(snapshot.data),
                    ),
                  ),
                  MessageTextBox(
                      messageInputController: messageInputController),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            // TODO: show error dialog here.
            return Text("${snapshot.error}");
          }
          return Center(
            child: CircularProgressIndicator(),
          );
        });
  }
}

class MessageTextBox extends StatelessWidget {
  const MessageTextBox({
    Key key,
    @required this.messageInputController,
    this.onSend,
    this.onOpenCamera,
    this.onOpenFileUpload,
  }) : super(key: key);

  final TextEditingController messageInputController;
  final VoidCallback onSend;
  final VoidCallback onOpenCamera;
  final VoidCallback onOpenFileUpload;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          child: TextField(
            style: TextStyle(
              color: Colors.black,
            ),
            decoration: InputDecoration(
              filled: true,
              hintText: "Send Message...",
              hintStyle: TextStyle(
                color: Colors.grey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
                borderSide: BorderSide.none,
              ),
            ),
            controller: this.messageInputController,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.file_upload,
              ),
              onPressed: onOpenFileUpload,
              splashRadius: 17.0,
            ),
            IconButton(
              icon: Icon(
                Icons.camera_alt,
              ),
              onPressed: onOpenCamera,
              splashRadius: 17.0,
            ),
            Expanded(
              child: SizedBox(),
            ),
            TextButton(
              onPressed: onSend,
              child: Text("SEND"),
            ),
          ],
        )
      ],
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine = false;

  final CircleAvatar userAvatar = CircleAvatar(
    backgroundColor: Colors.black12,
    child: Icon(
      Icons.group,
      color: Colors.black,
    ),
  );

  final myMessageStyle = BubbleStyle(
    nip: BubbleNip.rightBottom,
    alignment: Alignment.bottomRight,
  );

  final otherMessageStyle = BubbleStyle(
    nip: BubbleNip.leftBottom,
    alignment: Alignment.bottomLeft,
  );

  MessageBubble({this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        userAvatar,
        SizedBox(
          width: 10.0,
        ),
        Expanded(
          child: Bubble(
            child: Text(message.message),
            padding: BubbleEdges.all(12.0),
            style: isMine ? myMessageStyle : otherMessageStyle,
          ),
        ),
      ],
    );
  }
}
