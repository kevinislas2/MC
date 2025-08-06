-- The URL of the file you want to download
local url = "https://github.com/kevinislas2/MC/raw/refs/heads/main/mountains.dfpwm"
-- The name you want to save the file as
local fileName = "mountains.dfpwm"

-- Access the disk drive on the left side
-- It will be automatically mounted as "/disk"
local drive = peripheral.wrap("front")
if not drive then
  print("Error: No disk drive found on the left.")
  return
end

-- Download the file content
print("Downloading from: " .. url)
local response = http.get(url)

if response then
  -- Open a file on the floppy disk in "write" mode
  local file = fs.open("/disk/" .. fileName, "w")
  
  -- Write the downloaded content to the file and close it
  file.write(response.readAll())
  file.close()
  
  print("Success! File saved to /disk/" .. fileName)
  response.close()
else
  print("Error: Failed to download file.")
end
