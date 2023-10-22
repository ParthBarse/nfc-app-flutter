import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ECard Wallet'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'NFC'),
            Tab(text: 'OCR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ContentTab(),
          OcrTab(), // Updated to OcrTab
        ],
      ),
    );
  }
}

class ContentTab extends StatefulWidget {
  @override
  ContentTabState createState() => ContentTabState();
}

class ContentTabState extends State<ContentTab> {
  ValueNotifier<dynamic> result = ValueNotifier(null);
  String ndefData = 'NDEF data will be displayed here';

  TextEditingController _writeDataController = TextEditingController();

  Future<String> fetchData(String data) async {
    final url = Uri.parse(
        'https://getcode-ndef-api.vercel.app/convert?data=${data}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String message = data['textData'];
        return message;
      } else {
        return "Failed to load data";
      }
    } catch (e) {
      return "Failed to load data: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 16), // Add margin from the top
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Place buttons side by side
          children: [
            ElevatedButton(
              child: Text('Tag Read'),
              onPressed: _tagRead,
            ),
            ElevatedButton(
              child: Text('Ndef Write'),
              onPressed: () => _writeData(context),
            ),
          ],
        ),
        SizedBox(height: 16), // Add margin below buttons
        Container(
          margin: EdgeInsets.only(top: 48), // Adjust the margin as needed
          child: ValueListenableBuilder<dynamic>(
            valueListenable: result,
            builder: (context, value, _) => Text(
              '${value ?? ''}',
              style: TextStyle(
                fontSize: 24, // Adjust the font size as needed
                fontWeight: FontWeight.bold, // Make it bold
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _tagRead() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reading NDEF Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(), // Display a loading indicator
              SizedBox(height: 16),
              Text('Please hold the NFC card near the device.'),
            ],
          ),
        );
      },
    );

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      Ndef? ndef = Ndef.from(tag);
      if (ndef != null) {
        try {
          NdefMessage message = await ndef.read();
          setState(() {
            ndefData = 'NDEF Data: $message';
          });

          String? ndefData1 = await fetchData(tag.data.toString());
          result.value = ndefData1;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Card Read Successfully.'),
              duration: Duration(seconds: 2),
            ),
          );
        } catch (e) {
          setState(() {
            ndefData = 'Error reading NDEF data: $e';
          });
        } finally {
          Navigator.of(context).pop(); // Close the reading dialog
        }
      } else {
        setState(() {
          ndefData = 'NDEF not supported on this tag';
        });
        Navigator.of(context).pop(); // Close the reading dialog
      }
      NfcManager.instance.stopSession();
    });
  }

  void _writeData(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Write Ndef Data'),
          content: TextField(
            controller: _writeDataController,
            decoration: InputDecoration(labelText: 'Enter Ndef Data'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Write'),
              onPressed: () {
                Navigator.of(context).pop();
                _writeNdefData(_writeDataController.text);
              },
            ),
          ],
        );
      },
    );
  }

  void _writeNdefData(String data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Writing NDEF Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(), // Display a loading indicator
              SizedBox(height: 16),
              Text('Please hold the NFC card near the device for writing.'),
            ],
          ),
        );
      },
    );

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null || !ndef.isWritable) {
        result.value = 'Tag is not ndef writable';
        NfcManager.instance.stopSession(errorMessage: result.value);
        Navigator.of(context).pop(); // Close the writing dialog
        return;
      }

      NdefMessage message = NdefMessage([
        NdefRecord.createMime(
            'text/plain', Uint8List.fromList(data.codeUnits)),
      ]);

      try {
        await ndef.write(message);
        result.value = 'Successfully wrote NDEF data';
        NfcManager.instance.stopSession();
        Navigator.of(context).pop(); // Close the writing dialog
      } catch (e) {
        result.value = e;
        NfcManager.instance.stopSession(errorMessage: result.value.toString());
        Navigator.of(context).pop(); // Close the writing dialog
        return;
      }
    });
  }
}

class OcrTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('OCR'),
    );
  }
}