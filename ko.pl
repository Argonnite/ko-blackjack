use List::Util qw/shuffle sum/;
use Data::Dumper;
use Scalar::Util qw/looks_like_number/;
$Data::Dumper::Sortkeys = 1;

my $DEBUG = 1;

#FIXME: create a param object.
#FIXME: test nsa==1 and aa.


#my $nDecks = 8;      # size of shoe
#my $cut = 1;         # penetration in number of decks unseen
my $nDecks = 1;      # size of shoe
my $cut = 0.4;       # penetration in number of decks unseen
my $nShoesToRun = 1; # number of shoes to simulate
my $spreadMin;       # limits on the betting spread
my $spreadMax;
my $spotsLimit = 2;  # number of those seated
my $esAllowed = 0;   # early surrender
my $lsAllowed = 0;   # late surrender
my $rsa = 1;         # resplit aces allowed
my $rs = 0;          # resplit any allowed
my $rsa3 = 1;        # resplit aces once
my $rs3 = 1;         # resplit once more
my $das = 0;         # doubling after splitting aces
my $ds = 1;          # doubling after splitting
my $da = 1;          # double down on any two cards
my $hsa = 0;         # can hit after splitting aces
my $nsa = 0;         # no splitting of aces
my $nrs = 0;         # no resplitting
my $h17 = 1;         # dealer hits soft 17
my $bjPayout = 1.5;  # blackjack pays either 6:5 or 3:2


my %table = ();
generate(\%table); ### basic strategy


