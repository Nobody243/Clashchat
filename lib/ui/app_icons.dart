import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/debate_mode.dart';
import '../models/rank_model.dart';

/// The app's icon vocabulary (Lucide). See DESIGN.md §7.
///
/// Screens reference these names, never `Icons.*` or emoji. Regular stroke
/// is the default; `*Filled` maps to the 600-weight stroke and is used for
/// selected navigation items. `*Duo` aliases exist for call sites that want
/// an "illustrative" icon inside a tinted tile; they resolve to the regular
/// glyph (the tile provides the second tone).
abstract final class AppIcons {
  // Navigation
  static const IconData home = LucideIcons.house;
  static const IconData homeFilled = LucideIcons.house600;
  static const IconData history = LucideIcons.history;
  static const IconData historyFilled = LucideIcons.history600;
  static const IconData profile = LucideIcons.circleUser;
  static const IconData profileFilled = LucideIcons.circleUser600;
  static const IconData settings = LucideIcons.settings;
  static const IconData settingsFilled = LucideIcons.settings600;

  // Modes
  static const IconData casual = LucideIcons.messagesSquare;
  static const IconData ranked = LucideIcons.trophy;
  static const IconData learning = LucideIcons.graduationCap;
  static const IconData casualDuo = LucideIcons.messagesSquare;
  static const IconData rankedDuo = LucideIcons.trophy;
  static const IconData learningDuo = LucideIcons.graduationCap;

  // Debate
  static const IconData topic = LucideIcons.bookOpen;
  static const IconData stanceFor = LucideIcons.thumbsUp;
  static const IconData stanceAgainst = LucideIcons.thumbsDown;
  static const IconData stanceForFilled = LucideIcons.thumbsUp600;
  static const IconData stanceAgainstFilled = LucideIcons.thumbsDown600;
  static const IconData timer = LucideIcons.timer;
  static const IconData send = LucideIcons.send;
  static const IconData sendFilled = LucideIcons.send600;
  static const IconData endDebate = LucideIcons.flag;
  static const IconData ai = LucideIcons.brain;
  static const IconData coachTip = LucideIcons.lightbulb;
  static const IconData coachTipFilled = LucideIcons.lightbulb600;
  static const IconData score = LucideIcons.target;
  static const IconData strengths = LucideIcons.circleCheck;
  static const IconData weaknesses = LucideIcons.circleAlert;
  static const IconData points = LucideIcons.zap;
  static const IconData pointsFilled = LucideIcons.zap600;
  static const IconData messages = LucideIcons.messageCircle;
  static const IconData trendUp = LucideIcons.trendingUp;
  static const IconData trendDown = LucideIcons.trendingDown;
  static const IconData play = LucideIcons.play;
  static const IconData pause = LucideIcons.pause;
  static const IconData stop = LucideIcons.circleStop;

  // Difficulty
  static const IconData easy = LucideIcons.sprout;
  static const IconData medium = LucideIcons.sword;
  static const IconData hard = LucideIcons.flame;
  static const IconData easyDuo = LucideIcons.sprout;
  static const IconData mediumDuo = LucideIcons.sword;
  static const IconData hardDuo = LucideIcons.flame;

  // Ranks
  static const IconData rankNewcomer = LucideIcons.sprout600;
  static const IconData rankChallenger = LucideIcons.sword600;
  static const IconData rankDebater = LucideIcons.target600;
  static const IconData rankOrator = LucideIcons.scale600;
  static const IconData rankGrandmaster = LucideIcons.crown600;

  // Topic categories
  static const IconData technology = LucideIcons.cpu;
  static const IconData education = LucideIcons.graduationCap;
  static const IconData society = LucideIcons.users;
  static const IconData health = LucideIcons.heartPulse;
  static const IconData politics = LucideIcons.landmark;
  static const IconData environment = LucideIcons.leaf;
  static const IconData economy = LucideIcons.chartLine;
  static const IconData culture = LucideIcons.drama;

  // Actions & chrome
  static const IconData back = LucideIcons.arrowLeft;
  static const IconData forward = LucideIcons.chevronRight;
  static const IconData close = LucideIcons.x;
  static const IconData more = LucideIcons.ellipsisVertical;
  static const IconData edit = LucideIcons.pencil;
  static const IconData delete = LucideIcons.trash2;
  static const IconData filter = LucideIcons.listFilter;
  static const IconData search = LucideIcons.search;
  static const IconData check = LucideIcons.check;
  static const IconData checkCircle = LucideIcons.circleCheck600;
  static const IconData info = LucideIcons.info;
  static const IconData warning = LucideIcons.circleAlert;
  static const IconData error = LucideIcons.octagonX;
  static const IconData sun = LucideIcons.sun;
  static const IconData moon = LucideIcons.moon;
  static const IconData signOut = LucideIcons.logOut;
  static const IconData shuffle = LucideIcons.shuffle;
  static const IconData sparkle = LucideIcons.sparkles;
  static const IconData sparkleFilled = LucideIcons.sparkles600;
  static const IconData shield = LucideIcons.shieldCheck;
  static const IconData bell = LucideIcons.bell;
  static const IconData speaker = LucideIcons.volume2;
  static const IconData document = LucideIcons.fileText;
  static const IconData calendar = LucideIcons.calendar;
  static const IconData usage = LucideIcons.gauge;

  // Auth
  static const IconData email = LucideIcons.mail;
  static const IconData lock = LucideIcons.lock;
  static const IconData lockOpen = LucideIcons.lockOpen;
  static const IconData user = LucideIcons.user;
  static const IconData eye = LucideIcons.eye;
  static const IconData eyeSlash = LucideIcons.eyeOff;
  static const IconData key = LucideIcons.keyRound;

  // ── Mappings ──

  static IconData forRank(DebateRank rank) => switch (rank) {
        DebateRank.newcomer => rankNewcomer,
        DebateRank.challenger => rankChallenger,
        DebateRank.debater => rankDebater,
        DebateRank.orator => rankOrator,
        DebateRank.grandmaster => rankGrandmaster,
      };

  static IconData forMode(DebateMode mode, {bool duotone = false}) =>
      switch (mode) {
        DebateMode.casual => duotone ? casualDuo : casual,
        DebateMode.ranked => duotone ? rankedDuo : ranked,
        DebateMode.learning => duotone ? learningDuo : learning,
      };

  /// Accepts 'easy' | 'medium' | 'hard' (case-insensitive); unknown → medium.
  static IconData forDifficulty(String difficulty, {bool duotone = false}) {
    switch (difficulty.trim().toLowerCase()) {
      case 'easy':
      case 'newcomer':
        return duotone ? easyDuo : easy;
      case 'hard':
      case 'orator':
      case 'grandmaster':
        return duotone ? hardDuo : hard;
      default:
        return duotone ? mediumDuo : medium;
    }
  }

  static IconData forStance(String stance, {bool filled = false}) {
    final isFor = stance.trim().toLowerCase() == 'for';
    if (filled) return isFor ? stanceForFilled : stanceAgainstFilled;
    return isFor ? stanceFor : stanceAgainst;
  }

  /// Topic category by display name (case-insensitive); unknown → topic.
  static IconData forCategory(String name) => switch (name.trim().toLowerCase()) {
        'technology' => technology,
        'education' => education,
        'society' => society,
        'health' => health,
        'politics' => politics,
        'environment' => environment,
        'economy' => economy,
        'culture' => culture,
        _ => topic,
      };
}
