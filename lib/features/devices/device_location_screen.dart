import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/colors.dart';
import '../../main.dart';

class DeviceLocationScreen extends StatelessWidget {
  final String deviceName;
  final double? lat;
  final double? lng;

  /// UID حق صاحب الجهاز.
  final String? userId;

  /// Device document ID.
  final String? deviceId;

  const DeviceLocationScreen({
    super.key,
    required this.deviceName,
    this.lat,
    this.lng,
    this.userId,
    this.deviceId,
  });

  Future<void> _openGoogleMaps(
    BuildContext context,
    double? currentLat,
    double? currentLng,
  ) async {
    final lang = appLanguage;

    if (currentLat == null ||
        currentLng == null ||
        currentLat == 0 ||
        currentLng == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.text(
              en: "No valid location available yet.",
              ar: "لا يوجد موقع صالح متاح حتى الآن.",
            ),
          ),
        ),
      );
      return;
    }

    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$currentLat,$currentLng',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.text(
              en: "Could not open Google Maps.",
              ar: "تعذر فتح خرائط Google.",
            ),
          ),
        ),
      );
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    if (userId != null && userId!.isNotEmpty) {
      final hasValidDeviceId =
          deviceId != null && deviceId!.isNotEmpty && deviceId != "-";

      if (hasValidDeviceId) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('devices')
              .doc(deviceId)
              .snapshots(),
          builder: (context, deviceSnapshot) {
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .snapshots(),
              builder: (context, userSnapshot) {
                final deviceData = deviceSnapshot.data?.data() ?? {};
                final userData = userSnapshot.data?.data() ?? {};

                final liveLat = _toDouble(deviceData['lat']) ??
                    _toDouble(deviceData['latitude']) ??
                    _toDouble(userData['lat']) ??
                    _toDouble(userData['latitude']) ??
                    lat;

                final liveLng = _toDouble(deviceData['lng']) ??
                    _toDouble(deviceData['longitude']) ??
                    _toDouble(userData['lng']) ??
                    _toDouble(userData['longitude']) ??
                    lng;

                final gpsFix =
                    deviceData['gpsFix'] == true || userData['gpsFix'] == true;

                final sat = deviceData['sat'] ?? userData['sat'];

                final updatedAt = deviceData['updatedAt'] ??
                    deviceData['lastUpdate'] ??
                    userData['updatedAt'] ??
                    userData['lastUpdate'];

                return _LocationBody(
                  deviceName: deviceName,
                  lat: liveLat,
                  lng: liveLng,
                  gpsFix: gpsFix,
                  sat: sat,
                  updatedAt: updatedAt,
                  onOpenMaps: () => _openGoogleMaps(context, liveLat, liveLng),
                );
              },
            );
          },
        );
      }

      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};

          final liveLat =
              _toDouble(data['lat']) ?? _toDouble(data['latitude']) ?? lat;

          final liveLng =
              _toDouble(data['lng']) ?? _toDouble(data['longitude']) ?? lng;

          final gpsFix = data['gpsFix'] == true;
          final sat = data['sat'];
          final updatedAt = data['updatedAt'] ?? data['lastUpdate'];

          return _LocationBody(
            deviceName: deviceName,
            lat: liveLat,
            lng: liveLng,
            gpsFix: gpsFix,
            sat: sat,
            updatedAt: updatedAt,
            onOpenMaps: () => _openGoogleMaps(context, liveLat, liveLng),
          );
        },
      );
    }

    return _LocationBody(
      deviceName: deviceName,
      lat: lat,
      lng: lng,
      gpsFix: lat != null && lng != null && lat != 0 && lng != 0,
      sat: null,
      updatedAt: null,
      onOpenMaps: () => _openGoogleMaps(context, lat, lng),
    );
  }
}

class _LocationBody extends StatelessWidget {
  final String deviceName;
  final double? lat;
  final double? lng;
  final bool gpsFix;
  final dynamic sat;
  final dynamic updatedAt;
  final VoidCallback onOpenMaps;

  const _LocationBody({
    required this.deviceName,
    required this.lat,
    required this.lng,
    required this.gpsFix,
    required this.sat,
    required this.updatedAt,
    required this.onOpenMaps,
  });

  bool get hasLocation => lat != null && lng != null && lat != 0 && lng != 0;

  String _formatUpdatedAt(dynamic value) {
    if (value is Timestamp) {
      final dt = value.toDate();
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }

    if (value is DateTime) {
      return "${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} "
          "${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}";
    }

    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }

    return "-";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = appLanguage;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      lang.isArabic
                          ? Icons.arrow_forward_ios_rounded
                          : Icons.arrow_back_ios_new_rounded,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      deviceName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            hasLocation
                                ? Icons.location_on_rounded
                                : Icons.location_searching_rounded,
                            color: AppColors.primary,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          hasLocation
                              ? lang.text(
                                  en: "Live Location",
                                  ar: "الموقع المباشر",
                                )
                              : lang.text(
                                  en: "Waiting for GPS",
                                  ar: "بانتظار GPS",
                                ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          hasLocation
                              ? "Lat: ${lat!.toStringAsFixed(6)}\nLng: ${lng!.toStringAsFixed(6)}"
                              : lang.text(
                                  en:
                                      "No valid GPS location is available yet from the device.",
                                  ar:
                                      "لا يوجد موقع GPS صالح من الجهاز حتى الآن.",
                                ),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: hasLocation
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _InfoRow(
                          icon: Icons.gps_fixed_rounded,
                          label: lang.text(en: "GPS Fix", ar: "إشارة GPS"),
                          value: gpsFix
                              ? lang.text(en: "Available", ar: "متوفرة")
                              : lang.text(en: "Not fixed", ar: "غير ثابتة"),
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.satellite_alt_rounded,
                          label: lang.text(en: "Satellites", ar: "الأقمار"),
                          value: sat?.toString() ?? "-",
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.update_rounded,
                          label: lang.text(en: "Last update", ar: "آخر تحديث"),
                          value: _formatUpdatedAt(updatedAt),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: hasLocation ? onOpenMaps : null,
                            icon: const Icon(Icons.map_rounded),
                            label: Text(
                              lang.text(
                                en: "Open in Google Maps",
                                ar: "فتح في خرائط Google",
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}