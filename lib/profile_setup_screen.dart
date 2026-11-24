import 'package:material_ui/material_ui.dart';
import 'profile_options.dart';

// ─────────────────────────────────────────────
// SAKTI Profile Setup / Onboarding Wizard
// Multi-step signup wizard (Step 1: Identity, Step 2: Location/Background, Step 3: Eligibility)
// ─────────────────────────────────────────────

class ProfileSetupScreen extends StatefulWidget {
  final Map<String, String> t;
  final Locale locale;
  final Function(ProfileData) onComplete;
  final VoidCallback? onCancel;

  const ProfileSetupScreen({
    super.key,
    required this.t,
    required this.locale,
    required this.onComplete,
    this.onCancel,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int _step = 1;
  final _fullNameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _classYearCtrl = TextEditingController();
  final _courseDegreeCtrl = TextEditingController();

  String _gender = '';
  String _district = '';
  String _educationLevel = '';
  String _annualIncome = '';
  String _occupation = '';
  String _institutionType = '';
  String _farmerStatus = 'No';
  String _disabilityStatus = 'No';
  String _studentStatus = 'No';
  final List<String> _specialCategories = [];

  String? _error;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _ageCtrl.dispose();
    _classYearCtrl.dispose();
    _courseDegreeCtrl.dispose();
    super.dispose();
  }

  bool get _isTa => widget.locale.languageCode == 'ta';

  void _handleOccupationChange(String? val) {
    if (val == null) return;
    setState(() {
      _occupation = val;
      if (val == 'Farmer') {
        _farmerStatus = 'Yes';
        if (!_specialCategories.contains('Farmer')) {
          _specialCategories.add('Farmer');
        }
      } else if (val == 'Student') {
        _studentStatus = 'Yes';
      } else {
        if (_studentStatus == 'Yes') {
          _studentStatus = 'No';
          _institutionType = '';
          _classYearCtrl.clear();
          _courseDegreeCtrl.clear();
        }
      }
    });
  }

  void _handleCategoryToggle(String catVal) {
    setState(() {
      if (_specialCategories.contains(catVal)) {
        _specialCategories.remove(catVal);
      } else {
        _specialCategories.add(catVal);
      }
      if (catVal == 'Farmer') {
        _farmerStatus = _specialCategories.contains('Farmer') ? 'Yes' : 'No';
      }
      if (catVal == 'Differently Abled') {
        _disabilityStatus =
            _specialCategories.contains('Differently Abled') ? 'Yes' : 'No';
      }
    });
  }

  void _nextStep() {
    setState(() => _error = null);
    if (_step == 1) {
      if (_fullNameCtrl.text.trim().isEmpty) {
        setState(
          () =>
              _error =
                  _isTa
                      ? 'உங்கள் முழு பெயரை உள்ளிடவும்'
                      : 'Please enter your full name',
        );
        return;
      }
      setState(() => _step = 2);
    } else if (_step == 2) {
      if (_district.isEmpty) {
        setState(
          () =>
              _error =
                  _isTa
                      ? 'உங்கள் மாவட்டத்தை தேர்ந்தெடுக்கவும்'
                      : 'Please select your district',
        );
        return;
      }
      setState(() => _step = 3);
    } else if (_step == 3) {
      final profile = ProfileData(
        fullName: _fullNameCtrl.text.trim(),
        age: _ageCtrl.text.trim(),
        gender: _gender,
        district: _district,
        occupation: _occupation,
        educationLevel: _educationLevel,
        annualIncome: _annualIncome,
        disabilityStatus: _disabilityStatus,
        farmerStatus: _farmerStatus,
        studentStatus: _studentStatus,
        specialCategories: _specialCategories,
        institutionType: _institutionType,
        currentClassYear: _classYearCtrl.text.trim(),
        courseDegree: _courseDegreeCtrl.text.trim(),
      );
      widget.onComplete(profile);
    }
  }

  void _prevStep() {
    if (_step > 1) {
      setState(() {
        _error = null;
        _step--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _step / 3.0;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF7F1212),
          ),
          onPressed: () {
            if (_step > 1) {
              _prevStep();
            } else if (widget.onCancel != null) {
              widget.onCancel!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _isTa ? 'சுயவிவரப் பதிவு' : 'Profile Setup Wizard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF7F1212),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor:
                isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7F1212)),
            minHeight: 4,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isTa ? 'படி $_step / 3' : 'Step $_step of 3',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: const Color(0xFF7F1212),
                    ),
                  ),
                  Text(
                    _step == 1
                        ? (_isTa ? 'அடிப்படை விவரங்கள்' : 'Identity')
                        : _step == 2
                        ? (_isTa
                            ? 'இருப்பிடம் & கல்வி'
                            : 'Location & Education')
                        : (_isTa
                            ? 'தகுதி & சிறப்புப் பிரிவுகள்'
                            : 'Eligibility & Categories'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _step == 1
                    ? (_isTa ? 'உங்கள் அடையாளம்' : 'Tell us about yourself')
                    : _step == 2
                    ? (_isTa
                        ? 'உங்கள் இருப்பிடம் மற்றும் பின்னணி'
                        : 'Location & Background')
                    : (_isTa
                        ? 'திட்ட தகுதி விவரங்கள்'
                        : 'Welfare Scheme Eligibility'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _step == 1
                    ? (_isTa
                        ? 'சரியான அரசு திட்டங்களை பரிந்துரைக்க உங்கள் பெயர் மற்றும் வயதை உள்ளிடவும்.'
                        : 'Enter your basic details so we can personalize welfare schemes for you.')
                    : _step == 2
                    ? (_isTa
                        ? 'மாவட்ட வாரியான மற்றும் வருமான அடிப்படையிலான திட்டங்களை கண்டறிய உதவுகிறது.'
                        : 'Helps match region-specific subsidies and scholarship criteria.')
                    : (_isTa
                        ? 'சிறப்பு பிரிவுகளை தேர்வு செய்து கூடுதல் நலத்திட்ட உதவிகளை கண்டறியுங்கள்.'
                        : 'Select categories you belong to for targeted welfare matching.'),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Error display
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── STEP 1 ──
              if (_step == 1) ...[
                _buildTextField(
                  isDark: isDark,
                  controller: _fullNameCtrl,
                  label: _isTa ? 'முழு பெயர் *' : 'Full Name *',
                  hint: _isTa ? 'எ.கா. காவ்யா ராமன்' : 'e.g. Kavya Raman',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  isDark: isDark,
                  controller: _ageCtrl,
                  label: _isTa ? 'வயது' : 'Age',
                  hint: _isTa ? 'எ.கா. 24' : 'e.g. 24',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildLabel(isDark, _isTa ? 'பாலினம்' : 'Gender'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildGenderChip(
                      isDark,
                      'Male',
                      _isTa ? 'ஆண்' : 'Male',
                      Icons.male,
                    ),
                    const SizedBox(width: 8),
                    _buildGenderChip(
                      isDark,
                      'Female',
                      _isTa ? 'பெண்' : 'Female',
                      Icons.female,
                    ),
                    const SizedBox(width: 8),
                    _buildGenderChip(
                      isDark,
                      'Transgender',
                      _isTa ? 'திருநங்கை' : 'Transgender',
                      Icons.transgender,
                    ),
                  ],
                ),
              ],

              // ── STEP 2 ──
              if (_step == 2) ...[
                _buildLabel(isDark, _isTa ? 'மாவட்டம் *' : 'District *'),
                const SizedBox(height: 6),
                _buildDistrictDropdown(isDark),
                const SizedBox(height: 16),
                _buildLabel(
                  isDark,
                  _isTa ? 'கல்வித் தகுதி' : 'Education Level',
                ),
                const SizedBox(height: 6),
                _buildDropdown(
                  isDark: isDark,
                  value: _educationLevel.isEmpty ? null : _educationLevel,
                  hint:
                      _isTa
                          ? 'கல்வித் தகுதியைத் தேர்ந்தெடுக்கவும்'
                          : 'Select education level',
                  items:
                      kEducationLevels
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.value,
                              child: Text(
                                _isTa ? e.ta : e.en,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (val) => setState(() => _educationLevel = val ?? ''),
                ),
                const SizedBox(height: 16),
                _buildLabel(
                  isDark,
                  _isTa ? 'ஆண்டு வருமானம்' : 'Annual Family Income',
                ),
                const SizedBox(height: 6),
                _buildDropdown(
                  isDark: isDark,
                  value: _annualIncome.isEmpty ? null : _annualIncome,
                  hint:
                      _isTa
                          ? 'வருமான வரம்பைத் தேர்ந்தெடுக்கவும்'
                          : 'Select annual income range',
                  items:
                      kIncomeRanges
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.value,
                              child: Text(
                                _isTa ? e.ta : e.en,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _annualIncome = val ?? ''),
                ),
                const SizedBox(height: 16),
                _buildLabel(isDark, _isTa ? 'தொழில்' : 'Occupation'),
                const SizedBox(height: 6),
                _buildDropdown(
                  isDark: isDark,
                  value: _occupation.isEmpty ? null : _occupation,
                  hint:
                      _isTa
                          ? 'தொழிலைத் தேர்ந்தெடுக்கவும்'
                          : 'Select occupation',
                  items:
                      kOccupations
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.value,
                              child: Text(
                                _isTa ? e.ta : e.en,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: _handleOccupationChange,
                ),
              ],

              // ── STEP 3 ──
              if (_step == 3) ...[
                if (_occupation == 'Student' || _studentStatus == 'Yes') ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF7F1212,
                      ).withAlpha((0.06 * 255).toInt()),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(
                          0xFF7F1212,
                        ).withAlpha((0.2 * 255).toInt()),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.school,
                              size: 18,
                              color: Color(0xFF7F1212),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isTa
                                  ? 'மாணவர் கூடுதல் விவரங்கள்'
                                  : 'Student Specifics',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7F1212),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          isDark: isDark,
                          value:
                              _institutionType.isEmpty
                                  ? null
                                  : _institutionType,
                          hint:
                              _isTa
                                  ? 'கல்வி நிறுவன வகை'
                                  : 'Select institution type',
                          items:
                              kInstitutionTypes
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.value,
                                      child: Text(
                                        _isTa ? e.ta : e.en,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) =>
                                  setState(() => _institutionType = val ?? ''),
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          isDark: isDark,
                          controller: _classYearCtrl,
                          label:
                              _isTa
                                  ? 'தற்போதைய வகுப்பு / ஆண்டு'
                                  : 'Current Class / Year',
                          hint:
                              _isTa
                                  ? 'எ.கா. 12-ஆம் வகுப்பு'
                                  : 'e.g. 12th Std, 3rd Year',
                          icon: Icons.calendar_today_outlined,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          isDark: isDark,
                          controller: _courseDegreeCtrl,
                          label: _isTa ? 'படிப்பு / பட்டம்' : 'Course / Degree',
                          hint:
                              _isTa
                                  ? 'எ.கா. B.Sc. இயற்பியல்'
                                  : 'e.g. B.Sc Physics',
                          icon: Icons.book_outlined,
                        ),
                      ],
                    ),
                  ),
                ],

