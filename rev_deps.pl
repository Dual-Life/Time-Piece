use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use Data::Dumper;
use Time::Piece;    #of course
use MetaCPAN::Client;

#search cpan for any module that mentions "Time::Piece"
$|=1;
my $i           = 1;
my @total_dists = ();
my @skipped     = ();
my $too_old     = localtime->strptime( "2011-01-01", "%Y-%m-%d" );
my $meta        = MetaCPAN::Client->new();

HTTP::Tiny->new->get("https://grep.metacpan.org/api/search?size=20&q=Time::Piece&qft=*.pm,%20*.t&qd=&qifl=&qls=on&p=1");
sleep(10);


while (
    my $response = HTTP::Tiny->new->get(
        "https://grep.metacpan.org/api/search?size=20&q=Time::Piece&qft=*.pm,%20*.t&qd=&qifl=&qls=on&p=$i")
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


    foreach my $raw_dist ( @{ $j->{results} } ) {
        my $dist_date;
        my $release;

        #skip bundled stuff
        if ( $raw_dist->{distro} =~ /task|belike|bundle/i ) {
            print "SKIP: $raw_dist->{distro}\n";
            next;
        }

        eval {
          $dist_date = localtime->strptime( $meta->release( $raw_dist->{distro} )->date(),
            "%Y-%m-%dT%H:%M:%S" );
        };

        if($@){
            print  "SKIP: $raw_dist->{distro} -" . (split(/\n/, $@))[0];
            print "\n";
            next;
        }

        #or too old
        if ( $dist_date < $too_old && $raw_dist->{distro} !~ /time|date/i) {
            print "SKIP (old): $raw_dist->{distro} - $dist_date\n";
            next;
        }

        $raw_dist->{distro} =~ s/-/::/g;
        print "$raw_dist->{distro}\n";
    }
    sleep(5);
}

