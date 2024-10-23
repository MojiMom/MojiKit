import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:realm/realm.dart';
import 'package:undo/undo.dart';
import 'package:signals/signals.dart';
import 'package:mojikit/mojikit.dart';
import 'package:lexicographical_order/lexicographical_order.dart';

class R {
  static void Function(Set<String>) updateMojiOrigins = (_) {};
  static bool online = false;
  static late Realm m;
  static late Realm p;

  static updateMojiPlannerWidth(double? width) async {
    if (width != null) {
      final existingPreferences = untracked(() => S.preferencesSignal(kLocalPreferences).value);
      // If the preferences exists
      if (existingPreferences.id.isNotEmpty) {
        R.p.write(() {
          existingPreferences.mojiPlannerWidth = width;
        });
      }
    }
  }

  static updateDarkness(bool? darkness) async {
    if (darkness != null) {
      final existingPreferences = untracked(() => S.preferencesSignal(kLocalPreferences).value);
      // If the preferences exists
      if (existingPreferences.id.isNotEmpty) {
        R.p.write(() {
          existingPreferences.darkness = darkness;
        });
      }
    }
  }

  static String updateDockMojiChildrenAndGetLastParent(String mid, {bool includeSelf = false}) {
    // Get the moji from realm
    final moji = untracked(() => S.mojiSignal(mid).value);
    // If the moji doesn't exist
    if (moji.p == null) {
      // Return an empty string
      return kEmptyString;
    }
    // Get the dock tile and all the parent mojis
    final (_, parents) = R.getMojiDockTileAndParents(moji);
    // Get the dock moji
    final dMoji = parents.firstOrNull;
    // Get all the parents that are moji tiles
    final mojiTileParents = parents.where((p) => p.m != null && p.id.length != 1);

    // If it exists
    if (dMoji != null) {
      // Allocate all quick access moji tiles
      final quickAccessMojis = [...mojiTileParents.map((p) => p.id), if (includeSelf) mid].take(1);
      // Start a write transaction
      R.m.write(() {
        // Re-assign the quick access mojis tiles to the dock moji
        dMoji.q.clear();
        dMoji.q[quickAccessMojis.first] = generateOrderKeys(1).first;
      });
      // Update the dock moji
      R.updateMojis([dMoji]);
      // Get the last parent moji
      final parentMID = quickAccessMojis.lastOrNull;
      // If it exists
      if (parentMID != null) {
        // Return the last parent moji id
        return parentMID;
      }
    }
    // If it should include itself, return the mid, otherwise return an empty string
    return includeSelf ? mid : kEmptyString;
  }

  static void changeParent(String mid, String opid, String npid, int oIndex, int nIndex) {
    // Get the moji from realm
    final mojiR = untracked(() => S.mojiSignal(mid).value);
    // Get the old parent moji from realm
    final oParentR = untracked(() => S.mojiSignal(opid).value);
    // Get the new parent moji
    final nParentR = untracked(() => S.mojiSignal(npid).value);

    // Create a list of mojis to update
    final Set<String> mojisToUpdate = {};
    // Create a list of mojis before changes
    final List<Moji> mojiLBC = [];
    // If the moji exists
    if (mojiR.id.isNotEmpty) {
      // Start a write transaction
      R.m.write(() {
        // If the new parent id is different from the current moji parent
        if (mojiR.p != npid) {
          // Add a copy of the moji to the list of mojis before changes
          mojiLBC.add(mojiR.copyWith());
          // Update the parent id of the moji
          mojiR.p = npid;
          // Reset the write time of the moji
          mojiR.w = U.zeroDateTime;
          // Remember to update the moji
          mojisToUpdate.add(mojiR.id);
        }
        // If the old parent moji exists
        if (oParentR.id.isNotEmpty && opid != npid) {
          // Add a copy of the old parent moji to the list of mojis before changes
          mojiLBC.add(oParentR.copyWith());
          // Remove the moji from the old parent moji's children
          oParentR.c.remove(mid);
          // Remove the moji from the old parent moji's heap
          oParentR.h.remove(mid);
          // Remove the moji from the old parent moji's log
          oParentR.l.remove(mid);
          // Reset the write time of the moji
          oParentR.w = U.zeroDateTime;
          // Update the old parent moji
          mojisToUpdate.add(oParentR.id);
        }

        // If the new parent moji exists
        if (nParentR.id.isNotEmpty) {
          // Add a copy of the new parent moji to the list of mojis before changes
          mojiLBC.add(nParentR.copyWith());
          // If the new parent already contains the moji
          if (nParentR.c.containsKey(mid)) {
            // Remove the moji from the new parent moji's children in order to calculate the lid correctly
            nParentR.c.remove(mid);
          }
          // Sort the children
          final sortedChildrenLIDs = nParentR.c.values.toList()..sort();
          // Create placeholders for the next lid and the previous lid
          String? nextLID, prevLID;
          String lid;
          if (sortedChildrenLIDs.isEmpty) {
            lid = generateOrderKeys(1).first;
          } else if (nIndex == 0) {
            lid = between(next: sortedChildrenLIDs.first);
          } else if (nIndex >= sortedChildrenLIDs.length) {
            lid = between(prev: sortedChildrenLIDs.last);
          } else {
            // Get the next lid
            nextLID = sortedChildrenLIDs[nIndex.isNegative ? 0 : nIndex];
            if (nIndex - 1 >= 0) {
              // Get the previous lid
              prevLID = sortedChildrenLIDs[nIndex - 1];
              // Derive the lid
              lid = between(next: nextLID, prev: prevLID);
            } else {
              // Derive the lid
              lid = between(next: nextLID);
            }
          }

          // Insert the moji at the specified index in the new parent moji's children
          nParentR.c[mid] = lid;
          // Reset the write time of the moji
          nParentR.w = U.zeroDateTime;
          // Update the new parent moji
          mojisToUpdate.add(nParentR.id);
        }
      });
    }
    // If there are mojis to update
    if (mojisToUpdate.isNotEmpty) {
      U.mojiChanges.add(
        Change<List<Moji>>(
          mojiLBC,
          () {},
          (mojiLBC) {
            // Restore the mojis to their previous state
            R.updateMojis(mojiLBC);

            // Get the nodes within the active tree controller
            final nodesToRestore = U.activeTreeController?.$2?.search((node) {
              // Return true if the node id is equal to the mid, opid or npid
              return node.id == mid || node.id == opid || node.id == npid;
            });

            // Use a placeholder for the old parent node, new parent node and the moji node
            Node? oParentN, nParentN, mojiN;
            // If the nodes to restore exist
            if (nodesToRestore != null) {
              // For each node in the nodes to restore
              for (final node in nodesToRestore.matches.keys) {
                // If the node id is equal to the mid
                if (node.id == mid) {
                  // Assign the moji node
                  mojiN = node;
                  // If the node id is equal to the opid
                } else if (node.id == opid) {
                  // Assign the old parent node
                  oParentN = node;
                  // If the node id is equal to the npid
                } else if (node.id == npid) {
                  // Assign the new parent node
                  nParentN = node;
                }
              }
            }

            // If the old parent node doesn't exist use the root node
            oParentN ??= U.activeTreeController?.$1;

            // If the moji node exists
            if (mojiN != null) {
              // Remove the moji node from the old parent node
              nParentN?.removeChild(mojiN);
              // Insert the moji node at theold index in the old parent node
              oParentN?.insertChild(oIndex, mojiN);
            }

            // Rebuild the active tree controller
            U.activeTreeController?.$2?.rebuild();

            // Sync the unwritten mojis
            syncLocalUnwrittenMojis(mojiIDs: mojiLBC.map((e) => e.id).toSet());
          },
        ),
      );
      syncLocalUnwrittenMojis(mojiIDs: mojisToUpdate);
    }
  }

