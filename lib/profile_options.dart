// ─────────────────────────────────────────────
// SAKTI Profile Data & Options
// Matches webapp profileOptions.js exactly
// ─────────────────────────────────────────────

class ProfileData {
  String fullName;
  String age;
  String gender;
  String district;
  String occupation;
  String educationLevel;
  String annualIncome;
  String disabilityStatus;
  String farmerStatus;
  String studentStatus;
  List<String> specialCategories;
  String institutionType;
  String currentClassYear;
  String courseDegree;

  ProfileData({
    this.fullName = '',
    this.age = '',
    this.gender = '',
    this.district = '',
    this.occupation = '',
    this.educationLevel = '',
    this.annualIncome = '',
    this.disabilityStatus = 'No',
    this.farmerStatus = 'No',
    this.studentStatus = 'No',
    List<String>? specialCategories,
    this.institutionType = '',
    this.currentClassYear = '',
    this.courseDegree = '',
  }) : specialCategories = specialCategories ?? [];

  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'age': age,
      'gender': gender,
      'district': district,
      'occupation': occupation,
      'education_level': educationLevel,
      'annual_income': annualIncome,
      'disability_status': disabilityStatus,
      'farmer_status': farmerStatus,
      'student_status': studentStatus,
      'special_categories': specialCategories,
      'institution_type': institutionType,
      'current_class_year': currentClassYear,
      'course_degree': courseDegree,
    };
  }

  factory ProfileData.fromMap(Map<String, dynamic> map) {
    return ProfileData(
      fullName: map['full_name']?.toString() ?? '',
      age: map['age']?.toString() ?? '',
      gender: map['gender']?.toString() ?? '',
      district: map['district']?.toString() ?? '',
      occupation: map['occupation']?.toString() ?? '',
      educationLevel: map['education_level']?.toString() ?? '',
      annualIncome: map['annual_income']?.toString() ?? '',
      disabilityStatus: map['disability_status']?.toString() ?? 'No',
      farmerStatus: map['farmer_status']?.toString() ?? 'No',
      studentStatus: map['student_status']?.toString() ?? 'No',
      specialCategories: (map['special_categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      institutionType: map['institution_type']?.toString() ?? '',
      currentClassYear: map['current_class_year']?.toString() ?? '',
      courseDegree: map['course_degree']?.toString() ?? '',
    );
  }
}

class DistrictOption {
  final String value;
  final String en;
  final String ta;
  const DistrictOption({required this.value, required this.en, required this.ta});
}

const List<DistrictOption> kDistricts = [
  DistrictOption(value: "Ariyalur", en: "Ariyalur", ta: "அரியலூர்"),
  DistrictOption(value: "Chengalpattu", en: "Chengalpattu", ta: "செங்கல்பட்டு"),
  DistrictOption(value: "Chennai", en: "Chennai", ta: "சென்னை"),
  DistrictOption(value: "Coimbatore", en: "Coimbatore", ta: "கோயம்புத்தூர்"),
  DistrictOption(value: "Cuddalore", en: "Cuddalore", ta: "கடலூர்"),
  DistrictOption(value: "Dharmapuri", en: "Dharmapuri", ta: "தருமபுரி"),
  DistrictOption(value: "Dindigul", en: "Dindigul", ta: "திண்டுக்கல்"),
  DistrictOption(value: "Erode", en: "Erode", ta: "ஈரோடு"),
  DistrictOption(value: "Kallakurichi", en: "Kallakurichi", ta: "கள்ளக்குறிச்சி"),
  DistrictOption(value: "Kanchipuram", en: "Kanchipuram", ta: "காஞ்சிபுரம்"),
  DistrictOption(value: "Kanyakumari", en: "Kanyakumari", ta: "கன்னியாகுமரி"),
  DistrictOption(value: "Karur", en: "Karur", ta: "கரூர்"),
  DistrictOption(value: "Krishnagiri", en: "Krishnagiri", ta: "கிருஷ்ணகிரி"),
  DistrictOption(value: "Madurai", en: "Madurai", ta: "மதுரை"),
  DistrictOption(value: "Mayiladuthurai", en: "Mayiladuthurai", ta: "மயிலாடுதுறை"),
  DistrictOption(value: "Nagapattinam", en: "Nagapattinam", ta: "நாகப்பட்டினம்"),
  DistrictOption(value: "Namakkal", en: "Namakkal", ta: "நாமக்கல்"),
  DistrictOption(value: "Nilgiris", en: "Nilgiris", ta: "நீலகிரி"),
  DistrictOption(value: "Perambalur", en: "Perambalur", ta: "பெரம்பலூர்"),
  DistrictOption(value: "Pudukkottai", en: "Pudukkottai", ta: "புதுக்கோட்டை"),
  DistrictOption(value: "Ramanathapuram", en: "Ramanathapuram", ta: "இராமநாதபுரம்"),
  DistrictOption(value: "Ranipet", en: "Ranipet", ta: "இராணிப்பேட்டை"),
  DistrictOption(value: "Salem", en: "Salem", ta: "சேலம்"),
  DistrictOption(value: "Sivaganga", en: "Sivaganga", ta: "சிவகங்கை"),
  DistrictOption(value: "Tenkasi", en: "Tenkasi", ta: "தென்காசி"),
  DistrictOption(value: "Thanjavur", en: "Thanjavur", ta: "தஞ்சாவூர்"),
  DistrictOption(value: "Theni", en: "Theni", ta: "தேனி"),
  DistrictOption(value: "Thoothukudi", en: "Thoothukudi", ta: "தூத்துக்குடி"),
  DistrictOption(value: "Tiruchirappalli", en: "Tiruchirappalli", ta: "திருச்சிராப்பள்ளி"),
  DistrictOption(value: "Tirunelveli", en: "Tirunelveli", ta: "திருநெல்வேலி"),
  DistrictOption(value: "Tirupathur", en: "Tirupathur", ta: "திருப்பத்தூர்"),
  DistrictOption(value: "Tiruppur", en: "Tiruppur", ta: "திருப்பூர்"),
  DistrictOption(value: "Tiruvallur", en: "Tiruvallur", ta: "திருவள்ளூர்"),
  DistrictOption(value: "Tiruvannamalai", en: "Tiruvannamalai", ta: "திருவண்ணாமலை"),
  DistrictOption(value: "Tiruvarur", en: "Tiruvarur", ta: "திருவாரூர்"),
  DistrictOption(value: "Vellore", en: "Vellore", ta: "வேலூர்"),
  DistrictOption(value: "Viluppuram", en: "Viluppuram", ta: "விழுப்புரம்"),
  DistrictOption(value: "Virudhunagar", en: "Virudhunagar", ta: "விருதுநகர்"),
];

class LabelOption {
  final String value;
  final String en;
  final String ta;
  const LabelOption({required this.value, required this.en, required this.ta});
}

const List<LabelOption> kOccupations = [
  LabelOption(value: "Farmer", en: "Farmer / Agriculture", ta: "விவசாயி / விவசாயம்"),
  LabelOption(value: "Student", en: "Student", ta: "மாணவர்"),
  LabelOption(value: "Self-Employed", en: "Business Owner / Self-Employed", ta: "வணிகர் / சுயதொழில்"),
  LabelOption(value: "Private Sector", en: "Private Sector Employee", ta: "தனியார் துறை ஊழியர்"),
  LabelOption(value: "Government Sector", en: "Government Sector Employee", ta: "அரசு துறை ஊழியர்"),
  LabelOption(value: "Laborer", en: "Daily Wage Worker / Laborer", ta: "தினக்கூலி தொழிலாளி"),
  LabelOption(value: "Retired", en: "Retired", ta: "ஓய்வு பெற்றவர்"),
  LabelOption(value: "Unemployed", en: "Unemployed / Homemaker", ta: "வேலையில்லாதவர் / இல்லத்தரசி"),
  LabelOption(value: "Other", en: "Other", ta: "இதர"),
];

const List<LabelOption> kIncomeRanges = [
  LabelOption(value: "Below ₹1,00,000", en: "Below ₹1,00,000", ta: "₹1,00,000-க்கு கீழ்"),
  LabelOption(value: "₹1,00,000 - ₹3,00,000", en: "₹1,00,000 - ₹3,00,000", ta: "₹1,00,000 - ₹3,00,000"),
  LabelOption(value: "₹3,00,000 - ₹5,00,000", en: "₹3,00,000 - ₹5,00,000", ta: "₹3,00,000 - ₹5,00,000"),
  LabelOption(value: "₹5,00,000 - ₹8,00,000", en: "₹5,00,000 - ₹8,00,000", ta: "₹5,00,000 - ₹8,00,000"),
  LabelOption(value: "₹8,00,000 - ₹12,00,000", en: "₹8,00,000 - ₹12,00,000", ta: "₹8,00,000 - ₹12,00,000"),
  LabelOption(value: "Above ₹12,00,000", en: "Above ₹12,00,000", ta: "₹12,00,000-க்கு மேல்"),
];

const List<LabelOption> kEducationLevels = [
  LabelOption(value: "Below 10th", en: "Below 10th Standard", ta: "10-ஆம் வகுப்புக்கு கீழ்"),
  LabelOption(value: "10th Pass", en: "10th Standard (SSLC)", ta: "10-ஆம் வகுப்பு (SSLC) தேர்ச்சி"),
  LabelOption(value: "12th Pass", en: "12th Standard (HSC)", ta: "12-ஆம் வகுப்பு (HSC) தேர்ச்சி"),
  LabelOption(value: "Diploma", en: "Diploma / ITI", ta: "டிப்ளமோ / ITI"),
  LabelOption(value: "Undergraduate", en: "Undergraduate Degree (Bachelor's)", ta: "இளங்கலை பட்டம் (UG)"),
  LabelOption(value: "Postgraduate", en: "Postgraduate Degree (Master's / Ph.D.)", ta: "முதுகலை பட்டம் (PG / Ph.D.)"),
  LabelOption(value: "Illiterate", en: "No Formal Education", ta: "முறையான கல்வி இல்லை"),
];

const List<LabelOption> kSpecialCategories = [
  LabelOption(value: "Widow / Widower", en: "Widow / Widower", ta: "விதவை / கணவனை இழந்தவர்"),
  LabelOption(value: "Senior Citizen", en: "Senior Citizen (60+)", ta: "மூத்த குடிமகன் (60+)"),
  LabelOption(value: "Differently Abled", en: "Differently Abled", ta: "மாற்றுத்திறனாளி"),
  LabelOption(value: "Pregnant Woman", en: "Pregnant Woman", ta: "கர்ப்பிணி பெண்"),
  LabelOption(value: "Lactating Mother", en: "Lactating Mother", ta: "பாலூட்டும் தாய்"),
  LabelOption(value: "Single Woman", en: "Single Woman", ta: "தனித்து வாழும் பெண்"),
  LabelOption(value: "Destitute Woman", en: "Destitute Woman", ta: "ஆதரவற்ற பெண்"),
  LabelOption(value: "Orphan", en: "Orphan", ta: "அனாதை / ஆதரவற்ற குழந்தை"),
  LabelOption(value: "Ex-serviceman", en: "Ex-serviceman", ta: "முன்னாள் ராணுவத்தினர்"),
  LabelOption(value: "Transgender", en: "Transgender", ta: "திருநங்கை / திருநம்பி"),
  LabelOption(value: "Farmer", en: "Farmer", ta: "விவசாயி"),
  LabelOption(value: "Fisherfolk", en: "Fisherfolk", ta: "மீனவர்"),
  LabelOption(value: "Weaver", en: "Weaver", ta: "நெசவாளர்"),
  LabelOption(value: "Artisan", en: "Artisan", ta: "கைவினைஞர்"),
  LabelOption(value: "Street Vendor", en: "Street Vendor", ta: "தெரு வியாபாரி"),
  LabelOption(value: "Construction Worker", en: "Construction Worker", ta: "கட்டுமான தொழிலாளி"),
];

const List<LabelOption> kInstitutionTypes = [
  LabelOption(value: "Government School", en: "Government School", ta: "அரசு பள்ளி"),
  LabelOption(value: "Government-Aided School", en: "Government-Aided School", ta: "அரசு உதவி பெறும் பள்ளி"),
  LabelOption(value: "Private School", en: "Private School", ta: "தனியார் பள்ளி"),
  LabelOption(value: "Government College", en: "Government College", ta: "அரசு கல்லூரி"),
  LabelOption(value: "Government-Aided College", en: "Government-Aided College", ta: "அரசு உதவி பெறும் கல்லூரி"),
  LabelOption(value: "Private College", en: "Private College", ta: "தனியார் கல்லூரி"),
];
