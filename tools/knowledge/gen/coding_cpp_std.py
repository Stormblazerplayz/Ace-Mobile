"""Builds data/coding/gen_cpp_std.txt: short explanations of C++ standard library members
(containers, strings, algorithms, math and more), written by hand from the C++ standard and
turned into several kid-style wordings each. No network needed."""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
KNOW = os.path.dirname(HERE)
sys.path.insert(0, KNOW)
sys.path.insert(0, HERE)
from check_data import keyset, norm  # noqa: E402
from coding_common import existing  # noqa: E402

OUT = os.path.join(KNOW, "data", "coding", "gen_cpp_std.txt")

# (object name, header, {member: explanation}). Explanations start with the call itself.
MEMBERS = [
    ("vector", "<vector>", {
        "push_back": "`v.push_back(x)` adds x to the end of the vector, growing it by one.",
        "emplace_back": "`v.emplace_back(args)` builds a new element right at the end of the vector from the arguments, which can skip a copy.",
        "pop_back": "`v.pop_back()` removes the last element. Calling it on an empty vector is undefined behavior, so check `empty()` first.",
        "size": "`v.size()` returns how many elements are in the vector, as an unsigned `size_t`.",
        "empty": "`v.empty()` returns true if the vector has no elements. It does not clear the vector; that is `clear()`.",
        "clear": "`v.clear()` removes every element, making the size 0.",
        "at": "`v.at(i)` returns the element at index i, but throws `std::out_of_range` if i is too big, unlike `v[i]` which does not check.",
        "front": "`v.front()` returns the first element. Do not call it on an empty vector.",
        "back": "`v.back()` returns the last element. Do not call it on an empty vector.",
        "insert": "`v.insert(v.begin() + i, x)` puts x before position i, shifting later elements along.",
        "erase": "`v.erase(v.begin() + i)` removes the element at index i and shifts the rest down. It can also erase a range of iterators.",
        "resize": "`v.resize(n)` changes the size to n, adding default values or cutting elements off the end.",
        "reserve": "`v.reserve(n)` sets aside memory for at least n elements so pushing that many does not reallocate. The size does not change.",
        "capacity": "`v.capacity()` returns how many elements fit before the vector must reallocate memory. It is at least `size()`.",
        "data": "`v.data()` returns a pointer to the first element of the vector's underlying array.",
        "begin": "`v.begin()` returns an iterator to the first element, and `v.end()` one past the last. Algorithms like `std::sort` take these.",
        "swap": "`a.swap(b)` swaps the contents of two vectors very quickly, without copying elements.",
        "shrink_to_fit": "`v.shrink_to_fit()` asks the vector to give back unused capacity. It is a request the library may ignore.",
        "assign": "`v.assign(n, x)` replaces the contents with n copies of x. It can also copy from a pair of iterators.",
    }),
    ("string", "<string>", {
        "length": "`s.length()` and `s.size()` both return the number of characters in a std::string.",
        "substr": "`s.substr(start, count)` returns a new string of count characters starting at index start. Leave out count to go to the end.",
        "find": "`s.find(\"abc\")` returns the index where \"abc\" first appears, or `std::string::npos` if it is not found.",
        "rfind": "`s.rfind(x)` searches from the end and returns the index of the last match, or `std::string::npos`.",
        "append": "`s.append(\"more\")` adds text to the end, the same as `s += \"more\"`.",
        "push_back": "`s.push_back('!')` adds one character to the end of the string.",
        "replace": "`s.replace(pos, len, \"new\")` replaces len characters starting at pos with new text.",
        "insert": "`s.insert(pos, \"text\")` puts text in before index pos.",
        "erase": "`s.erase(pos, len)` removes len characters starting at pos. `s.erase(pos)` removes everything from pos on.",
        "c_str": "`s.c_str()` gives a C-style `const char*` version of the string, for older functions that need one.",
        "compare": "`a.compare(b)` returns 0 if equal, a negative number if a comes first and a positive one if b comes first. Usually `==` and `<` are easier.",
        "starts_with": "`s.starts_with(\"pre\")` (C++20) returns true if the string begins with that text.",
        "ends_with": "`s.ends_with(\".txt\")` (C++20) returns true if the string ends with that text.",
        "contains": "`s.contains(\"abc\")` (C++23) returns true if the text appears anywhere. Before C++23 use `s.find(\"abc\") != std::string::npos`.",
        "npos": "`std::string::npos` is a special value (the largest size_t) that find functions return to mean not found.",
        "getline": "`std::getline(std::cin, s)` reads a whole line of input, spaces included, into s.",
        "stoi": "`std::stoi(s)` turns text like \"42\" into an int. It throws if the text does not start with a number.",
        "to_string": "`std::to_string(x)` turns a number into a std::string, like 42 into \"42\".",
    }),
    ("map", "<map>", {
        "insert": "`m.insert({key, value})` adds a pair only if the key is not already there. `m[key] = value` adds or overwrites.",
        "find": "`m.find(key)` returns an iterator to the pair, or `m.end()` if the key is missing.",
        "count": "`m.count(key)` returns 1 if the key exists and 0 if not, since keys are unique.",
        "contains": "`m.contains(key)` (C++20) returns true if the key exists.",
        "erase": "`m.erase(key)` removes that key and its value.",
        "at": "`m.at(key)` returns the value but throws `std::out_of_range` if the key is missing, unlike `m[key]` which adds it.",
        "operator[]": "`m[key]` returns the value for key, and quietly adds the key with a default value if it was missing.",
        "size": "`m.size()` returns how many key-value pairs the map holds.",
        "emplace": "`m.emplace(key, value)` builds a new pair in place if the key is not present.",
        "insert_or_assign": "`m.insert_or_assign(key, value)` (C++17) adds the pair or overwrites the existing value.",
        "lower_bound": "`m.lower_bound(k)` returns an iterator to the first key that is not less than k, handy for range searches in a sorted map.",
    }),
    ("set", "<set>", {
        "insert": "`s.insert(x)` adds x if it is not already in the set. Duplicates are ignored.",
        "erase": "`s.erase(x)` removes x from the set.",
        "count": "`s.count(x)` returns 1 if x is in the set, else 0.",
        "find": "`s.find(x)` returns an iterator to x, or `s.end()` if it is missing.",
    }),
    ("unordered_map", "<unordered_map>", {
        "reserve": "`m.reserve(n)` prepares room for n elements so the hash table does not need to rebuild while you add them.",
        "bucket_count": "`m.bucket_count()` returns how many buckets the hash table uses. You rarely need it.",
    }),
    ("deque", "<deque>", {
        "push_front": "`d.push_front(x)` adds x to the front of a deque quickly.",
        "pop_front": "`d.pop_front()` removes the first element of a deque.",
    }),
    ("list", "<list>", {
        "splice": "`a.splice(pos, b)` moves elements from list b into list a before pos without copying them.",
        "sort": "`l.sort()` sorts a std::list. You cannot use `std::sort` on a list because it needs random access iterators.",
        "remove": "`l.remove(x)` removes every element equal to x from a std::list.",
    }),
    ("queue", "<queue>", {
        "push": "`q.push(x)` adds x to the back of a std::queue.",
        "front": "`q.front()` looks at the element that has waited longest, which `pop()` will remove next.",
        "pop": "`q.pop()` removes the front element. It returns nothing, so read `front()` first.",
    }),
    ("stack", "<stack>", {
        "push": "`st.push(x)` puts x on top of a std::stack.",
        "top": "`st.top()` returns the top element of a std::stack without removing it.",
        "pop": "`st.pop()` removes the top element and returns nothing, so read `top()` first.",
    }),
    ("optional", "<optional>", {
        "has_value": "`opt.has_value()` returns true if the optional holds a value. `if (opt)` does the same.",
        "value_or": "`opt.value_or(d)` returns the stored value, or d if the optional is empty.",
        "reset": "`opt.reset()` empties the optional.",
    }),
    ("unique_ptr", "<memory>", {
        "make_unique": "`std::make_unique<T>(args)` creates a T on the heap and returns a unique_ptr that owns it.",
        "get": "`p.get()` returns the raw pointer without giving up ownership.",
        "release": "`p.release()` gives up ownership and returns the raw pointer; you must delete it yourself.",
        "reset": "`p.reset()` deletes the owned object now and makes the pointer empty.",
    }),
    ("shared_ptr", "<memory>", {
        "make_shared": "`std::make_shared<T>(args)` creates a T and a shared_ptr to it in one efficient step.",
        "use_count": "`p.use_count()` returns how many shared_ptrs share ownership of the object.",
    }),
]

