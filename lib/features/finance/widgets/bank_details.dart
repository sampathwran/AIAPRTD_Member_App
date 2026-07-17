import 'package:flutter/material.dart';

class BankDetailsCard extends StatelessWidget {
  final Map<String, dynamic> bank;

  const BankDetailsCard({super.key, required this.bank});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.shade50, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: Colors.blue.shade100)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Union Bank Details", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 10),
          _detailRow("Bank:", bank['bankName'] ?? 'N/A'),
          _detailRow("Account Name:", bank['accountName'] ?? 'N/A'),
          _detailRow("Account No:", bank['accountNumber'] ?? 'N/A'),
          _detailRow("Branch:", bank['branch'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }
}
