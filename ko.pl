use List::Util qw/shuffle sum/;
use Data::Dumper;
use Scalar::Util qw/looks_like_number/;


my $nDecks = 8;
my $cut;            # penetration
my $nTrials;        # number of shoes to simulate
my $spreadMin;      # limits on the betting spread
my $spreadMax;
my $RCmin;          # running min count reached for the shoe
my $RCmax;          # running max count reached for the shoe
my $rsLimit = 3;    # limit on resplits.  -1 if unlimited.
my $spotsLimit = 2; # number of those seated



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
    push @places,{('bet' => $bet, 'cards' => [pop @deck, pop @deck], 'pos' => $i, 'splits' => 0)};
}



#
####testes
#my @blah = ('as','6s','th','as');
#print Dumper(\@blah);
#@blah = getTotals(\@blah);
#print Dumper(\@blah);
#exit(0);
#
#
#



my @patPlaces;
while (scalar @places) {
    my $hand = pop @places;
    print Dumper($hand);
#    print Dumper(\@places);
    print scalar @deck . " cards remaining.\n";
    my @totals = getTotals($hand->{'cards'});
    print Dumper(\@totals);
}


####sub _addIt
#sub _addIt {
#    my @cards = @{$_[0]};
#    my @totals = @{$_[1]};
#
#    my $card = shift @cards;
#
#    my $rank = substr($card,0,1);
#    print "Card is $card.\n";
#    if($rank eq 'a') {
#	print "It's an ace.\n";
#    } elsif($rank eq 't') {
#	print "It's a ten.\n";
#    } elsif(!looks_like_number($rank)) {
#	print "It's a ten.\n";
#    } elsif(looks_like_number($rank)) {
#	print "It's number.\n";
#    } else {
#	print "ERROR.\n";
#    }
#}


###sub getTotals
sub getTotals {
    my $cards = shift(@_);
    my @sums = (0);
#    _addIt($cards,\@sums);

    foreach my $card (@{$cards}) {
	my @newSums = ();
	my $rank = substr($card,0,1);
	print "Card is $card.\n";
	if($rank eq 'a') {
	    print "It's an ace.\n";
	    foreach my $total (@sums) {  ### add ones
		push @newSums,($total + 1);
	    }
	    foreach my $total (@sums) {  ### add elevens
		push @newSums,($total + 11);
	    }
	} elsif($rank eq 't') {
	    print "It's a ten.\n";
	    foreach my $total (@sums) {
		push @newSums,($total + 10);
	    }
	} elsif(!looks_like_number($rank)) {
	    print "It's a ten.\n";
	    foreach my $total (@sums) {
		push @newSums,($total + 10);
	    }
	} elsif(looks_like_number($rank)) {
	    print "It's number.\n";
	    foreach my $total (@sums) {
		push @newSums,($total + $rank);
	    }
	} else {
	    print "ERROR.\n";
	}
#print Dumper(\@sums);
	@sums = @newSums;
#print Dumper(\@sums);
#print "YEAH\n";
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
    

print "BLAHHHHH\n";
print Dumper(\@patPlaces);





###sub isBusted
###sub isSoft
###sub isPair

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
#99   sp sp sp sp sp sp sp sp  s  s
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
