import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'data/app_database.dart';
import 'data/cheapshark_api.dart';
import 'data/game_info_api.dart';
import 'state/exchange_provider.dart';
import 'state/deals_provider.dart';
import 'state/session_provider.dart';
import 'ui/auth_screens.dart';
import 'ui/catalog_screens.dart';
import 'ui/style.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PixelRadar(database: AppDatabase(databaseFactory)));
}

class PixelRadar extends StatelessWidget {
  const PixelRadar({super.key, required this.database});
  final AppDatabase database;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<http.Client>(
        create: (_) => http.Client(),
        dispose: (_, client) => client.close(),
      ),
      ChangeNotifierProvider(create: (_) => SessionProvider(database)),
      Provider(create: (context) => GameInfoApi(context.read<http.Client>())),
      ChangeNotifierProvider(
        create: (context) =>
            ExchangeProvider(context.read<http.Client>(), database)..refresh(),
      ),
    ],
    child: MaterialApp(
      title: 'Pixel Radar',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: appTheme(),
      home: Consumer<SessionProvider>(
        builder: (context, session, _) {
          if (session.user == null) return const LoginScreen();
          return ChangeNotifierProvider(
            key: ValueKey(session.user!.id),
            create: (context) =>
                DealsProvider(CheapSharkApi(context.read<http.Client>()))
                  ..load(),
            child: const CatalogScreen(),
          );
        },
      ),
    ),
  );
}
