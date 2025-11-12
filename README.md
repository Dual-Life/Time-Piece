# Time::Piece

[![CI Tests](https://github.com/Dual-Life/Time-Piece/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/Dual-Life/Time-Piece/actions)

A Perl module that replaces the standard `localtime` and `gmtime` functions with implementations that return objects.

## Documentation

# NAME

Time::Piece - Object Oriented time objects

# SYNOPSIS

    use Time::Piece;

    my $t = localtime;
    print "Time is $t\n";
    print "Year is ", $t->year, "\n";

# DESCRIPTION

This module replaces the standard `localtime` and `gmtime` functions with
implementations that return objects. It does so in a backwards
compatible manner, so that using localtime/gmtime in the way documented
in perlfunc will still return what you expect.

The module actually implements most of an interface described by
Larry Wall on the perl5-porters mailing list here:
[https://www.nntp.perl.org/group/perl.perl5.porters/2000/01/msg5283.html](https://www.nntp.perl.org/group/perl.perl5.porters/2000/01/msg5283.html)

After importing this module, when you use `localtime` or `gmtime` in a scalar
context, rather than getting an ordinary scalar string representing the
date and time, you get a `Time::Piece` object, whose stringification happens
to produce the same effect as the `localtime` and `gmtime` functions.

The primary way to create Time::Piece objects is through the `localtime` and
`gmtime` functions. There is also a `new()` constructor which is the same as
`localtime()`, except when passed a Time::Piece object, in which case it's a
copy constructor.

# Public Methods

The following methods are available on the object:

## Time Components

    $t->sec                 # also available as $t->second
    $t->min                 # also available as $t->minute
    $t->hour                # 24 hour

## Date Components

    $t->mday                # also available as $t->day_of_month
    $t->mon                 # 1 = January
    $t->_mon                # 0 = January
    $t->year                # based at 0 (year 0 AD is, of course 1 BC)
    $t->_year               # year minus 1900
    $t->yy                  # 2 digit year

## Day and Month Names

    $t->monname             # Feb
    $t->month               # same as $t->monname
    $t->fullmonth           # February
    $t->wday                # 1 = Sunday
    $t->_wday               # 0 = Sunday
    $t->day_of_week         # 0 = Sunday
    $t->wdayname            # Tue
    $t->day                 # same as wdayname
    $t->fullday             # Tuesday

## Formatted Date/Time Output

    $t->hms                 # 12:34:56
    $t->hms(".")            # 12.34.56
    $t->time                # same as $t->hms
    $t->ymd                 # 2000-02-29
    $t->date                # same as $t->ymd
    $t->mdy                 # 02-29-2000
    $t->mdy("/")            # 02/29/2000
    $t->dmy                 # 29-02-2000
    $t->dmy(".")            # 29.02.2000
    $t->datetime            # 2000-02-29T12:34:56 (ISO 8601)
    $t->cdate               # Tue Feb 29 12:34:56 2000
    "$t"                    # same as $t->cdate
    $t->strftime(FORMAT)    # same as POSIX::strftime (without the overhead
                            # of the full POSIX extension)
    $t->strftime()          # "Tue, 29 Feb 2000 12:34:56 GMT"

### strftime Format Flags

The `strftime` method calls your system's native `strftime()` implementation,
so the supported format flags and their behavior will depend on your platform.

**Platform Variability:** Some format flags behave differently or may be missing
entirely on certain platforms. The following flags are known to have
platform-specific issues: `%e`, `%D`, `%F`, `%k`, `%l`, `%P`, `%r`, `%R`,
`%s`, `%T`, `%u`, `%V`, `%z`, and `%Z`.

To mitigate these differences, `Time::Piece` includes a special translation layer
that attempts to unify behavior across platforms. For example, `%F` is not
available on some Microsoft platforms, so it is automatically converted to
`"%Y-%m-%d"` internally before calling the system's `strftime()`.

For a complete list of format flags supported by your system, consult your
platform's `strftime(3)` manual page (`man strftime` on Unix-like systems).

## Epoch and Calendar Calculations

    $t->epoch               # seconds since the epoch
    $t->julian_day          # number of days since Julian period began
    $t->mjd                 # modified Julian date (JD-2400000.5 days)
    $t->week                # week number (ISO 8601)
    $t->yday                # also available as $t->day_of_year, 0 = Jan 01

## Timezone and DST

    $t->tzoffset            # timezone offset in a Time::Seconds object
    $t->isdst               # also available as $t->daylight_savings

The `isdst` method returns:

- 0 for GMT/UTC times (they never have DST)
- 0 or 1 for local times depending on whether DST is active
- Automatically calculated if unknown

The `tzoffset` method returns the offset from UTC as a Time::Seconds object.
For GMT/UTC times, this always returns 0. For local times, it calculates
the actual offset including any DST adjustment.

## Utility Methods

    $t->is_leap_year        # true if it's a leap year
    $t->month_last_day      # 28-31
    $t->add_days            # Add days
    $t->add_months          # Add months
    $t->add_years           # Add years

## Global Configuration

    $t->time_separator($s)     # set the default separator (default ":")
    $t->date_separator($s)     # set the default separator (default "-")
    $t->day_list(@days)        # set the names used by wdayname()
    $t->mon_list(@months)      # set the names used by month()
    $t->fullday_list(@days)    # set the names used by fullday()
    $t->fullmon_list(@months)  # set the names used by fullmonth()

## Parsing

    Time::Piece->strptime(STRING, FORMAT)
                            # see strptime man page. Creates a new
                            # Time::Piece object

**Note:** `localtime` and `gmtime` are not listed above. If called as
methods on a Time::Piece object, they act as constructors, returning a new
Time::Piece object for the current time. In other words: they're not useful as
methods.

# Date Calculations

It's possible to use simple addition and subtraction of objects:

    use Time::Seconds;

    my $seconds = $t1 - $t2;
    $t1 += ONE_DAY; # add 1 day (constant from Time::Seconds)

The following are valid ($t1 and $t2 are Time::Piece objects):

    $t1 - $t2; # returns Time::Seconds object
    $t1 - 42; # returns Time::Piece object
    $t1 + 533; # returns Time::Piece object
    $t1->add_days(2); # returns Time::Piece object

**Note:** All arithmetic uses epoch seconds (UTC). When daylight saving time
(DST) changes occur:

- Adding seconds works on UTC time, so adding 3600 seconds during DST
transition from 1:30 AM gives 3:30 AM (not 2:30 AM, which doesn't exist
during "spring forward")
- Subtracting across DST transitions may differ from wall-clock expectations
due to skipped or repeated hours

## Adding Months and Years

Two methods handle calendar arithmetic differently than seconds-based math:

    $t = $t->add_months(6);
    $t = $t->add_years(5);

**Important behaviors:**

- These preserve the day-of-month number, which can cause overflow (Jan 31 + 1
month = Mar 3, since "Feb 31" doesn't exist)
- Wall-clock time is preserved across DST transitions
- Order matters: `add_months(1)` then `+ 86400` gives different results than
`+ 86400` then `add_months(1)`

# Truncation

Calling the `truncate` method returns a copy of the object but with the
time truncated to the start of the supplied unit.

    $t = $t->truncate(to => 'day');

This example will set the time to midnight on the same date which `$t`
had previously. Allowed values for the "to" parameter are: "year",
"quarter", "month", "day", "hour", "minute" and "second".

# Date Comparisons

Date comparisons are also possible, using the full suite of "<", ">",
"<=", ">=", "<=>", "==" and "!=".

All comparisons use epoch seconds, so they work correctly across timezones:

    my $t1 = localtime;
    my $t2 = gmtime;
    if ($t1 > $t2) {  # Compares actual moments in time, not clock values
        # ...
    }

Time::Piece objects can also be compared as strings using `cmp`:

    if ($t1 cmp "2024-01-15") {  # Compares against cdate format
        # ...
    }

# Date Parsing

Time::Piece provides flexible date parsing via the built-in `strptime()`
function (from FreeBSD).

For more information on acceptible formats and flags for `strptime` see
"man strptime" on unix systems. Alternatively look here:
[http://www.unix.com/man-page/FreeBSD/3/strftime/](http://www.unix.com/man-page/FreeBSD/3/strftime/)

## Basic Usage

    my $t = Time::Piece->strptime("Sunday 3rd Nov, 1943",
                                  "%A %drd %b, %Y");

    print $t->strftime("%a, %d %b %Y");

Outputs:

    Wed, 03 Nov 1943

The default format string is `"%a, %d %b %Y %H:%M:%S %Z"`, so these are equivalent:

    my $t1 = Time::Piece->strptime($string);
    my $t2 = Time::Piece->strptime($string, "%a, %d %b %Y %H:%M:%S %Z");

## Supported Format Flags

`Time::Piece` uses a custom `strptime()` implementation that supports the
following format flags:

    Flag  Description
    ----  -----------
    %%    Literal '%' character
    %a    Abbreviated weekday name (Mon, Tue, etc.)
    %A    Full weekday name (Monday, Tuesday, etc.)
    %b    Abbreviated month name (Jan, Feb, etc.)
    %B    Full month name (January, February, etc.)
    %C    Century number (00-99)
    %d    Day of month (01-31)
    %D    Equivalent to %m/%d/%y
    %e    Day of month ( 1-31, space-padded)
    %f    Fractional seconds as microseconds (up to 6 digits, parsed but ignored)
    %F    Equivalent to %Y-%m-%d (ISO 8601 date format)
    %h    Abbreviated month name (same as %b)
    %H    Hour in 24-hour format (00-23)
    %I    Hour in 12-hour format (01-12)
    %j    Day of year (001-366)
    %k    Hour in 24-hour format ( 0-23, space-padded)
    %l    Hour in 12-hour format ( 1-12, space-padded)
    %m    Month number (01-12)
    %M    Minute (00-59)
    %n    Any whitespace
    %p    AM/PM indicator
    %P    Alt AM/PM indicator
    %r    Time in AM/PM format (%I:%M:%S %p, or %H:%M:%S if locale has no AM/PM)
    %R    Equivalent to %H:%M
    %s    Seconds since Unix epoch (1970-01-01 00:00:00 UTC)
    %S    Second (00-60, allowing for leap seconds)
    %t    Any whitespace (same as %n)
    %T    Equivalent to %H:%M:%S
    %u    Weekday as number (1-7, Monday = 1)
    %w    Weekday as number (0-6, Sunday = 0)
    %y    Year within century (00-99). Values 00-68 are 2000-2068, 69-99 are 1969-1999
    %Y    Year with century (e.g., 2024)
    %z    Timezone offset (+HHMM, -HHMM, +HH:MM, or -HH:MM)
    %Z    Timezone name (only GMT and UTC recognized; others parsed but ignored)

**Unsupported Locale Flags:** The format flags `%c`, `%x`, and `%X` are **not**
supported as they are highly locale-dependent and have inconsistent formats
across systems. However, you can construct equivalent formats using the individual
flags listed above. For example, `%c` is typically equivalent to something like:

    "%a %b %e %H:%M:%S %Y"   # e.g., "Tue Feb 29 12:34:56 2000"

**Note:** `%U`, `%V`, and `%W` (week number formats) are parsed but not fully
implemented in the strptime logic, as they require additional date components
to calculate the actual date.

**Note:** `%f` (fractional seconds) is only supported in `strptime` for parsing.
It is not available in `strftime` for output formatting, as Time::Piece uses
epoch seconds which do not store subsecond precision.

## GMT vs Local Time

By default, `strptime` returns GMT objects when called as a class method:

    # Returns GMT (c_islocal = 0)
    Time::Piece->strptime($string, $format)

To get local time objects, you can:

    # Call as instance method on localtime object
    localtime()->strptime($string, $format)

    # Use explicit islocal option
    Time::Piece->strptime($string, $format, { islocal => 1 })

    # Pass a local Time::Piece object as defaults
    my $local = localtime();
    Time::Piece->strptime($string, $format, { defaults => $local })

The islocal and defaults options were added in version 1.37; the instance
method can be used for compatibility with previous versions.

## Timezone Parsing with %z and %Z

Time::Piece's `strptime()` function has some limited support for parsing timezone
information through two format specifiers: `%z` and `%Z`

Added in version 1.38. Prior to that, these flags were mostly ignored.
Consider the current implementation somewhat "alpha" and in need of feedback.

### Numeric Offsets (%z)

The `%z` specifier parses numeric timezone offsets
(format: `[+-]HHMM`, `[+-]HH:MM`, or `[+-]HH`):

    my $t = Time::Piece->strptime("2024-01-15 15:30:00 +0500",
                                  "%Y-%m-%d %H:%M:%S %z");
    print $t->hour;  # prints 10 (converted to UTC: 15:30 - 5:00)

Key behaviors:

- Offsets are applied to convert to UTC (`+0500` means "5 hours ahead of UTC")
- Valid range: `-1200` to `+1400` with minutes less than 60
- For local objects (`islocal == 1`), the result is converted to system timezone

Times parsed with timezone information default to GMT. To convert to local time:

    # Parse and convert to local timezone
    my $t = Time::Piece->strptime("2024-01-15 15:30:00 +0500",
                                  "%Y-%m-%d %H:%M:%S %z",
                                  { islocal => 1 });
    # Result: 10:30 UTC converted to your local timezone

### Timezone Names (%Z)

The `%Z` specifier currently only recognizes "GMT" and "UTC" (case-sensitive).
Other timezone names are parsed **but ignored**:

    # GMT/UTC recognized and handled
    my $t1 = Time::Piece->strptime("2024-01-15 10:30:00 GMT",
                                   "%Y-%m-%d %H:%M:%S %Z");
    print $t1->hour;  # prints 10 (no adjustment)

    # Other timezones parsed but ignored
    my $t2 = Time::Piece->strptime("2024-01-15 10:30:00 PST",
                                   "%Y-%m-%d %H:%M:%S %Z");
    print $t2->hour;  # prints 10 (PST ignored - no adjustment)

    # Parse and convert to local timezone
    my $t3 = Time::Piece->strptime("2024-01-15 15:30:00 UTC",
                                  "%Y-%m-%d %H:%M:%S %Z",
                                  { islocal => 1 });
    print $t3->hour;  # prints 10:30 UTC converted to your local timezone

**Note:** Full timezone name support is not currently implemented. For reliable
timezone handling beyond GMT/UTC, consider using the [DateTime](https://metacpan.org/pod/DateTime) module.

## Handling Partial Dates

When parsing incomplete date strings, you can provide defaults for missing
components in several ways:

**Array Reference** - Standard time components (as returned by localtime):

    my @defaults = localtime();
    my $t = Time::Piece->strptime("15 Mar", "%d %b",
                                  { defaults => \@defaults });

**Hash Reference** - Specify only needed components:

    my $t = Time::Piece->strptime("15 Mar", "%d %b",
                                  { defaults => {
                                      year => 2023,
                                      hour => 14,
                                      min  => 30
                                  } });

Valid keys: `sec`, `min`, `hour`, `mday`, `mon`, `year`, `wday`, `yday`, `isdst`

**Note**: For the `year` parameter numbers less than 1000 are treated as an
offset from 1900. Whereas numbers larger than 1000 are treated as the actual year.

**Time::Piece Object** - Uses all components from the object:

    my $base = localtime();
    my $t = Time::Piece->strptime("15 Mar", "%d %b",
                                  { defaults => $base });

**Note:** In all cases, parsed values always override defaults. Only missing
components use default values.

## Locale Considerations

By default, `strptime` only parses English day and month names, while
`strftime` uses your system locale. This can cause parsing failures for
non-English dates.

To parse localized dates, call `Time::Piece->use_locale()` to build
a list of your locale's day and month names:

    # Enable locale-aware parsing (global setting)
    Time::Piece->use_locale();

    # Now strptime can parse names in your system locale
    my $t = Time::Piece->strptime("15 Marzo 2024", "%d %B %Y");

**Note:** This is a global change affecting all Time::Piece instances.

You can also override the day/month names manually:

    # Abbreviated day names
    my @days = qw( Dom Lun Mar Mie Jue Vie Sab );
    my $spanish_day = localtime->day(@days);

    # Full day names
    my @fulldays = qw( Domingo Lunes Martes Miercoles Jueves Viernes Sabado );
    my $spanish_fullday = localtime->fullday(@fulldays);

    # Abbreviated month names
    my @months = qw( Ene Feb Mar Abr May Jun Jul Ago Sep Oct Nov Dic );
    print localtime->month(@months);

    # Full month names
    my @fullmonths = qw( Enero Febrero Marzo Abril Mayo Junio
                         Julio Agosto Septiembre Octubre Noviembre Diciembre );
    print localtime->fullmonth(@fullmonths);

Set globally with:

    Time::Piece::day_list(@days);
    Time::Piece::mon_list(@months);
    Time::Piece::fullday_list(@fulldays);
    Time::Piece::fullmon_list(@fullmonths);

# Global Overriding

To override localtime and gmtime everywhere:

    use Time::Piece ':override';

This replaces Perl's built-in functions with Time::Piece versions globally.

# CAVEATS

## Setting $ENV{TZ} in Threads on Win32

Note that when using perl in the default build configuration on Win32
(specifically, when perl is built with PERL\_IMPLICIT\_SYS), each perl
interpreter maintains its own copy of the environment and only the main
interpreter will update the process environment seen by strftime.

Therefore, if you make changes to $ENV{TZ} from inside a thread other than
the main thread then those changes will not be seen by `strftime` if you
subsequently call that with the %Z formatting code. You must change $ENV{TZ}
in the main thread to have the desired effect in this case (and you must
also call `_tzset()` in the main thread to register the environment change).

Furthermore, remember that this caveat also applies to fork(), which is
emulated by threads on Win32.

## Use of epoch seconds

This module internally uses the epoch seconds system that is provided via
the perl `time()` function and supported by `gmtime()` and `localtime()`.

If your perl does not support times larger than `2^31` seconds
(Perl versions < 5.12) then this module is likely to fail at processing dates
beyond the year 2038. If that is not an option, use the [DateTime](https://metacpan.org/pod/DateTime) module
which has support for years well into the future and past.

# AUTHOR

Matt Sergeant, matt@sergeant.org
Jarkko Hietaniemi, jhi@iki.fi (while creating Time::Piece for core perl)

# COPYRIGHT AND LICENSE

Copyright 2001, Larry Wall.

This module is free software, you may distribute it under the same terms
as Perl.

# SEE ALSO

The excellent Calendar FAQ at [http://www.tondering.dk/claus/calendar.html](http://www.tondering.dk/claus/calendar.html)

# BUGS

- The test harness leaves much to be desired. Patches welcome.
- Proper UTF8 support

## Development Instructions

The module uses GitHub Actions for continuous integration testing across multiple platforms.

### Using Feature Branches

For development and testing:

1. **Setup Git Hooks**:
   ```bash
   ./setup-hooks.sh
   ```

2. **Create a feature branch**:
   ```bash
   git checkout -b feature/windows-fix
   ```
   
   You can create any descriptive name after the `feature/` prefix:
   ```bash
   git checkout -b feature/memory-optimization
   git checkout -b feature/strawberry-perl-compatibility
   ```

3. **Make your changes and commit them**:
   ```bash
   # Make changes to your code
   git add .
   git commit -m "Implement Windows-specific fixes"
   ```

4. **Push to GitHub to trigger automatic tests**:
   ```bash
   git push origin feature/windows-fix
   ```

5. **Delete once merge done**:
   ```bash
   # Delete locally
   git branch -D feature/windows-fix
   
   # Delete from GitHub
   git push origin --delete feature/windows-fix
   ```

## Installation

From CPAN:

```
cpan Time::Piece
```

From source:

```
perl Makefile.PL
make
make test
make install
```