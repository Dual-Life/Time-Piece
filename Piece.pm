# $Id: Piece.pm,v 1.19 2003/02/10 17:43:24 matt Exp $

package Time::Piece;

use strict;
use vars qw($VERSION @ISA @EXPORT %EXPORT_TAGS);

require Exporter;
require DynaLoader;
use Time::Seconds;
use Carp;
use Time::Local;
use UNIVERSAL qw(isa);
use DateTime;

@ISA = qw(Exporter DynaLoader DateTime);

@EXPORT = qw(
    localtime
    gmtime
);

%EXPORT_TAGS = (
    ':override' => 'internal',
    );

$VERSION = '2.00_00';

bootstrap Time::Piece $VERSION;

my $DATE_SEP = '-';
my $TIME_SEP = ':';
my @MON_LIST = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @FULLMON_LIST = qw(January February March April May June July
                      August September October November December);
my @DAY_LIST = qw(Sun Mon Tue Wed Thu Fri Sat);
my @FULLDAY_LIST = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);

sub localtime {
    my $time = shift || time;
    __PACKAGE__->from_epoch(epoch => $time);
}

sub gmtime {
    my $time = shift || time;
    my $ret = __PACKAGE__->from_epoch(epoch => $time);
    $ret->set_time_zone(0);
    return $ret;
}

sub parse {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my @components;
    if (@_ > 1) {
        @components = @_;
    }
    else {
        @components = shift =~ /(\d+)$DATE_SEP(\d+)$DATE_SEP(\d+)(?:(?:T|\s+)(\d+)$TIME_SEP(\d+)(?:$TIME_SEP(\d+)))/;
        @components = reverse(@components[0..5]);
    }
    return $class->new(epoch => _strftime("%s", @components));
}

sub import {
    # replace CORE::GLOBAL localtime and gmtime if required
    my $class = shift;
    my %params;
    map($params{$_}++,@_,@EXPORT);
    if (delete $params{':override'}) {
        $class->export('CORE::GLOBAL', keys %params);
    }
    else {
        $class->export((caller)[0], keys %params);
    }
}

## Methods ##

sub _mon {
    shift->mon_0;
}

sub month {
    my $time = shift;
    if (@_) {
        return $_[$time->mon_0];
    }
    elsif (@MON_LIST) {
        return $MON_LIST[$time->mon_0];
    }
    else {
        return $time->strftime('%b');
    }
}

*monname = \&month;

sub fullmonth {
    my $time = shift;
    if (@_) {
        return $_[$time->mon_0];
    }
    elsif (@FULLMON_LIST) {
        return $FULLMON_LIST[$time->mon_0];
    }
    else {
        return $time->strftime('%B');
    }
}

sub _year {
    shift->year - 1900;
}

sub yy {
    my $time = shift;
    my $res = $time->year % 100;
    return $res > 9 ? $res : "0$res";
}

# DateTime starts week on a Monday
sub wday {
    shift->SUPER::wday + 1;
}

sub _wday {
    shift->SUPER::wday;
}

*day_of_week = \&_wday;

sub wdayname {
    my $time = shift;
    if (@_) {
        return $_[$time->_wday];
    }
    elsif (@DAY_LIST) {
        return $DAY_LIST[$time->_wday];
    }
    else {
        return $time->strftime('%a');
    }
}

*day = \&wdayname;

sub fullday {
    my $time = shift;
    if (@_) {
        return $_[$time->_wday];
    }
    elsif (@FULLDAY_LIST) {
        return $FULLDAY_LIST[$time->_wday];
    }
    else {
        return $time->strftime('%A');
    }
}

sub yday {
    shift->doy - 1;
}

*day_of_year = \&yday;

sub isdst {
    my $t = shift;
    return 0 if $t->time_zone->is_utc;
    return $t->is_dst;
}

*daylight_savings = \&isdst;

# Thanks to Tony Olekshy <olekshy@cs.ualberta.ca> for this algorithm
sub tzoffset {
    my $time = shift;
    return Time::Seconds->new(seconds => $time->offset());
}

sub _is_leap_year {
    my $year = shift;
    my $time = DateTime->new(year => $year);
    return $time->is_leap_year;
}

