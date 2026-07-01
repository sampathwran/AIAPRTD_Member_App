// ignore_for_file: spell_check_on_languages

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BankDetailsTab extends StatelessWidget {
  final String membershipNo;

  const BankDetailsTab({
    super.key,
    required this.membershipNo,
  });

  void _copyAllDetails(BuildContext context) {
    const String bankDetails =
        'Account Name: National Union of Seafarers Sri Lanka\n'
        'Account Number: 1117010822\n'
        'Bank: Commercial Bank\n'
        'Branch: Narahenpita';


    Clipboard.setData(
    const ClipboardData(text: bankDetails),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
    content: Text('Copied'),
    duration: Duration(seconds: 2),
    behavior: SnackBarBehavior.floating,
    ),
    );


  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _copyAllDetails(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Name',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'National Union of Seafarers Sri Lanka',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Divider(height: 28),
                  Text(
                    'Account Number',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '1117010822',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Divider(height: 28),
                  Text(
                    'Bank',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Commercial Bank',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Divider(height: 28),
                  Text(
                    'Branch',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Narahenpita',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.center,
          child: IconButton(
            tooltip: 'Copy all bank details',
            onPressed: () => _copyAllDetails(context),
            icon: const Icon(
              Icons.copy_all_rounded,
              color: Colors.blue,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}
