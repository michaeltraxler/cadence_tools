#!/usr/bin/env perl 

# Finds resistor pairs matching a formular to arrive at a certain value.
# E24 and E96 are possible.


use warnings;
use strict;
use FileHandle;

use Data::Dumper; 

my @E96 = qw(1 1.02 1.05 1.07 1.1 1.13 1.15 1.18 1.2 1.21 1.24 1.27 1.3 1.33 1.37 1.4 1.43 1.47 1.5 1.54 1.58 1.6 1.62 1.65 1.69 1.74 1.78 1.8 1.82 1.87 1.91 1.96 2 2.05 2.1 2.15 2.2 2.21 2.26 2.32 2.37 2.4 2.43 2.49 2.55 2.61 2.67 2.7 2.74 2.8 2.87 2.94 3 3.01 3.09 3.16 3.24 3.3 3.32 3.4 3.48 3.57 3.6 3.65 3.74 3.83 3.9 3.92 4.02 4.12 4.22 4.3 4.32 4.42 4.53 4.64 4.7 4.75 4.87 4.99 5.1 5.11 5.23 5.36 5.49 5.6 5.62 5.76 5.9 6.04 6.19 6.2 6.34 6.49 6.65 6.8 6.81 6.98 7.15 7.32 7.5 7.68 7.87 8.06 8.2 8.25 8.45 8.66 8.87 9.09 9.1 9.31 9.53 9.76);

my @E24 = qw(1.0 1.1 1.2 1.3 1.5 1.6 1.8 2.0 2.2 2.4 2.7 3.0 3.3 3.6 3.9 4.3 4.7 5.1 5.6 6.2 6.8 7.5 8.2 9.1);


#print "argument $ARGV[0]\n";

my $arg = $ARGV[0];
if(!$arg) {
    print "you have to give the argument E24 or E96\n";
    print "The formular has to be adapted inside the code. 
Search for Formular.
The required output voltage and maximum deviation are variables to be adapted to
your needs.
";
    exit;
}

#my $required_value = 1.7;

### Please adapt
my $required_value = 2.5;
my $max_delta = 0.05;

my @v;

my @row;

if(lc($ARGV[0]) eq "e24") {
    @row= @E24;
}
elsif (lc($ARGV[0]) eq "e96") {
    @row= @E96;
}
else {
    usage();
}

main();

sub main {

    foreach my $potenz (1..5) {
	foreach (@row) {
	    push (@v, $_*10**$potenz);
	}
    }


#print Dumper \@v;

    my @r = ();
    my $r = {};

    foreach my $R2 (@v) { 
	foreach my $R1 (@v) { 

	    ###################################
	    ### Formular, please adapt
	    ###################################
	    my $v=1.2*(1+$R2/$R1) + 1.3E-6 * $R2;  #
#	    my $v=10*$R1/($R2+$R1); 
#	    my $v=0.4*(1+$R2/$R1); 
#	    my $v=-1.225*($R1+$R2)/$R2; # for LTC1550
#	    my $v=-1.225*($R1+$R2)/$R2; # for LTC1550L
#	    my $v=2/($R1+$R2)*$R2; # normal divider 
	    ####################################

	    my $delta = abs($v-$required_value);

	    if( $delta <= $max_delta) {
		if($R1<=20000 && $R1 > 2000) {
		    #print "R1=$R1, R2=$R2: $v\n" if($flag==1);
		    #push (@r, [$v, $R1, $R2] );
		    $r->{$delta}=[$v, $R1, $R2];
		    #print "R1: $R1, R2: $R2 :  $v\n";
		}
	    }

	}

    }


    #print Dumper $r;

    $arg=uc($arg);

    print "found matches for row $arg\n";
    print "conditions: max_delta: $max_delta\n";
    foreach  my $delta  (sort {$a<=>$b} keys %$r) {
	#print $_;
	my ($v, $R1, $R2) = @{$r->{$delta}};
	printf "delta: %2.4f:  R1: %8.2f, R2: %8.f : %2.4f\n", 
	$delta, $R1, $R2, $v;

    }

}


sub usage {

    print "usage: find_resistor_pair.pl <E24|E96>\n";
    exit;
}
