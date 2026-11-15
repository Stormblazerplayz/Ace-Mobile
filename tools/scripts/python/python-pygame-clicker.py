# @title Pygame Target Clicker
# @category Games
# @kind Console program
# @where Install pygame first (pip install pygame), save as clicker.py and run: python3 clicker.py. Click the targets with the mouse.
# @keywords pygame clicker, pygame mouse click, pygame aim trainer, pygame countdown timer
# @about Click as many targets as you can in 30 seconds; each target shrinks the longer it stays.

import random

import pygame

pygame.init()
WIDTH, HEIGHT = 700, 500
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Target Clicker")
clock = pygame.time.Clock()
font = pygame.font.SysFont(None, 40)

GAME_MS = 30000
start = pygame.time.get_ticks()
score = 0
target = [WIDTH // 2, HEIGHT // 2, 40]  # x, y, radius


def new_target():
    return [random.randint(50, WIDTH - 50), random.randint(80, HEIGHT - 50), 40]


running = True
while running:
    time_left = max(0, GAME_MS - (pygame.time.get_ticks() - start))
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        elif event.type == pygame.MOUSEBUTTONDOWN and time_left > 0:
            mx, my = event.pos
            # Inside the circle if the distance to the center is less than the radius
            if (mx - target[0]) ** 2 + (my - target[1]) ** 2 <= target[2] ** 2:
                score += 1
                target = new_target()

    if time_left > 0:
        target[2] -= 0.15
        if target[2] < 8:  # too slow, it vanished
            target = new_target()

    screen.fill((30, 30, 30))
    if time_left > 0:
        x, y, r = int(target[0]), int(target[1]), int(target[2])
        pygame.draw.circle(screen, (255, 60, 60), (x, y), r)
        pygame.draw.circle(screen, (255, 255, 255), (x, y), max(2, r // 2))
        hud = f"Score: {score}   Time: {time_left // 1000}"
    else:
        hud = f"Time's up! Final score: {score}. Close the window to quit."
    screen.blit(font.render(hud, True, (255, 255, 255)), (15, 15))
    pygame.display.flip()
    clock.tick(60)

pygame.quit()
