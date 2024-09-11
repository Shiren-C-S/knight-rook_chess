import 'package:flutter/material.dart';

void main() {
  runApp(ChessGame());
}

class ChessAssets {
  static const String whiteKnight = 'images/knight_white.png';
  static const String blackKnight = 'images/knight_black.png';
  static const String whiteRook = 'images/rook_white.png';
  static const String blackRook = 'images/rook_black.png';
}

class ChessGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BoardSelectionPage(),
    );
  }
}

class BoardSelectionPage extends StatefulWidget {
  @override
  _BoardSelectionPageState createState() => _BoardSelectionPageState();
}

class _BoardSelectionPageState extends State<BoardSelectionPage> {
  int boardSize = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Board Size'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Board Size: $boardSize x $boardSize', style: TextStyle(fontSize: 20)),
          Slider(
            value: boardSize.toDouble(),
            min: 3,
            max: 8,
            divisions: 5,
            label: '$boardSize',
            onChanged: (double value) {
              setState(() {
                boardSize = value.toInt();
              });
            },
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChessBoardPage(boardSize: boardSize),
                ),
              );
            },
            child: Text('Start Game'),
          ),
        ],
      ),
    );
  }
}

class ChessBoardPage extends StatefulWidget {
  final int boardSize;

  ChessBoardPage({required this.boardSize});

  @override
  _ChessBoardPageState createState() => _ChessBoardPageState();
}

class _ChessBoardPageState extends State<ChessBoardPage> {
  List<List<int?>> board = [];
  List<List<bool>> validMoves = [];
  bool whiteTurn = true;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  void _initializeBoard() {
    setState(() {
      board = List.generate(widget.boardSize, (_) => List.generate(widget.boardSize, (_) => null));
      validMoves = List.generate(widget.boardSize, (_) => List.generate(widget.boardSize, (_) => false));

      // Place rooks (elephants)
      if (widget.boardSize > 4) {
        board[0][0] = 2; // White rook 1
        board[0][widget.boardSize - 1] = 2; // White rook 2
        board[widget.boardSize - 1][0] = -2; // Black rook 1
        board[widget.boardSize - 1][widget.boardSize - 1] = -2; // Black rook 2
      }

      // Place knights
      board[0][1] = 1; // White knight 1
      board[0][widget.boardSize - 2] = 1; // White knight 2
      board[widget.boardSize - 1][1] = -1; // Black knight 1
      board[widget.boardSize - 1][widget.boardSize - 2] = -1; // Black knight 2
    });
  }

  void _showValidMoves(int x, int y) {
    setState(() {
      validMoves = List.generate(widget.boardSize, (_) => List.generate(widget.boardSize, (_) => false));
      List<List<int>> possibleMoves = [];

      // Determine if it's a knight or a rook
      if (board[x][y] == 1 || board[x][y] == -1) {
        // Knight moves
        possibleMoves = [
          [x + 2, y + 1], [x + 2, y - 1], [x - 2, y + 1], [x - 2, y - 1],
          [x + 1, y + 2], [x + 1, y - 2], [x - 1, y + 2], [x - 1, y - 2]
        ];
      } else if (board[x][y] == 2 || board[x][y] == -2) {
        // Rook moves (Horizontal and Vertical)
        for (int i = 0; i < widget.boardSize; i++) {
          if (i != x) possibleMoves.add([i, y]); // Vertical moves
          if (i != y) possibleMoves.add([x, i]); // Horizontal moves
        }
      }

      // Validate possible moves
      for (var move in possibleMoves) {
        int newX = move[0];
        int newY = move[1];
        if (newX >= 0 && newX < widget.boardSize && newY >= 0 && newY < widget.boardSize) {
          validMoves[newX][newY] = true;
        }
      }
    });
  }

  void _movePiece(int x, int y) {
    setState(() {
      if (board[x][y] == null || board[x][y] != board[selectedX!][selectedY!]) {
        board[x][y] = board[selectedX!][selectedY!];
        board[selectedX!][selectedY!] = null; // Clear previous position
        selectedX = null;
        selectedY = null;
        validMoves = List.generate(widget.boardSize, (_) => List.generate(widget.boardSize, (_) => false)); // Clear valid moves

        // Check for win condition
        _checkWinCondition();

        // Switch turn
        whiteTurn = !whiteTurn;
      }
    });
  }

  void _checkWinCondition() {
    bool whiteWin = !board.any((row) => row.contains(2)) && !board.any((row) => row.contains(1));
    bool blackWin = !board.any((row) => row.contains(-2)) && !board.any((row) => row.contains(-1));

    if (whiteWin || blackWin) {
      String winner = whiteWin ? "Black Wins!" : "White Wins!";
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(winner),
            content: Text('Game Over'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _initializeBoard(); // Reset the game
                },
                child: Text('Restart'),
              ),
            ],
          );
        },
      );
    }
  }

  int? selectedX;
  int? selectedY;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.boardSize} x ${widget.boardSize} Chess Board'),
      ),
      body: Column(
        children: [
          Text(
            whiteTurn ? 'White\'s Turn' : 'Black\'s Turn',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.boardSize,
              ),
              itemCount: widget.boardSize * widget.boardSize,
              itemBuilder: (context, index) {
                int x = index ~/ widget.boardSize;
                int y = index % widget.boardSize;
                int? piece = board[x][y];
                bool isValidMove = validMoves[x][y];

                return GestureDetector(
                  onTap: () {
                    if (piece != null && ((piece > 0 && whiteTurn) || (piece < 0 && !whiteTurn))) {
                      if (selectedX == null) {
                        // Select piece to move
                        setState(() {
                          selectedX = x;
                          selectedY = y;
                          _showValidMoves(x, y); // Show valid moves for the selected piece
                        });
                      } else if (selectedX == x && selectedY == y) {
                        // Deselect piece
                        setState(() {
                          selectedX = null;
                          selectedY = null;
                          validMoves = List.generate(widget.boardSize, (_) => List.generate(widget.boardSize, (_) => false)); // Clear valid moves
                        });
                      } else if (isValidMove) {
                        _movePiece(x, y); // Move piece if the cell is a valid move
                      }
                    } else if (selectedX != null && selectedY != null && isValidMove) {
                      _movePiece(x, y); // Move piece if the cell is a valid move
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.all(2),
                    color: (x + y) % 2 == 0 ? Colors.grey[300] : Colors.grey[700],
                    child: Center(
                      child: piece != null
                          ? Image.asset(
                              piece == 1
                                  ? ChessAssets.whiteKnight
                                  : piece == -1
                                      ? ChessAssets.blackKnight
                                      : piece == 2
                                          ? ChessAssets.whiteRook
                                          : ChessAssets.blackRook,
                              width: 40,
                              height: 40,
                            )
                          : isValidMove
                              ? Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green.withOpacity(0.7),
                                  ),
                                )
                              : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