# Julian Day is always calculated for UT regardless
# of local time
sub julian_day {
    my $time = shift;
    # Correct for localtime
    $time = &gmtime( $time->epoch ) if $time->offset != 0;
    
    # Calculate the Julian day itself
    my $jd = $time->_jd( $time->year, $time->mon, $time->mday,
                        $time->hour, $time->min, $time->sec);
    
    return $jd;
}

# MJD is defined as JD - 2400000.5 days
sub mjd {
    return shift->julian_day - 2_400_000.5;
}

# Internal calculation of Julian date. Needed here so that
# both tzoffset and mjd/jd methods can share the code
# Algorithm from Hatcher 1984 (QJRAS 25, 53-55), and
#  Hughes et al, 1989, MNRAS, 238, 15
# See: http://adsabs.harvard.edu/cgi-bin/nph-bib_query?bibcode=1989MNRAS.238.1529H&db_key=AST
# for more details

sub _jd {
    my $self = shift;
    my ($y, $m, $d, $h, $n, $s) = @_;

    # Adjust input parameters according to the month
    $y = ( $m > 2 ? $y : $y - 1);
    $m = ( $m > 2 ? $m - 3 : $m + 9);

    # Calculate the Julian Date (assuming Julian calendar)
    my $J = int( 365.25 *( $y + 4712) )
      + int( (30.6 * $m) + 0.5)
        + 59
          + $d
            - 0.5;

    # Calculate the Gregorian Correction (since we have Gregorian dates)
    my $G = 38 - int( 0.75 * int(49+($y/100)));

    # Calculate the actual Julian Date
    my $JD = $J + $G;

    # Modify to include hours/mins/secs in floating portion.
    return $JD + ($h + ($n + $s / 60) / 60) / 24;
}

sub week {
    my $self = shift;

    my $J  = $self->julian_day;
    # Julian day is independent of time zone so add on tzoffset
    # if we are using local time here since we want the week day
    # to reflect the local time rather than UTC
    $J += ($self->offset/(24*3600)) if $self->offset != 0;
    
    # Now that we have the Julian day including fractions
    # convert it to an integer Julian Day Number using nearest
    # int (since the day changes at midday we oconvert all Julian
    # dates to following midnight).
    $J = int($J+0.5);
    
    use integer;
    my $d4 = ((($J + 31741 - ($J % 7)) % 146097) % 36524) % 1461;
    my $L  = $d4 / 1460;
    my $d1 = (($d4 - $L) % 365) + $L;
    return $d1 / 7 + 1;
}

my @MON_LAST = qw(31 28 31 30 31 30 31 31 30 31 30 31);

sub month_last_day {
    my $time = shift;
    my $_mon = $time->mon_0;
    return $MON_LAST[$_mon] + ($_mon == 1 ? $time->is_leap_year : 0);
}

sub strftime {
    my $t = shift;
    my $fmt = @_ ? shift(@_) : "%a, %d %b %Y %H:%M:%S %Z";
    if ($fmt =~ /\%[DIUWjes]/) {
        return _strftime($fmt, $t->sec, $t->min, $t->hour, $t->mday, $t->_mon, $t->_year);
    }
    return $t->SUPER::strftime($fmt, @_);
}

sub strptime {
    my $time = shift;
    my $string = shift;
    my $format = @_ ? shift(@_) : "%a, %d %b %Y %H:%M:%S %Z";
    my @vals = _strptime($string, $format);
    # warn(sprintf("got vals: L:%d E:%d I:%d YD:%d WD:%d %d-%d-%d %d:%d:%d\n", reverse(@vals)));
    my $class = ref($time) || $time;
    return $class->new(
        second => $vals[0],
        minute => $vals[1],
        hour => $vals[2],
        day => $vals[3],
        month => $vals[4] + 1,
        year => $vals[5] + 1900,
        time_zone => (ref($time) ? $time->time_zone : 0),
        );
}

sub day_list {
    shift if ref($_[0]) && $_[0]->isa(__PACKAGE__); # strip first if called as a method
    my @old = @DAY_LIST;
    if (@_) {
        @DAY_LIST = @_;
    }
    return @old;
}

sub mon_list {
    shift if ref($_[0]) && $_[0]->isa(__PACKAGE__); # strip first if called as a method
    my @old = @MON_LIST;
    if (@_) {
        @MON_LIST = @_;
    }
    return @old;
}

