import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'subscription_model.dart';
import 'subscription_provider.dart';

class EditSubscriptionScreen extends ConsumerStatefulWidget {
  final Subscription subscription;

  const EditSubscriptionScreen({super.key, required this.subscription});

  @override
  ConsumerState<EditSubscriptionScreen> createState() =>
      _EditSubscriptionScreenState();
}

class _EditSubscriptionScreenState
    extends ConsumerState<EditSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _customIntervalController;

  late String _category;
  late String _billingCycle;
  late DateTime _startDate;
  late DateTime _nextDueDate;
  late bool _isFreeTrial;
  DateTime? _trialEndDate;

  final List<String> _categories = [
    'Entertainment',
    'Utilities',
    'Software',
    'Gym',
    'Insurance',
    'Education',
    'Other',
  ];

  final List<String> _billingCycles = ['Monthly', 'Yearly', 'Custom'];

  @override
  void initState() {
    super.initState();
    final sub = widget.subscription;
    _titleController = TextEditingController(text: sub.title);
    _amountController = TextEditingController(text: sub.amount.toString());
    _customIntervalController = TextEditingController(
      text: sub.customIntervalDays?.toString() ?? '',
    );

    _category = sub.category;

    // Normalize billingCycle to Title Case so it matches the dropdown options
    _billingCycle = _normalizeBillingCycle(sub.billingCycle);

    _startDate = sub.startDate;
    _nextDueDate = sub.nextDueDate;
    _isFreeTrial = sub.isFreeTrial;
    _trialEndDate = sub.trialEndDate;

    // Ensure _category matches one of the dropdown items
    if (!_categories.contains(_category)) {
      _category = _categories.firstWhere(
        (c) => c.toLowerCase() == sub.category.toLowerCase(),
        orElse: () => 'Other',
      );
    }
  }

  // Helper method to handle capitalization mismatches (e.g., "MONTHLY" -> "Monthly")
  String _normalizeBillingCycle(String cycle) {
    final upper = cycle.toUpperCase();
    if (upper == 'MONTHLY') return 'Monthly';
    if (upper == 'YEARLY') return 'Yearly';
    if (upper == 'CUSTOM') return 'Custom';
    return 'Monthly'; // Fallback default
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _customIntervalController.dispose();
    super.dispose();
  }

  // Automatic Recalculation Logic when fields change
  void _updateCalculatedDates() {
    setState(() {
      if (_isFreeTrial) {
        // Default trial end date to 7 days from start if not set
        _trialEndDate ??= _startDate.add(const Duration(days: 7));
        // Next due date for a free trial maps directly to when the trial ends (first bill date)
        _nextDueDate = _trialEndDate!;
      } else {
        int? customDays;
        if (_billingCycle == 'Custom') {
          customDays = int.tryParse(_customIntervalController.text.trim());
        }

        final modelCycle = _billingCycle.toUpperCase();
        _nextDueDate = Subscription.calculateNextDueDate(
          _startDate,
          modelCycle,
          intervalDays: customDays,
        );
        _trialEndDate = null;
      }
    });
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _updateCalculatedDates();
      });
    }
  }

  Future<void> _selectTrialEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _trialEndDate ?? _startDate.add(const Duration(days: 7)),
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _trialEndDate = picked;
        _nextDueDate = picked; // First billing date is trial end date
      });
    }
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedSub = Subscription(
        id: widget.subscription.id,
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        category: _category,
        billingCycle: _billingCycle.toUpperCase(),
        startDate: _startDate,
        nextDueDate: _nextDueDate,
        customIntervalDays: _billingCycle == 'Custom'
            ? int.tryParse(_customIntervalController.text.trim())
            : null,
        isFreeTrial: _isFreeTrial,
        trialEndDate: _isFreeTrial ? _trialEndDate : null,
        isPaused: widget.subscription.isPaused,
      );

      ref.read(subscriptionProvider.notifier).updateSubscription(updatedSub);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Subscription')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Subscription Title',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Please enter an amount'
                    : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),

              // Start Date Picker
              ListTile(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                title: const Text('Start Date'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectStartDate(context),
              ),
              const SizedBox(height: 16),

              // Free Trial Switch
              SwitchListTile(
                title: const Text('Is Free Trial?'),
                subtitle: const Text('Enable special trial tracking'),
                value: _isFreeTrial,
                onChanged: (val) {
                  setState(() {
                    _isFreeTrial = val;
                    _updateCalculatedDates();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Conditional UI for Free Trial configuration
              if (_isFreeTrial) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Free Trial Configuration',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(color: Colors.orange.shade200),
                        ),
                        title: const Text('Trial End Date'),
                        subtitle: Text(
                          _trialEndDate != null
                              ? DateFormat('yyyy-MM-dd').format(_trialEndDate!)
                              : 'Select Trial End Date',
                        ),
                        trailing: const Icon(
                          Icons.event_available,
                          color: Colors.orange,
                        ),
                        onTap: () => _selectTrialEndDate(context),
                      ),
                      const SizedBox(height: 12),
                      // Post-Trial Billing Cycle inside Free Trial Box
                      DropdownButtonFormField<String>(
                        value: _billingCycle,
                        decoration: const InputDecoration(
                          labelText: 'Post-Trial Billing Cycle',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _billingCycles
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _billingCycle = val;
                              _updateCalculatedDates();
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Charges start after trial ends',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Standard Billing Cycle Dropdown (if NOT free trial)
              if (!_isFreeTrial) ...[
                DropdownButtonFormField<String>(
                  value: _billingCycle,
                  decoration: const InputDecoration(
                    labelText: 'Billing Cycle',
                    border: OutlineInputBorder(),
                  ),
                  items: _billingCycles
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _billingCycle = val;
                        _updateCalculatedDates();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Custom Interval Input (Appears if Billing Cycle is Custom, for both free-trial post-trial or normal)
              if (_billingCycle == 'Custom') ...[
                TextFormField(
                  controller: _customIntervalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Repeat Interval (Days)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _updateCalculatedDates(),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter interval days' : null,
                ),
                const SizedBox(height: 16),
              ],

              // Auto-calculated Next Due Date info display container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isFreeTrial
                      ? Colors.orange.shade50
                      : Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isFreeTrial
                        ? Colors.orange.shade200
                        : Colors.deepPurple.shade200,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isFreeTrial
                              ? 'First Billing Date (Post-Trial):'
                              : 'Next Due Date (Auto-calculated):',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isFreeTrial
                                ? Colors.orange.shade800
                                : Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('yyyy-MM-dd').format(_nextDueDate),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isFreeTrial
                                ? Colors.orange.shade900
                                : Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.auto_awesome,
                      color: _isFreeTrial
                          ? Colors.orange.shade800
                          : Colors.deepPurple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
