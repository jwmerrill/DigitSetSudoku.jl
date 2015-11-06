DONE
* Concise, fixed length representation of digit sets
* No hashing

TODO
* Search for hidden singles can be linear instead of quadratic
* Don't allocate storage for units, neighbors, and eachindex
* Don't apply hidden singles until we're finished applying naked singles (because hidden singles is linear to notice, whereas naked singles is O(1) to notice)
* Store a count of digits for each unit so that we can apply hidden singles in O(1). There are 3*9 units. Could generalize DigitSet to DigitMultiSet for this purpose. Need to be able to store 0-9 occurrences of 9 digits, so we could fit a DigitMultiSet of this size into into an Int32, since 2^16 < 10^9 < 2^32. Could allow storing 0-15 occurrences of 9 digits so that we keep things aligned on (2) byte boundaries.
* Cache the next place we should assign in search

RHETORIC
* Sets made of strings???
* Idea of abstracting iteration from elimination strategies is nice. Even nicer if you can do it with no overhead.

SOURCES

http://norvig.com/sudoku.html
https://attractivechaos.wordpress.com/2011/06/19/an-incomplete-review-of-sudoku-solver-implementations/
http://www.math.cornell.edu/~mec/Summer2009/Mahmood/Symmetry.html

20veryhard.txt:
  https://github.com/attractivechaos/plb/blob/master/sudoku/sudoku.txt
easy50.txt
  http://norvig.com/easy50.txt
hardest.txt
  http://norvig.com/hardest.txt
top95.txt
  http://norvig.com/top95.txt
