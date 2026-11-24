import 'package:material_ui/material_ui.dart';
import 'profile_options.dart';
import 'login_sheet.dart';
import 'profile_setup_screen.dart';

// ─────────────────────────────────────────────
// SAKTI Profile Screen
// Displays live user details if logged in,
// or provides a sign-in / setup trigger if guest.
// ─────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  final Map<String, String> t;
  final Locale locale;
  final ProfileData? userProfile;
  final Function(ProfileData?) onProfileUpdated;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.t,
    required this.locale,
    required this.userProfile,
    required this.onProfileUpdated,
    required this.onLogout,
  });

  bool get _isTa => locale.languageCode == 'ta';

  void _showLogin(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => LoginSignupSheet(
            isDark: isDark,
            t: t,
            locale: locale,
            onLoginSuccess: (profile) {
              onProfileUpdated(profile);
            },
          ),
    );
  }

  void _openEditProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (ctx) => ProfileSetupScreen(
              t: t,
              locale: locale,
              onComplete: (updated) {
                Navigator.of(ctx).pop();
                onProfileUpdated(updated);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isTa
                          ? 'சுயவிவரம் வெற்றிகரமாக புதுப்பிக்கப்பட்டது.'
                          : 'Profile updated successfully.',
                    ),
                    backgroundColor: const Color(0xFF7F1212),
                  ),
                );
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoggedIn = userProfile != null && userProfile!.fullName.isNotEmpty;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          t['profileTab'] ?? 'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF7F1212),
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF7F1212)),
              tooltip: t['editProfile'] ?? 'Edit Profile',
              onPressed: () => _openEditProfile(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ── Avatar & Name ──
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFF7F1212),
                    child: Icon(
                      isLoggedIn ? Icons.person : Icons.person_outline,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                  if (isLoggedIn)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD700),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Color(0xFF7F1212),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isLoggedIn
                  ? userProfile!.fullName
                  : (t['guestUser'] ?? 'Guest User'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              isLoggedIn
                  ? (userProfile!.district.isNotEmpty
                      ? '${userProfile!.district}, ${_isTa ? "தமிழ்நாடு" : "Tamil Nadu"}'
                      : (_isTa ? 'தமிழ்நாடு' : 'Tamil Nadu'))
                  : (t['notSignedIn'] ?? 'Not Signed In'),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // ── GUEST / SIGN-IN CALLOUT ──
            if (!isLoggedIn) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.03 * 255).toInt()),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 36,
                      color: Color(0xFF7F1212),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t['signInToViewProfile'] ??
                          'Sign in to access your profile and personalized welfare schemes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showLogin(context, isDark),
                        icon: const Icon(Icons.login, size: 18),
                        label: Text(t['signIn'] ?? 'Sign In'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7F1212),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // ── PROFILE DETAILS LIST ──
              _buildProfileItem(
                Icons.badge_outlined,
                t['fullName'] ?? 'Full Name',
                userProfile!.fullName,
              ),
              if (userProfile!.age.isNotEmpty)
                _buildProfileItem(
                  Icons.cake_outlined,
                  t['age'] ?? 'Age',
                  userProfile!.age,
                ),
              if (userProfile!.gender.isNotEmpty)
                _buildProfileItem(
                  Icons.transgender,
                  t['gender'] ?? 'Gender',
                  userProfile!.gender,
                ),
              if (userProfile!.district.isNotEmpty)
                _buildProfileItem(
                  Icons.location_on_outlined,
                  t['district'] ?? 'District',
                  userProfile!.district,
                ),
              if (userProfile!.occupation.isNotEmpty)
                _buildProfileItem(
                  Icons.work_outline,
                  t['occupation'] ?? 'Occupation',
                  userProfile!.occupation,
                ),
              if (userProfile!.educationLevel.isNotEmpty)
                _buildProfileItem(
                  Icons.school_outlined,
                  t['educationLevel'] ?? 'Education Level',
                  userProfile!.educationLevel,
                ),
              if (userProfile!.annualIncome.isNotEmpty)
                _buildProfileItem(
                  Icons.currency_rupee,
                  t['annualIncome'] ?? 'Annual Income',
                  userProfile!.annualIncome,
                ),
              if (userProfile!.specialCategories.isNotEmpty)
                _buildProfileItem(
                  Icons.stars_outlined,
                  t['specialCategories'] ?? 'Special Categories',
                  userProfile!.specialCategories.join(', '),
                ),

              const SizedBox(height: 24),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout, size: 18, color: Colors.red),
                  label: Text(
                    t['logout'] ?? 'Sign Out',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String val) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withAlpha((0.15 * 255).toInt())),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF7F1212).withAlpha((0.08 * 255).toInt()),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF7F1212), size: 18),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          val,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
