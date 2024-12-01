import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:mojikit/mojikit.dart';
import 'package:realm/realm.dart';
import 'package:signals/signals_flutter.dart';
import 'package:signals/signals_flutter_extended.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SignalsObserver.instance = null;
  // Set the author
  await U.setAuthor();

  // Load the default font once
  GoogleFonts.rubik();
  final realmPath = await getRealmPath();

  // Initialize realm
  R.m = Realm(Configuration.local([Moji.schema], path: '$realmPath/moji'));
  R.p = Realm(Configuration.local([Preferences.schema], path: '$realmPath/preferences'));
  S.selectedHeaderView.set(MMHeaderView.thoughts);
  runApp(const MojiKitApp());
}

class MojiKitApp extends StatefulWidget {
  const MojiKitApp({super.key});

  @override
  State<MojiKitApp> createState() => _MojiKitAppState();
}

class _MojiKitAppState extends State<MojiKitApp> {
  final _dye = Dyes.grey;
  final r = S.mojiSignal(MojiDockTile.r.name);
  final o = S.mojiSignal(MojiDockTile.o.name);
  final g = S.mojiSignal(MojiDockTile.g.name);
  final t = S.mojiSignal(MojiDockTile.t.name);
  final b = S.mojiSignal(MojiDockTile.b.name);
  final i = S.mojiSignal(MojiDockTile.i.name);
  final p = S.mojiSignal(MojiDockTile.p.name);
  final c = S.mojiSignal(MojiDockTile.c.name);
  late final _mojiDockTilesWithDye = computed(() {
    final mojiDockTiles = [
      (r.value, MojiDockTile.r.dye),
      (o.value, MojiDockTile.o.dye),
      (g.value, MojiDockTile.g.dye),
      (t.value, MojiDockTile.t.dye),
      (b.value, MojiDockTile.b.dye),
      (i.value, MojiDockTile.i.dye),
      (p.value, MojiDockTile.p.dye),
      (c.value, MojiDockTile.c.dye),
    ];
    return mojiDockTiles;
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Watch(
        (context) {
          final darkness = S.darkness.value;
          return MojiColorFiltered(
            darkness: darkness,
            child: Theme(
              data: ThemeData.light().copyWith(
                dialogTheme: DialogTheme(
                  barrierColor: darkness ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
                ),
              ),
              child: Watch((context) {
                final dye = _dye.value;
                return ColoredBox(
                  color: U.ultraLightBackground(dye),
                  child: SafeArea(
                    maintainBottomViewPadding: true,
                    top: false,
                    left: false,
                    right: false,
                    bottom: true,
                    minimum: const EdgeInsets.only(bottom: 15),
                    child: Scaffold(
                      appBar: AppBar(
                        toolbarHeight: defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android ? 50 : 90,
                        elevation: 0.0,
                        systemOverlayStyle: darkness
                            ? SystemUiOverlayStyle.light.copyWith(
                                statusBarColor: Colors.transparent,
                                systemNavigationBarColor: invertColor(dye.ultraLight),
                                systemNavigationBarContrastEnforced: false,
                                systemNavigationBarIconBrightness: Brightness.dark,
                              )
                            : SystemUiOverlayStyle.dark.copyWith(
                                statusBarColor: Colors.transparent,
                                systemNavigationBarColor: dye.ultraLight,
                                systemNavigationBarContrastEnforced: false,
                                systemNavigationBarIconBrightness: Brightness.light,
                              ),
                        shadowColor: Colors.transparent,
                        backgroundColor: U.ultraLightBackground(dye),
                        centerTitle: true,
                        bottom: defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android
                            ? const PreferredSize(preferredSize: Size.fromHeight(15), child: SizedBox.shrink())
                            : null,
                        title: SizedBox(
                          width: 428,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  final darkness = S.darkness.untrackedValue;
                                  HapticFeedback.mediumImpact();
                                  R.updateDarkness(!darkness);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: dye.lighter),
                                  child: Center(
                                    child: RotatedBox(
                                      quarterTurns: 3,
                                      child: Watch((context) {
                                        final dye = _dye.value;
                                        return HugeIcon(icon: HugeIcons.strokeRoundedMoon02, color: dye.dark, size: 21);
                                      }),
                                    ),
                                  ),
                                ),
                              ),
                              for (final headerView in MMHeaderView.values)
                                Watch(
                                  (context) {
                                    final dye = _dye.value;
                                    final sHeaderView = S.selectedHeaderView.value;
                                    return Opacity(
                                      opacity: headerView == MMHeaderView.thoughts ? 1.0 : 0.42,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: dye.light.withValues(alpha: 0.0),
                                          border: Border.all(
                                            width: 3,
                                            color: dye.dark.withValues(alpha: sHeaderView == headerView ? 0.9 : 0.0),
                                          ),
                                        ),
                                        padding: const EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
                                        child: Text(
                                          toBeginningOfSentenceCase(headerView.name) ?? kEmptyString,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            fontFamily: kDefaultFontFamily,
                                            fontFamilyFallback: [kUnicodeMojiFamily],
                                            overflow: TextOverflow.ellipsis,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (U.mojiChanges.canUndo) {
                                    HapticFeedback.mediumImpact();
                                    U.mojiChanges.undo();
                                  }
                                },
                                child: Watch((context) {
                                  final dye = _dye.value;
                                  return Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: dye.lighter),
                                    child: Center(
                                      child: Watch((context) {
                                        final dye = _dye.value;
                                        return HugeIcon(icon: HugeIcons.strokeRoundedArrowTurnBackward, color: dye.darker, size: 21);
                                      }),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      extendBodyBehindAppBar: false,
                      extendBody: true,
                      resizeToAvoidBottomInset: false,
                      body: Watch((context) {
                        final mojiDockTiles = _mojiDockTilesWithDye.value;
                        return Container(
                          color: U.ultraLightBackground(dye),
                          child: ReorderableListView.builder(
                            physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            padding: EdgeInsets.only(left: 15),
                            itemExtentBuilder: (index, dimensions) {
                              final screenWidth = dimensions.viewportMainAxisExtent;
                              final extent = screenWidth - 60.0 > 500.0 ? 500.0 : screenWidth - 60.0;
                              return extent;
                            },
                            onReorderStart: (index) {},
                            onReorderEnd: (index) {},
                            scrollDirection: Axis.horizontal,
                            buildDefaultDragHandles: false,
                            proxyDecorator: (child, index, animation) {
                              return Transform.rotate(
                                angle: 0.10,
                                child: Transform.scale(
                                  scale: 0.8,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            itemBuilder: (context, index) {
                              final (mojiDockTile, mojiDockTileDye) = mojiDockTiles[index];
                              return Watch(key: ValueKey(mojiDockTile.id), (context) {
                                final dye = mojiDockTileDye.value;
                                return Padding(
                                  padding: EdgeInsets.only(right: 15),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/hugeicons/${mojiDockTile.m}',
                                        width: kMojiTileIconSize,
                                        height: kMojiTileIconSize,
                                        colorFilter: ColorFilter.mode(dye.dark, BlendMode.srcIn),
                                      ),
                                      Expanded(
                                        child: Container(
                                          margin: EdgeInsets.only(top: 5),
                                          decoration: BoxDecoration(
                                            color: dye.ultraLight,
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(
                                              width: 6,
                                              color: dye.dark.withValues(alpha: 1.0),
                                            ),
                                          ),
                                          child: FocusScope(
                                            child: FocusTraversalGroup(
                                              policy: WidgetOrderTraversalPolicy(
                                                requestFocusCallback: (node, {alignment, alignmentPolicy, curve, duration}) {
                                                  if (S.shouldTraverseFocus.untrackedValue) {
                                                    node.requestFocus();
                                                    S.shouldTraverseFocus.set(false);
                                                  }
                                                },
                                              ),
                                              child: MojiTree(
                                                key: ValueKey('mojiTree:${mojiDockTile.id}'),
                                                mid: mojiDockTile.id,
                                                dye: dye,
                                                mojiPlannerWidth: 500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              });
                            },
                            itemCount: mojiDockTiles.length,
                            onReorder: (a, b) {},
                          ),
                        );
                      }),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
