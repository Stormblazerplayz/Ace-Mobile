# @title Pygame Bouncing Ball
# @category Games
# @kind Console program
# @where Install pygame first (pip install pygame), save as bounce.py and run: python3 bounce.py on a computer.
# @keywords pygame bouncing ball, pygame first window, pygame game loop, pygame draw circle
# @about Your first pygame window: a ball bounces around the screen and changes color when it hits a wall.

import random

import pygame

pygame.init()
WIDTH, HEIGHT = 640, 480
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Bouncing Ball")
clock = pygame.time.Clock()

x, y = WIDTH // 2, HEIGHT // 2   # ball position
dx, dy = 5, 4                    # ball speed (pixels per frame)
radius = 25
color = (255, 200, 0)

running = True
while running:
    # 1. Handle events (like clicking the window's close button)
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    # 2. Update: move the ball and bounce off the edges
    x += dx
    y += dy
    if x - radius < 0 or x + radius > WIDTH:
        dx = -dx
        color = (random.randint(50, 255), random.randint(50, 255), random.randint(50, 255))
    if y - radius < 0 or y + radius > HEIGHT:
        dy = -dy
        color = (random.randint(50, 255), random.randint(50, 255), random.randint(50, 255))

    # 3. Draw everything, then show it
    screen.fill((20, 20, 40))
    pygame.draw.circle(screen, color, (x, y), radius)
    pygame.display.flip()

    clock.tick(60)  # run at 60 frames per second

pygame.quit()
