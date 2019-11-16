import 'dart:async';
import 'dart:math';

import 'config.dart';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sensors/sensors.dart';

class GameRoute extends StatefulWidget {
  final WebSocketChannel channel;
  final String roomId;

  GameRoute({Key key, @required this.roomId, @required this.channel}): super(key: key);

  @override
  _GameRouteState createState() => _GameRouteState();
}

class _GameRouteState extends State<GameRoute> {
  StreamSubscription _accelerometerSubscription;
  double _swingIntegral = 0;
  Timer _swingTimer;

  @override
  void initState() {
    super.initState();

    // Bind listeners
    _accelerometerSubscription = accelerometerEvents
      .map((event) => pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2))
      //.where((event) => event > 500)
      .listen(handleSwing);
  }

  handleSwing(magnitudeSquared) {
    _swingIntegral = magnitudeSquared;
    if (_swingTimer == null || !_swingTimer.isActive) {
      _swingTimer = Timer(Duration(milliseconds: 100), () {
        if (_swingIntegral > 1500) {
          print('Soft swing');
        }
        _swingIntegral = 0;
      });
    }

    if (_swingIntegral > 5000) {
      print('Hard swing');
      _swingTimer.cancel();
      _swingIntegral = 0;
    }
  }

  Widget buildFromWS(BuildContext context, AsyncSnapshot snapshot) {
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
    if (snapshot.hasError) {
      return Column(
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
                    channel: IOWebSocketChannel.connect('ws://$BACKEND_HOST/${widget.roomId}')
                  )
                )
              );
            }
          )
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
          stream: widget.channel.stream,
          builder: buildFromWS,
        ),
    )
    );
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    _accelerometerSubscription.cancel();
    super.dispose();
  }
}