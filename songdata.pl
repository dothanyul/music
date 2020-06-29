#!/usr/bin/env perl
use strict;
use warnings;
use Env qw( HOME );

# require the artist, album, title, track number, artwork
# if an artwork already exists, move it to BACK_COVER and give it the given cover

my $dir = "$HOME/Documents/code/perl/music";

# loop over every artist
foreach my $artist ( qx( ls -- "$dir" ) ) {
    chomp( $artist );
    next if ( $artist eq 'playlists' || $artist eq 'Artwork' );

    # loop over each album in each artist
    foreach my $album ( qx( ls -- "$dir/$artist" ) ) {
        chomp( $album );
        next if ( ! -d "$dir/$artist/$album" );

        # get all the songs and the cover, discard everything else (which should be nothing)
        my @files = qx( ls -- "$dir/$artist/$album" );
        my $cover;
        my @songs = ();

        foreach my $file ( @files ) {
            chomp( $file );
            if ( $file =~ m/^cover\./ ) {
                $cover = $file;
            } elsif ( $file =~ m/\.mp3$/ ) {
                push @songs, $file;
            }
        }

        foreach my $song ( @songs ) {
            print "$artist/$album/$song\n";
            # get all the ID3 tags for this song
            my @lines = qx( eyeD3 "$dir/$artist/$album/$song" );
            my %tags = ();
            # process them into a hash
            foreach ( 0..$#lines ) {
                chomp( my $line = $lines[$_] );
                if ( $line =~ /: / ) {
                    # split tag name from tag content
                my @tag = split /: /, $line, 2;
                    if ( $tag[0] eq 'UserTextFrame' ) {
                        # UserTextFrame tags have additional tag information after the colon and the content is on the next line
                        $tag[2] = substr $tag[2], 0, -1;
                        chomp( $lines[$_+1] );
                        $tags{"$tag[0]_$tag[2]"} = $lines[$_+1];
                    } elsif ( scalar @tag == 1 ) {
                        # blank tags will split into only one item
                        $tags{$tag[0]} = '';
                    } else {
                        $tags{$tag[0]} = $tag[1];
                    }
                }
            }
            foreach my $key ( keys %tags ) {
                print "$key|$tags{$key}\n";
            }
        }
    }
    last;
}
