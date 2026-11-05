import 'package:flutter/material.dart';
import 'legal_document_screen.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(title: '利用規約', fileName: 'terms.html');
  }
}
