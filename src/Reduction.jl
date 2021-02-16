function addinv(a, p)
    c = a % p
    c < 0 && return p + c
    return p - c
end
firstind(v::SparseVector{T, I}) where {T, I} = v.nzind[1]

function reduction!(
    Mat::macaulay_matrix{N, M},
    char::cf_t
) where {N, M}
    pivots = zeros(UInt64, Mat.n_cols)
    pivots[firstind(Mat.entries[end])] = Mat.n_rows

    for i in reverse(1:Mat.n_rows-1)
        buffer = Array{UInt64}(Mat.entries[i])
        
        for j in firstind(Mat.entries[i]):Mat.n_cols
            (iszero(pivots[j]) || pivots[j] < i ) && continue
            if Mat.row_sigs[i] == Mat.row_sigs[pivots[j]]
                println("WARNING: two rows in the same signature. Should not happen!")
                continue
            end
            if j == firstind(Mat.entries[i])
                Mat.flags[i] = true
            end
            mult = addinv(buffer[j], char)
            addmodp = (a, b) -> (a + b) % char
            for k in Mat.entries[pivots[j]].nzind
                buffer[k] = addmodp(buffer[k], mult * Mat.entries[pivots[j]][k])
            end
        end

        Mat.entries[i] = SparseVector(buffer)
        iszero(Mat.entries[i].nzind) && continue
        mult = invmod(Mat.entries[i][firstind(Mat.entries[i])], char)
        for k in Mat.entries[i].nzind
            Mat.entries[i][k] = (Mat.entries[i][k] * mult) % char
        end
        pivots[firstind(Mat.entries[i])] = i
    end
end
