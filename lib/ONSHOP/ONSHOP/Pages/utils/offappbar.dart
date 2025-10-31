import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class OffAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? selectedCity;
  final List<String> cities;
  final Function(String?)? onCityChanged;

  const OffAppBar({
    Key? key,
    required this.selectedCity,
    required this.cities,
    this.onCityChanged,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 255, 185, 41),
      toolbarHeight: 70,
      flexibleSpace: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          children: [
            // Logo Section
            const SizedBox(width: 45),
            ClipRRect(
              child: Image.asset("asset/appbarlogo.png", width: 50),
            ),
            const SizedBox(width: 10),

            // Title Section
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'On Shop',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Searchable City Dropdown
            if (cities.isNotEmpty)
              SizedBox(
                width: 150, // Adjust width as needed
                child: DropdownSearch<String>(
                  items: cities, // Pass the list directly
                  selectedItem: selectedCity,
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: "Search city...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  dropdownButtonProps: const DropdownButtonProps(
                    icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                  ),
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    baseStyle: TextStyle(color: Colors.black),
                    dropdownSearchDecoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Color.fromARGB(255, 255, 185, 41),
                    ),
                  ),
                  onChanged: onCityChanged,
                ),
              ),

            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}