import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_colors.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/application_provider.dart';
import 'providers/inspection_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/device_provider.dart';
import 'providers/vendor_provider.dart';

// Repositories
import 'data/repositories/mock_certificate_repository.dart';

// Services
import 'services/api_client.dart';
import 'services/token_storage_service.dart';
import 'services/backend_device_service.dart';
import 'services/websocket_service.dart';
import 'services/mock_certificate_service.dart';
import 'services/location_service.dart';
import 'services/i_certificate_service.dart';
import 'core/config/api_config.dart';

// Backend Repositories
import 'data/repositories/backend_auth_repository.dart';
import 'data/repositories/backend_application_repository.dart';
import 'data/repositories/backend_inspection_repository.dart';
import 'data/repositories/backend_notification_repository.dart';
import 'data/repositories/backend_vendor_repository.dart';

// ── Auth screen ──
import 'screens/auth/unified_login_screen.dart';

// ── LMO screens (preserved) ──
import 'screens/dashboard/lmo_dashboard_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/applications/application_list_screen.dart';
import 'screens/applications/application_details_screen.dart';
import 'screens/applications/document_review_screen.dart';
import 'screens/verification/verification_mode_screen.dart';
import 'screens/verification/digital_verification_screen.dart';
import 'screens/verification/tamper_logs_screen.dart';
import 'screens/verification/field_verification_screen.dart';
import 'screens/verification/inspection_form_screen.dart';
import 'screens/verification/verification_summary_screen.dart';
import 'screens/verification/verification_history_screen.dart';
import 'screens/certificate/certificate_request_screen.dart';
import 'screens/certificate/qr_verification_screen.dart';
import 'screens/profile/profile_screen.dart';

// ── Vendor screens (new) ──
import 'screens/vendor/dashboard/vendor_dashboard_screen.dart';
import 'screens/vendor/instruments/my_instruments_screen.dart';
import 'screens/vendor/instruments/register_instrument_screen.dart';
import 'screens/vendor/instruments/instrument_details_screen.dart';
import 'screens/vendor/verification/apply_verification_screen.dart';
import 'screens/vendor/verification/upload_documents_screen.dart';
import 'screens/vendor/verification/find_gatc_screen.dart';
import 'screens/vendor/verification/book_slot_screen.dart';
import 'screens/vendor/verification/application_summary_screen.dart';
import 'screens/vendor/payment/payment_gateway_screen.dart';
import 'screens/vendor/payment/payment_receipt_screen.dart';
import 'screens/vendor/tracking/my_applications_screen.dart';
import 'screens/vendor/tracking/application_tracking_screen.dart';
import 'screens/vendor/certificates/certificate_wallet_screen.dart';
import 'screens/vendor/certificates/certificate_details_screen.dart';
import 'screens/vendor/profile/vendor_profile_screen.dart';

class LmoApp extends StatelessWidget {
  const LmoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = TokenStorageService();
    final apiClient = ApiClient(
      baseUrl: ApiConfig.baseUrl,
      tokenStorage: tokenStorage,
    );

    final authRepo = BackendAuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);
    final vendorRepo = BackendVendorRepository(apiClient: apiClient);
    final appRepo = BackendApplicationRepository(apiClient: apiClient);
    final inspRepo = BackendInspectionRepository(apiClient: apiClient);
    final notifRepo = BackendNotificationRepository(apiClient: apiClient);

    return MultiProvider(
      providers: [
        Provider<TokenStorageService>.value(value: tokenStorage),
        Provider<ApiClient>.value(value: apiClient),

        // ── Auth (shared) ──
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),

        // ── LMO providers ──
        ChangeNotifierProvider(create: (_) => ApplicationProvider(appRepo)),
        ChangeNotifierProvider(create: (_) => InspectionProvider(inspRepo)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(notifRepo)),
        Provider(create: (_) => WebSocketService()),
        ChangeNotifierProvider(
          create: (ctx) => DeviceProvider(
            BackendDeviceService(),
            ctx.read<WebSocketService>(),
          ),
        ),
        Provider<ICertificateService>(create: (_) => MockCertificateService(MockCertificateRepository())),
        Provider(create: (_) => LocationService()),

        // ── Vendor provider ──
        ChangeNotifierProvider(create: (_) => VendorProvider(vendorRepo)),
      ],
      child: const _CalisAppRouter(),
    );
  }
}

class _CalisAppRouter extends StatefulWidget {
  const _CalisAppRouter();

  @override
  State<_CalisAppRouter> createState() => _CalisAppRouterState();
}