  static void openMojiToggle(String mid) {
    // Create a list of mojis to update
    final Set<String> mojisToUpdate = {};
    // Get the moji from realm
    final mojiR = untracked(() => S.mojiSignal(mid).value);

    // If the moji exists
    if (mojiR.id.isNotEmpty) {
      // Start a write transaction
      R.m.write(() {
        // Get the open status of the moji
        final open = mojiR.o;
        // If the moji is open
        if (open == true) {
          // Close the moji
          mojiR.o = false;
          // Reset the write time of the moji
          mojiR.w = U.zeroDateTime;
          // Remember to update the moji
          mojisToUpdate.add(mojiR.id);
          // If the moji is closed
        } else {
          // Open the moji
          if (mojiR.h.isNotEmpty || mojiR.c.isNotEmpty) {
            mojiR.o = true;
            // Reset the write time of the moji
            mojiR.w = U.zeroDateTime;
            // Remember to update the moji
            mojisToUpdate.add(mojiR.id);
          }
        }
      });
    }

    syncLocalUnwrittenMojis(mojiIDs: mojisToUpdate);
  }

  static (MojiDockTile, List<Moji>) getMojiDockTileAndParents(Moji moji) {
    // Create a list to hold all parent mojis
    final pMojis = <Moji>[];
    // Get the parent id
    String? pid = moji.p;
    // Get the initial dock tile related to the moji
    MojiDockTile dockTile = (pid == null || pid.isEmpty) ? MojiDockTile.fromString(moji.id) : MojiDockTile.c;
    // As long as there is a parent id
    while (pid != null && pid.isNotEmpty) {
      // Get the parent moji from realm
      final pMojiR = untracked(() => S.mojiSignal('$pid').value);
      // Re-assign the parent id
      pid = pMojiR.p;
      // If the parent is now null
      if (pid == null || pid.isEmpty) {
        // The dock tile of the current parent is the one that will provide the dye
        dockTile = MojiDockTile.fromString(pMojiR.d);
      }
      // If the parent moji exists
      if (pMojiR.id.isNotEmpty) {
        // Add the parent moji to the list of parent mojis
        pMojis.insert(0, pMojiR);
      }
    }
    // Return the dock tile and the list of parent mojis
    return (dockTile, pMojis);
  }

  static List<Moji> getDockMojiTiles() {
    final mojiDockTiles = <Moji>[];
    final mojiDockTileIds = MojiDockTile.values.map((m) => m.name).toList();
    for (final mojiDockTileId in mojiDockTileIds) {
      final mojiDockTile = untracked(() => S.mojiSignal(mojiDockTileId).value);
      if (mojiDockTile.id.isNotEmpty) {
        mojiDockTiles.add(mojiDockTile);
      }
    }
    return mojiDockTiles;
  }

  static void addMojiToPlannerIfNeeded(Moji pMoji, Moji cMoji, {DateTime? cStartTime, DateTime? cEndTime}) {
    // Create a list of mojis to update
    final Set<String> mojisToUpdate = {};
    // Create a list of mojis before changes
    final List<Moji> mojiLBC = [];
    final sTime = cStartTime?.toUtc() ?? cMoji.s?.toUtc();
    final eTime = cEndTime?.toUtc() ?? cMoji.e?.toUtc();
    // Get the original child moji from realm as the provided child moji has modifications already
    final cMojiR = untracked(() => S.mojiSignal(cMoji.id).value);
    // If it exists
    if (cMojiR.id.isNotEmpty) {
      // Add a copy of the child moji to the list of the mojis before changes
      mojiLBC.add(cMojiR.copyWith());
    }
    if (sTime != null) {
      // Derive the day id
      final did = U.did(sTime);
      // Get the moji planner from realm
      final mojiPlannerR = untracked(() => S.mojiSignal(did).value);
      // Create a copy of the parent moji before changes
      final pMojiBC = pMoji.copyWith();
      // Start a write transaction
      R.m.write(() {
        // Update the parent
        cMojiR.p = pMoji.id;
        // Update the start time
        cMojiR.s = sTime.toUtc();
        // Update the end time
        cMojiR.e = eTime?.toUtc();
        // Update the Text
        cMojiR.t = cMoji.t;
        // Reset the write time of the moji
        cMojiR.w = U.zeroDateTime;
        // Remember to update the child moji
        mojisToUpdate.add(cMojiR.id);
        // If the parent moji log doesn't already contain the child id
        if (pMoji.l.containsKey(cMojiR.id) != true) {
          // Add the child id to the children map of the parent with the calculated order key
          pMoji.l[cMojiR.id] = sTime.toUtc();
          // Reset the write time of the moji
          pMoji.w = U.zeroDateTime;
        }
        // If the parent children contain the child id
        if (pMoji.c.containsKey(cMojiR.id)) {
          // Remove the child id from the children list of the parent
          pMoji.c.remove(cMojiR.id);
          // Reset the write time of the moji
          pMoji.w = U.zeroDateTime;
        }

        // If the parent moji write time is zeroed out
        if (pMoji.w == U.zeroDateTime) {
          // Add a copy of the parent moji to the list of the mojis before changes
          mojiLBC.add(pMojiBC);
          // Remember to update the parent moji
          mojisToUpdate.add(pMoji.id);
        }

        // If the moji planner exists
        if (mojiPlannerR.id.isNotEmpty) {
          // Add a copy of the moji planner to the list of the mojis before changes
          mojiLBC.add(mojiPlannerR.copyWith());
          // If the moji planner log doesn't already contain the child id
          if (mojiPlannerR.l.containsKey(cMojiR.id) != true) {
            // Add the child moji id with the generated lexicographical id
            mojiPlannerR.l[cMojiR.id] = sTime.toUtc();
            // Reset the write time of the moji
            mojiPlannerR.w = U.zeroDateTime;
            // Remember to update the moji planner
            mojisToUpdate.add(mojiPlannerR.id);
          }
          // If the moji planner doesn't exist
        }
      });
    }
    if (mojisToUpdate.isNotEmpty) {
      U.mojiChanges.add(
        Change<List<Moji>>(
          mojiLBC,
          () {},
          (mojiLBC) {
            // Restore the mojis to their previous state
            R.updateMojis(mojiLBC);
            // Sync the unwritten mojis
            syncLocalUnwrittenMojis(mojiIDs: mojiLBC.map((e) => e.id).toSet());
            final day = sTime;
            if (day != null) {
              // Derive the day id
              final did = U.did(day);
              // Get the moji planner notifier for the day id
              final mojiPlannerNotifier = U.mojiPlannersNotifiers[did];
              // If the moji planner notifier exists
              if (mojiPlannerNotifier != null) {
                // Get the planner width
                final plannerWidth = R.p.find<Preferences>(kLocalPreferences)?.mojiPlannerWidth ?? kDefaultMojiPlannerWidth;
                // Get the flexible moji events for the day
                final flexibleMojiEvents = U.getFlexibleMojiEventsForDay(day, plannerWidth);
                // Update the value of the moji planner notifier
                mojiPlannerNotifier.value = (flexibleMojiEvents, DateTime.now().millisecondsSinceEpoch);
              }
            }
          },
        ),
      );
      updateMojiOrigins({cMojiR.id});
      // Sync the unwritten mojis
      syncLocalUnwrittenMojis(mojiIDs: mojisToUpdate);
    }
  }