FUNCS = {
    "<algorithm>": {
        "sort": "`std::sort(v.begin(), v.end())` sorts a range from small to big. Pass a comparator like `std::greater<>()` to sort the other way.",
        "stable_sort": "`std::stable_sort` sorts like sort but keeps equal elements in their original order.",
        "reverse": "`std::reverse(v.begin(), v.end())` flips the order of a range in place.",
        "find": "`std::find(first, last, x)` returns an iterator to the first element equal to x, or last if none.",
        "find_if": "`std::find_if(first, last, pred)` returns the first element for which the function pred returns true.",
        "count": "`std::count(first, last, x)` returns how many elements equal x.",
        "count_if": "`std::count_if(first, last, pred)` counts the elements where pred returns true.",
        "min_element": "`std::min_element(first, last)` returns an iterator to the smallest element. Use `*` to get its value.",
        "max_element": "`std::max_element(first, last)` returns an iterator to the largest element.",
        "min": "`std::min(a, b)` returns the smaller of two values. `std::min({a, b, c})` works for a list.",
        "max": "`std::max(a, b)` returns the larger of two values.",
        "clamp": "`std::clamp(x, lo, hi)` (C++17) keeps x between lo and hi.",
        "swap": "`std::swap(a, b)` swaps the values of two variables.",
        "fill": "`std::fill(first, last, x)` sets every element in the range to x.",
        "copy": "`std::copy(first, last, dest)` copies a range to where dest points. Make sure the destination has room.",
        "transform": "`std::transform(first, last, dest, f)` applies f to each element and writes the results to dest.",
        "remove": "`std::remove` moves the kept elements forward but does not shrink the container, so pair it with erase. In C++20 use `std::erase(v, x)` instead.",
        "unique": "`std::unique` removes back-to-back duplicates (sort first to remove all duplicates), then erase the leftover tail.",
        "binary_search": "`std::binary_search(first, last, x)` returns true if x is in a sorted range, in O(log n) time.",
        "lower_bound": "`std::lower_bound(first, last, x)` returns the first position in a sorted range where x could go, using binary search.",
        "upper_bound": "`std::upper_bound(first, last, x)` returns the first position in a sorted range with an element greater than x.",
        "all_of": "`std::all_of(first, last, pred)` returns true if pred is true for every element.",
        "any_of": "`std::any_of(first, last, pred)` returns true if pred is true for at least one element.",
        "none_of": "`std::none_of(first, last, pred)` returns true if pred is false for every element.",
        "for_each": "`std::for_each(first, last, f)` calls f on every element in the range.",
        "shuffle": "`std::shuffle(first, last, rng)` randomly reorders a range using a generator like `std::mt19937`.",
        "next_permutation": "`std::next_permutation(first, last)` rearranges a range into the next ordering, returning false after the last. Sort first to visit all orderings.",
        "rotate": "`std::rotate(first, middle, last)` shifts elements so middle becomes the first one, wrapping the rest around.",
        "equal": "`std::equal(first1, last1, first2)` checks if two ranges hold the same elements in the same order.",
        "partition": "`std::partition(first, last, pred)` moves elements where pred is true to the front.",
        "nth_element": "`std::nth_element(first, nth, last)` puts the element that would be at nth if sorted into that spot, faster than a full sort.",
        "merge": "`std::merge` combines two sorted ranges into one sorted output.",
    },
    "<numeric>": {
        "accumulate": "`std::accumulate(v.begin(), v.end(), 0)` adds up all the elements, starting from 0. Use 0.0 as the start to sum doubles.",
        "iota": "`std::iota(v.begin(), v.end(), 1)` fills a range with 1, 2, 3 and so on.",
        "gcd": "`std::gcd(a, b)` (C++17) returns the greatest common divisor of two integers.",
        "lcm": "`std::lcm(a, b)` (C++17) returns the least common multiple of two integers.",
        "partial_sum": "`std::partial_sum` writes running totals, so 1 2 3 becomes 1 3 6.",
        "reduce": "`std::reduce` (C++17) sums a range like accumulate but may add in any order, which allows parallel versions.",
    },
    "<cmath>": {
        "sqrt": "`std::sqrt(x)` returns the square root of x.",
        "pow": "`std::pow(base, exp)` returns base raised to the power exp, as a double. For squaring, `x * x` is faster.",
        "abs": "`std::abs(x)` returns the absolute value (distance from zero) of x.",
        "floor": "`std::floor(x)` rounds down to the next whole number, so 2.7 becomes 2.0 and -2.3 becomes -3.0.",
        "ceil": "`std::ceil(x)` rounds up, so 2.1 becomes 3.0.",
        "round": "`std::round(x)` rounds to the nearest whole number, with halves rounding away from zero.",
        "trunc": "`std::trunc(x)` chops off the decimal part, rounding toward zero.",
        "fmod": "`std::fmod(a, b)` gives the remainder of a / b for floating point numbers.",
        "sin": "`std::sin(x)` returns the sine of x, where x is in radians.",
        "cos": "`std::cos(x)` returns the cosine of x in radians.",
        "atan2": "`std::atan2(y, x)` returns the angle in radians from the x axis to the point (x, y), handy for aiming in games.",
        "hypot": "`std::hypot(x, y)` returns the length sqrt(x*x + y*y) without overflow problems.",
        "log": "`std::log(x)` returns the natural logarithm of x. Use `std::log10` for base 10 and `std::log2` for base 2.",
        "exp": "`std::exp(x)` returns e raised to the power x.",
        "isnan": "`std::isnan(x)` returns true if x is NaN (not a number), like the result of 0.0 / 0.0.",
    },
    "<cctype>": {
        "isdigit": "`std::isdigit(c)` returns nonzero if c is a digit 0 to 9.",
        "isalpha": "`std::isalpha(c)` returns nonzero if c is a letter.",
        "isspace": "`std::isspace(c)` returns nonzero for whitespace like space, tab and newline.",
        "toupper": "`std::toupper(c)` returns the uppercase version of a letter. Loop over a string to uppercase all of it.",
        "tolower": "`std::tolower(c)` returns the lowercase version of a letter.",
    },
    "<utility>": {
        "move": "`std::move(x)` turns x into something that can be moved from, so its contents can be taken instead of copied. Do not use x's value afterwards except to reassign it.",
        "make_pair": "`std::make_pair(a, b)` creates a std::pair. With C++17 you can just write `std::pair{a, b}`.",
        "exchange": "`std::exchange(x, newValue)` sets x to newValue and returns the old value.",
    },
    "<iomanip>": {
        "setw": "`std::setw(n)` pads the next printed value to at least n characters wide, for lining up columns.",
        "setfill": "`std::setfill('0')` sets the padding character used with setw, like for 007.",
        "setprecision": "`std::setprecision(n)` controls how many digits print for decimals. With `std::fixed`, it is digits after the point.",
    },
    "<cstdlib>": {
        "rand": "`std::rand()` returns a pseudo-random int from 0 to RAND_MAX. It is old and low quality; prefer `<random>`.",
        "srand": "`std::srand(seed)` seeds `rand()`, often with `time(nullptr)`. Modern code uses `<random>` instead.",
        "exit": "`std::exit(code)` ends the program right away with that exit code. Returning from main is usually cleaner.",
    },
}

