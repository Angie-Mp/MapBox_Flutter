import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_mapbox_navigation/library.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _instruction = "";
  final _origin = WayPoint(
      name: "Way Point 1", latitude: -12.130840, longitude: -76.979775);
  final _stop1 = WayPoint(
      name: "Way Point 2", latitude: -12.154339, longitude: -76.982378);

  MapBoxNavigation _directions;
  MapBoxOptions _options;

  bool _arrived = false;
  bool _isMultipleStop = false;
  double _distanceRemaining, _durationRemaining;
  MapBoxNavigationViewController _controller;
  bool _routeBuilt = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initialize() async {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    _directions = MapBoxNavigation(onRouteEvent: _onEmbeddedRouteEvent);
    _options = MapBoxOptions(
        //initialLatitude: 36.1175275,
        //initialLongitude: -115.1839524,
        zoom: 15.0,
        tilt: 0.0,
        bearing: 0.0,
        enableRefresh: false,
        alternatives: true,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        allowsUTurnAtWayPoints: true,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        units: VoiceUnits.imperial,
        simulateRoute: false,
        animateBuildRoute: true,
        longPressDestinationEnabled: true,
        language: "es");

    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await _directions.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Google MPs'),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                child: Text(""),
              ),
              ListTile(
                title: Container(
                  color: Colors.grey,
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: (Text(
                      _instruction == null || _instruction.isEmpty
                          ? "En camino .."
                          : _instruction,
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    )),
                  ),
                ),
              ),
              ListTile(
                title: RaisedButton(
                  child:
                      Text("Recorrido de la U.Ricardo Palma al Mall del Sur "),
                  onPressed: () async {
                    var wayPoints = List<WayPoint>();
                    wayPoints.add(_origin);
                    wayPoints.add(_stop1);

                    await _directions.startNavigation(
                        wayPoints: wayPoints,
                        options: MapBoxOptions(
                            mode: MapBoxNavigationMode.drivingWithTraffic,
                            simulateRoute: true,
                            language: "es",
                            units: VoiceUnits.metric));
                  },
                ),
              ),
              ListTile(
                title: RaisedButton(
                  child: Text(_routeBuilt && !_isNavigating
                      ? "Sin Ruta"
                      : "Mostrar la ruta como principal"),
                  onPressed: _isNavigating
                      ? null
                      : () {
                          if (_routeBuilt) {
                            _controller.clearRoute();
                          } else {
                            var wayPoints = List<WayPoint>();
                            wayPoints.add(_origin);
                            wayPoints.add(_stop1);

                            wayPoints.add(_origin);
                            _isMultipleStop = wayPoints.length > 2;
                            _controller.buildRoute(wayPoints: wayPoints);
                          }
                        },
                ),
              )
            ],
          ),
        ),
        body: Center(
          child: Column(children: <Widget>[
            //el mapa que se muestra debajo
            Expanded(
              flex: 10,
              child: Container(
                color: Colors.grey,
                child: MapBoxNavigationView(
                    options: _options,
                    onRouteEvent: _onEmbeddedRouteEvent,
                    onCreated:
                        (MapBoxNavigationViewController controller) async {
                      _controller = controller;
                      controller.initialize();
                    }),
              ),
            )
          ]),
        ),
      ),
    );
  }

  Future<void> _onEmbeddedRouteEvent(e) async {
    _distanceRemaining = await _directions.distanceRemaining;
    _durationRemaining = await _directions.durationRemaining;

    switch (e.eventType) {
      case MapBoxEvent.progress_change:
        var progressEvent = e.data as RouteProgressEvent;
        _arrived = progressEvent.arrived;
        if (progressEvent.currentStepInstruction != null)
          _instruction = progressEvent.currentStepInstruction;
        break;
      case MapBoxEvent.route_building:
      case MapBoxEvent.route_built:
        setState(() {
          _routeBuilt = true;
        });
        break;
      case MapBoxEvent.route_build_failed:
        setState(() {
          _routeBuilt = false;
        });
        break;
      case MapBoxEvent.navigation_running:
        setState(() {
          _isNavigating = true;
        });
        break;
      case MapBoxEvent.on_arrival:
        _arrived = true;
        if (!_isMultipleStop) {
          await Future.delayed(Duration(seconds: 3));
          await _controller.finishNavigation();
        } else {}
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        setState(() {
          _routeBuilt = false;
          _isNavigating = false;
        });
        break;
      default:
        break;
    }
    setState(() {});
  }
}
