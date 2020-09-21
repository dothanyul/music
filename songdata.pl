#!/usr/bin/env perl
use strict;
use warnings;
use Env qw( HOME );
use Switch;
use List::MoreUtils qw( first_index );

# Before calling this program, have the songs you want to standardize in a 
# folder with the desired cover art named cover.sth and all the songs named as 
# you want them
# Call this program with that folder name as its last argument, following the
# keyword arguments -a, --artist, -A, --album, and -c, --cover
# in replacing the artwork, don't modify albums with any song gotten from Bandcamp
# if any other tags exist, leave them
# get rid of comments and UserTextFrames
# 'eyeD3 --remove-all-comments song.mp3' to remove all comments
# 'eyeD3 --user-text-frame "DESCRIPTION:" song.mp3' to remove a user text frame
# (because it's supposed to be "DESCRIPTION:content" and blank content removes the tag)
 

# read command line arguments
my %tags = ();
my $arg;
while ( $arg = shift @ARGV ) { #!!!
    switch ( $arg ) {
        case ["-h", "--help"] {
            print "Call this program on a folder containing an album, with the artist, album title,\n";
            print "and cover art path passed to -a/--artist, -A/--album, and -c/--cover\n";
            print "respectively. Set all the song file names to their track numbers followed by\n";
            print "their titles. The program will set the ID3 tags for artist, album, title, track\n";
            print "number, and total tracks; add the cover art to the song; and sort it under the\n";
            print "artist and album in ~/Music.";
            print "If not given an album title, it will assume the folder name is the album title;\n";
            print "if not given a cover art path, it will look for a file named cover.jpg or\n";
            print "cover.png in the folder, failing which it will not add the cover; if not given\n";
            print "an artist it will not set the artist.\n";
            exit 0;
        } 
        case ["-a", "--artist"] {
            $tags{"artist"} = shift @ARGV;
        } 
        case ["-A", "--album"] {
            $tags{"album"} = shift @ARGV;
        }
        case ["-c", "--cover"] {
            $tags{"cover"} = shift @ARGV;
        }
        else {
            my $dir = $arg;
        }
    }
}
my $dh;

# loop over each song in dir
opendir $dh, "$HOME/$dir/" || die "Can't open $dir: $!";
my @songs = grep { /^[^.].*\.mp3/ } readdir $dh;
seek $dh, 0; #!!!
# rename the cover art to cover.jpg or cover.png if it isn't already
if ( $cover && $cover !~ m/^cover\.(jpg|png)$/ && $cover =~ m/\.(jpg|png)$/ ) {
    $cover =~ s/"/\\"/g;
    system( 'mv', "$cover", "cover." . ( $cover =~ m/(jpg|png)$)/ )[0] ); #!!!
    $cover = "cover." . ( $cover =~ m/(jpg|png)$)/ )[0];
} else {
    $cover = grep { /^cover.(jpg|png)/ } readdir $dh;
}
closedir $dh || die "Error in $dir: $!";
my $tracktotal = scalar @songs;
$dir =~ s/"/\\"/g;
# get each title and track number, and add all the tags to the song
foreach my $song ( @songs ) {
    chomp $song;
    $tags{"trkn"} = ( $song =~ m/^(\d+) .*\.mp3/ )[0];
    $tags{"title"} = ( $song =~ m/^\d+ (.*)\.mp3/ )[0];
    $song =~ s/"/\\"/g;
    my $file = "$dir/$song";
    # change the tags
    foreach ( "artist", "album", "title", "trkn" ) {
        $tags{$_} =~ s/"/\\"/g;
    }
    system( 'bash', '-c', "eyeD3 --artist \"$tags{'artist'}\" --album \"$tags{'album'}\" --title \"$tags{'title'}\" .
            "--track $tags{'trkn'} --track-total $tracktotal \"$file\"" ); #!!!
}
# replace the artwork with the picture in the folder, unless this album was downloaded from Bandcamp or has no cover image
if ( $cover && ! $albumbandcamp ) {
    system( 'bash', '-c', "eyeD3 --remove-all-images \"$dir/$artist/$album\" &>/dev/null" );
    system( 'bash', '-c', "eyeD3 --plugin art -T \"$dir/$artist/$album\" &>/dev/null" );
}
# set the total tracks on the album because why not
foreach my $song ( @songs ) {
    $song =~ s/"/\\"/g;
    system( 'bash', '-c', "eyeD3 --track-total $tracktotal \"$dir/$artist/$album/$song\" &>/dev/null" );
}
