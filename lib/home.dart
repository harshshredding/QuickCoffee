import 'package:flutter/material.dart';
import 'proposals.dart';
import 'user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'my_chats.dart';
import 'groups.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'helper.dart';

class Home extends StatefulWidget {
  HomeState createState() {
    return HomeState();
  }
}

class HomeState extends State<Home> {
  int _currentIndex = 0;
  final Set<String> trackNewMessages = new Set<String>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> _children;

  final FirebaseMessaging _fcm = FirebaseMessaging();
  StreamSubscription<IosNotificationSettings> iosSubscription;

  void initState() {
    super.initState();
    //Old
    _fcm.configure(
        onMessage: (Map<String, dynamic> message) async {
          print('$message');
          print("onMessage");
        },
        onResume: (Map<String, dynamic> message) async {
          print('$message');
          print("onResume");
        },
        onLaunch: (Map<String, dynamic> message) async {
          print('$message');
          print("onLaunch");
        }
    );
    _fcm.requestNotificationPermissions(const IosNotificationSettings(sound: true, badge: true, alert: true));
    _fcm.onIosSettingsRegistered.listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    registerToken();
  }

  void registerToken() async {
    String token = await _fcm.getToken();
    FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
    await Firestore.instance
        .collection("kingdoms")
        .document(getUserOrganization(currentUser) ?? "")
        .collection("users")
        .document(currentUser.uid)
        .collection("tokens")
        .document(token)
        .setData({
      "id": token
    });
  }

  HomeState() {
    _children = [
      Groups(),
      // We pass in null as filters to indicate this is the first time
      // proposals is being built.
      Proposals(),
      MyChats(this)
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: 40),
              child: ListTile(
                title: Text("My Info"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => UserProfile(true)));
                },
              ),
            )
            ,
            ListTile(
              title: Text("My Proposals"),
              onTap: () async {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/my_proposals");
              },
            ),
            ListTile(
              title: Text("My Favorites"),
              onTap: () async {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/my_favorites");
              },
            ),
            ListTile(
              title: Text("My Groups"),
              onTap: () async {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/my_groups");
              },
            ),
            ListTile(
              title: Text("Log Out"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, "/login_home_logout");
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.person, color: Colors.white,), onPressed: () {
          _scaffoldKey.currentState.openDrawer();
        }),
        title: Text("QuickCoffee"),
        actions: <Widget>[
          Container(
            margin: EdgeInsets.all(5),
            padding: EdgeInsets.all(5),
            child: RaisedButton(
              shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: EdgeInsets.all(0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 12,
              color: Colors.grey.shade800,
              child: Row( children: <Widget>[
                Icon(Icons.add, size: 20,),
                Text("proposal", style: TextStyle(fontSize: 10)),
              ],),
              onPressed: () {
                Navigator.pushNamed(context, '/addProposal');
              },
            ),
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _children,
      ),
      bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.grey.shade800,
          onTap: _onTabTapped,
          currentIndex: _currentIndex,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              title: Text('groups'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              title: Text('feed'),
            ),
            BottomNavigationBarItem(
              icon: trackNewMessages.isEmpty ? Icon(Icons.chat_bubble_outline) : Icon(Icons.clear),
              title: Text('chat'),
            ),
          ]
      )
    );
  }
}
