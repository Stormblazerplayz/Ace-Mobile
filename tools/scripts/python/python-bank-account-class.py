# @title Bank Account Class
# @category Basics
# @kind Console program
# @where Save as bank.py and run: python3 bank.py
# @keywords python bank account, python class example, python deposit withdraw, python raise error
# @about A BankAccount class that can deposit, withdraw, refuse overdrafts and keep a history.

class BankAccount:
    def __init__(self, owner, balance=0):
        self.owner = owner
        self.balance = balance
        self.history = []

    def deposit(self, amount):
        if amount <= 0:
            raise ValueError("Deposit must be more than 0")
        self.balance += amount
        self.history.append(f"+{amount}")

    def withdraw(self, amount):
        if amount > self.balance:
            # raise makes an error on purpose so the caller knows something went wrong
            raise ValueError(f"Not enough money! Balance is only {self.balance}")
        self.balance -= amount
        self.history.append(f"-{amount}")

    def show(self):
        print(f"{self.owner}'s balance: ${self.balance}  history: {', '.join(self.history) or 'none'}")


account = BankAccount("Storm", 20)
account.deposit(50)
account.withdraw(15)
account.show()

# try/except catches the error so the program doesn't crash.
try:
    account.withdraw(1000)
except ValueError as error:
    print("Oops:", error)

try:
    account.deposit(-5)
except ValueError as error:
    print("Oops:", error)

account.show()
