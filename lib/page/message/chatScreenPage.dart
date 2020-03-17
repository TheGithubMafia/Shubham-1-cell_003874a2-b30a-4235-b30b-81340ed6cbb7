import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/theme.dart';
import 'package:flutter_twitter_clone/model/chatModel.dart';
import 'package:flutter_twitter_clone/helper/utility.dart';
import 'package:flutter_twitter_clone/model/user.dart';
import 'package:flutter_twitter_clone/state/authState.dart';
import 'package:flutter_twitter_clone/state/chats/chatState.dart';
import 'package:flutter_twitter_clone/widgets/customWidgets.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/customUrlText.dart';
import 'package:provider/provider.dart';

class ChatScreenPage extends StatefulWidget {
  ChatScreenPage({Key key, this.userProfileId}) : super(key: key);

  final String userProfileId;

  _ChatScreenPageState createState() => _ChatScreenPageState();
}

class _ChatScreenPageState extends State<ChatScreenPage> {
  final messageController = new TextEditingController();
  String senderId;
  String userImage;
  ScrollController _controller;

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _controller = ScrollController();
    final chatState = Provider.of<ChatState>(context, listen: false);
    final state = Provider.of<AuthState>(context, listen: false);
    chatState.setIsChatScreenOpen = true;
    senderId = state.userId;
    chatState.databaseInit(chatState.chatUser.userId, state.userId);
    chatState.getchatDetailAsync();
    super.initState();
  }

  Widget _chatScreenBody() {
    final state = Provider.of<ChatState>(context);
    if (state.messageList == null || state.messageList.length == 0) {
      return Center(
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
      physics: BouncingScrollPhysics(),
      itemCount: state.messageList.length,
      itemBuilder: (context, index) => chatMessage(state.messageList[index]),
    );
  }

  Widget chatMessage(ChatMessage message) {
    if (senderId == null) {
      return Container();
    }
    if (message.senderId == senderId)
      return _message(message, true);
    else
      return _message(message, false);
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
            SizedBox(width: 15,),
            myMessage
                ? SizedBox()
                : CircleAvatar(
                    backgroundImage: customAdvanceNetworkImage(userImage),
                  ),
            Expanded(
              child: Container(
                alignment:
                    myMessage ? Alignment.centerRight : Alignment.centerLeft,
                margin: EdgeInsets.only(
                  right: myMessage ? 10 : (fullWidth(context) / 4),
                  top: 20,
                  left: myMessage ? (fullWidth(context) / 4) : 10,
                ),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomRight:
                          myMessage ? Radius.circular(0) : Radius.circular(20),
                      bottomLeft:
                          myMessage ? Radius.circular(20) : Radius.circular(0),
                    ),
                    color: myMessage
                        ? TwitterColor.dodgetBlue
                        : TwitterColor.mystic,
                  ),
                  child: UrlText(
                    text: chat.message,
                    style: TextStyle(
                        fontSize: 18,
                        color: myMessage ? TwitterColor.white : Colors.black),
                  ),
                ),
              ),
            ),
            //  myMessage ? CircleAvatar() : SizedBox()
          ],
        ),
        Padding(
          padding: EdgeInsets.only(right: 10, left: 10),
          child: Text(
            getChatTime(chat.createdAt),
            style: Theme.of(context).textTheme.caption.copyWith(fontSize: 12),
          ),
        )
      ],
    );
  }

  Widget _bottomEntryField() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Divider(
            thickness: 0,
            height: 1,
          ),
          TextField(
            onSubmitted: (val) async {
              submitMessage();
            },
            controller: messageController,
            decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 13),
              alignLabelWithHint: true,
              hintText: 'Start with a message...',
              suffixIcon:
                  IconButton(icon: Icon(Icons.send), onPressed: submitMessage),
              // fillColor: Colors.black12, filled: true
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final chatState = Provider.of<ChatState>(context);
    chatState.setIsChatScreenOpen = false;
    chatState.dispose();
    return true;
  }

  void submitMessage() {
    var state = Provider.of<ChatState>(context, listen: false);
    var authstate = Provider.of<AuthState>(context, listen: false);
    ChatMessage message;
    message = ChatMessage(
        message: messageController.text,
        createdAt: DateTime.now().toIso8601String(),
        senderId: authstate.userModel.userId,
        receiverId: state.chatUser.userId,
        seen: false,
        timeStamp: DateTime.now().millisecondsSinceEpoch.toString(),
        senderName: authstate.user.displayName);
    if (messageController.text == null || messageController.text.isEmpty) {
      return;
    }
    User myUser = User(
        displayName: authstate.userModel.displayName,
        userId: authstate.userModel.userId,
        userName: authstate.userModel.userName,
        profilePic: authstate.userModel.profilePic);
    User secondUser = User(
      displayName: state.chatUser.displayName,
      userId: state.chatUser.userId,
      userName: state.chatUser.userName,
      profilePic: state.chatUser.profilePic,
    );
    state.onMessageSubmitted(message, myUser: myUser, secondUser: secondUser);
    Future.delayed(Duration(milliseconds: 50)).then((_) {
      messageController.clear();
    });
    try {
      final state = Provider.of<ChatState>(context);
      if (state.messageList != null &&
          state.messageList.length > 1 &&
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
    var state = Provider.of<ChatState>(context, listen: false);
    userImage = state.chatUser.profilePic;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UrlText(
                text: state.chatUser.displayName,
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                state.chatUser.userName,
                style: TextStyle(color: AppColor.darkGrey, fontSize: 15),
              )
            ],
          ),
          iconTheme: IconThemeData(color: Colors.blue),
          backgroundColor: Colors.white,
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.info, color: AppColor.primary),
                onPressed: () {})
          ],
        ),
        body: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(bottom: 50),
                child: _chatScreenBody(),
              ),
            ),
            _bottomEntryField()
          ],
        ),
      ),
    );
  }
}
