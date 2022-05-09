import ..DictViews
import ..DictViews: dictview, DictView

export AbstractTupleArray, TupleArray, AbstractNamedTupleArray, NamedTupleArray
export TupleMatrix, TupleVector, AbstractTupleVector, AbstractTupleMatrix,
    NamedTupleVector, NamedTupleMatrix
export tupgetdata, tupgetindex, tuplength, getnames, tuptype

# temporary export
export _striptype, ensurevectorfields, hastuplecol

###
### AbstractTupleArray
###

"""
    AbstractTupleArray{Ttup, Nd, Nt} <: AbstractArray{Ttup, Nd}

An abstract array of `Tuple`s. In the concrete subtypes, the
data is not stored as `Tuple`s, but rather as `Nt` `Arrays`, where
`Nt` is the length of each `Tuple`.

`Ttup` is the data type of the array. It is `<:Tuple`.
`Nd` is the dimension of the array.
`Nt` is the length of each `Tuple` in the array.

#Examples

If `Nt=4` and `Nd=2`, then the array is a matrix of `4-Tuples`.
"""
abstract type AbstractTupleArray{Ttup, Nd, Nt} <: AbstractArray{Ttup, Nd} end
const AbstractTupleVector{Ttup} = AbstractTupleArray{Ttup, 1, Nt} where {Ttup, Nt}
const AbstractTupleMatrix{Ttup} = AbstractTupleArray{Ttup, 2, Nt} where {Ttup, Nt}

"""
    tuplength(ta::AbstractTupleArray)

Length  of each `Tuple` contained in `ta`.
"""
tuplength(ta::AbstractTupleArray{<:Any,<:Any,Nt}) where Nt = Nt


"""
    tuptype(ta::AbstractTupleArray)

Type of the `Tuple`s contained in `ta`.
"""
tuptype(ta::AbstractTupleArray{Ttup}) where Ttup = Ttup

tupgetdata(ta::AbstractTupleArray) = getfield(ta, :_data)

Base.ndims(ta::AbstractTupleArray{<:Any, Nd}) where Nd = Nd

"""
    hastuplecol(ta::AbstractTupleArray)

Return `true` if any column in `ta` is a `Tuple`.

The elements of `ta` are always `Tuple`s. But, the columns may
other containers.
"""
hastuplecol(ta::AbstractTupleArray) = any(x->isa(x,Tuple), tupgetdata(ta))

"""
    ensurevectorfields(fieldtup)

Copy the tuple of containers `fieldtup` converting any `Tuple` to a `Vector`.
This is probably not robust. Hard to say what needs to be converted.
"""
ensurevectorfields(fieldtup) = ((isa(x,Tuple) ? collect(x) : x for x in fieldtup)...,)
ensurevectorfields(ta::AbstractTupleArray) = !hastuplecol(ta) ? ta :
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
#     tav = hastuplecol(ta) ? ensurevectorfields(ta) : ta
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

function _construct(arrays, dims=-1, _Nt=-1)
    isempty(arrays) && throw(MethodError(TupleArray, ()))
    asize = _size(first(arrays))
    all(x -> _size(x) == asize, arrays) || throw(DimensionMismatchError("Elements of Tuples must have the same dimension"))
    Nd = length(asize)
    dims >= 0 && dims != Nd &&
        throw(DimensionMismatch("Can't construct a $(dims)-dimensional TupleArray with $(Nd)-dimensional data"))
    Ttup = typeof(arrays)
    Nd = length(asize)
    Nt = length(arrays)
    _Nt >=0 && Nt != _Nt &&
        throw(DimensionMismatch("Can't construct a Tuples of length $_Nt with $Nt input arrays."))
    return (Ttup, Nd, Nt)
end

struct TupleArray{Ttup, Nd, Nt} <: AbstractTupleArray{Ttup, Nd, Nt}
    _data::Ttup

    TupleArray(arrays...) = new{_construct(arrays)...}(arrays)
    TupleArray{Ttup}(arrays...) where {Ttup} = new{_construct(arrays)...}(arrays)
    TupleArray{Ttup,Nd}(arrays...) where {Ttup, Nd} = new{_construct(arrays, Nd)...}(arrays)
    TupleArray{Ttup,Nd,Nt}(arrays...) where {Ttup, Nd, Nt} = new{_construct(arrays, Nd, Nt)...}(arrays)
end

TupleArray(d::AbstractDict) = TupleArray(collect(keys(d)), collect(values(d)))

const TupleVector{Ttup, Nt} = TupleArray{Ttup, 1, Nt}
const TupleMatrix{Ttup, Nt} = TupleArray{Ttup, 2, Nt}

###
### AbstractNamedTupleArray
###

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


function _check_name_length(names, arrays)
    length(names) == length(arrays) ||
        throw(DimensionMismatch(
            "Number of names $(length(names)) differ from number of columns $(length(arrays))."))
    return true
end

struct NamedTupleArray{Ttup, Nd, Nt, Tnames} <: AbstractNamedTupleArray{Ttup, Nd, Nt, Tnames}
    _data::NamedTuple{Tnames,Ttup}

    function NamedTupleArray(names::NTuple, arrays...)
        _check_name_length(names, arrays)
        return new{_construct(arrays)..., names}(NamedTuple{names, typeof(arrays)}(arrays))
    end

    function NamedTupleArray{Ttup,Nd}(names::NTuple, arrays...) where {Ttup, Nd}
        _check_name_length(names, arrays)
        return new{_construct(arrays, Nd)..., names}(NamedTuple{names, typeof(arrays)}(arrays))
    end

    function NamedTupleArray{Ttup,Nd,Nt}(names::NTuple, arrays...) where {Ttup, Nd, Nt}
        _check_name_length(names, arrays)
        return new{_construct(arrays, Nd, Nt)..., names}(NamedTuple{names, typeof(arrays)}(arrays))
    end
end

NamedTupleArray(names::NTuple, d::AbstractDict) = NamedTupleArray(names, collect(keys(d)), collect(values(d)))

const NamedTupleVector{Ttup, Nt} = NamedTupleArray{Ttup, 1, Nt}
const NamedTupleMatrix{Ttup, Nt} = NamedTupleArray{Ttup, 2, Nt}

TupleVector(args...) = TupleArray{typeof(args),1}(args...)
TupleMatrix(args...) = TupleArray{typeof(args),2}(args...)

NamedTupleVector(names, args...) = NamedTupleArray{typeof(args),1}(names, args...)
NamedTupleMatrix(names, args...) = NamedTupleArray{typeof(args),2}(names, args...)

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
