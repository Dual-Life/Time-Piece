# Large tests - test dates outside of the epoch range
use Test;
BEGIN { plan tests => 250 }
use Time::Piece;
use DateTime::Duration;

my $t = gmtime;

my $base_year = $t->year;
my $one_year = DateTime::Duration->new(years => 1);

for (1..50) {
  $t = $t + $one_year;
  print "# $t\n";
  ok($t->year, $base_year + $_);
}

$t = gmtime;
$base_year = $t->year; # just in case it changed <g>


for (1..200) {
  $t = $t - $one_year;
  print "# $t\n";
  ok($t->year, $base_year - $_);
}
