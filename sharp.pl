use Data::Dumper;

my $sevens = 1;
my $notSevens = 6.4;

#my $nTrials = 100000;
my $nTrials = 40;
my $runningSum = 0;
my $bank = 0;
my $worstBank = 999;
my @sevenStreaks;
for(my $i = 0; $i < $nTrials; ++$i) {

#1 through 10 -- sevens
#11 through 64 -- not sevens
#### or 0 through 9 and 10 through 63
  if(int(rand(64)) < 10) { ### it's a seven
    push @sevenStreaks,$i;
    --$runningSum;
    $bank = $bank - 6;
    if($bank < $worstBank) {
      $worstBank = $bank;
    }
  } else {
# 0 for 2
# 1,2  for 3
# 3,4,5 for 4
# 6,7,8,9 for 5
# 10,11,12,13,14 for 6
# 15,16,17,18,19 for 8
# 20,21,22,23 for 9
# 24,25,26 for 10
# 27,28 for 11
# 29 for 12
    my $secondary = int(rand(30));
    if($secondary > 9 and $secondary < 15) {
      ++$runningSum;
      $bank = $bank + 7;
    } elsif ($secondary > 14 and $secondary < 20) {
      ++$runningSum;
      $bank = $bank + 7;
    }
  }
}

print "RUNNING SUM: $runningSum\n";
print "RATIO: " . $runningSum/$nTrials . "\n";
print "BANK: $bank\n";
print "WORSTBANK: $worstBank\n";
print "NTRIALS: $nTrials\n";
print "(" . join(',',@sevenStreaks) . ")\n";
print "NSEVENS: " . scalar @sevenStreaks . "\n";
