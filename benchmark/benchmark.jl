using DigitSetSudoku

root = Pkg.dir("DigitSetSudoku")

function timepuzzles(filehandle)
    timesum = 0.0
    timemax = 0.0
    n = 0
    for line in eachline(filehandle)
        puzzle = SudokuPuzzle(line)
        time = @elapsed SudokuBoard(puzzle)
        timesum += time
        timemax = max(time, timemax)
        n += 1
    end
    @printf "Mean time: %.6f seconds.\n" timesum/n
    @printf "Max time: %.6f seconds.\n" timemax
end

println("Easy puzzles")
open(timepuzzles, joinpath(root, "puzzledata", "easy50.txt"))
println()

println("Top 95 puzzles")
open(timepuzzles, joinpath(root, "puzzledata", "top95.txt"))
println()

println("11 Hardest puzzles")
open(timepuzzles, joinpath(root, "puzzledata", "hardest.txt"))
println()

println("20 very hard puzzles")
open(timepuzzles, joinpath(root, "puzzledata", "20veryhard.txt"))
