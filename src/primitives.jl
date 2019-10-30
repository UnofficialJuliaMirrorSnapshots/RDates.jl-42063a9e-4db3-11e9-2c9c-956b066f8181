import Dates
using AutoHashEquals

const WEEKDAYS = Dict(map(reverse,enumerate(map(Symbol ∘ uppercase, Dates.ENGLISH.days_of_week_abbr))))
const NTH_PERIODS = ["1st", "2nd", "3rd", "4th", "5th"]
const NTH_LAST_PERIODS = ["Last", "2nd Last", "3rd Last", "4th Last", "5th Last"]
const PERIODS = merge(Dict(map(reverse,enumerate(NTH_PERIODS))), Dict(map(reverse,enumerate(NTH_LAST_PERIODS))))
const MONTHS = Dict(zip(map(Symbol ∘ uppercase, Dates.ENGLISH.months_abbr),range(1,stop=12)))

@auto_hash_equals struct FDOM <: RDate
    calendars::Union{Vector{String}, Nothing}
    FDOM() = new(nothing)
    FDOM(calendars) = new(calendars)
end
function apply(rdate::FDOM, d::Dates.Date, cal_mgr::CalendarManager)
    fdom = Dates.firstdayofmonth(d)
    if rdate.calendars !== nothing
        fdom = apply(HolidayRoundingNBD(), fdom, calendar(cal_mgr, rdate.calendars))
    end

    return fdom
end
multiply_roll(x::FDOM, ::Integer) = x
multiply_no_roll(x::FDOM, ::Integer) = x
Base.:-(x::FDOM) = x

Base.show(io::IO, rdate::FDOM) = print(io, rdate.calendars === nothing ? "FDOM" : "FDOM@$(join(rdate.calendars, "|"))")
register_grammar!(E"FDOM" > FDOM)
register_grammar!(E"FDOM@" + p"[a-zA-Z\\\\\\s\\|]+" > calendar_name -> FDOM(map(String, split(calendar_name, "|"))))

@auto_hash_equals struct LDOM <: RDate
    calendars::Union{Vector{String}, Nothing}
    LDOM() = new(nothing)
    LDOM(calendars) = new(calendars)
end
function apply(rdate::LDOM, d::Dates.Date, cal_mgr::CalendarManager)
    ldom = Dates.lastdayofmonth(d)
    if rdate.calendars !== nothing
        ldom = apply(HolidayRoundingPBD(), ldom, calendar(cal_mgr, rdate.calendars))
    end

    return ldom
end
multiply_roll(x::LDOM, ::Integer) = x
multiply_no_roll(x::LDOM, ::Integer) = x
Base.:-(x::LDOM) = x

Base.show(io::IO, rdate::LDOM) = print(io, rdate.calendars === nothing ? "LDOM" : "LDOM@$(join(rdate.calendars, "|"))")
register_grammar!(E"LDOM" > LDOM)
register_grammar!(E"LDOM@" + p"[a-zA-Z\\\\\\s\\|]+" > calendar_name -> LDOM(map(String, split(calendar_name, "|"))))

struct Easter <: RDate
    yearδ::Int64
end

function apply(rdate::Easter, date::Dates.Date, cal_mgr::CalendarManager)
    y = Dates.year(date) + rdate.yearδ
    a = rem(y, 19)
    b = div(y, 100)
    c = rem(y, 100)
    d = div(b, 4)
    e = rem(b, 4)
    f = div(b + 8, 25)
    g = div(b - f + 1, 3)
    h = rem(19*a + b - d - g + 15, 30)
    i = div(c, 4)
    k = rem(c, 4)
    l = rem(32 + 2*e + 2*i - h - k, 7)
    m = div(a + 11*h + 22*l, 451)
    n = div(h + l - 7*m + 114, 31)
    p = rem(h + l - 7*m + 114, 31)
    return Dates.Date(y, n, p + 1)
end
multiply_roll(x::Easter, count::Integer) = Easter(x.yearδ*count)
multiply_no_roll(x::Easter, count::Integer) = Easter(x.yearδ*count)

Base.:-(rdate::Easter) = Easter(-rdate.yearδ)
Base.show(io::IO, rdate::Easter) = print(io, "$(rdate.yearδ)E")
register_grammar!(PInt64() + E"E" > Easter)

struct Day <: RDate
    days::Int64
end

apply(x::Day, y::Dates.Date, cal_mgr::CalendarManager) = y + Dates.Day(x.days)
multiply_roll(x::Day, count::Integer) = Day(x.days*count)
multiply_no_roll(x::Day, count::Integer) = Day(x.days*count)
Base.:-(x::Day) = Day(-x.days)
Base.:+(x::Day, y::Day) = Day(x.days + y.days)

