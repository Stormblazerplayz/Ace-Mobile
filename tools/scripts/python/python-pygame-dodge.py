# @title Pygame Dodge the Blocks
# @category Games
# @kind Console program
# @where Install pygame first (pip install pygame), save as dodge.py and run: python3 dodge.py. Move with the Left and Right arrows.
# @keywords pygame dodge game, pygame falling blocks, pygame avoid obstacles, pygame score timer
# @about Move left and right to dodge falling blocks that get faster the longer you survive.

import random

import pygame

pygame.init()
WIDTH, HEIGHT = 480, 640
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Dodge!")
clock = pygame.time.Clock()
font = pygame.font.SysFont(None, 36)

player = pygame.Rect(WIDTH // 2 - 25, HEIGHT - 70, 50, 50)
blocks = []
score = 0
fall_speed = 4
running = True

while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    keys = pygame.key.get_pressed()
    if keys[pygame.K_LEFT]:
        player.x -= 8
    if keys[pygame.K_RIGHT]:
        player.x += 8
    player.clamp_ip(screen.get_rect())

    # Sometimes add a new block at the top
    if random.random() < 0.04 + score / 20000:
        size = random.randint(25, 60)
        blocks.append(pygame.Rect(random.randint(0, WIDTH - size), -size, size, size))

    for block in blocks:
        block.y += fall_speed
        if block.colliderect(player):
            running = False
    blocks = [b for b in blocks if b.top < HEIGHT]  # forget blocks that fell off the screen

    score += 1
    fall_speed = 4 + score // 300  # faster over time

    screen.fill((25, 25, 35))
    pygame.draw.rect(screen, (80, 200, 255), player)
    for block in blocks:
        pygame.draw.rect(screen, (255, 90, 90), block)
    screen.blit(font.render(f"Score: {score}", True, (255, 255, 255)), (10, 10))
    pygame.display.flip()
    clock.tick(60)

pygame.quit()
print("You survived with a score of", score)
