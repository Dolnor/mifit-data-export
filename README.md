# What is this ?

A script that works in conjuction with SQLite to pull activity and weight data from Xiaomi's Mi Fit Android application for MiBand & MiScale and visualise it via Google Charts.

The original author is @xmxm - [Xiaomi Mi Band data extraction](http://forum.xda-developers.com/general/accessories/xiaomi-mi-band-data-extraction-t3019156), script for Unix adapted here from the batch script for Windows. 

Author's intention was to define certain query format so tha the data obrained from Mi Fit could be visualised and also imported to othe services, such as Fitbit via FitnessSyncer. Details on that in original thread over at xda.

However, FitnessSyncer requires credential renewal with Fitbit on a daily basis and can cause lots of struggle. 

As I only needed the daily weight report from MiScale to be imported to Fitbit (I don't own an Aria, but weigh myself in daily), I though I'd better off rely upon something more flexible rather than a propriatory service - @cbown 's [fitbit-oauth-perl](https://github.com/Dolnor/fitbit-oauth-perl), modified to work with Fitbit's Header OAuth token authorisation. 


## Preparation Steps

1. Version of sqlite3 preinstalled on your machine might be too old, so you might need to obtain something fresh

2. Grand main script proper permissions: chmod +x run.sh

3. Check that your sqlite3 is properly configured for your time zone. Run following command and see if it returns correct timestamp:

			sqlite3 dbfile "select datetime('now','localtime');"


## Checking Configuration Settings

1. Review SDPath parameter value in run.sh. The program will copy files from Mi Fit app location to folder specified in SDPath before pulling them locally. 
In most cases default value (/sdcard) shoud work fine, however if your phone does not have this directory, find appropriate path.

2. Review config.js and make any changes to your liking (set Goals for sleep hours and daily steps, force override UI language to specific value)

3. If you do not want main report being open every time you run extract, change OpenHTML=Y in run.sh to OpenHTML=N

4. If your device is not rooted or have any issues with default bacup method, set ForceBackupMode value to Y in run.sh.


## Performing Data Extract

1. Connect your phone through USB and make sure USB debugging setting is enabled on your phone.

2. Execute run.sh - if your phone is rooted, the data would be pulled automatically. 
If your phone is not rooted you would see backup screen and you need to press "Back up my data" button in the bottom left.

3. Data from your MiBand/Scale will be saved to extract.csv file and extract.js, scale data to miscale_weight.csv. 
After extraction is complete, if OpenHTML is set to Y, mi_data.html will be opened automatically to show charts for your Mi usage. If you have followed fitbit-oauth-perl guide on getting your token, you can use LoadWeight to upload your MiScale data to Fitbit.

4. HTML reports are using Google Charts framework, which needs working internet access for reports to work. 
Your data is not being sent to Google, the internet connection is only used to download latest version of Google Charts javascripts.


## Configuration and Localization

config.js - set initial daily goal values; select interface language

locale.js - contains all locale data

run.sh - rest of the data extraction-relates settings, see comments for more info

