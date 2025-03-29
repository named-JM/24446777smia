import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:qrqragain/constants.dart';

class TreatmentPage extends StatefulWidget {
  @override
  _TreatmentPageState createState() => _TreatmentPageState();
}

class _TreatmentPageState extends State<TreatmentPage> {
  List<dynamic> items = [];
  String selectedCategory = 'All'; // Default category
  List<String> categories = ['All']; // List of categories
  bool isLoading = true; // Add a loading state

  @override
  void initState() {
    super.initState();
    loadData(); // Load data when the page initializes
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        isLoading = true; // Show loading indicator
      });
    }

    await checkInternetAndSync();
    await fetchMedicines();
    if (mounted) {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  Future<void> checkInternetAndSync() async {
    try {
      final response = await http.get(
        Uri.parse("$BASE_URL/check_connection.php"),
      );
      if (response.statusCode == 200) {
        await syncPendingUpdates();
      }
    } catch (e) {
      print("No internet connection");
    }
  }

  Future<void> syncPendingUpdates() async {
    final pendingUpdatesBox = await Hive.openBox('pending_updates');
    List<Map<String, dynamic>> updates = [];

    for (var update in pendingUpdatesBox.values) {
      updates.add(update);
    }

    if (updates.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('$BASE_URL/sync_offline.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'updates': updates}),
        );

        if (response.statusCode == 200) {
          print("Offline updates synced successfully!");
          await pendingUpdatesBox.clear();
        } else {
          print(
            "Failed to sync offline updates. Server Response: ${response.body}",
          );
        }
      } catch (e) {
        print("Error syncing offline updates: $e");
      }
    }
  }

  Future<void> fetchMedicines() async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL/get_items.php'));

      if (response.statusCode == 200) {
        setState(() {
          items = jsonDecode(response.body)['items'];

          // Extract unique categories
          categories = ['All'];
          categories.addAll(
            items.map((item) => item['category'].toString()).toSet().toList(),
          );
        });
      } else {
        print("Failed to load items. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching medicines: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator if data is still loading
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treatment Area')),
        body: const Center(
          child: CircularProgressIndicator(), // Loading spinner
        ),
      );
    }

    // Filter items based on the selected category
    final filteredItems =
        selectedCategory == 'All'
            ? items
            : items
                .where((item) => item['category'] == selectedCategory)
                .toList();

    // Limit the number of items displayed in the bar chart
    final limitedItems = filteredItems.take(10).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Treatment Area')),
      body: Column(
        children: [
          // Dropdown for category filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: selectedCategory,
              onChanged: (String? newValue) {
                setState(() {
                  selectedCategory = newValue!;
                });
              },
              isExpanded: true,
              items:
                  categories.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          if (limitedItems.isNotEmpty)
            SizedBox(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups:
                        limitedItems.map((medicine) {
                          return BarChartGroupData(
                            x: limitedItems.indexOf(medicine),
                            barRods: [
                              BarChartRodData(
                                toY: double.parse(
                                  medicine['quantity'].toString(),
                                ),
                                color: Colors.blue,
                                width: 16,
                              ),
                            ],
                          );
                        }).toList(),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final itemName =
                                limitedItems[value.toInt()]['item_name'];
                            return RotatedBox(
                              quarterTurns: 1,
                              child: Text(
                                itemName.length > 10
                                    ? '${itemName.substring(0, 10)}...'
                                    : itemName,
                                style: const TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: false, // Disable top titles
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.grey,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final medicine = limitedItems[group.x.toInt()];
                          return BarTooltipItem(
                            medicine['item_name'], // Show the item name
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchMedicines,
              child: ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final medicine = filteredItems[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        medicine['item_name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Remaining: ${medicine['quantity']}'),
                            ],
                          ),
                          Text('Category: ${medicine['category']}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
