/// Maps a subject/deck title to one of the real Mozaik subject icon
/// assets (lib/assests/images/Mozaik_Expanded_Subject_Icon_Assets/subjects/*.png) by keyword matching.
/// These are designed illustrations, not a generic icon font — per the
/// asset pack's own guidance, the same asset should be used consistently
/// for a given subject everywhere in the app, never recolored per-card.
///
/// Supports both English and Arabic subject titles, since real subjects
/// in this app are entered in Arabic (e.g. "بيولوجيا الخلية").
///
/// Falls back to a generic "education" tile when nothing matches, so a
/// subject with an unrecognized name never renders blank.
String subjectIconAsset(String title) {
  final t = title.toLowerCase();

  // Ordered by specificity — more specific keywords are checked first
  // so e.g. "biochemistry" doesn't just match generic "chemistry" logic
  // in an unhelpful order. Arabic and English keywords both map to the
  // same underlying icon slug.
  const mapping = <String, String>{
    // Medical / pre-med — mapped to the closest available real subject art
    'pharmacology': 'medicine',
    'pharma': 'medicine',
    'صيدل': 'medicine',
    'pathology': 'medicine',
    'أمراض': 'medicine',
    'radiology': 'medicine',
    'أشعة': 'medicine',
    'surgery': 'medicine',
    'جراح': 'medicine',
    'clinical': 'medicine',
    'سريري': 'medicine',
    'immunology': 'medicine',
    'مناعة': 'medicine',
    'microbiology': 'biology',
    'أحياء دقيقة': 'biology',
    'anatomy': 'biology',
    'تشريح': 'biology',
    'physiology': 'biology',
    'وظائف الأعضاء': 'biology',
    'فيزيولوجيا': 'biology',
    'biochemistry': 'chemistry',
    'كيمياء حيوية': 'chemistry',
    'genetics': 'genetics',
    'وراثة': 'genetics',
    'جينات': 'genetics',
    'psychiatry': 'psychology',
    'نفسي': 'psychology',
    'psychology': 'psychology',
    'علم النفس': 'psychology',
    'medicine': 'medicine',
    'medical': 'medicine',
    'طب': 'medicine',
    'health': 'health',
    'صحة': 'health',

    // Core sciences
    'biology': 'biology',
    'بيولوجيا': 'biology',
    'أحياء': 'biology',
    'chemistry': 'chemistry',
    'كيمياء': 'chemistry',
    'physics': 'physics',
    'فيزياء': 'physics',
    'science': 'science',
    'علوم': 'science',

    // Languages
    'english': 'english',
    'إنجليزي': 'english',
    'انجليزي': 'english',
    'arabic': 'arabic_language',
    'عربي': 'arabic_language',
    'language': 'languages',
    'لغ': 'languages',

    // Math
    'mathematics': 'math',
    'math': 'math',
    'رياضيات': 'math',

    // Other common subjects
    'business': 'business',
    'أعمال': 'business',
    'history': 'history',
    'تاريخ': 'history',
    'geography': 'geography',
    'جغرافيا': 'geography',
    'economics': 'economics',
    'اقتصاد': 'economics',
    'literature': 'literature',
    'أدب': 'literature',
    'writing': 'writing',
    'كتابة': 'writing',
    'general knowledge': 'general_knowledge',
    'معرفة عامة': 'general_knowledge',
    'technology': 'technology',
    'تقنية': 'technology',
    'computer': 'computer-science',
    'حاسوب': 'computer-science',
    'coding': 'coding',
    'برمجة': 'coding',
    'programming': 'coding',
    'engineering': 'engineering',
    'هندسة': 'engineering',
    'art': 'arts',
    'فن': 'arts',
  };

  // Match the longest (most specific) keyword found, not just the first
  // one in list order. Short generic substrings like "طب" (appears
  // inside both "الطبية" = medical/adjective and "الطب" = medicine)
  // would otherwise win over a more specific keyword like "فيزياء"
  // purely by accident of which entry happens to be listed first.
  String? bestMatch;
  String? bestSlug;
  for (final entry in mapping.entries) {
    if (t.contains(entry.key)) {
      if (bestMatch == null || entry.key.length > bestMatch.length) {
        bestMatch = entry.key;
        bestSlug = entry.value;
      }
    }
  }

  if (bestSlug != null) {
    return 'lib/assests/images/Mozaik_Expanded_Subject_Icon_Assets/subjects/$bestSlug.png';
  }

  return 'lib/assests/images/Mozaik_Expanded_Subject_Icon_Assets/subjects/education.png';
}

/// Nocturne (night mode) medical artwork. Returns null when the title has no
/// matching medical icon, so callers keep their existing leading widget.
String? nocturneMedicalIcon(String title) {
  final t = title.toLowerCase();
  const map = <String, List<String>>{
    'icon-ribcage': ['تشريح', 'anatomy', 'skeleton', 'عظام'],
    'icon-brain-medical': ['أعصاب', 'عصب', 'neuro', 'brain', 'دماغ'],
    'icon-stethoscope': ['باطن', 'سريري', 'internal', 'clinical', 'medicine'],
    'icon-microscope': ['نسج', 'أنسجة', 'histology', 'physiology', 'فيزيولوجيا', 'وظائف'],
    'icon-first-aid': ['جراح', 'surgery', 'إسعاف', 'emergency', 'first aid'],
    'icon-dna': ['وراثة', 'جينات', 'genetic', 'dna', 'كيمياء حيوية', 'biochem'],
    'icon-microbes': ['أحياء دقيقة', 'جراثيم', 'micro', 'مناعة', 'immun'],
    'icon-pill-bottle': ['أدوية', 'صيدل', 'pharma', 'drug'],
    'icon-mri-scanner': ['أشعة', 'radiology', 'imaging', 'mri'],
    'icon-iv-bag': ['أمراض', 'pathology', 'تمريض', 'nursing'],
  };
  for (final e in map.entries) {
    if (e.value.any(t.contains)) {
      return 'lib/assests/nocturne/medical/${e.key}.png';
    }
  }
  return null;
}
