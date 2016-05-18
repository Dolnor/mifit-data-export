#!/bin/bash
######################################################################################################
# Creator: jlaunay, thorough revision by TimeWalker75a
# Date   : 01/29/2015, revised 07/20/2015
# Purpose: Extract MiBand and MiScale database from Mi Fit app to your Local Unix Machine
######################################################################################################

SDPath=/storage/sdcard1 # temp mountpoint where to store data before pulling it locally
OpenHTML=Y				# open html form with aggregated data when extraction completes
LoadWeight=N 			# upload weight data to fitbit via oauth perl
	
MiBand=N			# whether to extract miband data or not
MiScale=Y			# whether to extract miscale data or not

ForceBackupMode=N 	# force native android backup approach
ExtractRaw=N	  	# whether to extract miband raw sensor data (events by minutes) and sumamry or not
Height=182			# height for raw data extraction
Weight=70			# weight for raw data extraction 

# i8n support
export TEXTDOMAIN=mibandextract
# folder with .mo langage file, comment this line if you want to move
# .mo file in /usr/share/locale/XX/LC_MESSAGES/
export TEXTDOMAINDIR=./i18n/

######################################################################################################
# Def backup mode assumes the phone is rooted and backups are not forced via adb backup functionality
######################################################################################################
function fetch_db_root
{
	case $1 in
	band) 
		device=MiBand
		data=origin_db;; 
	scale) 
		device=MiScale
		data=mihealth.db;;
	*) 
		echo $"unknown xiaomi device, exiting"
		exit 1;;
	esac

	echo $"backing up $device database" 2>&1 | tee -a log
	if [[ -f ./db/${data} ]]; then
		mv ./db/${data} ./${data}.bak 2>&1 | tee -a log
	fi
	if [[ -f ./db/${data}-journal ]]; then
		mv ./db/${data}-journal ./db/${data}-journal.bak 2>&1 | tee -a log
	fi
	
	echo $"adb copy $device temp data to sdcard" 2>&1 | tee -a log
	./bin/adb shell 'db=`su -c "ls /data/data/com.xiaomi.hm.health/databases/origin_db*(_+([0-9])) | tail -n 1"`; su -c "cp $db /sdcard/origin_db"' 2>&1 | tee -a log
	./bin/adb shell 'db=`su -c "ls /data/data/com.xiaomi.hm.health/databases/origin_db*(_+([0-9]))-journal | tail -n 1"`; su -c "cp $db /sdcard/origin_db-journal"' 2>&1 | tee -a log
	echo $"adb pull $device data from sdcard to local machine" >> log
	./bin/adb pull $SDPath/${data} ./db/${data} 2>&1 | tee -a log
	./bin/adb pull $SDPath/${data}-journal ./db/${data}-journal 2>&1 | tee -a log
	echo $"adb remove temp $device data on sdcard" >> log
	./bin/adb shell "rm -f ${SDPath}/${data} && rm -f ${SDPath}/${data}-journal" 2>&1 | tee -a log
}

echo $"extraction started on $(date +"%m/%d/%Y %H:%M")" 2>&1 | tee log

if [[ ! $ForceBackupMode = 'Y' ]]; then
	if [[ $MiBand = 'Y' ]]; then 
		fetch_db_root band
	fi

	if [[ $MiScale = 'Y' ]]; then 
		fetch_db_root scale
	fi
