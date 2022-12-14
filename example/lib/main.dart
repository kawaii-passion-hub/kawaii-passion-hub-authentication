import 'package:event_bus/event_bus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kawaii_passion_hub_authentication/kawaii_passion_hub_authentication.dart'
    as auth_lib;
import 'firebase_options.dart';

const bool useEmulator = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseApp app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  EventBus globalBus = initializeApp(app);
  runApp(MyApp(
    eventBus: globalBus,
  ));
}

EventBus initializeApp(FirebaseApp app) {
  EventBus globalBus = EventBus();
  GetIt.I.registerSingleton(globalBus);
  GetIt.I.registerSingleton(app, instanceName: auth_lib.FirebaseAppName);
  auth_lib.initialize(useEmulator: useEmulator);
  return globalBus;
}

class EventBusWidget extends InheritedWidget {
  /// [EventBus] that provided by this widget
  final EventBus eventBus;

  /// Default constructor that create a default [EventBus] and provided it to [child] widget and its children.
  /// A [key] can be provided if necessary
  /// If [eventBus] is not given, a new [EventBus] is created, and [sync] is respected. [sync] decides the created event bus
  /// is `synchronized` or `asynchronized`, default to `asynchronized`.
  /// If [eventBus] is given, [sync] is ignored
  ///
  /// The [eventBus] param chould be useful if you want to access eventBus from widget who hold [EventBusWidget],
  /// or you are using custom [StreamController] in Event Bus.
  const EventBusWidget(
      {Key? key, required Widget child, required this.eventBus})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(EventBusWidget oldWidget) =>
      eventBus != oldWidget.eventBus;

  /// Find the closeset [EventBusWidget] from ancester tree.
  static EventBusWidget of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EventBusWidget>()!;
}

class MyApp extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  MyApp({Key? key, required this.eventBus}) : super(key: key);

  final EventBus eventBus;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return EventBusWidget(
      eventBus: eventBus,
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget result = StreamBuilder<auth_lib.UserInformationUpdated?>(
      stream: EventBusWidget.of(context)
          .eventBus
          .on<auth_lib.UserInformationUpdated>(),
      initialData: auth_lib.AuthentificationState.current != null
          ? auth_lib.UserInformationUpdated(
              auth_lib.AuthentificationState.current!)
          : null,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.newUser.isAuthenticated) {
          return auth_lib.AuthenticationWidget(
            googleClientId: const String.fromEnvironment('GOOGLE_CLIENT_ID'),
            logo: Image.asset('assets/icon.jpg'),
          );
        }
        if (kDebugMode) {
          print(
              '${snapshot.data!.newUser.name} - ${snapshot.data!.newUser.claims!['whitelisted']}');
        }
        return MyHomePage(title: "App for ${snapshot.data!.newUser.name}");
      },
    );
    return result;
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
