--```lua
utf8 = require('utf8')
promptfont = require('promptfont.promptfont')

function love.load()
    love.window.setTitle("PromptFont Demo")
    love.window.setMode(1280,720)

    -- Load audio file data into memory
    local audio_file = love.filesystem.newFileData("Adam F - Circles (Album Edit).mp3")
    local source = love.audio.newSource(audio_file, "stream")
    bpm = 162
    source:seek(45)
    source:setVolume(0.7)
    source:play()

    local font_size = 64
    promptfont_data = love.graphics.newFont("promptfont/promptfont.ttf", font_size)
    promptfont_data:setFilter("nearest")
    love.graphics.setFont(promptfont_data)

    remap = function( value, inMin, inMax, outMin, outMax )
        return outMin + ( ( ( value - inMin ) / ( inMax - inMin ) ) * ( outMax - outMin ) )
    end
    logo = function(x)
        return x ~= 0 and math.pow(2, 10 * x - 10) or 0
    end
    logo2 = function(x)
        return x ~= 1 and 1 - math.pow(2, -10 * x) or 1
    end

    -- .char: "a", .born: love.timer.getTime()
    old_char_stack = {}

    big_promptfont_data = love.graphics.newFont("promptfont/promptfont.ttf", font_size*2)

    local icon_canvas = love.graphics.newCanvas(font_size, font_size)
    local chars_for_icon = {}
    for glyph_key, glyph in pairs(promptfont) do
        if string.sub(glyph_key, -4) == "_INT" then
            chars_for_icon[#chars_for_icon+1] = glyph_key
        end
    end
    char_for_icon = ""
    render_icon = function()
        if char_for_icon ~= "" then
            table.insert(old_char_stack, {char=char_for_icon, born=love.timer.getTime()})
        end
        char_for_icon = utf8.char(promptfont[ chars_for_icon[math.floor(love.math.random(1, #chars_for_icon))] ])

        love.graphics.setCanvas(icon_canvas)
        love.graphics.clear()
        love.graphics.print(
            char_for_icon,
            promptfont_data,
            font_size/2,
            font_size/2,
            0, 1, 1,
            promptfont_data:getWidth(char_for_icon)/2,
            promptfont_data:getHeight()/2
        )
        love.graphics.setCanvas()
        love.window.setIcon( icon_canvas:newImageData() )
    end
    render_icon()

    draw_index = 1
    draw_time = 0
    draw_limit = (60/bpm)*4
    draw_text = ""
    draw_plaintext = ""
    type_buffer = ""
    type_color_wrap = {{0.5,0.5,0.5,0.5}, ""}
    ZERO_WIDTH_SPACE = utf8.char(0x200B)
    strings = {
        promptfont.KEYBOARD_LEFT .. "/" .. promptfont.KEYBOARD_RIGHT .. ": navigate",
        "ligatures " .. promptfont.ICON_EMPTY_HEART .. ": " .. promptfont.XBOX_LEFT_SHOULDER .. promptfont.DEVICE_KEYBOARD .. promptfont.DEVICE_KEYBOARD,
        "ligatures " .. promptfont.ICON_FULL_HEART .. ": " .. promptfont.XBOX_LEFT_SHOULDER .. ZERO_WIDTH_SPACE .. promptfont.DEVICE_KEYBOARD .. ZERO_WIDTH_SPACE .. promptfont.DEVICE_KEYBOARD,
        "play it loud "..promptfont.ICON_HEADPHONES,
        "" -- good luck
    }

    utf8_sub = function (str, char_idx_start, char_idx_end)
        return string.sub(
            str,
            utf8.offset(str, char_idx_start),
            utf8.offset(str, char_idx_end+1)-1
        )
    end

    cycle_index = function (direction)
        strings[#strings] = "good luck "..utf8.char(promptfont.ICON_D6_1_INT + math.floor(love.math.random(0, 5)))
        draw_index = 1+((draw_index+(direction-1)) % #strings)

        draw_plaintext = strings[draw_index]
        local emphasis_len = utf8.len(draw_plaintext)
        local emphasis_index, emphasis_character
        local roll = 0
        repeat
             roll = roll + 1
             emphasis_index = math.floor(love.math.random(1, emphasis_len))
             emphasis_character = utf8_sub(draw_plaintext, emphasis_index, emphasis_index)
        until (emphasis_character ~= nil and emphasis_character ~= " " and emphasis_character ~= ZERO_WIDTH_SPACE)
        draw_text = {
            {1,1,1}, utf8_sub(draw_plaintext, 0, emphasis_index-1),
            {1,0,0}, emphasis_character,
            {1,1,1}, utf8_sub(draw_plaintext, emphasis_index+utf8.len(emphasis_character), emphasis_len)
        }
    end

    cycle_index(0)
end

function love.draw()
    -- rectangle stuff
    local fill_pos = love.graphics.getWidth() * (logo2(draw_time / draw_limit))
    local fill_tall = promptfont_data:getHeight()/16

    love.graphics.setColor(0.5,0.5,0.5,0.5)
    love.graphics.rectangle(
        "fill",
        fill_pos,
        love.graphics.getHeight() - fill_tall,
        love.graphics.getWidth() - fill_pos,
        fill_tall
    )

    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle(
        "fill",
        0,
        love.graphics.getHeight() - fill_tall,
        fill_pos,
        fill_tall
    )

    for _, old_char in ipairs(old_char_stack) do
        local live_time = love.timer.getTime() - old_char.born
        if live_time > 0 then
            local ratio = live_time / draw_limit
            local char_width = big_promptfont_data:getWidth(old_char.char)
            love.graphics.setColor(0.25, 0.25, 0.25, remap(logo(ratio), 1, 0, 0, 0.66))
            love.graphics.print(
                old_char.char,
                big_promptfont_data,
                love.graphics.getWidth()/2 + math.sin(old_char.born*bpm)*(char_width*1.5)*ratio,
                remap(logo(ratio), 0, 1, love.graphics.getHeight()/4, love.graphics.getHeight()+big_promptfont_data:getHeight()),
                0, 1, 1,
                char_width/2,
                big_promptfont_data:getHeight()/2
            )
        end
    end



    -- big font stuff
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(
        char_for_icon,
        big_promptfont_data,
        love.graphics.getWidth()/2,
        love.graphics.getHeight()/4,
        0, 1, 1,
        big_promptfont_data:getWidth(char_for_icon)/2,
        big_promptfont_data:getHeight()/2
    )


    love.graphics.print(
        draw_text,
        promptfont_data,
        love.graphics.getWidth()/2,
        love.graphics.getHeight()/2,
        0, 1, 1,
        promptfont_data:getWidth(draw_plaintext)/2,
        promptfont_data:getHeight()/2
    )

    local ds = 0.5;
    local lw = love.graphics.getWidth() - (promptfont_data:getWidth(type_buffer)*ds)
    love.graphics.print(
        type_color_wrap,
        promptfont_data,
        lw,
        love.graphics.getHeight()-(promptfont_data:getHeight()*ds),
        0,
        ds, ds
    )
end

function love.update(dt)
    draw_time = draw_time + dt
    if draw_time >= draw_limit then
        draw_time = draw_time - draw_limit
        cycle_index(1)
    end
end

function love.keyreleased( key, scancode )
    if key == "left" or key == "right" then
        draw_time = 0
        if key == "left" then
            cycle_index(-1)
        elseif key == "right" then
            cycle_index(1)
        end
    elseif key == "escape" then
        love.event.quit("restart")
    elseif key == "return" then
        table.insert(strings, #strings, type_buffer)
        type_buffer = ""
    elseif key == "backspace" then
        type_buffer = string.sub(type_buffer, 0, -2)
        type_color_wrap[#type_color_wrap] = type_buffer
    end

end

function love.textinput(t)
    type_buffer = type_buffer .. t
    type_color_wrap[#type_color_wrap] = type_buffer
    render_icon()
end
---```
