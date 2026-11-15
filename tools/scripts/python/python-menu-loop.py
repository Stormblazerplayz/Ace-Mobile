# @title Menu Loop
# @category Basics
# @kind Console program
# @where Save as menu.py and run: python3 menu.py
# @keywords python menu, python while true loop, python user choices, python command menu
# @about A program that shows a menu, does what you pick, and keeps going until you choose Quit.

shopping = []

while True:
    print("\n=== Shopping List ===")
    print("1. Add an item")
    print("2. Show the list")
    print("3. Remove an item")
    print("4. Quit")
    choice = input("Pick 1 to 4: ").strip()

    if choice == "1":
        item = input("What should I add? ").strip()
        if item:
            shopping.append(item)
            print(f"Added {item}.")
    elif choice == "2":
        if not shopping:
            print("The list is empty.")
        for number, item in enumerate(shopping, start=1):
            print(f"{number}. {item}")
    elif choice == "3":
        item = input("What should I remove? ").strip()
        if item in shopping:
            shopping.remove(item)
            print(f"Removed {item}.")
        else:
            print("That's not on the list.")
    elif choice == "4":
        print("Bye! Happy shopping.")
        break  # leave the while loop
    else:
        print("Please type 1, 2, 3 or 4.")
