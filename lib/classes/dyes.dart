import 'package:flutter/material.dart';
import 'package:signals/signals.dart';
import 'package:mojikit/mojikit.dart';

class Dyes {
  static const unknown = Dye(
    ultraDark: Colors.black,
    extraDark: Colors.black,
    darker: Colors.black,
    dark: Colors.black,
    medium: Colors.black,
    light: Colors.black,
    lighter: Colors.black,
    extraLight: Colors.black,
    ultraLight: Colors.black,
  );

  static const Dye tealLight = Dye(
    ultraDark: Color.fromRGBO(0, 137, 123, 1),
    extraDark: Color.fromRGBO(38, 166, 154, 1),
    darker: Color.fromRGBO(77, 182, 172, 1),
    dark: Color.fromRGBO(128, 203, 196, 1),
    medium: Color.fromRGBO(178, 223, 219, 1),
    light: Color.fromRGBO(224, 242, 241, 1),
    lighter: Color.fromRGBO(241, 248, 247, 1),
    extraLight: Color.fromRGBO(245, 251, 250, 1),
    ultraLight: Color.fromRGBO(251, 254, 254, 1),
  );

  static final tealDark = generateDyePalette(tealLight.ultraDark);
  static Computed<Dye> get teal => computed(() => S.darkness.value ? tealDark : tealLight);

  static const Dye blueLight = Dye(
    ultraDark: Color.fromRGBO(30, 136, 229, 1),
    extraDark: Color.fromRGBO(66, 165, 245, 1),
    darker: Color.fromRGBO(100, 181, 246, 1),
    dark: Color.fromRGBO(144, 202, 249, 1),
    medium: Color.fromRGBO(187, 222, 251, 1),
    light: Color.fromRGBO(227, 242, 253, 1),
    lighter: Color.fromRGBO(241, 248, 254, 1),
    extraLight: Color.fromRGBO(245, 250, 255, 1),
    ultraLight: Color.fromRGBO(252, 254, 255, 1),
  );

  static final blueDark = generateDyePalette(blueLight.ultraDark);
  static Computed<Dye> get blue => computed(() => S.darkness.value ? blueDark : blueLight);

  static const Dye indigoLight = Dye(
    ultraDark: Color.fromRGBO(57, 73, 171, 1),
    extraDark: Color.fromRGBO(92, 107, 192, 1),
    darker: Color.fromRGBO(121, 134, 203, 1),
    dark: Color.fromRGBO(159, 168, 218, 1),
    medium: Color.fromRGBO(197, 202, 233, 1),
    light: Color.fromRGBO(232, 234, 246, 1),
    lighter: Color.fromRGBO(241, 243, 250, 1),
    extraLight: Color.fromRGBO(245, 246, 252, 1),
    ultraLight: Color.fromRGBO(252, 252, 254, 1),
  );

  static final indigoDark = generateDyePalette(indigoLight.ultraDark);
  static Computed<Dye> get indigo => computed(() => S.darkness.value ? indigoDark : indigoLight);

  static const Dye pinkLight = Dye(
    ultraDark: Color.fromRGBO(233, 30, 99, 1),
    extraDark: Color.fromRGBO(236, 64, 122, 1),
    darker: Color.fromRGBO(240, 98, 146, 1),
    dark: Color.fromRGBO(244, 143, 177, 1),
    medium: Color.fromRGBO(248, 187, 208, 1),
    light: Color.fromRGBO(252, 228, 236, 1),
    lighter: Color.fromRGBO(254, 241, 246, 1),
    extraLight: Color.fromRGBO(255, 245, 248, 1),
    ultraLight: Color.fromRGBO(255, 252, 253, 1),
  );

  static final pinkDark = generateDyePalette(pinkLight.ultraDark);
  static Computed<Dye> get pink => computed(() => S.darkness.value ? pinkDark : pinkLight);

