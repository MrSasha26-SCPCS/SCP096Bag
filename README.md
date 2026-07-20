# SCP096Bag
SCP: CS plugin (RP)

Плагин, подходящий для рп серверов.

Добавляет новый предмет - мешок, который можно надеть на SCP-096. Объект может порвать мешок, если рядом с ним никого нет или по нему кто-то нанёс урон.

**Установка:** 
1) Оба `.lua` файла запихнуть в папку `Plugins`;
2) Файлы из папок в архиве `Windows` и `Android` поместить в папки `Plugins/client/Windows` и `Plugins/client/Android` соответственно;
3) Установить `init.lua` из репозитория `RP-Init` в папку `Plugins` (если не установлен) либо самостоятельно в существующем init файле зарегистрировать классы:
* В InitClient:
```
    PluginAPI.RegisterRoomEvent("SCP096BagManager")
    _G.scp096bag_bundle = CS.ScriptHelper.LoadBundle("scp096bag")

    _G.sprites = {}

    CS.ScriptHelper.LoadTexture("scp096_bag.png", function(texture)
        if texture ~= nil then
            local sprite = CS.UnityEngine.Sprite.Create(texture, CS.UnityEngine.Rect(0, 0, texture.width, texture.height), CS.UnityEngine.Vector2(0, 0)) 
            _G.sprites["scp096_bag"] = sprite 
            PluginAPI.RegisterItem("SCP096Bag", false, sprite)  
        else
            PluginAPI.RegisterItem("SCP096Bag", false)                
        end
    end)
```
* В InitServer:
```
    PluginAPI.RegisterRoomEvent("SCP096BagManager")
    _G.scp096bag_bundle = CS.ScriptHelper.LoadBundle("scp096bag")

    PluginAPI.RegisterItem("SCP096Bag", false)

    CS.HookManager.Add("onMapGenerationComplete", function(obj)
        PluginAPI.SpawnNetworkedEvent("SCP096BagManager")
    end)  
```
