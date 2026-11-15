# @title Logging to a File
# @category Files and data
# @kind Console program
# @where Save as logging_demo.py and run: python3 logging_demo.py. It writes app.log next to it.
# @keywords python logging, python log file, python debug info warning error, python logger
# @about Uses the logging module to record what your program is doing, with times and levels, in a log file.

import logging
import random
from pathlib import Path

LOG = Path(__file__).with_name("app.log")
logging.basicConfig(
    level=logging.DEBUG,  # record everything from DEBUG and up
    format="%(asctime)s  %(levelname)-8s %(message)s",
    datefmt="%H:%M:%S",
    handlers=[logging.FileHandler(LOG, encoding="utf-8"), logging.StreamHandler()],
)
log = logging.getLogger("game")

log.info("Game started")
health = 100
for turn in range(1, 6):
    damage = random.randint(0, 40)
    health -= damage
    log.debug("Turn %d: took %d damage, health is %d", turn, damage, health)
    if 0 < health < 30:
        log.warning("Health is low (%d)!", health)
    if health <= 0:
        log.error("Player was defeated on turn %d", turn)
        break
else:
    log.info("Player survived all 5 turns with %d health", health)

try:
    1 / 0
except ZeroDivisionError:
    log.exception("Something went wrong, here is the full error:")

print(f"\nEverything above was also saved to {LOG.name}.")
