# @title Pygame Snake
# @category Games
# @kind Console program
# @where Install pygame first (pip install pygame), save as snake_game.py and run: python3 snake_game.py. Steer with the arrow keys.
# @keywords pygame snake, pygame grid game, pygame arrow keys, pygame eat food grow
# @about Snake in a pygame window: eat the red apples to grow, and don't crash into the walls or your tail.

import random

import pygame

CELL, COLS, ROWS = 24, 25, 20
pygame.init()
screen = pygame.display.set_mode((CELL * COLS, CELL * ROWS))
pygame.display.set_caption("Snake")
clock = pygame.time.Clock()
font = pygame.font.SysFont(None, 32)


def random_food(snake):
    while True:
        spot = (random.randrange(COLS), random.randrange(ROWS))
        if spot not in snake:
            return spot


snake = [(5, 10), (4, 10), (3, 10)]  # head first
direction = (1, 0)
food = random_food(snake)
alive = True
DIRECTIONS = {pygame.K_UP: (0, -1), pygame.K_DOWN: (0, 1), pygame.K_LEFT: (-1, 0), pygame.K_RIGHT: (1, 0)}

while alive:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            alive = False
        elif event.type == pygame.KEYDOWN and event.key in DIRECTIONS:
            new = DIRECTIONS[event.key]
            if (new[0] + direction[0], new[1] + direction[1]) != (0, 0):  # no U-turns
                direction = new

    head = (snake[0][0] + direction[0], snake[0][1] + direction[1])
    if head in snake or not (0 <= head[0] < COLS and 0 <= head[1] < ROWS):
        alive = False
    else:
        snake.insert(0, head)
        if head == food:
            food = random_food(snake)
        else:
            snake.pop()

    screen.fill((15, 30, 15))
    pygame.draw.rect(screen, (220, 40, 40), (food[0] * CELL, food[1] * CELL, CELL, CELL))
    for i, (x, y) in enumerate(snake):
        green = (60, 230, 60) if i == 0 else (40, 170, 40)
        pygame.draw.rect(screen, green, (x * CELL + 1, y * CELL + 1, CELL - 2, CELL - 2))
    screen.blit(font.render(f"Length: {len(snake)}", True, (255, 255, 255)), (8, 8))
    pygame.display.flip()
    clock.tick(10)  # 10 moves per second; raise it to make the game harder

pygame.time.wait(800)
pygame.quit()
print("Game over! Your snake was", len(snake), "long.")
