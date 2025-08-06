
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

  playAudio("cobra.dfpwm")
  
-- while true do
--   -- Pause the program until a redstone event happens
--   os.pullEvent("redstone")
  
--   -- Check if the back of the turtle is receiving a redstone signal
--   if redstone.getInput("front") then
--     print("Redstone signal DETECTED!")
--     turtle.select(1)
--     turtle.place()
--   end
-- end
