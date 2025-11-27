State Machine:
Used a pretty straightforward approach that can be improved later.
By using "canTransitionTo" and validating state transitions we can block invalid states.

States (in order of transition):
- IDLE -> Heist was created but still waiting players to join
- PREPARED -> Players are ready to start the heist
  - If someone leaves it goes back to idle.
  - I'm not sure if that was the right decision, but I made it based on the script being kinda arcade like GTA Online heists, where they have a lobby and heist per lobby.
- ENTRY -> Players are ready to attempt to enter the bank
  - If someone leaves, it transitions to FAILED then after cleanup interval it **SHOULD (not implemented)** go back to IDLE.


Loot:
- States
  - Players can start looting and stop (not collecting it)
  - Only 1 player can loot per loot spot
  - Loot spots can be collected by multiple players (configurable in loot settings)

Escape:
  - All players need to escape to mark the heist as completed - Enjoyable for both sides (police and robbers)
