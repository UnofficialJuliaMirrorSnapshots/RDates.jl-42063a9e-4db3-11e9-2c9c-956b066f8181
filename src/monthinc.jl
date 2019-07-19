module MonthIncrement
# We define as a separate module to keep the naming convention clean.
using Compat
import Dates

@compat abstract type MonthIncrementConvention end
adjust(mim::MonthIncrementConvention, day, month, year, new_month, new_year) = error("Needs implementation")

struct PreserveDayOfMonth <: MonthIncrementConvention end
adjust(mim::PreserveDayOfMonth, day, month, year, new_month, new_year) = (new_year, new_month, day)
Base.show(io::IO, ::PreserveDayOfMonth) = print(io, "PDOM")

struct PreserveDayOfMonthEOM <: MonthIncrementConvention end
function adjust(mim::PreserveDayOfMonthEOM, day, month, year, new_month, new_year)
    ld = Dates.daysinmonth(year, month)
    return (new_year, new_month, day == ld ? Dates.daysinmonth(new_year, new_month) : day)
end
Base.show(io::IO, ::PreserveDayOfMonthEOM) = print(io, "PDOMEOM")

const PDOM = PreserveDayOfMonth()
const PDOMEOM = PreserveDayOfMonthEOM()

const MAPPINGS = Dict("PDOM" => PDOM, "PDOMEOM" => PDOMEOM)

end # Module
