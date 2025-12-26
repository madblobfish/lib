# Minesweeper game
A super small Minesweeper game in under 2666 Characters. Programmed for exercise by the Object calisthenic rules.


# How to play
Start with ruby Minesweeper.rb [size of the minefield] [number of mines]
To uncover a cell type in the coordinates (x,y) starting from top left 0,0.
When a bomb is uncovered it explodes and you lose.
In the other case a number is shown which tells how many bombs are in the 8 cells around.
The goal is to uncover everything but the bombs.


# Features
* Auto reveal (when a 0 is uncovered it uncovers all 8 surrounding cells)
* Square size can be chosen (first parameter)
* Number of Mines can be chosen (second parameter)
* Tests for winning condition and quits
* Quits on bomb (shows bomb with * symbol)
* some broken inputs work ("number" => only x, ",number" => only y)


# Programming Features
* ruby
* Object calisthenic

# Object calistenic rules:
* only one indentation depth (no double loops or ifs and so on)
* no else
* encapsulate all primitive datatypes (not for constructors)
* one method call per line (math, keywords or new does not count)
* no acronyms, max 3 words per name
* max 10 lines per method
* max 50 lines per class
* only two instance variables (one when it contains multiple values for example Array, Map or Hash)
* no getters, setters (instance variables are not changed directly or given)

## Violations?
* violated one indentation depth in Field.rb:37
* not sure about encapsulations (instructions unclear...)