Base.show(io::IO, rdate::Day) = print(io, "$(rdate.days)d")
register_grammar!(PInt64() + E"d" > Day)

struct Week <: RDate
    weeks::Int64
end

apply(x::Week, y::Dates.Date, cal_mgr::CalendarManager) = y + Dates.Week(x.weeks)
multiply_roll(x::Week, count::Integer) = Week(x.weeks*count)
multiply_no_roll(x::Week, count::Integer) = Week(x.weeks*count)
Base.:-(x::Week) = Week(-x.weeks)
Base.:+(x::Week, y::Week) = Week(x.weeks + y.weeks)
Base.:+(x::Day, y::Week) = Day(x.days + 7*y.weeks)
Base.:+(x::Week, y::Day) = Day(7*x.weeks + y.days)

Base.show(io::IO, rdate::Week) = print(io, "$(rdate.weeks)w")
register_grammar!(PInt64() + E"w" > Week)

struct Month <: RDate
    months::Int64
    idc::InvalidDayConvention
    mic::MonthIncrementConvention

    Month(months::Int64) = new(months, InvalidDayLDOM(), MonthIncrementPDOM())
    Month(months::Int64, idc::InvalidDayConvention, mic::MonthIncrementConvention) = new(months, idc, mic)
end

function apply(rdate::Month, date::Dates.Date, cal_mgr::CalendarManager)
    y, m = Dates.yearmonth(date)
    ny = Dates.yearwrap(y, m, rdate.months)
    nm = Dates.monthwrap(m, rdate.months)
    ay, am, ad = adjust(rdate.mic, date, nm, ny, cal_mgr)
    ld = Dates.daysinmonth(ay, am)
    return ad <= ld ? Dates.Date(ay, am, ad) : adjust(rdate.idc, ad, am, ay)
end
multiply_no_roll(x::Month, count::Integer) = Month(x.months*count, x.idc, x.mic)
Base.:-(x::Month) = Month(-x.months)

Base.show(io::IO, rdate::Month) = (print(io, "$(rdate.months)m["), show(io, rdate.idc), print(io, ";"), show(io, rdate.mic), print(io,"]"))
register_grammar!(PInt64() + E"m" > Month)
register_grammar!(PInt64() + E"m[" + Alt(map(Pattern, collect(keys(INVALID_DAY_MAPPINGS)))...) + E";" + Alt(map(Pattern, collect(keys(MONTH_INCREMENT_MAPPINGS)))...) + E"]" > (d,idc,mic) -> Month(d, INVALID_DAY_MAPPINGS[idc], MONTH_INCREMENT_MAPPINGS[mic]))
# We also have the more complex PDOMEOM month increment which we handle separately.
register_grammar!(PInt64() + E"m[" + Alt(map(Pattern, collect(keys(INVALID_DAY_MAPPINGS)))...) + E";PDOMEOM@" + p"[a-zA-Z\\\\\\s\\|]+" + E"]" > (d,idc,calendar_name) -> Month(d, INVALID_DAY_MAPPINGS[idc], MonthIncrementPDOMEOM(map(String, split(calendar_name, "|")))))

struct Year <: RDate
    years::Int64
    idc::InvalidDayConvention
    mic::MonthIncrementConvention

    Year(years::Int64) = new(years, InvalidDayLDOM(), MonthIncrementPDOM())
    Year(years::Int64, idc::InvalidDayConvention, mic::MonthIncrementConvention) = new(years, idc, mic)
end

function apply(rdate::Year, date::Dates.Date, cal_mgr::CalendarManager)
    oy, m = Dates.yearmonth(date)
    ny = oy + rdate.years
    (ay, am, ad) = adjust(rdate.mic, date, m, ny, cal_mgr)
    ld = Dates.daysinmonth(ay, am)
    return ad <= ld ? Dates.Date(ay, am, ad) : adjust(rdate.idc, ad, am, ay)
end
multiply_no_roll(x::Year, count::Integer) = Year(x.years*count, x.idc, x.mic)
Base.:-(x::Year) = Year(-x.years)