for(my $nCurrentShoe = 0; $nCurrentShoe < $nShoesToRun; ++$nCurrentShoe) {

    ### shuffle
    my $fPenetrationCard = 52.0 * $cut; # when shoe becomes smaller than this, reshuffle.
    my @deck;
    my @ranks = qw/a k q j t 9 8 7 6 5 4 3 2/;
    my @suits = qw/s h d c/;
    for(my $i = 0; $i < $nDecks; ++$i) {
        foreach my $suit (@suits) {
            foreach my $rank (@ranks) {
                push @deck,$rank . $suit;
            }
        }
    }
    @deck = shuffle @deck;
    my @discards = ();


#    if($DEBUG) {
#    ### load a test
###	my $command = do { local $/; open(I,'TESTS/sp_line3_test1.txt'); <I> };
###	my $command = do { local $/; open(I,'TESTS/dd_line6_test1.txt'); <I> };
#    my $command = do { local $/; open(I,'TESTS/current_bug.txt'); <I> };
#    eval $command;
#    }


    if($DEBUG) {
        print "DECK:\n";
        print Dumper(\@deck);
    }


    my $nRound = 0;
    while(scalar @deck > $fPenetrationCard) { #deal a round

        if($DEBUG) {
            print "\nNEW DEAL $nRound\n";	
        }

        my $preDealRC = 4 * $nDecks - KOValAry(\@deck);


        ### dealer's cards
        my @dealer;
        push @dealer,deal(\@deck,\@discards);
        push @dealer,deal(\@deck,\@discards);


        ### players' cards
        my @places;
        my @cards;
        my $bet = 1;
        my @splitsCnt;
        my $surrenderRC;
        if(getRank($dealer[0] eq 'a')) {
            $surrenderRC = $preDealRC - 1;
        }

        for(my $i = 0; $i < $spotsLimit; ++$i) {
            @cards = ();
            push @cards,deal(\@deck,\@discards);
            push @cards,deal(\@deck,\@discards);
            push @places,{'bet' => $bet, 'cards' => [$cards[0],$cards[1]], 'pos' => $i, 'splitID' => 0, 'hist' => join('',@dealer) . '/' . join('',@cards), 'round' => $nRound, 'shoe' => $nCurrentShoe, 'preDealRC' => $preDealRC, 'surrenderRC' => $surrenderRC};
            $splitsCnt[$i] = 0;
        }


        ### players' hits
        my @patPlaces;
        my @bustedPlaces;


#FIXME: ask for insurance here if ace shows.

        my $bDealerHasBJ = 0;
        if(isNatural(\@dealer)) { #process dealer bj.
            @patPlaces = @places;
            @places = ();
            $bDealerHasBJ = 0;
        } else {#handle player actions normally.
            while (scalar @places) {
                my $hand = shift @places;
                my $action;

                my $preActionRC = 4 * $nDecks - KOValAry(\@deck);
                $hand->{'preActionRC'} = $preActionRC;


                ## splits handling
                $action = getAction(\@dealer, $hand, \%table, 'splitting');
                if($action eq 'sp') {
                    if(isPair($hand->{'cards'})) {
                        if(isAce($hand->{'cards'}->[0])) {
                            if($nsa == 0) { #splitting aces allowed.
                                if($hsa == 0 && $rsa == 0 && $splitsCnt[$hand->{'pos'}] == 0) {
                                    #line 3
                                    #split, unshift new, incr splitsCnt, pat current
                                    ($hand, my $newSpotRef) = splitHand($hand,\@deck,\@discards);
                                    ++$splitsCnt[$hand->{'pos'}];
                                    unshift @places,$newSpotRef;
                                    push @patPlaces,$hand; # "current" is now pat.
                                    undef $hand;
                                } elsif($hsa == 0 && $rsa == 0 && $splitsCnt[$hand->{'pos'}] == 1) {
                                    #line 4
                                    #pat current
                                    push @patPlaces,$hand;
                                    undef $hand;
                                } elsif($hsa == 0 && $rsa == 0 && $splitsCnt[$hand->{'pos'}] >= 2) {
                                    #line 5
                                    #ERROR
                                } elsif($hsa == 1 && $rsa == 0 && $splitsCnt[$hand->{'pos'}] == 0) {
                                    #line 6
                                    #split, unshift new, incr splitsCnt, goto decision
                                    ($hand, my $newSpotRef) = splitHand($hand,\@deck,\@discards);
                                    ++$splitsCnt[$hand->{'pos'}];
                                    unshift @places,$newSpotRef;
                                } elsif($hsa == 1 && $rsa == 0 && $splitsCnt[$hand->{'pos'}] == 1) {
                                    #line 7
                                    #goto decision
                                } elsif($hsa == 0 && $rsa == 1 && $rsa3 == 0) {
                                    #line 8
                                    #split, unshift new, pat current
                                    ($hand, my $newSpotRef) = splitHand($hand,\@deck,\@discards);
                                    ++$splitsCnt[$hand->{'pos'}];
                                    unshift @places,$newSpotRef;
                                    push @patPlaces,$hand; # "current" is now pat.
                                    undef $hand;
                                } elsif($hsa == 0 && $rsa == 1 && $rsa3 == 1 && ($splitsCnt[$hand->{'pos'}] == 0 || $splitsCnt[$hand->{'pos'}] == 1)) {
                                    #line 9
                                    #split, unshift new, incr splitsCnt, pat current
                                    ($hand, my $newSpotRef) = splitHand($hand,\@deck,\@discards);
                                    ++$splitsCnt[$hand->{'pos'}];
                                    unshift @places,$newSpotRef;
                                    push @patPlaces,$hand; # "current" is now pat.
                                    undef $hand;
                                } elsif($hsa == 0 && $rsa == 1 && $rsa3 == 1 && $splitsCnt[$hand->{'pos'}] == 2) {
                                    #line 10
                                    #pat current
                                    push @patPlaces,$hand; # "current" is now pat.
                                    undef $hand;
                                } elsif($hsa == 0 && $rsa == 1 && $rsa3 == 1 && $splitsCnt[$hand->{'pos'}] >= 3) {
                                    #line 11
                                    #ERROR
                                } elsif($hsa == 1 && $rsa == 1 && $rsa3 == 0) {
                                    #line 12
                                    #split, unshift new, goto decision
                                    ($hand, my $newSpotRef) = splitHand($hand,\@deck,\@discards);
                                    ++$splitsCnt[$hand->{'pos'}];
                                    unshift @places,$newSpotRef;
                                } elsif($hsa == 1 && $rsa == 1 && $rsa3 == 1 && ($splitsCnt[$hand->{'pos'}] == 0 || $splitsCnt[$hand->{'pos'}] == 1)) {
                                    #line 13
                                    #split, unshift new, incr splitsCnt, goto decision
                                    ($hand, my $newSpotRef) = splitHand($hand,\@deck,\@discards);
                                    ++$splitsCnt[$hand->{'pos'}];
                                    unshift @places,$newSpotRef;
                                } elsif($hsa == 1 && $rsa == 1 && $rsa3 == 1 && $splitsCnt[$hand->{'pos'}] == 2) {
                                    #line 14
                                    #goto decision
                                } elsif($hsa == 1 && $rsa == 1 && $rsa3 == 1 && $splitsCnt[$hand->{'pos'}] >= 3) {
                                    #line 15
                                    #ERROR
                                } else {
                                    #FAILTHROUGH
                                }
                            } #else gotoDecision
                        } else { #~isA & isPair
                            if($nrs == 1 && $splitsCnt[$hand->{'pos'}] == 0) {
                                #line 19
                                #split, unshift new, incr splitsCnt, goto decision
                                ($hand, my $newSpotRef) = splitHand($hand,\@deck,\@discards);
                                ++$splitsCnt[$hand->{'pos'}];
                                unshift @places,$newSpotRef;
                            } elsif($nrs == 1 && $splitsCnt[$hand->{'pos'}] == 1) {
                                #line 20
                                #goto decision
                            } elsif($nrs == 1 && $splitsCnt[$hand->{'pos'}] == 2) {
                                #line 21
                                #ERROR
                            } elsif($nrs == 0 && $rs3 == 0) {
                                #line 22
                                #split, unshift new, goto decision
                                ($hand, my $newSpotRef) = splitHand($hand,\@deck,\@discards);
                                ++$splitsCnt[$hand->{'pos'}];
                                unshift @places,$newSpotRef;
                            } elsif($nrs == 0 && $rs3 == 1 && $splitsCnt[$hand->{'pos'}] == 0) {
                                #line 23
                                #split, unshift new, incr splitsCnt, goto decision
                                ($hand, my $newSpotRef) = splitHand($hand,\@deck,\@discards);
                                ++$splitsCnt[$hand->{'pos'}];
                                unshift @places,$newSpotRef;
                            } elsif($nrs == 0 && $rs3 == 1 && $splitsCnt[$hand->{'pos'}] == 1) {
                                #line 24
                                #split, unshift new, incr splitsCnt, goto decision
                                ($hand, my $newSpotRef) = splitHand($hand,\@deck,\@discards);
                                ++$splitsCnt[$hand->{'pos'}];
                                unshift @places,$newSpotRef;
                            } elsif($nrs == 0 && $rs3 == 1 && $splitsCnt[$hand->{'pos'}] == 2) {
                                #line 25
                                #goto decision
                            } elsif($nrs == 0 && $rs3 == 1 && $splitsCnt[$hand->{'pos'}] >= 3) {
                                #line 26
                                #ERROR
                            } else {
                                #FAILTHROUGH
                            }
                        }
                    }
                } # if action eq 'sp'




                ## doubles handling
                if(defined $hand && scalar @{$hand->{'cards'}} == 2) {
                    if($action eq 'dh' or $action eq 'd' or $action eq 'ds') {
                        if(hasAce($hand)) {
                            $action = getAction(\@dealer, $hand, \%table, 'doubling');
                            if($da == 0) {
                                #line 3
                                #pat current
                            } elsif($da == 1 && $das == 1 && $ds == 1) {
                                #line 4
                                #dd, pat current
                                my $ddCard = deal(\@deck,\@discards);
                                push $hand->{'cards'},$ddCard;
                                $hand->{'bet'} = 2.0 * $hand->{'bet'};
                                $hand->{'hist'} = $hand->{'hist'} . 'dd' . $ddCard;
                                if(isBusted($hand->{'cards'})) {
                                    push @bustedPlaces,$hand; # "current" is now busted.
                                } else {
                                    push @patPlaces,$hand; # "current" is now pat.
                                }
                                undef $hand;
                            } elsif($das == 1 && $ds == 0) {
                                #line 5
                                #ERROR
                            } elsif($da == 1 && $das == 0 && $ds == 1 && $splitsCnt[$hand->{'pos'}] == 0) {
                                #line 6
                                #dd, pat current
                                my $ddCard = deal(\@deck,\@discards);
                                push $hand->{'cards'},$ddCard;
                                $hand->{'bet'} = 2.0 * $hand->{'bet'};
                                $hand->{'hist'} = $hand->{'hist'} . 'dd' . $ddCard;
                                if(isBusted($hand->{'cards'})) {
                                    push @bustedPlaces,$hand; # "current" is now busted.
                                } else {
                                    push @patPlaces,$hand; # "current" is now pat.
                                }
                                undef $hand;
                            } elsif($da == 1 && $das == 0 && $ds == 1 && $splitsCnt[$hand->{'pos'}] >= 1) {
                                #line 7
                                #goto decision
                            } else {
                                #FAILTHROUGH
                            }
                        } else { #~hasAce
                            if($ds == 0) {
                                #line 11
                                #goto decision
                            } elsif($ds == 1) {
                                #line 12
                                #dd, pat current
                                my $ddCard = deal(\@deck,\@discards);
                                push $hand->{'cards'},$ddCard;
                                $hand->{'bet'} = 2.0 * $hand->{'bet'};
                                $hand->{'hist'} = $hand->{'hist'} . 'dd' . $ddCard;
                                if(isBusted($hand->{'cards'})) {
                                    push @bustedPlaces,$hand; # "current" is now busted.
                                } else {
                                    push @patPlaces,$hand; # "current" is now pat.
                                }
                                undef $hand;
                            } else {
                                #FAILTHROUGH
                            }
                        }
                    }
                }



                ## iterate s,h,su on current hand.
                undef $action;
                while(defined $hand) {
                    $action = getAction(\@dealer, $hand, \%table, 'normal');
                    if($action eq 'sp') {
                        print "ERROR:  splits were supposed to be handled earlier.\n";
                        exit(1);
                    } elsif($action eq 'd') {
                        print "ERROR:  doubledowns were supposed to be handled earlier.\n";
                        exit(1);
                    } elsif($action eq 'dh') { # treat as hit
                        my $newCard = deal(\@deck,\@discards);
                        push $hand->{'cards'},$newCard;
                        $hand->{'hist'} = $hand->{'hist'} . $newCard;
                        if(isBusted($hand->{'cards'})) {
                            push @bustedPlaces,$hand; # "current" is now busted.
                            undef $action;
                            undef $hand;
                        }
                    } elsif($action eq 'ds') { # treat as stand
                        push @patPlaces,$hand;
                        undef $hand;
                    } elsif($action eq 's') {
                        push @patPlaces,$hand;
                        undef $hand;
                    } elsif($action eq 'h') {
                        my $newCard = deal(\@deck,\@discards);
                        push $hand->{'cards'},$newCard;
                        $hand->{'hist'} = $hand->{'hist'} . $newCard;
                        if(isBusted($hand->{'cards'})) {
                            push @bustedPlaces,$hand; # "current" is now busted.
                            undef $action;
                            undef $hand;
                        }
                    } elsif($action eq 'su') {
                        if($esAllowed == 1 || $lsAllowed == 1) {
#FIXME: flesh out surrenders.
#FIXME: su only on 2 cards?
                        } else {
                            # treat as hit
                            my $newCard = deal(\@deck,\@discards);
                            push $hand->{'cards'},$newCard;
                            $hand->{'hist'} = $hand->{'hist'} . $newCard;
                            if(isBusted($hand->{'cards'})) {
                                push @bustedPlaces,$hand; # "current" is now busted.
                                undef $action;
                                undef $hand;
                            }
                        }
                    } else {
                        #FAILTHROUGH
                    }
                }
            } # foreach @places




            ### dealer actions
            my @dealerTotalsAry = getTotals(\@dealer);
            my $dealerBest = bestTotal(\@dealerTotalsAry);

            while(($dealerBest < 17 or ( ($h17 == 1) and ($dealerBest == 17 and isSoft(\@dealer)) ) ) and not isBusted(\@dealer)) {
                my $dealerCard = deal(\@deck,\@discards);
                push @dealer,$dealerCard;
                @dealerTotalsAry = getTotals(\@dealer);
                $dealerBest = bestTotal(\@dealerTotalsAry);
            }
        }



        ### collections, payouts, and discards

        # collect on busted hands.
        foreach my $bustedHand (@bustedPlaces) {
            $bustedHand->{'change'} = -$bustedHand->{'bet'};
        }

        # determine winners.
        if($bDealerHasBJ == 1) {
            foreach my $patHand (@patPlaces) {
                if(isNatural($patHand->{'cards'})) {
                    $patHand->{'change'} = 0;
                } else {
                    $patHand->{'change'} = -$patHand->{'bet'};
                }
            }
        } elsif(isBusted(\@dealer)) {
            foreach my $patHand (@patPlaces) {
                if(isNatural($patHand->{'cards'})) {
                    if($splitsCnt[$patHand->{'pos'}] == 0) {  #ensuring it's not a fake "split" bj
                        $patHand->{'change'} = $bjPayout * $patHand->{'bet'};
                    } else {
                        $patHand->{'change'} = $patHand->{'bet'};
                    }
                } else {
                    $patHand->{'change'} = $patHand->{'bet'};
                }
            }
        } else {
            foreach my $patHand (@patPlaces) {
                my @tmp = getTotals($patHand->{'cards'});
                my $pTot = bestTotal(\@tmp);
                if($pTot > $dealerBest) {
                    if(isNatural($patHand->{'cards'})) {
                        $patHand->{'change'} = $bjPayout * $patHand->{'bet'};
                    } else {
                        $patHand->{'change'} = $patHand->{'bet'};
                    }
                } elsif($pTot < $dealerBest) {
                    $patHand->{'change'} = -$patHand->{'bet'};
                } else {
                    $patHand->{'change'} = 0;
                }
            }
        }


        if($DEBUG) {
            print "FINAL PATPLACES\n";
            print Dumper(\@patPlaces);
            print "FINAL BUSTEDPLACES\n";
            print Dumper(\@bustedPlaces);
            print "FINAL DEALER: " . join(' ',@dealer) . "\n";
            print "STUBSIZE: " . scalar @deck . " (" . (scalar @deck)/(52.0*$nDecks) . ")\n";
        }
        ++$nRound;
    }
}