fi 
######################################################################################################
# If db files are not present in /db/ after default backup mode or backups forced - run native backups
######################################################################################################
if [[ ( ! -f ./db/origin_db && $MiBand = 'Y' ) || ( ! -f ./db/mihealth.db && $MiScale = 'Y' ) || 
      ( $ForceBackupMode = 'Y' ) ]]; then
	echo $"cannot find database files. non-rooted phone? attempting native backup approach" 2>&1 | tee -a log
    #echo "press Backup My Data button on device..." 2>&1 | tee -a log
    ./bin/adb backup -f mi.ab -noapk -noshared com.xiaomi.hm.health
    #tail -c +25 mi.ab > mi.zlb  2>&1 | tee -a log
    #cat mi.zlb | openssl zlib -d > mi.tar 2>&1 | tee -a log
    dd if=mi.ab bs=1 skip=24 | python -c "import zlib,sys;sys.stdout.write(zlib.decompress(sys.stdin.read()))" > mi.tar 2>&1 | tee -a log
    
	if [[ $MiBand = 'Y' ]]; then
		tar xvf mi.tar apps/com.xiaomi.hm.health/db/origin_db apps/com.xiaomi.hm.health/db/origin_db-journal 2>&1 | tee -a log
		cp -f apps/com.xiaomi.hm.health/db/origin_db* ./db/
		echo $"extracted MiBand database"  2>&1 | tee -a log
	fi

	if [[ $MiScale = 'Y' ]]; then 
		tar xvf mi.tar apps/com.xiaomi.hm.health/db/mihealth.db apps/com.xiaomi.hm.health/db/mihealth.db-journal 2>&1 | tee -a log
		cp -f apps/com.xiaomi.hm.health/db/mihealth.db* ./db/
		echo $"extracted MiScale database"  2>&1 | tee -a log
	fi

    echo $"deleting temp backup files" 2>&1 | tee -a log
    rm mi.ab && rm mi.tar
    rm -rf apps/
fi
######################################################################################################
# When we have db files we can perform queries on them to form csv and js files for HTML/FintessSync
# Otherwise we restore original database files and exit with status code 1
######################################################################################################
if [[ ( ! -f ./db/origin_db && $MiBand = 'Y' ) || ( ! -f ./db/mihealth.db && $MiScale = 'Y' ) ]]; then
    echo $"extraction failed"
    echo $"still cannot find new database files - restoring original database backups"
    
	if [[ $MiBand = 'Y' ]]; then 
		if [[ -f ./db/origin_db.bak ]]; then
			mv ./db/origin_db.bak ./db/origin_db
		fi
		
		if [[ -f ./db/origin_db-journal.bak ]]; then
			mv ./db/origin_db-journal.bak origin_db-journal
		fi
	fi

	if [[ $MiScale = 'Y' ]]; then 
		if [[ -f ./db/mihealth.db.bak ]]; then
			mv ./db/mihealth.db.bak ./db/mihealth.db
		fi
		if [[ -f ./db/mihealth.db-journal.bak ]]; then
			mv ./db/mihealth.db-journal.bak mihealth.db-journal
		fi
	fi

	exit 1
else
    echo $"ok, got new database files" 2>&1 | tee -a log
    
	if [[ $MiBand = 'Y' ]]; then 
		if [[ $ExtractRaw = 'Y' ]]; then
			echo $"sqlite extraction of raw MiBand sensor data"
			echo "INSERT INTO _PersonParams (Height,Weight) VALUES ($Height,$Weight);" > ./db/health.sql
			sqlite3 ./db/origin_db < ./db/miband_raw.sql  | tee -a log
		else
			echo $"sqlite extraction of MiBand data" 2>&1 | tee -a log
			sqlite3 ./db/origin_db < ./db/miband.sql | tee -a log
		fi
		rm -f ./db/origin_db.bak | tee -a log
		rm -f ./db/origin_db-journal.bak | tee -a log
	fi

	if [[ $MiScale = 'Y' ]]; then 
		if [[ -f ./db/mihealth.db ]]; then
			echo $"sqlite extraction of MiScale data" 2>&1 | tee -a log
			sqlite3 ./db/mihealth.db  < ./db/miscale.sql | tee -a log
		fi
		rm -f ./db/mihealth.db.bak | tee -a log
		rm -f ./db/mihealth.db-journal.bak | tee -a log
	fi
	echo $"extraction of data completed" 2>&1 | tee -a log
	if [[ ( $MiScale = 'Y' && $LoadWeight = 'Y' ) ]] && [[ -f upload_data.pl ]]; then
		echo $"uploading weight data to Fitbit ..." 2>&1 | tee -a log
		perl -w upload_data.pl
	fi
	if [[ ( $MiBand = 'Y' && $OpenHTML = 'Y' ) ]]; then
		open ./mi_data.html
	fi
fi

exit 0
