# @title Snake in the Terminal
# @category Games
# @kind Console program
# @where Save as snake.py and run in a real terminal: python3 snake.py (uses curses, which is built in on Mac and Linux; on Windows run pip install windows-curses first)
# @keywords python snake game, python curses, python terminal game, python arrow keys game
# @about The classic Snake game in your terminal: eat food, grow longer and don't hit the walls or yourself.

import curses
import random


def main(screen):
    curses.curs_set(0)          # hide the blinking cursor
    screen.timeout(120)         # wait at most 120 ms for a key, so the game keeps moving
    height, width = screen.getmaxyx()
    snake = [(height // 2, width // 2 + i) for i in range(3)]  # list of (row, col), head first
    direction = (0, -1)
    food = (height // 3, width // 3)
    score = 0
    turns = {curses.KEY_UP: (-1, 0), curses.KEY_DOWN: (1, 0), curses.KEY_LEFT: (0, -1), curses.KEY_RIGHT: (0, 1)}

    while True:
        screen.clear()
        screen.border()
        screen.addstr(0, 2, f" Score: {score} ")
        screen.addch(food[0], food[1], "*")
        for r, c in snake:
            screen.addch(r, c, "O")
        key = screen.getch()
        if key in turns:
            new = turns[key]
            if (new[0] + direction[0], new[1] + direction[1]) != (0, 0):  # can't turn straight back
                direction = new
        elif key == ord("q"):
            break
        head = (snake[0][0] + direction[0], snake[0][1] + direction[1])
        if head in snake or not (0 < head[0] < height - 1 and 0 < head[1] < width - 1):
            break  # crashed
        snake.insert(0, head)
        if head == food:
            score += 1
            while food in snake:
                food = (random.randint(1, height - 2), random.randint(1, width - 2))
        else:
            snake.pop()  # not eating, so the tail moves forward too
    return score


final = curses.wrapper(main)
print(f"Game over! You ate {final} snacks.")
