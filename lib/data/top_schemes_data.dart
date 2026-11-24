// lib/data/top_schemes_data.dart
//
// SAKTI — Top 5 Flagship Government Schemes of Tamil Nadu
// Curated bilingual scheme information mirroring the webapp frontend format.

class TopScheme {
  final String id;
  final String titleEn;
  final String titleTa;
  final String summaryEn;
  final String summaryTa;
  final String benefitsPreviewEn;
  final String benefitsPreviewTa;
  final String fullDescriptionEn;
  final String fullDescriptionTa;
  final String fullBenefitsEn;
  final String fullBenefitsTa;
  final String eligibilityEn;
  final String eligibilityTa;
  final String applicationProcessEn;
  final String applicationProcessTa;
  final String documentsRequiredEn;
  final String documentsRequiredTa;
  final String officialUrl;

  const TopScheme({
    required this.id,
    required this.titleEn,
    required this.titleTa,
    required this.summaryEn,
    required this.summaryTa,
    required this.benefitsPreviewEn,
    required this.benefitsPreviewTa,
    required this.fullDescriptionEn,
    required this.fullDescriptionTa,
    required this.fullBenefitsEn,
    required this.fullBenefitsTa,
    required this.eligibilityEn,
    required this.eligibilityTa,
    required this.applicationProcessEn,
    required this.applicationProcessTa,
    required this.documentsRequiredEn,
    required this.documentsRequiredTa,
    required this.officialUrl,
  });

  String title(String lang) => lang == 'ta' ? titleTa : titleEn;
  String summary(String lang) => lang == 'ta' ? summaryTa : summaryEn;
  String benefitsPreview(String lang) =>
      lang == 'ta' ? benefitsPreviewTa : benefitsPreviewEn;
  String fullDescription(String lang) =>
      lang == 'ta' ? fullDescriptionTa : fullDescriptionEn;
  String fullBenefits(String lang) =>
      lang == 'ta' ? fullBenefitsTa : fullBenefitsEn;
  String eligibility(String lang) =>
      lang == 'ta' ? eligibilityTa : eligibilityEn;
  String applicationProcess(String lang) =>
      lang == 'ta' ? applicationProcessTa : applicationProcessEn;
  String documentsRequired(String lang) =>
      lang == 'ta' ? documentsRequiredTa : documentsRequiredEn;
}