  static void addChildMoji({required String pid, required String cfid, int? mcp, String? text}) {
    // Get the parent moji from realm
    final pMojiR = untracked(() => S.mojiSignal(pid).value);
    // Create the child moji
    final cMoji = untracked(() => S.mojiSignal(cfid).value);
    // Start a write transaction
    R.m.write(() {
      // If the parent moji exists
      if (pMojiR.id.isNotEmpty) {
        // If the child moji is a tile
        if (mcp != null) {
          // If the parent moji doesn't already contain the child id
          if (pMojiR.h.containsKey(cfid) != true) {
            // Generate an lexicographical id poisitioned at the beginning of the children of the parent
            final lid = pMojiR.h.isEmpty ? generateOrderKeys(1).first : between(next: (pMojiR.h.values.toList()..sort()).first);
            // Add it to the heap of the parent moji
            pMojiR.h[cfid] = lid;
            // Remove it from the children list of the parent moji
            pMojiR.c.remove(cfid);
            // Ensure that the parent is open
            pMojiR.o = true;
          }
        } else {
          // If the parent moji doesn't already contain the child id
          if (pMojiR.c.containsKey(cfid) != true) {
            // Generate an lexicographical id poisitioned at the beginning of the children of the parent
            final lid = pMojiR.c.isEmpty ? generateOrderKeys(1).first : between(next: (pMojiR.c.values.toList()..sort()).first);
            // Add the child moji to the top of the parent moji's children
            pMojiR.c[cfid] = lid;
            // Remove the child moji from the heap of the parent moji
            pMojiR.h.remove(cfid);
          }
        }

        // Clear the write time of parent moji
        pMojiR.w = U.zeroDateTime;
        // Update the child parent
        cMoji.p = pMojiR.id;
        // Update the child moji code point
        cMoji.m = mcp;
        // Update the child moji text
        cMoji.t = text;
        // Clear the write time of child moji
        cMoji.w = U.zeroDateTime;
        // Update the parent moji and the child moji in realm
        syncLocalUnwrittenMojis(mojiIDs: {pMojiR.id, cMoji.id});
      }
    });
  }

  static void addSiblingMoji(Moji moji, {required String sfid}) {
    final pid = moji.p;
    if (pid != null) {
      // Get the parent moji from realm
      final pMojiR = untracked(() => S.mojiSignal(pid).value);
      // If the parent moji exists
      if (pMojiR.id.isNotEmpty) {
        final sortedChildrenList = (pMojiR.c.entries.toList()..sort((a, b) => a.value.compareTo(b.value))).map((entry) => entry.key).toList();
        // Get the position of moji
        final position = sortedChildrenList.indexOf(moji.id);
        // If the position is not -1
        if (position != -1) {
          // Create the child moji
          final cMojiR = untracked(() => S.mojiSignal(sfid).value);
          // Get the current lid
          final currentLID = pMojiR.c[moji.id];
          // Create a placeholder for the next lid
          String? nextLID;
          // If there is a next moji
          if (sortedChildrenList.length > position + 1) {
            // Get the next moji id
            final nextMID = sortedChildrenList[position + 1];
            // Get the next lid
            nextLID = pMojiR.c[nextMID];
          }
          // Derive the lid
          final lid = between(next: nextLID, prev: currentLID);
          // Start a write transaction
          R.m.write(() {
            cMojiR.p = pMojiR.id;
            // Insert the child moji after the parent moji
            pMojiR.c[sfid] = lid;
            // Clear the write time of parent moji
            pMojiR.w = U.zeroDateTime;
            // Clear the write time of child moji
            cMojiR.w = U.zeroDateTime;
          });
          // Update the parent moji and the child moji in realm
          syncLocalUnwrittenMojis(mojiIDs: {pMojiR.id, cMojiR.id});
        }
      }
    }
  }

  static void updateMoji(String mid, {String? text, int? mcp, String? npid, bool shouldUpdateOrigin = false}) {
    // Create a list of mojis to update
    final Set<String> mojisToUpdate = {};
    // Create a list of mojis before changes
    final List<Moji> mojiLBC = [];
    // Get the moji from realm
    final mojiR = untracked(() => S.mojiSignal(mid).value);

    // If the parent id is not null
    if (npid != null) {
      // Get the new parent moji from realm
      final npMojiR = untracked(() => S.mojiSignal(npid).value);
      // Get the old parent id
      final opid = mojiR.p;
      // If the old parent id is not null and the moji is not a calendar
      if (opid != null && mojiR.x[kGoogleCalendarTokenKey] == null) {
        // Get the old parent moji from realm
        final opMojiR = untracked(() => S.mojiSignal(opid).value);
        // If the old parent moji exists
        if (opMojiR.id.isNotEmpty) {
          // Start a write transaction
          R.m.write(() {
            // Add a copy of the old parent moji to the list of original mojis
            mojiLBC.add(opMojiR.copyWith());
            // If the old parent heap contains the child id
            if (opMojiR.h.containsKey(mid)) {
              // Remove the child id from the heap of the old parent moji
              opMojiR.h.remove(mid);
              // Reset the write time of the moji
              opMojiR.w = U.zeroDateTime;
              // Remember to update the old parent moji
              mojisToUpdate.add(opMojiR.id);
            }
            // If the old parent moji contains the child id
            if (opMojiR.c.containsKey(mid)) {
              // Remove the child id from the children list of the old parent moji
              opMojiR.c.remove(mid);
              // Reset the write time of the moji
              opMojiR.w = U.zeroDateTime;
              // Remember to update the old parent moji
              mojisToUpdate.add(opMojiR.id);
            }
          });
        }
      }

      // If the new parent moji exists
      if (npMojiR.id.isNotEmpty) {
        // Add a copy of the new parent moji to the list of the mojis before changes
        mojiLBC.add(npMojiR.copyWith());
        // Start a write transaction
        R.m.write(() {
          // If the moji is a tile
          if (mojiR.m != null) {
            // If the new parent moji doesn't already contain the child id
            if (npMojiR.h.containsKey(mid) != true) {
              // Generate an lexicographical id poisitioned at the beginning of the children of the parent
              final lid = npMojiR.h.isEmpty ? generateOrderKeys(1).first : between(next: (npMojiR.h.values.toList()..sort()).first);
              // Insert the child id at the beginning of the heap of the new parent moji
              npMojiR.h[mid] = lid;
              // Delete the child id from the children list of the parent moji
              npMojiR.c.remove(mid);
              // Reset the write time of the moji
              npMojiR.w = U.zeroDateTime;
              // Remember to update the parent moji
              mojisToUpdate.add(npMojiR.id);
            }
          } else {
            // If the new parent moji doesn't already contain the child id
            if (npMojiR.c.containsKey(mid) != true) {
              // Generate an lexicographical id poisitioned at the beginning
              final lid = npMojiR.c.isEmpty ? generateOrderKeys(1).first : between(next: (npMojiR.c.values.toList()..sort()).first);
              // Insert the child id at the beginning of the children list of the parent moji
              npMojiR.c[mid] = lid;
              // Delete the child id from the heap of the parent moji
              npMojiR.h.remove(mid);
              // Reset the write time of the moji
              npMojiR.w = U.zeroDateTime;
              // Remember to update the parent moji
              mojisToUpdate.add(npMojiR.id);
            }
          }
        });
      }
    }

    // Add a copy of the moji to the list of original mojis
    mojiLBC.add(mojiR.copyWith());
    // Start a write transaction
    R.m.write(() {
      // If the text is not null
      if (text != null) {
        // Update the text of the moji
        mojiR.t = text;
      }

      // If the moji code point is not null
      if (mcp != null) {
        // Update the moji code point
        mojiR.m = mcp;
      }

      // If the parent id is not null
      if (npid != null) {
        // Update the parent id
        mojiR.p = npid;
      }
      // Reset the write time of the moji
      mojiR.w = U.zeroDateTime;
    });

    // If the parent has changed
    if (npid != null) {
      // Refresh the moji bar with it's own value to force a refresh
      S.implicitPID.set(S.implicitPID.value, force: true);
    }

    if (mojisToUpdate.isNotEmpty) {
      U.mojiChanges.add(
        Change<List<Moji>>(
          mojiLBC,
          () {},
          (originalMojis) {
            R.updateMojis(mojiLBC);
            syncLocalUnwrittenMojis(mojiIDs: mojiLBC.map((e) => e.id).toSet());
          },
        ),
      );

      if (shouldUpdateOrigin) {
        updateMojiOrigins(mojisToUpdate);
      }
      // Sync the unwritten mojis
      syncLocalUnwrittenMojis(mojiIDs: mojisToUpdate);
    }
  }

