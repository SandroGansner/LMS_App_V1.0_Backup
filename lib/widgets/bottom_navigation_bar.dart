import 'package:flutter/material.dart';

class BottomNavigationBarWidget extends StatefulWidget {
  const BottomNavigationBarWidget({super.key});

  @override
  _BottomNavigationBarWidgetState createState() =>
      _BottomNavigationBarWidgetState();
}

class _BottomNavigationBarWidgetState extends State<BottomNavigationBarWidget> {
  int _currentIndex = 0;

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // permanent visibility
      elevation: 0, // removed elevation to eliminate white border/shadow
      currentIndex: _currentIndex,
      onTap: onTabTapped,
      backgroundColor: const Color.fromARGB(255, 235, 19, 19),
      selectedItemColor: Colors.red, // changed icon color to red
      unselectedItemColor: Colors.red, // changed icon color to red
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Einkauf',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt),
          label: 'Spesen',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.campaign),
          label: 'Kampagnen',
        ),
      ],
    );
  }
}