class TopSchemesRepository {
  static const List<TopScheme> top5Schemes = [
    // 1. Kalaignar Magalir Urimai Thittam
    TopScheme(
      id: "101",
      titleEn: "Kalaignar Magalir Urimai Thittam",
      titleTa: "கலைஞர் மகளிர் உரிமைத் திட்டம்",
      summaryEn:
          "A pioneering social security initiative providing monthly basic income assistance of ₹1,000 to women heads of eligible households to recognize their unpaid care work and achieve economic self-reliance.",
      summaryTa:
          "குடும்பத்திற்காக உழைக்கும் பெண்களின் உழைப்பை அங்கீகரிக்கும் வகையில் தகுதிவாய்ந்த குடும்பத் தலைவிகளுக்கு மாதம் ₹1,000 அடிப்படை உரிமைத்தொகை வங்கி கணக்கில் நேரடியாக செலுத்தும் வரலாற்றுச் சிறப்புமிக்க நலத்திட்டம்.",
      benefitsPreviewEn:
          "₹1,000 direct bank transfer (DBT) every month on the 15th, financial independence, economic empowerment for over 1.15 Crore families.",
      benefitsPreviewTa:
          "ஒவ்வொரு மாதமும் 15-ஆம் தேதி ₹1,000 நேரடி வங்கிப் பரிமாற்றம் (DBT), பெண்களின் பொருளாதார தன்னிறைவு மற்றும் குடும்ப வாழ்வாதார மேம்பாடு.",
      fullDescriptionEn:
          "Kalaignar Magalir Urimai Thittam is a landmark social justice scheme launched by the Government of Tamil Nadu. It provides financial security of ₹1,000 every month directly to the bank account of women who are the primary caretakers of their families, enhancing their decision-making power and financial autonomy.",
      fullDescriptionTa:
          "கலைஞர் மகளிர் உரிமைத் திட்டம் தமிழக அரசால் தொடங்கப்பட்ட ஒரு மகத்தான சமூகநீதித் திட்டம். குடும்பத்தின் தலைமைப் பொறுப்பில் உள்ள தகுதியுடைய பெண்களுக்கு மாதந்தோறும் ₹1,000 உரிமைத்தொகை அவர்களின் வங்கிக் கணக்கில் நேரடியாக வரவு வைக்கப்படுகிறது.",
      fullBenefitsEn:
          "• Monthly financial assistance of ₹1,000 credited on the 15th of every month.<br>• Unconditional digital direct benefit transfer (DBT) via Aadhaar-linked bank accounts.<br>• Enhanced nutrition, educational support for children, and micro-savings enablement.<br>• Over 1.15 Crore women enrolled across all 38 districts of Tamil Nadu.",
      fullBenefitsTa:
          "• மாதந்தோறும் ₹1,000 உதவித்தொகை பயனாளியின் வங்கிக் கணக்கில் நேரடியாக வரவு வைக்கப்படும்.<br>• ஆதாருடன் இணைக்கப்பட்ட வங்கிக் கணக்கு மூலம் இடைத்தரகர்கள் இன்றி வெளிப்படையான பணப் பரிமாற்றம்.<br>• குடும்பத்தின் அத்தியாவசிய தேவைகள், குழந்தைகளின் கல்வி மற்றும் பெண்களின் சுயமரியாதை மேம்பாடு.<br>• தமிழ்நாடு முழுவதும் 1.15 கோடிக்கும் மேற்பட்ட பெண்கள் பயன்பெறுகின்றனர்.",
      eligibilityEn:
          "• Woman head of the family aged 21 years or above.<br>• Family annual income must be below ₹2.5 Lakhs.<br>• Family landholding must be less than 5 acres of wetland or 10 acres of dryland.<br>• Annual domestic electricity consumption must not exceed 3,600 units.<br>• Family members should not be government employees or income tax payees.",
      eligibilityTa:
          "• 21 வயது பூர்த்தியடைந்த குடும்பத் தலைவிகள்.<br>• குடும்பத்தின் ஆண்டு வருமானம் ₹2.5 லட்சத்திற்குள் இருக்க வேண்டும்.<br>• குடும்பத்திற்கு 5 ஏக்கருக்கு குறைவான நன்செய் நிலம் அல்லது 10 ஏக்கருக்கு குறைவான புன்செய் நிலம் இருக்க வேண்டும்.<br>• ஆண்டு மின்சாரப் பயன்பாடு 3,600 யூனிட்டுகளுக்குள் இருக்க வேண்டும்.<br>• குடும்பத்தில் அரசு ஊழியர்களோ அல்லது வருமான வரி செலுத்துபவர்களோ இருக்கக் கூடாது.",
      applicationProcessEn:
          "1. Obtain and fill the application form distributed at ration shops in your area.<br>2. Attend the designated e-Sevai / biometric camp in your revenue ward with original documents.<br>3. Aadhaar biometric fingerprint / OTP authentication is completed on spot.<br>4. SMS status updates sent to the registered mobile number upon field verification and approval.",
      applicationProcessTa:
          "1. உங்கள் நியாயவிலைக் கடையில் வழங்கப்படும் விண்ணப்பப் படிவத்தைப் பெற்று பூர்த்தி செய்யவும்.<br>2. உங்கள் பகுதியில் அறிவிக்கப்படும் சிறப்பு முகாமில் அசல் ஆவணங்களுடன் பங்கேற்கவும்.<br>3. பயோமெட்ரிக் கைரேகை அல்லது ஆதார் OTP மூலம் சரிபார்ப்பு மேற்கொள்ளப்படும்.<br>4. கள ஆய்வுக்குப் பின் ஒப்புதல் குறுஞ்செய்தி மூலம் பதிவு செய்யப்பட்ட அலைபேசிக்கு அனுப்பப்படும்.",
      documentsRequiredEn:
          "• Smart Family Ration Card (குடும்ப அட்டை)<br>• Aadhaar Card of the applicant<br>• Bank Passbook (linked with Aadhaar & active DBT)<br>• Recent domestic electricity bill or consumer number",
      documentsRequiredTa:
          "• குடும்ப அட்டை (Smart Ration Card)<br>• விண்ணப்பதாரரின் ஆதார் அட்டை<br>• வங்கி கணக்குப் புத்தகம் (ஆதாருடன் இணைக்கப்பட்ட கணக்கு)<br>• மின்சார கட்டண ரசீது அல்லது நுகர்வோர் எண்",
      officialUrl: "https://www.tn.gov.in",
    ),

    // 2. Pudhumai Penn Thittam
    TopScheme(
      id: "102",
      titleEn: "Pudhumai Penn Thittam (Higher Education Assurance Scheme)",
      titleTa:
          "புதுமைப் பெண் திட்டம் (மூவலூர் ராமாமிர்தம் அம்மையார் உயர்கல்வி உறுதி திட்டம்)",
      summaryEn:
          "Moovalur Ramamirtham Ammaiyar Higher Education Assurance Scheme provides ₹1,000 per month financial assistance to female students who studied from classes 6 to 12 in government schools to complete undergraduate degree, diploma, or ITI courses without interruption.",
      summaryTa:
          "அரசுப் பள்ளிகளில் 6 முதல் 12-ஆம் வகுப்பு வரை பயின்று கல்லூரி அல்லது தொழிற்கல்வி சேரும் மாணவிகளுக்கு மாதம் ₹1,000 நிதியுதவி வழங்கும் தமிழக அரசின் முதன்மை திட்டம்.",
      benefitsPreviewEn:
          "₹1,000 monthly allowance credited till completion of UG degree/diploma/ITI, higher enrollment and graduation rates for girl students.",
      benefitsPreviewTa:
          "இளநிலைப் பட்டம், பட்டயப் படிப்பு முடியும் வரை மாணவிகளின் வங்கிக் கணக்கில் மாதம் ₹1,000 வரவு, பெண்களின் உயர்கல்வி இடைநிற்றல் முற்றிலும் தடுப்பு.",
      fullDescriptionEn:
          "To promote girl child education, prevent early marriages, and empower women through higher qualifications, the Government of Tamil Nadu provides financial assistance of ₹1,000 per month to female students who pursued their schooling in state government schools.",
      fullDescriptionTa:
          "பெண் குழந்தைகளின் கல்வியை ஊக்குவிக்கவும், குழந்தை திருமணங்களைத் தடுக்கவும், பெண்கள் உயர்கல்வி பெற்று தன்னம்பிக்கையுடன் வாழவும் தமிழ்நாடு அரசு இத்திட்டத்தின் கீழ் மாணவிகளுக்கு மாதம் ₹1,000 உதவித்தொகை வழங்கி வருகிறது.",
      fullBenefitsEn:
          "• ₹1,000 credited every month into the student's individual bank account.<br>• Covers all Undergraduate Degrees (B.A., B.Sc., B.Com, B.E., MBBS), Polytechnics, and ITI courses.<br>• Financial support provided for the entire standard duration of the chosen academic programme.",
      fullBenefitsTa:
          "• மாணவிகளின் தனிப்பட்ட வங்கிக் கணக்கில் நேரடியாக மாதம் ₹1,000 வரவு வைக்கப்படும்.<br>• கலை, அறிவியல், பொறியியல், மருத்துவம், பாலிடெக்னிக் மற்றும் ஐடிஐ படிப்புகளுக்கு இச்சலுகை பொருந்தும்.<br>• படிப்பு முடியும் வரை முழு கல்வி காலத்திற்கும் உதவித்தொகை தொடர்ந்து வழங்கப்படும்.",
      eligibilityEn:
          "• Female students who studied continuously from Classes 6 to 12 in Tamil Nadu Government Schools.<br>• Enrolled in any recognized college, university, polytechnic, or ITI institution in Tamil Nadu.<br>• No annual family income ceiling is applicable.",
      eligibilityTa:
          "• தமிழ்நாட்டில் உள்ள அரசுப் பள்ளிகளில் 6 முதல் 12-ஆம் வகுப்பு வரை தொடர்ந்து படித்த மாணவிகள்.<br>• அங்கீகரிக்கப்பட்ட உயர்கல்வி நிறுவனங்கள், பாலிடெக்னிக் அல்லது ஐடிஐ-யில் முதலாமாண்டு சேர்க்கை பெற்றிருக்க வேண்டும்.<br>• இத்திட்டத்திற்கு குடும்ப வருமான வரம்பு ஏதும் இல்லை.",
      applicationProcessEn:
          "1. Students do not need to visit government offices; application is processed at their college.<br>2. Submit school TC and 10th/12th marksheets to the College Nodal Officer.<br>3. College verifies school education via EMIS database and submits the application on the Pudhumai Penn portal.<br>4. Funds are disbursed directly to verified bank accounts.",
      applicationProcessTa:
          "1. மாணவிகள் எங்கும் அலையத் தேவையில்லை; கல்லூரியிலேயே விண்ணப்பம் பெறப்படும்.<br>2. பள்ளி மாற்றுச் சான்றிதழ் (TC) மற்றும் மதிப்பெண் சான்றிதழை கல்லூரி ஒருங்கிணைப்பாளரிடம் சமர்ப்பிக்கவும்.<br>3. கல்லூரி நிர்வாகம் EMIS தரவுத்தளம் மூலம் சரிபார்த்து புதுமைப் பெண் தளத்தில் பதிவேற்றம் செய்யும்.<br>4. ஒப்புதலுக்குப் பின் வங்கி கணக்கிற்கு நிதி பரிமாற்றம் செய்யப்படும்.",
      documentsRequiredEn:
          "• School Transfer Certificate (TC) certifying study from 6th to 12th in govt school<br>• 10th and 12th Marksheets<br>• College ID card & Bonafide / Admission Receipt<br>• Student's Individual Bank Account Passbook & Aadhaar Card",
      documentsRequiredTa:
          "• அரசுப் பள்ளி படிப்புச் சான்றிதழ் (TC - 6 முதல் 12-ஆம் வகுப்பு வரை)<br>• 10 மற்றும் 12-ஆம் வகுப்பு மதிப்பெண் பட்டியல்கள்<br>• கல்லூரி சேர்க்கை ரசீது & அடையாள அட்டை<br>• மாணவியின் தனிப்பட்ட வங்கிக் கணக்குப் புத்தகம் மற்றும் ஆதார் அட்டை",
      officialUrl: "https://www.pudhumaipenn.tn.gov.in",
    ),

    // 3. Chief Minister's Comprehensive Health Insurance Scheme (CMCHIS)
    TopScheme(
      id: "103",
      titleEn:
          "Chief Minister's Comprehensive Health Insurance Scheme (CMCHIS)",
      titleTa: "முதலமைச்சரின் விரிவான மருத்துவக் காப்பீட்டுத் திட்டம் (CMCHIS)",
      summaryEn:
          "CMCHIS provides comprehensive cashless health insurance coverage up to ₹5,00,000 per family per year for secondary and tertiary inpatient care across 1,500+ empanelled hospitals in Tamil Nadu.",
      summaryTa:
          "தமிழ்நாட்டில் உள்ள அரசு மற்றும் 1,500-க்கும் மேற்பட்ட தனியார் மருத்துவமனைகளில் குடும்பத்திற்கு ஆண்டுக்கு ₹5,00,000 வரை கட்டணமில்லா அறுவை மற்றும் மருத்துவ சிகிச்சை அளிக்கும் விரிவான காப்பீட்டு திட்டம்.",
      benefitsPreviewEn:
          "Up to ₹5 Lakhs annual coverage per family, covers 1,090+ medical procedures, cashless hospitalization and diagnostic coverage.",
      benefitsPreviewTa:
          "குடும்பத்திற்கு ஆண்டுக்கு ₹5,00,000 வரை பணமில்லா மருத்துவ சிகிச்சை, 1,090-க்கும் மேற்பட்ட அறுவை மற்றும் மருத்துவ சிகிச்சைகள், இலவச பரிசோதனைகள்.",
      fullDescriptionEn:
          "CMCHIS aims to provide quality healthcare to underprivileged families by providing cashless hospitalization benefits for specific illnesses and surgeries through empanelled government and private hospitals across Tamil Nadu.",
      fullDescriptionTa:
          "முதலமைச்சரின் விரிவான மருத்துவக் காப்பீட்டுத் திட்டம் ஏழை மற்றும் நடுத்தர குடும்பங்கள் எதிர்பாராத மருத்துவச் செலவுகளால் பாதிக்கப்படாமல் இருக்க, அரசு மற்றும் தனியார் மருத்துவமனைகளில் தரமான உயர் சிகிச்சை பெற வழிவகுக்கிறது.",
      fullBenefitsEn:
          "• Cashless coverage up to ₹5,00,000 per family per year.<br>• Covers 1,090 specialized medical procedures, 52 follow-up therapies, and 8 diagnostic packages.<br>• Includes oncology (cancer), cardiovascular surgeries, organ transplants, and NICU neonate care.<br>• Free medicines and food provided during inpatient hospital stay.",
      fullBenefitsTa:
          "• குடும்பத்திற்கு ஆண்டுக்கு ₹5,00,000 வரை பணமில்லா உயர் மருத்துவ காப்பீடு.<br>• 1,090 குறிப்பிட்ட சிகிச்சைகள், 52 தொடர் சிகிச்சைகள் மற்றும் 8 முழுப் பரிசோதனை தொகுப்புகள்.<br>• இதய அறுவை சிகிச்சைகள், புற்றுநோய் சிகிச்சை, சிறுநீரக மாற்று அறுவை சிகிச்சை உள்ளிட்டவை அடங்கும்.<br>• உள்நோயாளி சிகிச்சையின் போது மருந்துகளும் உணவும் இலவசமாக வழங்கப்படும்.",
      eligibilityEn:
          "• Resident family of Tamil Nadu.<br>• Annual family income less than ₹1,20,000 (as certified by VAO/Revenue authorities).<br>• Must be enrolled in the Tamil Nadu Smart Ration Card database.<br>• Sri Lankan Tamil refugees living in camps are also eligible.",
      eligibilityTa:
          "• தமிழ்நாட்டில் வசிக்கும் குடும்பங்கள்.<br>• குடும்பத்தின் ஆண்டு வருமானம் ₹1,20,000-க்கு குறைவாக இருக்க வேண்டும்.<br>• குடும்ப அட்டை (Smart Ration Card) பெற்றிருக்க வேண்டும்.<br>• முகாம்களில் வசிக்கும் இலங்கைத் தமிழர்களுக்கும் இத்திட்டம் பொருந்தும்.",
      applicationProcessEn:
          "1. Obtain Income Certificate from Village Administrative Officer (VAO) or apply on e-Sevai.<br>2. Visit the District CMCHIS Kiosk located at District Collectorate or Government Medical College Hospital.<br>3. Submit Smart Ration card, Aadhaar, and biometric photos.<br>4. CMCHIS Smart Card is issued on the spot.",
      applicationProcessTa:
          "1. கிராம நிர்வாக அலுவலர் (VAO) அல்லது இ-சேவை மூலம் வருமானச் சான்றிதழ் பெறவும்.<br>2. மாவட்ட ஆட்சியர் அலுவலகம் அல்லது அரசு மருத்துவமனையில் உள்ள முதலமைச்சர் காப்பீட்டு மையத்தை அணுகவும்.<br>3. குடும்ப அட்டை, ஆதார் மற்றும் குடும்ப உறுப்பினர்களின் புகைப்படங்களை பதிவு செய்யவும்.<br>4. உடனடியாக முதலமைச்சர் மருத்துவக் காப்பீட்டு அட்டை வழங்கப்படும்.",
      documentsRequiredEn:
          "• Smart Family Ration Card<br>• Income Certificate issued by Revenue Authority (below ₹1.2 Lakhs)<br>• Aadhaar cards of all family members<br>• Proof of residence",
      documentsRequiredTa:
          "• குடும்ப அட்டை (Smart Ration Card)<br>• வருமானச் சான்றிதழ் (ஆண்டு வருமானம் ₹1.2 லட்சத்திற்குள்)<br>• குடும்ப உறுப்பினர்கள் அனைவரின் ஆதார் அட்டைகள்<br>• இருப்பிடச் சான்று",
      officialUrl: "https://www.cmchistn.com",
    ),

    // 4. Naan Mudhalvan Scheme
    TopScheme(
      id: "104",
      titleEn: "Naan Mudhalvan Scheme (Skill Development Initiative)",
      titleTa: "நான் முதல்வன் திட்டம் (இளைஞர் திறன் மேம்பாட்டுத் திட்டம்)",
      summaryEn:
          "A dynamic flagship employment and skill readiness initiative by Tamil Nadu government providing industry-aligned technical training, competitive exam guidance, and direct industrial placement to collegiate students.",
      summaryTa:
          "ஆண்டுதோறும் 10 லட்சத்திற்கும் மேற்பட்ட கல்லூரி மாணவர்களுக்கு நவீன தொழில்நுட்பப் பயிற்சி, தொழில் முனைவோர் வழிகாட்டுதல் மற்றும் முன்னணி நிறுவன வேலைவாய்ப்பை வழங்கும் முன்மாதிரி திட்டம்.",
      benefitsPreviewEn:
          "Free access to premium courses in AI, Cloud, Cybersecurity, direct corporate recruitment drives, and civil service coaching with stipend.",
      benefitsPreviewTa:
          "AI, கிளவுட், சைபர் பாதுகாப்பு மற்றும் ரோபாட்டிக்ஸ் ஆகியவற்றில் இலவச தொழில்முறை சான்றிதழ் பயிற்சிகள் மற்றும் முன்னணி நிறுவன வேலைவாய்ப்பு முகாம்கள்.",
      fullDescriptionEn:
          "The 'Naan Mudhalvan' initiative aims to equip college students across engineering, arts, science, polytechnics, and ITIs with future-ready tech skills, digital fluency, and language proficiency to make Tamil Nadu youth globally competitive.",
      fullDescriptionTa:
          "நான் முதல்வன் திட்டம் தமிழ்நாடு முழுவதும் உள்ள பொறியியல், கலை, அறிவியல் மற்றும் தொழிற்கல்வி பயிலும் இளைஞர்களுக்கு உலகளாவிய போட்டிக்கு ஏற்ற தொழில்நுட்பத் திறன்கள், தகவல் தொடர்புத் திறன் மற்றும் உடனடி வேலைவாய்ப்பை பெற்றுத்தரும் நோக்குடன் செயல்படுத்தப்படுகிறது.",
      fullBenefitsEn:
          "• High-value technical training in partnership with Google, Microsoft, IBM, AWS, and Cambridge.<br>• Dedicated campus recruitment drives, skill hackathons, and corporate mentorship.<br>• Financial assistance of ₹7,500/month for civil service aspirants preparing for UPSC/TNPSC main exams.<br>• Career guidance portal with customized career pathways.",
      fullBenefitsTa:
          "• கூகுள், மைக்ரோசாப்ட், ஐபிஎம் போன்ற உலகத் தரம் வாய்ந்த நிறுவனங்களின் நேரடி பயிற்சி சான்றிதழ்கள்.<br>• கல்லூரிகளிலேயே சிறப்பு வேலைவாய்ப்பு முகாம்கள் மற்றும் தொழிற்துறை வழிகாட்டுதல்.<br>• யுபிஎஸ்சி முதன்மைத் தேர்வுக்கு தயாராகும் மாணவர்களுக்கு மாதம் ₹7,500 ஊக்கத்தொகை.<br>• எதிர்கால வேலைவாய்ப்புகளுக்கு ஏற்ற தனிப்பயனாக்கப்பட்ட தொழில் வழிகாட்டி தளம்.",
      eligibilityEn:
          "• Students enrolled in Government and Government-aided Engineering, Polytechnic, Arts & Science, and ITI institutions.<br>• Graduated youth of Tamil Nadu looking for upskilling and competitive exam coaching.<br>• No family income restrictions for standard college curriculum programs.",
      eligibilityTa:
          "• தமிழ்நாட்டில் உள்ள அரசு மற்றும் அரசு உதவிபெறும் பொறியியல், கலை, அறிவியல், பாலிடெக்னிக் மற்றும் ஐடிஐ மாணவர்கள்.<br>• திறன் மேம்பாடு மற்றும் போட்டித் தேர்வுகளுக்கு தயாராகும் தமிழ்நாட்டு பட்டதாரி இளைஞர்கள்.<br>• கல்லூரி பாடத்திட்ட பயிற்சிகளுக்கு வருமான வரம்பு ஏதும் இல்லை.",
      applicationProcessEn:
          "1. Register online on the Naan Mudhalvan Portal (naanmudhalvan.tnschools.gov.in).<br>2. Login with student registration credentials provided by your college.<br>3. Choose course tracks: AI/ML, Data Science, Full Stack, Robotics, or Civil Services.<br>4. Attend lab modules, earn digital credentials, and participate in campus job fairs.",
      applicationProcessTa:
          "1. naanmudhalvan.tnschools.gov.in என்ற இணையதளத்தில் பதிவு செய்யவும்.<br>2. கல்லூரி வழங்கிய பதிவு எண் மூலம் உள்நுழையவும்.<br>3. விருப்பமான பாடப்பிரிவுகள் (AI, Data Science, Web Development) அல்லது போட்டித் தேர்வு பயிற்சியை தேர்ந்தெடுக்கவும்.<br>4. பயிற்சிகளை முடித்து சான்றிதழ் பெற்று வேலைவாய்ப்பு முகாம்களில் கலந்து கொள்ளவும்.",
      documentsRequiredEn:
          "• College Student ID card & Registration Number<br>• Aadhaar Card<br>• Academic marksheets (10th, 12th, and current semester)<br>• Active email address and mobile number",
      documentsRequiredTa:
          "• கல்லூரி அடையாள அட்டை & பல்கலைக்கழக பதிவு எண்<br>• ஆதார் அட்டை<br>• கல்வி மதிப்பெண் பட்டியல்கள்<br>• பயன்பாட்டில் உள்ள மின்னஞ்சல் மற்றும் தொலைபேசி எண்",
      officialUrl: "https://naanmudhalvan.tnschools.gov.in",
    ),

    // 5. Kalaignar All Village Integrated Agriculture Development Programme
    TopScheme(
      id: "105",
      titleEn:
          "Kalaignar All Village Integrated Agriculture Development Programme",
      titleTa:
          "கலைஞரின் அனைத்து கிராம ஒருங்கிணைந்த வேளாண் வளர்ச்சி திட்டம்",
      summaryEn:
          "An integrated rural agriculture mission aimed at transforming fallow and dry lands into fertile cultivable fields, providing solar powered pumps, farm machinery subsidies, and quality seeds to rural farmers.",
      summaryTa:
          "கிராமங்களில் உள்ள தரிசு நிலங்களை விளைநிலங்களாக மாற்றி, சூரியசக்தி பம்புசெட்டுகள், நுண்ணீர்ப்பாசன வசதிகள் மற்றும் வேளாண் உபகரணங்களை மானியத்தில் வழங்கும் ஒருங்கிணைந்த திட்டம்.",
      benefitsPreviewEn:
          "Up to 70% subsidy on standalone Solar Agriculture Pump Sets, 100% subsidy on micro-irrigation for small/marginal farmers, free soil health cards.",
      benefitsPreviewTa:
          "சூரியசக்தி பம்புசெட்டுகளுக்கு 70% வரை அரசு மானியம், சிறு/குறு விவசாயிகளுக்கு 100% சொட்டுநீர்ப் பாசன மானியம், இலவச மண் பரிசோதனை அட்டை.",
      fullDescriptionEn:
          "This flagship scheme of the Tamil Nadu Agriculture Department integrates all major agricultural and allied government programs to develop all village panchayats into self-sufficient agricultural hubs, bringing fallow lands into active cultivation.",
      fullDescriptionTa:
          "தமிழ்நாடு வேளாண்மை மற்றும் உழவர் நலத்துறை மூலம் செயல்படுத்தப்படும் இத்திட்டம், அனைத்து கிராம ஊராட்சிகளிலும் தரிசு நிலங்களை விளைநிலங்களாக மாற்றி, நீர் ஆதாரங்களை பெருக்கி, உழவர்களின் வருமானத்தை இரட்டிப்பாக்கும் நோக்குடன் செயல்படுகிறது.",
      fullBenefitsEn:
          "• 70% capital subsidy on standalone Solar Agriculture Pumpsets (up to 10 HP).<br>• 100% subsidy on drip and sprinkler micro-irrigation for small and marginal farmers (75% for other farmers).<br>• Distribution of subsidized high-yielding seeds, coconut seedlings, and pulses kits.<br>• Free soil sample testing and distribution of Soil Health Cards.",
      fullBenefitsTa:
          "• விவசாயிகளுக்கு 70% மானியத்தில் சூரியசக்தியால் இயங்கும் மோட்டார் பம்புசெட்டுகள் (10 HP வரை).<br>• சிறு, குறு விவசாயிகளுக்கு 100% மானியத்தில் சொட்டுநீர் மற்றும் தெளிப்புநீர் பாசனக் கருவிகள்.<br>• மானிய விலையில் தரமான விதைகள், தென்னங்கன்றுகள் மற்றும் பயறு வகைகள் விநியோகம்.<br>• இலவச மண் பரிசோதனை செய்யப்பட்டு மண்வள அட்டை வழங்கப்படும்.",
      eligibilityEn:
          "• Small and marginal farmers holding land in selected Village Panchayats of Tamil Nadu.<br>• Farmers who possess valid Patta, Chitta, and Adangal documents.<br>• Farmer clusters willing to bring contiguous fallow land under active farming.",
      eligibilityTa:
          "• தமிழ்நாட்டில் தேர்வு செய்யப்பட்ட கிராம ஊராட்சிகளில் நிலம் வைத்துள்ள சிறு மற்றும் குறு விவசாயிகள்.<br>• பட்டா, சிட்டா மற்றும் அடங்கல் ஆவணங்களை வைத்திருக்க வேண்டும்.<br>• தரிசு நிலங்களை சாகுபடிக்கு கொண்டுவர விரும்பும் உழவர் குழுக்கள்.",
      applicationProcessEn:
          "1. Download and register on the 'Uzhavan Mobile App' or visit the Block Assistant Director of Agriculture Office.<br>2. Submit land Patta/Chitta and village administrative verification.<br>3. Field inspection conducted by Agriculture Officers.<br>4. Subsidy sanctioned and equipment installed at farm site.",
      applicationProcessTa:
          "1. 'உழவன் செயலி' (Uzhavan App) அல்லது வட்டார வேளாண்மை உதவி இயக்குநர் அலுவலகத்தில் விண்ணப்பிக்கவும்.<br>2. நிலத்தின் பட்டா, சிட்டா மற்றும் VAO சான்றிதழை சமர்ப்பிக்கவும்.<br>3. வேளாண்மைத் துறை அலுவலர்கள் நேரில் கள ஆய்வு மேற்கொள்வார்கள்.<br>4. மானியம் ஒப்புதல் அளிக்கப்பட்டு வேளாண் கருவிகள் வழங்கப்படும்.",
      documentsRequiredEn:
          "• Land Patta, Chitta, and Adangal extract<br>• Small / Marginal Farmer Certificate issued by VAO<br>• Aadhaar Card & Ration Card<br>• Bank Account Passbook",
      documentsRequiredTa:
          "• நிலத்தின் பட்டா, சிட்டா மற்றும் அடங்கல் நகல்<br>• சிறு / குறு விவசாயி சான்றிதழ் (VAO வழங்கியது)<br>• ஆதார் அட்டை மற்றும் குடும்ப அட்டை<br>• வங்கி கணக்குப் புத்தகம்",
      officialUrl: "https://www.tnagrisnet.tn.gov.in",
    ),
  ];