Base.show(io::IO, rdate::Year) = (print(io, "$(rdate.years)y["), show(io, rdate.idc), print(io, ";"), show(io, rdate.mic), print(io,"]"))
register_grammar!(PInt64() + E"y" > Year)
register_grammar!(PInt64() + E"y[" + Alt(map(Pattern, collect(keys(INVALID_DAY_MAPPINGS)))...) + E";" + Alt(map(Pattern, collect(keys(MONTH_INCREMENT_MAPPINGS)))...) + E"]" > (d,idc,mic) -> Year(d, INVALID_DAY_MAPPINGS[idc], MONTH_INCREMENT_MAPPINGS[mic]))
# We also have the more complex PDOMEOM month increment which we handle separately.
register_grammar!(PInt64() + E"y[" + Alt(map(Pattern, collect(keys(INVALID_DAY_MAPPINGS)))...) + E";PDOMEOM@" + p"[a-zA-Z\\\\\\s\\|]+" + E"]" > (d,idc,calendar_name) -> Year(d, INVALID_DAY_MAPPINGS[idc], MonthIncrementPDOMEOM(map(String, split(calendar_name, "|")))))

struct DayMonth <: RDate
    day::Int64
    month::Int64

    DayMonth(day::Int64, month::Int64) = new(day, month)
end

apply(rdate::DayMonth, date::Dates.Date, cal_mgr::CalendarManager) = Dates.Date(Dates.year(date), rdate.month, rdate.day)
multiply_roll(x::DayMonth, ::Integer) = x
multiply_no_roll(x::DayMonth, ::Integer) = x
Base.:-(x::DayMonth) = x

Base.show(io::IO, rdate::DayMonth) = print(io, "$(rdate.day)$(uppercase(Dates.ENGLISH.months_abbr[rdate.month]))")
register_grammar!(PPosInt64() + month_short > (d,m) -> DayMonth(d,MONTHS[Symbol(m)]))

struct Date <: RDate
    date::Dates.Date

    Date(date::Dates.Date) = new(date)
    Date(y::Int64, m::Int64, d::Int64) = new(Dates.Date(y, m, d))
end

multiply_roll(x::Date, ::Integer) = x
multiply_no_roll(x::Date, ::Integer) = x
Base.:-(x::Date) = x

apply(rdate::Date, date::Dates.Date, cal_mgr::CalendarManager) = rdate.date
Base.show(io::IO, rdate::Date) = print(io, "$(Dates.day(rdate.date))$(uppercase(Dates.ENGLISH.months_abbr[Dates.month(rdate.date)]))$(Dates.year(rdate.date))")
register_grammar!(PPosInt64() + month_short + PPosInt64() > (d,m,y) -> Date(Dates.Date(y, MONTHS[Symbol(m)], d)))

struct NthWeekdays <: RDate
    dayofweek::Int64
    period::Int64

    NthWeekdays(dayofweek::Int64, period::Int64) = new(dayofweek, period)
end

function apply(rdate::NthWeekdays, date::Dates.Date, cal_mgr::CalendarManager)
    wd = Dates.dayofweek(date)
    wd1st = mod(wd - mod(Dates.day(date), 7), 7) + 1
    wd1stdiff = wd1st - rdate.dayofweek
    period = wd1stdiff > 0 ? rdate.period : rdate.period - 1
    days = 7*period - wd1stdiff + 1
    return Dates.Date(Dates.year(date), Dates.month(date), days)
end
multiply_roll(x::NthWeekdays, ::Integer) = x
multiply_no_roll(x::NthWeekdays, ::Integer) = x
Base.:-(x::NthWeekdays) = x

Base.show(io::IO, rdate::NthWeekdays) = print(io, "$(NTH_PERIODS[rdate.period]) $(uppercase(Dates.ENGLISH.days_of_week_abbr[rdate.dayofweek]))")

register_grammar!(Alt(map(Pattern, NTH_PERIODS)...) + space + weekday_short > (p,wd) -> NthWeekdays(WEEKDAYS[Symbol(wd)], PERIODS[p]))

struct NthLastWeekdays <: RDate
    dayofweek::Int64
    period::Int64

    NthLastWeekdays(dayofweek::Int64, period::Int64) = new(dayofweek, period)
end

function apply(rdate::NthLastWeekdays, date::Dates.Date, cal_mgr::CalendarManager)
    ldom = LDOM() + date
    ldom_dow = Dates.dayofweek(ldom)
    ldom_dow_diff = ldom_dow - rdate.dayofweek
    period = ldom_dow_diff >= 0 ? rdate.period - 1 : rdate.period
    days_to_sub = 7*period + ldom_dow_diff
    days = Dates.day(ldom) - days_to_sub
    return Dates.Date(Dates.year(date), Dates.month(date), days)
end
multiply_roll(x::NthLastWeekdays, ::Integer) = x
multiply_no_roll(x::NthLastWeekdays, ::Integer) = x
Base.:-(x::NthLastWeekdays) = x

