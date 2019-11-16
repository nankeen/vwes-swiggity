import 'package:flutter/material.dart';
import 'package:swiggity/game.dart';

class JoinRoom extends StatefulWidget {
  JoinRoom({Key key}) : super(key: key);

  @override
  _JoinRoomState createState() => _JoinRoomState();
}

class _JoinRoomState extends State<JoinRoom> {
  final TextEditingController _roomIdController = TextEditingController();

  String validateRoomId() {
    if (_roomIdController.text.length == 0) {
      return 'Please enter a room ID';
    }

    // TODO: Make request to backend and verify that the room exists
    return null;
  }

  void joinRoom(BuildContext context) {
    String snackBarMsg = validateRoomId();
    if (snackBarMsg != null) {
      final snackbar = SnackBar(content: Text(snackBarMsg));
      Scaffold.of(context).showSnackBar(snackbar);
      return null;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameRoute(
          roomId: _roomIdController.text,
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Container(
          padding: EdgeInsets.symmetric(horizontal: 45.0),
              child: Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextField(
                  controller: _roomIdController,
                  decoration: InputDecoration(
                    hintText: 'Join a room with its ID',
                    labelText: 'Room ID'
                  ),
                ),
                RaisedButton(
                  child: Text("Join!"),
                  onPressed: () => joinRoom(context),
                )
              ],
            ),
          ),
        )
      )
    );
  }
}