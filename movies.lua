-- 164x81
-- 8x6 monitors

-- url = "https://storage.googleapis.com/mc_joe/movie_10000f.joe"
local movieUrl = "https://raw.githubusercontent.com/kevinislas2/MC/refs/heads/main/test"

local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
local decoder = dfpwm.make_decoder()
local chunkSize = 16 * 1024
local music_response_handle = http.get("https://github.com/kevinislas2/MC/raw/refs/heads/main/music/shrek_es.dfpwm", nil, true)

-- Function to draw a frame (this is unchanged from the previous version)
local function drawFrame(term, frameData, width, height)
    local x, y = 1, 1
    term.setCursorPos(1, 1)
    term.clear()
    term.setBackgroundColor(colors.black)

    -- A lookup table to map our 0-15 color indices to CC's 2^n colors API
    local colorMap = {
        [0] = colors.white,     [1] = colors.orange,   [2] = colors.magenta,
        [3] = colors.lightBlue, [4] = colors.yellow,   [5] = colors.lime,
        [6] = colors.pink,      [7] = colors.gray,     [8] = colors.lightGray,
        [9] = colors.cyan,      [10] = colors.purple,  [11] = colors.blue,
        [12] = colors.brown,    [13] = colors.green,   [14] = colors.red,
        [15] = colors.black
    }

    for i = 1, #frameData do
        local ccColor = colorMap[frameData[i]] or colors.black
        term.setTextColor(ccColor)
        term.write(string.char(143))

        x = x + 1
        if x > width then
            x = 1
            y = y + 1
            term.setCursorPos(x, y)
        end
    end
end

-- Main playback logic (updated for streaming)
local function playMovie(url)
    print("Attempting to connect to URL...")
    
    -- Use http.get to open a connection to the URL
    -- The returned 'handle' works very similarly to a file handle
    local handle, err = http.get(url)

    if not handle then
        print("HTTP Error: " .. (err or "Could not connect."))
        return
    end

    print("Connection successful! Starting playback...")
    sleep(1) -- Give user time to read message

    local monitor = peripheral.find("monitor") or term
    monitor.setTextScale(0.5)
    local width, height = monitor.getSize()

    -- Read the response line by line (each line is one frame)
    local line = handle.readLine()
    local frame = 0
    while line do
        local decodedFrame = {}
        -- The RLE decoding logic is exactly the same
        for count, value in string.gmatch(line, "(%d+):(%d+);?") do
            count = tonumber(count)
            value = tonumber(value)
            for i = 1, count do
                table.insert(decodedFrame, value)
            end
        end

        drawFrame(monitor, decodedFrame, width, height)
        -- sleep(1/30) -- Adjust for your video's frame rate

        -- Read the next line from the web request
        line = handle.readLine()

        -- Play music?
        frame+=1
        if frame % 10 == 0 then
            music_chunk = music_response_handle.read(chunkSize)
            if music_chunk then
                local music_buffer = decoder(music_chunk)
                speaker.playAudio(music_buffer)
            end
        end
    end

    -- Close the HTTP connection handle
    handle.close()
    print("Playback finished.")
end

-- Check if the HTTP API is enabled before starting
if not http then
    printError("HTTP API is not available.")
    printError("Please enable it in the ComputerCraft config.")
    return
end

for i=1,65 do 
    local movieUrl = string.format("https://raw.githubusercontent.com/kevinislas2/MC/refs/heads/main/movie/shrek_%d.joe", i)
    playMovie(movieUrl)

end
