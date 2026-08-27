import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

const storage = FlutterSecureStorage();

const String baseUrl = 'http://10.0.2.2:8000/api';

void main() {
  runApp(const MartinisLoyaltyApp());
}

class MartinisLoyaltyApp extends StatelessWidget {
  const MartinisLoyaltyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Martinis & Manicures',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4F1EA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA48D78),
        ),
        useMaterial3: true,
      ),
      home: const AuthCheckScreen(),
    );
  }
}

// ============================================================
// CHECK IF CUSTOMER IS ALREADY LOGGED IN
// ============================================================

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final token = await storage.read(
      key: 'auth_token',
    );

    final name = await storage.read(
      key: 'customer_name',
    );

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            name: name ?? 'Customer',
            token: token,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F1EA),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFA48D78),
        ),
      ),
    );
  }
}

// ============================================================
// LOGIN SCREEN
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage(
        'Please enter your email and password.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final String token = data['token'];
        final String name = data['user']['name'];

        await storage.write(
          key: 'auth_token',
          value: token,
        );

        await storage.write(
          key: 'customer_name',
          value: name,
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              name: name,
              token: token,
            ),
          ),
        );
      } else {
        String message =
            data['message'] ?? 'Login failed.';

        if (data['errors'] != null &&
            data['errors']['email'] != null) {
          message =
              data['errors']['email'][0].toString();
        }

        showMessage(message);
      }
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'Unable to connect to the server. '
        'Make sure Laravel is running.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/martinis-logo.png',
                    width: 320,
                    fit: BoxFit.contain,
                    semanticLabel:
                        'Martinis and Manicures logo',
                  ),

                  const SizedBox(height: 50),

                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF9F6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE6DAC8),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 28,
                            color: Color(0xFF493B32),
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Sign in to access your loyalty membership.',
                          style: TextStyle(
                            color: Color(0xFF8B796A),
                          ),
                        ),

                        const SizedBox(height: 30),

                        const Text(
                          'Email Address',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5C4C40),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: emailController,
                          keyboardType:
                              TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText:
                                'customer@example.com',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Password',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5C4C40),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: passwordController,
                          obscureText: hidePassword,
                          decoration: InputDecoration(
                            hintText:
                                'Enter your password',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  hidePassword =
                                      !hidePassword;
                                });
                              },
                              icon: Icon(
                                hidePassword
                                    ? Icons
                                        .visibility_off_outlined
                                    : Icons
                                        .visibility_outlined,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                isLoading ? null : login,
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFA48D78),
                              foregroundColor:
                                  Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'SIGN IN',
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                      letterSpacing: 2,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ActivationScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Activate your membership',
                              style: TextStyle(
                                color:
                                    Color(0xFFA48D78),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CUSTOMER ACTIVATION SCREEN
// ============================================================

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() =>
      _ActivationScreenState();
}

