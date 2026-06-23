# juniper-gamejam
Game for the very serious juniper dev game jam https://itch.io/jam/theveryseriousjuniperdevgamejam

Live Game Dev Stream Playlist: https://www.youtube.com/playlist?list=PL1WRu1sntH9hZpimUcBGUtlens3eoKi7m

Game Plan:

1. Like Beyblade or Spinning Top Battle you're fighting in an arena with spinning tops
2. Customize your spinning top
3. Send your top into battle against randomzied opponents that get harder over time
4. Win $$$ each match and use that to upgrade your top and launcher
5. Repeat

Need to keep the scope very small since my time will be limited to work on it.

Mechanics: 

1. Spin the crank on your launcher to get more power then release it to send it into the arena.
2. Click to give your top a boost in a particular direction
3. Win or lose the fight head to the shop and buy upgrades
4. Pick your next opponent (1 of 3?)
5. Go back to 1


Day 1:

- Managed to get the spinning top physics to be decent
- Placeholder launcher mechanics in place, just hold LMB to crank and then release for now
- Figured out how to import blender models WITH collision shapes, works for anything static

https://github.com/user-attachments/assets/965ac243-b08f-4bd6-a8dc-afd8b121f17c


Day 2:

- Added menus (placeholder)
- Added volume controls (working)
- Added save/load of volume control settings
- Added Randomly generated CPUs to fight against
- CPUs are colour coded based on their highest stat
- Added particle effects for moving on the ground and sparks for hitting things (including the ground)
- Added spinning portion to center of arena
- CPU launchers are now placed randomly and their cranks spin when you are cranking yours
- CPUs launch at the same time as you
- Added sound effects to gameplay (not UI)
- Added Music (Aaron is going to make new music but using his music from past gamejam for now)
- Added more shaped portion to the top of the spinning tops using blender to test the process for customization later
- Various physics adjustments
- Removed the constant pull to the center and let the AI also do the rocket dash to improve the gameplay feel

https://github.com/user-attachments/assets/803b758c-50e3-4b32-800c-d4079eac833c

Day 3 TODOs:

- [Done] Change store into roguelike 3 options of next type of battle
- [Done] Battle options are a combination of type (duel, 4 player FFA, or 2v2 teams?) + arena + reward
- [Done] Rewards have a benefit, drawback, and visual difference (change one of your top's parts? colour?)
- [Done] Have count down that starts when you begin cranking the launcher at start of battle, auto have everyone launch when it completes
- [Done] READY? SET? SPIN! (voice lines during count down)
- [Done] Implement the UI sound effects
- [Done] Round counter that increases and ramps difficulty of CPUs as you complete battles
- [Done] Add player stats, progress, etc to the save file
- [Done] Make "new game" wipe the old save file and continue just plays the loaded save


Day 4 TODOs:
- [Done] Change how stats work (Just 3 human-readable stats Dexterity, Power, Special which affect the variables in different combinations)
- [Done] Change CPU scaling
- [Done] Change colours to be based on the new stats
- [Done] Change challenge rewards to use new stats and scale with wins
- [Done] Update physics
- [Done] Fix camera issues
- [Done] Fix issue with not being able to see tops behind stuff in the new arenas
- Implement ults and add as rewards
- [Done] Redesign the store/challenge screen (show 1-5 stars for each stat, your current stats, make it not hideous)
- [Done] Add stats for each CPU and the player to the HUD in battle (Have icon of the top matching its colour + 3 stats shown with 1-5 stars)
- [Done] Update damage calculations and use something other than spin speed as your "hp/stamina"