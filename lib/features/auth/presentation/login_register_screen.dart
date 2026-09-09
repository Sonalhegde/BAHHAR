import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/omani_regions.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/bahhar_logo_widget.dart';
import '../../../shared/widgets/custom_buttons.dart';

/// Screen 2: Login / Register Screen (Section 6.2)
/// Tabbed Sign In / Sign Up, email/phone, social buttons, home region selection.
class LoginRegisterScreen extends ConsumerStatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  ConsumerState<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends ConsumerState<LoginRegisterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController(text: 'fisherman@bahhar.om');
  final TextEditingController _passwordController = TextEditingController(text: 'secret123');
  String _selectedRegion = 'Muscat';
  bool _isLoading = false;

  final List<String> _regions = const [
    'Muscat',
    'Musandam',
    'Al Batinah North',
    'Al Batinah South',
    'Ash Sharqiyah South',
    'Al Wusta',
    'Dhofar',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitAuth() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        ref.read(authProvider.notifier).signIn(
              _emailController.text,
              _passwordController.text,
            );
        ref.read(authProvider.notifier).updateHomeRegion(_selectedRegion);
        setState(() => _isLoading = false);
        context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: BahharLogoWidget(
                  size: 64,
                  color: isDark ? Colors.white : AppColors.deepSea,
                  showWordmark: true,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.nightSurface : AppColors.mistGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.oceanBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Sign Up'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email or Phone Number',
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.oceanBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.oceanBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                decoration: InputDecoration(
                  labelText: 'Home Coastal Region',
                  prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.oceanBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _regions.map((region) {
                  return DropdownMenuItem(value: region, child: Text(region));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRegion = val);
                },
              ),
              const SizedBox(height: 24),
              BahharPrimaryButton(
                label: _tabController.index == 0 ? 'Sign In' : 'Create Account',
                isLoading: _isLoading,
                onPressed: _submitAuth,
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 12),
                    child: Text('OR CONTINUE WITH', style: AppTextStyles.micro),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: BahharSecondaryButton(
                      label: 'Google',
                      icon: Icons.g_mobiledata,
                      onPressed: _submitAuth,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BahharSecondaryButton(
                      label: 'Apple',
                      icon: Icons.apple,
                      onPressed: _submitAuth,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
