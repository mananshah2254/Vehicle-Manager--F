import 'package:flutter/material.dart';
import 'package:vehicle_manager/models/vehicle.dart';
import 'package:vehicle_manager/services/auth_service.dart';
import 'package:vehicle_manager/services/vehicle_service.dart';
import 'package:vehicle_manager/screens/vehicle_form_screen.dart';
import 'package:vehicle_manager/screens/login_screen.dart';
import 'package:vehicle_manager/screens/vehicle_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Vehicle> _vehicles = [];
  List<Vehicle> _filteredVehicles = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'make';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
    });

    final vehicles = await VehicleService.getVehicles();
    setState(() {
      _vehicles = vehicles;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    List<Vehicle> filtered = List.from(_vehicles);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((vehicle) {
        final query = _searchQuery.toLowerCase();
        return vehicle.make.toLowerCase().contains(query) ||
            vehicle.model.toLowerCase().contains(query) ||
            vehicle.color.toLowerCase().contains(query) ||
            vehicle.licensePlate.toLowerCase().contains(query) ||
            vehicle.year.toString().contains(query);
      }).toList();
    }

    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'make':
          comparison = a.make.compareTo(b.make);
          break;
        case 'year':
          comparison = a.year.compareTo(b.year);
          break;
        case 'color':
          comparison = a.color.compareTo(b.color);
          break;
        default:
          comparison = a.make.compareTo(b.make);
      }
      return _sortAscending ? comparison : -comparison;
    });

    setState(() {
      _filteredVehicles = filtered;
    });
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Vehicles'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Make'),
              value: 'make',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.pop(context);
                _applyFilters();
              },
            ),
            RadioListTile<String>(
              title: const Text('Year'),
              value: 'year',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.pop(context);
                _applyFilters();
              },
            ),
            RadioListTile<String>(
              title: const Text('Color'),
              value: 'color',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.pop(context);
                _applyFilters();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
              Navigator.pop(context);
              _applyFilters();
            },
            child: Text(_sortAscending ? 'Switch to Descending' : 'Switch to Ascending'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Are you sure you want to delete ${vehicle.make} ${vehicle.model}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await VehicleService.deleteVehicle(vehicle.id);
      _loadVehicles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle deleted successfully')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Widget _buildStatsCard() {
    if (_vehicles.isEmpty) return const SizedBox.shrink();

    final totalVehicles = _vehicles.length;
    final avgYear = (_vehicles.fold<int>(0, (sum, v) => sum + v.year) / totalVehicles).round();
    final newestYear = _vehicles.map((v) => v.year).reduce((a, b) => a > b ? a : b);
    final oldestYear = _vehicles.map((v) => v.year).reduce((a, b) => a < b ? a : b);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total', totalVehicles.toString()),
              ),
              Expanded(
                child: _buildStatItem('Avg Year', avgYear.toString()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Newest', newestYear.toString()),
              ),
              Expanded(
                child: _buildStatItem('Oldest', oldestYear.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VehicleDetailsScreen(vehicle: vehicle),
            ),
          );
          if (result == true) {
            _loadVehicles();
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.make} ${vehicle.model}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${vehicle.year} • ${vehicle.color}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.licensePlate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VehicleFormScreen(vehicle: vehicle),
                    ),
                  );
                  if (result == true) {
                    _loadVehicles();
                  }
                },
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                onPressed: () => _deleteVehicle(vehicle),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isLoading && _vehicles.isNotEmpty) _buildStatsCard(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                                _applyFilters();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                    _applyFilters();
                  },
                  tooltip: 'Toggle Sort',
                ),
                IconButton(
                  icon: const Icon(Icons.sort, size: 20),
                  onPressed: _showSortDialog,
                  tooltip: 'Sort Options',
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVehicles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off_outlined
                                  : Icons.directions_car_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No vehicles found'
                                  : 'No vehicles yet',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Try a different search term'
                                  : 'Tap the + button to add one',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade500,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _filteredVehicles.length,
                        itemBuilder: (context, index) => _buildVehicleCard(_filteredVehicles[index]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const VehicleFormScreen(),
            ),
          );
          if (result == true) {
            _loadVehicles();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
