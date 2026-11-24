import 'package:material_ui/material_ui.dart';

import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  final Map<String, String> t;
  final VoidCallback onThemeToggle;
  final VoidCallback onLanguageToggle;
  final Locale locale;
  final ThemeMode themeMode;
  final VoidCallback onNavigateToChat;

  const HomeScreen({
    super.key,
    required this.t,
    required this.onThemeToggle,
    required this.onLanguageToggle,
    required this.locale,
    required this.themeMode,
    required this.onNavigateToChat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomScrollView(
      slivers: [
        // App Bar Section
        SliverAppBar(
          floating: true,
          pinned: true,
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Row(
            children: [
              Image.asset(
                'assets/images/app_logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['appName']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: isDark ? Colors.white : const Color(0xFF7F1212),
                    ),
                  ),
                  Text(
                    t['govText']!.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Language Toggle Button
            TextButton(
              onPressed: onLanguageToggle,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: Colors.grey.withAlpha((0.3 * 255).toInt()),
                  ),
                ),
              ),
              child: Text(
                locale.languageCode == 'en' ? 'தமிழ்' : 'English',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF7F1212),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Theme Mode Toggle
            IconButton(
              tooltip:
                  isDark
                      ? (t['lightMode'] ?? 'Light Mode')
                      : (t['darkMode'] ?? 'Dark Mode'),
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: isDark ? Colors.amber : Colors.grey.shade700,
              ),
              onPressed: onThemeToggle,
            ),
            const SizedBox(width: 8),
          ],
        ),
        // Welcome / Search / Hero Card Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Digital Hero Badge & Slogan
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF7F1212,
                    ).withAlpha((0.08 * 255).toInt()),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.security,
                        size: 14,
                        color: Color(0xFF7F1212),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t['govText']!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7F1212),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Core Tamil Nadu Slogan (Tamil font styled)
                Text(
                  t['heroTamilTop']!,
                  style: TextStyle(
                    fontSize: 26,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF7F1212),
                  ),
                ),
                Text(
                  t['heroTamilBottom']!,
                  style: const TextStyle(
                    fontSize: 26,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t['heroSubtitle']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),

                const SizedBox(height: 24),
                // Main Launch Assistant Card (Branded Gradient)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7F1212), Color(0xFFA81D1D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF7F1212,
                        ).withAlpha((0.3 * 255).toInt()),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(
                                (0.15 * 255).toInt(),
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.smart_toy,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              t['aiLiveBadge'] ?? 'AI LIVE',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF7F1212),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t['welcomeTitle']!,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t['welcomeDesc']!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withAlpha((0.85 * 255).toInt()),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: onNavigateToChat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: const Color(0xFF7F1212),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              t['launchCta']!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Section: Popular Scheme Categories
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t['categoriesTitle']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.grid_view, size: 16, color: Colors.grey),
                  ],
                ),
                Text(
                  t['categoriesSubtitle']!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            delegate: SliverChildListDelegate([
              _buildCategoryCard(
                context,
                title: t['agriTitle']!,
                desc: t['agriDesc']!,
                icon: Icons.agriculture,
                color: Colors.green,
                url: 'https://www.tnagrisnet.tn.gov.in/people_app/GoScheme',
              ),
              _buildCategoryCard(
                context,
                title: t['eduTitle']!,
                desc: t['eduDesc']!,
                icon: Icons.school,
                color: Colors.blue,
                url: 'https://naanmudhalvan.tnschools.gov.in/schemes',
              ),
              _buildCategoryCard(
                context,
                title: t['healthTitle']!,
                desc: t['healthDesc']!,
                icon: Icons.favorite,
                color: Colors.red,
                url: 'https://www.tnhsp.org/',
              ),
              _buildCategoryCard(
                context,
                title: t['seniorTitle']!,
                desc: t['seniorDesc']!,
                icon: Icons.elderly,
                color: Colors.orange,
                url: 'https://chennai.nic.in/oap-eligibility/',
              ),
            ]),
          ),
        ),
        // Section: Trending News & Announcements
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 28.0,
              bottom: 10.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t['newsTitle']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 3,
                        backgroundColor: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t['liveBadge'] ?? 'LIVE',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Horizontal News Slider
        SliverToBoxAdapter(
          child: SizedBox(
            height: 190,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildNewsCard(
                  context,
                  category: t['womenWelfareNewsCat'] ?? 'WOMEN WELFARE',
                  title:
                      locale.languageCode == 'en'
                          ? 'Pudhumai Penn Scheme Expansion'
                          : 'புதுமை பெண் திட்டம் விரிவாக்கம்',
                  date: t['latestUpdate'] ?? 'Latest update',
                  gradient: const [Color(0xFF6B117A), Color(0xFF9C27B0)],
                ),
                _buildNewsCard(
                  context,
                  category: t['welfareNewsCat'] ?? 'WELFARE',
                  title:
                      locale.languageCode == 'en'
                          ? 'Kalaignar Magalir Urimai Thittam Updates'
                          : 'கலைஞர் மகளிர் உரிமைத் திட்டம் புதிய தகவல்கள்',
                  date: t['latestUpdate'] ?? 'Latest update',
                  gradient: const [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                ),
              ],
            ),
          ),
        ),
        // Footer Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 36.0,
              horizontal: 24.0,
            ),
            child: Column(
              children: [
                const Divider(height: 1),
                const SizedBox(height: 24),
                Image.asset(
                  'assets/images/app_logo.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                Text(
                  t['footerText']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required String url,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        debugPrint('Attempting to launch URL: $url');
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint('Successfully launched $url');
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t['linkError'] ?? 'Unable to open link')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withAlpha((0.15 * 255).toInt()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(
                  Icons.arrow_outward,
                  size: 15,
                  color:
                      isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF064E3B),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.3,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  t['linkExplore'] ?? 'Explore Portal',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF064E3B),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  size: 12,
                  color:
                      isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF064E3B),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(
    BuildContext context, {
    required String category,
    required String title,
    required String date,
    required List<Color> gradient,
  }) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withAlpha((0.25 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.newspaper,
              size: 130,
              color: Colors.white.withAlpha((0.08 * 255).toInt()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.2 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withAlpha((0.7 * 255).toInt()),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white.withAlpha((0.9 * 255).toInt()),
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
