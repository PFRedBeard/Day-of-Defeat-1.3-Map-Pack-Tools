#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);
use Carp qw(croak);
use File::Basename;
use File::Copy;
use File::Path qw(make_path);
use File::Spec::Functions;
use Getopt::Long qw(:config bundling auto_version auto_help);
use Pod::Usage;

our $VERSION = '1.0.0';

# GetOptions
GetOptions() or exit 1;

# Set default variables
my $main_dir               = 'dod';
my $quickftp_dir           = 'dod_quickftp/dod';
my $maps_dir               = 'maps';
my $overview_dir           = 'overviews';
my $object_icons_dir       = 'sprites/obj_icons';
my $main_maps_dir          = catdir( $main_dir, $maps_dir );
my $quickftp_maps_dir      = catdir( $quickftp_dir, $maps_dir );
my $main_overviews_dir     = catdir( $main_dir, $overview_dir );
my $quickftp_overviews_dir = catdir( $quickftp_dir, $overview_dir );
my $rfa_file               = 'res_dod.rfa';
my $resgen                 = "resgen -gkv -d $quickftp_maps_dir -b $rfa_file";
my @maps;
my @missingoverviews;
my @missingicons;
my %missingfiles;

# Set default maps
my %to_skip = (
    'dod_avalanche.bsp', 1, 'dod_anzio.bsp',      1, 'dod_caen.bsp',       1,
    'dod_charlie.bsp',   1, 'dod_chemille.bsp',   1, 'dod_donner.bsp',     1,
    'dod_escape.bsp',    1, 'dod_falaise.bsp',    1, 'dod_flash.bsp',      1,
    'dod_flugplatz.bsp', 1, 'dod_forest.bsp',     1, 'dod_glider.bsp',     1,
    'dod_jagd.bsp',      1, 'dod_kalt.bsp',       1, 'dod_kraftstoff.bsp', 1,
    'dod_merderet.bsp',  1, 'dod_northbound.bsp', 1, 'dod_saints.bsp',     1,
    'dod_sturm.bsp',     1, 'dod_switch.bsp',     1, 'dod_vicenza.bsp',    1,
    'dod_zalec.bsp',     1,
);

# These maps have special flag .spr files in sprites/obj_icons.
my %known_maps_spec_icons = (
    'dod_advance',   1, 'dod_ambushcombat', 1, 'dod_belfort_b2', 1,
    'dod_commando',  1, 'dod_density_b4',   1, 'dod_factory',    1,
    'dod_frost2',    1, 'dod_frosty2',      1, 'dod_koln_b3',    1,
    'dod_pizzano',   1, 'dod_push',         1, 'dod_riverlo',    1,
    'dod_saisie_b1', 1, 'dod_sanctuary',    1, 'dod_scrambled',  1,
    'dod_temple',    1, 'dod_tiger2_b2',    1,
);

main();

sub main {

    # Run directory and RFA file checks
    checks();

    # Set @maps by reading from directory
    setmaps();

    # Create mappack directory and move files over
    copymaps();

    # Run Resgen on new map directory. No or as file will stop here.
    system $resgen;

    # Modify Res File
    modifyres();

    # Write missing files
    writemissing();

    exit 0;
}

sub checks {

    # If no directory exit
    if ( !-d $main_maps_dir ) {
        pod2usage( -msg =>
              'Please place this file in the same directory as your dod folder.'
        );
    }

    # if No RFA file exit
    if ( !-f $rfa_file ) {
        pod2usage(
            -msg => "RFA file $rfa_file is required to run this script." );
    }

    return 0;
}

sub setmaps {

    # Set files we want to pull and glob them in.
    my $globfile = catfile( $main_maps_dir, '*.bsp' );
    my @allmaps  = glob $globfile;

    # Remove full name from path and lowercase.
    for (@allmaps) { $_ = basename(lc); }

    # Place all maps into @maps while skipping defaults.
    for my $map (@allmaps) {
        if ( !$to_skip{$map} ) { push @maps, $map; }
    }

    return 0;
}

