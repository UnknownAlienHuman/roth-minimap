local files = {
  "RothMinimap.lua",
  "Options.lua",
  "modules/Skin.lua",
  "modules/Ping.lua",
  "modules/Zoom.lua",
  "tests/test_syntax.lua",
  "tests/test_contracts_12_1_5.lua",
  "tests/runtime_stubs_env.lua",
  "tests/test_runtime_stubs.lua",
}

for _, path in ipairs(files) do
  local chunk, errorText = loadfile(path)
  assert(chunk, path .. ": " .. tostring(errorText))
end

print("PASS: all Lua files compile")