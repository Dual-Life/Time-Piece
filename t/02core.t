use Test;
BEGIN { plan tests => 91 }
my $is_win32 = ($^O =~ /Win32/);
use Time::Piece;
ok(1);

my $t = gmtime(951827696); # 2000-02-29T12:34:56

ok($t->sec, 56);
ok($t->second, 56);
ok($t->min, 34);
ok($t->minute, 34);
ok($t->hour, 12);
ok($t->mday, 29);
ok($t->day_of_month, 29);
ok($t->mon, 2);
ok($t->_mon, 1);
ok($t->monname, 'Feb');
ok($t->month, 'Feb');
ok($t->fullmonth, 'February');
ok($t->year, 2000);
ok($t->_year, 100);
ok($t->yy, '00');
ok($t->wday == 3);
ok($t->_wday == 2);
ok($t->day_of_week == 2);
ok($t->wdayname eq 'Tue');
ok($t->day eq 'Tue');
ok($t->fullday eq 'Tuesday');
ok($t->yday == 59);
ok($t->day_of_year == 59);

# In GMT there should be no daylight savings ever.
ok($t->isdst == 0);
ok($t->daylight_savings == 0);
ok($t->hms eq '12:34:56');
ok($t->time eq '12:34:56');
ok($t->ymd eq '2000-02-29');
ok($t->date eq '2000-02-29');
ok($t->mdy eq '02-29-2000');
ok($t->dmy eq '29-02-2000');
ok($t->cdate eq 'Tue Feb 29 12:34:56 2000');
ok("$t" eq 'Tue Feb 29 12:34:56 2000');
ok($t->datetime eq '2000-02-29T12:34:56');
ok($t->epoch == 951827696);

# ->tzoffset?
ok(($t->julian_day / 2451604.0243) - 1 < 0.001);
ok(($t->mjd        /   51603.52426) - 1 < 0.001);
ok($t->week == 9);

# strftime tests

# %a, %A, %b, %B, %c are locale-dependent

# %C is unportable: sometimes its like asctime(3) or date(1),
# sometimes it's the century (and whether for 2000 the century is
# 20 or 19, is fun, too..as far as I can read SUSv2 it should be 20.)
ok($t->strftime('%d') == 29);
skip($is_win32, $t->strftime('%D') eq '02/29/00'); # Yech!
skip($is_win32, $t->strftime('%e') eq '29'); # should test with < 10
ok($t->strftime('%H') eq '12'); # should test with < 10

 # %h is locale-dependent

ok($t->strftime('%I') eq '12'); # should test with < 10
ok($t->strftime('%j') == 60); # why ->yday+1 ?
ok($t->strftime('%M') eq '34'); # should test with < 10

# %p, %P, and %r are not widely implemented,
# and are possibly unportable (am or AM or a.m., and so on)

skip($is_win32, $t->strftime('%R') eq '12:34'); # should test with > 12
ok($t->strftime('%S') eq '56'); # should test with < 10
skip($is_win32, $t->strftime('%T') eq '12:34:56'); # < 12 and > 12

# There are bugs in the implementation of %u in many platforms.
# (e.g. Linux seems to think, despite the man page, that %u
# 1-based on Sunday...)

ok($t->strftime('%U') eq '09'); # Sun cmp Mon
# BROKEN ON OSX: ok($t->strftime('%V') eq '09'); # Sun cmp Mon
ok($t->strftime('%w') == 2);
ok($t->strftime('%W') eq '09'); # Sun cmp Mon

# %x is locale and implementation dependent.

ok($t->strftime('%y') == 0); # should test with 1999
ok($t->strftime('%Y') eq '2000');

# %Z is locale and implementation dependent
# (there is NO standard for timezone names)
ok($t->date("") eq '20000229');
ok($t->ymd("") eq '20000229');
ok($t->mdy("/") eq '02/29/2000');
ok($t->dmy(".") eq '29.02.2000');
ok($t->date_separator() eq '-');

$t->date_separator("/");
ok($t->ymd eq '2000/02/29');
ok($t->date_separator() eq '/');

$t->date_separator("-");
ok($t->hms(".") eq '12.34.56');
ok($t->time_separator() eq ':');

$t->time_separator(".");
ok($t->hms eq '12.34.56');
ok($t->time_separator() eq '.');

$t->time_separator(":");

my @fidays = qw( sunnuntai maanantai tiistai keskiviikko torstai
                 perjantai lauantai );
my @frdays = qw( Dimanche Lundi Merdi Mercredi Jeudi Vendredi Samedi );

ok($t->day(@fidays) eq "tiistai");
my @days = $t->day_list();

$t->day_list(@frdays);

ok($t->day eq "Merdi");

$t->day_list(@days);

ok($t->day eq "Tue");

my @months = $t->mon_list();

my @dumonths = qw(januari februari maart april mei juni
                  juli augustus september oktober november december);

ok($t->month(@dumonths) eq "februari");

$t->mon_list(@dumonths);

ok($t->month eq "februari");

$t->mon_list(@months);

ok($t->month eq "Feb");

ok($t->datetime(date => '/', T => ' ', time => '-') eq "2000/02/29 12-34-56");

ok($t->is_leap_year); # should test more with different dates

ok($t->month_last_day == 29); # test more

ok(!Time::Piece::_is_leap_year(1900));

ok(!Time::Piece::_is_leap_year(1901));

ok(Time::Piece::_is_leap_year(1904));

ok(Time::Piece->strptime("1945", "%Y")->year, 1945, "Year is 1945?");

ok(Time::Piece->strptime("13:00", "%H:%M")->hour, 13, "Hour is 13?");

# Test week number
# [from Ilya Martynov]
ok(Time::Piece->strptime("2002/06/10 0", '%Y/%m/%d %H')->week,24);
ok(Time::Piece->strptime("2002/06/10 1", '%Y/%m/%d %H')->week,24);
ok(Time::Piece->strptime("2002/06/10 2", '%Y/%m/%d %H')->week,24);
ok(Time::Piece->strptime("2002/06/10 12", '%Y/%m/%d %H')->week,24);
ok(Time::Piece->strptime("2002/06/10 13", '%Y/%m/%d %H')->week,24);
ok(Time::Piece->strptime("2002/06/10 14", '%Y/%m/%d %H')->week,24);
ok(Time::Piece->strptime("2002/06/10 23", '%Y/%m/%d %H')->week,24);

# Test that strptime populates all relevant fields
ok(Time::Piece->strptime("2002/07/10", '%Y/%m/%d')->wday,4);
ok(Time::Piece->strptime("2002/07/10", '%Y/%m/%d')->day_of_week,3);
ok(Time::Piece->strptime("2002/12/31", '%Y/%m/%d')->yday,364);
ok(Time::Piece->strptime("2002/07/10", '%Y/%m/%d')->isdst,0);
ok(Time::Piece->strptime("2000/02/29 12:34:56", '%Y/%m/%d %H:%M:%S')->epoch,951827696);
