import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:mojikit/mojikit.dart';
import 'package:signals/signals.dart';

class MojiTree extends StatefulWidget {
  const MojiTree({required this.mid, required this.dye, required this.mojiPlannerWidth, super.key});
  final Dye dye;
  final String mid;
  final double mojiPlannerWidth;

  @override
  State<MojiTree> createState() => _MojiTreeState();
}

class _MojiTreeState extends State<MojiTree> {
  @override
  Widget build(BuildContext context) {
    return DragAndDropTreeView(widget.mid, widget.mojiPlannerWidth, widget.dye);
  }
}

class Node {
  Node({
    required this.id,
    Iterable<Node>? children,
  }) : _children = <Node>[] {
    if (children == null) return;

    for (final Node child in children) {
      child._parent = this;
      _children.add(child);
    }
  }

  final String id;
  final List<Node> _children;

  Iterable<Node> get children => _children;
  bool get isLeaf => _children.isEmpty;

  Node? get parent => _parent;
  Node? _parent;

  int get index => _parent?._children.indexOf(this) ?? -1;

  void removeChild(Node node) {
    _children.remove(node);
    node._parent = null;
  }

  void insertChild(int index, Node node) {
    // Ensure the node is removed from its previous parent and update it
    node
      .._parent?._children.remove(node)
      .._parent = this;

    _children.insert(index, node);
  }
}

extension on TreeDragAndDropDetails<Node> {
  /// Splits the target node's height in three and checks the vertical offset
  /// of the dragging node, applying the appropriate callback.
  T mapDropPosition<T>({
    required T Function() whenAbove,
    required T Function() whenInside,
    required T Function() whenBelow,
  }) {
    final double oneThirdOfTotalHeight = targetBounds.height * 0.3;
    final double pointerVerticalOffset = dropPosition.dy;

    if (pointerVerticalOffset < oneThirdOfTotalHeight) {
      return whenAbove();
    } else if (pointerVerticalOffset < oneThirdOfTotalHeight * 2) {
      return whenInside();
    } else {
      return whenBelow();
    }
  }
}

class DragAndDropTreeView extends StatefulWidget {
  final String mid;
  final double mojiPlannerWidth;
  final Dye dye;
  const DragAndDropTreeView(this.mid, this.mojiPlannerWidth, this.dye, {super.key});

  @override
  State<DragAndDropTreeView> createState() => DragAndDropTreeViewState();
}

class DragAndDropTreeViewState extends State<DragAndDropTreeView> {
  late final Node root;
  late final TreeController<Node> treeController;
  late final AutoScrollController autoScrollController;

  @override
  void initState() {
    autoScrollController = AutoScrollController(axis: Axis.vertical);
    super.initState();
    root = Node(id: widget.mid);
    final oMoji = untracked(() => S.mojiSignal(widget.mid).value);
    if (oMoji.id.isNotEmpty) {
      final oMojiCIDs = (oMoji.c.entries.toList()..sort((a, b) => a.value.compareTo(b.value))).map((entry) => entry.key).toList();
      final oMojiChildren = <Moji>[];
      for (final oMojiCID in oMojiCIDs) {
        final oMojiC = untracked(() => S.mojiSignal(oMojiCID).value);
        if (oMojiC.id.isNotEmpty) {
          oMojiChildren.add(oMojiC);
        }
      }
      for (final oMojiC in oMojiChildren) {
        final cMojiCIDS = (oMojiC.c.entries.toList()..sort((a, b) => a.value.compareTo(b.value))).map((entry) => entry.key).toList();
        final cMojiChildren = <Moji>[];
        for (final cMojiCID in cMojiCIDS) {
          final cMojiC = untracked(() => S.mojiSignal(cMojiCID).value);
          if (cMojiC.id.isNotEmpty) {
            cMojiChildren.add(cMojiC);
          }
        }
        final node = Node(id: oMojiC.id, children: cMojiChildren.map((cMojiC) => Node(id: cMojiC.id))).._parent = root;
        root._children.add(node);
      }
    }

    root._children.add(Node(id: kEmptySpace));

    treeController = TreeController<Node>(
      roots: root.children,
      childrenProvider: (Node node) => node.children,

      // The parentProvider is extremely important when automatically expanding
      // and collapsing tree nodes on hover, as the [TreeDragTarget] needs to
      // ensure that it doesn't collapse an ancestor of the dragging node as it
      // would be removed from the view stopping the drag updates and callbacks.
      //
      // When not provided, the [TreeController] would need to first locate the
      // target node in the tree and then check its ancestors, which could be
      // very expensive for deep trees.
      parentProvider: (Node node) => node.parent,
    );

    U.activeTreeControllers[widget.mid] = (root, treeController);
  }

