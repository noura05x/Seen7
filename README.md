# SEEN4

SEEN4 is a Flutter-based personal safety system designed to help vulnerable individuals during emergencies through a wearable ESP32 device connected to a mobile application.

The system provides:
- Real-time SOS alerts
- Live GPS tracking
- Audio and video evidence capture
- Emergency contact notifications
- BLE communication with a wearable safety device

---

# Problem Statement

In emergency situations, vulnerable individuals may not have enough time or ability to unlock and use their phones.

SEEN4 solves this problem by providing a wearable emergency device that instantly communicates with trusted emergency contacts and shares critical real-time information.

---

# Hardware Components

| Component | Purpose |
|---|---|
| ESP32 | Main controller and BLE communication |
| GPS Module | Live location tracking |
| Camera Module | Captures visual evidence |
| Microphone | Records emergency audio |
| Emergency Button | Triggers SOS instantly |
| Battery Module | Powers the wearable device |

---

# Mobile Application Roles

## Vulnerable User
- Pair and manage SEEN device
- Trigger SOS alerts
- Manage emergency contacts
- View location and alert history
- Monitor device status

## Emergency Contact
- Receive emergency alerts
- View linked users
- Track live location
- Access evidence history
- Acknowledge or resolve alerts

## Admin
- Monitor the system
- Manage users and alerts
- Review reports
- Export PDFs and analytics

---

# Core Features

- One-tap SOS activation
- Real-time GPS tracking
- BLE device communication
- Audio evidence recording
- Video evidence support
- Firebase Cloud Messaging notifications
- Arabic & English localization
- Role-based dashboards
- Emergency contact management

---

# Technology Stack

| Layer | Technology |
|---|---|
| Framework | Flutter |
| Backend | Firebase |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| Notifications | Firebase Cloud Messaging |
| Bluetooth | flutter_blue_plus |
| Audio Recording | record |
| Charts | fl_chart |

---

# Project Structure

```txt
lib/
├── core/
├── features/
│   ├── devices/
│   ├── contacts/
│   ├── sos/
│   └── dashboard/
│       ├── vulnerable_user/
│       ├── emergency_contact/
│       └── admin/
├── screens/
└── main.dart
```

---

# Firestore Structure

```txt
users/
alerts/
live_sessions/
issues/
```

---

# Supported Platforms

| Platform | Support |
|---|---|
| Android | ✅ Fully Supported |
| iOS | ✅ Fully Supported |
| Windows | ⚠️ Partial Support |
| macOS | ⚠️ Partial Support |
| Web | ❌ Not Supported |

---

# Team Members

## Ghala Alahmari
- galahmarii@gmail.com

## Naifa Alarifi
- naifa.arifi@gmail.com

## Noura Aljandol
- noura04mj@gmail.com

---

# License

This project is proprietary and all rights are reserved.
