# @title Default, Keyword, *args and **kwargs
# @category Basics
# @kind Console program
# @where Save as arguments.py and run: python3 arguments.py
# @keywords python default arguments, python keyword arguments, python *args, python **kwargs
# @about Shows all the ways to pass values into a function, from defaults to any number of extras.

# Default values are used when you don't give one
def make_pizza(size="medium", cheese=True):
    print(f"A {size} pizza {'with' if cheese else 'without'} cheese")


make_pizza()
make_pizza("large")
make_pizza(cheese=False)            # keyword argument: say which one by name
make_pizza(cheese=False, size="small")


# *args collects any number of extra values into a tuple
def add_all(*numbers):
    return sum(numbers)


print("add_all(1, 2) =", add_all(1, 2))
print("add_all(1, 2, 3, 4, 5) =", add_all(1, 2, 3, 4, 5))


# **kwargs collects extra named values into a dictionary
def build_character(name, **stats):
    print(f"Character: {name}")
    for stat, value in stats.items():
        print(f"  {stat} = {value}")


build_character("Knight", strength=9, speed=4, magic=1)


# You can also "unpack" a list or dict into a function call
numbers = [10, 20, 30]
print("Unpacked list:", add_all(*numbers))
settings = {"size": "huge", "cheese": True}
make_pizza(**settings)