##################################################################

### sub getAction
sub getAction {
  (my $dealerRef, my $handRef, my $tableRef, my $tableSection) = @_;

  my $action;
  my $pRank = getRank($handRef->{'cards'}->[0]);
  my $dRank = getRank($dealerRef->[0]);

  my @totalsAry = getTotals($handRef->{'cards'});
  my $bestTotal = bestTotal(\@totalsAry);
  if($bestTotal == -1) {
      print "ERROR: busted lookup.\n";
      print "SECTION: $tableSection\n";
      print Dumper($handRef);
      exit(1);
  }

  if($tableSection eq 'splitting' and isPair($handRef->{'cards'})) { #split?
      $action = $tableRef->{$pRank . $pRank}->{$dRank};
  } elsif(isSoft($handRef->{'cards'})) { #soft?
      if($bestTotal >= 19) {
	  $action = 's';
      } else {
	  $action = $tableRef->{'s' . $bestTotal}->{$dRank};
      }
  } elsif(!isSoft($handRef->{'cards'})) { #it must be hard
      if($bestTotal >= 17) {
	  $action = 's';
      } else {
	  if(not exists $tableRef->{$bestTotal}->{$dRank}) {
	      $action = $tableRef->{"h" . $bestTotal}->{$dRank};
	  } else {
	      $action = $tableRef->{$bestTotal}->{$dRank};
	  }
      }
  } elsif(not defined $action) {
      print "ERROR: action undefined.\n";
      exit(1);
  }
  return $action;
}


