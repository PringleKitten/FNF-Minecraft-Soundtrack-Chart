function onCreate()
    makeLuaSprite('bg', 'menuBG', 0, 0)
    setScrollFactor('bg', 0, 0)
    setProperty('bg.antialiasing', false)
    setObjectCamera('bg', 'game')
    addLuaSprite('bg', true)
end
function onCreatePost()
    setProperty('boyfriend.visible', false)
    setProperty('dad.visible', false)
    setProperty('gf.visible', false)
    close()
end