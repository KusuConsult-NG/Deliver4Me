import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliver4me_mobile/models/order_model.dart';
// import 'package:deliver4me_mobile/services/order_service.dart'; // Unused

class EditDeliveryScreen extends StatefulWidget {
  final OrderModel order;

  const EditDeliveryScreen({super.key, required this.order});

  @override
  State<EditDeliveryScreen> createState() => _EditDeliveryScreenState();
}

class _EditDeliveryScreenState extends State<EditDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  // final _orderService = OrderService(); // Unused
  bool _isLoading = false;

  late TextEditingController _descController;
  late TextEditingController _receiverNameController;
  late TextEditingController _receiverPhoneController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _descController =
        TextEditingController(text: widget.order.parcelDescription);
    _receiverNameController =
        TextEditingController(text: widget.order.recipientName);
    _receiverPhoneController =
        TextEditingController(text: widget.order.recipientPhone);
    _notesController = TextEditingController(text: widget.order.notes);
  }

  @override
  void dispose() {
    _descController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.order.status != OrderStatus.pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot edit ongoing orders'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.id)
          .update({
        'parcelDescription': _descController.text.trim(),
        'recipientName': _receiverNameController.text.trim(),
        'recipientPhone': _receiverPhoneController.text.trim(),
        'notes': _notesController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Order updated successfully'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error updating order: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Delivery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveChanges,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (widget.order.status != OrderStatus.pending)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Only pending orders can be edited. This order is already in progress.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                    labelText: 'Parcel Description',
                    border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                enabled: widget.order.status == OrderStatus.pending,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _receiverNameController,
                decoration: const InputDecoration(
                    labelText: 'Recipient Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                enabled: widget.order.status == OrderStatus.pending,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _receiverPhoneController,
                decoration: const InputDecoration(
                    labelText: 'Recipient Phone', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                keyboardType: TextInputType.phone,
                enabled: widget.order.status == OrderStatus.pending,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                    labelText: 'Notes', border: OutlineInputBorder()),
                maxLines: 3,
                enabled: widget.order.status == OrderStatus.pending,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (widget.order.status == OrderStatus.pending &&
                          !_isLoading)
                      ? _saveChanges
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: const Color(0xFF135BEC),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
