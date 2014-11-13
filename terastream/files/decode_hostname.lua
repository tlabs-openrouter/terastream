#!/usr/bin/lua

-- this script takes a RFC6332 3. or RFC1035 Section 3.1
-- encoded domain name and outputs it correctly

local s = arg[1]

s = s:gsub("\\%d%d%d", ".")
s = s:gsub("[^a-zA-Z0-9-]", ".")

if s:sub(1,1)=='.' then
	s = s:sub(2, #s)
end

print(s)

