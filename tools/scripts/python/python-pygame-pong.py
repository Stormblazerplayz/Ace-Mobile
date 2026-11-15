# @title Pygame Pong
# @category Games
# @kind Console program
# @where Install pygame first (pip install pygame), save as pong.py and run: python3 pong.py. Left paddle uses W and S, right paddle uses the Up and Down arrows.
# @keywords pygame pong, pygame two player game, pygame paddles, pygame rect collision, pygame keyboard
# @about Two player Pong: bounce the ball past the other paddle to score, first to 5 wins.

import pygame

pygame.init()
WIDTH, HEIGHT = 800, 500
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Pong")
clock = pygame.time.Clock()
font = pygame.font.SysFont(None, 64)

left = pygame.Rect(30, HEIGHT // 2 - 50, 12, 100)
right = pygame.Rect(WIDTH - 42, HEIGHT // 2 - 50, 12, 100)
ball = pygame.Rect(WIDTH // 2 - 8, HEIGHT // 2 - 8, 16, 16)
speed = [6, 4]
scores = [0, 0]
PADDLE_SPEED = 7


def reset_ball(direction):
    ball.center = (WIDTH // 2, HEIGHT // 2)
    speed[0] = 6 * direction
    speed[1] = 4


running = True
while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    keys = pygame.key.get_pressed()
    if keys[pygame.K_w]:
        left.y -= PADDLE_SPEED
    if keys[pygame.K_s]:
        left.y += PADDLE_SPEED
    if keys[pygame.K_UP]:
        right.y -= PADDLE_SPEED
    if keys[pygame.K_DOWN]:
        right.y += PADDLE_SPEED
    left.clamp_ip(screen.get_rect())   # keep paddles on screen
    right.clamp_ip(screen.get_rect())

    ball.x += speed[0]
    ball.y += speed[1]
    if ball.top <= 0 or ball.bottom >= HEIGHT:
        speed[1] = -speed[1]
    if ball.colliderect(left) and speed[0] < 0:
        speed[0] = -speed[0] + 1   # speed up a little each hit
    if ball.colliderect(right) and speed[0] > 0:
        speed[0] = -speed[0] - 1
    if ball.left < 0:
        scores[1] += 1
        reset_ball(1)
    if ball.right > WIDTH:
        scores[0] += 1
        reset_ball(-1)

    screen.fill((0, 0, 0))
    pygame.draw.rect(screen, (255, 255, 255), left)
    pygame.draw.rect(screen, (255, 255, 255), right)
    pygame.draw.ellipse(screen, (255, 220, 0), ball)
    pygame.draw.line(screen, (80, 80, 80), (WIDTH // 2, 0), (WIDTH // 2, HEIGHT), 2)
    text = font.render(f"{scores[0]}   {scores[1]}", True, (255, 255, 255))
    screen.blit(text, text.get_rect(center=(WIDTH // 2, 40)))
    pygame.display.flip()

    if max(scores) >= 5:
        pygame.time.wait(1500)
        running = False
    clock.tick(60)

pygame.quit()
print("Final score:", scores[0], "to", scores[1])
