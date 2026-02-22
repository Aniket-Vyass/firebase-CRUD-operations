import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  //.instance means we are using the one single Firebase auth object that already exists — we don't create a new one.
  final _auth = FirebaseAuth.instance;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false; // true = show spinner, false = show button
  bool _otpSent = false; //false = OTP not sent yet, phone field active,
  String? _errorMessage; // holds the error text shown on screen.
  String? _verificationId; //when OTP is sent, Firebase gives us varifID

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ── STEP 1: Send OTP ─────────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter your phone number.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,

      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android only — Firebase auto-verifies without user typing anything
        await _auth.signInWithCredential(credential);
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      },

      verificationFailed: (FirebaseAuthException e) {
        // Something went wrong — wrong format, Firebase not set up, etc.
        setState(() {
          _errorMessage = e.message ?? 'Verification failed. Try again.';
          _isLoading = false;
        });
      },

      codeSent: (String verificationId, int? resendToken) {
        // OTP sent! Save verificationId — we NEED it in step 2
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _isLoading = false;
        });
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        // OTP expired — quietly update the verificationId
        _verificationId = verificationId;
      },
    );
  }

  // ── STEP 2: Verify OTP ───────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length < 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Combine verificationId + OTP code into a credential
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Pass credential to Firebase — if code matches, user is logged in
      await _auth.signInWithCredential(credential);

      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.code == 'invalid-verification-code'
            ? 'Wrong OTP. Please check and try again.'
            : 'Something went wrong. Please try again.';
      });
    } finally {
      // always runs — success or fail — stop the spinner
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon & Title
                  const Icon(
                    Icons.phone_outlined,
                    size: 64,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Phone Login',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your number and verify with OTP',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 28),

                  // Phone Field — disabled after OTP is sent
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !_otpSent,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+91xxxxxxxxxx',
                      prefixIcon: const Icon(Icons.phone),
                      border: const OutlineInputBorder(),
                      // green tick appears once OTP is sent
                      suffixIcon: _otpSent
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // OTP Field — disabled until OTP is sent
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    enabled: _otpSent,
                    decoration: InputDecoration(
                      labelText: '6-digit OTP',
                      prefixIcon: const Icon(Icons.sms_outlined),
                      border: const OutlineInputBorder(),
                      hintText: _otpSent ? '' : 'Send OTP first',
                    ),
                  ),

                  // Error Message — only shows when there is an error
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Button — Send OTP in step 1, Verify OTP in step 2
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _otpSent
                          ? _verifyOtp
                          : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _otpSent ? 'Verify OTP' : 'Send OTP',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),

                  // Resend Button — only appears after OTP is sent
                  // resets everything back to step 1
                  if (_otpSent) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _otpSent = false;
                          _otpController.clear();
                          _errorMessage = null;
                        });
                      },
                      child: const Text('Resend OTP'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
