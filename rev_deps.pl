use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use Data::Dumper;
use Time::Piece;    #of course
use MetaCPAN::Client;

#search cpan for any module that mentions "Time::Piece"

my $i           = 1;
my @total_dists = ();
my @skipped     = ();
my $too_old     = localtime->strptime( "2011-01-01", "%Y-%m-%d" );
my $meta        = MetaCPAN::Client->new();


while (
    my $response = HTTP::Tiny->new->get(
        "https://grep.metacpan.org/api/search?p=$i&q=Time%3A%3APiece&qls=on")
  )
{
    ++$i;
    die "Failed!\n" unless $response->{success};

    my $j;

    if ( length $response->{content} ) {
        $j = from_json( $response->{content} );

    }

    unless ( @{ $j->{results} } > 1 ) {
        warn "no results from:\n" . Dumper $j;
        last;
    }

    print "Got " . scalar @{ $j->{results} } . "\n";

    foreach my $raw_dist ( @{ $j->{results} } ) {
        my $dist_date;
        my $release;
        eval {
          $dist_date = localtime->strptime( $meta->release( $raw_dist->{distro} )->date(),
            "%Y-%m-%dT%H:%M:%S" );
        };

        if($@){
            push( @skipped, "$raw_dist->{distro} -" . (split(/\n/, $@))[0] );
            next;
        }

        #skip bundled stuff
        if ( $raw_dist->{distro} =~ /task|belike/i ) {
            push( @skipped, $raw_dist->{distro} );
            next;
        }
        #or too old
        if ( $dist_date < $too_old ) {
            push( @skipped, "$raw_dist->{distro} - $dist_date" );
            next;
        }

        $raw_dist->{distro} =~ s/-/::/g;
        push( @total_dists, $raw_dist->{distro} );
    }
    print "total_dists size is now: " . scalar @total_dists . "\n";
    print "Fetching page #$i\n";
}

print "\n\nSkipped dists:\n\n";
foreach my $dist (@skipped) {
    print "$dist\n";
}

print "\n\nDep dists:\n\n";
foreach my $dist (@total_dists) {
    print "$dist\n";
}
