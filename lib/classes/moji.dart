import 'package:realm/realm.dart';
part 'moji.realm.dart';

@RealmModel()
class _Moji {
  @PrimaryKey()
  late String id;
  @Indexed(RealmIndexType.regular)
  String? a; // Author
  @Indexed(RealmIndexType.regular)
  String? d; // Dye
  @Indexed(RealmIndexType.regular)
  String? p; // Parent
  @Indexed(RealmIndexType.regular)
  String? k; // Kickoff
  @Indexed(RealmIndexType.fullText)
  String? t; // Text
  @Indexed(RealmIndexType.fullText)
  String? r; // Recurrence
  late Map<String, String> c; // Cards
  late Map<String, String> h; // Heap
  late Map<String, DateTime> l; // Log
  late Map<String, DateTime> j; // Junk
  late Map<String, String> q; // Quick Access
  late Map<String, String> v; // Vault
  late Map<String, String> g; // Gatekeeper
  late Map<String, String> x; // Xternal
  late Map<String, String> z; // Zoo
  @Indexed(RealmIndexType.regular)
  DateTime? s; // StartTime
  @Indexed(RealmIndexType.regular)
  DateTime? e; // EndTime;
  @Indexed(RealmIndexType.regular)
  DateTime? f; // FinishedTime
  @Indexed(RealmIndexType.regular)
  DateTime? u; // UpdatedTime
  @Indexed(RealmIndexType.regular)
  DateTime? b; // BeforeTime
  @Indexed(RealmIndexType.regular)
  DateTime? w; // WriteTime
  @Indexed(RealmIndexType.regular)
  bool? o; // Open
  @Indexed(RealmIndexType.regular)
  bool? y; // Yearnful
  @Indexed(RealmIndexType.regular)
  int? i; // Interval
  @Indexed(RealmIndexType.regular)
  int? m; // MojiCodePoint
  @Indexed(RealmIndexType.regular)
  int? n; // Notify

  Map<String, dynamic> toJson() {
    return {
      'a': a,
      'd': d,
      'm': m,
      'p': p,
      't': t,
      'c': c,
      'h': h,
      'l': l.map((k, v) => MapEntry(k, v.toUtc().millisecondsSinceEpoch)),
      'j': j.map((k, v) => MapEntry(k, v.toUtc().millisecondsSinceEpoch)),
      'q': q,
      'g': g,
      'x': x,
      's': s?.toUtc().millisecondsSinceEpoch,
      'e': e?.toUtc().millisecondsSinceEpoch,
      'f': f?.toUtc().millisecondsSinceEpoch,
      'u': u?.toUtc().millisecondsSinceEpoch,
      'w': w?.toUtc().millisecondsSinceEpoch,
      'b': b?.toUtc().millisecondsSinceEpoch,
      'o': o,
      'i': i,
    };
  }

  Moji copyWith({
    String? a,
    String? d,
    int? m,
    String? p,
    String? t,
    Map<String, String>? c,
    Map<String, String>? h,
    Map<String, DateTime>? l,
    Map<String, DateTime>? j,
    Map<String, String>? q,
    Map<String, String>? g,
    Map<String, String>? x,
    DateTime? s,
    DateTime? e,
    DateTime? f,
    DateTime? u,
    DateTime? w,
    bool? o,
    int? i,
  }) {
    return Moji(
      id,
      a: a ?? this.a,
      d: d ?? this.d,
      m: m ?? this.m,
      p: p ?? this.p,
      t: t ?? this.t,
      c: c ?? Map<String, String>.from(this.c),
      h: h ?? Map<String, String>.from(this.h),
      l: l ?? Map<String, DateTime>.from(this.l),
      j: j ?? Map<String, DateTime>.from(this.j),
      q: q ?? Map<String, String>.from(this.q),
      g: g ?? Map<String, String>.from(this.g),
      x: x ?? Map<String, String>.from(this.x),
      s: s ?? this.s,
      e: e ?? this.e,
      f: f ?? this.f,
      u: u ?? this.u,
      w: w ?? this.w,
      o: o ?? this.o,
      i: i ?? this.i,
    );
  }
}
