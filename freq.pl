use strict;
use warnings;

my $filename = 'blah.csv';

open(my $fh, '<', $filename) or die "Can't open $!";

my %hist;

while(<$fh>) {
#  print;
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

  $hist{$raw}++;


}

foreach my $key (sort(keys %hist)) {
  print $key . " - " . $hist{$key} . "\n";
}