sub copymaps {

    # Create map pack directory if it does not exist
    if ( !-d $quickftp_maps_dir ) {
        make_a_dir($quickftp_maps_dir);
    }

    # Go through each map and copy it over if not in the mappack dir
    for my $map (@maps) {
        my $origfile    = catfile( $main_maps_dir,     $map );
        my $mappackfile = catfile( $quickftp_maps_dir, $map );

        if ( -f $origfile && !-f $mappackfile ) {
            copy( $origfile, $mappackfile );
        }
    }

    return 0;
}

sub modifyres {

    # Run through each map and modify res file
    for my $map (@maps) {
        my @files;

        # Set mapbase
        ( my $mapbase = $map ) =~ s/[.] bsp//xms;

        # Set res and txt file absolute paths. Ensure path uses / not \
        my $resfile = catfile( $quickftp_maps_dir, "$mapbase.res" );
        $resfile =~ s/\\/\//gxms;

        # Set res and txt file relative paths. Ensure path uses / not \
        my $resfilepath = catfile( $maps_dir, "$mapbase.res" );
        $resfilepath =~ s/\\/\//gxms;

        # Set txt file relative path. Ensure path uses / not \
        my $txtfilepath = catfile( $maps_dir, "$mapbase.txt" );
        $txtfilepath =~ s/\\/\//gxms;

        # Write out text file for map if missing.
        checktxtfile($txtfilepath);

        # Set overview txt file and overview bmp file
        my $overviewtxt = catfile( $overview_dir, "$mapbase.txt" );
        my $overviewbmp = catfile( $overview_dir, "$mapbase.bmp" );
        $overviewtxt =~ s/\\/\//gxms;
        $overviewbmp =~ s/\\/\//gxms;

        # Add files to @files
        push @files, $resfilepath, $txtfilepath;
        push @files, $overviewtxt, $overviewbmp;

        # Read res files and add them to @files
        readres( \@files, $resfile );

        # Check for object icons
        readicons( \@files, $mapbase );

        # Sort files while ignoring case
        my @sortedfiles = sort { lc $a cmp lc $b } @files;

        # Check files for missing files.
        checkmissing( \@sortedfiles );

        # Write the new resfile
        writeres( \@sortedfiles, $resfile );
    }

    return 0;
}

sub checktxtfile {
    my $txtfilepath = shift;

    my $txt = basename($txtfilepath);

    # Set message for missing txt file.
    my $message = <<"END";
Original $txt file has been lost.

This file has been generated by one of the Pucker Factor map pack scripts.

The source code for these scripts can be found here:

https://github.com/PFRedBeard/Day-of-Defeat-1.3
END

    # Check if original txtfile exists
    my $origtxtfile = catfile( $main_dir, $txtfilepath );
    if ( -f $origtxtfile ) {
        my $newtxtfile = catfile( $quickftp_dir, $txtfilepath );

        # If not write out our message.
        open my $txtfile, '>', $newtxtfile or croak $!;
        say {$txtfile} $message;
        close $txtfile or croak $!;
    }

    return 0;
}

sub readres {
    my ( $files, $resfile ) = @_;

    if ( -f $resfile ) {

        # Read in the resfile
        open my $res, '<', $resfile or croak $!;
        chomp( my @lines = <$res> );
        close $res or croak $!;

        # Skip maps and overviews as we already took care of that.
        # Skip blank lines and comments as well.
        for my $line (@lines) {
            if (   $line !~ /\A\/\//xms
                && $line !~ /\A\s*\z/xms
                && $line !~ /\Amaps/xms
                && $line !~ /\Aoverviews/xms )
            {
                push @{$files}, lc $line;
            }
        }
    }
    return 0;
}

sub readicons {
    my ( $files, $mapbase ) = @_;

    my $pathtoicons = catdir( $main_dir, $object_icons_dir, $mapbase );

    if ( -d $pathtoicons ) {
        my $globfile     = catfile( $pathtoicons, '*.spr' );
        my @object_icons = glob $globfile;
        for (@object_icons) {
            $_ = basename(lc);
            $_ = catfile( $object_icons_dir, $mapbase, $_ );
        }

        push @{$files}, @object_icons;
    }

    if ( !-d $pathtoicons && $known_maps_spec_icons{$mapbase} ) {
        push @missingicons, $mapbase;
    }
    return 0;
}

