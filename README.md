# mpv scripts

## youtube-chapters

Parses youtube description to get a timestamp (first one in line) and the
text beside it to form chapters.
It works on downloaded files too if they contain youtube id (after a dash
and before a dot as in a default filename of video downloaded by youtube-dl).

Options:
```lua
local o = {
	-- Timestamp patter to look for in the lines
	time_pattern        = '([%d:.]+:[%d.]+)',

	-- If it happens that the video already has chapters and this is set to
	-- true, they will get overwriten by the ones obtained from description (if
	-- found)
	overwrite_chapters  = true,
}
```