  static void clearQuickAccessMojis(String mid) {
    final mojiR = untracked(() => S.mojiSignal(mid).value);
    // If the moji exists
    if (mojiR.id.isNotEmpty) {
      // Start a write transaction
      R.m.write(() {
        mojiR.q.clear();
      });
    }
  }

  static void updateMojis(List<Moji> mojis) async {
    // Start a write transaction
    R.m.write(() {
      R.m.addAll<Moji>(mojis, update: true);
    });
    updateMojiOrigins(mojis.map((m) => m.id).toSet());
  }

  static Moji getMoji(String mid) {
    return untracked(() => S.mojiSignal(mid).value);
  }

  static void finishMoji(String mid) {
    // Create a list of mojis before changes
    final List<Moji> mojiLBC = [];
    // Get the moji from realm
    final moji = untracked(() => S.mojiSignal(mid).value);
    // If the moji exists
    if (moji.id.isNotEmpty) {
      // Add a copy of the moji to the list of mojis before changes
      mojiLBC.add(moji.copyWith());
      // Start a write transaction
      R.m.write(() {
        // Get the finished time of the moji
        final fTime = moji.f;
        // If the finished time is not null and not zero
        if (fTime != null && fTime.millisecondsSinceEpoch != 0) {
          // Set the finished time to zero to indicate that the moji is not finished
          moji.f = U.zeroDateTime;
          // Otherwise
        } else {
          // Set the finished time to the current time to indicate that the moji is finished
          moji.f = DateTime.now();
        }
        // Reset the write time of the moji
        moji.w = U.zeroDateTime;
      });
      U.mojiChanges.add(
        Change<List<Moji>>(
          mojiLBC,
          () {},
          (mojiLBC) {
            // Restore the mojis to their previous state
            R.updateMojis(mojiLBC);
            // Sync the unwritten mojis
            syncLocalUnwrittenMojis(mojiIDs: mojiLBC.map((e) => e.id).toSet());
          },
        ),
      );
      syncLocalUnwrittenMojis(mojiIDs: {moji.id});
    }
  }

  static List<Moji> getAllMojis(Set<String>? mids) {
    // Get all the mojis from realm
    final mojisR = <Moji>[];
    for (final mid in mids ?? {}) {
      final moji = untracked(() => S.mojiSignal(mid).value);
      if (moji.id.isNotEmpty) {
        mojisR.add(moji);
      }
    }
    return mojisR;
  }

  static void clear() {
    // Start a write transaction
    R.m.write(() {
      // Delete all mojis from realm
      R.m.deleteAll<Moji>();
    });
    // Start a write transaction
    R.p.write(() {
      // Delete all preferences from realm
      R.p.deleteAll<Preferences>();
    });
  }

  static void deleteMojiFromPlanner(String mid) {
    // Get the moji from realm
    final mojiR = untracked(() => S.mojiSignal(mid).value);
    // Create a list of mojis to update
    final Set<String> mojisToUpdate = {};
    // If the moji exists
    if (mojiR.id.isNotEmpty) {
      // Get the start time of the moji
      final sTime = mojiR.s?.toUtc();
      // If the start time exists
      if (sTime != null) {
        // Derive the day id
        final did = U.did(sTime);
        // Get the moji planner from realm
        final mojiPlannerR = untracked(() => S.mojiSignal(did).value);
        // If the moji planner exists
        if (mojiPlannerR.id.isNotEmpty) {
          // If the moji planner contains the moji
          if (mojiPlannerR.l.containsKey(mojiR.id) || mojiPlannerR.h.containsKey(mojiR.id)) {
            // Start a write transaction
            R.m.write(() {
              // Remove the moji from the moji planner's children
              mojiPlannerR.c.remove(mojiR.id);
              // Remove the moji from the moji planner's heap
              mojiPlannerR.h.remove(mojiR.id);
              // Remove the moji from the moji planner's log
              mojiPlannerR.l.remove(mojiR.id);
              // Reset the write time of the moji
              mojiPlannerR.w = U.zeroDateTime;
              // Remember to update the moji planner
              mojisToUpdate.add(mojiPlannerR.id);
            });
          }
        }
      }
      // If there are mojis to update
      if (mojisToUpdate.isNotEmpty) {
        syncLocalUnwrittenMojis(mojiIDs: mojisToUpdate);
      }
    }
  }

  static void changeMojiDay(DateTime cDate, Moji moji) {
    // Delete the moji from the planner
    R.deleteMojiFromPlanner(moji.id);
    // Create a new start time based on the date
    DateTime sTime = DateTime(cDate.year, cDate.month, cDate.day, 0, 0).toUtc();
    // Create a new end time based on the start time and the default moji event duration
    DateTime eTime = sTime.add(kDefaultMojiEventDuration).toUtc();
    // Get an instance of the existing start time
    final sTimeI = moji.s?.toUtc();
    // Get an instance of the existing end time
    final eTimeI = moji.e?.toUtc();
    // If the existing start time and end time are not null
    if (sTimeI != null && eTimeI != null) {
      // Derive the new start time based on the chosen date and the existing start time
      sTime = DateTime(cDate.year, cDate.month, cDate.day, sTimeI.hour, sTimeI.minute).toUtc();
      // Derive the new end time based on the chosen date and the existing end time
      eTime = DateTime(cDate.year, cDate.month, cDate.day, eTimeI.hour, eTimeI.minute).toUtc();
    }
    // Start a write transaction
    R.m.write(() {
      // Set the new start time
      moji.s = sTime.toUtc();
      // Set the new end time
      moji.e = eTime.toUtc();
      // Clear out the write time for the moji
      moji.w = U.zeroDateTime;
    });
    // Get the current parent id
    final pid = moji.p;
    // If it exists
    if (pid != null) {
      // Get the parent moji instance
      final pMoji = R.getMoji(pid);
      // If it exists
      if (pMoji.id.isNotEmpty) {
        // Add the moji to the planner
        R.addMojiToPlannerIfNeeded(pMoji, moji);
      }
    }
  }

