import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/jaune_haptics.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/friend.dart';
import '../services/audio_service.dart';
import '../services/friends_service.dart';
import '../theme/jaune_design.dart';
import 'add_friend_sheet.dart';
import 'confirm_sheet.dart';
import 'leaderboard_podium.dart';
import 'leaderboard_row.dart';
import 'pressable.dart';

enum _View { leaderboard, requests, addFriend }

/// Écran « Classement entre amis ». Navigation interne : demandes et ajout
/// d'ami remplacent le contenu du sheet en place (pas d'empilement).
class LeaderboardSheet {
  static Future<void> show(
    BuildContext context, {
    required LeaderboardEntry me,
  }) {
    JauneHaptics.selection();
    AudioService.instance.playUiPop();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LeaderboardSheetContent(me: me),
    );
  }
}

class _LeaderboardSheetContent extends StatefulWidget {
  final LeaderboardEntry me;
  const _LeaderboardSheetContent({required this.me});

  @override
  State<_LeaderboardSheetContent> createState() =>
      _LeaderboardSheetContentState();
}

class _LeaderboardSheetContentState extends State<_LeaderboardSheetContent> {
  _View _view = _View.leaderboard;
  List<LeaderboardEntry> _friends = [];
  List<FriendRequest> _pendingRequests = [];
  int _pendingCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await friendsService.refresh();
    final friends = await friendsService.friends();
    final requests = await friendsService.pendingRequests();
    if (!mounted) return;
    setState(() {
      _friends = friends;
      _pendingRequests = requests;
      _pendingCount = requests.length;
      _loading = false;
    });
  }

  List<LeaderboardEntry> get _ranking {
    final all = [..._friends, widget.me.copyWith(isMe: true)];
    all.sort((a, b) => b.healthPercent.compareTo(a.healthPercent));
    return all;
  }

  void _navigate(_View view) {
    JauneHaptics.selection();
    AudioService.instance.playUiPop();
    setState(() => _view = view);
  }

  Future<void> _accept(FriendRequest r) async {
    JauneHaptics.medium();
    AudioService.instance.playUiPop();
    await friendsService.acceptRequest(r.userId);
    await _load();
  }

  Future<void> _ignore(FriendRequest r) async {
    JauneHaptics.selection();
    await friendsService.ignoreRequest(r.userId);
    await _load();
  }

  Future<void> _remove(LeaderboardEntry friend) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await ConfirmSheet.show(
      context,
      title: l10n.leaderboardRemoveFriendTitle,
      message: l10n.leaderboardRemoveFriendMessage(friend.username),
      confirmLabel: l10n.leaderboardRemoveFriendConfirm,
      cancelLabel: l10n.cancel,
    );
    if (!confirmed) return;
    JauneHaptics.medium();
    await friendsService.removeFriend(friend.userId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEAF3FC), Color(0xFFF8FBFE)],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(JauneRadii.sheet),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder:
                  (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
              child: KeyedSubtree(
                key: ValueKey(_view),
                child: switch (_view) {
                  _View.leaderboard => _buildLeaderboard(context),
                  _View.requests => _buildRequests(context),
                  _View.addFriend => _buildAddFriend(context),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ranking = _ranking;
    final hasFriends = ranking.length > 1;
    final rest = ranking.length > 3 ? ranking.sublist(3) : <LeaderboardEntry>[];

    return Column(
      children: [
        _Header(
          title: l10n.leaderboardTitle,
          requestsLabel: l10n.leaderboardManageTitle,
          pendingCount: _pendingCount,
          onRequests: () => _navigate(_View.requests),
          onAddFriend: () => _navigate(_View.addFriend),
        ),
        const SizedBox(height: 8),
        Expanded(
          child:
              _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : !hasFriends
                  ? _EmptyState(
                    emoji: '🏆',
                    title: l10n.leaderboardEmptyTitle,
                    subtitle: l10n.leaderboardEmptySubtitle,
                    actionLabel: l10n.leaderboardAddFriend,
                    onAction: () => _navigate(_View.addFriend),
                  )
                  : ListView(
                    padding: const EdgeInsets.only(bottom: 28),
                    children: [
                      LeaderboardPodium(ranking: ranking),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Column(
                          children: [
                            for (var i = 0; i < rest.length; i++)
                              LeaderboardRow(rank: i + 4, entry: rest[i]),
                          ],
                        ),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _buildRequests(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasRequests = _pendingRequests.isNotEmpty;
    final hasFriends = _friends.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              PressableScale(
                semanticLabel: 'Retour',
                onTap: () => _navigate(_View.leaderboard),
                child: const Icon(
                  CupertinoIcons.chevron_left,
                  color: JauneColors.inkSoft,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.leaderboardManageTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: JauneColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child:
              _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : (!hasRequests && !hasFriends)
                  ? _EmptyState(
                    emoji: '📭',
                    title: l10n.leaderboardNoRequestsTitle,
                    subtitle: l10n.leaderboardNoRequestsSubtitle,
                  )
                  : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    children: [
                      // Section « Demandes » : seulement s'il y en a.
                      if (hasRequests) ...[
                        _ManageSectionTitle(
                          l10n.leaderboardTabRequests,
                          count: _pendingRequests.length,
                        ),
                        for (final r in _pendingRequests)
                          _RequestRow(
                            request: r,
                            onAccept: () => _accept(r),
                            onIgnore: () => _ignore(r),
                          ),
                      ],
                      if (hasFriends) ...[
                        // Un sous-titre « Mes amis » n'est utile que pour
                        // séparer des demandes affichées au-dessus.
                        if (hasRequests) ...[
                          const SizedBox(height: 14),
                          _ManageSectionTitle(
                            l10n.leaderboardYourFriends,
                            count: _friends.length,
                          ),
                        ],
                        for (final f in _friends)
                          _FriendManageRow(
                            friend: f,
                            removeLabel: l10n.leaderboardRemoveFriend,
                            onRemove: () => _remove(f),
                          ),
                      ],
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _buildAddFriend(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 32 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              PressableScale(
                semanticLabel: 'Retour',
                onTap: () => _navigate(_View.leaderboard),
                child: const Icon(
                  CupertinoIcons.chevron_left,
                  color: JauneColors.inkSoft,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.addFriendTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: JauneColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.addFriendSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: JauneColors.inkSoft),
          ),
                    Spacer(),

          AddFriendBody(
            myCode: friendsService.myCode,
            mySkin: widget.me.equippedSkin,
            onCodeReceived: (code) async {
              await friendsService.sendRequest(code);
              await _load();
              if (mounted) _navigate(_View.leaderboard);
            },
          ),
        ],
      ),
    );
  }
}

/// En-tête : titre + bouton « Demandes » (avec compteur) + ajouter un ami.
class _Header extends StatelessWidget {
  final String title;
  final String requestsLabel;
  final int pendingCount;
  final VoidCallback onRequests;
  final VoidCallback onAddFriend;

  const _Header({
    required this.title,
    required this.requestsLabel,
    required this.pendingCount,
    required this.onRequests,
    required this.onAddFriend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: JauneColors.ink,
              ),
            ),
          ),
          PressableScale(
            semanticLabel: requestsLabel,
            onTap: onRequests,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(JauneRadii.pill),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.person_2_fill,
                    size: 18,
                    color: JauneColors.inkSoft,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    requestsLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: JauneColors.ink,
                    ),
                  ),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE63946),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          PressableScale(
            semanticLabel: AppLocalizations.of(context).leaderboardAddFriend,
            onTap: onAddFriend,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [JauneColors.lemon, JauneColors.lemonDeep],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x55F6B73F),
                    offset: Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.person_add_solid,
                color: JauneColors.ink,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onIgnore;

  const _RequestRow({
    required this.request,
    required this.onAccept,
    required this.onIgnore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(JauneRadii.card),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          LeaderboardMonogram(name: request.username, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              request.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: JauneColors.ink,
              ),
            ),
          ),
          PressableScale(
            semanticLabel: l10n.leaderboardIgnore,
            onTap: onIgnore,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                l10n.leaderboardIgnore,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: JauneColors.inkSoft,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          PressableScale(
            semanticLabel: l10n.leaderboardAccept,
            onTap: onAccept,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [JauneColors.lemon, JauneColors.lemonDeep],
                ),
                borderRadius: BorderRadius.circular(JauneRadii.pill),
              ),
              child: Text(
                l10n.leaderboardAccept,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: JauneColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Petit titre de section dans la vue de gestion (« Demandes », « Mes amis »),
/// avec un compteur discret.
class _ManageSectionTitle extends StatelessWidget {
  final String label;
  final int count;
  const _ManageSectionTitle(this.label, {required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: JauneColors.ink,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: JauneColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne « ami existant » dans la vue de gestion : avatar, pseudo, et un
/// bouton discret pour retirer l'ami (confirmation gérée par l'appelant).
class _FriendManageRow extends StatelessWidget {
  final LeaderboardEntry friend;
  final String removeLabel;
  final VoidCallback onRemove;

  const _FriendManageRow({
    required this.friend,
    required this.removeLabel,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(JauneRadii.card),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          LeaderboardMonogram(name: friend.username, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              friend.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: JauneColors.ink,
              ),
            ),
          ),
          PressableScale(
            semanticLabel: removeLabel,
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE63946).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(JauneRadii.pill),
              ),
              child: Text(
                removeLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE63946),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: JauneColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: JauneColors.inkSoft),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              PressableScale(
                semanticLabel: actionLabel,
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [JauneColors.lemon, JauneColors.lemonDeep],
                    ),
                    borderRadius: BorderRadius.circular(JauneRadii.pill),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: JauneColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Petite feuille de saisie du pseudo, présentée à la première ouverture du
/// classement si aucun pseudo n'est défini. Renvoie le pseudo validé, ou null.
class UsernamePrompt {
  static Future<String?> show(BuildContext context, {String initial = ''}) {
    final controller = TextEditingController(text: initial);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(JauneRadii.sheet)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.usernamePromptTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: JauneColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.usernamePromptSubtitle,
                  style: TextStyle(fontSize: 14, color: JauneColors.inkSoft),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: l10n.usernamePromptHint,
                    filled: true,
                    fillColor: JauneColors.skyLight.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(JauneRadii.card),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (v) {
                    final t = v.trim();
                    if (t.isNotEmpty) Navigator.of(ctx).pop(t);
                  },
                ),
                const SizedBox(height: 8),
                PressableScale(
                  semanticLabel: l10n.usernamePromptSave,
                  onTap: () {
                    final t = controller.text.trim();
                    if (t.isEmpty) return;
                    JauneHaptics.selection();
                    Navigator.of(ctx).pop(t);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [JauneColors.lemon, JauneColors.lemonDeep],
                      ),
                      borderRadius: BorderRadius.circular(JauneRadii.pill),
                    ),
                    child: Center(
                      child: Text(
                        l10n.usernamePromptSave,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: JauneColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
