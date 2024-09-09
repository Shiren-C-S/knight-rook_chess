import 'package:flutter/material.dart';

void main() {
  runApp(ChessGame());
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
  List<List<int?>> knightPositions = [];
  int? selectedKnightX;
  int? selectedKnightY;
  bool whiteTurn = true; // Track whose turn it is

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  void _initializeBoard() {
    setState(() {
      board = List.generate(widget.boardSize, (_) => List.generate(widget.boardSize, (_) => null));
      validMoves = List.generate(widget.boardSize, (_) => List.generate(widget.boardSize, (_) => false));
      knightPositions = [
        [0, 0], // White knight 1
        [0, widget.boardSize - 1], // White knight 2
        [widget.boardSize - 1, 0], // Black knight 1
        [widget.boardSize - 1, widget.boardSize - 1], // Black knight 2
      ];
      board[0][0] = 1; // White knight 1
      board[0][widget.boardSize - 1] = 1; // White knight 2
      board[widget.boardSize - 1][0] = -1; // Black knight 1
      board[widget.boardSize - 1][widget.boardSize - 1] = -1; // Black knight 2
    });
  }

  void _showValidMoves(int x, int y) {
    setState(() {
      validMoves = List.generate(widget.boardSize, (_) => List.generate(widget.boardSize, (_) => false));
      // Calculate all valid L-shaped moves for the knight
      List<List<int>> knightMoves = [
        [x + 2, y + 1],
        [x + 2, y - 1],
        [x - 2, y + 1],
        [x - 2, y - 1],
        [x + 1, y + 2],
        [x + 1, y - 2],
        [x - 1, y + 2],
        [x - 1, y - 2]
      ];
      for (var move in knightMoves) {
        int newX = move[0];
        int newY = move[1];
        if (newX >= 0 && newX < widget.boardSize && newY >= 0 && newY < widget.boardSize) {
          validMoves[newX][newY] = true;
        }
      }
    });
  }

  void _moveKnight(int x, int y) {
    setState(() {
      // Move knight and handle capture
      if (board[x][y] == null || board[x][y] != board[selectedKnightX!][selectedKnightY!]) {
        board[x][y] = board[selectedKnightX!][selectedKnightY!];
        board[selectedKnightX!][selectedKnightY!] = null; // Clear previous position
        selectedKnightX = null;
        selectedKnightY = null;
        validMoves = List.generate(widget.boardSize, (_) => List.generate(widget.boardSize, (_) => false)); // Clear valid moves

        // Check for win condition
        _checkWinCondition();

        // Switch turn
        whiteTurn = !whiteTurn;
      }
    });
  }

  void _checkWinCondition() {
    bool whiteWin = !board.any((row) => row.contains(1));
    bool blackWin = !board.any((row) => row.contains(-1));

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
                int? knight = board[x][y];
                bool isValidMove = validMoves[x][y];

                return GestureDetector(
                  onTap: () {
                    if (knight != null && ((knight == 1 && whiteTurn) || (knight == -1 && !whiteTurn))) {
                      if (selectedKnightX == null) {
                        // Select knight to move
                        setState(() {
                          selectedKnightX = x;
                          selectedKnightY = y;
                          _showValidMoves(x, y); // Show valid moves for the selected knight
                        });
                      } else if (selectedKnightX == x && selectedKnightY == y) {
                        // Deselect knight
                        setState(() {
                          selectedKnightX = null;
                          selectedKnightY = null;
                          validMoves = List.generate(widget.boardSize, (_) => List.generate(widget.boardSize, (_) => false)); // Clear valid moves
                        });
                      } else if (isValidMove) {
                        _moveKnight(x, y); // Move knight if the cell is a valid move
                      }
                    } else if (selectedKnightX != null && selectedKnightY != null && isValidMove) {
                      _moveKnight(x, y); // Move knight if the cell is a valid move
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.all(2),
                    color: (x + y) % 2 == 0 ? Colors.grey[300] : Colors.grey[700],
                    child: Center(
                      child: knight != null
                          ? Image.asset(
                              knight == 1 ? '/Users/shiren/Documents/Flutter/chess_horse/images/knight_white.png' : '/Users/shiren/Documents/Flutter/chess_horse/images/knight_black.png',
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
                              : Container(),
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