### sub splitHand
sub splitHand {
    (my $handRef, my $deckRef, my $discardsRef) = @_;

    my %newSpot = %{$handRef};
    my $card0 = $handRef->{'cards'}->[0];
    my $card1 = $handRef->{'cards'}->[1];

    my $newCard0 = deal($deckRef,$discardsRef);
    my $newCard1 = deal($deckRef,$discardsRef);

    $handRef->{'cards'} = [$card0, $newCard0]; # dereferencing
    $newSpot{'cards'} = [$card1, $newCard1];

    $handRef->{'hist'} = $handRef->{'hist'} . 'sp' . $card0 . $newCard0;
    $newSpot{'hist'} = $newSpot{'hist'} . 'sp' . $card1 . $newCard1;

    $newSpot{'bet'} = $handRef->{'bet'}; # not-dereferencing
    $newSpot{'pos'} = $handRef->{'pos'};
    $newSpot{'splitID'} = $handRef->{'splitID'} + 1;

    return ($handRef, \%newSpot);
}


### sub hasAce
sub hasAce {
    my $handRef = shift(@_);
    if(isAce($handRef->{'cards'}->[0]) or isAce($handRef->{'cards'}->[1])) {
#FIXME: what if more than 2 cards?
	return 1;
    } else {
	return 0;
    }
}


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
        print "ERROR: Currently not dealing from discards on runouts.\n";
        exit(1);
    } else {
        return shift @{$deckRef};
    }
}


