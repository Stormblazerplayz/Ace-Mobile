# @title Lemonade Stand
# @category Games
# @kind Console program
# @where Save as lemonade.py and run: python3 lemonade.py
# @keywords python lemonade stand, python business game, python money simulation, python weather sales
# @about Run a lemonade stand for 7 days: buy lemons, set your price and watch the weather.

import random

money = 10.00
lemons = 0

for day in range(1, 8):
    weather = random.choice(["sunny", "hot", "cloudy", "rainy"])
    lemon_cost = round(random.uniform(0.20, 0.50), 2)
    print(f"\n=== Day {day} === Weather: {weather}. Money: ${money:.2f}. Lemons: {lemons}")
    print(f"Lemons cost ${lemon_cost:.2f} each today. One lemon makes one cup.")

    text = input("How many lemons to buy? ").strip()
    buy = int(text) if text.isdigit() else 0
    if buy * lemon_cost > money:
        buy = int(money // lemon_cost)
        print(f"You can only afford {buy}.")
    money -= buy * lemon_cost
    lemons += buy

    text = input("Price per cup in cents (like 50)? ").strip()
    price = int(text) / 100 if text.isdigit() else 0.50

    # More customers on hot days, fewer when the price is high
    base = {"hot": 40, "sunny": 30, "cloudy": 15, "rainy": 5}[weather]
    customers = max(0, int(base * (1.5 - price) + random.randint(-5, 5)))
    sold = min(customers, lemons)
    lemons -= sold
    money += sold * price
    print(f"{customers} people wanted lemonade. You sold {sold} cups and made ${sold * price:.2f}.")
    if lemons:
        spoiled = lemons // 2
        lemons -= spoiled
        print(f"{spoiled} leftover lemons went bad overnight.")

print(f"\nAfter 7 days you have ${money:.2f}. You started with $10.00.")
print("Business tycoon!" if money > 10 else "Better luck next summer!")
