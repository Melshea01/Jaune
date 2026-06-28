import 'package:flutter/material.dart';

/// Données du « Voyage du Citron » — 100 niveaux répartis en 5 mondes (arènes,
/// façon Clash Royale). Contenu narratif bilingue **en dur** (type-safe,
/// synchrone, sans plomberie d'assets) : chaque niveau donne une récompense
/// (lore, objet à collectionner, tenue/skin, feature ou badge).
///
/// Contrainte : les clés de type [UnlockType.citronState] qui correspondent à
/// un vrai skin (cf. kCitronSkins) doivent rester EXACTES pour l'équipement.

enum UnlockType {
  citronState, // tenue / skin du citron (clé = skin réel si équipable)
  feature, // fonctionnalité app
  badge, // badge partageable
  message, // (hérité) — conservé pour compat
  collectible, // objet de collection (vitrine)
  lore, // bribe d'histoire / réplique du citron
}

/// Un niveau du voyage et sa récompense. Libellés bilingues résolus à
/// l'affichage (cf. l10n_helpers.unlockTitle / unlockDescription).
class LevelUnlock {
  final int level;
  final int chapter; // 1..5
  final UnlockType type;
  final String key; // stable (skin/feature/badge) ou 'lvl_N'
  final String icon; // emoji affiché sur le nœud / la tuile
  final String titleFr;
  final String titleEn;
  final String descFr;
  final String descEn;

  const LevelUnlock(
    this.level,
    this.chapter,
    this.type,
    this.key,
    this.icon,
    this.titleFr,
    this.titleEn,
    this.descFr,
    this.descEn,
  );
}

/// Un monde / une arène du voyage.
class JourneyChapter {
  final int id;
  final int from;
  final int to;
  final String nameFr;
  final String nameEn;
  final String emoji;
  final int colorValue;

  const JourneyChapter(
    this.id,
    this.from,
    this.to,
    this.nameFr,
    this.nameEn,
    this.emoji,
    this.colorValue,
  );

  String name(bool fr) => fr ? nameFr : nameEn;
  Color get color => Color(colorValue);
}

const List<JourneyChapter> kChapters = [
  JourneyChapter(1, 1, 20, 'Le Verger', 'The Orchard', '🌿', 0xFF34C759),
  JourneyChapter(2, 21, 40, 'La Côte', 'The Coast', '🌊', 0xFF0A84FF),
  JourneyChapter(3, 41, 60, 'Les Sommets', 'The Peaks', '⛰️', 0xFF64748B),
  JourneyChapter(4, 61, 80, 'La Ville', 'The City', '🌃', 0xFFAF52DE),
  JourneyChapter(5, 81, 100, 'Les Étoiles', 'The Stars', '🌌', 0xFF6366F1),
];

JourneyChapter chapterOfLevel(int level) => kChapters.firstWhere(
      (c) => level >= c.from && level <= c.to,
      orElse: () => kChapters.last,
    );

Color chapterColorOf(int level) => chapterOfLevel(level).color;

/// Dégradé de fond de l'accueil teinté par le monde courant (façon arène).
/// Teinte douce en haut → blanc en bas, pour rester lisible sous l'UI.
List<Color> worldBackground(int level) {
  final c = chapterColorOf(level);
  return [
    Color.lerp(c, Colors.white, 0.55)!,
    Color.lerp(c, Colors.white, 0.80)!,
    Colors.white,
  ];
}

