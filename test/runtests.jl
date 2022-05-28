using TupleArrays
using Test

@testset "TupleArrays" begin

    mkvec(x...) = [x...]
    mktup(x...) = (x...,)

    # Test when columns are either Tuple or Vector
    for coll in (mkvec, mktup)
        for named in (true, false)
            if named
                tv = NamedTupleArray(a = coll(1,2,3,4), b = coll(4,5,6,7), c = coll(7,8,9,10)) # TODO method for NamedTupleVector
            else
                tv = TupleVector(coll(1,2,3,4), coll(4,5,6,7), coll(7,8,9,10))
            end
            @test length(tv) == 4
            @test ndims(tv) == 1
            @test tuplength(tv) == 3
            @test tuptype(tv) == Tuple{Int,Int,Int}
            @test getcol(tv,1) == coll(1:4...)
            @test getcol(tv,2) == coll(4:7...)
            @test getcol(tv,3) == coll(7:10...)
            @test hastuplecol(tv) == (coll == mktup) # are columns Vector or Tuples
            @test ! hastuplecol(ensurevectorcols(tv))
            @test alltuplecol(ensuretuplecols(tv))
            @test ! hasvectorcol(ensuretuplecols(tv))

            if coll == mkvec
                @test copy(tv) == tv
                etv = empty(tv)
                @test etv !== tv
                @test length(etv) == 0
                @test typeof(etv) == typeof(tv)
                stv = similar(tv)
                @test stv !== tv
                @test length(stv) == length(tv)
                @test tuplength(stv) == tuplength(tv)
                @test ndims(stv) == ndims(tv)
                @test typeof(stv) == typeof(tv)
            end

            if named
                _data = values(tupgetdata(tv))
                @test getproperty.(Ref(tv), [:a, :b, :c]) == [_data...]
            else
                _data = tupgetdata(tv)
            end
            @test _data == (coll(1, 2, 3, 4), coll(4, 5, 6, 7), coll(7, 8, 9, 10))
            if ! named
                @test tuptype(tv) == typeof(tv[1])
                @test collect(tv) == [(1, 4, 7), (2, 5, 8), (3, 6, 9), (4, 7, 10)]
                @test tv[[2,3]] == TupleVector(coll(2,3), coll(5,6), coll(8,9))
                @test tv[3:4] == TupleVector(coll(3,4), coll(6,7), coll(9,10))
            end
            if coll == mkvec
                @test typeof(tv) == typeof(tv[[2,3]])
                tv[3] = (3, 2, 1)
                if ! named
                    @test collect(tv) == [(1, 4, 7), (2, 5, 8), (3, 2, 1), (4, 7, 10)]
                end
            end
        end
    end
    @test TupleVector([1,2], [3,4]) == [(1, 3), (2, 4)]
    @test_throws DimensionMismatch TupleMatrix([1,2], [3,4])
    @test TupleMatrix([1 2; 3 4], [1 2; 3 4]) == [(1, 1) (2, 2); (3, 3) (4, 4)]
    @test_throws DimensionMismatch TupleVector([1 2; 3 4], [1 2; 3 4])
end


@testset "Other TupleArrays" begin
    tup = (1:10, 11:20)
    for data = (tup, collect.(tup))
        let ta = TupleArray(data...)
            @test isa(ta, TupleVector)
            @test length(ta) == 10
            @test tuplength(ta) == 2
            @test sum(prod, ta) == 935
            @test firstindex(ta) == 1
            @test lastindex(ta) == 10
        end
    end
    tup = (1:10, 11:20, 21:30)
    for data = (tup, collect.(tup))
        let ta1 = TupleArray(data...)
            @test isa(ta1, TupleVector)
            @test length(ta1) == 10
            @test tuplength(ta1) == 3
            @test firstindex(ta1) == 1
            @test lastindex(ta1) == 10
            @test sum(prod, ta1) == 25575
        end
    end
end

# This was for the previous meaning of tuptype
# @testset "Construct" begin
#     dd = ((1,2), (3,4))
#     Ttup = typeof(dd)
#     ta = TupleArray{Ttup}(dd...)
#     @test tuptype(ta) == Ttup
# end

@testset "Corner cases" begin
    @test_throws MethodError TupleVector()
    @test_throws MethodError TupleArray()
    @test_throws DimensionMismatch TupleMatrix((1,2))
    @test_throws DimensionMismatch TupleVector(zeros(2,2))
end
