# IW4x-Map-Voting-System

Improved version of eternalhabit's IW4x voting system (https://forum.alterware.dev/t/iw4x-map-vote-by-eternalhabit-update-v106-february-15th-2025/1537). 

Vote has been split into two phases. First for map, then game mode.
Increased maximum option count to 15.
I've made an attempt to make the code more readable by reducing the use of global variables.

## Map Voting

Maps are split manually into small, medium and large. The vote will consist of an even split of the three.

<img width="1129" height="1086" alt="image" src="https://github.com/user-attachments/assets/b4eb8d32-24f8-4324-b11e-219ec3a784ab" />

## Game Mode Voting

Game modes are displayed with some restrictions in place. Only MW2 maps will show Global Thermonuclear War.

"Custom" maps will also have Demolition, One-flag CTF and CTF filtered as I found these did not work on a lot of imported COD4 maps.

Currently these are not customisable, they are set in the getValidGameModeTypes function.

<img width="1078" height="564" alt="image" src="https://github.com/user-attachments/assets/b80b09b3-4e8e-4b91-af7f-d2c83b663e16" />

## DVARS

```
set mapvote_small_maps "mp_rust,mp_rust_long,mp_shipment"
set mapvote_med_maps "mp_terminal,mp_highrise,mp_favela"
set mapvote_big_maps "mp_afghan,mp_derail,mp_estate,mp_estate_tropical"

set mapvote_modes "arena,ctf,dd,dom,dm,gtnw,koth,oneflag,sab,sd,war"

set mapvote_map_timer "30"
set mapvote_gamemode_timer "30"

set mapvote_optionsCount "15" // 2 - 15
```
