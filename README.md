# music
A family of programs to manage and use a music library.

play is a wrapper for ffplay from ffmpeg that playsmultiple songs sequentially,
with options for shuffling and repeating.

plist runs a command line to add, delete, and edit playlists in the form of 
directories of hard links in the folder ~/Music/playlists. Currently has
functionality for creating new playlists, listing existing playlists, renaming
existing playlists, and adding and removing songs from existing playlists.

songdata.pl is the beginning of a script to standardize my ID3 tags, using the
eyeD3 program by nicfit.
