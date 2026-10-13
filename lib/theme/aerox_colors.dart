/// Design tokens and semantic color definitions for AeroX AI.
///
/// Exact 1:1 replica of the web platform's CSS custom properties from
/// `design-system.css`, providing visual identity parity across all platforms.
library;

import 'package:flutter/material.dart';

/// Provides static color constants and shadows matching the AeroX web design system.
///
/// Every value here corresponds directly to a CSS `--variable` defined in
/// `public/css/design-system.css`:
///
/// | Dart constant     | CSS variable         | Hex       |
/// |-------------------|----------------------|-----------|
/// | bgPrimary         | --bg-primary         | #000000   |
/// | bgSecondary       | --bg-secondary       | #0a0a0a   |
/// | bgTertiary        | --bg-tertiary        | #111111   |
/// | bgCard            | --bg-card            | #0d0d0d   |
/// | bgElevated        | --bg-elevated        | #141414   |
/// | bgSurface         | --bg-surface         | #1a1a1a   |
/// | bgHover           | --bg-hover           | #1f1f1f   |
/// | bgInput           | --bg-input           | #0f0f0f   |
class AeroXColors {
  AeroXColors._();

  // ─── Background Palette ────────────────────────────────────────────

  /// Primary canvas — pure black (`#000000`).
  static const Color bgPrimary = Color(0xFF000000);

  /// Secondary container / sidebar (`#0a0a0a`).
  static const Color bgSecondary = Color(0xFF0A0A0A);

  /// Tertiary structural panels (`#111111`).
  static const Color bgTertiary = Color(0xFF111111);

  /// Card element fill (`#0d0d0d`).
  static const Color bgCard = Color(0xFF0D0D0D);

  /// Elevated popover / modal / drawer (`#141414`).
  static const Color bgElevated = Color(0xFF141414);

  /// Neutral surface layer (`#1a1a1a`).
  static const Color bgSurface = Color(0xFF1A1A1A);

  /// Hover interactive state (`#1f1f1f`).
  static const Color bgHover = Color(0xFF1F1F1F);

  /// Form input / text field fill (`#0f0f0f`).
  static const Color bgInput = Color(0xFF0F0F0F);

  // ─── Text Palette ──────────────────────────────────────────────────

  /// High-contrast primary text (`#ffffff`).
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Muted secondary labels (`#a0a0a0`).
  static const Color textSecondary = Color(0xFFA0A0A0);

  /// Low-contrast tertiary metadata (`#666666`).
  static const Color textTertiary = Color(0xFF666666);

  /// Placeholder / disabled text (`#444444`).
  static const Color textMuted = Color(0xFF444444);

  // ─── Border Palette ────────────────────────────────────────────────

  /// Primary border outline (`#222222`).
  static const Color borderPrimary = Color(0xFF222222);

  /// Secondary border outline (`#1a1a1a`).
  static const Color borderSecondary = Color(0xFF1A1A1A);

  /// Subtle border outline (`#151515`).
  static const Color borderSubtle = Color(0xFF151515);

  /// Active focus / selection border (`#444444`).
  static const Color borderFocus = Color(0xFF444444);

  // ─── Accent ────────────────────────────────────────────────────────

  /// Primary brand cyan accent (`#38bdf8`).
  static const Color primary = Color(0xFF38BDF8);

  /// Primary accent — white (`#ffffff`).
  static const Color accent = Color(0xFFFFFFFF);

  /// Muted accent (`#888888`).
  static const Color accentMuted = Color(0xFF888888);

  /// Subtle accent (`#333333`).
  static const Color accentSubtle = Color(0xFF333333);

  // ─── Semantic States ───────────────────────────────────────────────

  /// Success state (`#4ade80`).
  static const Color success = Color(0xFF4ADE80);

  /// Warning state (`#fbbf24`).
  static const Color warning = Color(0xFFFBBF24);

  /// Error / danger state (`#f87171`).
  static const Color error = Color(0xFFF87171);

  /// Informative state (`#60a5fa`).
  static const Color info = Color(0xFF60A5FA);

