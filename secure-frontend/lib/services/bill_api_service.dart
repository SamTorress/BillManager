import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/bill.dart';
import 'auth_service.dart';
import 'api_exceptions.dart';

class BillApiService {
  static const String baseUrl = 'http://10.0.2.2:8001/restapi/bills';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${AuthService.accessToken}',
  };

  void _checkResponse(http.Response response) {
    if (response.statusCode == 401) throw UnauthorizedException();
    if (response.statusCode == 403) throw ForbiddenException();
    if (response.statusCode >= 500) throw ServerException();
  }

  Future<List<Bill>> getAllBills() async {
    final response = await http.get(Uri.parse(baseUrl), headers: _headers);
    _checkResponse(response);
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Bill.fromJson(json)).toList();
    }
    throw Exception('Failed to load bills (status ${response.statusCode})');
  }

  Future<Bill> getBillById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: _headers,
    );
    _checkResponse(response);
    if (response.statusCode == 200) {
      return Bill.fromJson(jsonDecode(response.body));
    }
    throw Exception('Bill not found (status ${response.statusCode})');
  }

  Future<void> createBill(Bill bill) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: _headers,
      body: jsonEncode(bill.toJson()),
    );
    _checkResponse(response);
    if (response.statusCode != 201) {
      throw Exception(
        'Failed to create bill (status ${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<Bill> updateBill(int id, Bill bill) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: _headers,
      body: jsonEncode(bill.toJson()),
    );
    _checkResponse(response);
    if (response.statusCode == 200) {
      return Bill.fromJson(jsonDecode(response.body));
    }
    throw Exception(
      'Failed to update bill (status ${response.statusCode}): ${response.body}',
    );
  }

  Future<void> deleteBill(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: _headers,
    );
    _checkResponse(response);
    if (response.statusCode != 204) {
      throw Exception('Failed to delete bill (status ${response.statusCode})');
    }
  }
}
