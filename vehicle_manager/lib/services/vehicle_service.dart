import 'package:vehicle_manager/models/vehicle.dart';
import 'package:vehicle_manager/services/api_service.dart';

class VehicleService {
  static Future<List<Vehicle>> getVehicles() async {
    try {
      final data = await ApiService.getVehicles();
      return data.map((json) {
        // Handle both API response format and direct map
        final vehicleData = json is Map ? json : json as Map<String, dynamic>;
        return Vehicle.fromJson({
          'id': vehicleData['id'],
          'make': vehicleData['make'],
          'model': vehicleData['model'],
          'year': vehicleData['year'],
          'color': vehicleData['color'],
          'licensePlate': vehicleData['licensePlate'],
        });
      }).toList();
    } catch (e) {
      print('Error fetching vehicles: $e');
      return [];
    }
  }

  static Future<void> addVehicle(Vehicle vehicle) async {
    await ApiService.addVehicle({
      'id': vehicle.id,
      'make': vehicle.make,
      'model': vehicle.model,
      'year': vehicle.year,
      'color': vehicle.color,
      'licensePlate': vehicle.licensePlate,
    });
  }

  static Future<void> updateVehicle(Vehicle vehicle) async {
    await ApiService.updateVehicle(vehicle.id, {
      'make': vehicle.make,
      'model': vehicle.model,
      'year': vehicle.year,
      'color': vehicle.color,
      'licensePlate': vehicle.licensePlate,
    });
  }

  static Future<void> deleteVehicle(String id) async {
    await ApiService.deleteVehicle(id);
  }
}
