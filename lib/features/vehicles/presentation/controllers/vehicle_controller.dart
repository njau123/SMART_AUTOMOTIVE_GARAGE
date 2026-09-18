import 'package:flutter/material.dart';
import '../../data/datasources/vehicle_api_datasource.dart';
class VehicleController extends ChangeNotifier {
  final VehicleApiDataSource _api = VehicleApiDataSource();
  List<dynamic> _vehicles = []; bool _isLoading = false;
  List<dynamic> get vehicles => _vehicles; bool get isLoading => _isLoading;
  Future<void> loadVehicles(String accessToken) async {
    _isLoading = true; notifyListeners();
    _vehicles = await _api.getVehicles(accessToken);
    _isLoading = false; notifyListeners();
  }
}
