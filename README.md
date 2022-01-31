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

# MP3 player ideas

Data structures:
 - song: MP3 file, with ID3 tags set for title, album, artist, track number, album track total, time, and cover art, and named with ## Title.mp3
 - album: folder containing a number of songs, as well as the cover art and a text file containing album artist, total runtime, and track listing with artists and lengths
 - artist: folder containing at least one picture and a text file with their name, a list of albums, and maybe some other stuff
 - playlist: folder containing soft links to songs (in their albums) as well as an image for the cover and a text file with the order of the songs on the playlist
 - three folders for albums, artists, and playlists

Some functionality for viewing all the songs on one page and sorting and filtering by any of the ID3 tags that are set
Some functionality for building a queue
Maybe some functionality for saving a listening session into a playlist?
Turns off shuffle and repeat when you close the program
