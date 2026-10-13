# AeroX AI — Cross-Platform Native Client

Official native client for **AeroX AI**, engineered with Flutter for **Windows, macOS, Linux, Android, and iOS**. This application connects directly to the central AeroX AI Node.js/Express backend, delivering an enterprise-grade AI chat experience, multi-modal file interactions, and unified push notification handling.

---

## 🚀 Key Features

- **Cross-Platform Parity**: Unified UI and logic running seamlessly across Windows, macOS, Linux, Android, and iOS.
- **Real-Time Streaming**: Server-Sent Events (SSE) support for token-by-token AI streaming responses with abort/cancel controls.
- **Multi-Modal Capabilities**:
  - File picker integration for documents, spreadsheets, PDFs, and media.
  - Native camera capture support on mobile and desktop platforms.
  - Image previews, file size validation, and upload progress indicators.
- **Interactive Markdown & Code Rendering**:
  - Syntax highlighted code blocks with one-click copy.
  - Rich typography and formatted lists powered by `flutter_markdown`.
- **Centralized Authentication**:
  - Secure session token persistence via `shared_preferences`.
  - Live user credit balances and role-based feature gating.
- **Real-Time Notification System**:
  - Server-Sent Events (SSE) stream for instant broadcast alerts and direct system messages.
  - In-app notification slide-down banners with dismiss and auto-expire timers.
  - Slide-out notification center drawer with unread badges and one-click "mark all read".
- **Dynamic Platform Enforcement**:
  - Automated maintenance mode checks against backend `/api/apps/config`.
  - Minimum version enforcement with client update prompts.

---

## 📁 Architecture & Project Structure

The project follows a clean, modular Flutter architecture divided into services, models, widgets, screens, and theme tokens:

```
Aplication/aeroxai/
├── lib/
│   ├── main.dart                  # Application entry point and theme setup
│   ├── models/                    # Immutable data transfer objects
│   │   ├── ai_model.dart          # Available LLM models and cost configurations
│   │   ├── attachment_item.dart   # File attachment metadata and state
│   │   ├── conversation.dart      # Chat conversation thread entities
│   │   ├── message.dart           # Message data, roles, and streaming status
│   │   ├── notification_item.dart # Push notification payloads and read status
│   │   ├── platform_config.dart   # Remote app maintenance and version settings
│   │   └── user.dart              # Authenticated user account and credits
│   ├── screens/                   # Top-level screen views
│   │   ├── auth_screen.dart       # Login and account registration flow
│   │   ├── dashboard_screen.dart  # Multi-platform chat dashboard and sidebar
│   │   └── splash_screen.dart     # App bootstrapper and session restoration
│   ├── services/                  # Business logic and network clients
│   │   ├── api_service.dart       # Core HTTP REST & SSE streaming client
│   │   ├── auth_service.dart      # Auth lifecycle and session token storage
│   │   ├── chat_service.dart      # Conversation state and message streams
│   │   ├── file_service.dart      # Cross-platform file picking and camera capture
│   │   ├── notification_service.dart # SSE push notifications & badge state
│   │   └── platform_service.dart  # OS detection and maintenance checks
│   ├── theme/                     # Brand styling matching the web platform
│   │   ├── aerox_animations.dart  # Easing curves and duration constants
│   │   ├── aerox_colors.dart      # Canonical hex color palette
│   │   └── aerox_theme.dart       # Material 3 dark theme builder
│   └── widgets/                   # Reusable UI components
│       ├── aerox_badge.dart       # Status indicators and credit pills
│       ├── aerox_button.dart      # Custom animated gradient buttons
│       ├── aerox_toast.dart       # Toast alerts and snackbars
│       ├── attachment_preview.dart# Thumbnail chips for attached files
│       ├── chat_bubble.dart       # Formatted AI & user chat messages
│       ├── model_selector_modal.dart # Bottom sheet / dialog for model switching
│       ├── notification_banner.dart  # Top floating alert banner
│       └── notification_drawer.dart  # Slide-out notification center
└── pubspec.yaml                   # Package dependencies and asset declarations
```

---

## 🛠️ Prerequisites & Setup

### 1. Backend Server
Ensure the main AeroX AI backend server is running:
```bash
# In the repository root
npm start
```
By default, the backend runs at `http://localhost:3000`.

### 2. Flutter Environment
Verify your Flutter installation:
```bash
flutter doctor
```

### 3. Install Dependencies
```bash
cd Aplication/aeroxai
flutter pub get
```

---

## 🏃 Running the Application

### Desktop Targets
```bash
# Windows (requires Windows Developer Mode enabled for plugin symlinks: `start ms-settings:developers`)
flutter run -d windows


# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### Mobile Targets
```bash
# Android (Device or Emulator)
flutter run -d android

# iOS (macOS host with Simulator or connected device)
flutter run -d ios
```

---

## 🧪 Code Analysis & Verification

Run static analysis to verify code quality and documentation compliance:
```bash
flutter analyze
```
