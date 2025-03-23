import 'package:flutter/material.dart';
import 'package:qrqragain/login/create/login.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _spreadAnimation;
  late Animation<double> _fadeAnimation;
  bool _showGif = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _spreadAnimation = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      setState(() {
        _showGif = true;
      });

      Future.delayed(const Duration(seconds: 4), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              Container(
                color:
                    _spreadAnimation.value >= 1.0
                        ? const Color.fromARGB(255, 242, 239, 231)
                        : const Color.fromARGB(255, 100, 122, 99),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: screenWidth * _spreadAnimation.value,
                  height: screenHeight * _spreadAnimation.value,
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 242, 239, 231),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(300),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: screenWidth * _spreadAnimation.value,
                  height: screenHeight * _spreadAnimation.value,
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 242, 239, 231),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(300),
                    ),
                  ),
                ),
              ),
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Image.asset(
                    'assets/Bulacan_Seal.svg.png', // Replace with your logo asset path
                    width: 200,
                    height: 200,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
