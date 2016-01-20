use List::Util qw/shuffle sum/;
use Data::Dumper;
use Scalar::Util qw/looks_like_number/;

my $DEBUG = 1;

#FIXME: handle deck runouts
#FIXME: action granularities and flags
#FIXME: make sure doubling happens only on 2 cards


my $nDecks = 8;      # size of shoe
my $cut = 1;         # penetration in number of decks unseen
my $nShoesToRun = 5; # number of shoes to simulate
my $spreadMin;       # limits on the betting spread
my $spreadMax;
my $RCmin;           # running min count reached for the shoe
my $RCmax;           # running max count reached for the shoe
my $rsLimit = 3;     # limit on resplits.  -1 if unlimited.
my $spotsLimit = 2;  # number of those seated
my $bjPayout = 1.5;
my $esAllowed = 0;   # surrender flags
my $lsAllowed = 0;
my $rsa;             # resplit aces allowed
my $rs;              # resplit any allowed
my $rsa3;            # resplit aces once
my $rs3 = 1;         # replit once
my $esAllowed;       # early surrender
my $lsAllowed;       # late surrender
my $dasAllowed;      # doubling after splitting
my $h17 = 1;         # dealer hits soft 17



for(my $nCurrentShoe = 0; $nCurrentShoe < $nShoesToRun; ++$nCurrentShoe) {

    ### prep deck
    my $fPenetrationCard = 52.0 * $cut; # when shoe becomes smaller than this, reshuffle.
    my @deck;
    my @ranks = qw/a k q j t 9 8 7 6 5 4 3 2/;
    my @suits = qw/s h d c/;
    for(my $i = 0; $i < $nDecks; ++$i) {
	foreach my $rank (@ranks) {
	    foreach my $suit (@suits) {
		push @deck,$rank . $suit;
	    }
	}
    }
    @deck = shuffle @deck;
    my @discards = ();
    my $runningCount = 0;


    while(scalar @deck > $fPenetrationCard) { #deal a round

	### before betting actions
	my $runningCountAtStartOfHand = $runningCount;
	print "IRC: $runningCountAtStartOfHand\n";

        ### dealer's cards
	my @dealer;
	push @dealer,shift @deck;
	push @dealer,shift @deck;
	print "Dealer: " . join(' ',("XX"),@dealer[1]) . "\n";
	$runningCount += KOVal($dealer[1]);

        ### players' cards
	my @places;
	my @cards;
	my $bet = 1;
	for(my $i = 0; $i < $spotsLimit; ++$i) {
	    my $initCard0 = shift @deck;
	    $runningCount += KOVal($initCard0);
	    my $initCard1 = shift @deck;
	    $runningCount += KOVal($initCard1);
	    push @places,{('bet' => $bet, 'cards' => [$initCard0, $initCard1], 'pos' => $i, 'splitID' => 0, 'IRC' => $runningCountAtStartOfHand)};
	}
	if($DEBUG) {
	    print "INITPLACES\n";
	    print Dumper(\@places);
	}

        ### players' hits
	my @patPlaces;
	my @bustedPlaces;
	while (scalar @places) {
	    my $hand = shift @places;
	    my @totals = getTotals($hand->{'cards'});
	    my $bestTotal = bestTotal(\@totals);

	    if($DEBUG) {
		print "WORKING ON:\n";
		print Dumper($hand->{'cards'});
		print "POS: " . $hand->{'pos'} . ", ";
		print "SplID: " . $hand->{'splitID'} . "\n";
		print "ISPAIR: " . isPair($hand->{'cards'}) . "\n";
		print "ISSOFT: " . isSoft($hand->{'cards'}) . "\n";
		print "BESTTOT: $bestTotal\n";
		print "ISNATURAL: " . isNatural($hand->{'cards'}) . "\n";
	    }

	    my %table = ();
	    generate(\%table);

	    my $pRank = substr($hand->{'cards'}->[0],0,1);
	    if($pRank =~ /[kqjt]/) {
		$pRank = 't';
	    }
	    if($DEBUG) {
		print "PRANK: $pRank\n";
	    }
	    my $dRank = substr($dealer[1],0,1);
	    if($dRank =~ /[kqjt]/) {
		$dRank = 't';
	    }
	    if($DEBUG) {
		print "DRANK: $dRank\n";
	    }


	    my $action;
	    if(isNatural($hand->{'cards'})) { #bj?
		$action = "bj";
	    } elsif(isPair($hand->{'cards'})) { #split?
		$action = $table{$pRank . $pRank}{$dRank};
	    } elsif(isSoft($hand->{'cards'})) { #soft?
		if($bestTotal >= 19) {
		    $action = 's';
		} else {
		    $action = $table{'s' . $bestTotal}{$dRank};
		}
	    } elsif(!isSoft($hand->{'cards'})) { #it must be hard
		if($bestTotal >= 17) {
		    $action = 's';
		} else {
		    if(not exists $table{$bestTotal}{$dRank}) {
			$action = $table{"h" . $bestTotal}{$dRank};
		    } else {
			$action = $table{$bestTotal}{$dRank};
		    }
		}
	    } else {
		print "ERROR:  Table lookup.\n";
		exit(0);
	    }
	    if($DEBUG) {
		print "ACTION: $action\n";
	    }


	    ### execute player actions.
	    if($action eq 'sp') { ### split
		if($DEBUG) {
		    print "SPLITTING\n";
		}
		my %newSpot = %hand;
		my $card0 = $hand->{'cards'}->[0];
		my $card1 = $hand->{'cards'}->[1];

		my $popCard0 = shift @deck;
		$runningCount += KOVal($popCard0);
		my $popCard1 = shift @deck;
		$runningCount += KOVal($popCard1);
		$hand->{'cards'} = [$card0, $popCard0];
		$newSpot->{'cards'} = [$card1, $popCard1];

		$newSpot->{'bet'} = $hand->{'bet'};
		$newSpot->{'pos'} = $hand->{'pos'};
		$newSpot->{'splitID'} = $hand->{'splitID'} + 1;
		
		push @places,$hand;
		push @places,$newSpot;

	    } elsif($action eq 's') { ### stand pat
		if($DEBUG) {
		    print "PAT\n";
		}
		push @patPlaces,$hand;
	    } elsif($action eq 'dh' or $action eq 'd' or $action eq 'ds') { ### double down
		if($DEBUG) {
		    print "DOUBLING\n";
		}
		$hand->{'bet'} = $hand->{'bet'} * 2;
		my $doubleCard = shift @deck;
		$runningCount += KOVal($doubleCard);
		push @{$hand->{'cards'}},$doubleCard;
		if(isBusted($hand->{'cards'})) { ### busted
		    $hand->{'busted'} = "yes";
		    push @bustedPlaces,$hand;
		} else {
		    push @patPlaces,$hand;
		}
	    } elsif($action eq 'su' or $action eq 'h') { ### hitting
		if($DEBUG) {
		    print "HITTING\n";
		}
		my $hitCard = shift @deck;
		$runningCount += KOVal($hitCard);
		push @{$hand->{'cards'}},$hitCard;
		if(isBusted($hand->{'cards'})) { ### busted
		    $hand->{'busted'} = "yes";
		    push @bustedPlaces,$hand;
		} else {
		    unshift @places,$hand;
		}
	    } elsif($action eq 'bj') { ### blackjack
		push @patPlaces,$hand;
	    } else {
		print "ERROR: unfound action $action\n";
		exit(0);
	    }

	    print "---PAUSE---\n";
	    print "Dealer: " . join(' ',("XX"),@dealer[1]) . "\n";
	    my $key = <>;
	    print "PLACES\n";
	    print Dumper(\@places);
	    print "BUSTEDPLACES\n";
	    print Dumper(\@bustedPlaces);
	    print "PATPLACES\n";
	    print Dumper(\@patPlaces);


	}


        ### dealer actions
	my @dealerTotals = getTotals(\@dealer);
	my $dealerBest = bestTotal(\@dealerTotals);
	print "Dealer: " . join(' ',@dealer) . "\n";
	$runningCount += KOVal($dealer[0]);
	print "DealerTots: " . Dumper(\@dealerTotals);
	print "DealerBest: $dealerBest\n";


	while(($dealerBest < 17 or ( ($h17 == 1) and ($dealerBest == 17 and isSoft(\@dealer)) ) ) and not isBusted(\@dealer)) {
	    print "---DEALER PAUSE---\n";
	    my $key = <>;
	    my $dealerCard = shift @deck;
	    $runningCount += KOVal($dealerCard);
	    push @dealer,$dealerCard;
	    @dealerTotals = getTotals(\@dealer);
	    $dealerBest = bestTotal(\@dealerTotals);
	    print "DEALER HITTING.\n";
	    print "DEALER: " . join(' ',@dealer) . "\n";
	    print "DEALERTOTS: " . Dumper(\@dealerTotals);
	    print "DEALERBEST: $dealerBest\n";
	}


        ### collections, payouts, and discards
	print "BLAHBLAHBLAH\n";
	print "Dealer: " . join(' ',("XX"),@dealer[1]) . "\n";
	print "PLACES\n";
	print Dumper(\@places);
	print "BUSTEDPLACES\n";
	print Dumper(\@bustedPlaces);
	print "PATPLACES\n";
	print Dumper(\@patPlaces);
	foreach my $patHand (@patPlaces) {
#FIXME: busted dealer.
	    my $pTot = bestTotal(getTotals(@{$patHand->{'cards'}}));
	    if($pTot > $dealerBest) {
		print "POS: $patHand->{'pos'} wins.\n";
	    } elsif($pTot < $dealerBest) {
		print "POS: $patHand->{'pos'} loses.\n";
	    } else {
		print "POS: $patHand->{'pos'} pushes.\n";
	    }
	}
	print "REMAINING: " . scalar @deck . "\n";
	print "CUTPOINT: $fPenetrationCard\n";
	print "RC: $runningCount\n";
	exit(0);

    }
}
##################################################################

