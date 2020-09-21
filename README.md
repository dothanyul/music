# music
A family of programs to manage and use a music library.

play is a wrapper for ffplay from ffmpeg that plays multiple songs sequentially,
with options for shuffling and repeating.

plist runs a command line to add, delete, and edit playlists in the form of 
directories of hard links in the folder ~/Music/playlists. Currently has
functionality for creating new playlists, listing existing playlists, renaming 
playlists, and adding and removing songs from playlists.

songdata.pl takes newly downloaded albums and sets their ID3 metadata using the
eyeD3 program by nicfit, then sorts them by artist, then album into ~/Music.
