import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/application_provider.dart';
import '../../core/constants/app_routes.dart';
import '../../widgets/dashboard/application_card.dart';

class ApplicationListScreen extends StatefulWidget {
  const ApplicationListScreen({super.key});

  @override
  State<ApplicationListScreen> createState() => _ApplicationListScreenState();
}

class _ApplicationListScreenState extends State<ApplicationListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<ApplicationProvider>();
    final allApps = appProvider.applications;
    
    final filteredApps = allApps.where((app) {
      return app.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (app.applicantInfo?.businessName.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed(AppRoutes.dashboard);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Applications'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(AppRoutes.dashboard);
              }
            },
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by ID or Business Name',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: appProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredApps.isEmpty
                      ? const Center(child: Text('No applications found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredApps.length,
                          itemBuilder: (context, index) {
                            final app = filteredApps[index];
                            return ApplicationCard(
                              application: app,
                              onTap: () => context.pushNamed(
                                AppRoutes.applicationDetails,
                                pathParameters: {'id': app.id},
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