### sub KOVal
sub KOVal {
    my $card = shift(@_);
    my $rank = substr($card,0,1);
    if($rank =~ /[akqjt]/) {
	return -1;
    } elsif ($rank > 1 and $rank < 8) {
	return 1;
    } else {
	return 0;
    }
}


### sub generate
sub generate {
    my $tableRef = shift(@_);
    my @textTable;
    push @textTable,"aa   sp sp sp sp sp sp sp sp sp sp";
    push @textTable,"tt    s  s  s  s  s  s  s  s  s  s";
    push @textTable,"99   sp sp sp sp sp  s sp sp  s  s";
    push @textTable,"88   sp sp sp sp sp sp sp sp sp sp";
    push @textTable,"77   sp sp sp sp sp sp  h  h  h  h";
    push @textTable,"66    h sp sp sp sp  h  h  h  h  h";
    push @textTable,"55    d  d  d  d  d  d  d  d  h  h";
    push @textTable,"44    h  h  h  h  h  h  h  h  h  h";
    push @textTable,"33    h  h sp sp sp sp  h  h  h  h";
    push @textTable,"22    h  h sp sp sp sp  h  h  h  h";
    push @textTable,"h17    s  s  s  s  s  s  s  s  s  s";
    push @textTable,"h16    s  s  s  s  s  h  h su su su";
    push @textTable,"h15    s  s  s  s  s  h  h  h su  h";
    push @textTable,"h14    s  s  s  s  s  h  h  h  h  h";
    push @textTable,"h13    s  s  s  s  s  h  h  h  h  h";
    push @textTable,"h12    s  s  s  s  s  h  h  h  h  h";
    push @textTable,"11    dh dh dh dh dh dh dh dh dh  h";
    push @textTable,"10    dh dh dh dh dh dh dh dh  h  h";
    push @textTable," 9     h dh dh dh dh  h  h  h  h  h";
    push @textTable," 8     h  h  h  h  h  h  h  h  h  h";
    push @textTable," 7     h  h  h  h  h  h  h  h  h  h";
    push @textTable," 6     h  h  h  h  h  h  h  h  h  h";
    push @textTable," 5     h  h  h  h  h  h  h  h  h  h";
    push @textTable," 4     h  h  h  h  h  h  h  h  h  h";
    push @textTable," 3     h  h  h  h  h  h  h  h  h  h";
    push @textTable," 2     h  h  h  h  h  h  h  h  h  h";
    push @textTable,"s19    s  s  s  s  s  s  s  s  s  s";
    push @textTable,"s18    s ds ds ds ds  s  s  h  h  h";
    push @textTable,"s17    h dh dh dh dh  h  h  h  h  h";
    push @textTable,"s16    h  h dh dh dh  h  h  h  h  h";
    push @textTable,"s15    h  h dh dh dh  h  h  h  h  h";
    push @textTable,"s14    h  h  h dh dh  h  h  h  h  h";
    push @textTable,"s13    h  h  h dh dh  h  h  h  h  h";

    my @dUps = qw/2 3 4 5 6 7 8 9 t a/;
    foreach my $line (@textTable) {
	$line =~ s/^\s+//;  # leading whitespace messes up below line.
	my @actions = split(/\s+/,$line);
	my $pHand = shift @actions;
	for(my $i; $i < 10; ++$i) {
	    $tableRef->{$pHand}->{$dUps[$i]} = $actions[$i];
	}
    }
}



### sub bestTotal
sub bestTotal {
    my $totals = shift(@_);
    my $bestTotal = -1;
    foreach my $total (@{$totals}) {
	if($total > $bestTotal && $total < 22) {
	    $bestTotal = $total;
	}
    }
    return $bestTotal;
 }


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
    if($i > 1) {
	return 1;
    } else {
	return 0;
    }
}


###sub isPair
sub isPair {
    my $cards = shift(@_);
    my @cardAry = @{$cards};

    my $rank0 = substr($cardAry[0],0,1);
    my $rank1 = substr($cardAry[1],0,1);

    if($rank0 =~ /[kqjt]/) {
	$rank0 = 't';
    }
    if($rank1 =~ /[kqjt]/) {
	$rank1 = 't';
    }

    if($rank0 eq $rank1 && scalar(@cardAry) == 2) {
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


###sub isBusted
sub isBusted {
    my $cards = shift(@_);
    my @totals = getTotals($cards);
    my $bestTot = bestTotal(\@totals);

    if($bestTot == -1) {
      return 1;
    } else {
      return 0;
    }
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
