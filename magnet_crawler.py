import requests, re, json, sys, os

reload(sys)
sys.setdefaultencoding('utf8')

cookie = ''
max_depth = 40
viewed_urls = []
found_magnets = []
ignore_url_param = True
ignore_html_label = True

session = requests.Session()
session.headers.update({'Cookie': cookie})

resource_list = []

if os.path.exists('resource_list.json'):
	with open('resource_list.json', 'r') as json_file:
		resource_list = json.loads(json_file.read())
	for resource in resource_list:
		found_magnets.extend(resource['magnets'])

def scan_page(url, depth=0):
	if url in viewed_urls:
		return
	if (depth > max_depth):
		return

	print('Entering: ' + url)
	sys.stdout.flush()

	try:
		result = session.get(url, timeout=60)
		if not (result.status_code >= 400 and result.status_code<500):
			result.raise_for_status()
		viewed_urls.append(url)
	except Exception:
		scan_page(url, depth)
		return
	result_text = result.content
	magnet_list = get_magnet_links(result_text)
	sub_urls = get_sub_urls(result_text, url)
	page_title = get_page_title(result_text)
	new_resource = {'title':page_title, 'magnets': magnet_list}

	if new_resource in resource_list:
		for sub_url in sub_urls:
			scan_page(sub_url, depth+1)
		return

	if (len(magnet_list) > 0):
		append_title_to_file(page_title, 'magnet_output')
		for magnet in magnet_list:
			print('Found magnet: ' + magnet)
			sys.stdout.flush()
			append_magnet_to_file(magnet, 'magnet_output')
		resource_list.append(new_resource)
		remove_duplicated_resources()
		save_json_to_file('resource_list.json')

	for sub_url in sub_urls:
		scan_page(sub_url, depth+1)

def get_sub_urls(result_text, url):
	urls = set(re.findall(r'<a.*?href=[\'"](.*?)[\'"].*?>', result_text))
	sub_urls = []
	for sub_url in urls:
		sub_url = sub_url.strip()
		if sub_url == '':
			continue
		if 'javascript:' in sub_url or 'mailto:' in sub_url:
			continue
		if sub_url[0:4] == 'http':
			try:
				if (get_url_prefix(sub_url)[1] != get_url_prefix(url)[1]):
					continue
			except Exception:
				continue
		elif sub_url[0:1] == '/':
			sub_url = get_url_prefix(url)[0] + '://' + get_url_prefix(url)[1] + sub_url
		else:
			sub_url = url + '/' + sub_url
		sub_url = re.sub(r'#.*$', '', sub_url)
		sub_url = re.sub(r'//$', '/', sub_url)
		if ignore_url_param:
			sub_url = re.sub(r'\?.*$', '', sub_url)
		if not sub_url in viewed_urls:
			sub_urls.append(sub_url)
	return sub_urls

def get_url_prefix(url):
	domain_match = re.search(r'(.*?)://(.*?)/', url)
	if (domain_match):
		return (domain_match.group(1) ,domain_match.group(2))
	else:
		domain_match = re.search(r'(.*?)://(.*)$', url)
		return (domain_match.group(1) ,domain_match.group(2))
	

def get_magnet_links(result_text):
	if (ignore_html_label):
		result_text = re.sub(r'<[\s\S]*?>', '', result_text)

	result_text = re.sub(r'([^0-9a-zA-Z])([0-9a-zA-Z]{5,30})[^0-9a-zA-Z]{5,30}([0-9a-zA-Z]{5,30})([^0-9a-zA-Z])', r'\1\2\3\4', result_text)

	hashes = list(set(re.findall(r'[^0-9a-fA-F]([0-9a-fA-F]{40})[^0-9a-fA-F]', result_text)))
	hashes.extend(list(set(re.findall(r'[^0-9a-zA-Z]([0-9a-zA-Z]{32})[^0-9a-zA-Z]', result_text))))
	magnets = list(set([('magnet:?xt=urn:btih:' + hash_value).lower() for hash_value in hashes if not ('magnet:?xt=urn:btih:' + hash_value).lower() in found_magnets]))
	
	found_magnets.extend(magnets)
	return magnets

def get_page_title(result_text):
	match = re.search(r'<title>(.+?)</title>', result_text)
	if match:
		return match.group(1).strip()
	else:
		return ''

def append_magnet_to_file(magnet, filename):
	with open(filename, 'a+') as output_file:
		output_file.write(magnet + '\n')

def append_title_to_file(title, filename):
	with open(filename, 'a+') as output_file:
		output_file.write(title + '\n')

def remove_duplicated_resources():
	global resource_list
	new_resource_list = []
	for resource in resource_list:
		add_flag = True
		for added_resource in new_resource_list:
			if added_resource['title'] == resource['title']:
				add_flag = False
				added_resource['magnets'].extend(resource['magnets'])
				added_resource['magnets'] = list(set(added_resource['magnets']))
				break
		if add_flag:
			new_resource_list.append(resource)
	resource_list = new_resource_list

def save_json_to_file(filename):
	with open(filename, 'w+') as output_file:
		output_file.write(json.dumps(resource_list, indent=4, sort_keys=True, ensure_ascii=False))

def main():
	print('Enter a website url to start.')
	root_url = raw_input()
	if not '://' in root_url:
		root_url = 'http://' + root_url
	#with open('magnet_output', 'w+') as output_file:
	#	output_file.write('')
	scan_page(root_url)

if __name__ == '__main__':
	main()


