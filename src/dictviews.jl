module DictViews

export DictView, dictview, getflags

abstract type AbstractDictView{K,V,T} <: AbstractDict{K,V} end

struct DictView{K,V,T,KF,VF,S} <: AbstractDictView{K,V,T}
    data::T
    keyf::KF
    valuef::VF
end

function DictView(data,kf,vf)
    K = typeof(dictview_keys(data))
    V = typeof(dictview_values(data))
    T = typeof(data)
    DictView{K,V,T,typeof(kf),typeof(vf),()}(data,kf,vf)
end

function _keys(data, keyf)
#    @show keyf
    keyf === typeof(identity) && return dictview_keys(data)
    return keyf(data)
end

function _values(data, valuef)
    valuef === typeof(identity) && return dictview_values(data)
    return valuef(data)
end

function dictview(data;keyf=identity,valuef=identity, flags=())
    K = typeof(_keys(data, keyf)) # dictview_keys(data))
    V = typeof(_values(data, valuef))  #dictview_values(data))
    T = typeof(data)
    DictView{K,V,T,typeof(keyf),typeof(valuef),flags}(data,keyf,valuef)
end

getdata(d::DictView) = d.data
getflags(d::DictView{<:Any,<:Any,<:Any,<:Any,<:Any,S}) where S = S

Base.issorted(d::DictView) = :sorted in getflags(d)

#(:values, :pairs, :get)
for f in (:values, :pairs)
    df = Symbol("dictview_", f)
    @eval function $df end
    @eval (Base.$f)(d::DictView, args...) = ($df)(getdata(d), args...)
end

function Base.keys(dv::DictView)
    return _keys(getdata(dv), dv.keyf)
end

function Base.values(dv::DictView)
    return _values(getdata(dv), dv.valuef)
    # dv.keyf === typeof(identity) && return dictview_keys(getdata(dv))
    # return dv.keyf(getdata(dv))
end


#Base.length(dv::DictView) = length(getdata(dv))
Base.length(dv::DictView) = length(keys(dv))

function dictview_keys end
function dictview_values end
function dictview_get end

function Base.iterate(dv::DictView, i=1)
    i > length(dv) && return nothing
    return ((keys(dv)[i], values(dv)[i]), i+1)
end


Base.get(dv::DictView, searchkey) = getposition(keys(dv), searchkey)

dictview_get(v, k, default=nothing) = getposition(v, k)

function getposition(_keys, searchkey)::Int
    i::Int = 1
    for n in _keys
        searchkey == n && return i
        i += 1
    end
    return i
end


end # module DictViews
