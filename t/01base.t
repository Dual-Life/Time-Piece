use Test;
BEGIN { plan tests => 4 }
use Time::Piece;
ok(1);

my $t = gmtime(315532800); # 00:00:00 1/1/1980

ok($t->year == 1980);

ok($t->hour, 0);

ok($t->mon, 1);

