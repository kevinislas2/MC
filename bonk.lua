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

function bonk () 
  print("bonk")
  turtle.select(1)
  turtle.place()
end

local bonked = false

playAudio("mountains.dfpwm")
while not bonked do
  local i = math.random(1, 10000)
  if i == 500 then
    bonk()
    bonked = true
    -- playAudio("mountains.dfpwm")
  end
end
