import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/Core/Tools/Helper.dart';
import 'package:tailorapp/Core/Widgets/CommonHeader.dart';
import 'package:tailorapp/Features/RootDirectory/customer/ToggleNotification.dart';
import 'package:tailorapp/GlobalVariables.dart';

import '../../../../Core/Widgets/CustomLoader.dart';
import '../../../../Core/Widgets/CustomSnakBar.dart';

final billingControllerProvider =
    StateNotifierProvider<BillingController, BillingState>(
  (ref) => BillingController(),
);

class BillingState {
  final TextEditingController billingTerms;
  final bool isGSTApplicable;
  final TextEditingController gstNumber;
  final TextEditingController gstRegistrationDate;
  final TextEditingController gstState;
  final TextEditingController gstAddress;
  final String? errorMessage;

  BillingState({
    required this.billingTerms,
    required this.isGSTApplicable,
    required this.gstNumber,
    required this.gstRegistrationDate,
    required this.gstState,
    required this.gstAddress,
    this.errorMessage,
  });

  BillingState copyWith({
    TextEditingController? billingTerms,
    bool? isGSTApplicable,
    TextEditingController? gstNumber,
    TextEditingController? gstRegistrationDate,
    TextEditingController? gstState,
    TextEditingController? gstAddress,
    String? errorMessage,
  }) {
    return BillingState(
      billingTerms: billingTerms ?? this.billingTerms,
      isGSTApplicable: isGSTApplicable ?? this.isGSTApplicable,
      gstNumber: gstNumber ?? this.gstNumber,
      gstRegistrationDate: gstRegistrationDate ?? this.gstRegistrationDate,
      gstState: gstState ?? this.gstState,
      gstAddress: gstAddress ?? this.gstAddress,
      errorMessage: errorMessage,
    );
  }
}

class BillingController extends StateNotifier<BillingState> {
  BillingController()
      : super(BillingState(
          billingTerms: TextEditingController(),
          isGSTApplicable: false,
          gstNumber: TextEditingController(),
          gstRegistrationDate: TextEditingController(),
          gstState: TextEditingController(),
          gstAddress: TextEditingController(),
        ));

  void toggleGSTApplicable() {
    state = state.copyWith(isGSTApplicable: !state.isGSTApplicable);
  }

  void updateRegistrationDate(String date) {
    state.gstRegistrationDate.text = date;
  }

  bool validateForm() {
    if (state.billingTerms.text.isEmpty) {
      state = state.copyWith(errorMessage: "Billing Terms is required.");
      return false;
    }
    if (state.isGSTApplicable) {
      if (state.gstNumber.text.isEmpty ||
          !RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')
              .hasMatch(state.gstNumber.text)) {
        state = state.copyWith(
            errorMessage:
                "Valid GST Number is required (e.g., 22AAAAA0000A1Z5).");
        return false;
      }
      if (state.gstRegistrationDate.text.isEmpty) {
        state =
            state.copyWith(errorMessage: "GST Registration Date is required.");
        return false;
      }
      if (state.gstState.text.isEmpty) {
        state = state.copyWith(errorMessage: "GST State is required.");
        return false;
      }
      if (state.gstAddress.text.isEmpty) {
        state = state.copyWith(
            errorMessage: "GST Registration Address is required.");
        return false;
      }
    }
    state = state.copyWith(errorMessage: null);
    return true;
  }

  Future<void> submitForm(BuildContext context) async {
    int? shopId = GlobalVariables.shopIdGet;
    if (shopId == null) {
      state = state.copyWith(errorMessage: 'Shop ID is missing');
      return;
    }
    if (!validateForm()) {
      return;
    }
    try {
      showLoader(context);

      final payload = {
        "shop_id": shopId,
        "terms": state.billingTerms.text,
        "gst_no": state.gstNumber.text,
        "gst_reg_date": state.gstRegistrationDate.text,
        "gst_state": state.gstState.text,
        "gst_address": state.gstAddress.text,
        "gst_available": state.isGSTApplicable,
        "owner": GlobalVariables.userId?.toString() ?? "Unknown",
      };
      final response =
          await ApiService().post(Urls.billingTerm, context, data: payload);

      if (response.data != null) {
        hideLoader(context);
        state = state.copyWith(errorMessage: null);
        CustomSnackbar.showSnackbar(
          context,
          response.data['message'] ?? 'Billing details saved successfully',
          duration: const Duration(seconds: 1),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to save billing details');
      }
    } catch (e) {
      hideLoader(context);
      state = state.copyWith(errorMessage: 'Error: ${e.toString()}');
      CustomSnackbar.showSnackbar(
        context,
        'Error while submitting form: ${e.toString()}',
        duration: const Duration(seconds: 2),
      );
      print('Error while submitting form: $e');
    }
  }
}

class BillingDetailsScreen extends ConsumerWidget {
  const BillingDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(billingControllerProvider.notifier);
    final state = ref.watch(billingControllerProvider);
    return Scaffold(
      backgroundColor: ColorPalatte.white,
      appBar: Commonheader(title: 'Billing Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Billing Terms', state.billingTerms, maxLines: 3),
            const SizedBox(height: 16),
            CustomToggleSwitch(
              label: 'GST Applicable',
              value: state.isGSTApplicable,
              onChanged: (_) => controller.toggleGSTApplicable(),
            ),
            if (state.isGSTApplicable) ...[
              _buildTextField('GST Number', state.gstNumber,
                  textCapitalization: TextCapitalization.characters,
                  capitalize: true),
              const SizedBox(height: 10),
              _buildDateField(context, controller, state.gstRegistrationDate),
              const SizedBox(height: 10),
              _buildTextField('GST State', state.gstState),
              const SizedBox(height: 10),
              _buildTextField('GST Registration Address', state.gstAddress,
                  maxLines: 3),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 130,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: ColorPalatte.black),
                    ),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalatte.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () => controller.submitForm(context),
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1,
      TextCapitalization textCapitalization = TextCapitalization.none,
      bool capitalize = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textCapitalization: textCapitalization,
          inputFormatters: capitalize ? [UpperCaseTextFormatter()] : null,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          maxLines: maxLines,
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context, BillingController controller,
      TextEditingController dateController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('GST Registration Date',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: dateController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'yyyy / mm / dd',
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  controller.updateRegistrationDate(
                      pickedDate.toString().split(' ')[0]);
                }
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
