module TupleArrays

export AbstractTupleArray, TupleArray, AbstractNamedTupleArray, NamedTupleArray
export TupleMatrix, TupleVector, AbstractTupleVector, AbstractTupleMatrix,
    NamedTupleVector, NamedTupleMatrix
export gettupfields, gettupindex, tuplength, getnames

abstract type AbstractTupleArray{Ttup, Nd, Nt} <: AbstractArray{Ttup, Nd} end
const AbstractTupleVector{Ttup} = AbstractTupleArray{Ttup, 1, Nt} where {Ttup, Nt}
const AbstractTupleMatrix{Ttup} = AbstractTupleArray{Ttup, 2, Nt} where {Ttup, Nt}

# piracy here. There is some bug in printing that makes
# this necessary. Doing this:
# show(io, MIME"text/plain"(), TupleArray((1,2),(3,4))
# attempts getindex with two indices instead of one. Don't know why or how
Base.getindex(tup::Tuple, i::Integer, j::Integer) = getindex(tup, i)

# Length  of tuple (typically number of fields in struct)
tuplength(ta::AbstractTupleArray{<:Any,<:Any,Nt}) where Nt = Nt
gettupfields(ta::AbstractTupleArray) = getfield(ta, :data)

function _gettupindex(ta::AbstractTupleArray, i::Integer)
    return ((x[i] for x in gettupfields(ta))...,)
end

function _gettupindex(ta::AbstractTupleArray, i::Integer...)
#    @show i
    return ((x[i...] for x in gettupfields(ta))...,)
end


#gettupindex(args...) = _gettupindex(args...) # can collapse again
function gettupindex(args...)
    _gettupindex(args...)
end

_size(args...) = Base.size(args...)
_size(t::Tuple) = (length(t),) # Preclude using Tuples for higher dim arrays
Base.size(ta::AbstractTupleArray) = _size(first(gettupfields(ta)))
Base.length(ta::AbstractTupleArray) = length(first(gettupfields(ta)))
Base.getindex(ta::AbstractTupleArray, i::Integer...) = gettupindex(ta, i...)

function _construct(arrays)
    asize = _size(first(arrays))
    all(x -> _size(x) == asize, arrays) || throw(DimensionMismatchError("bad dims"))
    _Ttup = typeof(arrays)
    _Nd = length(asize)
    _Nt = length(arrays)
    return (_Ttup, _Nd, _Nt)
end

struct TupleArray{Ttup, Nd, Nt} <: AbstractTupleArray{Ttup, Nd, Nt}
    data::Ttup
    function TupleArray(arrays...)
        return new{_construct(arrays)...}(arrays)
    end
end

const TupleVector{Ttup, Nt} = TupleArray{Ttup, 1, Nt}
const TupleMatrix{Ttup, Nt} = TupleArray{Ttup, 2, Nt}

abstract type AbstractNamedTupleArray{Ttup, Nd, Nt, Tnames} <: AbstractTupleArray{Ttup, Nd, Nt} end

getnames(::AbstractNamedTupleArray{<:Any,<:Any,<:Any,Tnames}) where Tnames = Tnames

function gettupindex(ta::AbstractNamedTupleArray, i::Integer...)
#    @show i
    tup = _gettupindex(ta, i...)
    names = getnames(ta)
    return NamedTuple{names, typeof(tup)}(tup)
end

struct NamedTupleArray{Ttup, Nd, Nt, Tnames} <: AbstractNamedTupleArray{Ttup, Nd, Nt, Tnames}
    data::Ttup
    function NamedTupleArray(names::NTuple, arrays...)
        return new{_construct(arrays)..., names}(arrays)
    end
end

const NamedTupleVector{Ttup, Nt} = NamedTupleArray{Ttup, 1, Nt}
const NamedTupleMatrix{Ttup, Nt} = NamedTupleArray{Ttup, 2, Nt}

end # module TupleArrays
