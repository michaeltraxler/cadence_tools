#!/usr/bin/perl -w

## This programs extracts a "ucf" or pin-file from an orcad
## so called "wire-list"


use strict;
use Data::Dumper;
use FileHandle;

##example

#[00006] +X00
#        GTBCON1         9       9               Passive        N10250-5212VC
#        TRDL_1          30      1B+             BiDirectional  SN75976A2DL
#        R17             2       2               Passive        150R
#        R18             1       1               Passive        300R


my $cur_line;

my @file;

my $component_name = uc($ARGV[0]);
my $filename  = $ARGV[1];

if(!$component_name) {
  print "You have to provide a component name as first argument!\n";
  usage();
  exit();
}

my $fh = new FileHandle("<$filename");

if(!$fh) {
  print "Could not open requested file!\n";
  usage();
  exit();
}


@file =  <$fh>;

#print "searching for component: $component_name\n";


my $in_signals = 0;

my $all_connections = {};

my @connections = ();
my $signal_name;

my @nodes = ();
my @lines = ();
foreach $cur_line (@file) {

  chop $cur_line;
  chop $cur_line;
  #print "\"$cur_line\"" . "\n";

  if($in_signals == 0) {
    if ( $cur_line !~ /^\[/ ) {
      next;
    }
    else {
      $in_signals = 1;
    }
  }

  if ( $cur_line ) {
    push(@lines, $cur_line);
    #print "cur line: $cur_line \n";
  }
  else {
    #print "next node:\n";
    my @tmp_lines = @lines;
    push(@nodes, \@tmp_lines);
    @lines = ();
    $in_signals = 0;
  }
}


#print Dumper @nodes;

my $mapping = {};

foreach my $cur_node (@nodes) {

  my $line_nr = 0;
  my $signal_name;
  foreach my $cur_line (@$cur_node) {
    #print "cur line: $cur_line\n";
    if($line_nr == 0) {
      ($signal_name)= $cur_line =~ /\] ([\w\+\-]+)/;
      $line_nr = 1;
    }
    else {
      $line_nr++;
      my ($comp, $pin_nr ) = $cur_line =~ /\s+(\w+)\s+(\w+)/;
      #print "comp: $comp , pin: $pin_nr\n";
      if($comp eq $component_name) {
	my ($tmp) = $signal_name =~ /([\D]+)/;
	my ($tmp2) = $signal_name =~ /(\d+)$/;
	$tmp2 = 0 if (!$tmp2);
	$mapping->{$signal_name} = {'COMP' => $comp, 'PIN' => $pin_nr, 
				    'SIG_WO_NR' => $tmp, 'SIG_NR' => $tmp2
				   };
      }
    }


  }

}

#print Dumper $mapping;

print <<EOF;

COMMERCIAL ;
BLOCK RESETPATHS ;
BLOCK ASYNCPATHS ;

EOF

# example 
# LOCATE COMP "outpin" SITE "L1" ;
# LOCATE COMP "clki" SITE "G1" ;


foreach my $cur_sig (sort { $mapping->{$a}->{'SIG_WO_NR'} cmp $mapping->{$b}->{'SIG_WO_NR'}
			      ||
				$mapping->{$a}->{'SIG_NR'} <=> $mapping->{$b}->{'SIG_NR'}
			  } 
		     keys %$mapping) {
  my $net; my  $pin;
  $net = $cur_sig;
  $net =~ s/(\d+)$/_$1/;
  $pin = $mapping->{$cur_sig}->{'PIN'};
  print "LOCATE COMP  \"$net\"\t  SITE \"$pin\";\n";
}


exit();


##############
##############


my %caps;
my %nums;

my $cur;

foreach $cur (keys %$all_connections) {
  my ($num) = $cur =~ /(\d+)/;
  if(!defined $num) {
      $num = 0;
  }
  #print $num . "\n";
  $nums{$cur}  = $num;
}
#print Dumper \%nums;
#exit;

foreach $cur (keys %$all_connections) {
  my ($cap) = $cur =~ /^(\D+)/;
  if(!defined $cap) { 
      #print "$cur\n";
      $cap = "";
  }
  #print $cap . "\n";
  $caps{$cur}  = $cap;
}

#print Dumper %caps;


foreach $cur (sort { $caps{$a} cmp $caps{$b}  || $nums{$a} <=> $nums{$b} }  keys %$all_connections) {
  #print $cur;
  printf "LOCATE COMP \"%-15.30s\" SITE \"%d\"\n", $cur, $all_connections->{$cur}->{'num'};

}



sub usage {
  print "

net_2_ucf <COMPONENT_NAME> <filename.net>

The program extracts all nets which are connected to the
component \"COMPONENT_NAME\".

The input-filename is the .NET file you want to analyze.

";

}
