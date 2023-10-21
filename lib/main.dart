import 'dart:typed_data';
import 'package:ndef/ndef.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ValueNotifier<dynamic> result = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('NfcManager Plugin Example')),
        body: SafeArea(
          child: FutureBuilder<bool>(
            future: NfcManager.instance.isAvailable(),
            builder: (context, ss) => ss.data != true
                ? Center(child: Text('NfcManager.isAvailable(): ${ss.data}'))
                : Flex(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    direction: Axis.vertical,
                    children: [
                      Flexible(
                        flex: 2,
                        child: Container(
                          margin: EdgeInsets.all(4),
                          constraints: BoxConstraints.expand(),
                          decoration: BoxDecoration(border: Border.all()),
                          child: SingleChildScrollView(
                            child: ValueListenableBuilder<dynamic>(
                              valueListenable: result,
                              builder: (context, value, _) =>
                                  Text('${value ?? ''}'),
                            ),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 3,
                        child: GridView.count(
                          padding: EdgeInsets.all(4),
                          crossAxisCount: 2,
                          childAspectRatio: 4,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          children: [
                            ElevatedButton(
                                child: Text('Tag Read'),
                                onPressed: _tagRead), //_tagRead
                            ElevatedButton(
                                child: Text('Ndef Write'),
                                onPressed: _ndefWrite),
                            ElevatedButton(
                                child: Text('Ndef Write Lock'),
                                onPressed: _ndefWriteLock),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
  String ndefData = 'NDEF data will be displayed here';

  void _tagRead() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      Ndef? ndef = Ndef.from(tag);
      print('Tag ID: ${tag.identifier}');
      print('Tech List: ${tag.techList}');
      if (ndef != null) {
      try {
        NdefMessage message = await ndef.read();
        setState(() {
          ndefData = 'NDEF Data: $message';
        });
      } catch (e) {
        setState(() {
          ndefData = 'Error reading NDEF data: $e';
        });
      }
    } else {
      setState(() {
        ndefData = 'NDEF not supported on this tag';
      });
    }
      
      result.value = tag.data;
      print(ndefData);

      // print(tag.data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tag Read'),
          duration: Duration(seconds: 2), // Adjust the duration as needed
        ),
      );
      NfcManager.instance.stopSession();
    });
  }

  late String query;

  // void sc() {
  //   final TextEditingController searchController = TextEditingController();
  //   print("bhdfbsdhbf");
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Search'),
  //         content: TextField(
  //           controller: searchController,
  //           decoration: InputDecoration(labelText: 'Enter your text'),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: Text('Cancel'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             child: Text('Search'),
  //             onPressed: () {
  //               query = searchController.text;
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _ndefWrite() {
    // sc();
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null || !ndef.isWritable) {
        result.value = 'Tag is not ndef writable';
        NfcManager.instance.stopSession(errorMessage: result.value);
        return;
      }

      NdefMessage message = NdefMessage([
        NdefRecord.createUri(Uri.parse('https://flutter.dev')),
        NdefRecord.createText("kartik"),
        NdefRecord.createMime(
            'text/plain', Uint8List.fromList('Hello'.codeUnits)),
        NdefRecord.createExternal(
            'com.example', 'mytype', Uint8List.fromList('mydata'.codeUnits)),
      ]);

      try {
        await ndef.write(message);
        result.value = 'Success to "Ndef Write"';
        NfcManager.instance.stopSession();
      } catch (e) {
        result.value = e;
        NfcManager.instance.stopSession(errorMessage: result.value.toString());
        return;
      }
    });
  }

  void _ndefWriteLock() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null) {
        result.value = 'Tag is not ndef';
        NfcManager.instance.stopSession(errorMessage: result.value.toString());
        return;
      }

      try {
        await ndef.writeLock();
        result.value = 'Success to "Ndef Write Lock"';
        NfcManager.instance.stopSession();
      } catch (e) {
        result.value = e;
        NfcManager.instance.stopSession(errorMessage: result.value.toString());
        return;
      }
    });
  }
}