# Keywords not already covered by the hand-written cpp.txt.
KEYWORDS = {
    "alignas": "`alignas(16)` asks the compiler to line a variable or type up on a memory boundary of that many bytes, sometimes needed for speed or hardware.",
    "alignof": "`alignof(T)` gives the alignment in bytes that type T needs in memory.",
    "consteval": "`consteval` (C++20) marks a function that must run at compile time; calling it with values only known at run time is an error.",
    "constinit": "`constinit` (C++20) makes sure a static or global variable is set up at compile time, without making it const.",
    "const_cast": "`const_cast<T>(x)` adds or removes const. Changing an object that was really created const is still undefined behavior, so it is rarely needed.",
    "co_await": "`co_await` (C++20) pauses a coroutine until something finishes, then resumes it. Coroutines need a library type to work with.",
    "co_yield": "`co_yield value` (C++20) hands a value out of a coroutine and pauses it, like a generator. C++23 adds `std::generator` for this.",
    "co_return": "`co_return` (C++20) finishes a coroutine, optionally with a result.",
    "decltype": "`decltype(expr)` gives the type of an expression without running it, like `decltype(x) y = 0;` to make y the same type as x.",
    "dynamic_cast": "`dynamic_cast<Derived*>(basePtr)` safely checks if a base class pointer really points to a Derived object, returning nullptr if not. It needs a virtual function in the base.",
    "reinterpret_cast": "`reinterpret_cast` treats the bits of one type as another, like a pointer as an integer. It is dangerous and only for low-level code.",
    "explicit": "`explicit` on a constructor stops C++ from using it for silent automatic conversions, which prevents surprising bugs.",
    "extern": "`extern int score;` declares a global variable that is defined in another .cpp file, so several files can share it.",
    "friend": "A `friend` function or class is allowed to use another class's private members.",
    "mutable": "`mutable` lets a member change even inside a const member function, used for things like caches. In a lambda it lets you change captured copies.",
    "noexcept": "`noexcept` promises a function will not throw exceptions. If it does, the program ends. It lets containers move objects faster.",
    "operator": "The `operator` keyword defines how symbols like `+`, `==` or `<<` work for your own types, such as `bool operator==(const Point&) const;`.",
    "requires": "`requires` (C++20) adds conditions to a template, like `requires std::integral<T>`, so wrong types give a clear error.",
    "concept": "A `concept` (C++20) is a named rule for template types, like `std::integral` or `std::floating_point`, used to limit what a template accepts.",
    "static_assert": "`static_assert(sizeof(int) == 4, \"need 32-bit int\");` checks a condition while compiling and stops the build with your message if it fails.",
    "thread_local": "A `thread_local` variable gets a separate copy for each thread.",
    "typedef": "`typedef unsigned int uint;` makes a new name for a type. Modern C++ prefers `using uint = unsigned int;`.",
    "typeid": "`typeid(x).name()` gives some information about x's type at run time. The name text differs between compilers.",
    "typename": "`typename` declares a type parameter in a template, like `template <typename T>`, and tells the compiler a dependent name is a type.",
    "union": "A `union` stores different types in the same memory, but only one at a time. `std::variant` is a safer modern choice.",
    "final": "`final` on a class stops other classes inheriting from it, and on a virtual function stops subclasses overriding it.",
    "default": "Besides switch, `= default` asks the compiler to write a special function for you, like `Player() = default;`.",
    "delete": "Besides freeing memory, `= delete` forbids a function, like `Player(const Player&) = delete;` to stop copying.",
    "export": "In C++20, `export` marks what a module makes visible to code that imports it.",
    "signed": "`signed` types can hold negative numbers. int is signed by default; whether plain char is signed depends on the compiler.",
    "wchar_t": "`wchar_t` is a wide character type for text beyond ASCII. Its size differs between Windows (2 bytes) and Linux or Mac (4 bytes).",
    "char8_t": "`char8_t` (C++20) is the character type for UTF-8 text, used by `u8\"...\"` string literals.",
    "long long": "`long long` is an integer type of at least 64 bits, holding about plus or minus 9.2 quintillion.",
    "register": "`register` was a hint to keep a variable in a CPU register. It was removed in C++17 and does nothing useful.",
}

