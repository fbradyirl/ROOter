module("luci.controller.sms", package.seeall)

function index()
	local page
	page = entry({"admin", "modem", "sms"}, template("rooter/sms"), "SMS Messaging", 35)
	page.dependent = true

	entry({"admin", "modem", "check_read"}, call("action_check_read"))
	entry({"admin", "modem", "del_sms"}, call("action_del_sms"))
	entry({"admin", "modem", "send_sms"}, call("action_send_sms"))
	entry({"admin", "modem", "change_sms"}, call("action_change_sms"))
	entry({"admin", "modem", "change_smsdn"}, call("action_change_smsdn"))
end

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function hasbit(x, p)
	return x % (p + p) >= p
end

function bitand(x, y)
	local p = 1; local z = 0; local limit = x > y and x or y
	while p <= limit do
		if hasbit(x, p) and hasbit(y, p) then
			z = z + p
		end
		p = p + p
	end
	return z
end

function bitor(x, y)
	local p = 1; local z = 0; local limit = x > y and x or y
	while p <= limit do
		if hasbit(x, p) or hasbit(y, p) then
			z = z + p
		end
		p = p + p
	end
	return z
end

function bitleft(x, y)
	return x * 2 ^ y
end

function action_send_sms()
	smsnum = luci.model.uci.cursor():get("modem", "general", "smsnum")
	local set = luci.http.formvalue("set")
	local number = trim(string.sub(set, 1, 20))
	local txt = string.sub(set, 21)
	local g7t = {}
	g7t[64] = "00"
	g7t[163] = "01"
	g7t[36] = "02"
	g7t[165] = "03"
	g7t[232] = "04"
	g7t[233] = "05"
	g7t[249] = "06"
	g7t[236] = "07"
	g7t[242] = "08"
	g7t[199] = "09"
	g7t[216] = "0B"
	g7t[248] = "0C"
	g7t[197] = "0E"
	g7t[229] = "0F"
	g7t[0x394] = "10"
	g7t[95] = "11"
	g7t[0x3A6] = "12"
	g7t[0x393] = "13"
	g7t[0x39B] = "14"
	g7t[0x3A9] = "15"
	g7t[0x3A0] = "16"
	g7t[0x3A8] = "17"
	g7t[0x3A3] = "18"
	g7t[0x398] = "19"
	g7t[0x39E] = "1A"
	g7t[198] = "1C"
	g7t[230] = "1D"
	g7t[223] = "1E"
	g7t[201] = "1F"
	g7t[164] = "24"
	g7t[161] = "40"
	g7t[196] = "5B"
	g7t[214] = "5C"
	g7t[209] = "5D"
	g7t[220] = "5E"
	g7t[167] = "5F"
	g7t[191] = "60"
	g7t[228] = "7B"
	g7t[246] = "7C"
	g7t[241] = "7D"
	g7t[252] = "7E"
	g7t[224] = "7F"
	g7t[94] = "1B14"
	g7t[123] = "1B28"
	g7t[125] = "1B29"
	g7t[92] = "1B2F"
	g7t[91] = "1B3C"
	g7t[126] = "1B3D"
	g7t[93] = "1B3E"
	g7t[124] = "1B40"
	g7t[0x20AC] = "1B65"
	g7t[96] = "27"
	local unicode = ''
	local g7hex = ''
	local g7isok = true
	local j = #txt
	local res = nil
	local msg = nil
	local dcs
	local k = 1
	repeat
		ch = string.byte(txt, k, k)
		if ch >= 0xF0 then
			g7hex = g7hex .. '3F'
			unicode = unicode .. '003F'
			k = k + 3
		elseif ch >= 0xE0 then
			ch = bitleft(bitand(ch, 0xF), 12)
			ch = bitor(bitleft(bitand(string.byte(txt, k + 1, k + 1), 0x3F), 6), ch)
			ch = bitor(bitand(string.byte(txt, k + 2, k + 2), 0x3F), ch)
			res = g7t[ch]
			if res == nil then
				g7isok = false
			else
				g7hex = g7hex .. res
			end
			unicode = unicode .. ('000' .. string.format("%X", ch)):sub(-4)
			k = k + 2
		elseif ch >= 0xC0 then
			ch = bitleft(bitand(ch, 0x3F), 6)
			ch = bitor(bitand(string.byte(txt, k + 1, k + 1), 0x3F), ch)
			res = g7t[ch]
			if res == nil then
				g7isok = false
			else
				g7hex = g7hex .. res
			end
			unicode = unicode .. ('000' .. string.format("%X", ch)):sub(-4)
			k = k + 1
		elseif ch <= 0x7F then
			res = g7t[ch]
			if res == nil then
				g7hex = g7hex .. ("0" .. string.format("%X", ch)):sub(-2)
			else
				g7hex = g7hex .. res
			end
			unicode = unicode .. ('000' .. string.format("%X", ch)):sub(-4)
		else
			g7hex = g7hex .. '3F'
			unicode = unicode .. '003F'
		end
		k = k + 1
	until k > j
	if g7isok and #g7hex <= 320 then
		dcs = "00"
		txt = g7hex
	elseif g7isok then
		msg = 'Processed text length = ' .. math.floor(#g7hex / 2) .. ' 7-bit characters.\n'
		msg = msg .. 'Currently ROOter supports 160 maximum per message.'
	elseif #unicode <= 280 then
		dcs = "08"
		txt = unicode
	else
		msg = 'Processed text length = ' .. math.floor(#unicode / 4) .. ' 16-bit Unicode characters.\n'
		msg = msg .. 'Currently ROOter supports 70 maximum per message.'
	end
	local rv ={}
	local file = nil
	local k = 1
	local status
	if msg == nil then
		os.execute('if [ -e /tmp/smssendstatus ]; then rm /tmp/smssendstatus; fi')
		os.execute("lua /usr/lib/sms/sendsms.lua " .. smsnum .. " " .. number .. " " .. dcs .. " " .. txt)
		os.execute("sleep 3")
		repeat
			file = io.open("/tmp/smssendstatus", "r")
			if file == nil then
				os.execute("sleep 1")
			end
			k = k + 1
		until k > 25 or file ~=nil
		if file == nil then
			status = 'Sending attempt timed out (fail)'
		else
			status = file:read("*line")
			file:close()
		end
	else
		status = msg
	end
	rv["status"] = status
	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function action_del_sms()
	local set = tonumber(luci.http.formvalue("set"))
	if set ~= nil and set > 0 then
		set = set - 1;
		smsnum = luci.model.uci.cursor():get("modem", "general", "smsnum")
		os.execute("/usr/lib/sms/delsms.sh " .. set .. " " .. smsnum)
	end
end

function action_check_read()
	local rv ={}
	local file
	local line
	smsnum = luci.model.uci.cursor():get("modem", "general", "smsnum")
	conn = "Modem #" .. smsnum
	rv["conntype"] = conn
	support = luci.model.uci.cursor():get("modem", "modem" .. smsnum, "sms")
	rv["ready"] = "0"
	if support == "1" then
		rv["ready"] = "1"
		result = "/tmp/smsresult" .. smsnum .. ".at"
		file = io.open(result, "r")
		if file ~= nil then
			file:close()
			os.execute("lua /usr/lib/sms/smsread.lua " .. smsnum)
			file = io.open("/tmp/smstext", "r")
			if file == nil then
				rv["ready"] = "3"
			else
				rv["ready"] = "2"
				local tmp = file:read("*line")
				rv["used"] = tmp
				tmp = file:read("*line")
				rv["max"] = tmp
				full = nil

				repeat
					for j = 1, 4 do
						line = file:read("*line")
						if line ~= nil then
							if j == 3 then
								full = full .. string.char(29)
								local i = tonumber(line)
								for k = 1, i do
									line = file:read("*line")
									full = full .. line
									if k < i then
										full = full .. '<br />'
									end
								end
							else
								if full == nil then
									full = line
								else
									full = full .. string.char(29) .. line
								end
							end
						end
					end
				until line == nil
				file:close()
				rv["line"] = full
			end
		end
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function action_change_sms()
	os.execute("/usr/lib/rooter/luci/modemchge.sh sms 1")
end

function action_change_smsdn()
	os.execute("/usr/lib/rooter/luci/modemchge.sh sms 0")
end
