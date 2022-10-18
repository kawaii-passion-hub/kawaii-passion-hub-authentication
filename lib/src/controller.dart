import 'dart:async';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';
import 'model.dart';
import 'constants.dart' as constants;

bool initialized = false;

void initialize({bool useEmulator = false}) {
  if (initialized) {
    return;
  }
  initialized = true;

  FirebaseApp authApp =
      GetIt.I<FirebaseApp>(instanceName: constants.FirebaseAppName);

  if (useEmulator) {
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    const authPort = 9099;
    const databasePort = 9000;

    // ignore: avoid_print
    print('Running with auth emulator.');

    FirebaseDatabase.instanceFor(app: authApp)
        .useDatabaseEmulator(host, databasePort);
    FirebaseAuth.instanceFor(app: authApp).useAuthEmulator(host, authPort);
  }

  EventBus globalBus = GetIt.I<EventBus>();
  EventBus localBus = EventBus();
  Controller controller = Controller(globalBus, localBus, authApp);
  GetIt.I.registerSingleton(controller);
  GetIt.I.registerSingleton(localBus,
      instanceName: 'kawaii_passion_hub_authentication');
  controller.subscribeToUserEvents();
}

class Controller extends Disposable {
  final EventBus globalBus;
  final EventBus localBus;
  final FirebaseApp authApp;
  StreamSubscription<DatabaseEvent>? eventSubscription;
  StreamSubscription<User?>? userSubscription;

  Controller(this.globalBus, this.localBus, this.authApp);

  void subscribeToUserEvents() {
    userSubscription = FirebaseAuth.instanceFor(app: authApp)
        .authStateChanges()
        .listen((event) {
      checkUserInformation(optionalUser: event);
    });
    checkUserInformation();
  }

  void checkUserInformation({User? optionalUser}) async {
    User? user =
        optionalUser ?? FirebaseAuth.instanceFor(app: authApp).currentUser;
    UserInformation info;
    if (user == null) {
      info = const UserInformation(false, null, null, null);
    } else {
      IdTokenResult idToken = await user.getIdTokenResult(true);
      String jwt = await user.getIdToken();
      final stream = FirebaseDatabase.instanceFor(app: authApp)
          .ref('metadata/${user.uid}/refreshTime')
          .onValue;
      eventSubscription?.cancel();
      eventSubscription = stream.listen((event) async {
        idToken = await user.getIdTokenResult(true);
        jwt = await user.getIdToken();
        info = UserInformation(true, user.displayName, idToken.claims, jwt);
        globalBus.fire(UserInformationUpdated(info));
      });
      info = UserInformation(true, user.displayName, idToken.claims, jwt);
    }
    AuthentificationState.current = info;
    globalBus.fire(UserInformationUpdated(info));
  }

  @override
  FutureOr onDispose() {
    eventSubscription?.cancel();
    userSubscription?.cancel();
  }
}
