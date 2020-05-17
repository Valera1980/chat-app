import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  static String id = 'chat-screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final msgTextController = TextEditingController();
  final _fileStore = Firestore.instance;
  final _auth = FirebaseAuth.instance;
  FirebaseUser loggedUser;
  String messageText;
  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedUser = user;
      }
    } catch (e) {
      print('==== AUTH ERROR ==========');
      print(e);
    }
  }

  void queryMessages() async {
    final doc = await _fileStore.collection('messages').getDocuments();
    for (var m in doc.documents) {
      print(m.data);
    }
  }

  void messagesStream() async {
    Stream<QuerySnapshot> str = _fileStore.collection('messages').snapshots();
    await for (QuerySnapshot snapShotItem in str) {
      for (DocumentSnapshot item in snapShotItem.documents) {
        print(item.data);
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getCurrentUser();
    queryMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
//                queryMessages();
                messagesStream();
                //Implement logout functionality
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilderWidget(fileStore: _fileStore, fbUser: loggedUser,),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: msgTextController,
                      onChanged: (value) {
                        messageText = value;
                        //Do something with the user input.
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      msgTextController.clear();
                      //Implement send functionality.
                      _fileStore.collection('messages').add(
                          {'sender': loggedUser.email, 'text': messageText});
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class StreamBuilderWidget extends StatelessWidget {
  final fileStore;
  final FirebaseUser fbUser;
  StreamBuilderWidget({@required this.fileStore, @required this.fbUser});
  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder<QuerySnapshot>(
        stream: fileStore.collection('messages').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.lightBlueAccent,
              ),
            );
          }
          final msg = snapshot.data.documents.reversed;
          List<BubbleMessage> msgWidgets = [];
          for (var m in msg) {
            final txt = m.data['text'];
            final sender = m.data['sender'];

            final msgForWidget = BubbleMessage(
                text: txt,
                sender: sender,
                isMe: fbUser.email == sender.toString().trim(),
            );
            msgWidgets.add(msgForWidget);
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              children: msgWidgets,
            ),
          );
        },
      ),
    );
  }
}


class BubbleMessage extends StatelessWidget {
  final String text;
  final String sender;
  final bool isMe;
  BubbleMessage({this.text, this.sender, this.isMe});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(sender, style: TextStyle(
            fontSize: 12.0,
            color: Colors.white
          ),),
          Material(
            elevation: 5,
            color: isMe ? Colors.lightBlueAccent : Colors.green,
            borderRadius: isMe ? BorderRadius.only(topLeft: Radius.circular(30), bottomLeft: Radius.circular(30),bottomRight: Radius.circular(30))
                                : BorderRadius.only(topRight: Radius.circular(30), bottomLeft: Radius.circular(30),bottomRight: Radius.circular(30)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Text(
                '$text',
                style: TextStyle(fontSize: 15.0, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
