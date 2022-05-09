using TupleArrays
using Test

@testset "TupleArrays.jl" begin
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

@testset "Corner cases" begin
    @test_throws MethodError TupleVector()
    @test_throws MethodError TupleArray()
    @test_throws DimensionMismatch TupleMatrix((1,2))
    @test_throws DimensionMismatch TupleVector(zeros(2,2))
#     @test ndims(ta) == 1
#     @test size(ta) == (0,)
#     @test length(ta) == 0
#     @test tupgetdata(ta) == ()
end
