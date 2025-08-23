--[[
  Parallel Video and Audio Player for ComputerCraft

  This script runs two independent tasks in parallel:
  1. A video player that sequentially streams and displays all video parts.
  2. An audio player that sequentially streams and plays all corresponding audio parts.
]]

-- #############
-- ## CONFIGURATION
-- #############

-- Base URL for video files. %d will be replaced with the file number.
local videoUrlFormat = "https://raw.githubusercontent.com/kevinislas2/MC/refs/heads/main/movie/shrek_%d.joe"
-- Base URL for audio files. %02d will be replaced with the zero-padded file number.
local audioUrlFormat = "https://raw.githubusercontent.com/kevinislas2/MC/refs/heads/main/music/output_%02d.dfpwm"
-- The number of movie/video parts to play in sequence.
local movieParts = 65
-- The number of unique audio files to cycle through.
local audioParts = 5
-- The frames per second to target for video playback.
local videoFps = 60
-- The size of each audio chunk to download in bytes.
local audioChunkSize = 16 * 1024

-- #############
-- ## INITIALIZATION
-- #############

-- Check for required APIs
if not http then
    printError("HTTP API is not available. Please enable it in the config.")
    return
end
if not parallel then
    printError("Parallel API is not available.")
    return
end

local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")

if not speaker then
    printError("No speaker found.")
    return
end

-- A lookup table to map 0-15 color indices to CC's 2^n colors API
local colorMap = {
    [0] = colors.white,     [1] = colors.orange,    [2] = colors.magenta,
    [3] = colors.lightBlue, [4] = colors.yellow,    [5] = colors.lime,
    [6] = colors.pink,      [7] = colors.gray,      [8] = colors.lightGray,
    [9] = colors.cyan,      [10] = colors.purple,   [11] = colors.blue,
    [12] = colors.brown,    [13] = colors.green,    [14] = colors.red,
    [15] = colors.black
}

-- #############
-- ## CORE FUNCTIONS
-- #############

--- Draws a single decoded video frame to the screen.
-- @param term The terminal or monitor to draw on.
-- @param frameData A table of color numbers for each pixel.
-- @param width The width of the screen.
local function drawFrame(term, frameData, width)
    local x, y = 1, 1
    term.setCursorPos(1, 1)
    
    for i = 1, #frameData do
        local ccColor = colorMap[frameData[i]] or colors.black
        term.setTextColor(ccColor)
        term.write(string.char(143)) -- Block character

        x = x + 1
        if x > width then
            x = 1
            y = y + 1
            term.setCursorPos(x, y)
        end
    end
end

--- A long-running task to stream and play all audio parts sequentially.
local function streamAllAudio()
    local decoder = dfpwm.make_decoder()

    for i = 1, movieParts do
        -- Calculate which audio file to use, cycling from 0 to (audioParts - 1)
        local audioIndex = (i - 1) % audioParts
        local currentAudioUrl = string.format(audioUrlFormat, audioIndex)
        
        local audioHandle, audioErr = http.get(currentAudioUrl, nil, true) -- true for binary mode

        if audioHandle then
            -- Prime the speaker with the first chunk to start the event chain.
            local first_chunk = audioHandle.read(audioChunkSize)
            if first_chunk and #first_chunk > 0 then
                speaker.playAudio(decoder(first_chunk))

                -- Loop until this specific audio part is finished.
                while true do
                    os.pullEvent("speaker_audio_empty")
                    local music_chunk = audioHandle.read(audioChunkSize)
                    if music_chunk and #music_chunk > 0 then
                        speaker.playAudio(decoder(music_chunk))
                    else
                        -- No more music data for this part, break to the outer loop.
                        break
                    end
                end
            end
            audioHandle.close()
        else
            -- Log error but continue, so audio failure doesn't stop the whole movie.
            printError("Audio part " .. i .. " failed: " .. (audioErr or "Unknown error"))
        end
    end
end

--- A long-running task to stream and display all video parts sequentially.
-- @param monitor The monitor to display the video on.
local function streamAllVideo(monitor)
    local width, height = monitor.getSize()
    local frameDelay = 1 / videoFps

    for i = 1, movieParts do
        local currentVideoUrl = string.format(videoUrlFormat, i)
        print(string.format("Loading part %d/%d...", i, movieParts))
        
        local videoHandle, videoErr = http.get(currentVideoUrl)
        
        if videoHandle then
            -- Read the response line by line (each line is one frame)
            local line = videoHandle.readLine()
            while line do
                local decodedFrame = {}
                -- RLE decoding logic
                for count, value in string.gmatch(line, "(%d+):(%d+);?") do
                    count = tonumber(count)
                    value = tonumber(value)
                    for i = 1, count do
                        table.insert(decodedFrame, value)
                    end
                end

                drawFrame(monitor, decodedFrame, width)
                sleep(frameDelay)

                line = videoHandle.readLine()
            end
            videoHandle.close()
        else
            printError("Video part " .. i .. " failed: " .. (videoErr or "Unknown error"))
        end
    end
end

-- #############
-- ## MAIN EXECUTION
-- #############

local function main()
    local monitor = peripheral.find("monitor") or term
    monitor.setTextScale(0.5)
    term.clear()
    term.setCursorPos(1,1)
    print("Starting Movie Player...")
    sleep(1)
    monitor.clear()
    
    -- Define the two long-running tasks.
    local videoTask = function() streamAllVideo(monitor) end
    local audioTask = function() streamAllAudio() end
    
    -- Run both tasks completely in parallel and wait for both to finish their entire sequence.
    parallel.waitForAll(videoTask, audioTask)
    
    print("Playback finished.")
    monitor.setTextScale(1)
    monitor.clear()
end

-- Run the main function
main()
