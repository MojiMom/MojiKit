import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mojikit/mojikit.dart';
import 'package:realm/realm.dart';
import 'package:signals/signals_flutter.dart';

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

  runApp(const MojiKitApp());
}

class MojiKitApp extends StatefulWidget {
  const MojiKitApp({super.key});

  @override
  State<MojiKitApp> createState() => _MojiKitAppState();
}

class _MojiKitAppState extends State<MojiKitApp> {
  final _dye = Dyes.blue;

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
                  barrierColor: darkness ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
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
                    minimum: const EdgeInsets.only(bottom: 10),
                    child: Scaffold(
                      appBar: AppBar(
                        toolbarHeight:
                            defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android ? 50 : 90,
                        elevation: 0.0,
                        systemOverlayStyle: darkness ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
                              Spacer(),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  final darkness = untracked(() => S.darkness.value);
                                  HapticFeedback.mediumImpact();
                                  R.updateDarkness(!darkness);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: dye.lighter),
                                  child: Center(
                                    child: RotatedBox(
                                      quarterTurns: 3,
                                      child: HugeIcon(icon: HugeIcons.strokeRoundedMoon02, color: dye.dark, size: 21),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      extendBodyBehindAppBar: false,
                      extendBody: true,
                      resizeToAvoidBottomInset: false,
                      body: Container(color: U.ultraLightBackground(dye)),
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
