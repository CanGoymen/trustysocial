import 'package:flutter/material.dart';
import 'package:Trusty/helper/utility.dart';
import 'package:Trusty/model/chatModel.dart';
import 'package:Trusty/state/authState.dart';
import 'package:Trusty/state/chats/chatState.dart';
import 'package:Trusty/ui/page/profile/widgets/circular_image.dart';
import 'package:Trusty/ui/theme/theme.dart';
import 'package:Trusty/widgets/url_text/customUrlText.dart';
import 'package:provider/provider.dart';

class ChatScreenPage extends StatefulWidget {
  const ChatScreenPage({
    Key? key,
  }) : super(key: key);

  @override
  _ChatScreenPageState createState() => _ChatScreenPageState();
}

class _ChatScreenPageState extends State<ChatScreenPage> {
  final messageController = TextEditingController();
  String? senderId;
  late String userImage;
  late ChatState state;
  late ScrollController _controller;
  late GlobalKey<ScaffoldState> _scaffoldKey;

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _scaffoldKey = GlobalKey<ScaffoldState>();
    _controller = ScrollController();
    final chatState = Provider.of<ChatState>(context, listen: false);
    final state = Provider.of<AuthState>(context, listen: false);
    chatState.setIsChatScreenOpen = true;
    senderId = state.userId;
    chatState.databaseInit(chatState.chatUser!.userId!, state.userId);
    chatState.getChatDetailAsync();
    super.initState();
  }

  Widget _chatScreenBody() {
    final state = Provider.of<ChatState>(context);
    if (state.messageList == null || state.messageList!.isEmpty) {
      return const Center(
        child: Text(
          'No message found',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      );
    }
    return ListView.builder(
      controller: _controller,
      shrinkWrap: true,
      reverse: true,
      physics: const BouncingScrollPhysics(),
      itemCount: state.messageList!.length,
      itemBuilder: (context, index) => chatMessage(state.messageList![index]),
    );
  }

  Widget chatMessage(ChatMessage message) {
    if (senderId == null) {
      return Container();
    }
    if (message.senderId == senderId) {
      return _message(message, true);
    } else {
      return _message(message, false);
    }
  }

  Widget _message(ChatMessage chat, bool myMessage) {
    return Column(
      crossAxisAlignment:
          myMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisAlignment:
          myMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            const SizedBox(
              width: 15,
            ),
            myMessage
                ? const SizedBox()
                : CircleAvatar(
                    backgroundColor: Colors.transparent,
                    backgroundImage: customAdvanceNetworkImage(userImage),
                  ),
            Expanded(
              child: Container(
                alignment:
                    myMessage ? Alignment.centerRight : Alignment.centerLeft,
                margin: EdgeInsets.only(
                  right: myMessage ? 10 : (context.width / 4),
                  top: 20,
                  left: myMessage ? (context.width / 4) : 10,
                ),
                child: Stack(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: getBorder(myMessage),
                        color: myMessage
                            ? TwitterColor.dodgeBlue
                            : TwitterColor.mystic,
                      ),
                      child: UrlText(
                        text: chat.message!,
                        style: TextStyle(
                          fontSize: 16,
                          color: myMessage ? TwitterColor.white : Colors.black,
                        ),
                        urlStyle: TextStyle(
                          fontSize: 16,
                          color: myMessage
                              ? TwitterColor.white
                              : TwitterColor.dodgeBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10, left: 10),
          child: Text(
            Utility.getChatTime(chat.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        )
      ],
    );
  }

  BorderRadius getBorder(bool myMessage) {
    return BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomRight:
          myMessage ? const Radius.circular(0) : const Radius.circular(20),
      bottomLeft:
          myMessage ? const Radius.circular(20) : const Radius.circular(0),
    );
  }

  Widget _bottomEntryField() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          //const Divider(),
          TextField(
            onSubmitted: (val) async {
              submitMessage();
            },
            controller: messageController,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              alignLabelWithHint: true,
              hintText: 'Start with a message...',
              suffixIcon: IconButton(
                  icon: const Icon(Icons.send), onPressed: submitMessage),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    state.setIsChatScreenOpen = false;
    state.onChatScreenClosed();
    return true;
  }

  void submitMessage() {
    var authState = Provider.of<AuthState>(context, listen: false);
    ChatMessage message;
    message = ChatMessage(
        message: messageController.text,
        createdAt: DateTime.now().toUtc().toString(),
        senderId: authState.userModel!.userId!,
        receiverId: state.chatUser!.userId!,
        seen: false,
        timeStamp: DateTime.now().toUtc().millisecondsSinceEpoch.toString(),
        senderName: authState.user!.displayName!);
    if (messageController.text.isEmpty) {
      return;
    }
    state.onMessageSubmitted(
      message, /*myUser: myUser, secondUser: secondUser*/
    );
    Future.delayed(const Duration(milliseconds: 50)).then((_) {
      messageController.clear();
    });
    try {
      if (state.messageList != null &&
          state.messageList!.length > 1 &&
          _controller.offset > 0) {
        _controller.animateTo(
          0.0,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 300),
        );
      }
    } catch (e) {
      print("[Error] $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    state = Provider.of<ChatState>(context, listen: false);
    userImage = state.chatUser!.profilePic!;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UrlText(
                text: state.chatUser!.displayName!,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                state.chatUser!.userName!,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 15,
                ),
              )
            ],
          ),
          iconTheme: const IconThemeData(color: Colors.blue),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.info, color: AppColor.primary),
                onPressed: () {
                  Navigator.pushNamed(context, '/ConversationInformation');
                })
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: _chatScreenBody(),
                ),
              ),
              _bottomEntryField()
            ],
          ),
        ),
      ),
    );
  }
}
