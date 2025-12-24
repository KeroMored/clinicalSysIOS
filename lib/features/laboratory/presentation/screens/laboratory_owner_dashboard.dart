import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/laboratory_model.dart';
import '../widgets/laboratory_widgets.dart';

class LaboratoryOwnerDashboard extends StatefulWidget {
  const LaboratoryOwnerDashboard({super.key});

  @override
  State<LaboratoryOwnerDashboard> createState() => _LaboratoryOwnerDashboardState();
}

class _LaboratoryOwnerDashboardState extends State<LaboratoryOwnerDashboard> {
  LaboratoryModel? _laboratory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLaboratoryData();
  }

  Future<void> _loadLaboratoryData() async {
    setState(() => _isLoading = true);
    
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      try {
        // البحث عن المعمل باستخدام الإيميل
        final querySnapshot = await FirebaseFirestore.instance
            .collection('laboratories')
            .where('authEmails', arrayContains: authState.user.email)
            .where('status', isEqualTo: 'approved')
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          setState(() {
            _laboratory = LaboratoryModel.fromFirestore(doc);
            _isLoading = false;
          });
          
          print('✅ تم تحميل بيانات المعمل - ID: ${doc.id}');
        } else {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('لم يتم العثور على معمل مرتبط بحسابك أو لم تتم الموافقة عليه بعد'),
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
          );
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        
        
        appBar: AppBar(
          leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
          title: const Text('إدارة معملي',style: TextStyle(color: Colors.white),),
          centerTitle: true,
          elevation: 2,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _laboratory == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.science_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لم يتم العثور على بيانات المعمل',
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'تأكد من أن حسابك مرتبط بمعمل\nوأنه تمت الموافقة عليه من الإدارة',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadLaboratoryData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadLaboratoryData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LaboratoryInfoCard(
                            laboratory: _laboratory!,
                            onUpdate: _loadLaboratoryData,
                          ),
                          const SizedBox(height: 20),
                          
                          ActionButtonsSection(
                            laboratory: _laboratory!,
                            onUpdate: _loadLaboratoryData,
                            onShowAvailableTests: _showAvailableTestsDialog,
                            onShowWorkingHours: _showWorkingHoursDialog,
                          ),
                          const SizedBox(height: 20),
                          
                          QuickStatsSection(
                            laboratory: _laboratory!,
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  void _showAvailableTestsDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('التحاليل المتاحة'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _laboratory!.availableTests.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.check, color: Colors.green),
                  title: Text(_laboratory!.availableTests[index]),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkingHoursDialog() {
    final days = [
      {'key': 'saturday', 'name': 'السبت'},
      {'key': 'sunday', 'name': 'الأحد'},
      {'key': 'monday', 'name': 'الإثنين'},
      {'key': 'tuesday', 'name': 'الثلاثاء'},
      {'key': 'wednesday', 'name': 'الأربعاء'},
      {'key': 'thursday', 'name': 'الخميس'},
      {'key': 'friday', 'name': 'الجمعة'},
    ];

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('مواعيد العمل'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final dayData = _laboratory!.workingHours[day['key']];
                final isAvailable = dayData != null ? !dayData.isHoliday : false;
                
                return ListTile(
                  leading: Icon(
                    isAvailable ? Icons.check_circle : Icons.cancel,
                    color: isAvailable ? Colors.green : Colors.red,
                  ),
                  title: Text(day['name']!),
                  subtitle: Text(
                    isAvailable
                        ? '${dayData.openTime} - ${dayData.closeTime}'
                        : 'عطلة',
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }
}