  static void deleteMoji(String mid) {
    // Create a list of mojis to update
    final Set<String> mojisToUpdate = {};
    // Create a list of mojis before changes
    final List<Moji> mojiLBC = [];
    // Get the moji that needs to be deleted from realm
    final mojiR = untracked(() => S.mojiSignal(mid).value);
    // If it exists
    if (mojiR.id.isNotEmpty) {
      // Add a copy of the moji to the list of mojis before changes
      mojiLBC.add(mojiR.copyWith());
      // Get the parent moji id
      final pid = mojiR.p;
      // If it has a parent
      if (pid != null) {
        // Get the parent moji from realm
        final pMojiR = untracked(() => S.mojiSignal(pid).value);
        // If the parent moji exists
        if (pMojiR.id.isNotEmpty) {
          // Add a copy of the parent moji to the list of mojis before changes
          mojiLBC.add(pMojiR.copyWith());
          // Start a write transaction
          R.m.write(() {
            // Remove the moji from the parent moji's children
            pMojiR.c.remove(mojiR.id);
            // Remove the moji from the parent moji's heap
            pMojiR.h.remove(mojiR.id);
            // Remove the moji from the parent moji's log
            pMojiR.l.remove(mojiR.id);
            // Remove the moji from the parent moji's quick access
            pMojiR.q.remove(mojiR.id);
            // If it's not already added to the junk map
            if (pMojiR.j.containsKey(mojiR.id) != true) {
              // Add it to the top of the junk map
              pMojiR.j[mojiR.id] = DateTime.now().toUtc();
            }
            // Reset the write time of the moji
            pMojiR.w = U.zeroDateTime;
            // Add the parent moji to the list of mojis to update
          });

          mojisToUpdate.add(pMojiR.id);
        }
      }
      // Get the start time of the moji
      final sTime = mojiR.s?.toUtc();
      // If the moji has a start time
      if (sTime != null) {
        // Derive the day id
        final did = U.did(sTime);
        // Get the moji planner from realm
        final mojiPlannerR = untracked(() => S.mojiSignal(did).value);
        // If the moji planner exists
        if (mojiPlannerR.id.isNotEmpty) {
          // Add a copy of the moji planner to the list of mojis before changes
          mojiLBC.add(mojiPlannerR.copyWith());
          // Start a write transaction
          R.m.write(() {
            // Remove the moji from the moji planner moji's children
            mojiPlannerR.c.remove(mojiR.id);
            // Remove the moji from the moji planner moji's heap
            mojiPlannerR.h.remove(mojiR.id);
            // Remove the moji from the moji planner moji's log
            mojiPlannerR.l.remove(mojiR.id);
            // If it's not already added to the junk list
            if (mojiPlannerR.j.containsKey(mojiR.id) != true) {
              // Add it to the top of the junk list
              mojiPlannerR.j[mojiR.id] = DateTime.now().toUtc();
            }
            // Reset the write time of the moji
            mojiPlannerR.w = U.zeroDateTime;
            // Add the moji planner moji to the list of mojis to update
          });
          mojisToUpdate.add(mojiPlannerR.id);
        }
      }
    }
    // If there are mojis to update
    if (mojisToUpdate.isNotEmpty) {
      U.mojiChanges.add(
        Change<List<Moji>>(
          mojiLBC,
          () {},
          (mojiLBC) {
            R.updateMojis(mojiLBC);
            // For each moji before changes
            for (final moji in mojiLBC) {
              // Get the start time of the moji
              final sTime = moji.s?.toUtc();
              // If the moji has a start time
              if (sTime != null) {
                // Derive the day id
                final did = U.did(sTime);
                // Get the existing moji planner notifier
                final existingMojiPlannerNotifier = U.mojiPlannersNotifiers[did];
                // If it exists
                if (existingMojiPlannerNotifier != null) {
                  // Get the planner width
                  final plannerWidth = R.p.find<Preferences>(kLocalPreferences)?.mojiPlannerWidth ?? kDefaultMojiPlannerWidth;
                  // Calculate the flexible moji events for the day
                  final flexibleMojiEvents = U.getFlexibleMojiEventsForDay(sTime, plannerWidth);
                  // Update the value of the moji planner notifier
                  existingMojiPlannerNotifier.value = (flexibleMojiEvents, DateTime.now().millisecondsSinceEpoch);
                }
              }
            }
            syncLocalUnwrittenMojis(mojiIDs: mojiLBC.map((e) => e.id).toSet());
          },
        ),
      );
      syncLocalUnwrittenMojis(mojiIDs: mojisToUpdate);
    }

    // Refresh the moji bar with it's own value to force a refresh
    S.implicitPID.set(S.implicitPID.value, force: true);
  }

  static void addMojiCalendar(String email, String refreshToken) {
    email = base64Encode(utf8.encode(email));
    // Get the moji calendar corresponding to the email from realm
    final mojiCalendarR = untracked(() => S.mojiSignal(email).value);
    // Get the moji calendars
    final mojiCalendarsR = untracked(() => S.mojiSignal(kMojiCalendars).value);
    final Set<String> mojisToUpdate = {};
    // If the moji calendar exists
    if (mojiCalendarR.id.isNotEmpty) {
      // Start a write transaction
      R.m.write(() {
        // Update the calendar parent
        mojiCalendarR.p = kMojiCalendars;
        // Update the google refresh token
        mojiCalendarR.x[kGoogleCalendarTokenKey] = refreshToken;
        // Reset the write time of the moji
        mojiCalendarR.w = U.zeroDateTime;
        // Remember to update the moji calendar
        mojisToUpdate.add(mojiCalendarR.id);
        // If the moji calendars exists
        if (mojiCalendarsR.id.isNotEmpty) {
          // If the moji calendars doesn't already contain the new moji calendar
          if (mojiCalendarsR.c.containsKey(mojiCalendarR.id) != true) {
            // Generate an lexicographical id poisitioned at the beginning
            final lid =
                mojiCalendarsR.c.isEmpty ? generateOrderKeys(1).first : between(next: (mojiCalendarsR.c.values.toList()..sort()).first);
            // Insert the new moji calendar at the beginning of the children list of the moji calendars
            mojiCalendarsR.c[mojiCalendarR.id] = lid;
            // Reset the write time of the moji
            mojiCalendarsR.w = U.zeroDateTime;
            // Remember to update the moji calendars
            mojisToUpdate.add(mojiCalendarsR.id);
          }
        }
      });
    }
    syncLocalUnwrittenMojis(mojiIDs: mojisToUpdate);
  }

  static Firestore? getFirestore(String? projectId, String? serviceAccountData) {
    // If the api key is null or the project id is null
    if (serviceAccountData == null || projectId == null) {
      // Return null for all the values
      return Platform.environment.containsKey('FLUTTER_TEST') ? U.createFirestoreEmulator() : null;
    }
    // Initialize the firestore instance with the project id
    final serviceAccountFile = InMemoryFile(utf8.fuse(base64).decode(serviceAccountData));
    // Initialize the service account auth
    final serviceAccountAuth = FirebaseAdminApp.initializeApp(projectId, Credential.fromServiceAccount(serviceAccountFile));
    // Initialize the firestore
    final firestore = Firestore(serviceAccountAuth);
    // Return the firestore
    return firestore;
  }

