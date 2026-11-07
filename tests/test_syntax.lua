local separator = package.config:sub(1, 1)
local command
if separator == "\\" then
  command = "dir /b /s *.lua 2>nul"
else
  command = "find . -type f -name '*.lua' -not -path './.git/*' -print 2>/dev/null"
end

local pipe = assert(io.popen(command, "r"))
local files = {}
for path in pipe:lines() do
  path = path:gsub("^%./", "")
  if path ~= "" then files[#files + 1] = path end
end
pipe:close()

assert(#files > 0, "no Lua files discovered")
table.sort(files)

for _, path in ipairs(files) do
  local chunk, errorText = loadfile(path)
  assert(chunk, path .. ": " .. tostring(errorText))
end

print(string.format("PASS: all %d discovered Lua files compile", #files))
