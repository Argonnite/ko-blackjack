use List::Util qw/shuffle sum/;
use Data::Dumper;
use Scalar::Util qw/looks_like_number/;


my $nDecks = 8;
my $cut;             # penetration
my $nTrials;         # number of shoes to simulate
my $spreadMin;       # limits on the betting spread
my $spreadMax;
my $RCmin;           # running min count reached for the shoe
my $RCmax;           # running max count reached for the shoe
my $rsLimit = 3;     # limit on resplits.  -1 if unlimited.
my $spotsLimit = 2;  # number of those seated
my $bjPayout = 1.5;



###prep deck
my @deck;
my @ranks = qw/a k q j t 9 8 7 6 5 4 3 2/;
my @suits = qw/s h d c/;

foreach my $rank (@ranks) {
  foreach my $suit (@suits) {
    push @deck,$rank . $suit;
  }
}
@deck = shuffle @deck;


####place bets
#my $bet = 'a';
#while(not looks_like_number $bet) {
#  print "Enter bet (You have $playerChips):";
#  $bet = <STDIN>;
#}
#chomp $bet;
#$playerChips -= $bet;
#print "Betting $bet.\n";
#print "You have $playerChips remaining.\n";


###dealer's cards
my @dealer;
push @dealer,pop @deck;
push @dealer,pop @deck;
print "Dealer: " . join(' ',("XX"),@dealer[1]) . "\n";

###players' cards
my @places;
my @cards;
my $bet = 1;
for(my $i = 0; $i < $spotsLimit; ++$i) {
    push @places,{('bet' => $bet, 'cards' => [pop @deck, pop @deck], 'pos' => $i, 'splitID' => 0)};
}


#print Dumper(\@places);
my @patPlaces;
while (scalar @places) {  # decide each spot.
    my $hand = shift @places;
    my @totals = getTotals($hand->{'cards'});

    print "\n";
    print Dumper($hand->{'cards'});
    print "POS: " . $hand->{'pos'} . ", ";
    print "SID: " . $hand->{'splitID'} . "\n";
    print "ISPAIR: " . isPair($hand->{'cards'}) . "\n";
    print "ISSOFT: " . isSoft($hand->{'cards'}) . "\n";
    my $bestTotal = bestTotal(\@totals);
    print "BESTTOT: $bestTotal\n";
    print "BINGO: " . isNatural($hand->{'cards'}) . "\n";
}



##################################################################

### sub bestTotal
sub bestTotal {
    my $totals = shift(@_);
    my $bestTotal = -1;
    foreach my $total (@{$totals}) {
print "TOT: $total\n";
	if($total > $bestTotal && $total < 22) {
	    $bestTotal = $total;
	}
    }
    return $bestTotal;
 }


###sub isBusted
###sub isSoft
sub isSoft {
    my $cards = shift(@_);
    my @cardAry = @{$cards};
    my @totals = getTotals(\@cardAry);

    my $i = 0;
    foreach my $total (@totals) {
	if($total < 22 && $total > 0) {
	    ++$i;
	}
    }
    if($total > 0) {
	return 1;
    } else {
	return 0;
    }
}


###sub isPair
sub isPair {
    my $cards = shift(@_);
    my @cardAry = @{$cards};

    if((substr($cardAry[0],0,1) == substr($cardAry[1],0,1)) && scalar(@cardAry) == 2) {
	return 1;
    } else {
	return 0;
    }
}


###sub isNatural
sub isNatural {
    my $cards = shift(@_);
    my @cardAry = @{$cards};
    my @totals = getTotals(\@cardAry);
    if(scalar @cardAry == 2 && bestTotal(\@totals) == 21) {
	return 1;
    } else {
	return 0;
    }
}


###sub getTotals
sub getTotals {
    my $cards = shift(@_);
    my @sums = (0);

    foreach my $card (@{$cards}) {
	my @newSums = ();
	my $rank = substr($card,0,1);
	if($rank eq 'a') {
	    foreach my $total (@sums) {  ### add ones
		push @newSums,($total + 1);
	    }
	    foreach my $total (@sums) {  ### add elevens
		push @newSums,($total + 11);
	    }
	} elsif($rank eq 't') {
	    foreach my $total (@sums) {
		push @newSums,($total + 10);
	    }
	} elsif(!looks_like_number($rank)) {
	    foreach my $total (@sums) {
		push @newSums,($total + 10);
	    }
	} elsif(looks_like_number($rank)) {
	    foreach my $total (@sums) {
		push @newSums,($total + $rank);
	    }
	} else {
	    print "ERROR.\n";
	}
	@sums = @newSums;
    }
    return @sums;
}

