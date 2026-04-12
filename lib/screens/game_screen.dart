import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_state.dart';
import '../services/socket_service.dart';
import '../utils/constants.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.isHost,
    required this.opponentIp,
  });

  final bool isHost;
  final String opponentIp;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final SocketService _socketService = SocketService.instance;

  late final GameState _state;
  StreamSubscription<String>? _messageSubscription;
  StreamSubscription<void>? _disconnectSubscription;

  String get _scoreKey => 'score_${widget.opponentIp}';

  @override
  void initState() {
    super.initState();
    _state = GameState(
      mySymbol: widget.isHost ? 'X' : 'O',
      opponentSymbol: widget.isHost ? 'O' : 'X',
      isMyTurn: widget.isHost,
    );

    _attachSocketListeners();
    _loadScore();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _disconnectSubscription?.cancel();
    super.dispose();
  }

  void _attachSocketListeners() {
    // Remote state synchronization relies only on move/reset/disconnect messages.
    _messageSubscription = _socketService.onMessage.listen(_handleNetworkMessage);
    _disconnectSubscription = _socketService.onDisconnected.listen((_) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Opponent disconnected.');
      Navigator.of(context).pop();
    });
  }

  Future<void> _loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_scoreKey) ?? 0;
    if (!mounted) {
      return;
    }

    setState(() {
      _state.myScore = stored;
    });
  }

  Future<void> _persistMyScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scoreKey, _state.myScore);
  }

  void _handleNetworkMessage(String message) {
    if (!mounted) {
      return;
    }

    if (message.startsWith(AppConstants.movePrefix)) {
      final raw = message.substring(AppConstants.movePrefix.length);
      final moveIndex = int.tryParse(raw);
      if (moveIndex == null) {
        return;
      }
      _handleRemoteMove(moveIndex);
      return;
    }

    if (message == AppConstants.reset) {
      setState(() {
        _state.resetRound(hostStarts: true);
      });
      return;
    }

    if (message == AppConstants.disconnect) {
      _showSnackBar('Opponent left the game.');
      Navigator.of(context).pop();
    }
  }

  void _handleRemoteMove(int index) {
    // Protocol sends only index; local board validation prevents desync.
    if (!_state.isIndexValid(index) || !_state.canPlaceAt(index)) {
      return;
    }

    setState(() {
      _state.placeMove(index, _state.opponentSymbol);
      _state.isMyTurn = true;
      _updateScoreAfterRound();
    });
  }

  Future<void> _handleTap(int index) async {
    if (!_state.isMyTurn) {
      return;
    }
    if (!_state.canPlaceAt(index)) {
      return;
    }

    setState(() {
      _state.placeMove(index, _state.mySymbol);
      _state.isMyTurn = false;
      _updateScoreAfterRound();
    });

    _socketService.sendMessage('${AppConstants.movePrefix}$index');
  }

  void _updateScoreAfterRound() {
    if (_state.winner == _state.mySymbol) {
      _state.myScore += 1;
      _persistMyScore();
    } else if (_state.winner == _state.opponentSymbol) {
      _state.opponentScore += 1;
    }
  }

  void _resetRound() {
    setState(() {
      _state.resetRound(hostStarts: true);
    });
    _socketService.sendMessage(AppConstants.reset);
  }

  Future<void> _leaveGame() async {
    await _socketService.shutdown(notifyPeer: true);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _buildStatusText() {
    if (_state.winner != null) {
      return _state.winner == _state.mySymbol ? 'You win!' : 'Opponent wins!';
    }

    if (_state.isDraw) {
      return 'Round draw';
    }

    return _state.isMyTurn ? 'Your turn' : 'Opponent turn';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _leaveGame();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text('You: ${_state.mySymbol}'),
          actions: [
            IconButton(
              onPressed: _leaveGame,
              tooltip: 'Disconnect',
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF111111),
                Color(0xFF0D0D0D),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gridSize = constraints.maxWidth > 520
                    ? 390.0
                    : constraints.maxWidth - 34;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _scoreBoard(),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: Text(
                          _buildStatusText(),
                          key: ValueKey<String>(_buildStatusText()),
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: _state.isMyTurn
                                ? AppColors.neonBlue
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: gridSize,
                        height: gridSize,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.neonPurple),
                          gradient: AppGradients.subtle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x554B30FF),
                              blurRadius: 26,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 9,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemBuilder: (context, index) {
                            return _NeonCell(
                              value: _state.board[index],
                              enabled: _state.isMyTurn &&
                                  _state.board[index].isEmpty &&
                                  !_state.gameFinished,
                              onTap: () => _handleTap(index),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _GameButton(
                            label: 'Reset Round',
                            onTap: _resetRound,
                          ),
                          _GameButton(
                            label: 'Disconnect',
                            onTap: _leaveGame,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Opponent: ${widget.opponentIp}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreBoard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ScoreTile(label: 'You (${_state.mySymbol})', value: _state.myScore),
          Container(width: 1, height: 32, color: AppColors.border),
          _ScoreTile(label: 'Opponent (${_state.opponentSymbol})', value: _state.opponentScore),
        ],
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.neonBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GameButton extends StatelessWidget {
  const _GameButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(150, 50),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _NeonCell extends StatefulWidget {
  const _NeonCell({
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_NeonCell> createState() => _NeonCellState();
}

class _NeonCellState extends State<_NeonCell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasSymbol = widget.value.isNotEmpty;
    final color = widget.value == 'X'
        ? AppColors.neonBlue
        : widget.value == 'O'
            ? AppColors.neonPink
            : AppColors.textPrimary;

    final glow = hasSymbol
      ? color.withValues(alpha: 0.55)
      : widget.enabled
        ? AppColors.neonPurple.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.15);

    return GestureDetector(
      onTapDown: widget.enabled
          ? (_) => setState(() {
                _pressed = true;
              })
          : null,
      onTapCancel: widget.enabled
          ? () => setState(() {
                _pressed = false;
              })
          : null,
      onTapUp: widget.enabled
          ? (_) => setState(() {
                _pressed = false;
                widget.onTap();
              })
          : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.93 : 1,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.enabled ? AppColors.neonBlue : AppColors.border,
              width: widget.enabled ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: glow,
                blurRadius: _pressed ? 18 : 14,
                spreadRadius: _pressed ? 2 : 1,
              ),
            ],
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w800,
                color: color,
                shadows: [
                  Shadow(
                    color: color.withValues(alpha: 0.65),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Text(widget.value),
            ),
          ),
        ),
      ),
    );
  }
}
