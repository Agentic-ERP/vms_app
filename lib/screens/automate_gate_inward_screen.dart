import 'package:flutter/material.dart';

import '../widgets/automate_gate_inward_form.dart';
import '../widgets/line_o_matic_logo.dart';

class AutomateGateInwardScreen extends StatelessWidget {
  const AutomateGateInwardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  Expanded(
                    child: Text(
                      'Automate Gate Inward',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const LineOMaticLogo(height: 32),
              const SizedBox(height: 20),
              const AutomateGateInwardForm(),
            ],
          ),
        ),
      ),
    );
  }
}
