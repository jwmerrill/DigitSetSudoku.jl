__precompile__()
module DigitSetSudoku

    using DigitSets

    type SudokuPuzzle
        squares::Array{Int8, 4}
    end

    function SudokuPuzzle(spec::AbstractString)
        squares = Int8[]
        sizehint!(squares, 81)

        for c in spec
            if c == '0' || c == '.'
                push!(squares, 0)
            elseif c == '1'
                push!(squares, 1)
            elseif c == '2'
                push!(squares, 2)
            elseif c == '3'
                push!(squares, 3)
            elseif c == '4'
                push!(squares, 4)
            elseif c == '5'
                push!(squares, 5)
            elseif c == '6'
                push!(squares, 6)
            elseif c == '7'
                push!(squares, 7)
            elseif c == '8'
                push!(squares, 8)
            elseif c == '9'
                push!(squares, 9)
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
                        print(io, " ")
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

    function SudokuBoard(puzzle::SudokuPuzzle)
        board = SudokuBoard()
        for i in eachindex(puzzle.squares)
            digit = puzzle.squares[i]
            digit == 0 && continue
            assign!(board, DigitSet(digit), i) || error("Inconsistent board.")
        end
        search!(board) || error("Inconsistent board.")
        board
    end

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
            # A board is inconsistent if we ever find a cell that contains
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
            cell = board.squares[i]
            # digits that occurred once before and also occur in cell
            # have now occurred multiple times
            multiples = union(multiples, intersect(cell, singles))
            # Add digits in cell to singles and remove known multiples
            singles = setdiff(union(singles, cell), multiples)
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
            ds = DigitSet(digit)
            status = assign!(board, ds, i)
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
            if len > 1 && len < minlen
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
                        cell = board.squares[col, stack, row, band]
                        for digit in cell
                            print(io, digit)
                        end
                        print(io, repeat(" ", width - length(cell)))
                    end
                    stack < 3 && print(io, "| ")
                end
                println(io, "")
            end
            band < 3 && println(io, line)
        end
    end

    export SudokuBoard, SudokuPuzzle

end # module
