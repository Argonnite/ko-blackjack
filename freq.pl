use strict;
use warnings;
use Data::Dumper;

my $filename = 'blah.csv';

open(my $fh, '<', $filename) or die "Can't open $!";

my %hist;
my $n = 0;
my $nSevens = 0;

while(<$fh>) {
  chomp;

  my $raw = $_;


  if($raw == 21) { $raw = 12; }
  if($raw == 31) { $raw = 13; }
  if($raw == 41) { $raw = 14; }
  if($raw == 51) { $raw = 15; }
  if($raw == 61) { $raw = 16; }
  if($raw == 32) { $raw = 23; }
  if($raw == 42) { $raw = 24; }
  if($raw == 52) { $raw = 25; }
  if($raw == 62) { $raw = 26; }
  if($raw == 43) { $raw = 34; }
  if($raw == 53) { $raw = 35; }
  if($raw == 63) { $raw = 36; }
  if($raw == 54) { $raw = 45; }
  if($raw == 64) { $raw = 46; }
  if($raw == 65) { $raw = 56; }

  if($raw == 11) { $hist{'11'}++; }
  if($raw == 12) { $hist{'12'}++; }
  if($raw == 13) { $hist{'13'}++; }
  if($raw == 14) { $hist{'14'}++; }
  if($raw == 15) { $hist{'15'}++; }
  if($raw == 16) { $hist{'16'}++; $nSevens++; }
  if($raw == 22) { $hist{'22'}++; }
  if($raw == 23) { $hist{'23'}++; }
  if($raw == 24) { $hist{'24'}++; }
  if($raw == 25) { $hist{'25'}++; $nSevens++; }
  if($raw == 26) { $hist{'26'}++; }
  if($raw == 33) { $hist{'33'}++; }
  if($raw == 34) { $hist{'34'}++; $nSevens++; }
  if($raw == 35) { $hist{'35'}++; }
  if($raw == 36) { $hist{'36'}++; }
  if($raw == 44) { $hist{'44'}++; }
  if($raw == 45) { $hist{'45'}++; }
  if($raw == 46) { $hist{'46'}++; }
  if($raw == 55) { $hist{'55'}++; }
  if($raw == 56) { $hist{'56'}++; }
  if($raw == 66) { $hist{'66'}++; }

  ++$n;

}

#while ((my $key, my $value) = each %hist) {
#  print $key . " - " . $value . "\n";
#}
#
print Dumper(\%hist);


print "SEVENS = $nSevens\n";
print "N = $n\n";
print "1:" . $n/$nSevens . "\n";
