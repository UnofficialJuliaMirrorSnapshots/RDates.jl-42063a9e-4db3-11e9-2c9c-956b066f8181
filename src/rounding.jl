import Dates

struct HolidayRoundingNBD <: HolidayRoundingConvention end
function apply(::HolidayRoundingNBD, date::Dates.Date, calendar::Calendar)::Dates.Date
    while is_holiday(calendar, date)
        date += Dates.Day(1)
    end
    date
end
Base.show(io::IO, ::HolidayRoundingNBD) = print(io, "NBD")

struct HolidayRoundingPBD <: HolidayRoundingConvention end
function apply(::HolidayRoundingPBD, date::Dates.Date, calendar::Calendar)::Dates.Date
    while is_holiday(calendar, date)
        date -= Dates.Day(1)
    end
    date
end
Base.show(io::IO, ::HolidayRoundingPBD) = print(io, "PBD")

struct HolidayRoundingNBDSM <: HolidayRoundingConvention end
function apply(::HolidayRoundingNBDSM, date::Dates.Date, calendar::Calendar)::Dates.Date
    new_date = date
    while is_holiday(calendar, new_date)
        new_date += Dates.Day(1)
    end

    if Dates.month(new_date) != Dates.month(date)
        new_date = date
        while is_holiday(calendar, new_date)
            new_date -= Dates.Day(1)
        end
    end

    new_date
end
Base.show(io::IO, ::HolidayRoundingNBDSM) = print(io, "NBDSM")

struct HolidayRoundingPBDSM <: HolidayRoundingConvention end
function apply(::HolidayRoundingPBDSM, date::Dates.Date, calendar::Calendar)::Dates.Date
    new_date = date
    while is_holiday(calendar, new_date)
        new_date -= Dates.Day(1)
    end

    if Dates.month(new_date) != Dates.month(date)
        new_date = date
        while is_holiday(calendar, new_date)
            new_date += Dates.Day(1)
        end
    end

    new_date
end
Base.show(io::IO, ::HolidayRoundingPBDSM) = print(io, "PBDSM")

struct HolidayRoundingNR <: HolidayRoundingConvention end
apply(::HolidayRoundingNR, date::Dates.Date, ::Calendar) = date
Base.show(io::IO, ::HolidayRoundingNR) = print(io, "NR")

const HOLIDAY_ROUNDING_MAPPINGS = Dict("NR" => HolidayRoundingNR(), "NBD" => HolidayRoundingNBD(), "PBD" => HolidayRoundingPBD(), "NBDSM" => HolidayRoundingNBDSM(), "PBDSM" => HolidayRoundingPBDSM())