sub checkmissing {
    my ($files) = @_;

    for my $file ( @{$files} ) {
        my $origfile = catfile( $main_dir,     $file );
        my $mpfile   = catfile( $quickftp_dir, $file );
        my $pathcheck = dirname($mpfile);

        if ( !-d $pathcheck ) { make_a_dir($pathcheck); }

        if ( -f $origfile && !-f $mpfile ) {
            copy( $origfile, $mpfile );
        }
        elsif ( !-f $origfile && $origfile =~ /[.] bmp/xms ) {
            push @missingoverviews, $file;
        }
        elsif ( !-f $origfile && $origfile !~ /[.] res/xms ) {
            $missingfiles{$file}++;
        }
    }

    return 0;
}

sub writeres {
    my ( $files, $resfile ) = @_;

    my $header = <<'END';
// RES File generated with RESGen and Pucker Factor Map Pack scripts.
// RESGen source can be found here: https://github.com/kriswema/resgen
// Pucker Factor Map Pack Scripts can be found here: https://github.com/PFRedBeard/Day-of-Defeat-1.3
END

    open my $res, '>', $resfile or croak $!;
    say {$res} $header;
    for ( @{$files} ) { say {$res} $_; }
    close $res or croak $!;

    return 0;
}

sub writemissing {

    # If missing files let user know.
    if ( keys %missingfiles ) {
        say 'THE FOLLOWING FILES ARE MISSING!!!';
        open my $missing, '>', 'missing_files.txt' or croak $!;
        say {$missing} 'THE FOLLOWING FILES ARE MISSING!!!';
        foreach ( sort keys %missingfiles ) {
            say;
            say {$missing} $_;
        }
        close $missing or croak $!;
    }

    # If missing overviews let user know.
    if (@missingoverviews) {
        say 'THE FOLLOWING OVERVIEWS ARE MISSING!!!';
        open my $overviews, '>', 'missing_overviews.txt' or croak $1;
        say {$overviews} 'THE FOLLOWING OVERVIEWS ARE MISSING!!!';
        foreach (@missingoverviews) {
            say;
            say {$overviews} $_;
        }
        close $overviews or croak $!;
    }

    # If missing object icons let user know.
    if (@missingicons) {
        say 'THE FOLLOWING OBJECT ICONS ARE MISSING!!!';
        open my $icons, '>', 'missing_icons.txt' or croak $!;
        say {$icons} 'THE FOLLOWING OBJECT ICONS ARE MISSING!!!';
        foreach (@missingicons) {
            say;
            say {$icons} $_;
        }
        close $icons or croak $!;
    }

    return 0;
}

sub make_a_dir {
    my $directory = lc shift;
    make_path(
        $directory,
        {
            verbose => 1,
            mode    => 777,
        }
    );
    return 0;
}

1;

__END__

=head1 NAME

PF_DoD_QuickFTP.pl - Generates complete res files for custom DOD maps and places all assets into dod_quickftp.

=head1 DESCRIPTION

Script PF_DoD_QuickFTP.pl should be placed in the same folder as your dod folder where the script can read dod/maps.
The file will then run resgen to generate the initial res files. Then it ensures all overviews and map txt files are accounted for.
Last it looks for sprites/obj_icons for custom flags to include them in the new res file. 
All the files needed for all your custom maps are then moved to dod_quickftp. 

You can then merge the contents of this folder into your dod server on your http/ftp site for quick downloads.

Missing file names will be placed into the following text files:

 missing_overviews.txt - Missing map overviews.
 missing_icons.txt     - Missing flag icons.
 missing_files.txt     - All other missing files + the above.


=head1 REQUIRED EXTERNAL COMMANDS

This script will not run without Strawberry Perl and resgen being installed.

Download Strawberry Perl here: http://strawberryperl.com/

Source code for resgen can be found here:

 https://github.com/kriswema/resgen

You can also find already compiled versions at places such as moddb.

=head1 USAGE

 PF_DoD_QuickFTP.pl

=head1 OPTIONS

=over 4

=item B<-?, --help>

Display help information.

=item B<--version>

Display version information.

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 by =PF=RedBeard

This library is free software; you can redistribute it and/or modify
it under the same terms as perl itself, either Perl version 5.30.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 AUTHOR

 =PF=RedBeard <redbeard@puckerfactor.com>

=cut
