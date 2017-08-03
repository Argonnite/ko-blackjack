# ko-blackjack
Placeholder for an eventual Knock Out count trainer.


Task List
---------

Engine

  Deck Function Library
  
    rigDeck 
    
      -- Input a count and stub size (nDecks) and return a random deck meeting KO count if possible### sub getAction 
      
      -- Return decision based on basic strategy lookup.
      
    splitHand 
    
      -- Input a hand plus deck and discards, split into two hands and deal until 2 cards per han### sub hasAce 
      
      -- Input a hand, return 1 if it contains an ace or 0 otherwise.
      
    isAce
    
      -- Input card, return 1 if it's an Ace or 0 otherwise.
      
    getRank 
    
      -- Input card, return its rank.
      
    deal 
    
      -- Input deck and discards, remove a card from deck and return that card.  Discards currently no
      
    KOValCard 
    
      -- Input card, return its KO value.
      
    KOValAry 
    
      -- Input an array of cards and return its KO total.
      
    generate 
    
      -- Initialize a basic strategy lookup table.
      
    bestTotal
    
    isSoft
    
    isPair
    
    isNatural
    
    getTotals
    
    isBusted
    
  Conditional Control Flow (ugly switch-case?)
  
    hsa
    
    rsa
    
    nsr
    
    etc...

UI/Forms

  Dealer spot
  
  Player spots
  
  Analysis popups or strategy wizard
  
    Current count
    
    Probabilities
    
    Win rate
    
  House conditions menu
  
  Communications with Engine
  

