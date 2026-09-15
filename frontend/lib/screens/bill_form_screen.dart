import 'package:flutter/material.dart';
import '../model/bill.dart';
import '../services/bill_api_service.dart';

class BillFormScreen extends StatefulWidget {
  // If an existing bill is passed in, this screen edits it.
  // If null, this screen creates a new one.
  final Bill? bill;

  const BillFormScreen({super.key, this.bill});

  @override
  State<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends State<BillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final BillApiService _apiService = BillApiService();

  late TextEditingController _payeeNameController;
  late TextEditingController _paymentDueController;
  late DateTime _dueDate;
  late bool _paid;

  bool _isSaving = false;

  bool get _isEditing => widget.bill != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.bill;

    _payeeNameController = TextEditingController(
      text: existing?.payeeName ?? '',
    );
    _paymentDueController = TextEditingController(
      text: existing != null ? existing.paymentDue.toString() : '',
    );
    _dueDate =
        existing?.dueDate ?? DateTime.now().add(const Duration(days: 14));
    _paid = existing?.paid ?? false;
  }

  @override
  void dispose() {
    _payeeNameController.dispose();
    _paymentDueController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.isBefore(today) ? today : _dueDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final bill = Bill(
      id: widget.bill?.id,
      payeeName: _payeeNameController.text.trim(),
      dueDate: _dueDate,
      paymentDue: double.parse(_paymentDueController.text),
      paid: _paid,
      version: widget.bill?.version,
    );

    try {
      if (_isEditing) {
        await _apiService.updateBill(bill.id!, bill);
      } else {
        await _apiService.createBill(bill);
      }
      if (mounted) {
        Navigator.of(context).pop(true); // true = saved, caller should refresh
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit bill' : 'Add bill')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _payeeNameController,
              decoration: const InputDecoration(labelText: 'Payee name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a payee name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paymentDueController,
              decoration: const InputDecoration(labelText: 'Payment due'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the amount that is due';
                }
                if (double.tryParse(value) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Due date'),
              subtitle: Text(_dueDate.toIso8601String().split('T').first),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDueDate,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Paid'),
              value: _paid,
              onChanged: (value) => setState(() => _paid = value),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Create bill'),
            ),
          ],
        ),
      ),
    );
  }
}