  static Future<bool> syncServerWrittenMojis() async {
    // If we are not online
    if (R.online != true) {
      // Don't do anything
      return Future.value(false);
    }

    // Get the directory of the realm database
    final mojiPath = m.config.path;
    final preferencesPath = p.config.path;

    Future<Set<DateTime>> mojiGetter(String? author) async {
      // Initialize realm
      R.m = Realm(Configuration.local([Moji.schema], path: mojiPath));
      // Initialize the preferences schema
      R.p = Realm(Configuration.local([Preferences.schema], path: preferencesPath));
      // Get the preferences
      final preferences = untracked(() => S.preferencesSignal(kLocalPreferences).value);
      // Get the last successful sync time
      final lastSuccessfullSyncSinceEpoch = preferences.lastSuccessfulSyncTime ?? U.zeroDateTime;
      // Get the current author instance
      final authorInstance = lastSuccessfullSyncSinceEpoch.year == U.zeroDateTime.year ? null : author;
      // Get the authenticated firebase user and firestore
      final firestore = getFirestore(preferences.projectId, preferences.serviceAccountData);
      // If the limit or firestore is null
      if (firestore == null) {
        // Return an empty set
        return <DateTime>{};
      }
      // Get the mojis from firestore that have been written since the last successful sync time
      final latestMojiSnapshot = await firestore
          .collection('m')
          .where('w', WhereFilter.greaterThan, lastSuccessfullSyncSinceEpoch.millisecondsSinceEpoch)
          .where('a', WhereFilter.notEqual, authorInstance)
          .orderBy('w')
          .orderBy('a')
          .get();

      debugPrint('got ${latestMojiSnapshot.docs.length} latest mojis');

      // Start with a zero date time
      DateTime latestTimeFromFetchedMojis = U.zeroDateTime;
      // Create a list to hold the mojis to update
      final List<Moji> mojisToUpdate = [];
      // Create a list to hold the moji planners to refresh
      final mojiPlannersToRefreshSet = <DateTime>{};
      // For each moji doc in the latest moji docs list
      for (final mojiDoc in latestMojiSnapshot.docs) {
        // Create a moji from the document
        final moji = mojiFromJson(mojiDoc.id, mojiDoc.data());
        // Get the moji write time
        final mojiWriteTime = moji.w;
        // If it's not null
        if (mojiWriteTime != null) {
          // If it's after the latest time from fetched mojis
          if (mojiWriteTime.isAfter(latestTimeFromFetchedMojis)) {
            // Update the latest time from fetched mojis
            latestTimeFromFetchedMojis = mojiWriteTime;
          }
        }
        // Get the start time of the moji
        final sTime = moji.s?.toUtc();
        // If the start time exists
        if (sTime != null) {
          // Add the day id to the set of moji planners to refresh
          mojiPlannersToRefreshSet.add(sTime);
        }
        // Create a list of mojis to update
        mojisToUpdate.add(moji);
      }

      // If we have mojis to update
      if (mojisToUpdate.isNotEmpty) {
        // Update the mojis in realm
        R.updateMojis(mojisToUpdate);
        // Refresh the moji bar with it's own value to force a refresh
        S.implicitPID.set(S.implicitPID.value, force: true);
      }

      // If we have a newer latest time from the fetched mojis
      if (latestTimeFromFetchedMojis.millisecondsSinceEpoch != U.zeroDateTime.millisecondsSinceEpoch) {
        // Get the existing preferences from realm
        final existingPreferences = untracked(() => S.preferencesSignal(kLocalPreferences).value);
        // If the preferences exists
        if (existingPreferences.id.isNotEmpty) {
          // Start a write transaction
          R.p.write(() {
            // Update the last successful sync time in realm
            existingPreferences.lastSuccessfulSyncTime = latestTimeFromFetchedMojis;
          });
        }
      }
      // Send the list of moji planners that need to be refreshed to the main isolate
      return Future.value(mojiPlannersToRefreshSet);
    }

    final author = U.author;
    // Spawn the moji getter in an isolate
    final mojiPlannersToRefresh = await Isolate.run(() {
      SignalsObserver.instance = null;
      return mojiGetter(author);
    });

    // Get the planner width
    final plannerWidth = untracked(() => S.preferencesSignal(kLocalPreferences).value).mojiPlannerWidth ?? kDefaultMojiPlannerWidth;
    // For each moji planner day id that needs to be refreshed
    for (final day in mojiPlannersToRefresh) {
      final did = U.did(day);
      // Get the moji planner notifier for the day id
      final mojiPlannerNotifier = U.mojiPlannersNotifiers[did];
      // If the moji planner notifier exists
      if (mojiPlannerNotifier != null) {
        // Get the flexible moji events for the day
        final flexibleMojiEvents = U.getFlexibleMojiEventsForDay(day, plannerWidth);
        // Update the value of the moji planner notifier
        mojiPlannerNotifier.value = (flexibleMojiEvents, DateTime.now().millisecondsSinceEpoch);
      }
    }
    batch(() {
      // Refresh the moji bar
      S.selectedMID.set(S.selectedMID.value, force: true);
      // Refresh the moji bar
      S.implicitPID.set(S.implicitPID.value, force: true);
    });

    return Future.value(true);
  }

  static Future<void> syncLocalUnwrittenMojis({Set<String>? mojiIDs, bool closeFirestore = false}) async {
    // If we are not online
    if (R.online != true) {
      // Don't do anything
      return;
    }

    // Always get the latest mojis first in order to avoid conflicts
    final gotLatestMojis = await R.syncServerWrittenMojis();
    // If we didn't get the latest mojis
    if (gotLatestMojis != true) {
      // Don't do anything
      return;
    }

    // Get the current author instance
    final authorInstance = U.author;
    // Singal that we are syncing mojis
    S.syncingMojis.set(true);
    // Get the directory of the realm database
    final mojiPath = m.config.path;
    final preferencesPath = p.config.path;
    // Run the in a separate isolate
    await Isolate.run(() async {
      SignalsObserver.instance = null;
      // Initialize realm
      R.m = Realm(Configuration.local([Moji.schema], path: mojiPath));
      // Initialize the preferences schema
      R.p = Realm(Configuration.local([Preferences.schema], path: preferencesPath));
      // Get the preferences
      final preferences = R.p.find<Preferences>(kLocalPreferences);
      // Get firestore details
      final firestore = getFirestore(preferences?.projectId, preferences?.serviceAccountData);
      // if The firestore is null
      if (firestore == null) {
        // Don't continue
        return;
      }
      // If we should close the firestore
      if (closeFirestore) {
        // Close the firestore to enforce failed writes
        firestore.app.close();
      }

      List<Moji?> mojisR = [];
      // If there are mojiIDs being provided
      if (mojiIDs != null) {
        // Get all mojis from realm
        for (final mojiId in mojiIDs) {
          final moji = untracked(() => S.mojiSignal(mojiId).value);
          if (moji.id.isNotEmpty) {
            mojisR.add(moji);
          }
        }
      } else {
        // Get all mojis from realm that have a null write time or a write time of zero
        mojisR = R.m.query<Moji>(r'w == null OR w == $0', [U.zeroDateTime]).toList();
      }

      // Create a list of futures
      final futures = <Future<(bool, String)> Function()>[];

      // For each moji from realm
      for (final moji in mojisR) {
        // Get the moji id
        final mid = moji?.id;
        // If it's null or if it's empty
        if (mid == null || mid.isEmpty == true) {
          // Skip to the next moji
          continue;
        }
        // Add a future to update the moji in firestore
        futures.add(
          () async {
            // Try to update the moji in firestore
            try {
              // Start a write transaction
              R.m.write(() {
                // Set the write time of the moji to the current time
                moji?.w = DateTime.now();
              });
              // Get the data
              final data = moji?.toJson();
              // Use the author instance to filter out local writes
              data?['a'] = authorInstance;
              // Update the moji in firestore
              if (data != null) {
                // Replace the moji on the server
                await firestore.collection('m').doc(mid).set(data);
              }
              // Return true and the moji id
              return (true, mid);
              // If an error occurs
            } catch (e) {
              // Start a write transaction
              R.m.write(() {
                // Set the write time of the moji to zero
                moji?.w = U.zeroDateTime;
              });
              // Return false and the moji id
              return (false, mid);
            }
          },
        );
      }

      // If we have futures to process
      if (futures.isNotEmpty) {
        // Set the concurrency limit
        const concurrencyLimit = 100;
        // Create a stopwatch to measure the time taken
        final Stopwatch stopwatch = Stopwatch()..start();
        // Process the futures with a concurrency limit
        final results = await processFuturesWithConcurrencyLimit(futures, concurrencyLimit: concurrencyLimit);
        // Print a debug message to indicate that the mojis have been updated
        debugPrint('Wrote ${futures.length} mojis in ${stopwatch.elapsedMilliseconds}ms with concurrency limit of $concurrencyLimit');
        // Stop the stopwatch
        stopwatch.stop();
        // Create a list for the successful writes
        final successfulWrites = <String>[];
        // Create a list for the failed writes
        final failedWrites = <String>[];
        // For each result
        for (final result in results) {
          // If the result is successful
          if (result.$1 == true) {
            // Add the moji id to the successful writes
            successfulWrites.add(result.$2);
            // Otherwise
          } else {
            // Add the moji id to the failed writes
            failedWrites.add(result.$2);
          }
        }

        // Get the current time
        final now = DateTime.now();

        // If we have successful writes
        if (successfulWrites.isNotEmpty) {
          final existingMojis = <Moji>[];
          for (final successfulWrite in successfulWrites) {
            final moji = untracked(() => S.mojiSignal(successfulWrite).value);
            if (moji.id.isNotEmpty) {
              existingMojis.add(moji);
            }
          }
          // Start a write transaction
          R.m.write(() {
            // For each moji
            for (final moji in existingMojis) {
              // Set the write time of the moji to the current time
              moji.w = now;
            }
          });
        }
        // If we have failed writes
        if (failedWrites.isNotEmpty) {
          final existingMojis = <Moji>[];
          for (final failedWrite in failedWrites) {
            final moji = untracked(() => S.mojiSignal(failedWrite).value);
            if (moji.id.isNotEmpty) {
              existingMojis.add(moji);
            }
          }
          // Start a write transaction
          R.m.write(() {
            // For each moji
            for (final moji in existingMojis) {
              // Set the write time of the moji to zero
              moji.w = U.zeroDateTime;
            }
          });
        }
        debugPrint('Successful: ${successfulWrites.length} Failed: ${failedWrites.length}');
      }
    });
    // Signal that we are no longer syncing mojis
    S.syncingMojis.set(false);
  }

