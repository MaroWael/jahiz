import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jahiz/core/constants/app_colors.dart';
import 'package:jahiz/core/services/user_profile_service.dart';
import 'package:jahiz/features/home/presentation/screens/home_screan.dart';

enum UserType { student, professional }

enum CompanyType { startup, enterprise }

enum CareerLevel { junior, mid, senior }

enum InterviewLanguage { english, arabic, mixed }

class ProfileOnboardingScreen extends StatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  State<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends State<ProfileOnboardingScreen> {
  final _userProfileService = UserProfileService();

  int _currentStep = 0;
  bool _isSaving = false;

  UserType selectedUserType = UserType.student;
  CompanyType? _companyType;
  CareerLevel? _careerLevel;
  InterviewLanguage selectedInterviewLanguage = InterviewLanguage.english;

  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _expectedGraduationYearController =
      TextEditingController();

  final TextEditingController _currentTitleController = TextEditingController();
  final TextEditingController _yearsOfExperienceController =
      TextEditingController();

  final TextEditingController _targetRoleController = TextEditingController();

  final TextEditingController _skillController = TextEditingController();
  final List<String> _technicalSkills = <String>[];

  final TextEditingController _githubController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();

  @override
  void dispose() {
    _universityController.dispose();
    _majorController.dispose();
    _expectedGraduationYearController.dispose();
    _currentTitleController.dispose();
    _yearsOfExperienceController.dispose();
    _targetRoleController.dispose();
    _skillController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return true;
      case 1:
        if (selectedUserType == UserType.student) {
          return _universityController.text.trim().isNotEmpty &&
              _majorController.text.trim().isNotEmpty &&
              _expectedGraduationYearController.text.trim().isNotEmpty;
        }
        return _currentTitleController.text.trim().isNotEmpty &&
            _yearsOfExperienceController.text.trim().isNotEmpty &&
            _companyType != null;
      case 2:
        return _targetRoleController.text.trim().isNotEmpty &&
            _careerLevel != null;
      case 3:
        return _technicalSkills.length >= 3 && _technicalSkills.length <= 5;
      case 4:
        return _isValidUrl(_githubController.text.trim()) &&
            _isValidUrl(_linkedinController.text.trim());
      case 5:
        return true;
      default:
        return false;
    }
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _continueStep() async {
    if (!_validateCurrentStep()) {
      switch (_currentStep) {
        case 0:
          _showValidationMessage('Please select a user type.');
          break;
        case 1:
          _showValidationMessage('Please complete all required information.');
          break;
        case 2:
          _showValidationMessage('Please fill career target and level.');
          break;
        case 3:
          _showValidationMessage('Add 3 to 5 technical skills.');
          break;
        case 4:
          _showValidationMessage('Enter valid GitHub and LinkedIn URLs.');
          break;
        case 5:
          _showValidationMessage('Please select interview language.');
          break;
      }
      return;
    }

    if (_currentStep == 5) {
      await _saveAndFinish();
      return;
    }

    setState(() => _currentStep += 1);
  }

  void _cancelStep() {
    if (_currentStep == 0) {
      return;
    }
    setState(() => _currentStep -= 1);
  }

