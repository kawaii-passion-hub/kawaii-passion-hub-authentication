import 'dart:async';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'model.dart';

void initialize() {
  if (kDebugMode) {
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    const authPort = 9099;
    const databasePort = 9000;

    print('Running with auth emulator.');

    FirebaseDatabase.instance.useDatabaseEmulator(host, databasePort);
    FirebaseAuth.instance.useAuthEmulator(host, authPort);
  }

  EventBus globalBus = GetIt.I<EventBus>();
  EventBus localBus = EventBus();
  Controller controller = Controller(globalBus, localBus);
  GetIt.I.registerSingleton(controller);
  GetIt.I.registerSingleton(localBus,
      instanceName: 'kawaii_passion_hub_authentication');
  controller.subscribeToUserEvents();
}

class Controller extends Disposable {
  final EventBus globalBus;
  final EventBus localBus;
  StreamSubscription<DatabaseEvent>? eventSubscription;
  StreamSubscription<User?>? userSubscription;

  Controller(this.globalBus, this.localBus);

  void subscribeToUserEvents() {
    userSubscription = FirebaseAuth.instance.authStateChanges().listen((event) {
      checkUserInformation(optionalUser: event);
    });
    checkUserInformation();
  }

  void checkUserInformation({User? optionalUser}) async {
    User? user = optionalUser ?? FirebaseAuth.instance.currentUser;
    UserInformation info;
    if (user == null) {
      info = const UserInformation(false, null, null);
    } else {
      IdTokenResult idToken = await user.getIdTokenResult(true);
      final stream = FirebaseDatabase.instance
          .ref('metadata/${user.uid}/refreshTime')
          .onValue;
      eventSubscription?.cancel();
      eventSubscription = stream.listen((event) async {
        idToken = await user.getIdTokenResult(true);
        info = UserInformation(true, user.displayName, idToken.claims);
        globalBus.fire(UserInformationUpdated(info));
      });
      info = UserInformation(true, user.displayName, idToken.claims);
    }
    globalBus.fire(UserInformationUpdated(info));
  }

  @override
  FutureOr onDispose() {
    eventSubscription?.cancel();
    userSubscription?.cancel();
  }
}
