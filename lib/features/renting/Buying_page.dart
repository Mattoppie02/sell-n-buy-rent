import 'package:flutter/material.dart';
import 'package:sell_n_buy_updated/features/renting/Renting_page.dart';
import 'package:sell_n_buy_updated/widget/bottom_navigation.dart';

class BuyingShoesPage extends StatelessWidget {
  final List<Map<String, String>> shoes = [
    {
      'name': 'Adidas Mustard',
      'price': 'RM 330.00',
      'image': 'assets/images/preloved samba.jpg',
    },
    {
      'name': 'Asics NYC',
      'price': 'RM 40.00',
      'image': 'assets/images/NYC.jpg',
    },
    {
      'name': 'Adidas Samba',
      'price': 'RM 320.00',
      'image': 'assets/images/samba.jpg',
    },
    {
      'name': 'New Balance 2002r',
      'price': 'RM 400.00',
      'image': 'assets/images/2002r.jpg',
    },
    {
      'name': 'Nike Air Max',
      'price': 'RM 350.00',
      'image': 'assets/images/airmax tn.png',
    },
    {
      'name': 'Adidas Forum',
      'price': 'RM 280.00',
      'image': 'assets/images/campus.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Buying Shoes',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: StadiumBorder(),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) =>  RentingShoesPage()),
                          (route) => false,
                        );
              },
              child: Text('Renting?', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                filled: true,
                fillColor: Color(0xFFDDF2A6),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.55,
              ),
              itemCount: shoes.length,
              itemBuilder: (context, index) {
                final shoe = shoes[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        shoe['image']!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      shoe['name']!,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      shoe['price']!,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 1,),
    );
  }
}
