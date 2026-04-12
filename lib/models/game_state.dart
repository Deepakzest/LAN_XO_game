class GameState {
  GameState({
    required this.mySymbol,
    required this.opponentSymbol,
    required this.isMyTurn,
    this.myScore = 0,
    this.opponentScore = 0,
  }) : board = List<String>.filled(9, '');

  final String mySymbol;
  final String opponentSymbol;
  final List<String> board;

  bool isMyTurn;
  String? winner;
  bool isDraw = false;
  int myScore;
  int opponentScore;

  bool get gameFinished => winner != null || isDraw;

  bool isIndexValid(int index) => index >= 0 && index < board.length;

  bool canPlaceAt(int index) {
    return isIndexValid(index) && board[index].isEmpty && !gameFinished;
  }

  bool placeMove(int index, String symbol) {
    if (!canPlaceAt(index)) {
      return false;
    }

    board[index] = symbol;
    _evaluateBoard();
    return true;
  }

  void resetRound({required bool hostStarts}) {
    for (int i = 0; i < board.length; i++) {
      board[i] = '';
    }
    winner = null;
    isDraw = false;
    isMyTurn = hostStarts ? mySymbol == 'X' : mySymbol == 'O';
  }

  void _evaluateBoard() {
    winner = detectWinner(board);
    if (winner == null && board.every((cell) => cell.isNotEmpty)) {
      isDraw = true;
    }
  }

  static String? detectWinner(List<String> board) {
    const winPatterns = <List<int>>[
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (final pattern in winPatterns) {
      final a = board[pattern[0]];
      final b = board[pattern[1]];
      final c = board[pattern[2]];
      if (a.isNotEmpty && a == b && b == c) {
        return a;
      }
    }

    return null;
  }
}
