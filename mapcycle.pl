#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);
use Carp qw(croak);
use File::Basename;
use File::Spec::Functions;
use Getopt::Long qw(:config bundling auto_version auto_help);
use Pod::Usage;

our $VERSION = '1.0.0';

# Option variables
my $skip_defaults;

# GetOptions
GetOptions( 'skip_defaults|s' => \$skip_defaults, )
  or exit 1;

# Set default variables
my $main_maps_directory = 'dod/maps';
my $mapcycle            = 'mapcycle.txt';
my @maps;

# Default maps we can skip for full custom mapcycle.txt files.
my %to_skip = (
    'dod_avalanche.bsp', 1, 'dod_anzio.bsp',      1, 'dod_caen.bsp',       1,
    'dod_charlie.bsp',   1, 'dod_chemille.bsp',   1, 'dod_donner.bsp',     1,
    'dod_escape.bsp',    1, 'dod_falaise.bsp',    1, 'dod_flash.bsp',      1,
    'dod_flugplatz.bsp', 1, 'dod_forest.bsp',     1, 'dod_glider.bsp',     1,
    'dod_jagd.bsp',      1, 'dod_kalt.bsp',       1, 'dod_kraftstoff.bsp', 1,
    'dod_merderet.bsp',  1, 'dod_northbound.bsp', 1, 'dod_saints.bsp',     1,
    'dod_sturm.bsp',     1, 'dod_switch.bsp',     1, 'dod_vicenza.bsp',    1,
    'dod_zalec.bsp',     1
);

# If no directory exit
if ( !-d $main_maps_directory ) {
    pod2usage( -msg =>
          'Please place this file in the same directory as your dod folder.' );
}

# Set files we want to pull and glob them in.
my $globfile = catfile( $main_maps_directory, '*.bsp' );
my @allmaps  = glob $globfile;

# Remove full path as it is not needed for mapcycle.txt
for (@allmaps) { $_ = basename($_); }

# Place all maps into @maps while skipping defaults.
for my $map (@allmaps) {
    if ( !$to_skip{ lc $map } ) { push @maps, lc $map; }
}

# Determine whether to write defaults or not
if ($skip_defaults) {
    write_mapcycle(@maps);
}
else {
    write_mapcycle(@allmaps);
}

sub write_mapcycle {
    my (@list) = @_;

# Mapcycle.txt does not expect to have .bsp added in it. Remove it from the files.
    for (@list) { s/[.]bsp//xms; }

    # Write out mapcycle.txt
    open my $mapfile, '>', $mapcycle or croak $!;
    for (@list) { say {$mapfile} $_ }
    close $mapfile or croak $!;

    return 0;
}

1;

__END__

=head1 NAME

mapcycle.pl - Generates a Day of Defeat 1.3 mapcycle.txt. 

=head1 DESCRIPTION

Script mapcycle.pl should be placed in the same folder as your dod folder where the script can read dod/maps.
The file will then read all the .bsp files and create a mapcycle.txt. If you only want custom maps use the -s or --skip_defaults
command line option to skip default maps.

=head1 USAGE

 mapcycle.pl
 mapcycle.pl -s
 mapcycle.pl --skip_defaults

=head1 OPTIONS

=over 4

=item B<-s, --skip_defaults>

When creating mapcycle.txt will skip the default Day of Defeat 1.3 maps.

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
