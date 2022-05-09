import ..DictViews
import ..DictViews: dictview, DictView

export AbstractTupleArray, TupleArray, AbstractNamedTupleArray, NamedTupleArray
export TupleMatrix, TupleVector, AbstractTupleVector, AbstractTupleMatrix,
    NamedTupleVector, NamedTupleMatrix
export tupgetdata, tupgetindex, tuplength, getnames

# temporary export
export _striptype, ensurevectorfields, hastuplefield

###
### AbstractTupleArray
###

"""
    AbstractTupleArray{Ttup, Nd, Nt} <: AbstractArray{Ttup, Nd}

`Ttup` is the data type of the array. It is `<:Tuple`.
`Nd` is the dimension of the array.
`Nt` is the length of each `Tuple` in the array.
"""
abstract type AbstractTupleArray{Ttup, Nd, Nt} <: AbstractArray{Ttup, Nd} end
const AbstractTupleVector{Ttup} = AbstractTupleArray{Ttup, 1, Nt} where {Ttup, Nt}
const AbstractTupleMatrix{Ttup} = AbstractTupleArray{Ttup, 2, Nt} where {Ttup, Nt}


# Length  of tuple (typically number of fields in struct)
tuplength(ta::AbstractTupleArray{<:Any,<:Any,Nt}) where Nt = Nt
tupgetdata(ta::AbstractTupleArray) = getfield(ta, :_data)

Base.ndims(ta::AbstractTupleArray{<:Any, Nd}) where Nd = Nd

hastuplefield(ta::AbstractTupleArray) = any(x->isa(x,Tuple), tupgetdata(ta))

"""
    ensurevectorfields(fieldtup)

Copy the tuple of containers `fieldtup` converting any `Tuple` to a `Vector`.
This is probably not robust. Hard to say what needs to be converted.
"""
ensurevectorfields(fieldtup) = ((isa(x,Tuple) ? collect(x) : x for x in fieldtup)...,)
ensurevectorfields(ta::AbstractTupleArray) = !hastuplefield(ta) ? ta :
    _striptype(typeof(ta))(ensurevectorfields(tupgetdata(ta))...,)


# Worked around this by converting AbstractTupleArray with tuple data
# to one with vector data when calling `show`. So we don't need the
# piracy below.
# piracy here. There is some bug in printing that makes
# this necessary. Doing this:
# show(io, MIME"text/plain"(), TupleArray((1,2),(3,4))
# attempts getindex with two indices instead of one. Don't know why or how
Base.getindex(tup::Tuple, i::Integer, j::Integer) = getindex(tup, i)

# The following kinda works, and makes the pirate-hack above uneccessary.
# But, the below will print the wrong type if it converts Tuples to Vectors.
# So we use the pirate hack, instead.
# function Base.show(io::IO, ::MIME"text/plain", ta::AbstractTupleArray)
#     tav = hastuplefield(ta) ? ensurevectorfields(ta) : ta
#     nd = ndims(ta)
#     invoke(show, Tuple{IO,MIME"text/plain", AbstractArray{<:Any,nd}}, io, MIME"text/plain"(), tav)
# end

_tupgetindex(ta::AbstractTupleArray, i::Integer...) = ((x[i...] for x in tupgetdata(ta))...,)
tupgetindex(args...) = _tupgetindex(args...)

_size(args...) = Base.size(args...)
_size(t::Tuple) = (length(t),) # Preclude using Tuples for higher dim arrays
# These have length, but you can't index into them, so no good.
# _size(t::Base.ValueIterator) = (length(t),)
# _size(t::Base.KeySet) = (length(t),)

function Base.size(ta::AbstractTupleArray)
    data = tupgetdata(ta)
    isempty(data) && return ((0 for _ in 1:ndims(ta))...,)
    return _size(first(data))
end

Base.length(ta::AbstractTupleArray) = prod(size(ta))

Base.getindex(ta::AbstractTupleArray, i::Integer...) = tupgetindex(ta, i...)

function _construct(arrays, dims=0)
    isempty(arrays) && throw(ErrorException("Empty TupleArray not supported."))
    asize = isempty(arrays) ? (0,) : _size(first(arrays))
    all(x -> _size(x) == asize, arrays) || throw(DimensionMismatchError("Elements of Tuples must have the same dimension"))
    _Ttup = typeof(arrays)
    _Nd = length(asize)
    _Nt = length(arrays)
    return (_Ttup, _Nd, _Nt)
