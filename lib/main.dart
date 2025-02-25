import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'tabs/examination_room.dart';
import 'tabs/washing_room.dart';
import 'tabs/statistics_page.dart';
import 'tabs/settings.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'provider/patient_provider.dart';
import 'provider/settings_provider.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PatientProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [const Locale('ko', 'KR'), const Locale('en', 'US')],
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, userSnapshot) {
          if (userSnapshot.hasData) {
            return MyHomePage();
          }
          return LoginPage();
        },
      ),
      routes: {'/home': (ctx) => MyHomePage()},
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  final int initialTabIndex;

  MyHomePage({this.initialTabIndex = 0});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '안성 성모 내시경센터',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                  shadows: [
                    Shadow(
                      offset: Offset(1.0, 1.0),
                      blurRadius: 2.0,
                      color: Colors.blue.shade100,
                    ),
                  ],
                ),
              ),
            ),
            Image.asset('assets/images/ansung.png', width: 40, height: 40),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ExaminationRoom(),
          WashingRoom(),
          StatisticsPage(tabController: _tabController),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.search), text: '검사실'),
            Tab(icon: Icon(Icons.cleaning_services), text: '세척실'),
            Tab(icon: Icon(Icons.bar_chart), text: '통계'),
            Tab(icon: Icon(Icons.settings), text: '설정'),
          ],
          labelColor: Colors.blue[700],
          unselectedLabelColor: Colors.grey[400],
          indicatorColor: Colors.blue[700],
          indicatorWeight: 3,
          labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
