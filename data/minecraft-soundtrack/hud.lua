-- I really dunno what I'm doing, all I know is it works well enough.
local maxHealth = 20
local playerHealth = 20
local hearts = {}

local flashTimer = 0
local flashCount = 0
local isHealingFlash = false

local frameSize = 9 
local flashNow = 0
local startX = (screenWidth / 2) - 197 
local startY = screenHeight - 80

function onCreate()
    setPropertyFromClass('substates.GameOverSubstate', 'characterName', 'blueBar');
    setPropertyFromClass('substates.GameOverSubstate', 'deathSoundName', 'nothing');
    setPropertyFromClass('substates.GameOverSubstate', 'loopSoundName', 'nothing');
    setPropertyFromClass('substates.GameOverSubstate', 'endSoundName', 'nothing');
    setProperty('guitarHeroSustains', false)
    runHaxeCode([[
        game.variables.set('oldDown0', 0);
        game.variables.set('oldDown1', 0);
        game.variables.set('oldUp0', 0);
        game.variables.set('oldUp1', 0);
        if (ClientPrefs.data.arrowRGB != null) {
            if (ClientPrefs.data.arrowRGB.length > 1 && ClientPrefs.data.arrowRGB[1] != null) {
                game.variables.set('oldDown0', ClientPrefs.data.arrowRGB[1][0]);
                game.variables.set('oldDown1', ClientPrefs.data.arrowRGB[1][1]);
                
                ClientPrefs.data.arrowRGB[1][0] = 0xFF00C2C2;
                ClientPrefs.data.arrowRGB[1][1] = 0xFF000000;
            }
            if (ClientPrefs.data.arrowRGB.length > 2 && ClientPrefs.data.arrowRGB[2] != null) {
                game.variables.set('oldUp0', ClientPrefs.data.arrowRGB[2][0]);
                game.variables.set('oldUp1', ClientPrefs.data.arrowRGB[2][1]);
                
                ClientPrefs.data.arrowRGB[2][0] = 0xFF0BC503;
                ClientPrefs.data.arrowRGB[2][1] = 0xFF000000;
            }
        }
    ]])
    setProperty('scoreTxt.y', startY + 50)
    if getPropertyFromClass('backend.ClientPrefs', 'data.downScroll') then
        startY = screenHeight-680
        setProperty('scoreTxt.y', startY - 30)
    end
    for i = 1, 10 do
        local tag = 'heart'..i
        makeLuaSprite(tag, 'health', startX + ((i - 1) * 40), startY)
        loadGraphic(tag, 'health', frameSize, frameSize)
        addAnimation(tag, 'empty', {0}, 0, false)
        addAnimation(tag, 'full', {1}, 0, false)
        addAnimation(tag, 'half', {2}, 0, false)
        addAnimation(tag, 'flashEmpty', {3}, 0, false)
        addAnimation(tag, 'flashFull', {4}, 0, false)
        addAnimation(tag, 'flashHalf', {5}, 0, false)
        setProperty(tag..'.antialiasing', false)
        scaleObject(tag, 4.0, 4.0)
        setObjectCamera(tag, 'hud')
        addLuaSprite(tag, true)
        hearts[i] = tag
    end
    updateHearts()
    for i = 0, 3 do
        setPropertyFromGroup('playerStrums', i, 'y', getPropertyFromGroup('playerStrums', 0, 'y') + 10)
    end
end

function onCreatePost()
    setProperty('healthBar.visible', false)
    setProperty('healthBarBG.visible', false)
    setProperty('iconP1.visible', false)
    setProperty('iconP2.visible', false)
    runHaxeCode([[
        for (i in 0...game.strumLineNotes.length) {
            var strum = game.strumLineNotes.members[i];
            strum.antialiasing = false;
            strum.y += 10;
            strum.scale.set(5.9, 5.9);
            strum.updateHitbox();
        }

        for (i in 0...game.unspawnNotes.length) {
            var note = game.unspawnNotes[i];
            note.antialiasing = false;
            note.scale.x = 5.9;
            note.scale.y = 5.9;
            note.offsetX += 44.65;
            note.offsetY += 32.5;
            if (ClientPrefs.data.downScroll) {
                note.offsetY += 20;
            }

            if (note.isSustainNote) {
                note.offsetX -= 18;
                note.offsetY -= 1;
                if (ClientPrefs.data.downScroll) {
                    note.offsetY += 1;
                }
            if (note.nextNote == null || StringTools.endsWith(note.animation.curAnim.name, 'end')) {
                note.scale.y = ((Conductor.stepCrochet * game.songSpeed * 0.6124) / 5.8) * 0.6; // Tweak the 0.7 to change size
            } else {
                note.scale.y = (Conductor.stepCrochet * game.songSpeed * 0.6124) / 5.8;
            }
                switch(note.noteData) {
                    case 0: // Left Sustain
                        note.offsetX += -0.4;
                    case 1: // Down Sustain
                        note.offsetX += -0.3;
                    case 2: // Up Sustain
                        note.offsetX += -0.5;
                    case 3: // Right Sustain
                        note.offsetX += -0.37;
                }
                note.updateHitbox();
            }
        }
    ]])
