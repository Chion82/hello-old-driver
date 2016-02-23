import json, sys

reload(sys)
sys.setdefaultencoding('utf8')

resource_list = []
found_magnet_list = []

with open('resource_list.json', 'r') as resource_file:
	resource_list = json.loads(resource_file.read())

keyword = raw_input()
for resource in resource_list:
	if keyword in resource['title']:
		found_magnet_list.extend(resource['magnets'])

for magnet in found_magnet_list:
	print(magnet)

