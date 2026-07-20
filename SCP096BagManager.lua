local Vector3 = CS.UnityEngine.Vector3
local PlayerUtilities = CS.PlayerUtilities
local GameObject = CS.UnityEngine.GameObject

-- Settings

local dt = 1
local time = 11
local speedInBag = 3

--

local function findInObj(obj, name)
    local children = obj:GetComponentsInChildren(typeof(CS.UnityEngine.Transform))
    for i = 0, children.Length - 1 do
        local child = children[i]
        if child.name == name then
            return child.gameObject
        end
    end
end

---@class SCP096BagManagerBagManager:CS.Akequ.Base.Room
SCP096BagManager = {}

SCP096BagManager.isRoundStarted = false
SCP096BagManager.dt = 0
SCP096BagManager.scps096 = {}
SCP096BagManager.faces = {}
SCP096BagManager.bags = {}
SCP096BagManager.sent = false

SCP096BagManager.bag_obj = nil

function SCP096BagManager:Init()
    if self.main.netEvent.isServer then
        --[[local roomObj = GameObject.Find("Map_HC_096(Clone)")
        if roomObj ~= nil then
            local item = CS.ResourcesManager.SpawnItem("SCP096Bag")
            item.transform:SetParent(roomObj.transform)
            item.transform.localPosition = Vector3(2.29, 0.05, -5.26)
            item.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 90, 0)
        end]]
        
        CS.HookManager.Add("onRoundStart", function(obj)
            self.isRoundStarted = true
        end)
        CS.HookManager.Add("onPlayerSetClass", function(obj)
            for scp, info in pairs(self.scps096) do
                if scp == obj[0] then
                    self.scps096[scp] = nil
                    self.main:SendToEveryone("RemoveFace", scp)
                    break
                end
            end
        end)
        CS.HookManager.Add("onBagPut", function(obj)
            local scp = obj[0]
            if scp ~= nil then
                scp:SetSpeed(speedInBag, speedInBag, speedInBag)
                self.scps096[scp] = {inBag = true,
            timeToTear = time}
                self.main:SendToClient("ChangeSpeed", scp.connectionToClient, speedInBag)
                self.main:SendToEveryone("PutBag", scp)
            end
        end)
    end
end

function SCP096BagManager:Update()
    if self.main.netEvent.isServer then    
        self.dt = self.dt - CS.UnityEngine.Time.deltaTime
        if self.dt <= 0 then
            self.dt = dt
            self:PluginUpdate()
        end
    elseif self.main.netEvent.isClient and not self.sent then
        self.sent = true
        self.main:SendToServer("SendInstructions")
    end
end

--SERVER

function SCP096BagManager:SendInstructions(conn)
    for scp, info in pairs(self.scps096) do
        if info.inBag then
            self.main:SendToClient("PutBag", conn, scp)
        end
    end
end

function SCP096BagManager:TearBag(scp)
    self.scps096[scp].inBag = false
    GameObject.FindObjectOfType(typeof(CS.AdminPanel)):ShowAdminMessage("<color=green>Вы порвали мешок</color>", 3, scp)
    self.main:SendToEveryone("ClientTearBag", scp)
end

function SCP096BagManager:PluginUpdate()
    if self.isRoundStarted then    
        local players = GameObject.FindObjectsOfType(typeof(CS.Player))
        for scp, info in pairs(self.scps096) do
            if info.inBag then
                -- Проверка на то, что скромник в состоянии агра
                if scp:GetRunSpeed() ~= 3 then
                    self:TearBag(scp)
                else
                    -- Проверка на то, что со скромником рядом никого нет
                    local isPlayerNear = false
                    for i = 0, players.Length - 1 do
                        local player = players[i]
                        if player.playerClass ~= nil then
                            if player.playerClass:GetTeamID() ~= "SCP" and player.playerClass:GetTeamID() ~= "Spectator" then
                                if Vector3.Distance(player.transform.position, scp.transform.position) < 3.5 then
                                    isPlayerNear = true
                                    self.scps096[scp].timeToTear = time
                                    break
                                end
                            end
                        end
                    end
                    if not isPlayerNear then
                        self.scps096[scp].timeToTear = self.scps096[scp].timeToTear - dt
                        if self.scps096[scp].timeToTear <= 0 then
                            self.main:SendToClient("ChangeSpeed", scp.connectionToClient, 3.5)
                            self:TearBag(scp)
                        end
                    end
                end
            end
        end
    end
end

--CLIENT
function SCP096BagManager:RemoveFace(scp)
    if self.faces[scp] ~= nil then self.faces[scp] = nil end
    if self.bags[scp] ~= nil then self.bags[scp] = nil end
end

function SCP096BagManager:ChangeSpeed(speed)
    local localPlayer = PlayerUtilities.GetLocalPlayer()
    localPlayer:SetSpeed(speed, speed, speed)
end

function SCP096BagManager:ClientTearBag(scp)
    if scp == PlayerUtilities.GetLocalPlayer() then return end
    if self.faces[scp] ~= nil then   
        self.faces[scp]:SetActive(true)
    end
    if self.bags[scp] ~= nil then
        self.bags[scp]:SetActive(false)
    end
end

function SCP096BagManager:PutBag(scp)
    if scp == PlayerUtilities.GetLocalPlayer() then return end
    if self.faces[scp] == nil then    
        self.faces[scp] = findInObj(scp.playerClass.playerModel, "Face")
    end
    self.faces[scp]:SetActive(false)

    if self.bags[scp] == nil then
        self.bags[scp] = GameObject.Instantiate(_G.scp096bag_bundle:LoadAsset("Bag.prefab"))

        local meshRenderers = self.bags[scp]:GetComponentsInChildren(typeof(CS.UnityEngine.MeshRenderer))
        for i = 0, meshRenderers.Length - 1 do
            local meshRenderer = meshRenderers[i]
            meshRenderer.material.shader = CS.UnityEngine.Shader.Find(meshRenderer.material.shader.name)
        end
        
        local head_transform = findInObj(scp, "Head").transform

        self.bags[scp].transform:SetParent(head_transform)
        self.bags[scp].transform.localPosition = Vector3(0.0003, 0.0002, 0)
        self.bags[scp].transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, -90, 135)
    end    

    self.bags[scp]:SetActive(true)
end

return SCP096BagManager