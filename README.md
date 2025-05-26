# bobadex

Pokedex but for boba. 

## Basic Use
Allows users to add boba shops into their personal index, hence bobadex. Every entry requires a picture for the shops image in the user's bobadex. Users can add and rate individual drinks that they've tried from specific boba shops. User's can also add friends and view their bobadex's.

## Local DEV
pass

### TODO
[x] scaffold MVP
[X] login auth
[X] set up database
[] maybe set up Google API or OSM export to get unique shop IDs for statistics
[] add friends and visit their bobadex
    - [] add an aggregate bobadex (squadadex .... ? ok thats a tentative nanme) that shows statistices like averages, photos etc (requires the above check)
    - [-] maybe a central feed on what you and your friends 'caught'
    - [] Allow users to make a customizable banner for each shop with their favorite drink/drinks
    - [] allow users to make comments on shops of friends
[] polish UI
    - [X] switch rating numpad with a UI or validation check for nums outside of 0 and 5
    - [] fix up the text in the grid a little so stars always show
[X] add filters and sorters for the bobadex add favorites
    - [] timestamp filter (default for shops)
[X] within every shop you should be able to add a drink and have ratings for each drink
[] Optimize app
    - [] fix RLS
    - [] Make index in supabase for faster queries
    - [] Cache image urls for better performance