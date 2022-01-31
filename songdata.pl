#!/usr/bin/env perl
use strict;
use warnings;
use Env qw(HOME);
use Switch;
#use List::MoreUtils qw(first_index);
use File::Path qw(rmtree);

# Before calling this program, have the songs you want to standardize in a folder with the desired cover art named cover.sth and all the songs named as you want them, or as YoutubetoMP3 names them (## - Artist - Title)
# Call this program with that folder name as its last argument, following the keyword arguments -a, --artist, -A, --album, and -c, --cover
# in replacing the artwork, doesn't modify albums with any song gotten from Bandcamp
# if any other tags exist, leaves them
# gets rid of comments and UserTextFrames
# 'eyeD3 --remove-all-comments song.mp3' to remove all comments
# 'eyeD3 --user-text-frame "DESCRIPTION:" song.mp3' to remove a user text frame (because it's supposed to be "DESCRIPTION:content" and blank content removes the tag)
#TODO now test weird inputs/artists/albums/covers/etc.

# read command line arguments
my $artist = 0;
my $artistGiven;
my $album;
my $cover = 0;
my $dir = "$HOME/Music/";
my $arg;

while ($arg = shift @ARGV) {
    switch ($arg) {
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
            print "an artist it will check if the artist is set in the ID3 tags, failing which it\n";
            print "check if the file name matches /<track> - <artist> - <title>/ and use that\n";
            print "artist, failing which it will not set the artist.\n";
            exit 0;
        }

        case ["-a", "--artist"] {
            $artist = shift @ARGV;
            $artistGiven = 1;
        }

        case ["-A", "--album"] {
            $album = shift @ARGV;
        }

        case ["-c", "--cover"] {
            $cover = shift @ARGV;
        }

        else {
            $dir .= $arg;
        }
    }
}

# get album name from dir
unless ($album) {
    $album = ($dir =~ m/(.*\/)*(.+[^\/])\/?/)[1];
}
# add trailing slash to dir if it's not there
unless ($dir =~ m/\/$/) {
    $dir .= "/";
}

# read from dir
my $dh;
opendir $dh, "$dir" || die "Can't open $dir: $!";
# read songs in dir
my @songs = grep { /^[^.].*\.mp3/ } readdir $dh;
seekdir $dh, 0;
# find the cover if not given
unless ($cover) {
    $cover = (grep { /^cover.(jpe?g|png)$/ } readdir $dh)[0];
}
closedir $dh || die "Error in $dir: $!";

# rename the cover art to cover.jpg or cover.png if it isn't already
if ($cover && $cover !~ m/^cover\.(jpe?g|png)$/ && $cover =~ m/\.(jpe?g|png)$/) {
    $cover =~ s/"/\\"/g;
    system('mv', "$cover", "cover." . ($cover =~ m/(jpe?g|png)$/)[0]); #!!!
    $cover = "cover." . ($cover =~ m/(jpe?g|png)$/)[0];
}

my $tracktotal = scalar @songs;
my $albumbandcamp = 0;
$dir =~ s/"/\\"/g;

# get each title and track number, and artist if not given, and add all the tags to the song
foreach my $song (@songs) {
    chomp $song;
    $song =~ s/"/\\"/g;
    my $file = "$dir/$song";
    open my $tags, '-|', "eyeD3 -- \"$file\"" || die "Couldn't read from eyeD3: $!";
    while (<$tags>) {
        if (m/bandcamp\.com/) {
            $albumbandcamp = 1;
        }
        if (!$artistGiven && m/artist: /) {
            $artist = (m/artist: (.*)/)[0];
        }
    }

    unless ($artist && $artistGiven) {
        if ($song =~ m/^\d+ - (.*) - (.*)\.mp3/) {
            $artist = ($song =~ m/^\d+ - (.*) - (.*)\.mp3/)[0];
        }
    }

    close $tags || die "Failed to close eyeD3: $!";
    system('bash', '-c', "eyeD3 --remove-all-comments \"$file\" &>/dev/null") unless ($albumbandcamp);
    my $trkn = ($song =~ m/^(\d+) .*\.mp3/)[0];
    unless ($trkn) {
        $trkn = 1;
    }
    my $title = ($song =~ m/^(\d+)?( - .*)?(.*- )?(.*)\.mp3/)[2];
    # get rid of the artist name if it's in the file name
    if ($song !~ m/^${trkn} ${title}\.mp3/) {
        system('mv', "$dir$song", "$dir$trkn $title.mp3");
        $song = "$trkn $title.mp3";
        $file = $dir . $song;
    }

    # check to see if strings are safe to encode in latin1 encoding
    my $latin = 1;
    foreach my $tag ($artist, $album, $title) {
        foreach my $char (split //, $tag) {
            if (ord $char > 127) {
                $latin = 0;
                last;
            }
        }
        last unless $latin;
    }

    # change the tags
    foreach ($artist, $album, $title, $trkn) {
        $_ =~ s/"/\\"/g;
    }
    unless ($albumbandcamp) {
        if ($latin) {
            system('bash', '-c', "eyeD3 --encoding latin1 --artist \"$artist\" --album \"$album\" --title \"$title\" --track $trkn --track-total $tracktotal \"$file\" >/dev/null");
        } else {
            system('bash', '-c', "eyeD3 --encoding utf8 --artist \"$artist\" --album \"$album\" --title \"$title\" --track $trkn --track-total $tracktotal \"$file\" >/dev/null");
        }
    }
}

# replace the artwork with the picture in the folder, unless this album was downloaded from Bandcamp or has no cover image
if ($cover && ! $albumbandcamp) {
    print "$cover\n";
    system('bash', '-c', "eyeD3 --remove-all-images \"$dir\" >/dev/null");
    system('bash', '-c', "eyeD3 --plugin art -T \"$dir\" >/dev/null");
}

# sort album into appropriate artist under ~/Music
unless (-d "$HOME/Music/$artist") {
    mkdir "$HOME/Music/$artist";
}
if (-d "$HOME/Music/$artist/$album") {
    print "This album is already in your library. Do you want to overwrite? (y/n) ";
    chomp(my $ans = <STDIN>);
    if ($ans =~ m/y/i) {
        rmtree "$HOME/Music/$artist/$album" || die "Failed to remove $album: $!";
        system('mv', "$dir", "$HOME/Music/$artist");
    }
} else {
    system('mv', "$dir", "$HOME/Music/$artist");
}
