import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rayhan_erp/constants/app_theme.dart';
import 'package:rayhan_erp/constants/app_text.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  double _scrollOffset = 0;
  late final ScrollController _scrollCtrl;
  late final AnimationController _heroAnimCtrl;
  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()..addListener(_onScroll);
    _heroAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _heroFade = CurvedAnimation(
        parent: _heroAnimCtrl,
        curve: const Interval(0, 0.6, curve: Curves.easeOut));
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _heroAnimCtrl,
        curve: const Interval(0, 0.6, curve: Curves.easeOut)));
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _heroAnimCtrl.dispose();
    super.dispose();
  }

  void _onScroll() => setState(() => _scrollOffset = _scrollCtrl.offset);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollCtrl,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeroSection(),
                _buildProductsSection(),
                _buildPourquoiSection(),
                _buildModulesSection(),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final collapsed = _scrollOffset > 30;
    return SliverAppBar(
      centerTitle: false,
      floating: false,
      pinned: true,
      expandedHeight: 80,
      elevation: collapsed ? 1 : 0,
      backgroundColor: collapsed
          ? AppTheme.kBackgroundCream.withValues(alpha: 0.85)
          : Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: collapsed
            ? null
            : BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.kPrimaryRedDark,
                    AppTheme.kPrimaryRed,
                    AppTheme.kPrimaryOrange,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
        child: FlexibleSpaceBar(
          titlePadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: collapsed
                          ? AppTheme.kPrimaryRed.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/images/rayhan_icon.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'RayhanERP',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: collapsed ? AppTheme.kTextPrimary : Colors.white,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () => context.push('/login'),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Se connecter'),
                style: FilledButton.styleFrom(
                  backgroundColor: collapsed
                      ? AppTheme.kPrimaryRed
                      : Colors.white.withValues(alpha: 0.2),
                  foregroundColor:
                      collapsed ? AppTheme.kSurfaceWhite : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.kPrimaryRedDark,
            AppTheme.kPrimaryRed,
            AppTheme.kPrimaryOrange,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 60),
      child: FadeTransition(
        opacity: _heroFade,
        child: SlideTransition(
          position: _heroSlide,
          child: _heroTextContent(),
        ),
      ),
    );
  }

  Widget _heroTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          AppText.heroTitle,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppText.heroSubtitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.85),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Certifié ISO 9001',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Livraison Express',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Container(
              height: 3,
              width: 60,
              decoration: BoxDecoration(
                color: AppTheme.kSecondaryGold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Depuis 1992',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    return AppTheme.glassBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          children: [
            Text(AppText.productsTitle,
                style: AppTheme.headlineLarge.copyWith(fontSize: 28)),
            const SizedBox(height: 8),
            Text(AppText.productsSubtitle,
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.kTextSecondary)),
            const SizedBox(height: 40),
            LayoutBuilder(
              builder: (ctx, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 4
                    : constraints.maxWidth > 600
                        ? 2
                        : 1;
                final aspect = crossAxisCount == 4 ? 0.85 : 0.9;
                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: aspect,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  children: [
                    _productCard(
                      title: AppText.productSacs,
                      desc: AppText.productSacsDesc,
                      icon: Icons.inventory_2_rounded,
                      color: AppTheme.kPrimaryRed,
                      imagePath: 'assets/images/products/product_sacs.jpg',
                    ),
                    _productCard(
                      title: AppText.productFilm,
                      desc: AppText.productFilmDesc,
                      icon: Icons.wrap_text_rounded,
                      color: AppTheme.kSecondaryGold,
                      imagePath: 'assets/images/products/product_film.jpg',
                    ),
                    _productCard(
                      title: AppText.productSangles,
                      desc: AppText.productSanglesDesc,
                      icon: Icons.link_rounded,
                      color: AppTheme.kPrimaryOrange,
                      imagePath: 'assets/images/products/product_sangles.jpg',
                    ),
                    _productCard(
                      title: AppText.productPoubelle,
                      desc: AppText.productPoubelleDesc,
                      icon: Icons.cleaning_services_rounded,
                      color: AppTheme.kPrimaryRedDark,
                      imagePath: 'assets/images/products/product_poubelle.jpg',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required String imagePath,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.kSectionBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.shadowMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(title,
                          style: AppTheme.titleSmall.copyWith(fontSize: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(desc,
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.kTextSecondary)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/catalogue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kSuccessGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Commander',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPourquoiSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.kPrimaryRedDark,
            AppTheme.kPrimaryRed,
            AppTheme.kPrimaryOrange,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          Text(AppText.pourquoiTitle,
              style: AppTheme.headlineLarge
                  .copyWith(fontSize: 28, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            'Découvrez pourquoi les plus grands industriels tunisiens nous font confiance.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 40),
          LayoutBuilder(
            builder: (ctx, constraints) {
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _pourquoiCard(
                    icon: Icons.verified_rounded,
                    title: AppText.pourquoiQuality,
                    desc: AppText.pourquoiQualityDesc,
                  ),
                  _pourquoiCard(
                    icon: Icons.flash_on_rounded,
                    title: AppText.pourquoiDelivery,
                    desc: AppText.pourquoiDeliveryDesc,
                  ),
                  _pourquoiCard(
                    icon: Icons.auto_awesome_rounded,
                    title: AppText.pourquoiExpertise,
                    desc: AppText.pourquoiExpertiseDesc,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _pourquoiCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.kPrimaryOrange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.kPrimaryOrange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17)),
          const SizedBox(height: 8),
          Text(desc,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.5,
              )),
        ],
      ),
    );
  }

  Widget _buildModulesSection() {
    return AppTheme.glassBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          children: [
            Text(AppText.modulesTitle,
                style: AppTheme.headlineLarge.copyWith(fontSize: 28)),
            const SizedBox(height: 8),
            Text(AppText.modulesSubtitle,
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.kTextSecondary)),
            const SizedBox(height: 40),
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth > 700;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _moduleCard(
                      icon: Icons.dashboard_rounded,
                      title: 'Tableau de bord',
                      desc: 'Indicateurs en temps réel',
                      color: AppTheme.kPrimaryRed,
                    ),
                    _moduleCard(
                      icon: Icons.shopping_cart_rounded,
                      title: 'Gestion des ventes',
                      desc: 'Commandes, factures, clients',
                      color: AppTheme.kSecondaryGold,
                    ),
                    _moduleCard(
                      icon: Icons.local_shipping_rounded,
                      title: 'Gestion des achats',
                      desc: 'Approvisionnement, fournisseurs',
                      color: AppTheme.kPrimaryOrange,
                    ),
                    _moduleCard(
                      icon: Icons.precision_manufacturing_rounded,
                      title: 'Production',
                      desc: 'OF, BOM, suivi atelier',
                      color: AppTheme.kPrimaryRedDark,
                    ),
                    _moduleCard(
                      icon: Icons.warehouse_rounded,
                      title: 'Gestion de stock',
                      desc: 'Mouvements, alertes, inventaire',
                      color: AppTheme.kSuccessGreen,
                    ),
                    _moduleCard(
                      icon: Icons.inventory_2_rounded,
                      title: 'Articles & Produits',
                      desc: 'MP, PSF, PF, nomenclatures',
                      color: AppTheme.kSecondaryGold,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.kSectionBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: AppTheme.titleSmall
                  .copyWith(fontSize: 15, color: AppTheme.kTextPrimary)),
          const SizedBox(height: 4),
          Text(desc,
              style:
                  AppTheme.bodySmall.copyWith(color: AppTheme.kTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D0A1A), Color(0xFF1A142E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.factory_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              const Text(
                'RayhanERP',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppText.footerTagline,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '© ${DateTime.now().year} ${AppText.footerCopyright}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppText.footerRights,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
