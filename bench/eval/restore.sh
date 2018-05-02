source ~/.bash_profile

if [ "$#" -ne 2 ];then
    echo "Usage : $./restore.sh [nvme|hdd] [master|gmap]"
    exit
fi

if [ "$1" == "nvme" ];then
    use nvme
elif [ "$1" == "hdd" ];then
    use hdd
else
    echo "invalid argment"
    exit
fi

if [ "$2" != "master" -a "$2" != "gmap" ];then
    echo "target is invalid"
    exit
fi
TARGET=$2

stop ${TARGET}

base=`echo $PGBASE`
echo "base = $base"

# remove
rm -rf ${base}/${TARGET}/data/

# copy
echo "copying..."
time cp -r /nvme/bkup/${TARGET}_sf8000/ ${base}/${TARGET}/data

    
