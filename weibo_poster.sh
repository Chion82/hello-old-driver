#/bin/sh

weibo_text='早上好，这里是某神社的更新姬http://t.cn/RGOhCMf '

if [ $(cat README.md | grep '今天琉璃神社挂了吗？ 没有' | wc -l) -gt 0 ] && [ $(cat lasterror.log | wc -l) -eq 0 ]; then
	weibo_text="${weibo_text}昨晚同步成功了(●´∀｀●)"
	magnets_added=$(cat README.md | grep '同步成功 新增记录.*条' | head -n 1 | sed -e 's/\[.*\]//g' | sed -e 's/[^0-9]//g')
	weibo_text="${weibo_text} 新增${magnets_added}条磁力记录"
	titles_added=$(git diff HEAD~ HEAD resource_list.json | grep '+.*"title":' | sed -e 's/+.*"title": "//g' | sed -e 's/| 琉璃神社 ★ HACG"//g' | sed -e 's/ *$//g' | perl -pe 's/\n/, /g' | sed -e 's/, $//g')
	weibo_text="${weibo_text} 最新资源：${titles_added}"
else
	weibo_text="${weibo_text}昨晚同步出错了哦(,,#ﾟДﾟ) 主人快来调♂教♂我"
fi

weibo_text="$(echo $weibo_text | cut -c 1-138)..."

echo $weibo_text

access_token=$(cat access_token)

curl 'https://api.weibo.com/2/statuses/update.json' --data-urlencode "access_token=${access_token}" --data-urlencode "status=${weibo_text}"
