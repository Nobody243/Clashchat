/// One of the selectable avatars. The image is the same Dicebear "thumbs"
/// render the rest of the app uses, so what you pick is what you get.
class AvatarOption {
  final String name;
  final String seed;

  const AvatarOption({required this.name, required this.seed});

  String get url => avatarUrlFor(seed);
}

/// Dicebear thumbs in the app palette. Used by the picker and by every
/// avatar render so previews always match.
String avatarUrlFor(String seed) {
  final s = Uri.encodeComponent(seed.trim().isEmpty ? 'Debater' : seed.trim());
  return 'https://api.dicebear.com/9.x/thumbs/svg?seed=$s'
      '&backgroundColor=1e1e21,10342a,132a45,3d1d1d,3a2b10'
      '&shapeColor=ff5a3c,4ed39a,6fb1ff,ff7b6b,d9a441,b7bec7'
      '&radius=50';
}

const List<AvatarOption> kAvatars = [
  AvatarOption(name: 'Felix', seed: 'Felix'),
  AvatarOption(name: 'Aneka', seed: 'Aneka'),
  AvatarOption(name: 'Milo', seed: 'Milo'),
  AvatarOption(name: 'Luna', seed: 'Luna'),
  AvatarOption(name: 'Sophie', seed: 'Sophie'),
  AvatarOption(name: 'Kai', seed: 'Kai'),
  AvatarOption(name: 'Nova', seed: 'Nova'),
  AvatarOption(name: 'Rhea', seed: 'Rhea'),
  AvatarOption(name: 'Otto', seed: 'Otto'),
  AvatarOption(name: 'Zara', seed: 'Zara'),
  AvatarOption(name: 'Idris', seed: 'Idris'),
  AvatarOption(name: 'Mira', seed: 'Mira'),
  AvatarOption(name: 'Theo', seed: 'Theo'),
  AvatarOption(name: 'Suki', seed: 'Suki'),
  AvatarOption(name: 'Ravi', seed: 'Ravi'),
  AvatarOption(name: 'Elin', seed: 'Elin'),
];
