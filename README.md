# Day-of-Defeat-1.3 Map Pack Tools

The following repository from the Pucker Factor gaming community contains three scripts to help other gaming communities with res file handling and map packing of custom maps while overcoming the shortcomings of using RESgen by itself.

The scripts ensure the following things are included that RESgen typically misses:

- Map overviews: The green bars are annoying to users.
- sprites/obj_icons: These are flag icon files that are missed by RESgen.
- .res: The file includes the .res file itself.

If files are missing on map pack or quickftp creation the following text files are created that show you the files you are missing.

- missing_overviews.txt: Missing map overview files.
- missing_icons.txt: Missing map flag icons for maps that are known to have them.
- missing_files.txt: All missing files. Some listed .wad files may be irrelevent.

The scripts require RESgen to work. The source code of which can be found at the following location:

[RESgen](https://github.com/kriswema/resgen)

And on Windows Strawberry Perl needs to be installed which can be downloaded here:

[Strawberry Perl](http://strawberryperl.com/)

You can also find an already compiled exe at places like moddb.

- PF_DoD_QuickFTP.pl: Generate .res files from all custom maps in your dod folder.
- PF_Map_Pack_Creator.pl: Generate .res files from maps in mapcycle.txt. Place them in a zip file.
- mapcycle.pl: Generate a mapcycle.txt based on all maps in your dod/maps folder.

## Setup Instructions

Install strawberry perl then place the following files in the folder that contains your dod directory:

- RESgen.exe
- res_dod.rfa
- mapcycle.pl
- PF_DoD_QuickFTP.pl
- PF_Map_Pack_Creator.pl

Each perl script has a perldoc with instructions on how to use them. Basic information for each below.

You can double-click to run the scripts or run with perl *scriptname* on the command line.

## PF_DoD_QuickFTP.pl

Script will read all the .bsp files from your dod/maps directory then move them to dod_quickftp/dod/maps. RESGen will be run to generate the initial res file.
After the script ensures overviews and obj_icons are included in the file that is normally missed. Any missing files will be placed in the listed missing_*.txt files as listed above.

You can then push the dod file to your ftp server and point your server sv_downloadurl to it for quick ftp map access for your users.

## PF_Map_Pack_Creator.pl

Script will read in your mapcycle.txt file and move the .bsp files to dod_mappack/maps. RESGen will then be run to generate the initial res files. 
After the script ensures overviews and obj_icons are included in the file that is normally missed. Any missing files will be placed in the listed missing_*.txt files as listed above.

The folder will then be zipped up as dod_mappack.zip for easy upload to your site for users to download. You can change this name using the -d option on the command line.

## mapcycle.pl

Reads your dod/maps folder and generated a mapcycle.txt with all maps listed. Use --skip option to skip default maps.

## License

See LICENSE file.

## Author

=PF=RedBeard