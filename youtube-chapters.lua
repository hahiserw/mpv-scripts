-- Parses youtube description to get a timestamp (first one in line) and the
-- text beside it to form chapters.
-- It works on downloaded files too if they contain youtube id (after a dash
-- and before a dot as in a default filename of video downloaded by youtube-dl).


local o = {
	-- Timestamp patter to look for in the lines
	time_pattern        = '([%d:.]+:[%d.]+)',

	-- If it happens that the video already has chapters and this is set to
	-- true, they will get overwriten by the ones obtained from description (if
	-- found)
	overwrite_chapters  = true,
}


local msg   = require 'mp.msg'
local utils = require 'mp.utils'


function get_video_id()
	local filename = mp.get_property('filename')

	local vid = filename:match('-([%w_-]+)%.')

	if not vid then
		vid = filename:match('watch%?v=([%w_-]+)')
	end

	return vid
end

function exec(args)
	local ret = utils.subprocess({args = args})
	return ret.status, ret.stdout, ret
end

function get_description(url)
	-- from ytdl_hook.lua
	local ytdl = {
		path     = 'youtube-dl',
		searched = false,
	}

	if not (ytdl.searched) then
		local ytdl_mcd = mp.find_config_file("youtube-dl")
		if not (ytdl_mcd == nil) then
			msg.verbose("found youtube-dl at: " .. ytdl_mcd)
			ytdl.path = ytdl_mcd
		end
		ytdl.searched = true
	end

	local command = {ytdl.path, '--no-warning', '--get-description', '--', url}
	-- local command = {ytdl.path, '--no-warning', '-J', '--', url}

	local es, data, result = exec(command)

	if es < 0 or data == nil or data == '' then
		return
	end

	return data

	-- local json, err = utils.parse_json(json)
	-- return json['description']
end

function parse_time(time_string)
	if not time_string then
		return nil
	end

	local numbers = {}

	string.gsub(time_string, '[%d.]+', function(number)
		table.insert(numbers, number)
	end)

	local matches = #numbers

	local month = (matches > 4 and numbers[matches - 4] or 0) + 1
	local day   = (matches > 3 and numbers[matches - 3] or 0) + 1
	local hour  = (matches > 2 and numbers[matches - 2] or 0) + 1
	local min   =  matches > 1 and numbers[matches - 1] or 0
	local sec   =  matches > 0 and numbers[matches]     or 0

	local ret = os.time({
		year  = 1970,
		month = month,
		day   = day,
		hour  = hour,
		min   = min,
		sec   = sec,
	})

	return ret
end

function extract_chapters(data)
	local video_length = mp.get_property_native('length')

	local ret = {}

	for line in data:gmatch('[^\r\n]+') do
		local time_string = string.match(line, o.time_pattern)

		if time_string then
			time = parse_time(time_string)

			if time < video_length then
				table.insert(ret, {time = time, title = line})
			end
		end
	end

	return ret
end

function main_file()
	if not o.overwrite_chapters then
		local chapter_list = mp.get_property_native('chapter-list')
		if #chapter_list > 0 then
			msg.verbose('Not overwriting chapters because overwrite_chapters is set to false')
			return
		end
	end

	local video_id = get_video_id() or ''

	if video_id == '' then
		msg.verbose('Not youtube video')
		return
	end

	local url = 'https://youtube.com/watch?v=' .. video_id

	local description = get_description(url)

	if not description then
		msg.verbose('No description')
		return
	end

	local chapter_list = extract_chapters(description)

	if not chapter_list then
		msg.verbose('No timestamps in this video\'s description')
		return
	end

	msg.verbose('Setting chapters from video\'s description')

	mp.set_property_native('chapter-list', chapter_list)
end


mp.add_hook('on_preloaded', 30, main_file)
