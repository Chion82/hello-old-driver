#!/bin/sh

website_url='http://www.llss.tv'
first_run_time=1455976198

for i in {1..10}
do
	test_result=$(curl $website_url -I | grep '200 OK' | wc -l)
	if [ $test_result -eq 1 ]; then
		website_test_passed=1
		gua_le_ma='没有'
		break
	else
		website_test_passed=0
		gua_le_ma='卧槽...挂了'
	fi
done

test -d 'archives' || mkdir 'archives'
cp magnet_output ./archives/magnet_output-$(date +"%F-%H%M%S")
cp resource_list.json ./archives/resource_list.json-$(date +"%F-%H%M%S")

test -d 'log' || mkdir 'log'
cp lastsync.log ./log/sync.log-$(date +"%F-%H%M%S")
if [ $(cat lasterror.log | wc -l) -gt 0 ];then
	cp lasterror.log ./log/error.log-$(date +"%F-%H%M%S")
fi

if [ $website_test_passed -eq 1 ]; then
	echo -e "${website_url}\n" | python magnet_crawler.py > lastsync.log 2> lasterror.log
	if [ $(cat lasterror.log | wc -l) -gt 0 ]; then
		sync_success=0
	else
		sync_success=1
	fi
else
	sync_success=0
fi

if [ $sync_success -eq 1 ]; then
	added_magnets=$(expr $(cat magnet_output | grep "magnet:?" | wc -l) - $(cat last_magnet_numbers.txt))
	echo $(date) > last_sync_success.txt
	echo $(cat magnet_output | grep "magnet:?" | wc -l) > last_magnet_numbers.txt
	echo -e "[$(date)] 同步成功 新增记录${added_magnets}条  \n$(cat synclog.txt)" > synclog.txt
else
	echo -e "[$(date)] 同步失败  \n$(cat synclog.txt)" > synclog.txt
fi

cp readme_header.md README.md
echo '今天琉璃神社挂了吗？ '$gua_le_ma'  ' >> README.md
echo '最后同步成功时间:  '$(cat last_sync_success.txt)'  ' >> README.md
echo '已抓取磁力链: '$(cat magnet_output | grep "magnet:?" | wc -l)'  ' >> README.md
echo '本repo已存活: '$(expr $(expr $(date +"%s") - $first_run_time) / 60 / 60 / 24)'天  ' >> README.md

echo -e '\nLog' >> README.md
echo '----' >> README.md
cat synclog.txt >> README.md

git add .
git commit -m "Sync on $(date)"
git push origin master -f
