--[[
  Parallel Video and Audio Player for ComputerCraft

  This script streams video and audio from URLs concurrently to prevent stuttering.
  - Video is expected in RLE ".joe" format, one frame per line.
  - Audio is expected in DFPWM format.
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
    -- We don't clear because the frame data covers the whole screen
    
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

--- Streams and plays audio from a web handle using events. Runs in parallel.
-- @param audioHandle The binary read handle for the audio stream.
local function streamAudio(audioHandle)
    local decoder = dfpwm.make_decoder()

    -- Prime the speaker with the first chunk of audio to start the event chain.
    local first_chunk = audioHandle.read(audioChunkSize)
    if not first_chunk or #first_chunk == 0 then
        return -- No audio data to play.
    end
    speaker.playAudio(decoder(first_chunk))

    -- Loop, waiting for the speaker to be empty before sending the next chunk.
    while true do
        -- This waits for the speaker to finish its queue, yielding to other parallel tasks.
        os.pullEvent("speaker_audio_empty")

        local music_chunk = audioHandle.read(audioChunkSize)
        if music_chunk and #music_chunk > 0 then
            local music_buffer = decoder(music_chunk)
            speaker.playAudio(music_buffer)
        else
            -- No more music data, so we exit the loop.
            break
        end
    end
end

--- Streams and displays video from a web handle. Runs in parallel.
-- @param videoHandle The read handle for the video stream.
-- @param monitor The monitor to display the video on.
local function streamVideo(videoHandle, monitor)
    local width, height = monitor.getSize()
    local frameDelay = 1 / videoFps

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

        -- Read the next line from the web request
        line = videoHandle.readLine()
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
    
    for i = 1, movieParts do
        local currentVideoUrl = string.format(videoUrlFormat, i)
        
        -- Calculate which audio file to use, cycling from 0 to (audioParts - 1)
        local audioIndex = (i - 1) % audioParts
        local currentAudioUrl = string.format(audioUrlFormat, audioIndex)
        
        print(string.format("Loading part %d/%d (Audio %s)...", i, movieParts, string.format("%02d", audioIndex)))
        
        -- Open connections to both the video and audio URLs
        local videoHandle, videoErr = http.get(currentVideoUrl)
        local audioHandle, audioErr = http.get(currentAudioUrl, nil, true) -- true for binary mode

        if not videoHandle or not audioHandle then
            printError("Error loading part " .. i)
            if videoErr then printError("Video: " .. videoErr) end
            if audioErr then printError("Audio: " .. audioErr) end
        else
            print("Part " .. i .. " loaded. Starting playback.")
            sleep(1)
            monitor.clear()
            
            -- Define the two functions that will run in parallel.
            -- We wrap them in anonymous functions to pass arguments.
            local videoTask = function() streamVideo(videoHandle, monitor) end
            local audioTask = function() streamAudio(audioHandle) end
            
            -- This runs both functions at the same time and waits for them to finish.
            parallel.waitForAll(videoTask, audioTask)
            
            -- Clean up handles after the part is done
            videoHandle.close()
            audioHandle.close()
        end
    end
    
    print("Playback finished.")
    monitor.setTextScale(1)
    monitor.clear()
end

-- Run the main function
main()
