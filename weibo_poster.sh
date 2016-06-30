#/bin/sh

weibo_text='早上好(｀・ω・´)” 今天琉璃神社挂了吗？'

if [ $(cat README.md | grep '今天琉璃神社挂了吗？ 没有' | wc -l) -gt 0 ]; then
	weibo_text="${weibo_text}没有。"
	gualema=0
else
	weibo_text="${weibo_text}卧槽？挂了。。。"
	gualema=1
fi

if [ $(cat lasterror.log | wc -l) -eq 0 ] && [ $gualema -eq 0 ]; then
	magnets_added=$(cat README.md | grep '同步成功 新增记录.*条' | head -n 1 | sed -e 's/\[.*\]//g' | sed -e 's/[^0-9]//g')
	weibo_text="${weibo_text}昨晚同步成功了(●´∀｀●) 新增${magnets_added}条磁力记录"
	titles_added=''
	back_commits=1
	while [ "$titles_added" == "" ]; do
		titles_added=$(git diff HEAD~${back_commits} HEAD resource_list.json | grep '+.*"title":' | sed -e 's/+.*"title": "//g' | sed -e 's/| 琉璃神社 ★ HACG"//g' | sed -e 's/ *$//g' | perl -pe 's/\n/, /g' | sed -e 's/, $//g')
		back_commits=$(($back_commits + 1))
	done
	weibo_text="${weibo_text} 最新资源：${titles_added}"
else
	weibo_text="${weibo_text}昨晚同步出错了哦(,,#ﾟДﾟ) 主人快来调♂教♂我 @炒鸡小学僧 DEBUG_INFO: $(cat lasterror.log)"
fi

weibo_text=$(echo $weibo_text | cut -c 1-138)
if [ ${#weibo_text} -eq 138 ]; then
	weibo_text="${weibo_text}..."
fi

echo $weibo_text

access_token=$(cat access_token)

curl 'https://api.weibo.com/2/statuses/update.json' --data-urlencode "access_token=${access_token}" --data-urlencode "status=${weibo_text}"
