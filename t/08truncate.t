use strict;
use warnings;
use Test::More tests => 24;

# Test::Trap required to test exceptions
my $have_test_trap;
our $trap; # Imported
BEGIN {
    eval {
        require Test::Trap;
        Test::Trap->import (qw/trap $trap :flow
        :stderr(systemsafe)
        :stdout(systemsafe)
        :warn/);
        $have_test_trap = 1;
    };
}

use Time::Piece;

my $epoch = 1373371631;
my $t = gmtime($epoch); # 2013-07-09T12:07:11

is ($t->truncate,        $t, 'No args, same object');
is ($t->truncate('foo'), $t, 'No "to" arg, same object');
SKIP: {
    skip "Test::Trap not available", 2 unless $have_test_trap;
    my @r = trap { $t->truncate('to') };
    like ($trap->die,
        qr/Invalid value of 'to' parameter/,
        'No "to" value croaks');
    @r = trap { $t->truncate('to' => 'foo') };
    like ($trap->die,
        qr/Invalid value of 'to' parameter: foo/,
        'Unrecognised "to" value croaks');
}

my $short = $t->truncate(to => 'second');
my $exp   = $epoch;
cmp_ok ($short->epoch, '==', $exp, 'Truncate to second');

$short = $t->truncate(to => 'minute');
$exp   -= 11;
cmp_ok ($short->epoch, '==', $exp, 'Truncate to minute');

$short = $t->truncate(to => 'hour');
$exp   -= 420;
cmp_ok ($short->epoch, '==', $exp, 'Truncate to hour');

$short = $t->truncate(to => 'day');
$exp   -= 43200;
cmp_ok ($short->epoch, '==', $exp, 'Truncate to day');

$short = $t->truncate(to => 'month');
$exp   -= 8 * 86400;
cmp_ok ($short->epoch, '==', $exp, 'Truncate to month');

$exp = gmtime ($exp)->add_months(-6);
$short = $t->truncate(to => 'year');
cmp_ok ($short, '==', $exp, 'Truncate to year');

is ($t->epoch, $epoch, 'Time unchanged');

for my $addmon (0..12) {
    my $quarter = $short->add_months ($addmon);
    $exp   = $quarter->add_months (0 - ($addmon % 3));
    $quarter = $quarter->truncate(to => 'quarter');
    cmp_ok ($quarter, '==', $exp, "Truncate to quarter (month $addmon)");

}