Base.show(io::IO, rdate::NthLastWeekdays) = print(io, "$(NTH_LAST_PERIODS[rdate.period]) $(uppercase(Dates.ENGLISH.days_of_week_abbr[rdate.dayofweek]))")

register_grammar!(Alt(map(Pattern, NTH_LAST_PERIODS)...) + space + weekday_short > (p,wd) -> NthLastWeekdays(WEEKDAYS[Symbol(wd)], PERIODS[p]))

struct Weekdays <: RDate
    dayofweek::Int64
    count::Int64
    inclusive::Bool

    Weekdays(dayofweek::Int64, count::Int64) = new(dayofweek, count, false)
    Weekdays(dayofweek::Int64, count::Int64, inclusive::Bool) = new(dayofweek, count, true)
end

function apply(rdate::Weekdays, date::Dates.Date, cal_mgr::CalendarManager)
    dayδ = Dates.dayofweek(date) - rdate.dayofweek
    weekδ = rdate.count

    if rdate.count < 0 && (dayδ > 0 || (rdate.inclusive && dayδ == 0))
        weekδ += 1
    elseif rdate.count > 0 && (dayδ < 0 || (rdate.inclusive && dayδ == 0))
        weekδ -= 1
    end

    return date + Dates.Day(weekδ*7 - dayδ)
end

multiply_no_roll(x::Weekdays, count::Integer) = Weekdays(x.dayofweek, x.count * count, x.inclusive)
Base.:-(rdate::Weekdays) = Weekdays(rdate.dayofweek, -rdate.count)

Base.show(io::IO, rdate::Weekdays) = print(io, "$(rdate.count)$(uppercase(Dates.ENGLISH.days_of_week_abbr[rdate.dayofweek]))")
register_grammar!(PNonZeroInt64() + weekday_short > (i,wd) -> Weekdays(WEEKDAYS[Symbol(wd)], i))
register_grammar!(PNonZeroInt64() + weekday_short + E"!" > (i,wd) -> Weekdays(WEEKDAYS[Symbol(wd)], i, true))

@auto_hash_equals struct BizDays{S <: HolidayRoundingConvention} <: RDate
    days::Int64
    calendar_names::Vector{String}
    rounding::S

    # I have twisted and turned on what the right default is for holiday start dates.
    # Going with next business day (or previous business day if negated) for 0b and no rounding otherwise.
    # This means that 0b and 1b will give you the same result if you start from a holiday, but I'm comfortable with that.
    BizDays(days::Int64, calendar_names) = BizDays(days, calendar_names, days == 0 ? HolidayRoundingNBD() : HolidayRoundingNR())
    BizDays(days::Int64, calendar_names, rounding::S) where {S <: HolidayRoundingConvention} = new{S}(days, calendar_names, rounding)
end

function apply(rdate::BizDays, date::Dates.Date, cal_mgr::CalendarManager)
    cal = calendar(cal_mgr, rdate.calendar_names)
    date = apply(rdate.rounding, date, cal)

    count = rdate.days
    if rdate.days > 0
        rounding = HolidayRoundingNBD()
        while count > 0
            date = apply(rounding, date + Dates.Day(1), cal)
            count -= 1
        end
    elseif rdate.days < 0
        rounding = HolidayRoundingPBD()
        while count < 0
            date = apply(rounding, date - Dates.Day(1), cal)
            count += 1
        end
    end

    return date
end

function multiply_no_roll(x::BizDays, count::Integer)
    x = count < 0 ? -x : x
    return BizDays(x.count * abs(count), x.calendar_names, x.rounding)
end

Base.:-(x::BizDays{HolidayRoundingNBD}) = BizDays(-x.days, x.calendar_names, HolidayRoundingPBD())
Base.:-(x::BizDays{HolidayRoundingPBD}) = BizDays(-x.days, x.calendar_names, HolidayRoundingNBD())
Base.:-(x::BizDays{HolidayRoundingNBDSM}) = BizDays(-x.days, x.calendar_names, HolidayRoundingPBDSM())
Base.:-(x::BizDays{HolidayRoundingPBDSM}) = BizDays(-x.days, x.calendar_names, HolidayRoundingNBDSM())
Base.:-(x::BizDays{HolidayRoundingNR}) = BizDays(-x.days, x.calendar_names, HolidayRoundingNR())

register_grammar!(PPosZeroInt64() + E"b@" + p"[a-zA-Z\\\\\\s\\|]+" > (days,calendar_name) -> BizDays(days, map(String, split(calendar_name, "|"))))
