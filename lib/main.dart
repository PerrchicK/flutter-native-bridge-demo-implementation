import 'package:flutter/material.dart';
import 'package:method_channel_example/native_bridge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NativeBridge.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Method Channel Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final TextEditingController keyController = TextEditingController();
  final TextEditingController valueController = TextEditingController();

  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: StatefulBuilder(
          builder: (context, stateSetter) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextField(
                  controller: keyController,
                  decoration: InputDecoration(hintText: "<key>"),
                ),
                TextField(
                  controller: valueController,
                  decoration: InputDecoration(hintText: "<value>"),
                ),
                ElevatedButton(
                  child: Text("Save"),
                  onPressed: () {
                    if (keyController.text?.isEmpty ?? true) return;

                    NativeBridge.saveToSecuredData(
                        key: keyController.text, value: valueController.text);
                  },
                ),
                ElevatedButton(
                    child: Text("Load"),
                    onPressed: () async {
                      if (keyController.text?.isEmpty ?? true) return;

                      String loadedData =
                          await NativeBridge.loadFromSecuredData(
                              key: keyController.text,
                              defaultValue: valueController.text);
                      stateSetter(() {
                        valueController.text = loadedData;
                      });
                    }),
              ],
            );
          },
        ),
      ),
//      floatingActionButton: FloatingActionButton(
//        onPressed: _someOperation,
//        tooltip: 'Do Something',
//        child: Icon(Icons.add),
//      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
