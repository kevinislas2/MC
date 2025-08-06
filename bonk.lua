local speaker = peripheral.find("speaker")
local dfpwm = require("cc.audio.dfpwm")

function playAudio (audio_path)
  local decoder = dfpwm.make_decoder()
  for chunk in io.lines(audio_path, 16 * 1024) do
    local buffer = decoder(chunk)
    while not speaker.playAudio(buffer) do
      os.pullEvent("speaker_audio_empty")
    end
  end
end

function playStream(url)
  local decoder = dfpwm.make_decoder()
  local chunkSize = 16 * 1024

  print("Connecting to: " .. url)
  local response = http.get(url, nil, true)

  if not response then
    print("Error: Could not connect to URL.")
    return
  end
  -- Loop indefinitely until the stream ends
  while true do
    -- Read a chunk of data from the web stream
    local chunk = response.read(chunkSize)

    -- If the chunk is nil, the stream is finished, so we exit the loop
    if not chunk then
      break
    end

    -- Decode the raw audio data into a playable buffer
    local buffer = decoder(chunk)

    -- This loop waits until the speaker has room in its queue
    while not speaker.playAudio(buffer) do
      os.pullEvent("speaker_audio_empty")
    end
  end

  -- Clean up by closing the web connection
  response.close()
end

function bonk () 
  print("bonk")
  turtle.select(1)
  turtle.place()
end

local bonked = false

playStream("https://github.com/kevinislas2/MC/raw/refs/heads/main/mountains.dfpwm")
-- playAudio("mountains.dfpwm")
-- while not bonked do
--   local i = math.random(1, 10000)
--   if i == 500 then
--     bonk()
--     bonked = true
--     -- playAudio("mountains.dfpwm")
--   end
-- end
