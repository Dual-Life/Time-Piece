# $Id: Seconds.pm,v 1.12 2003/02/10 09:06:00 matt Exp $

package Time::Seconds;
use strict;
use vars qw/@EXPORT @EXPORT_OK @ISA/;
use DateTime::Duration;

@ISA = ('Exporter', 'DateTime::Duration');

@EXPORT = qw(
		ONE_MINUTE 
		ONE_HOUR 
		ONE_DAY 
		ONE_WEEK 
		ONE_MONTH
                ONE_REAL_MONTH
		ONE_YEAR
                ONE_REAL_YEAR
		ONE_FINANCIAL_MONTH
		LEAP_YEAR 
		NON_LEAP_YEAR
		);

@EXPORT_OK = qw(cs_sec cs_mon);

use constant ONE_MINUTE => 60;
use constant ONE_HOUR => 3_600;
use constant ONE_DAY => 86_400;
use constant ONE_WEEK => 604_800;
use constant ONE_MONTH => 2_629_744; # ONE_YEAR / 12
use constant ONE_REAL_MONTH => '1M';
use constant ONE_YEAR => 31_556_930; # 365.24225 days
use constant ONE_REAL_YEAR  => '1Y';
use constant ONE_FINANCIAL_MONTH => 2_592_000; # 30 days
use constant LEAP_YEAR => 31_622_400; # 366 * ONE_DAY
use constant NON_LEAP_YEAR => 31_536_000; # 365 * ONE_DAY

# hacks to make Time::Piece compile once again
use constant cs_sec => 0;
use constant cs_mon => 1;

sub financial_months {
    my $s = shift;
    $s->days / 30;
}

sub new {
    my $class = shift;
    if (@_ == 1) {
        return $class->SUPER::new(seconds => $_[0]);
    }
    return $class->SUPER::new(@_);
}

1;
__END__

=head1 NAME

Time::Seconds - a simple API to convert seconds to other date values

=head1 SYNOPSIS

    use Time::Piece;
    use Time::Seconds;
    
    my $t = localtime;
    $t += ONE_DAY;
    
    my $t2 = localtime;
    my $s = $t - $t2;
    
    print "Difference is: ", $s->days, "\n";

=head1 DESCRIPTION

This module is part of the Time::Piece distribution. It allows the user
to find out the number of minutes, hours, days, weeks or years in a given
number of seconds. It is returned by Time::Piece when you delta two
Time::Piece objects.

Time::Seconds also exports the following constants:

    ONE_DAY
    ONE_WEEK
    ONE_HOUR
    ONE_MINUTE
	ONE_MONTH
	ONE_YEAR
	ONE_FINANCIAL_MONTH
    LEAP_YEAR
    NON_LEAP_YEAR

Since perl does not (yet?) support constant objects, these constants are in
seconds only, so you cannot, for example, do this: C<print ONE_WEEK-E<gt>minutes;>

=head1 METHODS

The following methods are available:

    my $val = Time::Seconds->new(SECONDS)
    $val->seconds;
    $val->minutes;
    $val->hours;
    $val->days;
    $val->weeks;
	$val->months;
	$val->financial_months; # 30 days
    $val->years;

The methods make the assumption that there are 24 hours in a day, 7 days in
a week, 365.24225 days in a year and 12 months in a year.
(from The Calendar FAQ at http://www.tondering.dk/claus/calendar.html)

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

Tobias Brox, tobiasb@tobiasb.funcom.com

Bal�zs Szab� (dLux), dlux@kapu.hu

=head1 LICENSE

Please see Time::Piece for the license.

=head1 Bugs

Currently the methods aren't as efficient as they could be, for reasons of
clarity. This is probably a bad idea.

=cut
