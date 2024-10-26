import 'package:mojikit/classes/moji.dart';

Moji mojiFromJson(String documentID, Map<String, dynamic> json) {
  return Moji(
    documentID,
    a: json['a'],
    d: json['d'],
    m: json['m'],
    p: json['p'],
    t: json['t'],
    c: json['c'] != null ? Map<String, String>.from(json['c']) : <String, String>{},
    h: json['h'] != null ? Map<String, String>.from(json['h']) : <String, String>{},
    l: json['l'] != null
        ? Map<String, int>.from(json['l']).map(
            (k, v) => MapEntry(
              k,
              DateTime.fromMillisecondsSinceEpoch(
                v,
                isUtc: true,
              ),
            ),
          )
        : <String, DateTime>{},
    j: json['j'] != null
        ? Map<String, int>.from(json['j']).map(
            (k, v) => MapEntry(
              k,
              DateTime.fromMillisecondsSinceEpoch(
                v,
                isUtc: true,
              ),
            ),
          )
        : <String, DateTime>{},
    q: json['q'] != null ? Map<String, String>.from(json['q']) : <String, String>{},
    x: json['x'] != null ? Map<String, String>.from(json['x']) : <String, String>{},
    s: json['s'] != null ? DateTime.fromMillisecondsSinceEpoch(json['s'], isUtc: true) : null,
    e: json['e'] != null ? DateTime.fromMillisecondsSinceEpoch(json['e'], isUtc: true) : null,
    f: json['f'] != null ? DateTime.fromMillisecondsSinceEpoch(json['f'], isUtc: true) : null,
    u: json['u'] != null ? DateTime.fromMillisecondsSinceEpoch(json['u'], isUtc: true) : null,
    w: json['w'] != null ? DateTime.fromMillisecondsSinceEpoch(json['w'], isUtc: true) : null,
    b: json['b'] != null ? DateTime.fromMillisecondsSinceEpoch(json['b'], isUtc: true) : null,
    o: json['o'],
    i: json['i'],
  );
}