  static Set<DateTime> fixMojiRelations() {
    final mojiPlannersToRefresh = R.m.write<Set<DateTime>>(() {
      // Create a set to hold all the moji planners
      final mojiPlannersSet = <String>{};
      // Create a set to hold all of the parents
      final parentsSet = <String>{};
      // Create a set to hold the moji planners that need to be refreshed
      final mojiPlannersToRefresh = <DateTime>{};
      // Create a list to hold the mojis to update
      final mojisToUpdate = <Moji>[];
      // Get all the mojis from realm
      final mojisR = R.m.all<Moji>();

      // For each moji from realm
      for (final mojiR in mojisR) {
        // Get the start time of the moji
        final sTime = mojiR.s?.toUtc();
        // If the start time exists
        if (sTime != null) {
          // Derive the day id
          final did = U.did(sTime);
          // Add the day id to the set of moji planners
          mojiPlannersSet.add(did);
        }
        // Get the parent of the moji
        final parent = mojiR.p;
        // If the parent exists
        if (parent != null) {
          // Add the parent to the set of parents
          parentsSet.add(parent);
        }
      }
      // Get all existing moji planners from realm
      final mojiPlannersR = mojisR.where((moji) => mojiPlannersSet.contains(moji.id));

      // Get all existing parents from realm
      final mojiParentsR = mojisR.where((moji) => parentsSet.contains(moji.id));

      // Create a map to hold the moji planners
      final mojiPlannersMap = Map<String, Moji>.fromIterable(mojiPlannersR, key: (mojiPlanner) {
        return (mojiPlanner as Moji?)?.id ?? '';
      });

      // Create a map to hold the parents
      final mojiParentsMap = Map<String, Moji>.fromIterable(mojiParentsR, key: (mojiParent) {
        return (mojiParent as Moji?)?.id ?? '';
      });

      // For each moji from realm
      for (final mojiR in mojisR) {
        // Get the start time of the event moji
        final sTime = mojiR.s?.toUtc();
        // If the start time exists
        if (sTime != null) {
          // Derive the day id
          final did = U.did(sTime);
          // Get the moji planner from the map
          final mojiPlanner = mojiPlannersMap[did];
          // If the moji planner exists
          if (mojiPlanner != null) {
            // If the event moji hasn't been removed from the moji planner
            if (mojiPlanner.j.containsKey(mojiR.id) != true) {
              // If the moji planner log doesn't already contain the event moji
              if (mojiPlanner.l.containsKey(mojiR.id) != true) {
                // Add the event moji to the moji planner log
                mojiPlanner.l[mojiR.id] = sTime.toUtc();
                // Reset the write time of the moji
                mojiPlanner.w = U.zeroDateTime;
                // Remember to update the moji planner
                mojisToUpdate.add(mojiPlanner);
                // Add the day id to the set of moji planners to refresh
                mojiPlannersToRefresh.add(sTime.toUtc());
              }
              // If the event moji has been removed from the moji planner
            } else {
              if (mojiPlanner.l.containsKey(mojiR.id)) {
                // Remove the event moji from the moji planner log
                mojiPlanner.l.remove(mojiR.id);
                // Reset the write time of the moji
                mojiPlanner.w = U.zeroDateTime;
                // Remember to update the moji planner
                mojisToUpdate.add(mojiPlanner);
                // Add the day id to the set of moji planners to refresh
                mojiPlannersToRefresh.add(sTime);
              }
            }
          }
          // Get the parent id
          final parentId = mojiR.p;
          // If it exists
          if (parentId != null) {
            // Get the moji parent from the map
            final mojiParent = mojiParentsMap[parentId];
            // If the moji parent exists
            if (mojiParent != null) {
              // If the event moji hasn't been removed from the moji parent
              if (mojiParent.j.containsKey(mojiR.id) != true) {
                // If the moji is still a child
                if (mojiParent.c.containsKey(mojiR.id)) {
                  // Remove the event moji from the moji parent children
                  mojiParent.c.remove(mojiR.id);
                  // Reset the write time of the moji
                  mojiParent.w = U.zeroDateTime;
                }
              }
            }
          }
        }
        // Get the parent id
        final parentId = mojiR.p;
        // If it exists
        if (parentId != null) {
          final sTime = mojiR.s?.toUtc();
          // Get the moji parent from the map
          final mojiParent = mojiParentsMap[parentId];
          // If the moji parent exists
          if (mojiParent != null) {
            // If the moji parent removed list doesn't contain the moji id
            if (mojiParent.j.containsKey(mojiR.id) != true) {
              // If the moji is a tile
              if (mojiR.m != null) {
                // If the heap list doesn't already contain the moji id
                if (mojiParent.h.containsKey(mojiR.id) != true) {
                  // Generate an lexicographical id poisitioned at the end
                  final lid = mojiParent.h.isEmpty ? generateOrderKeys(1).first : between(next: (mojiParent.h.values.toList()..sort()).last);
                  // Add it to the heap
                  mojiParent.h[mojiR.id] = lid;
                  // Clear the write time
                  mojiParent.w = U.zeroDateTime;
                }
                // If the moji is not a tile
              } else if (sTime != null) {
                // If the log list doesn't already contain the moji id
                if (mojiParent.l.containsKey(mojiR.id) != true) {
                  // Add it to the child list
                  mojiParent.l[mojiR.id] = sTime.toUtc();
                  // Clear the write time
                  mojiParent.w = U.zeroDateTime;
                }
              } else {
                // If the child list doesn't already contain the moji id
                if (mojiParent.c.containsKey(mojiR.id) != true) {
                  // Generate an lexicographical id poisitioned at the end
                  final lid = mojiParent.c.isEmpty ? generateOrderKeys(1).first : between(next: (mojiParent.c.values.toList()..sort()).last);
                  // Add it to the child list
                  mojiParent.c[mojiR.id] = lid;
                  // Clear the write time
                  mojiParent.w = U.zeroDateTime;
                }
              }
              // If the moji parent removed list contains the moji id
            } else {
              // If the log list contains the moji id
              if (mojiParent.h.containsKey(mojiR.id)) {
                // Remove it from the log
                mojiParent.h.remove(mojiR.id);
                // Reset the write time of the moji
                mojiParent.w = U.zeroDateTime;
              }
              // If the log list contains the moji id
              if (mojiParent.c.containsKey(mojiR.id)) {
                // Remove it from the log
                mojiParent.c.remove(mojiR.id);
                // Reset the write time of the moji
                mojiParent.w = U.zeroDateTime;
              }
              // If the log list contains the moji id
              if (mojiParent.l.containsKey(mojiR.id)) {
                // Remove it from the log
                mojiParent.l.remove(mojiR.id);
                // Reset the write time of the moji
                mojiParent.w = U.zeroDateTime;
              }
            }
            // If the write time has been reset
            if (mojiParent.w?.isAtSameMomentAs(U.zeroDateTime) == true) {
              // Remember to update the moji parent
              mojisToUpdate.add(mojiParent);
            }
          }
        }
      }
      // If there are mojis to update
      if (mojisToUpdate.isNotEmpty) {
        // Update all the mojis that need to be updated
        R.m.addAll<Moji>(mojisToUpdate, update: true);
      }
      // Return the set of moji planners to refresh
      return mojiPlannersToRefresh;
    });
    // Return the set of moji planners to refresh
    return mojiPlannersToRefresh;
  }