### sub KOValCard
sub KOValCard {
    my $rank = getRank(shift @_);
    if($rank eq 't' or $rank eq 'a') {
	return -1;
    } elsif ($rank > 1 and $rank < 8) {
	return 1;
    } else {
	return 0;
    }
}


### sub KOValAry
sub KOValAry {
    my $cardAryRef = shift(@_);

    my $runningTotal = 0;
    foreach my $card (@{$cardAryRef}) {
	$runningTotal += KOValCard($card);
    }
    return $runningTotal;
}


### sub generate
sub generate {
    my $tableRef = shift(@_);
    my @textTable;
# DEALER UPCARD            2  3  4  5  6  7  8  9  t  a
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
    push @textTable,"h17   s  s  s  s  s  s  s  s  s  s";
    push @textTable,"h16   s  s  s  s  s  h  h su su su";
    push @textTable,"h15   s  s  s  s  s  h  h  h su  h";
    push @textTable,"h14   s  s  s  s  s  h  h  h  h  h";
    push @textTable,"h13   s  s  s  s  s  h  h  h  h  h";
    push @textTable,"h12   s  s  s  s  s  h  h  h  h  h";
    push @textTable," 11  dh dh dh dh dh dh dh dh dh  h";
    push @textTable," 10  dh dh dh dh dh dh dh dh  h  h";
    push @textTable,"  9   h dh dh dh dh  h  h  h  h  h";
    push @textTable,"  8   h  h  h  h  h  h  h  h  h  h";
    push @textTable,"  7   h  h  h  h  h  h  h  h  h  h";
    push @textTable,"  6   h  h  h  h  h  h  h  h  h  h";
    push @textTable,"  5   h  h  h  h  h  h  h  h  h  h";
    push @textTable,"  4   h  h  h  h  h  h  h  h  h  h";
    push @textTable,"  3   h  h  h  h  h  h  h  h  h  h";
    push @textTable,"  2   h  h  h  h  h  h  h  h  h  h";
    push @textTable,"s19   s  s  s  s  s  s  s  s  s  s";
    push @textTable,"s18   s ds ds ds ds  s  s  h  h  h";
    push @textTable,"s17   h dh dh dh dh  h  h  h  h  h";
    push @textTable,"s16   h  h dh dh dh  h  h  h  h  h";
    push @textTable,"s15   h  h dh dh dh  h  h  h  h  h";
    push @textTable,"s14   h  h  h dh dh  h  h  h  h  h";
    push @textTable,"s13   h  h  h dh dh  h  h  h  h  h";

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
