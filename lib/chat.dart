import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'platform_adaptive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'circular_photo.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import 'helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'video-call/pages/call.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:random_string/random_string.dart';

final String MESSAGE_TYPE_TEXT = "text";
final String MESSAGE_TYPE_VIDEO_CALL_INVITATION = "videoCall";

/// Represents the screen where two people talk to each other.
/// roomId: The id of the room(in the database) that was created for each other.
/// photoUserId: This is the id of the person who the current user is talking to.
/// proposalId:
class ChatScreen extends StatefulWidget {
  final String roomId;
  final String photoUserId;
  ChatScreen(this.roomId, this.photoUserId);

  @override
  State createState() => ChatScreenState(roomId);
}

/// State of the ChatScreen
class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  List<ChatMessage> _messages = [];
  TextEditingController _chatInputController = TextEditingController();
  bool _isComposing = false; // Are we writing something at the moment ?
  StreamSubscription<QuerySnapshot> fireBaseSubscription;
  Firestore firestore = Firestore.instance;
  String roomId;
  CollectionReference roomCollectionReference;
  ScrollController _scrollController;
  Function _currentScrollListener;
  FirebaseUser currentUser;
  final FirebaseMessaging _fcm = FirebaseMessaging();
  bool _receivedMessage = false;



  ChatScreenState(this.roomId);


  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    firestore = Firestore.instance;
    initializeChatSubscription();
  }
  
  // Note how we use getUserOrganization method with a parameter here.
  void initializeChatSubscription() async {
    FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
    roomCollectionReference = firestore
        .collection("kingdoms")
        .document(getUserOrganization(currentUser) ?? "")
        .collection('chats')
        .document(roomId)
        .collection('chat_room');
    fireBaseSubscription = roomCollectionReference
        .limit(15) // only get last 15 for now, works with iphone
        .orderBy("timestamp", descending: true)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      for (DocumentSnapshot snapshot in snapshot.documents.reversed) {
        Timestamp newMessageTimestamp = snapshot.data['timestamp'];
        if (_messages.isNotEmpty) {
          Timestamp maxTimestamp = findMaxTimestamp();
          if (newMessageTimestamp.compareTo(maxTimestamp) > 0) {
            _addMessage(
                name: snapshot.data['sender']['name'],
                senderImageUrl: snapshot.data['sender']['imageUrl'],
                text: snapshot.data['text'],
                timestamp: newMessageTimestamp,
                messageType: snapshot.data['type'],
                channelName: snapshot.data['channel_name']
            );
          }
        } else {
          _addMessage(
              name: snapshot.data['sender']['name'],
              senderImageUrl: snapshot.data['sender']['imageUrl'],
              text: snapshot.data['text'],
              timestamp: newMessageTimestamp,
              messageType: snapshot.data['type'],
              channelName: snapshot.data['channel_name'],
          );
        }
      }
      // Update the 'time_seen' state in our database
      if (_messages.isNotEmpty) {
        _updateTimeSeenState(_messages[0].timestamp);
      }
    });
  }

  // Return the max timestamp in our list of messages.
  Timestamp findMaxTimestamp() {
    Timestamp maxTimestamp = _messages[0].timestamp;
    for (ChatMessage message in _messages) {
      Timestamp currTimeStamp = message.timestamp;
      if (currTimeStamp.compareTo(maxTimestamp) > 0) {
        maxTimestamp = currTimeStamp;
      }
    }
    return maxTimestamp;
  }

  // We keep track of timestamp of the last message the user has seen.
  // We update all the related state in the database.
  void _updateTimeSeenState(Timestamp maxTimestamp) async {
    FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
    DocumentReference chatReference = firestore
        .collection("kingdoms")
        .document(getUserOrganization(currentUser) ?? "")
        .collection("chats")
        .document(roomId);
    DocumentSnapshot chat = await chatReference.get();
    if (chat.data['creator_id'] == currentUser.uid) {
      firestore.runTransaction((Transaction t) async {
        await t.update(chatReference, <String, dynamic>{
          "creator_seen" : maxTimestamp
        });
      });
    } else  {
      firestore.runTransaction((Transaction t) async {
        await t.update(chatReference, <String, dynamic>{
          "interested_seen" : maxTimestamp
        });
      });
    }
  }

  // This will be used check if notifications are working. Currently they aren't ;(
  void printSomething() {
    print("something yaya");
    setState(() {
      _receivedMessage = true;
    });
  }

  // When the user tries to scroll up to see older messages,
  // he/she reaches end of currently available messages and that is
  // when we qeury to get older messages.
  Function getScrollListener(BuildContext context) {
    return () {
      if ((_scrollController.offset >=
              _scrollController.position.maxScrollExtent) &&
          (!_scrollController.position.outOfRange)) {
        setState(() {
          _getOldMessages();
        });
      }
    };
  }

  @override
  void dispose() {
    for (ChatMessage message in _messages) {
      message.animationController.dispose();
    }
    fireBaseSubscription.cancel();
    super.dispose();
  }

  void _handleMessageChanged(String text) {
    setState(() {
      _isComposing = text.length > 0;
    });
  }

  // This method adds a new chat-message to the front(where most resent messages go).
  void _addMessage(
      {String name, String text, String senderImageUrl, Timestamp timestamp, String messageType, String channelName}) {
    print("addMessage " + (channelName ?? ""));
    var animationController = AnimationController(
      duration: Duration(milliseconds: 700),
      vsync: this,
    );
    var sender = ChatUser(name: name, imageUrl: senderImageUrl);
    var message = ChatMessage(
        messageType,
        channelName: channelName,
        sender: sender,
        text: text,
        animationController: animationController,
        timestamp: timestamp);
    setState(() {
      _messages.insert(0, message);
    });
    animationController?.forward();
  }

  // This method adds a new chat-message to the end(where older messages go).
  void _addMessageAtEnd(
      {String name, String text, String senderImageUrl, String messageType, Timestamp timestamp, String channelName}) {
    print("addMessageEnd " + (channelName ?? ""));
    var animationController = AnimationController(
      duration: Duration(milliseconds: 700),
      vsync: this,
    );
    var sender = ChatUser(name: name, imageUrl: senderImageUrl);
    var message = ChatMessage(
        messageType,
        channelName: channelName,
        sender: sender,
        text: text,
        animationController: animationController,
        timestamp: timestamp);
    setState(() {
      _messages.insert(_messages.length, message);
    });
    animationController?.forward();
  }

  // Stuff that need to happen when user presses the submit button.
  void _handleSubmitted(String text) async {
    _chatInputController.clear();
    FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
    DocumentSnapshot userDetails = await firestore
        .collection("kingdoms")
        .document(getUserOrganization(currentUser) ?? "")
        .collection("users")
        .document(currentUser.uid).get();
    Timestamp currentTime = Timestamp.now();
    var message = {
      'sender': <String, dynamic>{'name': userDetails.data['name'], 'imageUrl': userDetails.data['photo_url']},
      'text': text,
      'timestamp': currentTime,
      "receiver" : widget.photoUserId,
      "type" : MESSAGE_TYPE_TEXT
    };
    roomCollectionReference.add(message);
    DocumentReference chatReference = firestore
        .collection("kingdoms")
        .document(getUserOrganization(currentUser) ?? "")
        .collection('chats')
        .document(roomId);
    // below we store the timestamp indicating when the last update to the
    // chat was made. We also store the last message which caused this update.
    String firstName;
    if (userDetails.data['name'] != null) {
      String name =  userDetails.data['name'];
      firstName = name.split(new RegExp('\\s+'))[0];
    }
    firstName = (firstName ?? "");
    firestore.runTransaction((Transaction t) async {
      await t.update(chatReference, <String, dynamic>{"last_updated": currentTime});
      await t.update(chatReference, <String, dynamic>{"last_message": firstName + " : " + text});
    });
    setState(() {
      _isComposing = false;
    });
  }

  void _sendVideoCallInvite(String channelName) async {
    FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
    DocumentSnapshot userDetails = await firestore
        .collection("kingdoms")
        .document(getUserOrganization(currentUser) ?? "")
        .collection("users")
        .document(currentUser.uid).get();
    Timestamp currentTime = Timestamp.now();
    var message = {
      'sender' : <String, dynamic>{'name': userDetails.data['name'], 'imageUrl': userDetails.data['photo_url']},
      'channel_name' : channelName,
      'text' : 'Video Call' + channelName,
      'timestamp': currentTime,
      "receiver" : widget.photoUserId,
      "type" : MESSAGE_TYPE_VIDEO_CALL_INVITATION
    };
    roomCollectionReference.add(message);
    DocumentReference chatReference = firestore
        .collection("kingdoms")
        .document(getUserOrganization(currentUser) ?? "")
        .collection('chats')
        .document(roomId);
    // below we store the timestamp indicating when the last update to the
    // chat was made. We also store the last message which caused this update.
    String firstName;
    if (userDetails.data['name'] != null) {
      String name =  userDetails.data['name'];
      firstName = name.split(new RegExp('\\s+'))[0];
    }
    firstName = (firstName ?? "");
    firestore.runTransaction((Transaction t) async {
      await t.update(chatReference, <String, dynamic>{"last_updated": currentTime});
      await t.update(chatReference, <String, dynamic>{"last_message": firstName + " : " + "VIDEO CALL INVITATION"});
    });
    setState(() {
      _isComposing = false;
    });
  }

  // Get the older 15 messages and update our state.
  void _getOldMessages() async {
    final snackBar = SnackBar(
      content: Text('Loading old messages'),
      duration: Duration(milliseconds: 800),
      backgroundColor: Colors.green,
    );
    // Find the Scaffold in the widget tree and use it to show a SnackBar.
    Scaffold.of(context).showSnackBar(snackBar);
    Timestamp minTimestamp = _messages.reversed.first.timestamp;
    QuerySnapshot querySnapshot = await roomCollectionReference
        .limit(15)
        .orderBy("timestamp", descending: true)
        .startAfter(<dynamic>[minTimestamp]).getDocuments();
    for (DocumentSnapshot docSnapshot in querySnapshot.documents) {
      _addMessageAtEnd(
          name: docSnapshot.data['sender']['name'],
          senderImageUrl: docSnapshot.data['sender']['imageUrl'],
          text: docSnapshot.data['text'],
          timestamp: docSnapshot.data['timestamp'],
          messageType: docSnapshot.data['type'],
          channelName: docSnapshot.data['channel_name']
      );
    }
  }

  // Build the field where you type your message.
  Widget _buildTextComposer() {
    return IconTheme(
        data: IconThemeData(color: Theme.of(context).accentColor),
        child: PlatformAdaptiveContainer(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(children: [
              Flexible(
                child: TextField(
                  controller: _chatInputController,
                  onChanged: _handleMessageChanged,
                  maxLines: null,
                  decoration:
                      InputDecoration.collapsed(hintText: 'Send a message'),
                ),
              ),
              Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.0),
                  child: PlatformAdaptiveButton(
                    icon: Icon(Icons.send),
                    onPressed: _isComposing
                        ? () {_handleSubmitted(_chatInputController.text);}
                        : null,
                    child: Text('Send'),
                  )),
            ])));
  }

  Widget build(BuildContext context) {
    if (_currentScrollListener != null) {
      _scrollController.removeListener(_currentScrollListener);
    }
    _currentScrollListener = getScrollListener(context);
    _scrollController.addListener(_currentScrollListener);
    return Scaffold(
      appBar: AppBar(
        title: _receivedMessage ? Text("Received Message") : Text("Chat"),
        actions: <Widget>[
          Container(
            margin: EdgeInsets.fromLTRB(0, 5, 15, 5),
            child: IconButton(
                  icon: Icon(Icons.video_call, size: 35,),
                  onPressed: () {
                    _joinVideoCallChannel();
                  }
                ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(0, 5, 10, 5),
            child: CircularPhoto(widget.photoUserId, 20),
          ),
        ]
      ),
      body: Center(
        child: Column(children: [
          Flexible(
              child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(8.0),
            reverse: true,
            itemBuilder: (_, int index) =>
                ChatMessageListItem(_messages[index]),
            itemCount: _messages.length,
          )),
          Divider(height: 1.0),
          Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              child: _buildTextComposer()),
        ]),
      ),
    );
  }

  _joinVideoCallChannel() async {
    // await for camera and mic permissions before pushing video page
    String channelName = randomAlpha(15);
    _sendVideoCallInvite(channelName);
  }
}