                _buildLabel(
                  isDark,
                  _isTa
                      ? 'சிறப்பு தகுதிப் பிரிவுகள் (பொருந்துபவற்றைத் தேர்ந்தெடுக்கவும்)'
                      : 'Special Welfare Categories (Select all that apply)',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      kSpecialCategories.map((cat) {
                        final isSelected = _specialCategories.contains(
                          cat.value,
                        );
                        return FilterChip(
                          selected: isSelected,
                          label: Text(_isTa ? cat.ta : cat.en),
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color:
                                isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade800),
                          ),
                          selectedColor: const Color(0xFF7F1212),
                          backgroundColor:
                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? const Color(0xFF7F1212)
                                      : (isDark
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade300),
                            ),
                          ),
                          onSelected: (_) => _handleCategoryToggle(cat.value),
                        );
                      }).toList(),
                ),
              ],

              const SizedBox(height: 36),

              // Navigation Buttons
              Row(
                children: [
                  if (_step > 1)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color:
                                isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isTa ? 'பின்செல்' : 'Back',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  if (_step > 1) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7F1212),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _step == 3
                                ? (_isTa
                                    ? 'பதிவை முடிக்கவும்'
                                    : 'Complete Setup')
                                : (_isTa ? 'அடுத்த படி' : 'Continue'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _step == 3
                                ? Icons.check_circle
                                : Icons.arrow_forward,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(bool isDark, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
      ),
    );
  }

  Widget _buildTextField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(isDark, label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade500),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF7F1212),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderChip(
    bool isDark,
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = _gender == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _gender = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? const Color(0xFF7F1212)
                    : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
                      ? const Color(0xFF7F1212)
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color:
                      isSelected
                          ? Colors.white
                          : (isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _district.isEmpty ? null : _district,
          hint: Text(
            _isTa ? 'மாவட்டத்தைத் தேர்ந்தெடுக்கவும்' : 'Select district',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          items:
              kDistricts
                  .map(
                    (d) => DropdownMenuItem(
                      value: d.value,
                      child: Text(
                        _isTa ? d.ta : d.en,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (val) => setState(() => _district = val ?? ''),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required bool isDark,
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
