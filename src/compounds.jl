import StaticArrays

struct RDateCompound{T} <: RDate
    parts::StaticArrays.SVector{T,RDate}

    RDateCompound(parts) = new{length(parts)}(parts)
end

Base.:+(rdate::RDateCompound, date::Dates.Date) = Base.foldl(+, rdate.parts, init=date)
Base.:-(rdate::RDateCompound) = RDateCompound(map(-, rdate.parts))
Base.:+(x::RDateCompound, y::RDate) = RDateCompound(vcat(x.parts, y))
Base.:+(x::RDate, y::RDateCompound) = RDateCompound(vcat(x, y.parts))
combine(left::RDate, right::RDate) = RDateCompound([left,right])
function Base.show(io::IO, rdate::RDateCompound)
    for (i,part) in enumerate(rdate.parts)
        if i > 1 print(io, "+") end
        show(io, part)
    end
end

struct RDateRepeat <: RDate
    count::Int64
    part::RDate
end

Base.:+(rdate::RDateRepeat, date::Dates.Date) = Base.foldl(+, fill(rdate.part, rdate.count), init=date)
Base.:-(rdate::RDateRepeat) = RDateRepeat(rdate.count, -rdate.part)
Base.show(io::IO, rdate::RDateRepeat) = (print(io, "$(rdate.count)*("), show(io, rdate.part), print(io,")"))

Base.:+(left::RDate, right::RDate) = combine(left, right)
Base.:-(left::RDate, right::RDate) = combine(left, -right)
Base.:*(count::Number, rdate::RDate) = RDateRepeat(count, rdate)
Base.:*(rdate::RDate, count::Number) = RDateRepeat(count, rdate)