  static void mergeMojiTiles(Moji mojiWW, Moji? mojiRunway) {
    // If the moji tiles don't have the exact same mojis
    if (mojiWW.m != mojiRunway?.m || mojiWW.m == null) {
      // Don't do anything
      return;
    }
    // Create a list of mojis to update
    final Set<String> mojisToUpdate = {};
    // Create a list of mojis before changes
    final List<Moji> mojiLBC = [];
    // Derive a set of all the descendants of the moji with wings
    final mojiWWD = <String>{...mojiWW.c.keys, ...mojiWW.h.keys, ...mojiWW.l.keys, ...mojiWW.j.keys};
    // Get all the descendants of the moji with wings from realm
    final mojiWWDRs = <Moji>[];
    for (final mid in mojiWWD) {
      final moji = untracked(() => S.mojiSignal(mid).value);
      if (moji.id.isNotEmpty) {
        mojiWWDRs.add(moji);
      }
    }
    R.m.write(() {
      // For each descendant of the moji with wings desendants from realm
      for (final mojiWWDR in mojiWWDRs) {
        // If it doesn't already have the moji runway as a parent
        if (mojiWWDR.p != mojiRunway?.id) {
          // Add a copy of the moji to the list of mojis before changes
          mojiLBC.add(mojiWWDR.copyWith());
          // Update the parent of the descendant to the moji runway id
          mojiWWDR.p = mojiRunway?.id;
          // Clear out the write time of the descendant
          mojiWWDR.w = U.zeroDateTime;
          // Remember to update the descendant
          mojisToUpdate.add(mojiWWDR.id);
        }
      }

      // If the moji runway exists
      if (mojiRunway != null) {
        // Add a copy of the moji runway to the list of mojis before changes
        mojiLBC.add(mojiRunway.copyWith());
        // Merge the flying moji children list with the moji runway children list
        mojiRunway.c.addAll(mojiWW.c);
        // Merge the flying moji heap list with the moji runway heap list
        mojiRunway.h.addAll(mojiWW.h);
        // Merge the flying moji log list with the moji runway log list
        mojiRunway.l.addAll(mojiWW.l);
        // Merge the flying moji junk list with the moji runway junk list
        mojiRunway.j.addAll(mojiWW.j);
        // Clear out the write time of the moji runway
        mojiRunway.w = U.zeroDateTime;
        // Remember to update the moji runway
        mojisToUpdate.add(mojiRunway.id);
      }

      // Get the moji with wings parent id
      final mojiWWPID = mojiWW.p;
      // If it exists
      if (mojiWWPID != null) {
        // Get the moji with wings parent from realm
        final mojiWWPR = untracked(() => S.mojiSignal(mojiWWPID).value);
        // If it exists
        if (mojiWWPR.id.isNotEmpty) {
          // Add a copy of the moji with wings parent to the list of mojis before changes
          mojiLBC.add(mojiWWPR.copyWith());
          // Remove the flying moji from the parent children list
          mojiWWPR.c.remove(mojiWW.id);
          // Remove the flying moji from the parent heap list
          mojiWWPR.h.remove(mojiWW.id);
          // Remove the flying moji from the parent log list
          mojiWWPR.l.remove(mojiWW.id);
          // If the moji with wings is not in the parent junk list
          if (mojiWWPR.j.containsKey(mojiWW.id) != true) {
            // Add the moji with wings to the parent junk list
            mojiWWPR.j[mojiWW.id] = DateTime.now().toUtc();
          }
          // Clear out the write time of the parent
          mojiWWPR.w = U.zeroDateTime;
          // Remember to update the parent
          mojisToUpdate.add(mojiWWPR.id);
        }
      }

      // Add a copy of the moji with wings to the list of mojis before changes
      mojiLBC.add(mojiWW.copyWith());
      // Clear out the children list of the moji with wings
      mojiWW.c.clear();
      // Clear out the heap list of the moji with wings
      mojiWW.h.clear();
      // Clear out the log list of the moji with wings
      mojiWW.l.clear();
      // Clear out the junk list of the moji with wings
      mojiWW.j.clear();
      // Clear out the write time of the moji with wings
      mojiWW.w = U.zeroDateTime;
      // Remember to update the moji with wings
      mojisToUpdate.add(mojiWW.id);
    });

    if (mojisToUpdate.isNotEmpty) {
      // Sync the unwritten mojis
      syncLocalUnwrittenMojis(mojiIDs: mojisToUpdate);
      U.mojiChanges.add(
        Change<List<Moji>>(
          mojiLBC,
          () {},
          (mojiLBC) {
            // Restore the mojis to their previous state
            R.updateMojis(mojiLBC);
            // Sync the unwritten mojis
            syncLocalUnwrittenMojis(mojiIDs: mojiLBC.map((e) => e.id).toSet());
          },
        ),
      );
    }

    // Refresh the moji bar with it's own value to force a refresh
    S.implicitPID.set(S.implicitPID.value, force: true);
  }
}
