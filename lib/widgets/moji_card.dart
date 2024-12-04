import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mojikit/mojikit.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:signals/signals_flutter.dart';
import 'package:signals/signals_flutter_extended.dart';

class MojiCard extends StatefulWidget {
  final String id;
  final bool renderedByMojiIsland, shouldShowParentMojis, placeholder, openMojiChild;
  final Node? node;
  final AutoScrollController? autoScrollController;
  const MojiCard({
    required this.id,
    required this.renderedByMojiIsland,
    required this.shouldShowParentMojis,
    required this.openMojiChild,
    required this.placeholder,
    this.autoScrollController,
    this.node,
    super.key,
  });

  @override
  State<MojiCard> createState() => _MojiCardState();
}

class _MojiCardState extends State<MojiCard> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool hasUnwrittenChange = false;

  textEditingContollerListener() {
    if (S.selectedMID.untrackedValue == widget.id) {
      S.currentMojiText.set(_controller.text);
    }
    if (_controller.text.isEmpty) {
      S.shouldTraverseFocus.set(true);
      final nodeInstance = widget.node;
      FocusManager.instance.primaryFocus?.previousFocus();
      if (nodeInstance != null) {
        nodeInstance.parent?.removeChild(nodeInstance);
      }
      R.deleteMojis({widget.id});
      for (final activeTreeControllerWithNode in U.activeTreeControllers.values) {
        final activeTreeController = activeTreeControllerWithNode.$2;
        activeTreeController.rebuild();
      }
      return;
    }

    if (_controller.text.startsWith(kEmptySpace) != true) {
      // Prefix the text with an empty space
      _controller.text = kEmptySpace + _controller.text;
      _controller.selection = _controller.selection.copyWith(baseOffset: 1, extentOffset: 1);
    }

    // Disallow 0th caracter selection
    if (_controller.selection.start == 0) {
      _controller.selection = _controller.selection.copyWith(baseOffset: 1, extentOffset: _controller.selection.isCollapsed ? 1 : null);
    }
  }

  onFocused() {
    if (_focusNode.hasFocus) {
      batch(() {
        S.selectedMID.set(widget.id);
        S.currentMojiText.set(_controller.text);
      });
      ensureVisible();
    } else {
      S.currentMojiText.set(kEmptyString);
      // If there are unwritten changes
      if (hasUnwrittenChange) {
        // Check if it's a placeholder
        final isPlaceholder = widget.placeholder;
        // Get the selected MID
        var selectedMID = S.selectedMID.untrackedValue;
        // If the selected MID is empty
        if (selectedMID?.isEmpty == true) {
          // Set it to null
          selectedMID = null;
        }
        // If the widget is mounted
        if (mounted) {
          // Update the Moji with the latest changes and write them to the server
          R.updateMoji(widget.id, text: _controller.text, npid: isPlaceholder ? selectedMID : null, shouldUpdateOrigin: true);
          // Reset the flag
          hasUnwrittenChange = false;
        }
      }
    }
  }

  ensureVisible({bool shouldRequestFocus = false}) {
    final index = widget.node?.index;
    if (index != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.autoScrollController?.scrollToIndex(index);
      });
    }
  }

  @override
  void initState() {
    final mojiR = R.getMoji(widget.id);
    var text = mojiR.t ?? kEmptyString;

    if (text.startsWith(kEmptySpace)) {
      text = text.replaceFirst(kEmptySpace, kEmptyString);
    }
    text = text.replaceAll(kZeroWidthSpace, kEmptyString);

    _focusNode = FocusNode();

    _focusNode.addListener(onFocused);

    if (S.selectedMID.untrackedValue == widget.id && widget.renderedByMojiIsland != true) {
      _focusNode.requestFocus();
    }
    _controller = TextWithPrefixController(
      prefixWidget: AnimatedBuilder(
        animation: _focusNode,
        builder: (context, child) {
          if (child == null) {
            return const SizedBox.shrink();
          }
          final shouldBeFocused = S.selectedMID.untrackedValue == widget.id && widget.renderedByMojiIsland != true;
          return Visibility(visible: _focusNode.hasFocus != true && shouldBeFocused != true && _controller.text.trim().isEmpty, child: child);
        },
        child: Watch((context) {
          return Text(
            'Enter Text..',
            style: TextStyle(
              color: S.implicitMojiDockTile.value?.dye.value.extraDark,
              fontFamily: kDefaultFontFamily,
              fontFamilyFallback: const [kUnicodeMojiFamily],
            ),
          );
        }),
      ),
      text: '$kEmptySpace$text',
    );

    _controller.addListener(textEditingContollerListener);
    super.initState();
  }

  @override
  void dispose() {
    _controller.removeListener(textEditingContollerListener);
    _controller.dispose();
    _focusNode.removeListener(onFocused);
    _focusNode.dispose();
    super.dispose();
  }

  late final _mojiR = S.mojiSignal(widget.id);
  late final _isMojiFlying = computed(() => S.flyingMoji.value.id == widget.id);
  late final _dyeAndParents = computed(() {
    final mojiR = _mojiR.value;
    final mojiText = mojiR.t;
    if (_controller.text != mojiText) {
      _controller.value = _controller.value.copyWith(text: mojiText);
    }
    final (mojiDT, parents) = R.getMojiDockTileAndParents(mojiR);
    return (mojiDT.dye.value, parents);
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        S.selectedMID.set(widget.id);
        _focusNode.requestFocus();
      },
      child: Watch(
        (context) {
          final isMojiFlying = _isMojiFlying.value;
          final dye = _dyeAndParents.value.$1;
          final isSelected = S.selectedMID.value == widget.id;
          return AnimatedContainer(
            constraints: BoxConstraints(
              minWidth: widget.openMojiChild ? kMojiTileWidth - 8 : kMojiTileWidth,
              minHeight: kMojiTileHeight,
            ),
            duration: const Duration(milliseconds: 250),
            curve: Curves.ease,
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.only(top: 4, left: 8, right: 2),
            decoration: BoxDecoration(
              color: dye.lighter,
              borderRadius: BorderRadius.circular(kMojiTileBorderRadius),
              border: Border.all(
                color: isSelected || isMojiFlying ? dye.extraDark : dye.medium,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 3, top: 3, right: 3, bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 1.5),
                    child: Watch((context) {
                      final dye = _dyeAndParents.value.$1;
                      return Theme(
                        data: ThemeData(
                          textSelectionTheme: TextSelectionThemeData(
                            cursorColor: dye.extraDark,
                            selectionColor: dye.medium.withValues(alpha: 0.75),
                            selectionHandleColor: dye.extraDark,
                          ),
                        ),
                        child: Watch((context) {
                          final dye = _dyeAndParents.value.$1;
                          return CupertinoTheme(
                            data: CupertinoThemeData(
                              primaryColor: dye.extraDark,
                            ),
                            child: Watch((context) {
                              final dye = _dyeAndParents.value.$1;
                              return TextField(
                                onTapOutside: (event) {
                                  // Since we will be losing focus there won't be any unwritten changes after we update the moji from here
                                  hasUnwrittenChange = false;
                                  // Check if it's a placeholder
                                  final isPlaceholder = widget.placeholder;
                                  // Get the selected MID
                                  var selectedMID = S.selectedMID.untrackedValue;
                                  // If the selected MID is empty
                                  if (selectedMID?.isEmpty == true) {
                                    // Set it to null
                                    selectedMID = null;
                                  }

                                  // Update the moji with the latest changes and write them to the server
                                  R.updateMoji(widget.id, text: _controller.text, npid: isPlaceholder ? selectedMID : null, shouldUpdateOrigin: true);
                                  // Wait a frame to avoid flicker
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    // Clear the current moji text
                                    S.currentMojiText.set(kEmptyString);
                                  });
                                },
                                contextMenuBuilder: (BuildContext context, EditableTextState editableTextState) {
                                  // If supported, show the system context menu.
                                  if (SystemContextMenu.isSupported(context)) {
                                    return SystemContextMenu.editableText(
                                      editableTextState: editableTextState,
                                    );
                                  }
                                  // Otherwise, show the flutter-rendered context menu for the current platform.
                                  return AdaptiveTextSelectionToolbar.editableText(
                                    editableTextState: editableTextState,
                                  );
                                },
                                onTap: () {
                                  S.selectedMID.set(widget.id);
                                },
                                controller: _controller,
                                focusNode: _focusNode,
                                textInputAction: TextInputAction.next,
                                cursorHeight: 18,
                                keyboardAppearance: S.darkness.untrackedValue ? Brightness.dark : Brightness.light,
                                decoration: null,
                                style: TextStyle(
                                  color: dye.ultraDark,
                                  fontFamily: kDefaultFontFamily,
                                  fontFamilyFallback: const [kUnicodeMojiFamily],
                                ),
                                maxLines: null,
                                onChanged: (value) {
                                  S.lastInteractionAt.set(DateTime.now());
                                  final mojiR = _mojiR.untrackedValue;
                                  hasUnwrittenChange = true;
                                  R.m.write(() {
                                    mojiR.t = value;
                                  });
                                },
                                onSubmitted: (value) {
                                  final isPlaceholder = widget.placeholder;
                                  var selectedMID = S.selectedMID.untrackedValue;
                                  if (selectedMID?.isEmpty == true) {
                                    selectedMID = null;
                                  }
                                  if (S.selectedHeaderView.untrackedValue == MMHeaderView.thoughts) {
                                    final cfid = U.fid();
                                    batch(() {
                                      S.selectedMID.set(cfid);
                                      S.shouldTraverseFocus.set(false);
                                    });
                                    if (widget.renderedByMojiIsland) {
                                      R.addChildMoji(pid: widget.id, cfid: cfid);
                                      final parents = _dyeAndParents.untrackedValue.$2;
                                      parents.insert(0, _mojiR.untrackedValue);
                                      for (final parent in parents) {
                                        if (U.activeTreeControllers[parent.id] != null) {
                                          final pinnedMoji = U.activeTreeControllers[parent.id]?.$1;
                                          pinnedMoji?.insertChild(0, Node(id: cfid));
                                          U.activeTreeControllers[parent.id]?.$2.rebuild();
                                          break;
                                        }
                                      }
                                    } else {
                                      final mojiR = _mojiR.untrackedValue;
                                      if (mojiR.id.isNotEmpty) {
                                        R.updateMoji(widget.id, text: value, npid: isPlaceholder ? selectedMID : null, shouldUpdateOrigin: true);
                                        R.addSiblingMoji(mojiR, sfid: cfid);
                                        widget.node?.parent?.insertChild((widget.node?.index ?? 0) + 1, Node(id: cfid));
                                      }
                                    }
                                    final parents = _dyeAndParents.untrackedValue.$2;
                                    for (final parent in parents) {
                                      if (U.activeTreeControllers[parent.id] != null) {
                                        U.activeTreeControllers[parent.id]?.$2.rebuild();
                                      }
                                    }
                                  } else {
                                    R.updateMoji(widget.id, text: value, npid: isPlaceholder ? selectedMID : null, shouldUpdateOrigin: true);
                                  }
                                },
                                textCapitalization: TextCapitalization.sentences,
                              );
                            }),
                          );
                        }),
                      );
                    }),
                  ),
                  Visibility(
                    visible: widget.shouldShowParentMojis,
                    child: Watch(
                      (context) {
                        final mojiR = _mojiR.value;
                        if (mojiR.p == null) return const SizedBox();
                        return MojiToolbar(mojiId: widget.id);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
