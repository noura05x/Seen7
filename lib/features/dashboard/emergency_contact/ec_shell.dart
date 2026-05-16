import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../main.dart';
import 'ec_dashboard.dart';
import 'ec_alerts_page.dart';
import 'ec_linked_users_page.dart';
import 'ec_settings_page.dart';

class ECShell extends StatefulWidget {
  const ECShell({super.key});

  @override
  State<ECShell> createState() => _ECShellState();
}

class _ECShellState extends State<ECShell> {
  int _selectedIndex = 0;

  StreamSubscription<QuerySnapshot>? _alertsSubscription;
  final Set<String> _knownAlertIds = {};
  bool _initialAlertsLoaded = false;
  bool _dialogShowing = false;

  final List<Widget> pages = const [
    ECDashboard(),
    ECAlertsPage(),
    ECLinkedUsersPage(),
    ECSettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _listenForEmergencyAlerts();
  }

  void _listenForEmergencyAlerts() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _alertsSubscription = FirebaseFirestore.instance
        .collection('alerts')
        .where('emergencyContactIds', arrayContains: currentUser.uid)
        .where('status', isEqualTo: 'Triggered')
        .snapshots()
        .listen((snapshot) {
      if (!_initialAlertsLoaded) {
        for (final doc in snapshot.docs) {
          _knownAlertIds.add(doc.id);
        }
        _initialAlertsLoaded = true;
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added &&
            !_knownAlertIds.contains(change.doc.id)) {
          _knownAlertIds.add(change.doc.id);

          final data = change.doc.data() as Map<String, dynamic>;
          _showEmergencyPopup(data);
        }
      }
    });
  }

  void _showEmergencyPopup(Map<String, dynamic> alert) {
    if (!mounted || _dialogShowing) return;

    final lang = appLanguage;

    final userName = (alert['userName'] ??
            lang.text(en: 'Unknown User', ar: 'مستخدم غير معروف'))
        .toString();

    final location = (alert['location'] ??
            lang.text(en: 'Unknown Location', ar: 'موقع غير معروف'))
        .toString();

    _dialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.emergencyRed,
            ),
            const SizedBox(width: 8),
            Text(
              lang.text(en: "Emergency Alert", ar: "تنبيه طارئ"),
              style: const TextStyle(
                color: AppColors.emergencyRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          lang.text(
            en: "$userName triggered an emergency alert.\nLocation: $location",
            ar: "قام $userName بتفعيل تنبيه طارئ.\nالموقع: $location",
          ),
          style: const TextStyle(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 1);
            },
            child: Text(
              lang.text(en: "View Alerts", ar: "عرض التنبيهات"),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              lang.text(en: "Dismiss", ar: "إغلاق"),
            ),
          ),
        ],
      ),
    ).then((_) {
      _dialogShowing = false;
    });
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = appLanguage;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text("Not logged in"),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('alerts')
          .where('emergencyContactIds', arrayContains: currentUser.uid)
          .where('status', isEqualTo: 'Triggered')
          .snapshots(),
      builder: (context, snapshot) {
        final hasActiveAlerts =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              items: [
                _item(
                  Icons.home_rounded,
                  lang.text(en: "Home", ar: "الرئيسية"),
                  0,
                ),
                _item(
                  Icons.warning_amber_rounded,
                  lang.text(en: "Alerts", ar: "التنبيهات"),
                  1,
                  showRedDot: hasActiveAlerts,
                ),
                _item(
                  Icons.group_rounded,
                  lang.text(en: "Users", ar: "المستخدمون"),
                  2,
                ),
                _item(
                  Icons.settings_rounded,
                  lang.text(en: "Settings", ar: "الإعدادات"),
                  3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  BottomNavigationBarItem _item(
    IconData icon,
    String label,
    int index, {
    bool showRedDot = false,
  }) {
    final isSelected = _selectedIndex == index;

    return BottomNavigationBarItem(
      label: label,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22),
          ),
          if (showRedDot)
            const Positioned(
              right: 2,
              top: 2,
              child: SizedBox(
                width: 10,
                height: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.emergencyRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}