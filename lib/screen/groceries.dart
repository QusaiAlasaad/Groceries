import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/screen/add_grocery.dart';
import 'package:http/http.dart' as http;

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  List<GroceryItem> groceryItems = [];
  late Future<List<GroceryItem>> loadedItems;
  var isloading = true;
  String? error;

  @override
  void initState() {
    _loadItems();
    super.initState();
  }

  void _loadItems() async {
    final url = Uri.https('shopping-list-6eada-default-rtdb.firebaseio.com',
        'shopping-list.json');
    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception('no response from the server');
    }

    if (response.body == 'null') {
      return;
    }

    final Map<String, dynamic> dataList = json.decode(response.body);
    final List<GroceryItem> list = [];

    for (final item in dataList.entries) {
      final category = categories.entries
          .firstWhere((element) => element.value.name == item.value['category'])
          .value;
      list.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    setState(() {
      groceryItems = list;
      isloading = false;
    });
  }

  void addItim() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
        MaterialPageRoute(builder: (context) => const AddGrocery()));
    if (newItem == null) {
      return;
    }
    setState(
      () {
        groceryItems.add(newItem);
      },
    );
  }

  void removeItem(GroceryItem item) async {
    setState(
      () {
        groceryItems.remove(item);
      },
    );
    final url = Uri.https('shopping-list-6eada-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(
        () {
          groceryItems.add(item);
        },
      );
      if (!context.mounted) {
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('item was not deleted'),
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: StadiumBorder(),
        ));
      }
    } else {
      if (!context.mounted) {
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('item was successfully deleted'),
            duration: Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: StadiumBorder(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items added yet.'),
    );

    if (isloading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: groceryItems.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: ValueKey(groceryItems[index].id),
            onDismissed: (direction) {
              removeItem(
                groceryItems[index],
              );
            },
            child: ListTile(
              title: Text(groceryItems[index].name),
              leading: Container(
                color: groceryItems[index].category.color,
                width: 25,
                height: 25,
              ),
              trailing: Text(
                groceryItems[index].quantity.toString(),
              ),
            ),
          );
        },
      );
    }

    if (error != null) {
      content = Center(
        child: Text(error!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Groceries',
          style: Theme.of(context)
              .textTheme
              .titleLarge!
              .copyWith(color: Theme.of(context).colorScheme.onBackground),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addItim,
          ),
        ],
      ),
      body: content,
    );
  }
}