end

function onUpdate(delta)
    local nativeHealth = (playerHealth / maxHealth) * 2
    setHealth(nativeHealth)
    if playerHealth < 1 then
        setHealth(0)
    end
end

function onUpdatePost(elapsed)
    if flashTimer > 0 then
        flashTimer = flashTimer - elapsed
        if flashTimer <= 0 then
            if not isHealingFlash and flashCount > 0 then
                flashCount = flashCount - 1
                flashTimer = 0.1 
                updateHearts()
            else
                flashTimer = 0
                flashCount = 0
                isHealingFlash = false
                updateHearts()
            end
        end
    end
end

--function onSongStart()
--    runHaxeCode([[
--        game.notes.addCallback = function(note:Dynamic) {
--            if (!note.isSustainNote) {
--                game.notes.remove(note, true);
--                game.notes.insert(0, note);
--            }
--        };
--    ]])
--end

local oldBpm = 0
function onSectionHit()
    if curBpm == oldBpm then return end
    oldBpm = curBpm
    local speed = curBpm / 60
    setProperty('songSpeed', speed/2)
end
function noteMiss(id, direction, noteType, isSustainNote)
    playerHealth = math.max(0, playerHealth - 1)
    isHealingFlash = false
    flashCount = 5 
    flashTimer = 0.1 
    updateHearts()
end

function goodNoteHit(id, direction, noteType, isSustainNote)
    if playerHealth < maxHealth then
        local oldHealthFloor = math.floor(playerHealth)
        if not isSustainNote then
            playerHealth = math.min(maxHealth, playerHealth + 1)
        else
            flashNow = flashNow + 1
            playerHealth = math.min(maxHealth, playerHealth + 0.1)
        end
        if math.floor(playerHealth) > oldHealthFloor or not isSustainNote then
            isHealingFlash = true
            flashCount = 0
            flashTimer = 0.08 
        end
        updateHearts()
    end
end

function isFlashingNow()
    if flashTimer <= 0 then return false end
    if isHealingFlash then return true end
    return (flashCount % 2 == 1)
end

function updateHearts()
    local flashing = isFlashingNow()
    for i = 1, 10 do
        local value = playerHealth - ((i - 1) * 2)
        local state
        if value >= 2 then
            state = 'full'
        elseif value >= 1 and value < 2 then
            state = 'half'
        else
            state = 'empty'
        end
        if flashing then
            if state == 'full' then
                state = 'flashFull'
            elseif state == 'half' then
                state = 'flashHalf'
            else
                state = 'flashEmpty'
            end
        end
        playAnim('heart'..i, state, true)
    end
    if playerHealth <= 4.9 then
        runTimer('minecraftLowHealthShake', 0.03)
    else
        cancelTimer('minecraftLowHealthShake')
        for i = 1, 10 do
            local heartTag = 'heart'..i
            setProperty(heartTag..'.y', startY)
        end
    end
end
function onTimerCompleted(tag, loops, loopsLeft)
    if tag == 'minecraftLowHealthShake' then
        if playerHealth <= 4.9 then
            for i = 1, 10 do
                local heartTag = 'heart'..i
                local originalY = startY
                local shakeAmount = 5 
                local newY = originalY + (math.random() * shakeAmount * 2 - shakeAmount)
                setProperty(heartTag..'.y', newY)
            end
            runTimer('minecraftLowHealthShake', 0.03)
        end
    end
    if tag == 'respawnEnd' then
        restartSong()
    end
end
function onGameOverStart()
    makeLuaSprite('loading', 'loading', 0, 0)
    setObjectCamera('loading', 'hud')
    addLuaSprite('loading', true)
    startVideo('respawn', false)
    setObjectCamera('videoCutscene','other')
    runTimer('respawnEnd', 4.3)
end
function onDestroy()
    runHaxeCode([[
        if (ClientPrefs.data.arrowRGB != null) {
            if (ClientPrefs.data.arrowRGB.length > 1 && ClientPrefs.data.arrowRGB[1] != null && game.variables.get('oldDown0') != 0) {
                ClientPrefs.data.arrowRGB[1][0] = game.variables.get('oldDown0');
                ClientPrefs.data.arrowRGB[1][1] = game.variables.get('oldDown1');
            }
            if (ClientPrefs.data.arrowRGB.length > 2 && ClientPrefs.data.arrowRGB[2] != null && game.variables.get('oldUp0') != 0) {
                ClientPrefs.data.arrowRGB[2][0] = game.variables.get('oldUp0');
                ClientPrefs.data.arrowRGB[2][1] = game.variables.get('oldUp1');
            }
        }
    ]])
end