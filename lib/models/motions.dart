/// Curated debate motions for the home hero ("Today's motion").
///
/// One rotates in per day (by day-of-year), so every user sees the same
/// motion on the same day and can compare results. Keep them short,
/// debatable and specific; avoid anything that needs local context.
abstract final class Motions {
  static const List<String> all = [
    'Social media has done more harm than good to public debate.',
    'Universities should abolish letter grades.',
    'Remote work makes teams more productive, not less.',
    'Cities should ban private cars from their centres.',
    'Artificial intelligence will create more jobs than it destroys.',
    'Voting should be compulsory.',
    'Space exploration is worth its cost.',
    'Homework does more harm than good.',
    'Nuclear power is the best path to clean energy.',
    'Professional athletes are overpaid.',
    'A four-day work week should be the legal standard.',
    'Zoos should no longer exist.',
    'Governments should provide a universal basic income.',
    'Video games are a legitimate art form.',
    'Standardised tests measure privilege, not ability.',
    'The internet has made us lonelier.',
    'Fast fashion should be taxed like tobacco.',
    'Children should learn to code before they learn a second language.',
    'Billionaires should not exist.',
    'Cash should be phased out entirely.',
    'Streaming has made music worse.',
    'Every citizen should do a year of public service.',
    'Self-driving cars will make roads safer.',
    'Museums should return all looted artefacts.',
    'Online anonymity does more good than harm.',
    'Tipping should be abolished.',
    'Schools should start later in the morning.',
    'Plastic should be banned from packaging.',
    'Space tourism is an indefensible luxury.',
    'Nations should open their borders.',
    'Advertising to children should be illegal.',
    'The Olympics do more harm than good to host cities.',
    'Genetic editing of embryos should be allowed to prevent disease.',
    'Public libraries matter more than ever.',
    'Meat should cost twice as much.',
    'Smartphones should be banned in secondary schools.',
  ];

  /// The motion for [date] (defaults to today). Same for every user that day.
  static String forDay([DateTime? date]) {
    final d = (date ?? DateTime.now()).toUtc();
    final dayOfYear = d.difference(DateTime.utc(d.year, 1, 1)).inDays;
    return all[(dayOfYear + d.year) % all.length];
  }

  /// A different motion than [current], for a "shuffle" affordance.
  static String another(String current, {int seed = 0}) {
    final i = all.indexOf(current);
    final next = (i + 7 + seed) % all.length;
    return all[next == i ? (next + 1) % all.length : next];
  }
}
