import 'package:flutter/material.dart';
import '../model/bill.dart';
import '../services/bill_api_service.dart';
import 'bill_form_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../services/api_exceptions.dart';

class BillListScreen extends StatefulWidget {
  const BillListScreen({super.key});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  final BillApiService _apiService = BillApiService();
  late Future<List<Bill>> _billsFuture;

  @override
  void initState() {
    super.initState();
    _billsFuture = _apiService.getAllBills();
  }

  void _refreshBills() {
    setState(() {
      _billsFuture = _apiService.getAllBills();
    });
  }

  Future<void> _openForm({Bill? bill}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => BillFormScreen(bill: bill)),
    );
    if (saved == true) {
      _refreshBills();
    }
  }




  Future<void> _confirmAndDeleteBill(Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete bill?'),
        content: Text(
          'This will permanently delete the bill for "${bill.payeeName}".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.deleteBill(bill.id!);
      _refreshBills();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted bill for ${bill.payeeName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
      }
    }
  }

String _friendlyError(Object e) {
    if (e is UnauthorizedException) return e.message;
    if (e is ForbiddenException) return e.message;
    if (e is ServerException) return e.message;
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService.logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Bill>>(
        future: _billsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(_friendlyError(snapshot.error!)));
          }

          final bills = snapshot.data ?? [];
          if (bills.isEmpty) {
            return const Center(child: Text('No bills found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: InkWell(
                  onTap: () => _openForm(bill: bill),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bill.payeeName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 16,
                                runSpacing: 4,
                                children: [
                                  _BillField(
                                    label: 'Due date',
                                    value: bill.dueDate
                                        .toIso8601String()
                                        .split('T')
                                        .first,
                                  ),
                                  _BillField(
                                    label: 'Payment due',
                                    value:
                                        '\$${bill.paymentDue.toStringAsFixed(2)}',
                                  ),
                                  _BillField(
                                    label: 'Paid',
                                    value: bill.paid ? 'Yes' : 'No',
                                  ),
                                  _BillField(
                                    label: 'Version',
                                    value: '${bill.version ?? 0}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (AuthService.roles.contains('ActiveStudent'))
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete bill',
                            onPressed: () => _confirmAndDeleteBill(bill),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: AuthService.roles.contains('ActiveStudent')
          ? FloatingActionButton(
              onPressed: () => _openForm(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

/// Renders a small label above its value, e.g. "Due date" / "2026-07-29".
/// Mirrors the column-header style from the Assignment 6 web table.
class _BillField extends StatelessWidget {
  final String label;
  final String value;

  const _BillField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
