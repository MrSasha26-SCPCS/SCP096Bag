local GameObject = CS.UnityEngine.GameObject
local Vector3 = CS.UnityEngine.Vector3
local Vector2 = CS.UnityEngine.Vector2
local BindingFlags = CS.System.Reflection.BindingFlags

-- Settings
local dt = 1
local time = 11
--

local function GetHitList(pos, dir, maxDistance, gotMask)
    local mask = gotMask or CS.UnityEngine.LayerMask.GetMask("Default", "HitBox", "Door", "Glass")

    local target = nil

    local hits = CS.UnityEngine.Physics.RaycastAll(pos, dir, maxDistance, mask)

    if hits.Length == 0 then
        return nil
    end

    -- Переносим данные из C#-массива в таблицу Lua
    local hitList = {}
    for i = 0, hits.Length - 1 do
        table.insert(hitList, hits[i])
    end

    table.sort(hitList, function(a, b)
        return a.distance < b.distance
    end)

    return hitList
end

local function GetHit(pos, dir, maxDistance)
    local hitList = GetHitList(pos, dir, maxDistance)
    
    if hitList == nil or #hitList == 0 then return end

    local closest = hitList[1]

    local collider = closest.collider

    if collider == nil then
        return nil
    end

    local target = nil

    if collider.gameObject ~= nil and collider.gameObject.name == "ServerHitbox" then
        target = collider:GetComponentInParent(typeof(CS.Player))
    end

    if target == nil then
        local hitbox = collider:GetComponentInChildren(typeof(CS.HitBox))

        if hitbox ~= nil then
            target = hitbox.player
        end
    end

    return target
end

---@class SCP096Bag:CS.Akequ.Base.Item
SCP096Bag = {}

SCP096Bag.bundle = nil

SCP096Bag.dt = 0
SCP096Bag.isPutting = false

function SCP096Bag:GetPrefab()
    local model = GameObject.Instantiate(_G.scp096bag_bundle:LoadAsset("BagItem.prefab"))

    local meshRenderers = model:GetComponentsInChildren(typeof(CS.UnityEngine.MeshRenderer))
    for i = 0, meshRenderers.Length - 1 do
        local meshRenderer = meshRenderers[i]
        meshRenderer.material.shader = CS.UnityEngine.Shader.Find(meshRenderer.material.shader.name)
    end
    return model
end

function SCP096Bag:GetWorldPrefab()
    local model = GameObject.Instantiate(_G.scp096bag_bundle:LoadAsset("BagItem.prefab"))

    local meshRenderers = model:GetComponentsInChildren(typeof(CS.UnityEngine.MeshRenderer))
    for i = 0, meshRenderers.Length - 1 do
        local meshRenderer = meshRenderers[i]
        meshRenderer.material.shader = CS.UnityEngine.Shader.Find(meshRenderer.material.shader.name)
    end
    return model
end

function SCP096Bag:GetMobileInput()
    return { "Shoot" }
end

function SCP096Bag:GetName()
    return "Мешок"
end

function SCP096Bag:GetImage()
    return _G.sprites["scp096_bag"]
end

function SCP096Bag:OnDrop()
    if self.main.player.isServer then
        self:StopPutting()
    end
end

function SCP096Bag:OnHolster()
    if self.main.player.isServer then
        self:StopPutting()
    end
end

--SERVER
function SCP096Bag:ServerUpdate()
    self.dt = self.dt - CS.UnityEngine.Time.deltaTime
    if self.dt <= 0 then
        self.dt = dt
        self:ItemUpdate()
    end
end

function SCP096Bag:StopPutting()
    self.isPutting = false
    self.main:SendToClient("DisableText", self.main.player.connectionToClient)
end

function SCP096Bag:ItemUpdate()
    if self.isPutting then
        self.time = self.time - dt
        if CS.UnityEngine.Vector3.Distance(self.main.player.transform.position, self.currentSCP.transform.position) > 3.5 
        or self.currentSCP:GetRunSpeed() ~= 3.5 then
            self:StopPutting()
        end

        if self.time <= 0 then
            CS.HookManager.Run("onBagPut", self.currentSCP)
            self:StopPutting()
            GameObject.FindObjectOfType(typeof(CS.AdminPanel)):ShowAdminMessage("<color=green>Вы надели мешок</color>", 3, self.main.player)
            GameObject.FindObjectOfType(typeof(CS.AdminPanel)):ShowAdminMessage("<color=red>На вас надели мешок</color>", 3, self.currentSCP)
            self.main.player:RemoveItemOnServer(self.main.player.currentItem)
        end
    end
end

function SCP096Bag:StartPuttingBag_ServerOwner(currentSCP)
    if self.isPutting then return end
    
    if CS.UnityEngine.Vector3.Distance(self.main.player.transform.position, currentSCP.transform.position) > 3.5 then return end

    if currentSCP:GetRunSpeed() ~= 3.5 then return end

    self.isPutting = true
    self.currentSCP = currentSCP
    self.time = time

    self.main:SendToClient("EnableText", self.main.player.connectionToClient, "Вы надеваете мешок...")
end

--CLIENT
function SCP096Bag:EnableText(message)
    -- Creating text
    local canvas = GameObject.Find("PlayerCanvas")

    local text_tr = canvas.transform:Find("BagPuttingStatusText")

    if text_tr == nil and self.text_obj == nil then
        self.text_obj = GameObject("BagPuttingStatusText")
        self.text_obj.transform:SetParent(canvas.transform, false)
        self.text_obj.transform.localPosition = Vector3(0, 40, 0)
        local rt = self.text_obj:AddComponent(typeof(CS.UnityEngine.RectTransform))
        rt.anchorMin = Vector2(0.5, 0)
        rt.anchorMax = Vector2(0.5, 0)
        rt.pivot = Vector2(0.5, 0)
        rt.sizeDelta = Vector2(550, 52)
        local text_text = self.text_obj:AddComponent(typeof(CS.UnityEngine.UI.Text))
        text_text.alignment = CS.UnityEngine.TextAnchor.MiddleCenter
        --text_text.text = "<color=red>На вас смотрят " .. playersCountToBlock .."+ человек!</color>"
        text_text.fontSize = 32
        text_text.font = CS.UnityEngine.Resources.GetBuiltinResource(typeof(CS.UnityEngine.Font), "Arial.ttf")
        text_text.raycastTarget = false
    else
        self.text_obj = text_tr.gameObject
    end
    
    if self.text_obj == nil then return end
    self.text_obj:SetActive(true)
    local text_text = self.text_obj:GetComponent(typeof(CS.UnityEngine.UI.Text))
    text_text.text = message
end

function SCP096Bag:DisableText()
    if self.text_obj == nil then return end
    self.text_obj:SetActive(false)
end

function SCP096Bag:Update()
    if CS.UnityEngine.InputSystem.InputSystem.actions:FindAction("Shoot").triggered then
        self:ShootClient()
    end
end

function SCP096Bag:ShootClient()
    local hitPlayer = GetHit(self.main.player.transform.position, CS.UnityEngine.Camera.main.transform.forward, 2) 
    if hitPlayer ~= nil then
        if hitPlayer.playerClass:GetName() == "SCP-096" then
            self.main:SendToServer("StartPuttingBag_ServerOwner", hitPlayer)
        end
    end
end

return SCP096Bag