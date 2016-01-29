use List::Util qw/shuffle sum/;
use Data::Dumper;
use Scalar::Util qw/looks_like_number/;

my $DEBUG = 1;

#FIXME: action granularities and flags
#FIXME: make sure doubling happens only on 2 cards


#my $nDecks = 8;      # size of shoe
#my $cut = 1;         # penetration in number of decks unseen
my $nDecks = 1;      # size of shoe
my $cut = 0.7;         # penetration in number of decks unseen
my $nShoesToRun = 5; # number of shoes to simulate
my $spreadMin;       # limits on the betting spread
my $spreadMax;
my $RCmin;           # running min count reached for the shoe
my $RCmax;           # running max count reached for the shoe
my $spotsLimit = 2;  # number of those seated
my $bjPayout = 1.5;
my $esAllowed;       # early surrender
my $lsAllowed;       # late surrender
my $rsa = 1;         # resplit aces allowed
my $rs = 0;          # resplit any allowed
my $rsa3 = 1;        # resplit aces once
my $rs3 = 1;         # resplit once more
my $das = 0;         # doubling after splitting aces
my $ds;              # doubling after splitting
my $da;              # double down on any two cards
my $hsa;             # can hit after splitting aces
my $nsa;             # no splitting of aces
my $nrs;             # no resplitting
my $h17 = 1;         # dealer hits soft 17


my %table = ();
generate(\%table);



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

	### IRC before dealing round
	my $runningCountAtStartOfHand = $runningCount;
	print "IRC: $runningCountAtStartOfHand\n";

        ### dealer's cards
	my @dealer;
	push @dealer,deal(\@deck,\@discards);
	push @dealer,deal(\@deck,\@discards);
	print "Dealer: " . join(' ',("XX"),@dealer[1]) . "\n";

        ### players' cards
	my @places;
	my @cards;
	my $bet = 1;
	my @splitsCnt;
	for(my $i = 0; $i < $spotsLimit; ++$i) {
	    push @places,{('bet' => $bet, 'cards' => [deal(\@deck,\@discards), deal(\@deck,\@discards)], 'pos' => $i, 'splitID' => 0, 'IRC' => $runningCountAtStartOfHand)};
	    $splitsCnt[$i] = 0;
	}
	if($DEBUG) {
	    print "INITPLACES\n";
	    print Dumper(\@places);
	}

        ### players' hits
	my @patPlaces;
	my @bustedPlaces;




###TESTING HERE###
print "###TESTING HERE###\n";
@deck = ( 'ag', '5c', 'as', '7c', 'kd', '4h', 'ah', 'qs');
unshift @deck,"ae";
unshift @deck,"af";
print Dumper(\@deck);
print "Dealer: " . join(' ',("XX"),@dealer[1]) . "\n";
print "PLACES\n";
$places[0]{'cards'}[0] = "aa";
$places[0]{'cards'}[1] = "ab";
print Dumper(\@places);
#exit(0);