OBJ_WORDS = {"unordered_map": "unordered map", "unique_ptr": "unique pointer", "shared_ptr": "shared pointer"}

entries, seen, seen_k = [], set(), set()


def add(tag, qs, a):
    assert "=>" not in a and "||" not in a and len(a) <= 600, a
    keep = []
    for q in qs:
        q = re.sub(r"\s+", " ", q.lower()).strip()
        k = keyset(q)
        if not q or "?" in q or norm(q) in seen or (len(k) >= 2 and k in seen_k) or q in keep:
            continue
        keep.append(q)
    if len(keep) < 2:
        return
    for q in keep:
        seen.add(norm(q))
        if len(keyset(q)) >= 2:
            seen_k.add(keyset(q))
    if a[0] == "`":
        a = "In C++, " + a
    entries.append((tag, keep, a))


def main():
    w, k = existing(OUT)
    seen.update(w)
    seen_k.update(k)
    for obj, header, members in MEMBERS:
        ow = OBJ_WORDS.get(obj, obj)
        for m, a in members.items():
            mw = m.replace("operator[]", "square brackets")
            add("coding.cpp.std", [f"what does {obj} {mw} do in c++", f"c++ {ow} {mw}", f"std {obj} {mw}",
                                   f"how do i use {mw} on a {ow} in c++"], a)
    for header, funcs in FUNCS.items():
        for f, a in funcs.items():
            add("coding.cpp.std", [f"what does std {f} do in c++", f"c++ std::{f}", f"how do i use {f} in c++",
                                   f"{f} function c++"], a + f" It is in `{header}`.")
    for kw, a in KEYWORDS.items():
        add("coding.cpp.std", [f"what is the {kw} keyword in c++", f"c++ {kw} keyword", f"what does {kw} mean in c++",
                               f"{kw} in c++ explained"], a)
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("# Generated by gen/coding_cpp_std.py from hand-written notes on the C++ standard library. "
                 "Do not edit by hand.\n")
        tag = None
        for t, qs, a in entries:
            if t != tag:
                fh.write(f"# tag: {t}\n")
                tag = t
            fh.write(" | ".join(qs) + " => " + a + "\n")
    print(len(entries), "entries ->", OUT)


if __name__ == "__main__":
    main()
