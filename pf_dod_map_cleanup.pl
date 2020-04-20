#!C:\strawberry\perl\bin\perl.exe

use File::Path qw(make_path);
use File::Basename;
use File::Spec::Functions;
use File::Copy;
use strict;
use warnings;

my $main_directory = 'dod';
my $cleaned_directory = 'dod2';
my $main_maps_directory = 'dod/maps';
my $cleaned_maps_directory = 'dod2/maps';
my $main_overviews_directory = 'dod/overviews';
my $cleaned_overviews_directory = 'dod2/overviews';
my $mapsfolder = 'maps';
my $overviewsfolder = 'overviews';
my $object_icons_path = 'sprites/obj_icons';
my @missingoverviews = ();
my @maps = ();
my @missingfiles = ();

sub make_a_directory($);

my %to_skip = ("dod_avalanche.bsp", 1, "dod_anzio.bsp", 1, "dod_caen.bsp", 1, "dod_charlie.bsp", 1, "dod_chemille.bsp", 1, "dod_donner.bsp", 1, "dod_escape.bsp", 1, "dod_falaise.bsp", 1, "dod_flash.bsp", 1, "dod_flugplatz.bsp", 1, "dod_forest.bsp", 1, "dod_glider.bsp", 1, "dod_jagd.bsp", 1, "dod_kalt.bsp", 1, "dod_kraftstoff.bsp", 1, "dod_merderet.bsp", 1, "dod_northbound.bsp", 1, "dod_saints.bsp", 1, "dod_sturm.bsp", 1, "dod_switch.bsp", 1, "dod_vicenza.bsp", 1, "dod_zalec.bsp", 1);

opendir(DODDIR, $main_maps_directory) || die ("Cannot open directory");

while(readdir(DODDIR)){
	if ($_ =~ /\.bsp/ && ! $to_skip{lc($_)}) { push(@maps, lc($_));}
}
closedir(DODDIR);

if (! -d $cleaned_maps_directory){ make_a_directory($cleaned_maps_directory);}

foreach(@maps){
	my $originalpath = catfile($main_maps_directory, $_);
	my $cleanedpath = catfile($cleaned_maps_directory, $_);
	
	if (-f $originalpath && ! -f $cleanedpath) {copy($originalpath, lc($cleanedpath));}
}

system("RESGen -gk -d $cleaned_maps_directory -b res_dod.rfa");

foreach(@maps)
{
	my @files = ();
	my $resfile = catfile($cleaned_maps_directory, $_);
	$resfile =~ s/.bsp/.res/g;
	$resfile =~ s/\\/\//g;
	my $resfilepath = catfile($mapsfolder, $_);
	$resfilepath =~ s/\.bsp/\.res/g;
	$resfilepath =~ s/\\/\//g;
	my $txtfilepath = catfile($mapsfolder, $_);
	$txtfilepath =~ s/\.bsp/\.txt/g;
	$txtfilepath =~ s/\\/\//g;
	
	my $mapsoriginaltxtfile = catfile($main_directory, $txtfilepath);
	if(! -f $mapsoriginaltxtfile){
		my $mapsnewtxtfile = catfile($cleaned_directory, $txtfilepath);
		open TXTFILE, ">$mapsnewtxtfile";
		
		print TXTFILE "Original map.txt has been lost.\n\nThis file has been generated by Pucker Factor's map directory cleansing tool\n\n";
		print TXTFILE "Visit us at www.puckerfactor.com.";
		
		close(TXTFILE);
	}
	
	
	
	my $overviewtxtpath = catfile($overviewsfolder, $_);
	$overviewtxtpath =~ s/\.bsp/\.txt/g;
	$overviewtxtpath =~ s/\\/\//g;
	my $overviewpath = catfile($overviewsfolder, $_);
	$overviewpath =~ s/\.bsp/\.bmp/g;
	$overviewpath =~ s/\\/\//g;
	my $mapfolder = $_;
	$mapfolder =~ s/\.bsp//;
	push(@files, $resfilepath);
	push(@files, $txtfilepath);
	push(@files, $overviewpath);
	push(@files, $overviewtxtpath);
	
	if (-f $resfile)
	{
		open RES, "<$resfile";

		while (<RES>) {

		if($_ !~ /^\/\// && $_ !~ /^\s*$/ && $_ !~ /^maps/ && $_ !~ /^overviews/) {
			chomp($_);
			push(@files, lc($_)); 
			}
		}
		close(RES);
	}
	my @object_icons = ();
	my $object_icon_test = catdir($main_directory, $object_icons_path, $mapfolder);
	
	
	if (-d $object_icon_test){
	
		opendir(OBJECTDIR, $object_icon_test) || die ("Cannot open directory");

		while(readdir(OBJECTDIR)){
			if ($_ =~ /\.spr$/) { push(@object_icons, lc($_));}
		}
		closedir(OBJECTDIR);
	}
	
	foreach(@object_icons) {
		my $icons_path = catfile($object_icons_path, $mapfolder, $_);
		$icons_path =~ s/\\/\//g;
		push(@files, $icons_path);
	}

	my @sortedfiles = ();

	@sortedfiles = sort { lc($a) cmp lc($b) } @files; 
	
	foreach(@sortedfiles)
	{
		my $origfile = catfile($main_directory, $_);
		my $cleanedfile = catfile($cleaned_directory, $_);
		my $pathcheck = dirname($cleanedfile);
		
		if(! -d $pathcheck) {make_a_directory($pathcheck);}
		
	    if (-f $origfile && ! -f $cleanedfile) {copy($origfile, lc($cleanedfile));}
		elsif (! -f $origfile && $origfile =~ /\.bmp/) {push(@missingoverviews, $_);}
		elsif (! -f $origfile && $origfile !~ /\.res/) {push(@missingfiles, $_);}
	
	}
	

	open RES, ">$resfile";
	
	print RES "// RES File generated with resgen 2.0.2\n";
	print RES "// File cleansed by Pucker Factor's map folder and resgen cleanup script\n";
	print RES "// For more information visit us at www.puckerfactor.com\n\n";

	foreach(@sortedfiles)
	{
		print RES "$_\n";
	}

	close(RES);

}
	open MISSING, ">missing.txt";
	if(@missingfiles){
		print "THE FOLLOWING FILES ARE MISSING!!!\n";
		print MISSING "THE FOLLOWING FILES ARE MISSING!!!\n\n";
		foreach(@missingfiles)
		{
			print "$_\n";
			print MISSING "$_\n";
		}
	}
	close(MISSING);
	
	open OVERVIEWS, ">overviews.txt";
	if(@missingoverviews){
		print "THE FOLLOWING OVERVIEWS ARE MISSING!!!\n";
		print OVERVIEWS "THE FOLLOWING OVERVIEWS ARE MISSING!!!\n\n";
		foreach(@missingoverviews)
		{
			print "$_\n";
			print OVERVIEWS "$_\n";
		}
	}
	close(OVERVIEWS);
	
	move($main_directory, "dod_uncleansed");
	move($cleaned_directory, $main_directory);
	
	exit();

sub make_a_directory($){
	my ($directory) = @_;
	$directory = lc($directory);
	$directory =~ s/^\///;
	make_path($directory, {
		verbose => 1,
		mode => 777,
	});
}