import 'package:flutter/material.dart';
import '../../../models/onboarding.dart';
import '../widgets/onboarding_card.dart';

class OnboardingsTab extends StatelessWidget {
  final List<Onboarding> onboardings;

  const OnboardingsTab({super.key, required this.onboardings});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: onboardings
            .map((o) => OnboardingCard(onboarding: o))
            .toList(),
      ),
    );
  }
}