const List<LevelUnlock> kLevelUnlocks = [
  // ---------------------------------------------------------------------------
  // Chapitre 1 — Le Verger (1-20) 🌿
  // ---------------------------------------------------------------------------
  LevelUnlock(1, 1, UnlockType.lore, 'lvl_1', '🌱', 'La graine', 'The seed',
      'Ton voyage commence dans le verger.', 'Your journey begins in the orchard.'),
  LevelUnlock(2, 1, UnlockType.collectible, 'lvl_2', '💧', 'Goutte de rosée',
      'Dewdrop', 'Au matin, tout est possible.', 'In the morning, anything is possible.'),
  LevelUnlock(3, 1, UnlockType.feature, 'history_7d', '📊', 'Carnet 7 jours',
      '7-day journal', 'Visualise ta semaine.', 'See your week at a glance.'),
  LevelUnlock(4, 1, UnlockType.collectible, 'lvl_4', '🌰', 'Première racine',
      'First root', 'Tu prends ancrage.', 'You take root.'),
  LevelUnlock(5, 1, UnlockType.badge, 'badge_first_step', '🏅', 'Premier pas',
      'First step', 'Tu as lancé l\'aventure.', 'You set off on the adventure.'),
  LevelUnlock(6, 1, UnlockType.citronState, 'skin_sunglasses', '🕶️',
      'Lunettes de soleil', 'Sunglasses', 'Le citron a la classe.', 'The lemon looks cool.'),
  LevelUnlock(7, 1, UnlockType.collectible, 'lvl_7', '🐝', 'L\'abeille',
      'The bee', 'Une amie bourdonne près de toi.', 'A friend buzzes nearby.'),
  LevelUnlock(8, 1, UnlockType.lore, 'lvl_8', '🌞', 'Plein soleil', 'Full sun',
      'Chaque jour sobre te nourrit.', 'Each sober day feeds you.'),
  LevelUnlock(9, 1, UnlockType.collectible, 'lvl_9', '🍃', 'Première feuille',
      'First leaf', 'Tu grandis doucement.', 'You grow, gently.'),
  LevelUnlock(10, 1, UnlockType.collectible, 'lvl_10', '🪴', 'Jeune pousse',
      'Young sprout', 'Déjà dix niveaux !', 'Ten levels already!'),
  LevelUnlock(11, 1, UnlockType.citronState, 'skin_verdant', '🍈', 'Citron vert',
      'Lime tint', 'Une nouvelle teinte à porter.', 'A fresh new tint to wear.'),
  LevelUnlock(12, 1, UnlockType.feature, 'weekly_insight', '🔎',
      'Coup d\'œil hebdo', 'Weekly insight', 'Un regard sur ta semaine.', 'A look at your week.'),
  LevelUnlock(13, 1, UnlockType.collectible, 'lvl_13', '🦋', 'Le papillon',
      'The butterfly', 'La légèreté revient.', 'Lightness returns.'),
  LevelUnlock(14, 1, UnlockType.lore, 'lvl_14', '🌧️', 'La pluie douce',
      'Gentle rain', 'Même les jours gris t\'aident.', 'Even grey days help you.'),
  LevelUnlock(15, 1, UnlockType.collectible, 'lvl_15', '🧺', 'Panier d\'osier',
      'Wicker basket', 'De quoi récolter tes efforts.', 'To gather your efforts.'),
  LevelUnlock(16, 1, UnlockType.citronState, 'skin_party_hat', '🎉',
      'Chapeau de fête', 'Party hat', 'On célèbre chaque victoire.', 'Celebrate every win.'),
  LevelUnlock(17, 1, UnlockType.collectible, 'lvl_17', '🐞', 'La coccinelle',
      'The ladybug', 'Un porte-bonheur se pose.', 'A lucky charm lands.'),
  LevelUnlock(18, 1, UnlockType.lore, 'lvl_18', '🌳', 'L\'arbre prend forme',
      'The tree takes shape', 'Tes racines sont solides.', 'Your roots run deep.'),
  LevelUnlock(19, 1, UnlockType.collectible, 'lvl_19', '🍯', 'Pot de miel',
      'Jar of honey', 'La douceur récompense.', 'Sweetness rewards you.'),
  LevelUnlock(20, 1, UnlockType.badge, 'badge_orchard', '🏆',
      'Maître du Verger', 'Orchard Master', 'Tu quittes le verger, grandi.', 'You leave the orchard, grown.'),

  // ---------------------------------------------------------------------------
  // Chapitre 2 — La Côte (21-40) 🌊
  // ---------------------------------------------------------------------------
  LevelUnlock(21, 2, UnlockType.lore, 'lvl_21', '⛵', 'Cap sur la côte',
      'Off to the coast', 'L\'horizon s\'ouvre.', 'The horizon opens.'),
  LevelUnlock(22, 2, UnlockType.collectible, 'lvl_22', '🐚', 'Coquillage',
      'Seashell', 'Un souvenir du rivage.', 'A keepsake from the shore.'),
  LevelUnlock(23, 2, UnlockType.collectible, 'lvl_23', '🌊', 'La vague',
      'The wave', 'Apprends à surfer tes envies.', 'Learn to surf your urges.'),
  LevelUnlock(24, 2, UnlockType.collectible, 'lvl_24', '🦀', 'Le crabe',
      'The crab', 'Avance, même de côté.', 'Move forward, even sideways.'),
  LevelUnlock(25, 2, UnlockType.badge, 'badge_regularity', '🎖️', 'Régularité',
      'Consistency', '25 niveaux de constance.', '25 levels of steadiness.'),
  LevelUnlock(26, 2, UnlockType.collectible, 'lvl_26', '🏖️', 'Parasol',
      'Beach umbrella', 'Prends le temps de souffler.', 'Take time to breathe.'),
  LevelUnlock(27, 2, UnlockType.collectible, 'lvl_27', '🐬', 'Le dauphin',
      'The dolphin', 'La joie nage à tes côtés.', 'Joy swims beside you.'),
  LevelUnlock(28, 2, UnlockType.feature, 'stats_advanced', '📈',
      'Stats avancées', 'Advanced stats', 'Tendances et comparaisons.', 'Trends and comparisons.'),
  LevelUnlock(29, 2, UnlockType.collectible, 'lvl_29', '🪸', 'Le corail',
      'The coral', 'La beauté pousse en silence.', 'Beauty grows in silence.'),
  LevelUnlock(30, 2, UnlockType.collectible, 'lvl_30', '🛟', 'La bouée',
      'The life ring', 'Tes boucliers te protègent.', 'Your shields protect you.'),
  LevelUnlock(31, 2, UnlockType.citronState, 'skin_tropical', '🌺',
      'Teinte tropicale', 'Tropical tint', 'Des couleurs d\'été à enfiler.', 'Summer colors to wear.'),
  LevelUnlock(32, 2, UnlockType.lore, 'lvl_32', '🌅', 'Lever de soleil marin',
      'Sea sunrise', 'Un jour nouveau, plus clair.', 'A new, clearer day.'),
  LevelUnlock(33, 2, UnlockType.citronState, 'skin_crown', '👑', 'Couronne',
      'Crown', 'La royauté se mérite.', 'Royalty is earned.'),
  LevelUnlock(34, 2, UnlockType.collectible, 'lvl_34', '🦭', 'Le phoque',
      'The seal', 'Repose-toi sans culpabilité.', 'Rest without guilt.'),
  LevelUnlock(35, 2, UnlockType.collectible, 'lvl_35', '🗺️', 'Carte au trésor',
      'Treasure map', 'Ton cap se précise.', 'Your course sharpens.'),
  LevelUnlock(36, 2, UnlockType.collectible, 'lvl_36', '🐙', 'La pieuvre',
      'The octopus', 'Tu gères tout d\'une main.', 'You handle it all at once.'),
  LevelUnlock(37, 2, UnlockType.lore, 'lvl_37', '🌬️', 'Vent favorable',
      'Fair wind', 'Tes habitudes te portent.', 'Your habits carry you.'),
  LevelUnlock(38, 2, UnlockType.collectible, 'lvl_38', '🏝️', 'Île secrète',
      'Secret island', 'Une escale rien qu\'à toi.', 'A stop just for you.'),
  LevelUnlock(39, 2, UnlockType.collectible, 'lvl_39', '🫧', 'Perle rare',
      'Rare pearl', 'Le fruit de ta patience.', 'The fruit of your patience.'),
  LevelUnlock(40, 2, UnlockType.badge, 'badge_coast', '🏆', 'Maître de la Côte',
      'Coast Master', 'L\'océan derrière toi.', 'The ocean behind you.'),

  // ---------------------------------------------------------------------------
  // Chapitre 3 — Les Sommets (41-60) ⛰️
  // ---------------------------------------------------------------------------
  LevelUnlock(41, 3, UnlockType.lore, 'lvl_41', '🥾', 'Vers les sommets',
      'To the peaks', 'La pente monte, toi aussi.', 'The slope rises, so do you.'),
  LevelUnlock(42, 3, UnlockType.collectible, 'lvl_42', '🧭', 'La boussole',
      'The compass', 'Garde ton cap.', 'Keep your bearing.'),
  LevelUnlock(43, 3, UnlockType.collectible, 'lvl_43', '❄️', 'Premier flocon',
      'First snowflake', 'La fraîcheur te réveille.', 'The cold wakes you up.'),
  LevelUnlock(44, 3, UnlockType.collectible, 'lvl_44', '⛺', 'La tente',
      'The tent', 'Un abri pour tes nuits.', 'Shelter for your nights.'),
  LevelUnlock(45, 3, UnlockType.collectible, 'lvl_45', '🪨', 'Le rocher',
      'The boulder', 'Solide, comme toi.', 'Solid, like you.'),
  LevelUnlock(46, 3, UnlockType.lore, 'lvl_46', '🌲', 'Forêt de pins',
      'Pine forest', 'Respire, tu es sur la bonne voie.', 'Breathe, you\'re on track.'),
  LevelUnlock(47, 3, UnlockType.citronState, 'skin_frost', '❄️', 'Givre',
      'Frost tint', 'Un éclat glacé des sommets.', 'An icy glow from the peaks.'),
  LevelUnlock(48, 3, UnlockType.collectible, 'lvl_48', '🔥', 'Feu de camp',
      'Campfire', 'Une chaleur qui rassure.', 'A reassuring warmth.'),
  LevelUnlock(49, 3, UnlockType.collectible, 'lvl_49', '🪕', 'Chanson du soir',
      'Evening song', 'Célèbre le chemin parcouru.', 'Honor the road traveled.'),
  LevelUnlock(50, 3, UnlockType.collectible, 'lvl_50', '🏔️', 'Mi-parcours',
      'Halfway', 'La moitié du voyage !', 'Halfway through the journey!'),
  LevelUnlock(51, 3, UnlockType.collectible, 'lvl_51', '🦅', 'L\'aigle',
      'The eagle', 'Tu prends de la hauteur.', 'You rise above.'),
  LevelUnlock(52, 3, UnlockType.collectible, 'lvl_52', '🌸', 'Edelweiss',
      'Edelweiss', 'Rare, comme ta volonté.', 'Rare, like your resolve.'),
  LevelUnlock(53, 3, UnlockType.lore, 'lvl_53', '🌫️', 'Au-dessus des nuages',
      'Above the clouds', 'La clarté revient.', 'Clarity returns.'),
  LevelUnlock(54, 3, UnlockType.collectible, 'lvl_54', '🧗', 'Le grimpeur',
      'The climber', 'Une prise après l\'autre.', 'One hold at a time.'),
  LevelUnlock(55, 3, UnlockType.collectible, 'lvl_55', '🏕️', 'Camp de base',
      'Base camp', 'Prépare le grand sommet.', 'Ready for the summit.'),
  LevelUnlock(56, 3, UnlockType.collectible, 'lvl_56', '🐐', 'Le bouquetin',
      'The ibex', 'Sûr de chaque pas.', 'Sure of every step.'),
  LevelUnlock(57, 3, UnlockType.lore, 'lvl_57', '🌄', 'Aube alpine',
      'Alpine dawn', 'Le plus dur est derrière.', 'The hardest part is behind.'),
  LevelUnlock(58, 3, UnlockType.citronState, 'skin_gold', '✨', 'Citron doré',
      'Golden lemon', 'L\'éclat des longs voyages.', 'The shine of long journeys.'),
  LevelUnlock(59, 3, UnlockType.collectible, 'lvl_59', '🚩', 'Le drapeau',
      'The flag', 'Plante-le, tu y es presque.', 'Plant it, you\'re almost there.'),
  LevelUnlock(60, 3, UnlockType.badge, 'badge_peaks', '🏆', 'Maître des Sommets',
      'Peaks Master', 'Au sommet du monde.', 'On top of the world.'),

  // ---------------------------------------------------------------------------
  // Chapitre 4 — La Ville (61-80) 🌃
  // ---------------------------------------------------------------------------
  LevelUnlock(61, 4, UnlockType.lore, 'lvl_61', '🌆', 'Lumières de la ville',
      'City lights', 'Un nouveau rythme.', 'A new rhythm.'),
  LevelUnlock(62, 4, UnlockType.collectible, 'lvl_62', '🚕', 'Le taxi jaune',
      'Yellow cab', 'À la couleur du citron.', 'Lemon-colored, of course.'),
  LevelUnlock(63, 4, UnlockType.collectible, 'lvl_63', '☕', 'Café du coin',
      'Corner café', 'Un rituel sans alcool.', 'A ritual without alcohol.'),
  LevelUnlock(64, 4, UnlockType.collectible, 'lvl_64', '🎷', 'Jazz de rue',
      'Street jazz', 'La nuit peut être douce.', 'Nights can be gentle.'),
  LevelUnlock(65, 4, UnlockType.collectible, 'lvl_65', '🏙️', 'Gratte-ciel',
      'Skyscraper', 'Tu vises toujours plus haut.', 'You aim ever higher.'),
  LevelUnlock(66, 4, UnlockType.lore, 'lvl_66', '🌃', 'Soirée sans verre',
      'Drink-free night', 'Tu profites, sans regret.', 'You enjoy it, no regrets.'),
  LevelUnlock(67, 4, UnlockType.collectible, 'lvl_67', '🎟️', 'Le ticket',
      'The ticket', 'Une sortie mémorable.', 'A night to remember.'),
  LevelUnlock(68, 4, UnlockType.collectible, 'lvl_68', '💡', 'Néon citron',
      'Lemon neon', 'Ta lumière à toi.', 'Your very own glow.'),
  LevelUnlock(69, 4, UnlockType.collectible, 'lvl_69', '🎧', 'Le casque',
      'Headphones', 'Ta bande-son du voyage.', 'Your journey\'s soundtrack.'),
  LevelUnlock(70, 4, UnlockType.collectible, 'lvl_70', '🌉', 'Le grand pont',
      'The great bridge', 'Tu relies tes mondes.', 'You bridge your worlds.'),
  LevelUnlock(71, 4, UnlockType.citronState, 'skin_neon', '💜', 'Néon',
      'Neon tint', 'La ville s\'illumine sur toi.', 'The city lights up on you.'),
  LevelUnlock(72, 4, UnlockType.lore, 'lvl_72', '🪩', 'La piste',
      'The dance floor', 'Danser, lucide et léger.', 'Dance, clear and light.'),
  LevelUnlock(73, 4, UnlockType.collectible, 'lvl_73', '📸', 'Polaroïd',
      'Polaroid', 'Capture les bons moments.', 'Capture the good moments.'),
  LevelUnlock(74, 4, UnlockType.collectible, 'lvl_74', '🌹', 'La rose',
      'The rose', 'La beauté en pleine ville.', 'Beauty in the heart of the city.'),
  LevelUnlock(75, 4, UnlockType.collectible, 'lvl_75', '🎆', 'Feu d\'artifice',
      'Fireworks', 'Célèbre le niveau 75 !', 'Celebrate level 75!'),
  LevelUnlock(76, 4, UnlockType.citronState, 'skin_batman', '🦇',
      'Chevalier Noir', 'Dark Knight', 'Le citron veille sur la ville.', 'The lemon watches over the city.'),
  LevelUnlock(77, 4, UnlockType.collectible, 'lvl_77', '📻', 'Vinyle rare',
      'Rare vinyl', 'Un classique de ton histoire.', 'A classic of your story.'),
  LevelUnlock(78, 4, UnlockType.lore, 'lvl_78', '🌙', 'Nuit calme',
      'Quiet night', 'Le repos est une victoire.', 'Rest is a victory.'),
  LevelUnlock(79, 4, UnlockType.collectible, 'lvl_79', '🗽', 'Le monument',
      'The monument', 'Ton parcours fait référence.', 'Your journey stands tall.'),
  LevelUnlock(80, 4, UnlockType.badge, 'badge_city', '🏆', 'Maître de la Ville',
      'City Master', 'Les lumières s\'inclinent.', 'The city bows to you.'),

  // ---------------------------------------------------------------------------
  // Chapitre 5 — Les Étoiles (81-100) 🌌
  // ---------------------------------------------------------------------------
  LevelUnlock(81, 5, UnlockType.lore, 'lvl_81', '🚀', 'Décollage', 'Lift-off',
      'Au-delà du connu.', 'Beyond the known.'),
  LevelUnlock(82, 5, UnlockType.collectible, 'lvl_82', '🪐', 'La planète',
      'The planet', 'Un monde à toi.', 'A world of your own.'),
  LevelUnlock(83, 5, UnlockType.collectible, 'lvl_83', '☄️', 'La comète',
      'The comet', 'Tu files, lumineux.', 'You streak by, luminous.'),
  LevelUnlock(84, 5, UnlockType.citronState, 'skin_dark', '🌑', 'Mode nuit',
      'Night mode', 'Un citron des étoiles.', 'A lemon of the stars.'),
  LevelUnlock(85, 5, UnlockType.collectible, 'lvl_85', '⭐', 'Étoile filante',
      'Shooting star', 'Fais un vœu, tiens-le.', 'Make a wish, then keep it.'),
  LevelUnlock(86, 5, UnlockType.collectible, 'lvl_86', '🌖', 'Phase de lune',
      'Moon phase', 'Tes cycles te guident.', 'Your cycles guide you.'),
  LevelUnlock(87, 5, UnlockType.lore, 'lvl_87', '🌠', 'Champ d\'étoiles',
      'Star field', 'Tu n\'es plus le même.', 'You\'re not the same anymore.'),
  LevelUnlock(88, 5, UnlockType.collectible, 'lvl_88', '🛰️', 'Le satellite',
      'The satellite', 'Tu gardes le contrôle.', 'You stay in control.'),
  LevelUnlock(89, 5, UnlockType.collectible, 'lvl_89', '👨‍🚀', 'L\'explorateur',
      'The explorer', 'Pionnier de ta vie.', 'Pioneer of your own life.'),
  LevelUnlock(90, 5, UnlockType.collectible, 'lvl_90', '🌌', 'La galaxie',
      'The galaxy', 'Immense, comme ton chemin.', 'Vast, like your path.'),
  LevelUnlock(91, 5, UnlockType.citronState, 'skin_cosmic', '🌌', 'Cosmique',
      'Cosmic tint', 'Les étoiles colorent ton fruit.', 'The stars color your fruit.'),
  LevelUnlock(92, 5, UnlockType.lore, 'lvl_92', '🌜', 'Sérénité cosmique',
      'Cosmic calm', 'Le calme t\'habite.', 'Calm lives within you.'),
  LevelUnlock(93, 5, UnlockType.collectible, 'lvl_93', '💫', 'Poussière d\'étoiles',
      'Stardust', 'Tu brilles de l\'intérieur.', 'You shine from within.'),
  LevelUnlock(94, 5, UnlockType.collectible, 'lvl_94', '🌈', 'Aurore', 'Aurora',
      'Des couleurs après la nuit.', 'Colors after the night.'),
  LevelUnlock(95, 5, UnlockType.collectible, 'lvl_95', '🪐', 'Les anneaux',
      'The rings', 'La grâce de l\'expérience.', 'The grace of experience.'),
  LevelUnlock(96, 5, UnlockType.collectible, 'lvl_96', '🛸', 'Le vaisseau',
      'The starship', 'Tu mènes l\'équipage.', 'You lead the crew.'),
  LevelUnlock(97, 5, UnlockType.lore, 'lvl_97', '🕯️', 'Lumière intérieure',
      'Inner light', 'Ta plus belle source.', 'Your finest source.'),
  LevelUnlock(98, 5, UnlockType.collectible, 'lvl_98', '🌟', 'Super-nova',
      'Supernova', 'Une énergie rare.', 'A rare energy.'),
  LevelUnlock(99, 5, UnlockType.collectible, 'lvl_99', '🏵️', 'Médaille d\'étoile',
      'Star medal', 'Plus qu\'un pas.', 'Just one step to go.'),
  LevelUnlock(100, 5, UnlockType.badge, 'badge_master', '👑', 'Citron Légendaire',
      'Legendary Lemon', 'Le voyage d\'une vie.', 'The journey of a lifetime.'),
];