class _ActivationScreenState
    extends State<ActivationScreen> {
  final membershipController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  final confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;
  bool hideConfirmPassword = true;

  Future<void> activateMembership() async {
    final membershipCode = membershipController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final passwordConfirmation =
        confirmPasswordController.text;

    if (membershipCode.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        passwordConfirmation.isEmpty) {
      showMessage('Please complete all fields.');
      return;
    }

    if (password != passwordConfirmation) {
      showMessage('Passwords do not match.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer/activate'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'membership_code': membershipCode,
          'phone': phone,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      debugPrint('ACTIVATION STATUS: ${response.statusCode}');
      debugPrint('ACTIVATION BODY: ${response.body}');

      Map<String, dynamic> data = {};

      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      }

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final token = data['token']?.toString();
        final user = data['user'];
        final name = user is Map
            ? user['name']?.toString()
            : null;

        if (token == null || name == null) {
          showMessage(
            'Account was activated, but the server response was incomplete.',
          );
          return;
        }

        await storage.write(
          key: 'auth_token',
          value: token,
        );

        await storage.write(
          key: 'customer_name',
          value: name,
        );

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              name: name,
              token: token,
            ),
          ),
          (route) => false,
        );
      } else {
        String message =
            data['message']?.toString() ?? 'Activation failed.';

        if (data['errors'] is Map) {
          final errors = data['errors'] as Map;

          if (errors.isNotEmpty) {
            final firstError = errors.values.first;

            if (firstError is List && firstError.isNotEmpty) {
              message = firstError.first.toString();
            }
          }
        }

        showMessage(
          'Error ${response.statusCode}: $message',
        );
      }
    } on FormatException {
      if (!mounted) return;

      showMessage(
        'Server returned an invalid activation response. '
        'Check the Laravel logs for the real error.',
      );
    } catch (e) {
      debugPrint('ACTIVATION EXCEPTION: $e');

      if (!mounted) return;

      showMessage(
        'Unable to connect to the server. '
        'Make sure Laravel is running.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    membershipController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F1EA),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF4F1EA),
        elevation: 0,
        foregroundColor:
            const Color(0xFF493B32),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),

          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 420,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACTIVATE MEMBERSHIP',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2.5,
                      color:
                          Color(0xFFA48D78),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Create Your Account',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 30,
                      color:
                          Color(0xFF493B32),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Enter the membership information registered at Martinis & Manicures.',
                    style: TextStyle(
                      color:
                          Color(0xFF8B796A),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Container(
                    padding:
                        const EdgeInsets.all(
                      24,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFFAF9F6,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(20),
                      border: Border.all(
                        color:
                            const Color(
                          0xFFE6DAC8,
                        ),
                      ),
                    ),

                    child: Column(
                      children: [
                        TextField(
                          controller:
                              membershipController,
                          textCapitalization:
                              TextCapitalization
                                  .characters,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Membership Code',
                            hintText:
                                'MM-XXXXXXXX',
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        TextField(
                          controller:
                              phoneController,
                          keyboardType:
                              TextInputType.phone,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Registered Phone Number',
                            hintText:
                                '09XXXXXXXXX',
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        TextField(
                          controller:
                              emailController,
                          keyboardType:
                              TextInputType
                                  .emailAddress,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Email Address',
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        TextField(
                          controller:
                              passwordController,
                          obscureText:
                              hidePassword,
                          decoration:
                              InputDecoration(
                            labelText:
                                'Password',
                            suffixIcon:
                                IconButton(
                              onPressed: () {
                                setState(() {
                                  hidePassword =
                                      !hidePassword;
                                });
                              },
                              icon: Icon(
                                hidePassword
                                    ? Icons
                                        .visibility_off_outlined
                                    : Icons
                                        .visibility_outlined,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        TextField(
                          controller:
                              confirmPasswordController,
                          obscureText:
                              hideConfirmPassword,
                          decoration:
                              InputDecoration(
                            labelText:
                                'Confirm Password',
                            suffixIcon:
                                IconButton(
                              onPressed: () {
                                setState(() {
                                  hideConfirmPassword =
                                      !hideConfirmPassword;
                                });
                              },
                              icon: Icon(
                                hideConfirmPassword
                                    ? Icons
                                        .visibility_off_outlined
                                    : Icons
                                        .visibility_outlined,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 26,
                        ),

                        SizedBox(
                          width:
                              double.infinity,
                          height: 52,
                          child:
                              ElevatedButton(
                            onPressed: isLoading ? null : activateMembership,
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFFA48D78,
                              ),
                              foregroundColor:
                                  Colors.white,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                      color:
                                          Colors
                                              .white,
                                    ),
                                  )
                                : const Text(
                                    'ACTIVATE ACCOUNT',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                      letterSpacing:
                                          1.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CUSTOMER HOME / DIGITAL LOYALTY CARD
// ============================================================

class HomeScreen extends StatefulWidget {
  final String name;
  final String token;

  const HomeScreen({
    super.key,
    required this.name,
    required this.token,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  bool isLoading = true;

  String? errorMessage;

  Map<String, dynamic>? customer;
  Map<String, dynamic>? membership;

  @override
  void initState() {
    super.initState();
    loadMembership();
  }

  Future<void> loadMembership() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/customer/membership',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization':
              'Bearer ${widget.token}',
        },
      );

      final data =
          jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          customer =
              data['customer'];

          membership =
              data['membership'];

          isLoading = false;

          errorMessage = null;
        });
      } else if (response.statusCode ==
          401) {
        await storage.delete(
          key: 'auth_token',
        );

        await storage.delete(
          key: 'customer_name',
        );

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const LoginScreen(),
          ),
          (route) => false,
        );
      } else {
        setState(() {
          errorMessage =
              data['message'] ??
                  'Unable to load membership.';

          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Unable to connect to the server.';

        isLoading = false;
      });
    }
  }

  Future<void> logout() async {
    await storage.delete(
      key: 'auth_token',
    );

    await storage.delete(
      key: 'customer_name',
    );

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const LoginScreen(),
      ),
      (route) => false,
    );
  }

  String formatDate(
    String? value,
  ) {
    if (value == null ||
        value.isEmpty) {
      return 'No Expiration';
    }

    try {
      final date =
          DateTime.parse(value)
              .toLocal();

      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      return '${months[date.month - 1]} '
          '${date.day}, ${date.year}';
    } catch (e) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F1EA),

      appBar: AppBar(
        automaticallyImplyLeading:
            false,

        elevation: 0,

        backgroundColor:
            const Color(0xFFFAF9F6),

        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'MARTINIS',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 17,
                letterSpacing: 3,
                color:
                    Color(0xFF493B32),
              ),
            ),
            Text(
              '& MANICURES',
              style: TextStyle(
                fontSize: 8,
                letterSpacing: 2.5,
                color:
                    Color(0xFFA48D78),
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Transaction History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionHistoryScreen(
                    token: widget.token,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF493B32),
            ),
          ),

          IconButton(
            tooltip: 'Refresh',
            onPressed: loadMembership,
            icon: const Icon(
              Icons.refresh,
              color:
                  Color(0xFF493B32),
            ),
          ),

          IconButton(
            tooltip: 'Logout',
            onPressed: logout,
            icon: const Icon(
              Icons.logout,
              color:
                  Color(0xFF493B32),
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFFA48D78),
              ),
            )
          : errorMessage != null
              ? buildError()
              : buildMembership(),
    );
  }

  Widget buildError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color:
                  Color(0xFFA48D78),
            ),

            const SizedBox(height: 20),

            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color:
                    Color(0xFF493B32),
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });

                loadMembership();
              },
              child:
                  const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMembership() {
    final plan =
        membership?['plan']
            as Map<String, dynamic>?;

    final firstName =
        customer?['first_name']
                ?.toString() ??
            '';

    final lastName =
        customer?['last_name']
                ?.toString() ??
            '';

    final fullName =
        '$firstName $lastName'
            .trim();

    final membershipCode =
        membership?['membership_code']
                ?.toString() ??
            '';

    final status =
        membership?['status']
                ?.toString() ??
            '';

    final qrToken =
        membership?['qr_token']
                ?.toString() ??
            '';

    final planName =
        plan?['name']
                ?.toString() ??
            'Loyalty Member';

    final discount =
        plan?['discount_percentage']
                ?.toString() ??
            '0';

    final discountNumber =
        double.tryParse(discount) ??
            0;

    return RefreshIndicator(
      onRefresh: loadMembership,

      color:
          const Color(0xFFA48D78),

      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'YOUR MEMBERSHIP',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2.5,
                color:
                    Color(0xFFA48D78),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Hello, $firstName',
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 28,
                color:
                    Color(0xFF493B32),
              ),
            ),

            const SizedBox(height: 24),

            // ====================================================
            // DIGITAL LOYALTY CARD
            // ====================================================

            Container(
              width: double.infinity,

              decoration: BoxDecoration(
                color:
                    const Color(
                  0xFF493B32,
                ),

                borderRadius:
                    BorderRadius.circular(
                  24,
                ),

                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black
                            .withValues(
                      alpha: 0.12,
                    ),
                    blurRadius: 20,
                    offset:
                        const Offset(
                      0,
                      8,
                    ),
                  ),
                ],
              ),

              child: Padding(
                padding:
                    const EdgeInsets.all(
                  26,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    const Text(
                      'MARTINIS & MANICURES',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing:
                            2.5,
                        color:
                            Color(
                          0xFFD8C6B4,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    const Text(
                      'Loyalty Card',
                      style: TextStyle(
                        fontFamily:
                            'serif',
                        fontSize: 26,
                        color:
                            Color(
                          0xFFFAF9F6,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    Center(
                      child: Container(
                        padding:
                            const EdgeInsets
                                .all(14),

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,

                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                        ),

                        child:
                            QrImageView(
                          data: qrToken,
                          version:
                              QrVersions
                                  .auto,
                          size: 190,
                          backgroundColor:
                              Colors
                                  .white,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    const Text(
                      'MEMBER',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 2,
                        color:
                            Color(
                          0xFFD8C6B4,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      fullName,
                      style:
                          const TextStyle(
                        fontFamily:
                            'serif',
                        fontSize: 22,
                        color:
                            Color(
                          0xFFFAF9F6,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,

                      crossAxisAlignment:
                          CrossAxisAlignment
                              .end,

                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              const Text(
                                'MEMBERSHIP',
                                style:
                                    TextStyle(
                                  fontSize:
                                      9,
                                  letterSpacing:
                                      2,
                                  color:
                                      Color(
                                    0xFFD8C6B4,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Text(
                                membershipCode,
                                style:
                                    const TextStyle(
                                  fontSize:
                                      15,
                                  letterSpacing:
                                      1,
                                  color:
                                      Color(
                                    0xFFFAF9F6,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              Text(
                                planName,
                                style:
                                    const TextStyle(
                                  color:
                                      Color(
                                    0xFFD8C6B4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .end,

                          children: [
                            const Text(
                              'DISCOUNT',
                              style:
                                  TextStyle(
                                fontSize: 9,
                                letterSpacing:
                                    2,
                                color:
                                    Color(
                                  0xFFD8C6B4,
                                ),
                              ),
                            ),

                            Text(
                              '${discountNumber.toStringAsFixed(0)}%',
                              style:
                                  const TextStyle(
                                fontFamily:
                                    'serif',
                                fontSize: 36,
                                color:
                                    Color(
                                  0xFFFAF9F6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ====================================================
            // MEMBERSHIP STATUS
            // ====================================================

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(
                20,
              ),

              decoration: BoxDecoration(
                color:
                    const Color(
                  0xFFFAF9F6,
                ),

                borderRadius:
                    BorderRadius.circular(
                  18,
                ),

                border: Border.all(
                  color:
                      const Color(
                    0xFFE6DAC8,
                  ),
                ),
              ),

              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,

                        decoration:
                            BoxDecoration(
                          color:
                              status ==
                                      'active'
                                  ? Colors
                                      .green
                                  : Colors
                                      .red,

                          shape:
                              BoxShape
                                  .circle,
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      const Text(
                        'Membership Status',
                        style: TextStyle(
                          color:
                              Color(
                            0xFF8B796A,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Text(
                        status
                            .toUpperCase(),

                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,

                          color:
                              Color(
                            0xFF493B32,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(
                    height: 32,
                    color:
                        Color(
                      0xFFE6DAC8,
                    ),
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .calendar_month_outlined,
                        color:
                            Color(
                          0xFFA48D78,
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      const Text(
                        'Valid Until',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Color(
                            0xFF8B796A,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Flexible(
                        child: Text(
                          formatDate(
                            membership?[
                                    'expires_at']
                                ?.toString(),
                          ),
                          textAlign:
                              TextAlign
                                  .right,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .w600,
                            color:
                                Color(
                              0xFF493B32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TransactionHistoryScreen(
                        token: widget.token,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.receipt_long_outlined,
                ),
                label: const Text(
                  'Transaction History',
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Center(
              child: Text(
                'Present this QR code during your visit.',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Color(
                    0xFF8B796A,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CUSTOMER TRANSACTION HISTORY
// ============================================================

class TransactionHistoryScreen extends StatefulWidget {
  final String token;

  const TransactionHistoryScreen({
    super.key,
    required this.token,
  });

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends State<TransactionHistoryScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> transactions = [];

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer/transactions'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          transactions = data is List
              ? data
              : data['transactions'] as List<dynamic>? ?? [];
          isLoading = false;
          errorMessage = null;
        });
      } else {
        setState(() {
          errorMessage = data is Map
              ? data['message']?.toString() ??
                  'Unable to load transactions.'
              : 'Unable to load transactions.';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to connect to the server.';
        isLoading = false;
      });
    }
  }

  String formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(value).toLocal();

      return '${date.month}/${date.day}/${date.year}';
    } catch (_) {
      return value;
    }
  }

  String formatMoney(dynamic value) {
    final amount =
        double.tryParse(value?.toString() ?? '');

    if (amount == null) {
      return 'PHP ${value ?? '0'}';
    }

    return 'PHP ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: const Color(0xFFFAF9F6),
        foregroundColor: const Color(0xFF493B32),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFA48D78),
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF493B32),
                      ),
                    ),
                  ),
                )
              : transactions.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No transactions yet.',
                          style: TextStyle(
                            color: Color(0xFF8B796A),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadTransactions,
                      color: const Color(0xFFA48D78),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];

                          if (transaction is! Map) {
                            return const SizedBox.shrink();
                          }

                          final items =
                              transaction['items']
                                  as List<dynamic>? ??
                                  [];

                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: 14,
                            ),
                            child: ExpansionTile(
                              title: Text(
                                'Transaction #${transaction['id']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF493B32),
                                ),
                              ),
                              subtitle: Text(
                                '${formatDate(transaction['transaction_date']?.toString())}'
                                ' - ${formatMoney(transaction['total_amount'])}',
                              ),
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  child: Column(
                                    children: [
                                      ...items.map((item) {
                                        if (item is! Map) {
                                          return const SizedBox
                                              .shrink();
                                        }

                                        return Padding(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            vertical: 6,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item[
                                                              'service_name']
                                                          ?.toString() ??
                                                      'Service',
                                                ),
                                              ),
                                              Text(
                                                formatMoney(
                                                  item[
                                                      'final_price'],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      const Divider(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                        children: [
                                          const Text('Subtotal'),
                                          Text(
                                            formatMoney(
                                              transaction[
                                                  'subtotal'],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                        children: [
                                          Text(
                                            'Discount (${transaction['discount_percentage']}%)',
                                          ),
                                          Text(
                                            '- ${formatMoney(transaction['discount_amount'])}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                        children: [
                                          const Text(
                                            'Total',
                                            style: TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            formatMoney(
                                              transaction[
                                                  'total_amount'],
                                            ),
                                            style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
