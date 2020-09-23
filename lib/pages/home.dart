import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

import 'package:provider/provider.dart';

import 'package:band_names/services/socket_service.dart';
import 'package:band_names/models/band.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Band> bands = [];

  @override
  void initState() {
    final SocketService socketService =
        Provider.of<SocketService>(context, listen: false);
    socketService.socket.on('active-bands', _handleActiveBands);
    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    this.bands = (payload as List).map((band) => Band.fromMap(band)).toList();
    setState(() {});
  }

  @override
  void dispose() {
    final SocketService socketService =
        Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  void _displaySnackBar(String txt) {
    final snackBar = SnackBar(content: Text(txt));
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final SocketService socketService = Provider.of<SocketService>(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 1,
        title: Text(
          'BandNames',
          style: TextStyle(
            color: Colors.black87,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(
              right: 16.0,
            ),
            child: (socketService.serverStatus == ServerStatus.Online)
                ? Icon(Icons.check_circle, color: Colors.green)
                : Icon(Icons.error, color: Colors.red),
          )
        ],
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _showGraph(),
          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: (BuildContext context, int index) =>
                  _bandTile(bands[index]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBand,
        child: Icon(Icons.add),
        elevation: 1,
      ),
    );
  }

  Widget _bandTile(Band band) {
    final SocketService socketService =
        Provider.of<SocketService>(context, listen: false);
    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => socketService.socket.emit('delete-band', band.id),
      background: Container(
        padding: EdgeInsets.only(
          left: 8.0,
        ),
        color: Colors.red[400],
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Delete Band',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(band.name[0].toUpperCase()),
          backgroundColor: Colors.blue[100],
        ),
        title: Text(
          band.name,
          style: TextStyle(color: Colors.black87),
        ),
        trailing: Text('${band.votes}'),
        onTap: () => socketService.socket.emit('vote-band', {'id': band.id}),
      ),
    );
  }

  _addBand() {
    final textController = new TextEditingController();

    if (Platform.isIOS) {
      return showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('New band name'),
          content: TextField(
            controller: textController,
          ),
          actions: [
            MaterialButton(
              onPressed: () => validateBandName(textController.text),
              elevation: 5,
              color: Colors.blue,
              child: Text('Add'),
            ),
          ],
        ),
      );
    }

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('New band name'),
        content: CupertinoTextField(
          controller: textController,
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => validateBandName(textController.text),
            child: Text('Add'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
            ),
          ),
        ],
      ),
    );
  }

  void validateBandName(String name) {
    if (name.length > 0) {
      final SocketService socketService =
          Provider.of<SocketService>(context, listen: false);
      socketService.socket.emit('add-band', name);
      _displaySnackBar('Band $name, created!!');
      Navigator.pop(context);
    } else {
      _displaySnackBar('Fill Name');
    }
  }

  Widget _showGraph() {
    Map<String, double> dataMap = new Map();
    bands.forEach(
      (element) =>
          dataMap.putIfAbsent(element.name, () => element.votes.toDouble()),
    );
    return Container(
      width: double.infinity,
      height: 200,
      child: (bands.isEmpty)
          ? Center(child: CircularProgressIndicator())
          : PieChart(dataMap: dataMap),
    );
  }
}
