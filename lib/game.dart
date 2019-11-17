import 'dart:async';
import 'dart:math';

import 'config.dart';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sensors/sensors.dart';
import 'package:vibration/vibration.dart';

class GameRoute extends StatefulWidget {
  final String roomId;

  GameRoute({Key key, @required this.roomId}): super(key: key);

  @override
  _GameRouteState createState() => _GameRouteState();
}

class _GameRouteState extends State<GameRoute> {
  StreamSubscription _accelerometerSubscription;
  double _swingIntegral = 0;
  Timer _swingTimer;
  bool timeOut = false;
  WebSocketChannel channel;

  @override
  void initState() {
    super.initState();

    // Bind listeners
    _accelerometerSubscription = accelerometerEvents
      .map((event) => pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2))
      //.where((event) => event > 500)
      .distinct()
      .listen(handleSwing);
    channel = IOWebSocketChannel.connect('ws://$BACKEND_HOST/ws/rooms/${widget.roomId}/');
  }

  sendSwing(String strength) {
    if (!timeOut) {
      channel.sink.add('{"action": "$strength"}');

      if (strength == 'soft') {
        Vibration.vibrate(duration: 250);
      } else {
        Vibration.vibrate(duration: 750);
      }

      timeOut = true;
      Timer(Duration(seconds: 1), () {
        timeOut = false;
        _swingIntegral = 0;
      });
    }
  }

  handleSwing(num magnitudeSquared) {
    if (magnitudeSquared > 500) {
      _swingIntegral += magnitudeSquared;
    }
    if (_swingTimer == null || !_swingTimer.isActive) {
      _swingTimer = Timer(Duration(milliseconds: 100), () {
        if (_swingIntegral > 2000) {
          sendSwing('soft');
        }
        _swingIntegral = 0;
      });
    }

    if (_swingIntegral > 10000) {
      _swingTimer.cancel();
      sendSwing('hard');
      _swingIntegral = 0;
    }
  }

  Widget buildFromWS(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.hasError) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.error),
          Text('Can\'t join the room. Retry?'),
          IconButton(
            icon: Icon(Icons.refresh),
            iconSize: 16.0,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => GameRoute(
                    roomId: widget.roomId,
                  )
                )
              );
            }
          )
        ]
      );
    }
    if (!snapshot.hasData) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SpinKitWave(
            color: Colors.accents[0],
            size: 70.0,
          ),
          Text('Joining ${widget.roomId}')
        ]
      );
    }

    return Text('READY!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: StreamBuilder(
          stream: channel.stream,
          builder: buildFromWS,
        ),
      )
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    _accelerometerSubscription.cancel();
    super.dispose();
  }
}