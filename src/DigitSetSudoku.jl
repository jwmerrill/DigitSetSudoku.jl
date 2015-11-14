__precompile__()
module DigitSetSudoku

    using DigitSets

    type SudokuPuzzle
        squares::Array{Int8, 4}
    end

    SudokuPuzzle(spec::AbstractString) = parse(SudokuPuzzle, spec)

    function Base.parse(::Type{SudokuPuzzle}, spec::AbstractString)
        squares = Int8[]
        sizehint!(squares, 81)

        for c in spec
            if '0' <= c <= '9'
                push!(squares, parse(Int, c))
            elseif c == '.'
                push!(squares, 0)
            end
        end

        if length(squares) != 81
            error(@sprintf(
                "Expected 81 characters from [\\.0-9] but saw %d.",
                length(squares)
            ))
        end

        SudokuPuzzle(reshape(squares, (3, 3, 3, 3)))
    end

    function Base.show(io::IO, puzzle::SudokuPuzzle)
        for band in 1:3
            for row in 1:3
                for stack in 1:3
                    for col in 1:3
                        digit = puzzle.squares[col, stack, row, band]
                        print(io, digit == 0 ? "." : digit)
                        (stack == 3 && col == 3) || print(io, " ")
                    end
                    stack < 3 && print(io, "| ")
                end
                println(io, "")
            end
            band < 3 && println(io, "------+-------+------")
        end
    end

    type SudokuBoard
        squares::Array{DigitSet, 4}
    end

    SudokuBoard() = SudokuBoard(
        [
            DigitSet(1:9)
            for col in 1:3, stack in 1:3, row in 1:3, band in 1:3
        ]
    )

    const squareindices = reshape(1:81, 3, 3, 3, 3)
    const units = [
        (
            collect(squareindices[1:3, stack, 1:3, band]),
            collect(squareindices[1:3, 1:3, row, band]),
            collect(squareindices[col, stack, 1:3, 1:3])
        )
        for col in 1:3, stack in 1:3, row in 1:3, band in 1:3
    ]

    function solve(puzzle::SudokuPuzzle)
        board = SudokuBoard()
        assigngivens!(board, puzzle) || error("Inconsistent board")
        search!(board) || error("Inconsistent board")
        board
    end

    function assigngivens!(board::SudokuBoard, puzzle::SudokuPuzzle)
        for i in eachindex(puzzle.squares)
            digit = puzzle.squares[i]
            digit == 0 && continue
            assign!(board, DigitSet(digit), i) || return false
        end
        true
    end

    SudokuBoard(puzzle::SudokuPuzzle) = solve(puzzle)

    function assign!(board::SudokuBoard, ds::DigitSet, i)
        ds == board.squares[i] && return true
        length(ds) == 0 && return false

        board.squares[i] = ds

        # Strategies
        nakedsingle!(board, ds, i) || return false
        hiddensingle!(board, i) || return false

        true
    end

    function nakedsingle!(board::SudokuBoard, ds::DigitSet, i)
        length(ds) == 1 || return true
        for u in units[i]
            nakedsingleunit!(board, ds, i, u) || return false
        end
        true
    end

    function nakedsingleunit!(board::SudokuBoard, ds::DigitSet, i, unit)
        for j in unit
            i == j && continue
            difference = setdiff(board.squares[j]::DigitSet, ds)
            assign!(board, difference, j) || return false
        end
        true
    end

    function hiddensingle!(board::SudokuBoard, i)
        for u in units[i]
            hiddensingleunit!(board, u) || return false
        end
        true
    end

    function hiddensingleunit!(board::SudokuBoard, unit)
        singles = lonelydigits(board, unit)
        length(singles) > 0 || return true
        for i in unit
            intersection = intersect(singles, board.squares[i])
            # A board is inconsistent if we ever find a square that contains
            # more than one lonely digit for the same unit
            length(intersection) <= 1 || return false
            length(intersection) == 1 || continue
            assign!(board, intersection, i) || return false
        end
        true
    end

    function lonelydigits(board::SudokuBoard, unit)
        # Digits that occur only once in a unit
        singles = DigitSet()
        # Digits that occur multiple times
        multiples = DigitSet()
        for i in unit
            square = board.squares[i]
            # digits that occurred once before and also occur in square
            # have now occurred multiple times
            multiples = union(multiples, intersect(square, singles))
            # Add digits in square to singles and remove known multiples
            singles = setdiff(union(singles, square), multiples)
        end
        singles
    end

    function search!(board::SudokuBoard)
        i = searchindex(board)
        # Board is solved. Could adjust this to push board onto
        # an accumulator if we wanted to find all solutions.
        i == 0 && return true
        ds = board.squares[i]
        for digit in ds
            tmp = copy(board.squares)
            status = assign!(board, DigitSet(digit), i)
            status = status && search!(board)
            status && return true
            board.squares = tmp
        end
        false
    end

    function searchindex(board::SudokuBoard)
        out = 0
        minlen = 10
        for i in eachindex(board.squares)
            len = length(board.squares[i])
            if 1 < len < minlen
                minlen = len
                out = i
            end
        end
        out
    end

    function Base.show(io::IO, board::SudokuBoard)
        width = 1 + maximum(map(length, board.squares))
        dashes = repeat("-", 3*width)
        line = string(dashes, "+", dashes, "-", "+", dashes)
        for band in 1:3
            for row in 1:3
                for stack in 1:3
                    for col in 1:3
                        square = board.squares[col, stack, row, band]
                        for digit in square
                            print(io, digit)
                        end
                        print(io, repeat(" ", width - length(square) - 1))
                        (stack == 3 && col == 3) || print(io, " ")
                    end
                    stack < 3 && print(io, "| ")
                end
                println(io, "")
            end
            band < 3 && println(io, line)
        end
    end

    export SudokuBoard, SudokuPuzzle, solve

end # module