  // ─── Elevation Shadows ─────────────────────────────────────────────

  /// Subtle card shadow — `0 1px 3px rgba(0,0,0,0.5)`.
  static const BoxShadow shadowSm = BoxShadow(
    color: Color(0x80000000),
    offset: Offset(0, 1),
    blurRadius: 3,
  );

  /// Medium popover shadow — `0 4px 12px rgba(0,0,0,0.6)`.
  static const BoxShadow shadowMd = BoxShadow(
    color: Color(0x99000000),
    offset: Offset(0, 4),
    blurRadius: 12,
  );

  /// Prominent modal shadow — `0 8px 32px rgba(0,0,0,0.7)`.
  static const BoxShadow shadowLg = BoxShadow(
    color: Color(0xB3000000),
    offset: Offset(0, 8),
    blurRadius: 32,
  );

  /// Subtle ambient glow — `0 0 40px rgba(255,255,255,0.03)`.
  static const BoxShadow shadowGlow = BoxShadow(
    color: Color(0x08FFFFFF),
    offset: Offset.zero,
    blurRadius: 40,
  );

  // ─── AI Model Accent Palette ────────────────────────────────────────

  /// Flash / Aperture Cyan (`#06b6d4`).
  static const Color modelFlash = Color(0xFF06B6D4);

  /// Pulse / Mint Vital (`#10b981`).
  static const Color modelPulse = Color(0xFF10B981);

  /// Velocity / Supersonic Sky (`#0ea5e9`).
  static const Color modelVelocity = Color(0xFF0EA5E9);

  /// Altitude / Royal Summit (`#8b5cf6`).
  static const Color modelAltitude = Color(0xFF8B5CF6);

  /// Apex / Imperial Gold (`#f59e0b`).
  static const Color modelApex = Color(0xFFF59E0B);

  /// Vector / Matrix Lime (`#84cc16`).
  static const Color modelVector = Color(0xFF84CC16);

  /// Synapse / Rose Coral (`#f43f5e`).
  static const Color modelSynapse = Color(0xFFF43F5E);

  /// Stratos / Celestial Teal (`#14b8a6`).
  static const Color modelStratos = Color(0xFF14B8A6);

  /// Quantum / Electric Purple (`#a855f7`).
  static const Color modelQuantum = Color(0xFFA855F7);

  /// Nexus / Sapphire Blue (`#3b82f6`).
  static const Color modelNexus = Color(0xFF3B82F6);

  /// Ultra / Ruby Flame (`#ef4444`).
  static const Color modelUltra = Color(0xFFEF4444);

  /// Core / Emerald Spark (`#10b981`).
  static const Color modelCore = Color(0xFF10B981);

  /// Pro / Indigo Neural (`#6366f1`).
  static const Color modelPro = Color(0xFF6366F1);

  /// Reason / Amber Analytical (`#d97706`).
  static const Color modelReason = Color(0xFFD97706);

  /// Image / Creative Synthesis (`#ec4899`).
  static const Color modelImage = Color(0xFFEC4899);

  /// Resolves the signature accent color for a given model name and type.
  static Color getModelColor(String name, [String? modelType]) {
    if (modelType == 'image') return modelImage;
    final n = name.toLowerCase();
    if (n.contains('flash')) return modelFlash;
    if (n.contains('pulse')) return modelPulse;
    if (n.contains('velocity')) return modelVelocity;
    if (n.contains('altitude')) return modelAltitude;
    if (n.contains('apex')) return modelApex;
    if (n.contains('vector')) return modelVector;
    if (n.contains('synapse')) return modelSynapse;
    if (n.contains('stratos')) return modelStratos;
    if (n.contains('quantum')) return modelQuantum;
    if (n.contains('nexus')) return modelNexus;
    if (n.contains('ultra')) return modelUltra;
    if (n.contains('core')) return modelCore;
    if (n.contains('pro')) return modelPro;
    if (n.contains('reason')) return modelReason;
    if (n.contains('vision') || n.contains('omni')) return modelFlash;
    return textPrimary;
  }
}
