#!/usr/bin/env perl
use strict;
use warnings;
use Env qw( HOME );

# require the artist, album, title, track number, artwork
# if an artwork already exists, move it to BACK_COVER and give it the given cover
# if any of lyrics, disc number, recording date, composer, genre, album artist exist, leave them
# get rid of comments and UserTextFrames
# 'eyeD3 --remove-all-comments song.mp3' to remove all comments
# 'eyeD3 --user-text-frame "DESCRIPTION:" song.mp3' to remove a user text frame
# (because it's supposed to be "DESCRIPTION:content" and blank content removes the tag)
# Eventual goal: merge this program with the .name.sh program in ~/Music to
# have an all-in-one program that standardizes tags and applies the desired
# artwork unless the song came from Bandcamp, then sorts it into the desired 
# folder by artist and album.

my $dir = "$HOME/Documents/code/music";
my $dh;

# loop over every artist
opendir $dh, $dir || die "Can't open directory $dir: $!";
my @artists = grep { !/^\./ } readdir $dh;
closedir $dh || die "Error in $dir: $!";
foreach my $artist ( @artists ) {
    chomp( $artist );
    next if ( $artist eq 'playlists' || $artist eq 'Artwork' || ! -d $artist );

    # loop over each album in each artist
    opendir $dh, "$dir/$artist" || die "Can't open artist $dir/$artist: $!";
    my @albums = grep { !/^\./ } readdir $dh;
    closedir $dh || die "Error in $dir/$artist: $!";
    foreach my $album ( @albums ) {
        chomp( $album );
        next if ( ! -d "$dir/$artist/$album" );

        # get all the songs and the cover, discard everything else (which should be nothing)
        opendir $dh, "$dir/$artist/$album" || die "Can't open album $dir/$artist/$album: $!";
        my @songs = grep { m/.+\.mp3$/ } readdir $dh;
        seekdir $dh, 0;
        my $cover = ( grep { m/^cover\.\w{3}$/ } readdir $dh )[0];
        closedir $dh || die "Error in $dir/$artist/$album: $!";
        my $albumbandcamp = 0;  # true if any song on the album is from Bandcamp, because I don't want to overwrite anything from Bandcamp
        my $tracktotal = 1;  # set the total number of tracks on the album because why not

        foreach my $song ( @songs ) {
            chomp $song;
            my $file = "$dir/$artist/$album/$song";
            $file =~ s/"/\\"/g;
            # get all the relevant ID3 tags for this song
            open my $lines, '-|', "eyeD3 \"$file\"" || die "Couldn't run eyeD3: $!";
            my %tags = ();
            my @UTFs = ();  # only need to know the names of the UserTextFrames in order to remove them
            my $bandcamp = 0;  # don't change the artwork or tags on files gotten from Bandcamp
            # process them into a hash
            while ( <$lines> ) {
                chomp;
                if ( /: / ) {  # skip content lines
                    # split tag name from tag content
                    my @tag = split /: /, $_, 2;
                    if ( $tag[0] eq 'UserTextFrame' ) {
                        my $desc = ( $tag[1] =~ m/^\[Description: (.+)\]$/ )[0];
                        # escape colons because they are used in eyeD3 syntax
                        $desc =~ s/:/\\:/g;
                        push @UTFs, $desc;
                    } elsif ( $tag[0] eq 'Comment' ) {
                        # can remove all comments in one fell swoop so only check for Bandcamp
                        my $comment = <$lines>;
                        if ( $comment =~ m/bandcamp.com/ ) {
                            $bandcamp = 1;
                        }
                    } elsif ( $tag[0] eq 'Time' ) {
                        $tags{$tag[0]} = ( $tag[1] =~ m/^(\d+:\d+)\s+/ )[0];
                    } elsif ( $tag[0] eq 'track' ) {
                        $tags{$tag[0]} = ( $tag[1] =~ m/^(\d+)/ )[0];
                    } elsif ( scalar @tag == 1 ) {
                        # blank tags will split into only one item
                        $tags{$tag[0]} = '';
                    } elsif ( $tag[1] =~ /^\s+$/ ) {
                        $tags{$tag[0]} = '';
                    } else {
                        $tags{$tag[0]} = $tag[1];
                    }
                }
            }
            close $lines || die "Error in eyeD3: $! $?";
            foreach my $key ( ( "artist", "album", "title", "track" ) ) {
                if ( ! $tags{$key} || $tags{$key} eq '' ) {
                    if ( $key eq "artist" ) {
                        $tags{$key} = $artist;
                    } elsif ( $key eq "album" ) {
                        $tags{$key} = $album;
                    } elsif ( $key eq "title" ) {
                        $tags{$key} = ( $song =~ m/^(\d+ )?(.+)\.mp3$/ )[1];
                    } elsif ( $key eq "track" ) {
                        if ( $song =~ m/^\d+/ ) {
                            $tags{$key} = ( $song =~ m/^(\d+) / )[0];
                        } else {
                            $tags{$key} = 1;
                        }
                    }
                }
            }
            # count total tracks on the album
            if  ( $tags{'track'} > $tracktotal ) {
                $tracktotal = $tags{'track'};
            }
            # fix the tags
            if ( $bandcamp ) {  # don't change anything on bandcamp stuff
                $albumbandcamp = 1;
            } else {  # change the tags
                # escape quotes so we can double-quote it
                # remove all the user text frames
                foreach ( @UTFs ) {
                    system( 'bash', '-c', "eyeD3 --user-text-frame '$_:' \"$file\"" );
                }
                # remove all comments
                system( 'bash', '-c', "eyeD3 --remove-all-comments \"$file\"" );
                # these are the only four that are known independent of the tags
                foreach ( "artist", "album", "title", "track" ) {
                    my $tag = $tags{$_};
                    $tag =~ s/"/\\"/g;
                    system( 'bash', '-c', "eyeD3 --$_ \"$tag\" \"$file\"" );
                }
            }
        }
#        # replace the artwork with the picture in the folder, unless this album was downloaded from Bandcamp or has no cover image
        if ( $cover && ! $albumbandcamp ) {
            system( 'eyeD3', '--plugin', 'art', '-T', "$dir/$artist/$album" );
        }
        # set the total tracks on the album because why not
        foreach my $song ( @songs ) {
            my $file = "$dir/$artist/$album/$song";
            $file =~ s/"/\\"/g;
            system( 'bash', '-c', "eyeD3 --track-total $tracktotal \"$file\"" );
        }
        last;
    }
    last;
}
