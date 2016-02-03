use strict;
use warnings;
use Data::Dumper;

#TODO: passline odds.

my $filename = 'blah.csv';

open(my $fh, '<', $filename) or die "Can't open $!";

my %hist;
my $n = 0;
my $nSevens = 0;
my $nPrimary = 0;
my $nSecondary = 0;
my $nDouble = 0;
my $off = 1;
my $on = 0;
my $cutoff = -1; # max trials
my $net = 0;
my $working = 0;
my $minNet = 10000;
my $maxNet = -10000;


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

  if($raw == 11) { $hist{'11'}++; $nPrimary++; }
  if($raw == 12) { $hist{'12'}++; }
  if($raw == 13) { $hist{'13'}++; }
  if($raw == 14) { $hist{'14'}++; }
  if($raw == 15) { $hist{'15'}++; }
  if($raw == 16) { $hist{'16'}++; $nSevens++; }
  if($raw == 22) { $hist{'22'}++; $nPrimary++; }
  if($raw == 23) { $hist{'23'}++; $nSecondary++; }
  if($raw == 24) { $hist{'24'}++; $nSecondary++; }
  if($raw == 25) { $hist{'25'}++; $nSevens++; $nDouble++; }
  if($raw == 26) { $hist{'26'}++; }
  if($raw == 33) { $hist{'33'}++; $nPrimary++; }
  if($raw == 34) { $hist{'34'}++; $nSevens++; $nDouble++; }
  if($raw == 35) { $hist{'35'}++; $nSecondary++; }
  if($raw == 36) { $hist{'36'}++; }
  if($raw == 44) { $hist{'44'}++; $nPrimary++; }
  if($raw == 45) { $hist{'45'}++; $nSecondary++; }
  if($raw == 46) { $hist{'46'}++; }
  if($raw == 55) { $hist{'55'}++; $nPrimary++; }
  if($raw == 56) { $hist{'56'}++; }
  if($raw == 66) { $hist{'66'}++; $nPrimary++; }

  my $sum = substr($raw,0,1) + substr($raw,1,1);

  if($off) {
      if($sum == 7 or $sum == 11) {
	  $net += 5;
	  if($working == 1 and $sum == 7) {
	      $net = $net - 5 - 5 - 6 - 6;
	  }
	  print "$sum:$net\n";
      } elsif($sum == 2 or $sum == 3 or $sum == 12) {
#	  $net = $net - 5 - 5 - 6 - 6;
	  print "$sum:$net\n";
      } else {
	  $on = $sum;
	  $off = 0;
	  print "$sum,";
	  if($sum == 6 or $sum == 8) {
	      $net += 7;
	  }
	  if($sum == 5 or $sum == 9) {
	      $net += 7;
	  }
      }
  } elsif($on) {
      if($sum == 7) {
	  $on = 0;
	  $off = 1;
	  $net = $net - 5 - 5 - 6 - 6;
	  print "$sum:$net\n";
      } elsif($on == $sum) {
	  $on = 0;
	  $off = 1;
	  $net += 5;
	  if($sum == 6 or $sum == 8) {
	      $net += 7;
	  }
	  if($sum == 5 or $sum == 9) {
	      $net += 7;
	  }
	  print "$sum:$net\n";
      } else {
	  print "$sum,";
	  if($sum == 6 or $sum == 8) {
	      $net += 7;
	  }
	  if($sum == 5 or $sum == 9) {
	      $net += 7;
	  }
      }
  }

  ++$n;

  if($net < $minNet) {
      $minNet = $net;
  }
  if($net > $maxNet) {
      $maxNet = $net;
  }

  if($cutoff > 0 and $n > $cutoff) {
      last;
  }
}

#while ((my $key, my $value) = each %hist) {
#  print $key . " - " . $value . "\n";
#}
#
print Dumper(\%hist);


print "SEVENS = $nSevens\n";
print "N = $n\n";
print "1:" . $n/$nSevens . "\n";

print "PRIMARY: $nPrimary\n";
print "SECONDARY: $nSecondary\n";
print "DOUBLE: $nDouble\n";
print "PD: " . $nPrimary/$nDouble . "\n";
print "NET: $net\n";
print "MINNET: $minNet\n";
print "MAXNET: $maxNet\n";

foreach my $key (sort keys(%hist)) {
    print $key . " - " . $hist{$key}/$n . "\n";
}
