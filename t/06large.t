use Test::More;
use Time::Piece;
use Time::Seconds;

# Large tests - test dates outside of the epoch range,
# somewhat silly, but lets see what happens

# Won't run without time64 support (perl > 5.10) on windows
my $is_win32 = ( $^O =~ /Win32/ );

plan skip_all => "Large time tests not required for installation"
  unless ( $ENV{AUTOMATED_TESTING} && !( $is_win32 && $] < 5.012 ) );

my $t = gmtime;

my $base_year = $t->year;
my $one_year  = ONE_YEAR;

for ( 1 .. 50 ) {
    $t = $t + $one_year;
    cmp_ok(
        $t->year, '==',
        $base_year + $_,
        "Year is: " . ( $base_year + $_ )
    );
}

$t         = gmtime;
$base_year = $t->year;

for ( 1 .. 200 ) {
    $t = $t - $one_year;
    cmp_ok(
        $t->year, '==',
        $base_year - $_,
        "Year is: " . ( $base_year - $_ )
    );
}

done_testing(250);