class _CalisAppRouterState extends State<_CalisAppRouter> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();

    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';

        if (!isLoggedIn && !isLoggingIn) return '/login';
        if (isLoggedIn && isLoggingIn) {
          final user = authProvider.currentUser;
          if (user != null && user.isVendor) return '/vendor/dashboard';
          return '/dashboard';
        }
        return null;
      },
      routes: [
        // ══════════════════════════════════════════════════════════
        // AUTH
        // ══════════════════════════════════════════════════════════
        GoRoute(
          path: '/login',
          name: AppRoutes.login,
          builder: (context, state) => const UnifiedLoginScreen(),
        ),

        // ══════════════════════════════════════════════════════════
        // LMO ROUTES (all preserved exactly as before)
        // ══════════════════════════════════════════════════════════
        GoRoute(
          path: '/dashboard',
          name: AppRoutes.dashboard,
          onExit: (BuildContext context) async {
            final shouldExit = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Exit application?'),
                content: const Text('Are you sure you want to exit the LMO Portal?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Exit'),
                  ),
                ],
              ),
            );
            if (shouldExit == true) {
              SystemNavigator.pop();
              return true;
            }
            return false;
          },
          builder: (context, state) => const LmoDashboardScreen(),
        ),
        GoRoute(
          path: '/notifications',
          name: AppRoutes.notifications,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/applications',
          name: AppRoutes.applicationList,
          builder: (context, state) => const ApplicationListScreen(),
        ),
        GoRoute(
          path: '/applications/:id',
          name: AppRoutes.applicationDetails,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ApplicationDetailsScreen(applicationId: id);
          },
        ),
        GoRoute(
          path: '/applications/:id/documents',
          name: AppRoutes.documentReview,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return DocumentReviewScreen(applicationId: id);
          },
        ),
        GoRoute(
          path: '/applications/:id/verify/mode',
          name: AppRoutes.verificationMode,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return VerificationModeScreen(applicationId: id);
          },
        ),
        GoRoute(
          path: '/applications/:id/verify/digital',
          name: AppRoutes.digitalVerification,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return DigitalVerificationScreen(applicationId: id);
          },
        ),
        GoRoute(
          path: '/applications/:id/tamper-logs',
          name: AppRoutes.tamperLogs,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return TamperLogsScreen(applicationId: id);
          },
        ),
        GoRoute(
          path: '/applications/:id/verify/field',
          name: AppRoutes.fieldVerification,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return FieldVerificationScreen(applicationId: id);
          },
        ),
        GoRoute(
          path: '/applications/:id/inspect',
          name: AppRoutes.inspectionForm,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return InspectionFormScreen(applicationId: id);
          },
        ),
        GoRoute(
          path: '/inspections/:id/summary',
          name: AppRoutes.verificationSummary,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return VerificationSummaryScreen(inspectionId: id);
          },
        ),
        GoRoute(
          path: '/instruments/:instrumentId/history',
          name: AppRoutes.verificationHistory,
          builder: (context, state) {
            final id = state.pathParameters['instrumentId']!;
            return VerificationHistoryScreen(instrumentId: id);
          },
        ),
        GoRoute(
          path: '/certificates/request',
          name: AppRoutes.certificateRequest,
          builder: (context, state) => const CertificateRequestScreen(),
        ),
        GoRoute(
          path: '/verify/:certId',
          name: AppRoutes.qrVerification,
          builder: (context, state) {
            final certId = state.pathParameters['certId']!;
            return QrVerificationScreen(certId: certId);
          },
        ),
        GoRoute(
          path: '/profile',
          name: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),

        // ══════════════════════════════════════════════════════════
        // VENDOR ROUTES (new)
        // ══════════════════════════════════════════════════════════
        GoRoute(
          path: '/vendor/dashboard',
          name: AppRoutes.vendorDashboard,
          builder: (context, state) => const VendorDashboardScreen(),
        ),
        GoRoute(
          path: '/vendor/instruments',
          name: AppRoutes.vendorMyInstruments,
          builder: (context, state) => const MyInstrumentsScreen(),
        ),
        GoRoute(
          path: '/vendor/instruments/register',
          name: AppRoutes.vendorRegisterInstrument,
          builder: (context, state) => const RegisterInstrumentScreen(),
        ),
        GoRoute(
          path: '/vendor/instruments/:id',
          name: AppRoutes.vendorInstrumentDetails,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return InstrumentDetailsScreen(instrumentId: id);
          },
        ),
        GoRoute(
          path: '/vendor/apply',
          name: AppRoutes.vendorApplyVerification,
          builder: (context, state) => const ApplyVerificationScreen(),
        ),
        GoRoute(
          path: '/vendor/apply/upload-docs',
          name: AppRoutes.vendorApplyUploadDocs,
          builder: (context, state) => const UploadDocumentsScreen(),
        ),
        GoRoute(
          path: '/vendor/apply/gatc',
          name: AppRoutes.vendorFindGatc,
          builder: (context, state) => const FindGatcScreen(),
        ),
        GoRoute(
          path: '/vendor/apply/slot',
          name: AppRoutes.vendorBookSlot,
          builder: (context, state) => const BookSlotScreen(),
        ),
        GoRoute(
          path: '/vendor/apply/summary',
          name: AppRoutes.vendorApplicationSummary,
          builder: (context, state) => const ApplicationSummaryScreen(),
        ),
        GoRoute(
          path: '/vendor/payment/:id',
          name: AppRoutes.vendorPaymentGateway,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return PaymentGatewayScreen(applicationId: id);
          },
        ),
        GoRoute(
          path: '/vendor/payment/:id/receipt',
          name: AppRoutes.vendorPaymentReceipt,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return PaymentReceiptScreen(applicationId: id);
          },
        ),
        GoRoute(
          path: '/vendor/applications',
          name: AppRoutes.vendorMyApplications,
          builder: (context, state) => const MyApplicationsScreen(),
        ),
        GoRoute(
          path: '/vendor/applications/:id/track',
          name: AppRoutes.vendorApplicationTracking,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ApplicationTrackingScreen(applicationId: id);
          },
        ),
        GoRoute(
          path: '/vendor/certificates',
          name: AppRoutes.vendorCertificateWallet,
          builder: (context, state) => const CertificateWalletScreen(),
        ),
        GoRoute(
          path: '/vendor/certificates/:id',
          name: AppRoutes.vendorCertificateDetails,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return CertificateDetailsScreen(certificateId: id);
          },
        ),
        GoRoute(
          path: '/vendor/profile',
          name: AppRoutes.vendorProfile,
          builder: (context, state) => const VendorProfileScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Calibris — Legal Metrology Platform',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
