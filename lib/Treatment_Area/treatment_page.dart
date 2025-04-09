import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
  List<dynamic> removalLogs = [];

  @override
  void initState() {
    super.initState();
    loadData(); // Load data when the page initializes
    fetchRemovalLogs(); // Load logs
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

  Future<void> fetchRemovalLogs() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/get_removal_logs.php'),
      );

      if (response.statusCode == 200) {
        setState(() {
          removalLogs = jsonDecode(response.body)['logs'];
        });
      } else {
        print(
          "Failed to load removal logs. Status Code: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("Error fetching removal logs: $e");
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

  void _confirmDelete(
    BuildContext context,
    Map<String, dynamic> medicine,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Item"),
          content: Text(
            "Are you sure you want to delete '${medicine['item_name']}'?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteMedicine(medicine, index);
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMedicine(Map<String, dynamic> medicine, int index) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$BASE_URL/delete_item.php',
        ), // Replace with your delete API endpoint
        body: jsonEncode({'qr_code_data': medicine['qr_code_data']}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            //  filteredItems.removeAt(index); // Remove the item from the list
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Item '${medicine['item_name']}' deleted successfully!",
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to delete item: ${result['message']}"),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete item. Server error.")),
        );
      }
    } catch (e) {
      print("Error deleting item: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred. Please try again.")),
      );
    }
  }

  void _showHistoryModal(BuildContext context, Map<String, dynamic> medicine) {
    final filteredLogs =
        removalLogs.where((log) {
          return log['qr_code_data'] == medicine['qr_code_data'] &&
              log['exp_date'] == medicine['exp_date'];
        }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                " ${medicine['item_name']}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              if (filteredLogs.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      final DateTime dateTime = DateTime.parse(
                        log['removed_at'],
                      );
                      final String formattedDate = DateFormat(
                        'yyyy-MM-dd',
                      ).format(dateTime);
                      final String formattedTime = DateFormat(
                        'hh:mm a',
                      ).format(dateTime);

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            "Total Item Purchased: ${log['quantity_removed']} | Total Cost: ${log['total_cost']}",
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            "Date: $formattedDate | Time: $formattedTime",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Center(
                  child: Text(
                    "Still Havent Removed Any Items",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
            ],
          ),
        );
      },
    );
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
                          Text('Remaining: ${medicine['quantity']}'),
                          Text('Category: ${medicine['category']}'),
                          // if (removalLogs.isNotEmpty)
                          //   Column(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children:
                          //         removalLogs
                          //             .where(
                          //               (log) =>
                          //                   log['qr_code_data'] ==
                          //                       medicine['qr_code_data'] &&
                          //                   log['exp_date'] ==
                          //                       medicine['exp_date'],
                          //             )
                          //             .map((log) {
                          //               final DateTime dateTime =
                          //                   DateTime.parse(log['removed_at']);
                          //               final String formattedDate = DateFormat(
                          //                 'yyyy-MM-dd',
                          //               ).format(dateTime);
                          //               final String formattedTime = DateFormat(
                          //                 'hh:mm a',
                          //               ).format(dateTime);

                          //               return Padding(
                          //                 padding: const EdgeInsets.only(
                          //                   top: 5,
                          //                 ),
                          //                 child: Text(
                          //                   "Removed: ${log['quantity_removed']} | Total Cost: ${log['total_cost']} | Date: $formattedDate | Time: $formattedTime",
                          //                   style: const TextStyle(
                          //                     fontSize: 14,
                          //                     color: Colors.red,
                          //                   ),
                          //                 ),
                          //               );
                          //             })
                          //             .toList(),
                          // ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.history, color: Colors.blue),
                            onPressed: () {
                              _showHistoryModal(context, medicine);
                            },
                            tooltip: "View History",
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _confirmDelete(context, medicine, index);
                            },
                            tooltip: "Delete Item",
                          ),
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
