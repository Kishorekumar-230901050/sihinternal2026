import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/vendor_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';

class BookSlotScreen extends StatefulWidget {
  const BookSlotScreen({super.key});

  @override
  State<BookSlotScreen> createState() => _BookSlotScreenState();
}

class _BookSlotScreenState extends State<BookSlotScreen> {
  DateTime? _selectedDate;
  String? _selectedTime;
  bool _isBooking = false;

  final _availableTimes = ['Morning (9:00 AM – 12:00 PM)', 'Afternoon (1:00 PM – 4:00 PM)'];

  Future<void> _confirmSlot(VendorProvider vendor) async {
    vendor.selectSlot(_selectedDate!, _selectedTime!.split(' ').first);
    setState(() => _isBooking = true);
    try {
      await vendor.bookSelectedSlot();
      if (mounted) context.pushNamed(AppRoutes.vendorApplicationSummary);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  List<DateTime> _getAvailableDates() {
    final today = DateTime.now();
    return List.generate(14, (i) => today.add(Duration(days: i + 2)))
        .where((d) => d.weekday != DateTime.sunday)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<VendorProvider>();
    final dates = _getAvailableDates();

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.vendorAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Step 3 of 4 — Select Date & Time',
                  style: TextStyle(color: AppColors.vendorAccent, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(height: 12),
            Text('GATC: ${vendor.selectedGatc?.name ?? "—"}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 16),

            Text('Select Date', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  final date = dates[index];
                  final isSelected = _selectedDate != null &&
                      date.year == _selectedDate!.year &&
                      date.month == _selectedDate!.month &&
                      date.day == _selectedDate!.day;
                  final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = date),
                    child: Container(
                      width: 64,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.vendorAccent : AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppColors.vendorAccent : AppColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(dayName, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : AppColors.textSecondary)),
                          Text('${date.day}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            Text('Select Time Slot', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._availableTimes.map((time) {
              final isSelected = _selectedTime == time;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: isSelected ? AppColors.vendorAccent : AppColors.border, width: isSelected ? 2 : 1),
                ),
                child: ListTile(
                  leading: Icon(Icons.schedule, color: isSelected ? AppColors.vendorAccent : AppColors.textSecondary),
                  title: Text(time, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                  trailing: Radio<String>(
                    value: time,
                    groupValue: _selectedTime,
                    onChanged: (v) => setState(() => _selectedTime = v),
                    activeColor: AppColors.vendorAccent,
                  ),
                  onTap: () => setState(() => _selectedTime = time),
                ),
              );
            }),

            const Spacer(),

            if (_selectedDate != null && _selectedTime != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Selected: ${DateFormatter.formatDate(_selectedDate!)} • ${_selectedTime!.split(' ').first}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.vendorAccent),
                ),
              ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_selectedDate == null || _selectedTime == null || _isBooking)
                    ? null
                    : () => _confirmSlot(vendor),
                child: _isBooking
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('NEXT — Review & Pay'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