end

struct TupleArray{Ttup, Nd, Nt} <: AbstractTupleArray{Ttup, Nd, Nt}
    _data::Ttup
    function TupleArray(arrays...)
        isempty(arrays) && throw(MethodError(TupleArray, ()))
        return new{_construct(arrays)...}(arrays)
    end

    # function TupleArray{Ttup,Nd}(arrays...)
    # end

    # This may not be useful.
    function TupleArray{Ttup, Nd, Nt}(arrays...) where {Ttup, Nd, Nt}
        asize = isempty(arrays) ? ((0 for _ in 1:Nt)...,) : _size(first(arrays))
        @show asize
        all(x -> _size(x) == asize, arrays) || throw(DimensionMismatchError("bad dims"))
        _Ttup = typeof(arrays)
        _Nd = length(asize)
        _Nt = length(arrays)
        _Ttup == Ttup || error("Type $_Ttup != $Ttup")
        _Nd == Nd || error("Dimensions $_Nd != $Nd")
        _Nt == Nt || error("Tuple length $_Nt != $Nt")
        return new{Ttup, Nd, Nt}(arrays)
    end
end

TupleArray(d::AbstractDict) = TupleArray(collect(keys(d)), collect(values(d)))

const TupleVector{Ttup, Nt} = TupleArray{Ttup, 1, Nt}
const TupleMatrix{Ttup, Nt} = TupleArray{Ttup, 2, Nt}

abstract type AbstractNamedTupleArray{Ttup, Nd, Nt, Tnames} <: AbstractTupleArray{Ttup, Nd, Nt} end

getnames(::AbstractNamedTupleArray{<:Any,<:Any,<:Any,Tnames}) where Tnames = Tnames

function ensurevectorfields(ta::AbstractNamedTupleArray)
    return _striptype(typeof(ta))(getnames(ta), ensurevectorfields(tupgetdata(ta))...,)
end

function tupgetindex(ta::AbstractNamedTupleArray, i::Integer...)
    tup = _tupgetindex(ta, i...)
    names = getnames(ta)
    return NamedTuple{names, typeof(tup)}(tup)
end

struct NamedTupleArray{Ttup, Nd, Nt, Tnames} <: AbstractNamedTupleArray{Ttup, Nd, Nt, Tnames}
    _data::NamedTuple{Tnames,Ttup}
    function NamedTupleArray(names::NTuple, arrays...)
        # length(names) == length(arrays) || error("bad")
        return new{_construct(arrays)..., names}(NamedTuple{names, typeof(arrays)}(arrays))
    end
end

NamedTupleArray(names::NTuple, d::AbstractDict) = NamedTupleArray(names, collect(keys(d)), collect(values(d)))

const NamedTupleVector{Ttup, Nt} = NamedTupleArray{Ttup, 1, Nt}
const NamedTupleMatrix{Ttup, Nt} = NamedTupleArray{Ttup, 2, Nt}

TupleVector(args...) = TupleArray(args...)
TupleMatrix(args...) = TupleMatrix(args...)
NamedTupleVector(args...) = NamedTupleArray(args...)
NamedTupleMatrix(args...) = NamedTupleMatrix(args...)

for _type in (:NamedTupleArray, :TupleArray, :AbstractTupleArray, :AbstractNamedTupleArray,
              :NamedTupleVector, :TupleVector)
    @eval _striptype(::Type{<:$_type}) = $_type
end

###
### DictViews interface
###

DictViews.dictview_keys(ta::AbstractTupleArray) = first(tupgetdata(ta))

function DictViews.dictview_values(ta::AbstractTupleArray)
    n = length(tupgetdata(ta))
    n == 1 && throw(ErrorException("there is no values field"))
    n == 2 && return tupgetdata(ta)[2]
    return tupgetdata(ta)[2:end]
end

# get a value by key
# Default is slow linear search
function DictViews.dictview_get(ta::AbstractTupleArray, k, default)
    for i in eachindex(ta)
        tup = ta[i]
        if first(tup) == k
            x = ta[i]
#            return Base.rest(x, 2) # This is ok too, no faster
            return ((x[i] for i in 2:length(x))...,)
        end
    end
    return default
end
