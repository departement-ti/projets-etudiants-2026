import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/onboarding_content.dart';

class Onboarding extends StatefulWidget {
  final void Function()? showSignInScreen;
  const Onboarding({super.key, required this.showSignInScreen});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> with TickerProviderStateMixin {
  int currentIndex = 0;
  late PageController pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    pageController = PageController(initialPage: 0);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    _fadeController.reset();
    _fadeController.forward();
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 241, 250, 251),
              Color.fromARGB(255, 222, 240, 243),
              Color.fromARGB(255, 241, 250, 251),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 8),
                //logo
                const Image(
                   image: AssetImage('lib/assets/neurocare_logo.png'),
                  height: 65,
                ),
                const SizedBox(height: 8),
                //pages
                Expanded(
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: contents.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (_, i) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: <Widget>[
                            const Spacer(flex: 1),
                            //illustration
                            Container(
                              height: MediaQuery.of(context).size.height * 0.32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromRGBO(7, 82, 96, 1)
                                        .withOpacity(0.08),
                                    blurRadius: 40,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: Image.asset(
                                  contents[i].image,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const Spacer(flex: 2),
                            //title
                            Text(
                              contents[i].title,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 28,
                                height: 1.3,
                                color: const Color.fromRGBO(7, 82, 96, 1),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            //description
                            Text(
                              contents[i].description,
                              style: GoogleFonts.roboto(
                                fontSize: 17,
                                height: 1.5,
                                color: const Color.fromARGB(255, 100, 110, 115),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const Spacer(flex: 2),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                //dots modernes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    contents.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      height: 8,
                      width: index == currentIndex ? 28 : 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: index == currentIndex
                            ? const Color.fromRGBO(7, 82, 96, 1)
                            : const Color.fromARGB(255, 185, 205, 210),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                //boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      height: 54,
                      width: 130,
                      child: TextButton(
                        onPressed: widget.showSignInScreen,
                        style: TextButton.styleFrom(
                          foregroundColor:
                              const Color.fromRGBO(7, 82, 96, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          'Passer',
                          style: GoogleFonts.roboto(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (currentIndex < contents.length - 1)
                          SizedBox(
                            height: 54,
                            width: 130,
                            child: FilledButton(
                              onPressed: () {
                                pageController.nextPage(
                                    duration:
                                        const Duration(milliseconds: 600),
                                    curve: Curves.easeInOut);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(7, 82, 96, 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Suivant',
                                style: GoogleFonts.roboto(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        if (currentIndex == contents.length - 1)
                          SizedBox(
                            height: 54,
                            width: 130,
                            child: FilledButton(
                              onPressed: widget.showSignInScreen,
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(7, 82, 96, 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Commencer',
                                style: GoogleFonts.roboto(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
