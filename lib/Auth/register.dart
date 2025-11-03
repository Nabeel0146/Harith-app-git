// lib/register_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:harithapp/Screens/mainscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _referredByCtrl = TextEditingController(); // New controller for referred by field
  final _deliveryAddressCtrl = TextEditingController(); // New controller for delivery address

  // Dropdown values
  String? _selectedPanchayath;
  String? _selectedWard;
  List<String> _panchayathNames = [];
  List<String> _wardsForPanchayath = [];

  bool _loading = false;
  bool _checkingRegistration = true;
  bool _sharedPrefsError = false;
  bool _validatingFacilitator = false;
  String? _facilitatorValidationMessage;

  // Shared Preferences keys
  static const String _isRegisteredKey = 'isRegistered';
  static const String _userIdKey = 'userId';

  // SharedPreferences instance
  SharedPreferences? _prefs;

  /* ----------  Shared Preferences Methods  ---------- */
  Future<void> _initializeSharedPreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _sharedPrefsError = false;
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      _sharedPrefsError = true;
    }
  }

  Future<bool> get isUserRegistered async {
    if (_prefs == null) {
      await _initializeSharedPreferences();
    }
    return _prefs?.getBool(_isRegisteredKey) ?? false;
  }

  Future<void> setUserRegistered(String userId) async {
    if (_prefs == null) {
      await _initializeSharedPreferences();
    }
    try {
      await _prefs?.setBool(_isRegisteredKey, true);
      await _prefs?.setString(_userIdKey, userId);
    } catch (e) {
      print('Error saving to SharedPreferences: $e');
      _sharedPrefsError = true;
    }
  }

  Future<void> clearUserRegistration() async {
    if (_prefs == null) {
      await _initializeSharedPreferences();
    }
    try {
      await _prefs?.remove(_isRegisteredKey);
      await _prefs?.remove(_userIdKey);
    } catch (e) {
      print('Error clearing SharedPreferences: $e');
      _sharedPrefsError = true;
    }
  }

  /* ----------  Check Registration Status  ---------- */
  Future<void> _checkRegistrationStatus() async {
    try {
      // Initialize SharedPreferences first
      await _initializeSharedPreferences();
      
      // If SharedPreferences failed to initialize, skip the check
      if (_sharedPrefsError) {
        print('Skipping registration check due to SharedPreferences error');
        setState(() {
          _checkingRegistration = false;
        });
        return;
      }

      // Check if user is already registered in SharedPreferences
      final bool registered = await isUserRegistered;
      
      if (registered) {
        // If registered, check if user data exists in Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('harith-users')
              .doc(user.uid)
              .get();
              
          if (userDoc.exists) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
            return;
          } else {
            // User data doesn't exist in Firestore, clear registration
            await clearUserRegistration();
          }
        }
      }
    } catch (e) {
      print('Error checking registration: $e');
      // If there's any error, just show the registration form
    } finally {
      if (mounted) {
        setState(() {
          _checkingRegistration = false;
        });
      }
    }
  }

  /* ----------  Firestore fetchers  ---------- */
  Future<void> _fetchPanchayaths() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('harith-panchayaths')
          .get();
      
      setState(() {
        _panchayathNames = snap.docs
            .map((d) => d['name']?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
        _panchayathNames.sort();
      });
    } catch (e) {
      print('Error fetching panchayaths: $e');
    }
  }

  Future<void> _fetchWards(String panchayath) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('harith-wards')
          .where('panchayath', isEqualTo: panchayath)
          .get();

      setState(() {
        _wardsForPanchayath = snap.docs
            .map((d) => (d['number'] ?? '').toString())
            .where((e) => e.isNotEmpty)
            .toList();
        _wardsForPanchayath.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
        _selectedWard = null; // reset ward on panchayath change
      });
    } catch (e) {
      print('Error fetching wards: $e');
    }
  }

  /* ----------  Facilitator Validation  ---------- */
  Future<void> _validateFacilitatorCode() async {
    final code = _referredByCtrl.text.trim();
    if (code.isEmpty) {
      setState(() {
        _facilitatorValidationMessage = null;
      });
      return;
    }

    setState(() {
      _validatingFacilitator = true;
      _facilitatorValidationMessage = null;
    });

    try {
      final facilitatorQuery = await FirebaseFirestore.instance
          .collection('harith-facilitators')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (facilitatorQuery.docs.isNotEmpty) {
        final facilitator = facilitatorQuery.docs.first.data();
        setState(() {
          _facilitatorValidationMessage = '✓ Valid facilitator: ${facilitator['name']}';
        });
      } else {
        setState(() {
          _facilitatorValidationMessage = '✗ Invalid facilitator code';
        });
      }
    } catch (e) {
      print('Error validating facilitator: $e');
      setState(() {
        _facilitatorValidationMessage = 'Error validating code';
      });
    } finally {
      setState(() {
        _validatingFacilitator = false;
      });
    }
  }

  /* ----------  Lifecycle  ---------- */
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _checkRegistrationStatus();
    await _fetchPanchayaths();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _mobileCtrl.dispose();
    _referredByCtrl.dispose();
    _deliveryAddressCtrl.dispose(); // Dispose the new controller
    super.dispose();
  }

  /* ----------  Submit - Save to harith-users collection  ---------- */
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPanchayath == null || _selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both panchayath and ward'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate facilitator code if provided
    final facilitatorCode = _referredByCtrl.text.trim();
    if (facilitatorCode.isNotEmpty && _facilitatorValidationMessage?.startsWith('✗') == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid facilitator code or leave it empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ??
          (await FirebaseAuth.instance.signInAnonymously()).user!.uid;

      // Prepare user data
      final userData = {
        'fullName': _fullNameCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'panchayath': _selectedPanchayath,
        'wardNo': int.tryParse(_selectedWard!) ?? 0,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': uid,
        'email': user?.email, // Optional: store email if available
        'lastLogin': FieldValue.serverTimestamp(),
      };

      // Add facilitator code if provided and valid
      if (facilitatorCode.isNotEmpty && _facilitatorValidationMessage?.startsWith('✓') == true) {
        userData['facilitatorCode'] = facilitatorCode;
        userData['referredBy'] = facilitatorCode; // Store in both fields for compatibility
      }

      // Add delivery address if provided
      final deliveryAddress = _deliveryAddressCtrl.text.trim();
      if (deliveryAddress.isNotEmpty) {
        userData['deliveryAddress'] = deliveryAddress;
      }

      // Save user data to harith-users collection
      await FirebaseFirestore.instance.collection('harith-users').doc(uid).set(
        userData,
        SetOptions(merge: true),
      );

      // Try to save registration status to SharedPreferences
      // If it fails, we'll still proceed since Firestore has the data
      try {
        await setUserRegistered(uid);
      } catch (e) {
        print('Warning: Could not save to SharedPreferences: $e');
        // Continue even if SharedPreferences fails
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      print('Error during registration: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /* ----------  Logout/Unregister Method  ---------- */
  Future<void> _logout() async {
    try {
      await clearUserRegistration();
    } catch (e) {
      print('Error clearing SharedPreferences: $e');
    }
    await FirebaseAuth.instance.signOut();
    // This will trigger a rebuild and show the registration form again
    setState(() {
      _checkingRegistration = false;
    });
  }

  /* ----------  UI helpers  ---------- */
  Widget _textField(String label, TextEditingController c,
      {TextInputType kb = TextInputType.text, bool isOptional = false, int maxLines = 1}) {
    return TextFormField(
      controller: c,
      keyboardType: kb,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label + (isOptional ? ' (Optional)' : ''),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (v) {
        if (!isOptional && (v == null || v.trim().isEmpty)) {
          return 'Required';
        }
        if (kb == TextInputType.phone && v!.trim().isNotEmpty) {
          if (v.trim().length != 10) {
            return 'Enter a valid 10-digit mobile number';
          }
          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) {
            return 'Enter a valid Indian mobile number';
          }
        }
        return null;
      },
    );
  }

  Widget _referredByField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _referredByCtrl,
          decoration: InputDecoration(
            labelText: 'Referred by (Facilitator Code) - Optional',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: _validatingFacilitator
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          onChanged: (value) {
            // Debounce validation
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _validateFacilitatorCode();
            });
          },
        ),
        if (_facilitatorValidationMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Text(
              _facilitatorValidationMessage!,
              style: TextStyle(
                fontSize: 12,
                color: _facilitatorValidationMessage!.startsWith('✓') 
                    ? Colors.green 
                    : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(height: 4),
        const Text(
          'Enter the facilitator code if someone referred you',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _deliveryAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textField(
          'Delivery Address',
          _deliveryAddressCtrl,
          isOptional: true,
          maxLines: 3,
        ),
        const SizedBox(height: 4),
        const Text(
          'Enter your complete delivery address for easier order delivery',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _panchayathDropDown() {
    return DropdownButtonFormField<String>(
      value: _selectedPanchayath,
      decoration: _dropdownDecoration('Panchayath'),
      items: _panchayathNames
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  style: const TextStyle(fontSize: 16),
                ),
              ))
          .toList(),
      onChanged: (val) {
        setState(() {
          _selectedPanchayath = val;
          _wardsForPanchayath.clear();
          _selectedWard = null;
        });
        if (val != null) _fetchWards(val);
      },
      validator: (_) => _selectedPanchayath == null ? 'Please select a panchayath' : null,
    );
  }

  Widget _wardDropDown() {
    return DropdownButtonFormField<String>(
      value: _selectedWard,
      decoration: _dropdownDecoration('Ward No.'),
      items: _wardsForPanchayath
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(
                  'Ward $e',
                  style: const TextStyle(fontSize: 16),
                ),
              ))
          .toList(),
      onChanged: _wardsForPanchayath.isEmpty ? null : (val) {
        setState(() => _selectedWard = val);
      },
      validator: (_) => _selectedWard == null ? 'Please select a ward' : null,
    );
  }

  InputDecoration _dropdownDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  /* ----------  Build  ---------- */
  @override
  Widget build(BuildContext context) {
    // Show loading while checking registration status
    if (_checkingRegistration) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/harithagramamlogogreen.png', height: 120),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                color: Color.fromARGB(255, 113, 187, 117),
              ),
              const SizedBox(height: 20),
              const Text(
                'Checking registration...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              if (_sharedPrefsError) ...[
                const SizedBox(height: 10),
                const Text(
                  'Loading registration form...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Image.asset('assets/harithagramamlogogreen.png', height: 100),
            const SizedBox(height: 8),
            const Text(
              'Register',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Register to Harithagramam App',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 113, 187, 117),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_sharedPrefsError) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: const Text(
                              'Note: App data may not persist after closing',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _textField('Full Name', _fullNameCtrl),
                        const SizedBox(height: 16),
                        _textField('Mobile', _mobileCtrl, kb: TextInputType.phone),
                        const SizedBox(height: 16),
                       
                        _panchayathDropDown(),
                        const SizedBox(height: 16),
                        _wardDropDown(),
                        const SizedBox(height: 16),
                        _deliveryAddressField(), // New delivery address field
                        const SizedBox(height: 16),
                        _referredByField(), // Facilitator code field
                        const SizedBox(height: 16),
                        
                        ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color.fromARGB(255, 113, 187, 117),
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Color.fromARGB(255, 113, 187, 117),
                                  ),
                                )
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        // Optional: Add a logout button for testing
                        TextButton(
                          onPressed: _logout,
                          child: const Text(
                            'Clear Registration',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}