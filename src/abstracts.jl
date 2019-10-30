import Dates
using Compat

@compat abstract type RDate end
# Calendars
@compat abstract type CalendarManager end
@compat abstract type Calendar end
# Conventions
@compat abstract type HolidayRoundingConvention end
@compat abstract type InvalidDayConvention end
@compat abstract type MonthIncrementConvention end

"""
    NullCalendarManager() <: CalendarManager

The most primitive calendar manager, that will return an error for any request to
get a calendar. The default calendar manager that is available when applying rdates
using the + operator, without an explicit calendar manager.
"""
struct NullCalendarManager <: CalendarManager end

"""
    is_holiday(calendar::Calendar, date::Dates.Date)::Bool

Determine whether the date requested is a holiday for this calendar or not.
"""
is_holiday(x::Calendar, ::Dates.Date) = error("$(typeof(x)) does not support is_holiday")

"""
    calendar(calendarmgr::CalendarManager, names::Vector{String})::Calendar

Given a set of calendar names, request the calendar manager to retrieve the associated
calendar that supports the union of them.
"""
calendar(x::CalendarManager, names)::Calendar = error("$(typeof(x)) does not support calendar")

"""
    apply(rdate::RDate, date::Dates.Date, calendarmgr::CalendarManager)::Dates.Date

The application of an rdate to a specific date, given an explicit calendar manager.
"""
apply(rd::RDate, ::Dates.Date, ::CalendarManager)::Dates.Date = error("$(typeof(rd)) does not support date apply")

"""
    multiply_no_roll(rdate::RDate, count::Integer)::RDate

An internalised multiplication of an rdate which is generated without reapplication of a relative date multiple
times. This differs from multiply_roll when either calendars or month adjustments are involved.

For example "6m" + "6m" != "12m" for all dates, due to the fact that there are different days in each month
and invalid day conventions will kick in.
"""
multiply_no_roll(rd::RDate, count::Integer) = error("$(typeof(rd)) does not support no roll multiplication")

calendar_mgr = NullCalendarManager()
function with_cal_mgr(f::Function, cal_mgr::CalendarManager)
    global calendar_mgr
    current_cal_mgr = calendar_mgr
    calendar_mgr = cal_mgr
    try
        f()
    finally
        calendar_mgr = current_cal_mgr
    end
end

"""
    apply(rdate::RDate, date::Dates.Date)::Dates.Date

The application of an rdate to a specific date, without an explicit calendar manager.
This will use the globally specified calendar manager defined at the point of request.
"""
apply(rd::RDate, date::Dates.Date) = apply(rd, date, calendar_mgr)
Base.:+(rd::RDate, date::Dates.Date) = apply(rd, date)
Base.:+(date::Dates.Date, rd::RDate) = apply(rd, date)
Base.:-(date::Dates.Date, rd::RDate) = apply(-rd, date)
Base.:-(x::RDate)::RDate = error("$(typeof(x)) does not support negation")

"""
    apply(rounding::HolidayRoundingConvention, date::Dates.Date, calendar::Calendar)::Dates.Date

Apply the appropriate adjustment to the date if it falls on a holiday for the given calendar. Be aware
that there is no strict requirement that the resolved date will not be a holiday for the given calendar.
"""
apply(x::HolidayRoundingConvention, date::Dates.Date, calendar::Calendar) = error("$(typeof(x)) does not support apply")

"""
    apply(rounding::InvalidDayConvention, day::Integer, month::Integer, year::Integer)::Dates.Date

Given a day, month and year which do not generate a valid date, adjust them in some form to a valid date.
"""
adjust(x::InvalidDayConvention, day, month, year) = error("$(typeof(x)) does not support adjust")

"""
    apply(rounding::MonthIncrementConvention, from::Dates.Date, new_month::Integer, new_year::Integer, calendar_mgr::CalendarManager)::Tuple{Integer, Integer, Integer}

Given the initial day, month and year that we're moving from and a generated new month and new year, determine the new
day, month and year that should be used. Generally used to handle specific features around preservation of month ends
or days of week, if required.

Note that the generated (day, month, year) do not need to be able to produce a valid date. The invalid day convention
should be applied, if required, after this calculation.

May use a calendar manager if required as well
"""
adjust(x::MonthIncrementConvention, from::Dates.Date, new_month, new_year, calendar_mgr::CalendarManager) = error("$(typeof(x)) does not support adjust")
