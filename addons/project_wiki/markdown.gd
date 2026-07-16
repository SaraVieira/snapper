@tool
extends RefCounted
## Small markdown -> BBCode converter used for the wiki preview.
## Supports headings, bold, italic, inline code, fenced code blocks,
## bullet lists, blockquotes, links and horizontal rules.

const HEADING_SIZES := [26, 22, 19, 17, 16, 15]


static func to_bbcode(md: String) -> String:
	var out := PackedStringArray()
	var in_code_block := false
	for raw_line in md.split("\n"):
		var line := raw_line
		var stripped := line.strip_edges()
		if stripped.begins_with("```"):
			out.append("[/code]" if in_code_block else "[code]")
			in_code_block = not in_code_block
			continue
		if in_code_block:
			out.append(_escape(line))
			continue
		if stripped == "---" or stripped == "***" or stripped == "___":
			out.append("[color=#88888866]────────────────────[/color]")
			continue
		if stripped.begins_with("#"):
			var level := 0
			while level < stripped.length() and stripped[level] == "#":
				level += 1
			if level <= 6 and level < stripped.length() and stripped[level] == " ":
				var text := _inline(stripped.substr(level + 1).strip_edges())
				out.append("[font_size=%d][b]%s[/b][/font_size]" % [HEADING_SIZES[level - 1], text])
				continue
		if stripped.begins_with("- ") or stripped.begins_with("* "):
			out.append("  •  " + _inline(stripped.substr(2)))
			continue
		if stripped.begins_with("> "):
			out.append("[i][color=#9c9c9c]" + _inline(stripped.substr(2)) + "[/color][/i]")
			continue
		out.append(_inline(line))
	if in_code_block:
		out.append("[/code]")
	return "\n".join(out)


static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


static func _inline(text: String) -> String:
	var escaped := _escape(text)
	escaped = _regex_sub(escaped, "\\[lb\\]([^\\]]+)\\]\\(([^)]+)\\)", "[url=$2]$1[/url]")
	escaped = _regex_sub(escaped, "\\*\\*([^*]+)\\*\\*", "[b]$1[/b]")
	escaped = _regex_sub(escaped, "(?<!\\*)\\*([^*]+)\\*(?!\\*)", "[i]$1[/i]")
	escaped = _regex_sub(escaped, "`([^`]+)`", "[code]$1[/code]")
	return escaped


static func _regex_sub(text: String, pattern: String, replacement: String) -> String:
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		return text
	return regex.sub(text, replacement, true)
