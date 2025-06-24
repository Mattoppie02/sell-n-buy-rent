import 'package:flutter/material.dart';
import 'package:sell_n_buy_updated/features/buying/buying_homepage.dart';
import 'package:sell_n_buy_updated/features/renting/Renting_page.dart';
import 'package:sell_n_buy_updated/features/selling/Add_Listing_page.dart';
import 'package:sell_n_buy_updated/features/home/homepage.dart';



class CustomBottomNavBar extends StatelessWidget {
  final int? currentIndex;
  final Color backgroundColor;
  final Function(int)? onTap; // <-- Added

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    this.backgroundColor = Colors.black,
    this.onTap, // <-- Added
  }) : super(key: key);

  void _defaultOnTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget nextPage;

    switch (index) {
      case 0:
        nextPage = Homepage();
        break;
      case 1:
        nextPage = BuyingHomepage();
        break;
      case 2:
        nextPage = AddListingPage();
        break;
      default:
        nextPage = Homepage();
    }

    // Use push for AddListingPage to maintain navigation history
    // Use pushReplacement for other main pages to avoid stack buildup
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => nextPage),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextPage),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex ?? 0,
      backgroundColor: backgroundColor,
      selectedItemColor: const Color.fromARGB(255, 70, 182, 5),
      unselectedItemColor: const Color.fromARGB(255, 255, 255, 255),
      onTap: (index) {
        if (onTap != null) {
          onTap!(index); // Call user-defined onTap
        } else {
          _defaultOnTap(context, index); // Call default one if not defined
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          label: 'Buy/Rent',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'Add Listing',
        ),
      ],
      type: BottomNavigationBarType.fixed,
      selectedFontSize: currentIndex == null ? 0 : 14,
      unselectedFontSize: currentIndex == null ? 0 : 12,
      selectedIconTheme: IconThemeData(
        color: currentIndex == null ? Colors.grey : const Color.fromARGB(255, 70, 182, 5),
      ),
    );
  }
}
