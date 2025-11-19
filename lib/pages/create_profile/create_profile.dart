import 'package:apnea_app/widgets/labeled_text_field.dart';
import 'package:apnea_app/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/baby_profile.dart';

class CreateProfile extends StatefulWidget {
  const CreateProfile({super.key});

  @override
  State<CreateProfile> createState() => _CreateProfileState();
}

class _CreateProfileState extends State<CreateProfile> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final _createProfileFormKey = GlobalKey<FormState>();
  
  // Controllers to capture form data
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _gestationalAgeController = TextEditingController();
  final _birthWeightController = TextEditingController();
  String? _selectedGender;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _gestationalAgeController.dispose();
    _birthWeightController.dispose();
    super.dispose();
  }

  // Sanitize text input - trim whitespace and capitalize first letter
  String _sanitizeText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  // Validate and save profile to database
  Future<void> _saveProfile() async {
    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    if (!_createProfileFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Sanitize input data
      final firstName = _sanitizeText(_firstNameController.text);
      final lastName = _sanitizeText(_surnameController.text);
      final gestationalAge = int.tryParse(_gestationalAgeController.text.trim());
      final weight = double.tryParse(_birthWeightController.text.trim());

      // Additional validation
      if (firstName.isEmpty || lastName.isEmpty) {
        _showErrorMessage('Please enter valid names');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (gestationalAge == null || gestationalAge < 20 || gestationalAge > 45) {
        _showErrorMessage('Gestational age must be between 20 and 45 weeks');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (weight == null || weight < 0.5 || weight > 10.0) {
        _showErrorMessage('Weight must be between 0.5 and 10.0 kg');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (_selectedGender == null) {
        _showErrorMessage('Please select a gender');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Create BabyProfile object
      final newProfile = BabyProfile(
        firstName: firstName,
        lastName: lastName,
        gestationalAge: gestationalAge,
        weight: weight,
        gender: _selectedGender!.toLowerCase(),
      );

      // Save to database
      final profileId = await _databaseService.addProfile(newProfile);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        // Wait a moment for the snackbar to show, then navigate back
        await Future.delayed(Duration(milliseconds: 500));
        
        // Return true to indicate successful save
        if(mounted){
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print('Error saving profile: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Failed to save profile. Please try again.');
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Color(0xFFF6F7F8),
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 24.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
            ),
            child: Form(
              key: _createProfileFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Text(
                    'Baby Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Enter your baby\'s details to create a new profile',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Form fields
                  LabeledTextField(
                    icon: Icons.person_outline,
                    label: "First Name",
                    hint: "Enter first name",
                    textInputType: TextInputType.name,
                    controller: _firstNameController,
                  ),
                  LabeledTextField(
                    icon: Icons.person_outline,
                    label: "Surname",
                    hint: "Enter surname",
                    textInputType: TextInputType.name,
                    controller: _surnameController,
                  ),
                  LabeledTextField(
                    icon: Icons.calendar_today_outlined,
                    label: "Gestational Age (weeks)",
                    hint: "Enter age in weeks (20-45)",
                    textInputType: TextInputType.number,
                    controller: _gestationalAgeController,
                  ),
                  LabeledTextField(
                    icon: Icons.monitor_weight_outlined,
                    label: "Birth Weight",
                    hint: "Enter child's weight in kg (0.5-10.0)",
                    textInputType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    controller: _birthWeightController,
                  ),
                  
                  // Gender dropdown
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedGender = newValue;
                            });
                          },
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.wc_outlined,
                              color: Color(0xFFA0A0A9),
                            ),
                            hintText: 'Select gender',
                            hintStyle: TextStyle(color: Color(0xFFA0A0A9)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(17.0)),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: "Male",
                              child: Text("Male"),
                            ),
                            DropdownMenuItem(
                              value: "Female",
                              child: Text("Female"),
                            ),
                          ],
                          validator: (value) {
                            return value == null ? "Please select a gender" : null;
                          },
                        ),
                        SizedBox(height: 4),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Save button
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF6B6B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _saveProfile,
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                "Save Profile",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Cancel button
                  Center(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context, false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF8A8A8A),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back),
        color: Colors.black87,
      ),
      title: Text(
        'Add New Profile',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
    );
  }
}