  @override
  void dispose() {
    autoScrollController.dispose();
    treeController.dispose();
    U.activeTreeControllers.remove(widget.mid);
    super.dispose();
  }

  void onNodeAccepted(TreeDragAndDropDetails<Node> details) {
    final opid = details.draggedNode._parent?.id;
    final oIndex = details.draggedNode.index;
    Node? newParent;
    int newIndex = 0;

    details.mapDropPosition(
      whenAbove: () {
        // Insert the dragged node as the previous sibling of the target node.
        newParent = details.targetNode.parent;
        newIndex = details.targetNode.index;
      },
      whenInside: () {
        // Insert the dragged node as the last child of the target node.
        newParent = details.targetNode;
        newIndex = details.targetNode.children.length;

        // Ensure that the dragged node is visible after reordering.
        treeController.setExpansionState(details.targetNode, true);
      },
      whenBelow: () {
        // Insert the dragged node as the next sibling of the target node.
        newParent = details.targetNode.parent;
        newIndex = details.targetNode.index + 1;
      },
    );

    (newParent ?? root).insertChild(newIndex, details.draggedNode);

    final npid = newParent?.id;
    if (opid != null && npid != null) {
      R.changeParent(
        details.draggedNode.id,
        opid,
        npid,
        oIndex,
        newIndex,
      );
    }
    // Rebuild the tree to show the reordered node in its new vicinity.
    treeController.rebuild();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return TreeView<Node>(
      controller: autoScrollController,
      padding: EdgeInsets.zero,
      treeController: treeController,
      nodeBuilder: (BuildContext context, TreeEntry<Node> entry) {
        if (entry.node.id == kEmptySpace) {
          return const SizedBox(height: 200);
        }
        return AutoScrollTag(
          controller: autoScrollController,
          index: entry.node.index,
          key: ValueKey(entry.node.id),
          child: DragAndDropTreeTile(
            treeController: treeController,
            autoScrollController: autoScrollController,
            entry: entry,
            dye: widget.dye,
            borderSide: BorderSide(
              color: widget.dye.extraDark,
              width: 2.0,
            ),
            longPressDelay: kMojiLongPressTimeout,
            onNodeAccepted: onNodeAccepted,
            mojiPlannerWidth: widget.mojiPlannerWidth,
            onFolderPressed: () {
              // Check if the node is expanded before toggling it.
              final expanded = treeController.getExpansionState(entry.node);
              // If it isn't expanded
              if (expanded != true) {
                // Start a read transaction
                // For each child node
                for (final cNode in entry.node.children) {
                  // Clear any existing children as we will be overriding them
                  cNode._children.clear();
                  // Get the child moji from realm
                  final cMojiR = untracked(() => S.mojiSignal(cNode.id).value);
                  // If the child moji exists
                  if (cMojiR.id.isNotEmpty) {
                    // Get the grand children ids
                    final gcIDs = (cMojiR.c.entries.toList()..sort((a, b) => a.value.compareTo(b.value))).map((entry) => entry.key).toList();
                    // Get the grand children mojis from realm
                    final gcMojisR = <Moji>[];
                    for (final gcID in gcIDs) {
                      final gcMojiR = untracked(() => S.mojiSignal(gcID).value);
                      if (gcMojiR.id.isNotEmpty) {
                        gcMojisR.add(gcMojiR);
                      }
                    }
                    // For each grand child moji
                    for (final gcMojiR in gcMojisR) {
                      // Create a new grand child node and set its parent to the child node
                      final gcNode = Node(id: gcMojiR.id).._parent = cNode;
                      // Add the grand child node to the child node's children
                      cNode._children.add(gcNode);
                    }
                  }
                }
              }
              treeController.toggleExpansion(entry.node);
            },
          ),
        );
      },
    );
  }
}