  static TopScheme? findById(String id) {
    try {
      return top5Schemes.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Format all top 5 schemes into the webapp HTML format
  static String formatTop5SchemesHtml(String language) {
    final isTa = language == 'ta';
    final lines = <String>[];

    if (isTa) {
      lines.add(
          "<strong>உங்களுக்கான 5 தொடர்புடைய திட்டங்களைக் கண்டறிந்துள்ளேன்:</strong><br>");
    } else {
      lines.add("<strong>I found 5 relevant schemes for you:</strong><br>");
    }

    for (int i = 0; i < top5Schemes.length; i++) {
      final s = top5Schemes[i];
      final title = s.title(language);
      final summary = s.summary(language);
      final benefits = s.benefitsPreview(language);
      final btnText = isTa ? "📖 முழு விவரங்களைப் பார்க்க" : "📖 View Full Details";
      final benefitLabel = isTa ? "முதன்மை பலன்கள்:" : "Key Benefits:";

      final schemeLines = <String>[
        "<strong>${i + 1}. $title</strong>",
        summary,
        if (benefits.isNotEmpty) "🎁 <strong>$benefitLabel</strong> $benefits",
        '<button class="scheme-btn" data-scheme-id="${s.id}" data-language="$language">$btnText</button>',
      ];

      lines.add(schemeLines.join("<br>"));
      lines.add("");
    }

    if (isTa) {
      lines.add(
          "<strong>முழு விவரங்களைப் பார்க்க எந்தத் திட்டத்தையும் கிளிக் செய்யவும்.</strong>");
    } else {
      lines.add(
          "<strong>Click on 'View Full Details' for any scheme to see complete information.</strong>");
    }

    return lines.join("<br>");
  }

  /// Format a single scheme in full details format (matching webapp chatbot.py format_full_scheme)
  static String formatFullSchemeHtml(TopScheme scheme, String language) {
    final isTa = language == 'ta';
    final title = scheme.title(language);
    final desc = scheme.fullDescription(language);
    final benefits = scheme.fullBenefits(language);
    final eligibility = scheme.eligibility(language);
    final application = scheme.applicationProcess(language);
    final documents = scheme.documentsRequired(language);
    final url = scheme.officialUrl;

    final descHeading = isTa ? "<h4>📋 விளக்கம்</h4>" : "<h4>📋 Description</h4>";
    final benHeading = isTa ? "<h4>🎁 பலன்கள்</h4>" : "<h4>🎁 Benefits</h4>";
    final eligHeading =
        isTa ? "<h4>✅ தகுதி விதிமுறைகள்</h4>" : "<h4>✅ Eligibility Criteria</h4>";
    final appHeading =
        isTa ? "<h4>📝 விண்ணப்ப செயல்முறை</h4>" : "<h4>📝 Application Process</h4>";
    final docHeading =
        isTa ? "<h4>📄 தேவையான ஆவணங்கள்</h4>" : "<h4>📄 Required Documents</h4>";
    final infoHeading =
        isTa ? "<h4>🔗 மேலும் தகவலுக்கு</h4>" : "<h4>🔗 More Information</h4>";

    final buffer = StringBuffer();
    buffer.write("<h3>📌 $title</h3>");
    buffer.write("<hr>");
    buffer.write("$descHeading<p>$desc</p>");
    buffer.write("$benHeading<p>$benefits</p>");
    buffer.write("$eligHeading<p>$eligibility</p>");
    buffer.write("$appHeading<p>$application</p>");
    buffer.write("$docHeading<p>$documents</p>");
    buffer.write(
        "$infoHeading<p><a href='$url' target='_blank'>$url</a></p>");

    return buffer.toString();
  }
}
