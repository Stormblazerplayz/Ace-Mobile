# @title Blackjack
# @category Games
# @kind Console program
# @where Save as blackjack.py and run: python3 blackjack.py
# @keywords python blackjack, python 21 card game, python deck of cards, python dealer game
# @about Play the card game 21 against a dealer: get closer to 21 than the dealer without going over.

import random

SUITS = ["hearts", "diamonds", "clubs", "spades"]
RANKS = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]


def new_deck():
    deck = [(rank, suit) for suit in SUITS for rank in RANKS]
    random.shuffle(deck)
    return deck


def hand_value(hand):
    total, aces = 0, 0
    for rank, _ in hand:
        if rank == "A":
            total += 11
            aces += 1
        elif rank in ("J", "Q", "K"):
            total += 10
        else:
            total += int(rank)
    while total > 21 and aces:  # an ace can count as 1 instead of 11
        total -= 10
        aces -= 1
    return total


def show(name, hand):
    cards = ", ".join(f"{r} of {s}" for r, s in hand)
    print(f"{name}: {cards}  (total {hand_value(hand)})")


chips = 100
while chips > 0:
    print(f"\nYou have {chips} chips. Each hand costs 10.")
    deck = new_deck()
    player = [deck.pop(), deck.pop()]
    dealer = [deck.pop(), deck.pop()]
    print(f"Dealer shows: {dealer[0][0]} of {dealer[0][1]}")

    while hand_value(player) < 21:
        show("You", player)
        if input("Hit or stand? (h/s) ").strip().lower() != "h":
            break
        player.append(deck.pop())
    show("You", player)

    if hand_value(player) > 21:
        print("Bust! You went over 21.")
        chips -= 10
    else:
        while hand_value(dealer) < 17:  # dealer must hit below 17
            dealer.append(deck.pop())
        show("Dealer", dealer)
        p, d = hand_value(player), hand_value(dealer)
        if d > 21 or p > d:
            print("You win!")
            chips += 10
        elif p == d:
            print("Push (tie). Nobody wins.")
        else:
            print("Dealer wins.")
            chips -= 10

    if input("Play another hand? (y/n) ").strip().lower() != "y":
        break

print(f"You leave the table with {chips} chips.")
