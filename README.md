# bobadex

Pokedex but for boba. 

## Basic Use
Allows users to add boba shops into their personal index, hence bobadex. Every entry requires a picture for the shops image in the user's bobadex. Users can add and rate individual drinks that they've tried from specific boba shops. User's can also add friends and view their bobadex's.

## Local DEV
pass

### TODO
[] Add admin panel
    [] run OSM import
    [] verify import
    [] Ai image gen verification
    [] user shop input validation


[x] scaffold MVP
[X] login auth
[X] set up database
[X] maybe set up Google API or OSM export to get unique shop IDs for statistics
[] add achievments and badges
[] Brand view page, want to switch the add shop dialog with this (keep the current one for adding shops that are NOT in the db)
[] add a verification for shops not in db. Can have 1 pass through perplexity AI API and then a 2nd pass for manual verification.
[] Automate current OSM brand normalization and import scripts using github
[X] add friends and visit their bobadex
    - [] Account view page should have more stats
        - [] shared number of shops
        - [] highest rated shop -> check shop rating -> check avg drink ratings
    - [X] add an aggregate bobadex (squadadex .... ? ok thats a tentative nanme) that shows statistices like averages, photos etc (requires the above check)
    - [-] maybe a central feed on what you and your friends 'caught'
    - [X] Allow users to make a customizable banner for each shop with their favorite drink/drinks
    - [] allow users to make comments on shops of friends
    - [X] Ability to add friends
[] polish UI
    - [X] switch rating numpad with a UI or validation check for nums outside of 0 and 5
    - [X] fix up the text in the grid a little so stars always show
    - [X] Add a floating bar on the bottom with things like add shop, view profile, view friends, etc.
[X] add filters and sorters for the bobadex add favorites
    - [X] timestamp filter (default for shops)
[X] within every shop you should be able to add a drink and have ratings for each drink
[] Optimize app
    - [] fix RLS
    - [] Make index in supabase for faster queries
    - [X] Cache image urls for better performance