sub time_separator {
    shift if ref($_[0]) && $_[0]->isa(__PACKAGE__);
    my $old = $TIME_SEP;
    if (@_) {
        $TIME_SEP = $_[0];
    }
    return $old;
}

sub date_separator {
    shift if ref($_[0]) && $_[0]->isa(__PACKAGE__);
    my $old = $DATE_SEP;
    if (@_) {
        $DATE_SEP = $_[0];
    }
    return $old;
}

sub ymd {
    my $t = shift;
    my $sep = @_ ? $_[0] : $DATE_SEP;
    $t->SUPER::ymd($sep);
}

sub mdy {
    my $t = shift;
    my $sep = @_ ? $_[0] : $DATE_SEP;
    $t->SUPER::mdy($sep);
}

sub dmy {
    my $t = shift;
    my $sep = @_ ? $_[0] : $DATE_SEP;
    $t->SUPER::dmy($sep);
}

sub hms {
    my $t = shift;
    my $sep = @_ ? $_[0] : $TIME_SEP;
    $t->SUPER::hms($sep);
}

sub datetime {
    my $t = shift;
    my $dsep = $DATE_SEP;
    my $tsep = $TIME_SEP;
    my $sep = 'T';
    if (@_) {
        my %args = @_;
        $dsep = $args{'date'} if exists $args{'date'};
        $tsep = $args{'time'} if exists $args{'time'};
        $sep = $args{'T'} if exists $args{'T'};
    }
    return $t->ymd($dsep) . $sep . $t->hms($tsep);
}

use overload '""' => \&cdate,
             'cmp' => \&str_compare,
             'fallback' => undef;

sub epoch {
    shift->strftime("%s");
}
             
sub cdate {
    my $time = shift;
    # Mon Feb 10 17:19:35 2003
    return $time->strftime('%a %b %d %H:%M:%S %Y');
}

sub str_compare {
    my ($lhs, $rhs, $reverse) = @_;
    if (UNIVERSAL::isa($rhs, 'DateTime')) {
        $rhs = "$rhs";
    }
    return $reverse ? $rhs cmp $lhs->cdate : $lhs->cdate cmp $rhs;
}

1;
__END__

=head1 NAME

Time::Piece - Object Oriented time objects

=head1 SYNOPSIS

    use Time::Piece;
    
    my $t = localtime;
    print "Time is $t\n";
    print "Year is ", $t->year, "\n";

=head1 DESCRIPTION

This module replaces the standard localtime and gmtime functions with
implementations that return objects. It does so in a backwards
compatible manner, so that using localtime/gmtime in the way documented
in perlfunc will still return what you expect. Not only that but
by using DateTime as a base class, Time::Piece supports dates outside
of the epoch range (though not by using 64 bit epoch times).

The module actually implements most of an interface described by
Larry Wall on the perl5-porters mailing list here:
http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/2000-01/msg00241.html

=head1 USAGE

After importing this module, when you use localtime or gmtime in a scalar
context, rather than getting an ordinary scalar string representing the
date and time, you get a Time::Piece object, whose stringification happens
to produce the same effect as the localtime and gmtime functions. There is 
also a new() constructor provided, which is the same as localtime(), except
when passed a Time::Piece object, in which case it's a copy constructor. The
following methods are available on the object:

    $t->sec                 # also available as $t->second
    $t->min                 # also available as $t->minute
    $t->hour                # 24 hour
    $t->mday                # also available as $t->day_of_month
    $t->mon                 # 1 = January
    $t->_mon                # 0 = January
    $t->monname             # Feb
    $t->month               # same as $t->monname
    $t->fullmonth           # February
    $t->year                # based at 0 (year 0 AD is, of course 1 BC)
    $t->_year               # year minus 1900
    $t->yy                  # 2 digit year
    $t->wday                # 1 = Sunday
    $t->_wday               # 0 = Sunday
    $t->day_of_week         # 0 = Sunday
    $t->wdayname            # Tue
    $t->day                 # same as wdayname
    $t->fullday             # Tuesday
    $t->yday                # also available as $t->day_of_year, 0 = Jan 01
    $t->isdst               # also available as $t->daylight_savings

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

    $t->epoch               # seconds since the epoch
    $t->tzoffset            # timezone offset in a Time::Seconds object

    $t->julian_day          # number of days since Julian period began
    $t->mjd                 # modified Julian date (JD-2400000.5 days)

    $t->week                # week number (ISO 8601)

    $t->is_leap_year        # true if it its
    $t->month_last_day      # 28-31

    $t->time_separator($s)  # set the default separator (default ":")
    $t->date_separator($s)  # set the default separator (default "-")
    $t->day_list(@days)     # set the default weekdays
    $t->mon_list(@days)     # set the default months

    $t->strftime(FORMAT)    # same as POSIX::strftime (without the overhead
                            # of the full POSIX extension)
    $t->strftime()          # "Tue, 29 Feb 2000 12:34:56 GMT"
    
    Time::Piece->strptime(STRING, FORMAT)
                            # see strptime man page. Creates a new
                            # Time::Piece object

