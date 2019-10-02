import StaticArrays

struct RDateCompound{T} <: RDate
    parts::StaticArrays.SVector{T,RDate}

    RDateCompound(parts) = new{length(parts)}(parts)
end

apply(rdate::RDateCompound, date::Dates.Date, cal_mgr::CalendarManager) = Base.foldl((x,y) -> apply(y, x, cal_mgr), rdate.parts, init=date)
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

apply(rdate::RDateRepeat, date::Dates.Date, cal_mgr::CalendarManager) = Base.foldl((x,y) -> apply(y, x, cal_mgr), fill(rdate.part, rdate.count), init=date)
Base.:-(rdate::RDateRepeat) = RDateRepeat(rdate.count, -rdate.part)
Base.show(io::IO, rdate::RDateRepeat) = (print(io, "$(rdate.count)*("), show(io, rdate.part), print(io,")"))

Base.:+(left::RDate, right::RDate) = combine(left, right)
Base.:-(left::RDate, right::RDate) = combine(left, -right)
Base.:*(count::Number, rdate::RDate) = rdate*count
Base.:*(rdate::RDate, count::Number) = RDateRepeat(count, rdate)

struct CalendarAdj{R <: RDate, S <: HolidayRoundingConvention, T} <: RDate
    calendar_names::StaticArrays.SVector{T,String}
    part::R
    rounding::S

    CalendarAdj(calendar_names, part::R, rounding::S) where {R <: RDate, S <: HolidayRoundingConvention} = new{R, S, length(calendar_names)}(calendar_names, part, rounding)
end

function apply(rdate::CalendarAdj, date::Dates.Date, cal_mgr::CalendarManager)
    base_date = apply(rdate.part, date, cal_mgr)
    cal = calendar(cal_mgr, rdate.calendar_names)
    apply(rdate.rounding, base_date, cal)
end

Base.:-(x::CalendarAdj) = CalendarAdj(x.calendar_names, -x.part, x.rounding)

struct Next{T} <: RDate
    parts::StaticArrays.SVector{T,RDate}
    inclusive::Bool

    Next(parts, inclusive::Bool) = new{length(parts)}(parts, inclusive)
end

function apply(rdate::Next, date::Dates.Date, cal_mgr::CalendarManager)
    results = filter(x -> x > date || (rdate.inclusive && x == date), map(x -> apply(x, date, cal_mgr), rdate.parts))
    length(results) > 0 || error("$(rdate) does not evaluate to a future date for $(date)")
    minimum(results)
end

struct Last{T} <: RDate
    parts::StaticArrays.SVector{T,RDate}
    inclusive::Bool

    Last(parts, inclusive::Bool) = new{length(parts)}(parts, inclusive)
end

function apply(rdate::Last, date::Dates.Date, cal_mgr::CalendarManager)
    results = filter(x -> x < date || (rdate.inclusive && x == date), map(x -> apply(x, date, cal_mgr), rdate.parts))
    length(results) > 0 || error("$(rdate) does not evaluate to a future date for $(date)")
    maximum(results)
end
