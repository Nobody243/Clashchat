enum DebateRank {
  newcomer,
  challenger,
  debater,
  orator,
  grandmaster,
}

class RankModel {
  static const Map<DebateRank, Map<String, dynamic>> rankData = {
    DebateRank.newcomer: {
      'name': 'Newcomer',
      'minPoints': 0,
      'maxPoints': 199,
      'color': 0xFF8E8A85,  // stone
    },
    DebateRank.challenger: {
      'name': 'Challenger',
      'minPoints': 200,
      'maxPoints': 499,
      'color': 0xFFB5793F,  // bronze
    },
    DebateRank.debater: {
      'name': 'Debater',
      'minPoints': 500,
      'maxPoints': 999,
      'color': 0xFFA9B0BA,  // silver
    },
    DebateRank.orator: {
      'name': 'Orator',
      'minPoints': 1000,
      'maxPoints': 1999,
      'color': 0xFFD4A84B,  // brass
    },
    DebateRank.grandmaster: {
      'name': 'Grandmaster',
      'minPoints': 2000,
      'maxPoints': 999999,
      'color': 0xFFCFE3F0,  // ice
    },
  };

  // Get rank from total points
  static DebateRank getRankFromPoints(int points) {
    if (points >= 2000) return DebateRank.grandmaster;
    if (points >= 1000) return DebateRank.orator;
    if (points >= 500)  return DebateRank.debater;
    if (points >= 200)  return DebateRank.challenger;
    return DebateRank.newcomer;
  }

  // Calculate points earned from a debate
  // Score 50+ = win, higher score = more points
  static int calculatePointsEarned(int debateScore, bool isRanked) {
    if (!isRanked) return 0; // casual gives no rank points

    if (debateScore < 50) {
      // Loss - lose points based on how bad
      if (debateScore < 30) return -20;
      return -10;
    }

    // Win - scale points with score
    if (debateScore >= 90) return 50;
    if (debateScore >= 80) return 35;
    if (debateScore >= 70) return 25;
    if (debateScore >= 60) return 15;
    return 10; // 50-59
  }

  // Progress to next rank (0.0 to 1.0)
  static double getRankProgress(int points) {
    final rank = getRankFromPoints(points);
    final data = rankData[rank]!;
    final min = data['minPoints'] as int;
    final max = data['maxPoints'] as int;
    if (max == 999999) return 1.0; // grandmaster maxed
    return ((points - min) / (max - min)).clamp(0.0, 1.0);
  }
}
