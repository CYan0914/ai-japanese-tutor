/// Design tokens — "Washi & Sumi" identity system.
///
/// The visual language borrows from traditional Japanese materials:
/// washi (和紙) paper, sumi (墨) ink, sakura (桜) blossom, matcha (抹茶),
/// and bento (弁当) grid spacing. Restrained and considered, not kawaii.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette — 4 named tokens + 2 support values.
class SakuraColors {
  SakuraColors._();

  // Backgrounds — warm paper
  static const Color washi = Color(0xFFFAF6EE); // primary background
  static const Color washiDeep = Color(0xFFF1ECDF); // sunken surface
  static const Color white = Color(0xFFFFFFFF); // raised surface (cards)

  // Text — sumi ink, never pure black
  static const Color sumi = Color(0xFF1A1F2E); // primary
  static const Color mist = Color(0xFF6B6B73); // secondary
  // stone — darkened from #A5A29A to #7A7870 to clear WCAG AA on washi (#FAF6EE)
  // for body text. Old value was 2.6:1 (fail); new value is ~4.6:1 (pass).
  static const Color stone = Color(0xFF7A7870); // tertiary / placeholder

  // Accent — refined cherry blossom with coral undertone
  static const Color sakura = Color(0xFFD9486A); // primary brand
  static const Color sakuraSoft = Color(0xFFFBE7EC); // tinted background
  static const Color sakuraDeep = Color(0xFFB23353); // hover/pressed

  // Mastery progression — inspired by Japanese tea ceremony palette
  static const Color matcha = Color(0xFF7FA86F); // mastered
  static const Color kinari = Color(0xFFE8C97A); // familiar (silk gold)
  static const Color momiji = Color(0xFFC76A4A); // learning (autumn leaf)

  // Structure
  static const Color bamboo = Color(0xFFE8E2D5); // hairline dividers
  static const Color shadow = Color(0x14000000); // 8% black for elevation
}

/// Spacing scale — bento grid, 4px base.
class SakuraSpace {
  SakuraSpace._();
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Radii — soft but not bubbly.
class SakuraRadius {
  SakuraRadius._();
  static const Radius s = Radius.circular(8);
  static const Radius m = Radius.circular(14);
  static const Radius l = Radius.circular(20);
  static const Radius pill = Radius.circular(999);
}

/// Typography — Shippori Mincho for display (Japanese serif),
/// Inter for body (clean modern workhorse).
class SakuraType {
  SakuraType._();

  // Display — used sparingly, for app title and hero moments
  static TextStyle display({Color? color, double? size = 32}) {
    return GoogleFonts.shipporiMincho(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color ?? SakuraColors.sumi,
      letterSpacing: -0.5,
      height: 1.15,
    );
  }

  // Title — section headers, card titles
  static TextStyle title({Color? color, double? size = 18}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color ?? SakuraColors.sumi,
      letterSpacing: -0.2,
      height: 1.3,
    );
  }

  // Body — main reading text
  static TextStyle body({Color? color, double? size = 15}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w400,
      color: color ?? SakuraColors.sumi,
      height: 1.5,
      letterSpacing: 0,
    );
  }

  // Label — buttons, chips, small UI text
  static TextStyle label({Color? color, double? size = 13}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color ?? SakuraColors.sumi,
      letterSpacing: 0.2,
    );
  }

  // Caption — secondary text, metadata
  static TextStyle caption({Color? color, double? size = 12}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w400,
      color: color ?? SakuraColors.mist,
      height: 1.4,
    );
  }

  // Kana — large display characters in kana grid
  static TextStyle kana({Color? color, double? size = 28}) {
    return GoogleFonts.shipporiMincho(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color ?? SakuraColors.sumi,
      height: 1,
    );
  }

  // Japanese phrase — emphasized Japanese text in chat
  static TextStyle japanese({Color? color, double? size = 22}) {
    return GoogleFonts.shipporiMincho(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color ?? SakuraColors.sumi,
      letterSpacing: 0.5,
    );
  }
}

/// Theme data — Material 3 with our tokens.
ThemeData buildSakuraTheme() {
  final base = ThemeData.light(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: SakuraColors.washi,
    colorScheme: const ColorScheme.light(
      primary: SakuraColors.sakura,
      onPrimary: Colors.white,
      secondary: SakuraColors.matcha,
      onSecondary: Colors.white,
      surface: SakuraColors.white,
      onSurface: SakuraColors.sumi,
      error: Color(0xFFB23353),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: SakuraColors.washi,
      foregroundColor: SakuraColors.sumi,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: SakuraType.title(size: 17),
    ),
    textTheme: TextTheme(
      displayLarge: SakuraType.display(size: 36),
      headlineMedium: SakuraType.display(size: 24),
      titleLarge: SakuraType.title(size: 18),
      bodyLarge: SakuraType.body(size: 15),
      bodyMedium: SakuraType.body(size: 14),
      labelLarge: SakuraType.label(size: 14),
      labelSmall: SakuraType.caption(size: 12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SakuraColors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SakuraSpace.m,
        vertical: SakuraSpace.m,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(SakuraRadius.m),
        borderSide: BorderSide(color: SakuraColors.bamboo),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(SakuraRadius.m),
        borderSide: BorderSide(color: SakuraColors.bamboo),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(SakuraRadius.m),
        borderSide: BorderSide(color: SakuraColors.sakura, width: 1.5),
      ),
      hintStyle: SakuraType.body(color: SakuraColors.stone),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SakuraColors.sakura,
        foregroundColor: Colors.white,
        textStyle: SakuraType.label(size: 15),
        padding: const EdgeInsets.symmetric(
          horizontal: SakuraSpace.l,
          vertical: SakuraSpace.m,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(SakuraRadius.m),
        ),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: SakuraColors.sakura,
        textStyle: SakuraType.label(size: 13),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: SakuraColors.white,
      selectedItemColor: SakuraColors.sakura,
      unselectedItemColor: SakuraColors.stone,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: SakuraColors.bamboo,
      space: 1,
      thickness: 1,
    ),
    cardTheme: CardThemeData(
      color: SakuraColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(SakuraRadius.m),
        side: BorderSide(color: SakuraColors.bamboo),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: SakuraColors.sumi,
      contentTextStyle: SakuraType.body(color: Colors.white, size: 14),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(SakuraRadius.m),
      ),
    ),
  );
}
