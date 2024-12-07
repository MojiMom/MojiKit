import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:signals/signals.dart';
import 'package:mojikit/mojikit.dart';

class Dyes {
  static const almostBlack = Color.from(alpha: 1.0, red: 0.1294, green: 0.1294, blue: 0.1294);
  static const almostWhite = Color.from(alpha: 1.0, red: 0.8706, green: 0.8706, blue: 0.8706);
  static Computed<Color> get almostWhiteOrBlack => computed(() => S.darkness.value ? almostWhite : almostBlack);
  static Computed<Color> get almostBlackOrWhite => computed(() => S.darkness.value ? almostBlack : almostWhite);

  static const greyReference = Color.from(alpha: 1.0, red: 0.42, green: 0.42, blue: 0.42);
  static final Dye greyLight = generateDyePalette(greyReference, invert: false);
  static final Dye greyDark = generateDyePalette(greyReference, invert: true);
  static Computed<Dye> get grey => computed(() => S.darkness.value ? greyDark : greyLight);

  static const tealReference = Color.from(alpha: 1.0, red: 0.000000, green: 0.537255, blue: 0.482353);
  static final Dye tealLight = generateDyePalette(tealReference);
  static final Dye tealDark = generateDyePalette(tealReference, invert: true);
  static Computed<Dye> get teal => computed(() => S.darkness.value ? tealDark : tealLight);

  static const blueReference = Color.from(alpha: 1.0, red: 0.117647, green: 0.533333, blue: 0.898039);
  static final Dye blueLight = generateDyePalette(blueReference);
  static final Dye blueDark = generateDyePalette(blueReference, invert: true);
  static Computed<Dye> get blue => computed(() => S.darkness.value ? blueDark : blueLight);

  static const indigoReference = Color.from(alpha: 1.0, red: 0.67, green: 0.28, blue: 0.90);
  static final Dye indigoLight = generateDyePalette(indigoReference);
  static final Dye indigoDark = generateDyePalette(indigoReference, invert: true);
  static Computed<Dye> get indigo => computed(() => S.darkness.value ? indigoDark : indigoLight);

  static const pinkReference = Color.from(alpha: 1.0, red: 0.913725, green: 0.117647, blue: 0.388235);
  static final Dye pinkLight = generateDyePalette(pinkReference);
  static final Dye pinkDark = generateDyePalette(pinkReference, invert: true);
  static Computed<Dye> get pink => computed(() => S.darkness.value ? pinkDark : pinkLight);

  static const redReference = Color.from(alpha: 1.0, red: 0.898039, green: 0.223529, blue: 0.207843);
  static final Dye redLight = generateDyePalette(redReference);
  static final Dye redDark = generateDyePalette(redReference, invert: true);
  static Computed<Dye> get red => computed(() => S.darkness.value ? redDark : redLight);

  static const orangeReference = Color.from(alpha: 1.0, red: 0.984314, green: 0.549020, blue: 0.000000);
  static final Dye orangeLight = generateDyePalette(orangeReference);
  static final Dye orangeDark = generateDyePalette(orangeReference, invert: true);
  static Computed<Dye> get orange => computed(() => S.darkness.value ? orangeDark : orangeLight);

  static const greenReference = Color.from(alpha: 1.0, red: 0.262745, green: 0.627451, blue: 0.278431);
  static final Dye greenLight = generateDyePalette(greenReference);
  static final Dye greenDark = generateDyePalette(greenReference, invert: true);
  static Computed<Dye> get green => computed(() => S.darkness.value ? greenDark : greenLight);

  static const chestnutReference = Color.from(alpha: 1.0, red: 0.427451, green: 0.298039, blue: 0.254902);
  static final Dye chestnutLight = generateDyePalette(chestnutReference);
  static final Dye chestnutDark = generateDyePalette(chestnutReference, invert: true);
  static Computed<Dye> get chestnut => computed(() => S.darkness.value ? chestnutDark : chestnutLight);
}

Dye generateDyePalette(Color inputColor, {bool invert = false}) {
  // For light mode (invert = false), we go from the base color towards white.
  // For dark mode (invert = true), we go from the base color towards black.
  final Color targetColor = invert ? Color.from(alpha: 1.0, red: 0.0, green: 0.0, blue: 0.0) : Color.from(alpha: 1.0, red: 1.0, green: 1.0, blue: 1.0);

  List<Color> palette = [];

  // Adjust the factor scaling if needed to get a nice range
  for (int i = 0; i < 9; i++) {
    double factor = i / (invert ? 6.75 : 6.35);

    Color newColor = Color.lerp(
      inputColor,
      targetColor,
      factor,
    )!;

    palette.add(newColor);
  }

  return Dye(
    ultraDark: palette[0],
    extraDark: palette[1],
    darker: palette[2],
    dark: palette[3],
    medium: palette[4],
    light: palette[5],
    lighter: palette[6],
    extraLight: palette[7],
    ultraLight: palette[8],
  );
}

class Dye {
  final Color ultraDark;
  final Color extraDark;
  final Color darker;
  final Color dark;
  final Color medium;
  final Color light;
  final Color lighter;
  final Color extraLight;
  final Color ultraLight;

  const Dye({
    required this.ultraDark,
    required this.extraDark,
    required this.darker,
    required this.dark,
    required this.medium,
    required this.light,
    required this.lighter,
    required this.extraLight,
    required this.ultraLight,
  });
}
