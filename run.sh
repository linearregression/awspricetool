# aws site changes multiple times a day and may have js file format in error
# may need to run several times to get whole set
# validate data against previous set and check the version

export DDATE=`date "+%Y%m%d-%H%M%S"`
export NSPR_LOG_FILE=${DDATE}_awsec2.txt
export NSPR_LOG_MODULES=nsHttp:3

# 
firefox -new-instance -silent 'http://aws.amazon.com/ec2/pricing/' & 
sleep 60 && pkill firefox
mkdir -p data && mkdir -p data/${DDATE}

# extract url resources
grep -n GET\ /pricing ${NSPR_LOG_FILE} | sed 's/HTTP\/1.1//g' >> ${DDATE}_awsec2get.txt
grep -n GET\ /spot.js ${NSPR_LOG_FILE} >> ${DDATE}_awsec2getspots.txt
grep -n Host:  ${NSPR_LOG_FILE} | sed 's/Host\:/Host/g' >> ${DDATE}_awsec2host.txt

# 
cat ${DDATE}_awsec2getspots.txt >> ${DDATE}_awsec2result.txt
cat ${DDATE}_awsec2get.txt >> ${DDATE}_awsec2result.txt
cat ${DDATE}_awsec2host.txt >> ${DDATE}_awsec2result.txt

# remove unneeded characters, blank lines and pair resource with host
sed 's/\:.*\://g' ${DDATE}_awsec2result.txt | sort -k 2n,2 >> ${DDATE}_awsec2result_sorted.txt
grep -A 1 GET\  ${DDATE}_awsec2result_sorted.txt | sed -e 's/^--$//g' -e '/^$/d' >> ${DDATE}_awsec2result_assests.txt

# stitch resource url and retrieve 
echo 'Form resource url'
python get_ec2_price.py ${DDATE}_awsec2result_assests.txt ${DDATE}_awsec2url.txt

# wget 
echo 'Download pricing resource from aws..'
cat ${DDATE}_awsec2url.txt | xargs wget -d -T 10

# normalize filenames
# mv ${DDATE}_awsec2url.txt data/${DDATE}
echo 'Basic cleanse pricing data file..'
ls | xargs rename -v -f 's/\.js?.*/.js/'

# cleanse comment blocks and normalize to plain old js objects
mv spot.js spot.bak
ls *.js | xargs sed -i -e '1,5d' -e 's/^callback(//g' -e 's/);$//g'
mv spot.bak spot.js
sed -i -e 's/^callback(//g' -e 's/)$//g' spot.js
mv spot.js spot.json


# convert to csv file
# npm install j2j
# sudo gem install js2json
for i in *.js
do
   echo 'converting '$i 'to '$i'.json.'
   j2j.js debug -f $i -o $i.json 
   sleep 3
done

#  
# mv *.js data/${DDATE}
echo 'move data file to share.'
mv *.json data/${DDATE}

# cleanse intermediate files
rm -f *.txt *.js *.json

# 
unset NSPR_LOG_FILE
unset DDATE