  Future<void> _saveAndFinish() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      _showValidationMessage('Unable to identify the current user.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _userProfileService.saveOnboardingData(
        uid: user.uid,
        email: user.email!,
        userType: selectedUserType.name,
        studentInfo: {
          'university': _universityController.text.trim(),
          'major': _majorController.text.trim(),
          'expectedGraduationYear': _expectedGraduationYearController.text
              .trim(),
        },
        professionalInfo: {
          'currentTitle': _currentTitleController.text.trim(),
          'yearsOfExperience': _yearsOfExperienceController.text.trim(),
          'companyType': _companyType?.name ?? '',
        },
        careerTarget: {
          'targetRole': _targetRoleController.text.trim(),
          'level': _careerLevel!.name,
        },
        technicalStack: _technicalSkills,
        socialLinks: {
          'github': _githubController.text.trim(),
          'linkedin': _linkedinController.text.trim(),
        },
        interviewLanguage: selectedInterviewLanguage.name,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(builder: (_) => const HomeScrean()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showValidationMessage('Failed to save profile. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isEmpty) {
      return;
    }
    if (_technicalSkills.contains(skill)) {
      _showValidationMessage('Skill already added.');
      return;
    }
    if (_technicalSkills.length == 5) {
      _showValidationMessage('Maximum 5 skills allowed.');
      return;
    }

    setState(() {
      _technicalSkills.add(skill);
      _skillController.clear();
    });
  }

  void _removeSkill(String skill) {
    setState(() {
      _technicalSkills.remove(skill);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Onboarding'),
        centerTitle: true,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: _isSaving ? null : _continueStep,
        onStepCancel: _isSaving ? null : _cancelStep,
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == 5;
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _isSaving ? null : details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving && isLastStep
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isLastStep ? 'Save & Finish' : 'Next'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _isSaving ? null : details.onStepCancel,
                  child: const Text('Back'),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('User Type'),
            subtitle: Text('Step ${_currentStep + 1} of 6'),
            isActive: _currentStep >= 0,
            content: _buildUserTypeStep(),
          ),
          Step(
            title: const Text('Education / Work Information'),
            subtitle: const Text('Step 2 of 6'),
            isActive: _currentStep >= 1,
            content: _buildEducationWorkStep(),
          ),
          Step(
            title: const Text('Career Target'),
            subtitle: const Text('Step 3 of 6'),
            isActive: _currentStep >= 2,
            content: _buildCareerTargetStep(),
          ),
          Step(
            title: const Text('Technical Stack'),
            subtitle: const Text('Step 4 of 6'),
            isActive: _currentStep >= 3,
            content: _buildTechnicalStackStep(),
          ),
          Step(
            title: const Text('Social Presence'),
            subtitle: const Text('Step 5 of 6'),
            isActive: _currentStep >= 4,
            content: _buildSocialStep(),
          ),
          Step(
            title: const Text('Interview Language'),
            subtitle: const Text('Step 6 of 6'),
            isActive: _currentStep >= 5,
            content: _buildLanguageStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeStep() {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<UserType>(
        segments: const [
          ButtonSegment(value: UserType.student, label: Text('Student')),
          ButtonSegment(
            value: UserType.professional,
            label: Text('Professional'),
          ),
        ],
        selected: <UserType>{selectedUserType},
        onSelectionChanged: (selection) {
          setState(() => selectedUserType = selection.first);
        },
      ),
    );
  }

  Widget _buildEducationWorkStep() {
    if (selectedUserType == UserType.professional) {
      return Column(
        children: [
          TextField(
            controller: _currentTitleController,
            decoration: const InputDecoration(labelText: 'Current Job Title'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _yearsOfExperienceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Years of Experience'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<CompanyType>(
            initialValue: _companyType,
            decoration: const InputDecoration(labelText: 'Company Type'),
            items: const [
              DropdownMenuItem(
                value: CompanyType.startup,
                child: Text('Startup'),
              ),
              DropdownMenuItem(
                value: CompanyType.enterprise,
                child: Text('Enterprise'),
              ),
            ],
            onChanged: (value) {
              setState(() => _companyType = value);
            },
          ),
        ],
      );
    }

    return Column(
      children: [
        TextField(
          controller: _universityController,
          decoration: const InputDecoration(labelText: 'University'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _majorController,
          decoration: const InputDecoration(labelText: 'Major'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _expectedGraduationYearController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Expected Graduation Year',
          ),
        ),
      ],
    );
  }

  Widget _buildCareerTargetStep() {
    return Column(
      children: [
        TextField(
          controller: _targetRoleController,
          decoration: const InputDecoration(labelText: 'Target Job Role'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<CareerLevel>(
          initialValue: _careerLevel,
          decoration: const InputDecoration(labelText: 'Level'),
          items: const [
            DropdownMenuItem(value: CareerLevel.junior, child: Text('Junior')),
            DropdownMenuItem(value: CareerLevel.mid, child: Text('Mid')),
            DropdownMenuItem(value: CareerLevel.senior, child: Text('Senior')),
          ],
          onChanged: (value) {
            setState(() => _careerLevel = value);
          },
        ),
      ],
    );
  }

  Widget _buildTechnicalStackStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _skillController,
                decoration: const InputDecoration(labelText: 'Add a skill'),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _addSkill, child: const Text('Add')),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _technicalSkills
              .map(
                (skill) => Chip(
                  label: Text(skill),
                  onDeleted: () => _removeSkill(skill),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        const Text('Add 3 to 5 core technical skills.'),
      ],
    );
  }

  Widget _buildSocialStep() {
    return Column(
      children: [
        TextField(
          controller: _githubController,
          decoration: const InputDecoration(labelText: 'GitHub URL'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _linkedinController,
          decoration: const InputDecoration(labelText: 'LinkedIn URL'),
        ),
      ],
    );
  }

  Widget _buildLanguageStep() {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<InterviewLanguage>(
        segments: const [
          ButtonSegment(
            value: InterviewLanguage.english,
            label: Text('English'),
          ),
          ButtonSegment(value: InterviewLanguage.arabic, label: Text('Arabic')),
          ButtonSegment(value: InterviewLanguage.mixed, label: Text('Mixed')),
        ],
        selected: <InterviewLanguage>{selectedInterviewLanguage},
        onSelectionChanged: (selection) {
          setState(() => selectedInterviewLanguage = selection.first);
        },
      ),
    );
  }
}