  static const Dye redLight = Dye(
    ultraDark: Color.fromRGBO(229, 57, 53, 1),
    extraDark: Color.fromRGBO(239, 83, 80, 1),
    darker: Color.fromRGBO(229, 115, 115, 1),
    dark: Color.fromRGBO(239, 154, 154, 1),
    medium: Color.fromRGBO(255, 205, 210, 1),
    light: Color.fromRGBO(255, 235, 238, 1),
    lighter: Color.fromRGBO(255, 243, 244, 1),
    extraLight: Color.fromRGBO(255, 246, 246, 1),
    ultraLight: Color.fromRGBO(255, 252, 252, 1),
  );

  static final redDark = generateDyePalette(redLight.ultraDark);
  static Computed<Dye> get red => computed(() => S.darkness.value ? redDark : redLight);

  static const Dye orangeLight = Dye(
    ultraDark: Color.fromRGBO(251, 140, 0, 1),
    extraDark: Color.fromRGBO(255, 167, 38, 1),
    darker: Color.fromRGBO(255, 183, 77, 1),
    dark: Color.fromRGBO(255, 204, 128, 1),
    medium: Color.fromRGBO(255, 224, 178, 1),
    light: Color.fromRGBO(255, 243, 224, 1),
    lighter: Color.fromRGBO(255, 248, 238, 1),
    extraLight: Color.fromRGBO(255, 250, 243, 1),
    ultraLight: Color.fromRGBO(255, 254, 252, 1),
  );

  static final orangeDark = generateDyePalette(orangeLight.ultraDark);
  static Computed<Dye> get orange => computed(() => S.darkness.value ? orangeDark : orangeLight);

  static const Dye greenLight = Dye(
    ultraDark: Color.fromRGBO(67, 160, 71, 1),
    extraDark: Color.fromRGBO(102, 187, 106, 1),
    darker: Color.fromRGBO(129, 199, 132, 1),
    dark: Color.fromRGBO(165, 214, 167, 1),
    medium: Color.fromRGBO(200, 230, 201, 1),
    light: Color.fromRGBO(232, 245, 233, 1),
    lighter: Color.fromRGBO(241, 250, 242, 1),
    extraLight: Color.fromRGBO(246, 252, 246, 1),
    ultraLight: Color.fromRGBO(252, 254, 252, 1),
  );

  static final greenDark = generateDyePalette(greenLight.ultraDark);
  static Computed<Dye> get green => computed(() => S.darkness.value ? greenDark : greenLight);

  static const Dye chestnutLight = Dye(
    ultraDark: Color.fromRGBO(109, 76, 65, 1),
    extraDark: Color.fromRGBO(141, 110, 99, 1),
    darker: Color.fromRGBO(161, 136, 127, 1),
    dark: Color.fromRGBO(188, 170, 164, 1),
    medium: Color.fromRGBO(215, 204, 200, 1),
    light: Color.fromRGBO(239, 235, 233, 1),
    lighter: Color.fromRGBO(246, 243, 242, 1),
    extraLight: Color.fromRGBO(249, 247, 246, 1),
    ultraLight: Color.fromRGBO(253, 253, 252, 1),
  );

  static final chestnustDark = generateDyePalette(chestnutLight.ultraDark);
  static Computed<Dye> get chestnut => computed(() => S.darkness.value ? chestnustDark : chestnutLight);
}

Color invertColor(Color color) {
  return Color.fromARGB(
    color.alpha,
    255 - color.red,
    255 - color.green,
    255 - color.blue,
  );
}

Dye generateDyePalette(Color inputColor, {bool invert = true}) {
  // Invert the input color
  Color baseColor = invertColor(inputColor);

  List<Color> palette = [];

  for (int i = 0; i < 9; i++) {
    double factor = i / 6.75;

    Color newColor = Color.lerp(
      baseColor, // baseColor.withOpacity(0.7),
      Colors.white,
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