=head2 Local Locales

Both wdayname (day) and monname (month) allow passing in a list to use
to index the name of the days against. This can be useful if you need
to implement some form of localisation without actually installing or
using locales.

  my @days = qw( Dimanche Lundi Merdi Mercredi Jeudi Vendredi Samedi );

  my $french_day = localtime->day(@days);

These settings can be overriden globally too:

  Time::Piece::day_list(@days);

Or for months:

  Time::Piece::mon_list(@months);

And locally for months:

  print localtime->month(@months);

=head2 Date Calculations

It's possible to use simple addition and subtraction of objects:

    use Time::Seconds;
    
    my $seconds = $t1 - $t2;
    $t1 += ONE_DAY; # add 1 day (constant from Time::Seconds)

The following are valid ($t1 and $t2 are Time::Piece objects):

    $t1 - $t2; # returns Time::Seconds object
    $t1 - 42; # returns Time::Piece object
    $t1 + 533; # returns Time::Piece object

However adding a Time::Piece object to another Time::Piece object
will cause a runtime error.

Note that the first of the above returns a Time::Seconds object, so
while examining the object will print the number of seconds (because
of the overloading), you can also get the number of minutes, hours,
days, weeks and years in that delta, using the Time::Seconds API.

=head2 Date Comparisons

Date comparisons are also possible, using the full suite of "<", ">",
"<=", ">=", "<=>", "==" and "!=".

=head2 Date Parsing

Time::Piece links to your C library's strptime() function, allowing
you incredibly flexible date parsing routines. For example:

  my $t = Time::Piece->strptime("Sun 3rd Nov, 1943",
                                "%A %drd %b, %Y");
  
  print $t->strftime("%a, %d %b %Y");

Outputs:

  Wed, 03 Nov 1943

(see, it's even smart enough to fix my obvious date bug)

For more information see "man strptime", which should be on all unix
systems.

=head2 YYYY-MM-DDThh:mm:ss

The ISO 8601 standard defines the date format to be YYYY-MM-DD, and
the time format to be hh:mm:ss (24 hour clock), and if combined, they
should be concatenated with date first and with a capital 'T' in front
of the time.

=head2 Week Number

The I<week number> may be an unknown concept to some readers.  The ISO
8601 standard defines that weeks begin on a Monday and week 1 of the
year is the week that includes both January 4th and the first Thursday
of the year.  In other words, if the first Monday of January is the
2nd, 3rd, or 4th, the preceding days of the January are part of the
last week of the preceding year.  Week numbers range from 1 to 53.

=head2 Global Overriding

Finally, it's possible to override localtime and gmtime everywhere, by
including the ':override' tag in the import list:

    use Time::Piece ':override';

=head2 Early/Late Dates

Version 2.00 of Time::Piece supports early and late dates (before and
after the epoch under/over flow dates). However this does not mean
you can do C<localtime($bigint)> to get at those dates - as
internally that code still goes through the C library's localtime()
function. Instead to get to a large date you must add or remove
years. See F<t/06large.t> in the test suite for an example. This
code is likely to be expanded on greatly in the near future.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org
Jarkko Hietaniemi, jhi@iki.fi (while creating Time::Piece for core perl)

=head1 License

This module is free software, you may distribute it under the same terms
as Perl.

=head1 SEE ALSO

The excellent Calendar FAQ at http://www.tondering.dk/claus/calendar.html

=head1 BUGS

The test harness leaves much to be desired. Patches welcome.

=cut