#    my $key = "h";
#    while ($key eq "h" or $key eq "p") {
#	print scalar @deck . " cards remaining.\n";
#	print "Player: " . join(' ',@{$hand->{cards}}) . "\n";
#	print "(h)it, (s)tand, (d)ouble down, s(p)lit:\n";
#	$key = <>;
#	chomp $key;
#	if($key eq "h") {
#	    print "Hitting.\n";
#	    push @{$hand->{cards}},pop @deck;
#	    if(busted($hand)) {
#		$key = '';
#		$hand->{bet} = 0;
#		push @patPlaces,$hand;
#		undef $hand;
#	    }
#	} elsif ($key eq "s") {
#	    print "Standing.\n";
#	    push @patPlaces,$hand;
#	    undef $hand;
#	} elsif ($key eq "d") {
#	    print "Doubling-down.\n";
#	    $playerChips -= $hand->{bet}; # betting more chips.
#	    print "You have $playerChips remaining.\n";
#	    push @{$hand->{cards}},pop @deck;
#	    if(busted($hand)) {
#		$key = '';
#		$hand->{bet} = 0;
#		push @patPlaces,$hand;
#		undef $hand;
#	    } else {
#		$hand->{bet} += $bet;
#	    }
#	    push @patPlaces,$hand;
#	    undef $hand;
#	} elsif ($key eq "p") {
#	    print "Splitting.\n";
#	    my @newCards;
#	    push @newCards,pop @{$hand->{cards}};
#	    push @newCards,pop @deck;
#	    push @{$hand->{cards}},pop @deck;
#	    push @places,{('bet' => $bet, 'cards' => \@newCards, 'pos' => ++$pos)};
#	    $playerChips -= $bet;
#	    print "You have $playerChips remaining.\n";
#	} else {
#	    print "Not a valid choice.\n";
#	    $key = "h";
#	}
#    }
#}
    






####dealer's turn
#while(total(@dealer) < 17 and soft(@dealer) and not busted(@dealer)) {
#  push @dealer,pop @deck;
#}
#
#if(busted(@dealer)) {
#  pay(%places);
#}



#########################################
#sub total {
#  my $refCards = pop @_;
#  my @deck = @{$refCards};
#  my @vals = map { s/^[kqjt][shdc]/10/g } @deck;
#  @vals = map { s/^a[shdc]/11/g } @vals;
#  my $total = sum @vals;
#
#
#
#
#
##  my $sum = 0;
##  foreach (@deck) {
##    if($_ =~ /^(\d)/) {
##      $sum += $1;
##    } 
##    if($_ =~ /^[kqjt]/) {
##      $sum += 10;
##    }
##    if($_ =~ /^a/) {
##      $sum += 11;
##    }
##  }
##  return $sum;
#}



#  up  2  3  4  5  6  7  8  9  T  A
#aa   sp sp sp sp sp sp sp sp sp sp
#tt    s  s  s  s  s  s  s  s  s  s
#99   sp sp sp sp sp  s sp sp  s  s
#88   sp sp sp sp sp sp sp sp sp sp
#77   sp sp sp sp sp sp  h  h  h  h
#66    h sp sp sp sp  h  h  h  h  h
#55    d  d  d  d  d  d  d  d  h  h
#44    h  h  h  h  h  h  h  h  h  h
#33    h  h sp sp sp sp  h  h  h  h
#22    h  h sp sp sp sp  h  h  h  h
#
#h17    s  s  s  s  s  s  s  s  s  s
#h16    s  s  s  s  s  h  h su su su
#h15    s  s  s  s  s  h  h  h su  h
#h14    s  s  s  s  s  h  h  h  h  h
#h13    s  s  s  s  s  h  h  h  h  h
#h12    s  s  s  s  s  h  h  h  h  h
#11    dh dh dh dh dh dh dh dh dh  h
#10    dh dh dh dh dh dh dh dh  h  h
# 9     h dh dh dh dh  h  h  h  h  h
#8..    h  h  h  h  h  h  h  h  h  h
#
#s19    s  s  s  s  s  s  s  s  s  s
#s18    s ds ds ds ds  s  s  h  h  h
#s17    h dh dh dh dh  h  h  h  h  h
#s16    h  h dh dh dh  h  h  h  h  h
#s15    h  h dh dh dh  h  h  h  h  h
#s14    h  h  h dh dh  h  h  h  h  h
#s13    h  h  h dh dh  h  h  h  h  h