/// Represents a person involved in the chat. Includes information that will
/// displayed in the chat messages.
class ChatUser {
  ChatUser({this.name, this.imageUrl});
  final String name;
  final String imageUrl;
}

class ChatMessage {
  ChatMessage(this.type, {this.sender, this.text, this.animationController, this.timestamp, this.channelName});
  final ChatUser sender;
  final Timestamp timestamp;
  final String text;
  final AnimationController animationController;
  final String type;
  final String channelName;
}

/// Represents the root item that holds the chat message.
class ChatMessageListItem extends StatelessWidget {
  ChatMessageListItem(this.message);

  final ChatMessage message;

  Widget build(BuildContext context) {
    return SizeTransition(
        sizeFactor: CurvedAnimation(
            parent: message.animationController, curve: Curves.easeOut),
        axisAlignment: 0.0,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                    backgroundImage: NetworkImage(message.sender.imageUrl)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.sender.name,
                      style: Theme.of(context).textTheme.subhead),
                  Container(
                      margin: const EdgeInsets.only(top: 5.0),
                      child: ChatMessageContent(message)),
                ],
              ),
            ],
          ),
        ));
  }
}

/// Represents the text part of the chat message
class ChatMessageContent extends StatelessWidget {
  ChatMessageContent(this.message);

  final ChatMessage message;

  static _handleCameraAndMic() async {
    await PermissionHandler().requestPermissions(
        [PermissionGroup.camera, PermissionGroup.microphone]);
  }

  Widget build(BuildContext context) {
    //print("Message type : " + message.type);
    if ((message.type == MESSAGE_TYPE_VIDEO_CALL_INVITATION)
        && (message.channelName != null)) {
      return new Container(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new RaisedButton(onPressed: () async {
              await _handleCameraAndMic();
              if (message.channelName != null) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => new CallPage(
                          channelName: message.channelName,
                        )));
              }
            },
              color: Colors.deepPurpleAccent,
              textColor: Colors.white,
              child: Text("Join Video Call ", overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
    }

    //80% of screen width
    return new Container(
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Text(message.text, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
