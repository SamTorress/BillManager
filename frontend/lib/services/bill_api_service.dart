import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/bill.dart';

class BillApiService {

  static const String baseUrl = 'http://10.0.2.2:8000/restapi/bills';

  Future<List<Bill>> getAllBills() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Bill.fromJson(json)).toList();
    }
    throw Exception('Failed to load bills (status ${response.statusCode})');
  }

  Future<Bill> getBillById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      return Bill.fromJson(jsonDecode(response.body));
    }
    throw Exception('Bill not found (status ${response.statusCode})');
  }

  Future<void> createBill(Bill bill) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bill.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception(
        'Failed to create bill (status ${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<Bill> updateBill(int id, Bill bill) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bill.toJson()),
    );
    if (response.statusCode == 200) {
      return Bill.fromJson(jsonDecode(response.body));
    }
    throw Exception(
      'Failed to update bill (status ${response.statusCode}): ${response.body}',
    );
  }

  Future<void> deleteBill(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete bill (status ${response.statusCode})');
    }
  }
}