class DragAndDropTreeTile extends StatelessWidget {
  const DragAndDropTreeTile({
    super.key,
    required this.entry,
    required this.onNodeAccepted,
    required this.mojiPlannerWidth,
    required this.autoScrollController,
    required this.dye,
    required this.treeController,
    this.borderSide = BorderSide.none,
    this.longPressDelay,
    this.onFolderPressed,
  });

  final TreeEntry<Node> entry;
  final TreeDragTargetNodeAccepted<Node> onNodeAccepted;
  final BorderSide borderSide;
  final Duration? longPressDelay;
  final VoidCallback? onFolderPressed;
  final double mojiPlannerWidth;
  final AutoScrollController autoScrollController;
  final TreeController<Node> treeController;
  final Dye dye;

  @override
  Widget build(BuildContext context) {
    return TreeDragTarget<Node>(
      node: entry.node,
      onNodeAccepted: onNodeAccepted,
      builder: (BuildContext context, TreeDragAndDropDetails<Node>? details) {
        Decoration? decoration;

        if (details != null) {
          // Add a border to indicate in which portion of the target's height
          // the dragging node will be inserted.
          decoration = BoxDecoration(
            borderRadius: details.mapDropPosition(
              whenAbove: () => BorderRadius.zero,
              whenInside: () => BorderRadius.circular(10),
              whenBelow: () => BorderRadius.zero,
            ),
            border: details.mapDropPosition(
              whenAbove: () => Border(top: borderSide),
              whenInside: () => Border.fromBorderSide(borderSide),
              whenBelow: () => Border(bottom: borderSide),
            ),
          );
        }
        return TreeDraggable<Node>(
          onDragStarted: () {
            FocusManager.instance.primaryFocus?.unfocus();
            final flyingMoji = untracked(() => S.mojiSignal(entry.node.id).value);
            S.flyingMoji.set(flyingMoji);
          },
          onDragEnd: (details) {
            S.flyingMoji.set(U.emptyMoji);
          },
          onDragCompleted: () {
            if (context.mounted) {
              treeController.rebuild();
            }
          },
          node: entry.node,
          longPressDelay: longPressDelay,
          childWhenDragging: IgnorePointer(
            child: Opacity(
              opacity: .5,
              child: TreeTile(
                dye: dye,
                entry: entry,
                autoScrollController: autoScrollController,
              ),
            ),
          ),
          feedback: const SizedBox.shrink(),
          child: TreeTile(
            dye: dye,
            autoScrollController: autoScrollController,
            entry: entry,
            onFolderPressed: entry.node.isLeaf ? null : onFolderPressed,
            decoration: decoration,
          ),
        );
      },
    );
  }
}

class TreeTile extends StatelessWidget {
  const TreeTile({
    super.key,
    required this.entry,
    required this.autoScrollController,
    this.onFolderPressed,
    this.decoration,
    this.showIndentation = true,
    required this.dye,
  });

  final TreeEntry<Node> entry;
  final VoidCallback? onFolderPressed;
  final Decoration? decoration;
  final bool showIndentation;
  final AutoScrollController autoScrollController;
  final Dye dye;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Row(
        children: [
          FolderButton(
            isOpen: entry.node.isLeaf ? null : entry.isExpanded,
            onPressed: onFolderPressed,
            openedIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              color: dye.ultraDark,
            ),
            closedIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: dye.ultraDark,
            ),
            icon: const SizedBox.shrink(),
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          Flexible(
            child: MojiCard(
              key: ValueKey(entry.node.id),
              id: entry.node.id,
              renderedByMojiIsland: false,
              shouldShowParentMojis: false,
              openMojiChild: true,
              placeholder: false,
              autoScrollController: autoScrollController,
              node: entry.node,
            ),
          ),
        ],
      ),
    );

    if (decoration != null) {
      content = Stack(
        children: [
          content,
          Positioned.fill(
            right: 8,
            left: 40,
            child: DecoratedBox(
              decoration: decoration!,
            ),
          )
        ],
      );
    }

    if (showIndentation) {
      return TreeIndentation(
        entry: entry,
        guide: const IndentGuide(indent: 20),
        child: content,
      );
    }

    return content;
  }
}
