#!/bin/bash
#added flags
github=''
version=''

while getopts 'g:v:' flag; do
  case "${flag}" in
     g) github="${OPTARG}" ;;
     v) version="${OPTARG}" ;;
  esac
done
#clone from github
#add option to add from certain branch (optional default to be master)
#change the name to voyagerZoneController
git clone --single-branch -b ${github:-master} https://github.com/raptordesign/voyagerZoneController.git voyagerZoneController

error_exit()
{
  echo "$1"
  exit 1
}

sudo cp filelist.txt voyagerZoneController/
sudo cp fileParser.py voyagerZoneController/
cd voyagerZoneController

#to freeze zcEngine.py
echo freezing zcEngine.py
if sudo pyinstaller --paths /usr/local/lib/python3.5/dist-packages/:/usr/lib/python3/dist-packages/ --hidden-import=dns.e164 --hidden-import=dns.hash --hidden-import=dns.namedict --hidden-import=dns.tsigkeyring --hidden-import=dns.update --hidden-import=dns.version --hidden-import=dns.zone --hidden-import=engineio.async_drivers.eventlet --log-level=DEBUG --onefile zcEngine/zcEngine.py > build.txt 2>&1; then
  echo frozen file zcEngine.py
else
  error_exit "could not freeze zcEngine.py."
fi &

#to freeze bq.py
echo freezing bq.py
if sudo pyinstaller --paths /usr/local/lib/python3.5/dist-packages/:/usr/lib/python3/dist-packages/ --add-data "bigQuery/key.json:key.json" --additional-hooks-dir /home/pi/voyager-zc/hooks/ --hidden-import=google.cloud.bigquery --hidden-import=google.resumable_media.requests --log-level=DEBUG --onefile bigQuery/bq.py > build.txt 2>&1; then 
  echo frozen file bq.py
else
  error_exit "could not freeze bq.py."
fi &

#read the file for pyservice
sudo python3 fileParser.py &
wait

mapfile -t fileList < filelist.txt

mapfile -t services < listfile.txt

#to freeze all other files
let i = 0
let N = 4

for line in ${fileList[@]}
do
  line_no_space="$(echo -e "${line}" | tr -d '[:space:]')"
  (( j=j%N )); (( j++==0 )) && wait
  echo freezing file ${services[i]}
  if sudo pyinstaller --paths /usr/local/lib/python3.5/dist-packages/:/usr/lib/python3/dist-packages/ --log-level=DEBUG --onefile "$line_no_space" > build.txt 2>&1; then
    echo frozen file ${services[i]}
  else
    error_exit "could not freeze file ${services[i]}."
  fi &
  (( i = i + 1 ))
done
wait
sudo cp misc/makeRelease.sh /home/pi/makeRelease.sh
cd /home/pi
sudo chmod +x makeRelease.sh
./makeRelease.sh $version
cd Voyager-Zone-Controller
touch $version
cd ..
tar -cvf Voyager-Zone-Controller.tar Voyager-Zone-Controller
cp Voyager-Zone-Controller.tar Voyager-Zone-Controller/