#FIXME: check dealer bj before player actions.

	while (scalar @places) {
	    my $hand = shift @places;
	    my @totalsAry = getTotals($hand->{'cards'});
	    my $bestTotal = bestTotal(\@totalsAry);

	    if($DEBUG) {
		print "WORKING ON:\n";
		print Dumper($hand->{'cards'});
		print "POS: " . $hand->{'pos'} . ", ";
		print "SplID: " . $hand->{'splitID'} . "\n";
		print "ISPAIR: " . isPair($hand->{'cards'}) . "\n";
		print "ISSOFT: " . isSoft($hand->{'cards'}) . "\n";
		print "BESTTOT: $bestTotal\n";
		print "ISNATURAL: " . isNatural($hand->{'cards'}) . "\n";
		print "SPLITSCNT: $splitsCnt[$hand->{'pos'}]\n";
	    }

	    my $pRank = getRank($hand->{'cards'}->[0]);
	    if($DEBUG) {
		print "PRANK: $pRank\n";
	    }
	    my $dRank = getRank($dealer[1]);
	    if($DEBUG) {
		print "DRANK: $dRank\n";
	    }


	    ## lookup player actions.
	    my $action;
	    if(isNatural($hand->{'cards'})) { #bj?
		$action = "bj";
	    } elsif(isPair($hand->{'cards'})) { #split?
#FIXME: test these branches.
#FIXME: add nodas/das checking.
# rsa, rs, rsa3, rs3, das, ds, da, hsa, nsa, nrs
		if(isAce($pRank)) {  # ace splits
		    if($splitsCnt[$hand->{'splID'}] == 0) { # the original aces
			$action = $table{$pRank . $pRank}{$dRank};
		    } else {
			if($rsa) {
			    if($rsa3) {
				if($splitsCnt[$hand->{'pos'}] < 2) {
print "DO I GET HERE?99\n";
				    $action = $table{$pRank . $pRank}{$dRank};
				} else {
print "DO I GET HERE?AA\n";
				    $action = 's'; # limit hits on split aces.
				}
			    } else {
print "DO I GET HERE?BB\n";
				$action = $table{$pRank . $pRank}{$dRank};
			    }
			} else {
print "DO I GET HERE?CC\n";
			    $action = 's'; # limit hits on split aces.
			}
		    }
		} else { # non-ace splits.
		    if($rs3) {
			if($splitsCnt[$hand->{'pos'}] < 2) {
			    $action = $table{$pRank . $pRank}{$dRank};
			} else {
			    if(isSoft($hand->{'cards'})) { #soft?
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
			    }
			}
		    } else {
			$action = $table{$pRank . $pRank}{$dRank};
		    }
		}
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


	    ## execute player actions.
	    if($action eq 'sp') { ### split
		if($DEBUG) {
		    print "SPLITTING\n";
		}

		my %newSpot = %{$hand};
		my $card0 = $hand->{'cards'}->[0];
		my $card1 = $hand->{'cards'}->[1];

		my $newCard0 = deal(\@deck,\@discards);
		my $newCard1 = deal(\@deck,\@discards);

		$hand->{'cards'} = [$card0, $newCard0]; # dereferencing
		$newSpot{'cards'} = [$card1, $newCard1];

		$newSpot{'bet'} = $hand->{'bet'}; # not-dereferencing
		$newSpot{'pos'} = $hand->{'pos'};
		$newSpot{'splitID'} = $hand->{'splitID'} + 1;

		++$splitsCnt[$hand->{'pos'}];

		unshift @places,$hand;
		unshift @places,\%newSpot;
	    } elsif($action eq 's') { ### stand pat
		if($DEBUG) {
		    print "PAT\n";
		}
		push @patPlaces,$hand;
#FIXME: break up below compound condition.
	    } elsif($action eq 'dh' or $action eq 'd' or $action eq 'ds') { ### double down
#FIXME: check if two cards only.
		if($DEBUG) {
		    print "DOUBLING\n";
		}
		$hand->{'bet'} = $hand->{'bet'} * 2;
		my $doubleCard = deal(\@deck,\@discards);
		push @{$hand->{'cards'}},$doubleCard;
		if(isBusted($hand->{'cards'})) { ### busted
		    $hand->{'busted'} = "yes";
		    push @bustedPlaces,$hand;
		} else {
		    push @patPlaces,$hand;
		}
#FIXME: break up below compound condition.
	    } elsif($action eq 'su' or $action eq 'h') { ### hitting
#FIXME: su only on 2 cards?
		if($DEBUG) {
		    print "HITTING\n";
		}
		push @{$hand->{'cards'}},deal(\@deck,\@discards);
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
	my @dealerTotalsAry = getTotals(\@dealer);
	my $dealerBest = bestTotal(\@dealerTotalsAry);
	print "Dealer: " . join(' ',@dealer) . "\n";
	print "DealerTots: " . Dumper(\@dealerTotalsAry);
	print "DealerBest: $dealerBest\n";


	while(($dealerBest < 17 or ( ($h17 == 1) and ($dealerBest == 17 and isSoft(\@dealer)) ) ) and not isBusted(\@dealer)) {
	    print "---DEALER PAUSE---\n";
	    my $key = <>;
	    my $dealerCard = deal(\@deck,\@discards);
	    push @dealer,$dealerCard;
	    @dealerTotalsAry = getTotals(\@dealer);
	    $dealerBest = bestTotal(\@dealerTotalsAry);
	    print "DEALER HITTING.\n";
	    print "DEALER: " . join(' ',@dealer) . "\n";
	    print "DEALERTOTS: " . Dumper(\@dealerTotalsAry);
	    print "DEALERBEST: $dealerBest\n";
	}


        ### collections, payouts, and discards
	print "BLAHBLAHBLAH\n";
	print "Dealer: " . join(' ',("XX"),@dealer[1]) . "\n";
	print "PLACES\n";
	print Dumper(\@places);
	print "BUSTEDPLACES\n";
	print Dumper(\@bustedPlaces);

#FIXME: naturals
#FIXME: pushing naturals 
#FIXME: split then naturals? NO.
#FIXME: record dInit and pInitInit

	### determine winners/losers
	if(isBusted(\@dealer)) {
	    foreach my $patHand (@patPlaces) {
print "DO I GET HERE?1\n";
		if(isNatural($patHand->{'cards'})) {
		    if($splitsCnt[$patHand->{'pos'}] == 0) {
			$patHand->{'won'} = "bj";
		    } else {
			$patHand->{'won'} = "yes";
		    }
		} else {
		    $patHand->{'won'} = "yes";
		}
	    }
	} elsif(isNatural(\@dealer)) {
print "DO I GET HERE?2\n";
	    foreach my $patHand (@patPlaces) {
		if(isNatural($patHand->{'cards'})) {
		    $patHand->{'pushed'} = "yes";
		} else {
		    $patHand->{'lost'} = "yes";
		}
	    }
	} else {
print "DO I GET HERE?3\n";
	    foreach my $patHand (@patPlaces) {
		my @tmp = getTotals($patHand->{'cards'});
		my $pTot = bestTotal(\@tmp);
print "TMP: " . Dumper(\@tmp);
print "PTOT = $pTot\n";
		if($pTot > $dealerBest) {
print "DO I GET HERE?3a\n";
		    if(isNatural($patHand->{'cards'})) {
			$patHand->{'won'} = "bj";
		    } else {
			$patHand->{'won'} = "yes";
		    }
		} elsif($pTot < $dealerBest) {
print "DO I GET HERE?3b\n";
		    $patHand->{'lost'} = "yes";
		} else {
print "DO I GET HERE?3c\n";
		    $patHand->{'pushed'} = "yes";
		}
	    }
	}
	print "PATPLACES\n";
	print Dumper(\@patPlaces);


	print "REMAINING: " . scalar @deck . "\n";
	print "CUTPOINT: $fPenetrationCard\n";
	print "RC: $runningCount\n";
	exit(0);

    }
}
##################################################################

### sub isAce
sub isAce {
    my $input = shift(@_);
    if(getRank($input) eq 'a') {
	return 1;
    } else {
	return 0;
    }
}


### sub getRank
sub getRank {
    my $input = substr(shift(@_),0,1);
    if($input =~ /[kqjt]/) {
	return 't';
    } else {
	return $input;
    }
}


### sub deal
sub deal {
    my $deckRef = shift(@_);
    my $discardsRef = shift(@_);

    if(scalar @{$deckRef} < 1) {
#FIXME: reshuffle discards here.	
	print "ERROR: Deck running out.\n";
	exit(0);
    } else {
	return shift @{$deckRef};
    }

}


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
	if(isAce($rank)) {
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
