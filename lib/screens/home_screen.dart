import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/socket_service.dart';
import '../utils/constants.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _ipController = TextEditingController();
  final SocketService _socketService = SocketService.instance;

  StreamSubscription<String>? _errorSubscription;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _errorSubscription = _socketService.onError.listen((error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(error);
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _errorSubscription?.cancel();
    super.dispose();
  }

  Future<void> _hostGame() async {
    String? ip;
    StreamSubscription<void>? connectedSubscription;

    try {
      ip = await _socketService.getLocalIpAddress();
      if (ip == null) {
        _showSnackBar('Could not detect local WiFi IP address.');
        return;
      }

      await _socketService.startServer();

      if (!mounted) {
        return;
      }

      connectedSubscription = _socketService.onConnected.listen((_) {
        if (!mounted) {
          return;
        }

        Navigator.of(context, rootNavigator: true).maybePop();
        connectedSubscription?.cancel();

        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GameScreen(
              isHost: true,
              opponentIp: _socketService.remoteIpAddress ?? 'Unknown',
            ),
          ),
        );
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.panel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.border),
            ),
            title: const Text('Hosting Game'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share this IP with your opponent:',
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                SelectableText(
                  '$ip:${AppConstants.serverPort}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neonBlue,
                  ),
                ),
                const SizedBox(height: 16),
                const LinearProgressIndicator(minHeight: 4),
                const SizedBox(height: 8),
                const Text('Waiting for client connection...'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  connectedSubscription?.cancel();
                  Navigator.of(dialogContext).pop();
                  _socketService.shutdown();
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      connectedSubscription?.cancel();
      await _socketService.shutdown();
      if (mounted) {
        _showSnackBar('Failed to host game: $error');
      }
    }
  }

  Future<void> _joinGame() async {
    if (_isJoining) {
      return;
    }

    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      _showSnackBar('Enter host IP address.');
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      await _socketService.connectToServer(ip);
      if (!mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(
            isHost: false,
            opponentIp: ip,
          ),
        ),
      );
    } on FormatException {
      _showSnackBar('Invalid IP format. Example: 192.168.43.1');
    } on SocketException catch (error) {
      _showSnackBar('Connection failed: ${error.message}');
    } catch (error) {
      _showSnackBar('Could not connect: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.subtle),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Hotspot Tic Tac Toe',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Play 1v1 over local WiFi using TCP sockets.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    _ActionCard(
                      title: 'Host Game',
                      subtitle:
                          'Start a local server on port ${AppConstants.serverPort} and wait for your friend.',
                      child: _GradientButton(
                        label: 'Start Hosting',
                        onPressed: _hostGame,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ActionCard(
                      title: 'Join Game',
                      subtitle:
                          'Enter host IP from the hotspot device and connect.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _ipController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'e.g. 192.168.43.1',
                              hintStyle: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1C1C1C),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.neonBlue,
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _GradientButton(
                            label: _isJoining ? 'Connecting...' : 'Join Match',
                            onPressed: _isJoining ? null : _joinGame,
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
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33115DFF),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x558A2EFF),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
