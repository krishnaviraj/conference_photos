import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../screens/home_screen.dart';
import '../services/storage_service.dart';
import '../widgets/animated_cards_svg.dart';
import '../widgets/animated_welcome_widget.dart';

class OnboardingScreen extends StatefulWidget {
  final StorageService storageService;

  const OnboardingScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Permission state
  bool _cameraPermissionGranted = false;
  
  // Create a key for the animated cards
  final GlobalKey<AnimatedCardsSvgState> _cardsKey = GlobalKey<AnimatedCardsSvgState>();


  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;

    setState(() {
      _cameraPermissionGranted = cameraStatus.isGranted;
    });
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _cameraPermissionGranted = status.isGranted;
    });
    
    if (status.isPermanentlyDenied && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Camera permission'),
          content: const Text(
            'The camera permission is required to take photos. '
            'Please enable it in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    // Navigate to home screen
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(storageService: widget.storageService),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.04, 
              left: 16.0, 
              right: 16.0,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Centered logo with additional padding to push it down
                Positioned.fill(
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/logo/mosaic_logo.svg',
                      height: MediaQuery.of(context).size.width < 400 ? 36 : 48,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                
                // Skip button aligned to the right (unchanged)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: MediaQuery.of(context).size.width < 400 ? 10 : 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                    
                    // If we're on the photos info page (page 1), restart the animation
                    if (page == 1 && _cardsKey.currentState != null) {
                      _cardsKey.currentState!.resetAndStartAnimations();
                    }

                  },
                  children: [
                    // Welcome page
                    Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width < 400 ? 24.0 : 40.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                              // Using our animated welcome widget here
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.2,
                                child: const AnimatedWelcomeWidget(),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                              Text(
                                'Welcome to Mosaic',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: MediaQuery.of(context).size.width < 400 ? 24 : 28,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Capture and organize photos with annotations. Perfect for groups, inspirations, or trips.',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withAlpha(220),
                                      fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                                    ),
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),      
                    // Photos info page
                    Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width < 400 ? 12.0 : 20.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                              // Using our animated cards widget here with the key
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.18,
                                child: AnimatedCardsSvg(
                                  key: _cardsKey,
                                  startAnimation: true,
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                              Text(
                                'Your photos stay in the app',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: MediaQuery.of(context).size.width < 400 ? 24 : 28,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Photos you take are stored within the app and won\'t appear in your gallery to avoid cluttering it up. Use the backup feature for important content!',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withAlpha(220),
                                      fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                                    ),
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Permissions page
                    Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width < 400 ? 12.0 : 20.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                              SvgPicture.asset(
                                'assets/images/camera_permission.svg',
                                width: MediaQuery.of(context).size.width < 400 ? 100 : 150,
                                height: MediaQuery.of(context).size.width < 400 ? 100 : 150,
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                              Text(
                                'Camera permission',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: MediaQuery.of(context).size.width < 400 ? 24 : 28,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'The app needs access to your camera to let you take photos.',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withAlpha(220),
                                      fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 40),
                              _buildPermissionItem(
                                icon: Icons.camera_alt,
                                title: 'Camera',
                                description: 'To take photos within the app',
                                isGranted: _cameraPermissionGranted,
                                onRequest: _requestCameraPermission,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Navigation dots
              Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => Container(
                      margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 400 ? 4.0 : 5.0),
                      width: MediaQuery.of(context).size.width < 400 ? 8 : 10,
                      height: MediaQuery.of(context).size.width < 400 ? 8 : 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? AppTheme.accentColor
                            : AppTheme.accentColor.withAlpha(100),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Next button
              Padding(
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  bottom: MediaQuery.of(context).size.height * 0.05,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: AppTheme.primaryColor,
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.width < 400 ? 12.0 : 16.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: Text(
                      _currentPage == 2 ? 'Get started' : 'Next',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 400 ? 16 : 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          // Replace the AnimatedBuilder with a simple Icon widget
          Icon(
            icon,
            color: Colors.white,
            size: isSmallScreen ? 22 : 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withAlpha(179),
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          isGranted
              ? Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: isSmallScreen ? 22 : 28,
                )
              : ElevatedButton(
                  onPressed: onRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 16.0 : 20.0),
                    ),
                  ),
                  child: const Text('Grant'),
                ),
        ],
      ),
    );
  }
}