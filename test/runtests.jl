using TupleArrays
using Test

@testset "TupleArrays.jl" begin
    let ta = TupleArray(1:10, 11:20)
        @test isa(ta, TupleVector)
        @test length(ta) == 10
        @test tuplength(ta) == 2
    end

    let ta1 = TupleArray(1:10, 11:20, 21:30)
        @test isa(ta1, TupleVector)
        @test length(ta1) == 10
        @test tuplength(ta1) == 3
    end
end
