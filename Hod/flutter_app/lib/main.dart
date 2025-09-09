import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/providers/app_provider.dart';
import 'src/screens/address_list_screen.dart';
import 'src/screens/map_screen.dart';
import 'src/screens/route_history_screen.dart';

void main() {
  runApp(const HodApp());
}

class HodApp extends StatelessWidget {
  const HodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: MaterialApp(
        title: 'Hod',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const RootTabs(),
      ),
    );
  }
}

class RootTabs extends StatefulWidget {
  const RootTabs({super.key});

  @override
  State<RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<RootTabs> {
  int _index = 0;

  final _pages = const [
    AddressListScreen(),
    MapScreen(),
    RouteHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: 'Адреса'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Карта'),
          NavigationDestination(icon: Icon(Icons.history), label: 'История'),
        ],
      ),
    );
  }
}


