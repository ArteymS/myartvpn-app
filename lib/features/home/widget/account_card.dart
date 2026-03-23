import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AccountCard extends HookConsumerWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);
    final theme = Theme.of(context);
    return switch (activeProfile) {
      AsyncData(value: final profile?) => _buildContent(context, profile, theme),
      _ => const SizedBox(),
    };
  }

  Widget _buildContent(BuildContext context, ProfileEntity profile, ThemeData theme) {
    if (profile is! RemoteProfileEntity) return const SizedBox();
    final url = profile.url;
    final userId = _extractUserId(url);
    if (userId == null) return const SizedBox();
    return FutureBuilder(
      future: _fetchUserData(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final data = snapshot.data as Map<String, dynamic>;
        final daysLeft = data['days_left'] ?? 0;
        final maxDevices = data['max_devices'] ?? 1;
        final trialAvailable = data['trial_available'] ?? false;
        final subUrl = "https://myartvpn.online:8443/robokassa/pay?user_id=$userId";
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Личный кабинет", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text("ID: $userId", style: theme.textTheme.bodySmall),
                ],
              ),
              const Gap(12),
              Row(
                children: [
                  _infoTile(theme, Icons.calendar_today, "$daysLeft", "дней осталось"),
                  const Gap(24),
                  _infoTile(theme, Icons.devices, "$maxDevices", "устройств"),
                ],
              ),
              const Gap(16),
              Row(
                children: [
                  if (trialAvailable)
                    Expanded(child: FilledButton.tonal(onPressed: () => _getTrial(context, userId), child: const Text("Тест 24ч"))),
                  if (trialAvailable) const Gap(8),
                  Expanded(child: FilledButton(onPressed: () => launchUrlString(subUrl, mode: LaunchMode.externalApplication), child: const Text("Продлить"))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoTile(ThemeData theme, IconData icon, String value, String label) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 16, color: theme.colorScheme.primary), const Gap(4), Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))]),
      Text(label, style: theme.textTheme.bodySmall),
    ]);
  }

  String? _extractUserId(String url) { try { return Uri.parse(url).pathSegments.last; } catch (_) { return null; } }

  Future<Map<String, dynamic>> _fetchUserData(String userId) async {
    try { final r = await Dio().get("https://myartvpn.online:8443/robokassa/user_data?user_id=$userId"); return r.data as Map<String, dynamic>; } catch (e) { return {}; }
  }

  Future<void> _getTrial(BuildContext context, String userId) async {
    try { await Dio().get("https://myartvpn.online:8443/robokassa/get_trial?user_id=$userId"); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Пробный период активирован!"))); } catch (e) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ошибка активации"))); }
  }
}
