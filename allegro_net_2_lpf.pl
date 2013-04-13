#!/usr/bin/perl -w

## This programs extracts a "lpf"-list from an allegro netlist

use warnings;
use strict;
use Data::Dumper;
use FileHandle;

##example
#TEST_LINE20,FPGA1.A15 HPLA2.15
#TEST_LINE21,FPGA1.C15 HPLA2.14
#TEST_LINE22,FPGA1.A14 HPLA2.13
#TEST_LINE23,FPGA1.C13 HPLA2.12


my $cur_line;

my @file;

my $component_name = uc($ARGV[0]);
my $filename  = $ARGV[1];

if(!$component_name || !$filename) {
  print "wrong arguments!\n";
  usage();
  exit();
}

my $fh = new FileHandle("<$filename");

if(!$fh) {
  print "Could not open requested file: $filename!\n";
  exit();
}


@file =  <$fh>;

#print "searching for component: $component_name\n";

my @exclusion_list = ("1V2","2V5","GND","3V3","3V_PLL","2V_IO_L","2V_IO_R", "2V_VCCA");

my $rh_connection = {};

foreach $cur_line (@file) {

  chomp $cur_line;

  my (@comp_pin) = ();
  my ($netname, $rest) = $cur_line =~/(\w+)\,(.*)/;
  next unless $netname;
  if($netname) {
    @comp_pin = split /\s/, $rest;
  }


  foreach my $cur_comp_pin (@comp_pin) {
    my ($comp, $pin) = $cur_comp_pin =~ /(\w+)\.(\w+)/;
    next unless $comp;
    push @{$rh_connection->{$netname}->{$comp}}, $pin;
  }

}

#print Dumper $rh_connection;

my $rh_components_to_pins = {};

foreach my $net (keys $rh_connection) {
  foreach my $comp (keys $rh_connection->{$net}) {
    foreach my $pin (@{$rh_connection->{$net}->{$comp}}) {
      push @{$rh_components_to_pins->{$comp}->{$net}}, $pin;
    }
  }
}

#print Dumper $rh_components_to_pins;

my $selection = $rh_components_to_pins->{$component_name};

if (!$selection) {
  print "No component with name $component_name is existing. exit\n";
  exit;
}

print <<EOF;

COMMERCIAL ;
BLOCK RESETPATHS ;
BLOCK ASYNCPATHS ;

EOF


# example 
# LOCATE COMP "outpin" SITE "L1" ;
# LOCATE COMP "clki" SITE "G1" ;


foreach my $net (sort keys $selection) {
  next if (grep /^$net$/, @exclusion_list);
  foreach my $pin (sort @{$selection->{$net}}) {
    printf ("LOCATE COMP %-30.30s   SITE \"$pin\";\n", "\"$net\"");
#    print "LOCATE COMP  \"$net\"\t  SITE \"$pin\";\n";
  }
}


exit;



##############
##############


sub usage {
  print "

allegto_net_2_lpf <COMPONENT_NAME> <filename.net>

The program extracts all nets which are connected to the
component \"COMPONENT_NAME\".

The input-filename is the .NET file you want to analyze.

";

}
