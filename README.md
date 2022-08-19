# TupleArrays

[![Build Status](https://github.com/jlapeyre/TupleArrays.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jlapeyre/TupleArrays.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/jlapeyre/TupleArrays.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jlapeyre/TupleArrays.jl)

The main types provided by this module are `TupleArray` and `NamedTupleArray`. A `TupleArray`
is an `AbstractArray` whose elements are `Tuple`s. But, for `Tuple`s of length `n`, the data
is stored not as tuples, but as `n` arrays. The tuples are assembled when iterating or indexing
into the `TupleArray`. A `NamedTupleArray` is the same except that the elements are `NamedTuple`s.

## relation to StructArrays

I did not realize that [StructArrays.jl](https://github.com/JuliaArrays/StructArrays.jl) already
does most of what I want. So, it's clear what this package is worth. There is somethin that
`TupleArrays` does that `StructArrays` does not... I think treating `Tuple` more like a `Vector`.
