module DigitSetSudoku

    using DigitSets

    type SudokuPuzzle
        cells::Array{Int8, 4}
    end

    function SudokuPuzzle(spec::AbstractString)
        cells = Int8[]
        sizehint!(cells, 81)

        for c in spec
            if c == '0' || c == '.'
                push!(cells, 0)
            elseif c == '1'
                push!(cells, 1)
            elseif c == '2'
                push!(cells, 2)
            elseif c == '3'
                push!(cells, 3)
            elseif c == '4'
                push!(cells, 4)
            elseif c == '5'
                push!(cells, 5)
            elseif c == '6'
                push!(cells, 6)
            elseif c == '7'
                push!(cells, 7)
            elseif c == '8'
                push!(cells, 8)
            elseif c == '9'
                push!(cells, 9)
            end
        end

        if length(cells) != 81
            error(@sprintf(
                "Expected 81 chracters from [\\.0-9] but saw %d.",
                length(cells)
            ))
        end

        SudokuPuzzle(reshape(cells, (3, 3, 3, 3)))
    end

    function Base.show(io::IO, puzzle::SudokuPuzzle)
        for band in 1:3
            for row in 1:3
                for stack in 1:3
                    for col in 1:3
                        digit = puzzle[BoardPosition(col, stack, row, band)]
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
        cells::Array{DigitSet, 4}
    end

    SudokuBoard() = SudokuBoard(
        [DigitSet(1:9) for col in 1:3, stack in 1:3, row in 1:3, band in 1:3]
    )

    immutable BoardPosition
        col::Int8
        stack::Int8
        row::Int8
        band::Int8
    end

    nullboardposition() = BoardPosition(0, 0, 0, 0)

    Base.getindex(b::SudokuBoard, p::BoardPosition) =
        b.cells[p.col, p.stack, p.row, p.band]

    Base.setindex!(b::SudokuBoard, ds::DigitSet, p::BoardPosition) =
        b.cells[p.col, p.stack, p.row, p.band] = ds

    Base.getindex(puzzle::SudokuPuzzle, p::BoardPosition) =
        puzzle.cells[p.col, p.stack, p.row, p.band]

    function Base.eachindex(_::Union{SudokuPuzzle, SudokuBoard})
        [
            BoardPosition(col, stack, row, band)
            for col in 1:3, stack in 1:3, row in 1:3, band in 1:3
        ]
    end

    function neighborindices(p::BoardPosition)
        out = BoardPosition[]

        for stack in 1:3, col in 1:3
            p.stack == stack && p.col == col && continue
            push!(out, BoardPosition(col, stack, p.row, p.band))
        end

        for band in 1:3, row in 1:3
            p.band == band && p.row == row && continue
            push!(out, BoardPosition(p.col, p.stack, row, band))
        end

        for row in 1:3, col in 1:3
            p.row == row && p.col == col && continue
            push!(out, BoardPosition(col, p.stack, row, p.band))
        end

        out
    end

    function units(p::BoardPosition)
        (
            [
                BoardPosition(col, stack, p.row, p.band)
                for col in 1:3, stack in 1:3
            ],
            [
                BoardPosition(p.col, p.stack, row, band)
                for row in 1:3, band in 1:3
            ],
            [
                BoardPosition(col, p.stack, row, p.band)
                for col in 1:3, row in 1:3
            ]
        )
    end

    function SudokuBoard(puzzle::SudokuPuzzle)
        board = SudokuBoard()
        local status = true
        for i in eachindex(puzzle)
            digit = puzzle[i]
            if digit != 0
                status = assign!(board, DigitSet(digit), i)
                status || error("Inconsistent board.")
            end
        end
        status = search!(board)
        status || error("Inconsistent board.")
        board
    end

    function assign!(board::SudokuBoard, ds::DigitSet, i::BoardPosition)
        ds == board[i] && return true
        length(ds) == 0 && return false

        board[i] = ds

        # Strategies
        nakedsingle!(board, ds, i) || return false
        hiddensingle!(board, i) || return false

        true
    end

    function nakedsingle!(board::SudokuBoard, ds::DigitSet, i::BoardPosition)
        if length(ds) == 1
            for j in neighborindices(i)
                status = assign!(board, setdiff(board[j], ds), j)
                status || return false
            end
        end
        true
    end

    function hiddensingle!(board::SudokuBoard, i::BoardPosition)
        for unit in units(i)
            singles = lonelydigits(board, unit)
            length(singles) > 0 || continue
            for j in unit
                intersection = intersect(singles, board[j])
                # A board is inconsistent if we ever find a cell that contains
                # more than one lonely digit for the same unit
                length(intersection) <= 1 || return false
                length(intersection) == 1 || continue
                assign!(board, intersection, j) || return false
            end
        end
        true
    end

    function lonelydigits(board::SudokuBoard, unit)
        # Digits that occur only once in a unit
        singles = DigitSet()
        # Digits that occur multiple times
        multiples = DigitSet()
        for i in unit
            cell = board[i]
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
        i == nullboardposition() && return true
        ds = board[i]
        for digit in ds
            tmp = copy(board.cells)
            status = assign!(board, DigitSet(digit), i) && search!(board)
            status && return true
            board.cells = tmp
        end
        false
    end

    function searchindex(board::SudokuBoard)
        out = nullboardposition()
        minlen = 10
        for i in eachindex(board)
            len = length(board[i])
            if len > 1 && len < minlen
                minlen = len
                out = i
            end
        end
        out
    end

    function Base.show(io::IO, board::SudokuBoard)
        width = 1 + maximum(map(length, board.cells))
        dashes = repeat("-", 3*width)
        line = string(dashes, "+", dashes, "-", "+", dashes)
        for band in 1:3
            for row in 1:3
                for stack in 1:3
                    for col in 1:3
                        cell = board[BoardPosition(col, stack, row, band)]
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
