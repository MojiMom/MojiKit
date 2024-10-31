import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:signals/signals.dart';
import 'package:mojikit/mojikit.dart';

class Dyes {
  static const greyReference = Color.from(alpha: 1.0, red: 0.42, green: 0.42, blue: 0.42);
  static final Dye greyLight = generateDyePalette(greyReference, invert: false);
  static final Dye greyDark = generateDyePalette(greyReference);
  static Computed<Dye> get grey => computed(() => S.darkness.value ? greyDark : greyLight);

  static const tealReference = Color.from(alpha: 1.0, red: 0.000000, green: 0.537255, blue: 0.482353);
  static final Dye tealLight = generateDyePalette(tealReference, invert: false);
  static final Dye tealDark = generateDyePalette(tealReference);
  static Computed<Dye> get teal => computed(() => S.darkness.value ? tealDark : tealLight);

  static const blueReference = Color.from(alpha: 1.0, red: 0.117647, green: 0.533333, blue: 0.898039);
  static final Dye blueLight = generateDyePalette(blueReference, invert: false);
  static final blueDark = generateDyePalette(blueReference);
  static Computed<Dye> get blue => computed(() => S.darkness.value ? blueDark : blueLight);

  static const indigoReference = Color.from(alpha: 1.0, red: 0.635294, green: 0.376471, blue: 0.972549);
  static final Dye indigoLight = generateDyePalette(indigoReference, invert: false);
  static final Dye indigoDark = generateDyePalette(indigoReference);
  static Computed<Dye> get indigo => computed(() => S.darkness.value ? indigoDark : indigoLight);

  static const pinkReference = Color.from(alpha: 1.0, red: 0.913725, green: 0.117647, blue: 0.388235);
  static final Dye pinkLight = generateDyePalette(pinkReference, invert: false);
  static final Dye pinkDark = generateDyePalette(pinkReference);
  static Computed<Dye> get pink => computed(() => S.darkness.value ? pinkDark : pinkLight);

  static const redReference = Color.from(alpha: 1.0, red: 0.898039, green: 0.223529, blue: 0.207843);
  static final Dye redLight = generateDyePalette(redReference, invert: false);
  static final Dye redDark = generateDyePalette(redReference);
  static Computed<Dye> get red => computed(() => S.darkness.value ? redDark : redLight);

  static const orangeReference = Color.from(alpha: 1.0, red: 0.984314, green: 0.549020, blue: 0.000000);
  static final Dye orangeLight = generateDyePalette(orangeReference, invert: false);
  static final Dye orangeDark = generateDyePalette(orangeReference);
  static Computed<Dye> get orange => computed(() => S.darkness.value ? orangeDark : orangeLight);

  static const greenReference = Color.from(alpha: 1.0, red: 0.262745, green: 0.627451, blue: 0.278431);
  static final Dye greenLight = generateDyePalette(greenReference, invert: false);
  static final Dye greenDark = generateDyePalette(greenReference);
  static Computed<Dye> get green => computed(() => S.darkness.value ? greenDark : greenLight);

  static const chestnutReference = Color.from(alpha: 1.0, red: 0.427451, green: 0.298039, blue: 0.254902);
  static final Dye chestnutLight = generateDyePalette(chestnutReference, invert: false);
  static final Dye chestnutDark = generateDyePalette(chestnutReference);
  static Computed<Dye> get chestnut => computed(() => S.darkness.value ? chestnutDark : chestnutLight);
}

Color invertColor(Color color) {
  return Color.from(alpha: color.a, red: 1 - color.r, green: 1 - color.g, blue: 1 - color.b);
}

Dye generateDyePalette(Color inputColor, {bool invert = true}) {
  // Invert the input color if needed
  Color baseColor = invert ? invertColor(inputColor) : inputColor;

  List<Color> palette = [];

  for (int i = 0; i < 9; i++) {
    double factor = i / (invert ? 6.75 : 6.35);

    Color newColor = Color.lerp(
      baseColor,
      Color.from(alpha: 1, red: 1.0, green: 1.0, blue: 1.0),
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
