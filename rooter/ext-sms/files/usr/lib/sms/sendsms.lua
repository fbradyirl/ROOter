#!/usr/bin/lua

modem = arg[1]
addr = arg[2]
dcs = arg[3]
txt = arg[4]

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

function bitright(x, y)
	return math.floor(x / 2 ^ y)
end

function bitleft(x, y)
	return x * 2 ^ y
end

function pack_ud7(udl, txt)
	maxb = math.ceil((tonumber(udl, 16) / 8) * 7)
	udtab = {}
	ii = 1
	jj = 1
	kk = 0
	repeat
		ch = tonumber(txt:sub(jj, jj + 1), 16)
		if ii == 1 then
			udtab[kk + 1] = ch
		elseif ii == 2 then
			udtab[kk] = bitor(bitleft(bitand(ch, 1), 7), udtab[kk])
			udtab[kk + 1] = bitright(bitand(ch, 126), 1)
		elseif ii == 3 then
			udtab[kk] = bitor(bitleft(bitand(ch, 3), 6), udtab[kk])
			udtab[kk + 1] = bitright(bitand(ch, 124), 2)
		elseif ii == 4 then
			udtab[kk] = bitor(bitleft(bitand(ch, 7), 5), udtab[kk])
			udtab[kk + 1] = bitright(bitand(ch, 120), 3)
		elseif ii == 5 then
			udtab[kk] = bitor(bitleft((bitand(ch, 15)), 4), udtab[kk])
			udtab[kk + 1] = bitright(bitand(ch, 112), 4)
		elseif ii == 6 then
			udtab[kk] = bitor(bitleft(bitand(ch, 31), 3), udtab[kk])
			udtab[kk + 1] = bitright(bitand(ch, 96), 5)
		elseif ii == 7 then
			udtab[kk] = bitor(bitleft(bitand(ch, 63), 2), udtab[kk])
			udtab[kk + 1] = bitright(bitand(ch, 64), 6)
		else
			udtab[kk] = bitor(bitleft(ch, 1), udtab[kk])
			ii = 0
			kk = kk - 1
		end
		ii = ii + 1
		jj = jj + 2
		kk = kk + 1
	until jj > #txt
	ud = ''
	for jj = 1, maxb do
		ud = ud .. ("0" .. string.format("%X", udtab[jj])):sub(-2)
	end
	return ud
end

udl = ("0" .. string.format("%X", math.floor(#txt / 2))):sub(-2)
da = "81"
if addr:sub(1, 1) == "+" then
	da = "91"
	addr = addr:sub(2)
elseif addr:sub(1, 1) == "-" then
	addr = addr:sub(2)
end
da = ("0" .. string.format("%X", #addr)):sub(-2) .. da
if (#addr % 2) > 0 then
	addr = addr .. "F"
end
k = #addr
j = 1
repeat
	da = da .. addr:sub(j + 1, j + 1) .. addr:sub(j, j)
	j = j + 2
until j > k
if dcs == "00" then
	ud = pack_ud7(udl, txt)
else
	ud = txt
end
pdu = "001100" .. da .. "00" .. dcs .. "AD" .. udl .. ud
epdu = ("0" .. string.format("%d", (math.floor(#pdu / 2) - 1))):sub(-3) .. ',' .. pdu
os.execute("/usr/lib/sms/sendsms.sh " .. modem .. " " .. epdu .. " &")
