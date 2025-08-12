local http = require("http")

function bonk () 
  print("bonk")
  turtle.select(1)
  turtle.place()
end

function contentContainsYes(content)
  if not content or type(content) ~= "string" then
    return false
  end

  for line in content:gmatch("[^\\n]+") do
    -- Trim whitespace and check if the line is exactly "yes"
    if line:match("^%s*(.-)%s*$") == "yes" then
      return true -- Found it!
    end
  end

  return false
end

function main ()
  url = "https://github.com/kevinislas2/MC/raw/refs/heads/main/download.lua"
  print("Connecting to: " .. url)
  local response = http.get(url)
  local content = response.readAll()
  response.close() -- Good practice to close the handle

  if contentContainsYes(content) then
    bonk()
    sleep(300)
  end
end

while true do
  if pcall(main) then
    -- no-op
    print("No error bonk")
  else
    print("Error. Bonk")
  end
  sleep(1)
end
