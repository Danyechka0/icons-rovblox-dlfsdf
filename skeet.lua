-- Potassium / place 114234929420007. RightShift toggles the panel.
if game.PlaceId ~= 114234929420007 then error("Wrong place") end
local G = getgenv()
local previousState=G.RainPlaceSuite and G.RainPlaceSuite.state
if G.RainPlaceSuite and G.RainPlaceSuite.stop then
    local stopped=pcall(G.RainPlaceSuite.stop)
    if not stopped then
        pcall(function() local previous=game:GetService("CoreGui"):FindFirstChild("RainPlaceSuite",true); if previous then previous:Destroy() end end)
        G.RainPlaceSuite=nil
    end
end
local uiRoot
if gethui then local ok,result=pcall(gethui);if ok then uiRoot=result end end
uiRoot=uiRoot or game:GetService("CoreGui")
if uiRoot then
    for _,previous in ipairs(uiRoot:GetDescendants()) do
        if previous.Name=="RainPlaceSuite" then previous:Destroy() end
    end
end
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Tween = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera
local Bullet = require(RS.Components.Weapon.Classes.Bullet)
local Weapon = require(RS.Components.Weapon)
local CameraController = require(RS.Controllers.CameraController)
local DataController = require(RS.Controllers.DataController)
local InventoryController = require(RS.Controllers.InventoryController)
local CharacterClass = require(RS.Classes.Character)
local ViewmodelClass = require(RS.Classes.WeaponComponent.Classes.Viewmodel)
local WeaponComponentClass = require(RS.Classes.WeaponComponent)
local MoveButtons = require(RS.MovementV2.Buttons)
local MovementSettings = require(RS.MovementV2.Simulation.RuntimeSettings)
local state = {silent=false,esp=false,third=false,yaw=false,pitch=false,glow=false,bhop=false,strafe=false,tracers=false,noSpread=false,noRecoil=false,rapid=false,autoFire=false,jitter=false,wallbang=false,chinaHat=false,worldParticles=false,worldAmbient=false,jumpSpin=false,weaponChams=false,handChams=false,playerChams=false,localMaterial=false,chamGlow=false,handFovEnabled=false,mainFovEnabled=false,scopeCrosshair=true,scopeDot=true,aimAngle=90,zoom=5,yawAngle=90,pitchAngle=35,strafeStrength=65,rapidRps=15,jitterRange=25,jitterSpeed=12,particleCount=24,particleSpeed=4,ambientHue=220,ambientStrength=55,fogDistance=750,jumpSpinSpeed=540,chamHue=190,chamTransparency=35,handFov=70,mainFov=80,scopeGap=9,scopeLength=18,scopeThickness=2,scopeHue=190,modelScale=25,modelYOffset=0,modelChoice="Off",skin=nil,weapon=nil}
if type(previousState)=="table" then for key in pairs(state) do if previousState[key]~=nil then state[key]=previousState[key] end end end
local oldRay = Bullet._performRaycast
local oldGetTrueSpread = Bullet.getTrueSpread
local oldPerspective = CameraController.setPerspective
local oldWeaponKick = CameraController.weaponKick
local oldSetWeaponRecoil = CameraController.setWeaponRecoil
local oldSampleInput = CharacterClass.SampleInput
local oldPrepareInputFrame = CharacterClass.PrepareInputFrame
local oldViewmodelRender = ViewmodelClass.render
local oldMouseBehavior,oldMouseIcon=UIS.MouseBehavior,UIS.MouseIconEnabled
local oldCameraFov=Cam.FieldOfView
local main
local menuOpen=true
CameraController.setPerspective=function(firstPerson,mouseEnabled,distance)
    if state.third then return oldPerspective(false,menuOpen,state.zoom) end
    return oldPerspective(firstPerson,mouseEnabled,distance)
end
CameraController.weaponKick=function(...)
    if state.noRecoil then return end
    return oldWeaponKick(...)
end
CameraController.setWeaponRecoil=function(config,scale)
    if state.noRecoil then return oldSetWeaponRecoil({Value=Vector3.zero,Damper=1,Speed=25},scale) end
    return oldSetWeaponRecoil(config,scale)
end
Bullet.getTrueSpread=function(self)
    if state.noSpread then return 0 end
    return oldGetTrueSpread(self)
end
local function applyHandFov(model,largeModel)
    if not state.handFovEnabled or not model or not model.Parent then return false end
    local camera=workspace.CurrentCamera
    local original=model:GetPivot()
    local relative=camera.CFrame:ToObjectSpace(original)
    local factor=math.tan(math.rad(state.handFov*.5))/math.tan(math.rad(camera.FieldOfView*.5))
    local adjusted=camera.CFrame*CFrame.new(relative.Position*factor)*relative.Rotation
    local delta=adjusted*original:Inverse()
    model:PivotTo(adjusted)
    if largeModel and largeModel.Parent then largeModel:PivotTo(delta*largeModel:GetPivot()) end
    return true
end
ViewmodelClass.render=function(self,dt)
    local result=oldViewmodelRender(self,dt)
    applyHandFov(self.Model,self.LargeWeaponModel)
    return result
end
local oldLighting = {Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient,FogEnd=Lighting.FogEnd,FogColor=Lighting.FogColor,Brightness=Lighting.Brightness}
local connections, adornments = {}, {}
local gui = Instance.new("ScreenGui")
gui.Name = "RainPlaceSuite"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 500
gui.Parent = uiRoot
local function new(class,parent,props)
    local o=Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    o.Parent=parent
    return o
end
local iconAtlas
pcall(function()
    local path="rain_skeet_icons.webp"
    if not isfile(path) then
        writefile(path,game:HttpGet("https://raw.githubusercontent.com/Danyechka0/icons-rovblox-dlfsdf/refs/heads/main/image.webp"))
    end
    iconAtlas=(getcustomasset or getsynasset)(path)
end)
main=new("Frame",gui,{Name="SkeetPanel",Size=UDim2.fromOffset(580,500),Position=UDim2.new(.5,-290,.5,-250),BackgroundColor3=Color3.fromRGB(12,12,12),BorderSizePixel=0})
new("UIStroke",main,{Color=Color3.fromRGB(85,85,85),Thickness=1})
local innerBorder=new("Frame",main,{Position=UDim2.fromOffset(3,3),Size=UDim2.new(1,-6,1,-6),BackgroundTransparency=1,BorderSizePixel=0})
new("UIStroke",innerBorder,{Color=Color3.fromRGB(39,39,39),Thickness=1})
local top=new("Frame",main,{Name="DragBar",Position=UDim2.fromOffset(5,5),Size=UDim2.new(1,-10,0,17),BackgroundColor3=Color3.fromRGB(23,23,23),BorderSizePixel=0})
new("Frame",top,{Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,0,1),BackgroundColor3=Color3.fromRGB(115,115,115),BorderSizePixel=0})
new("TextLabel",top,{Position=UDim2.fromOffset(10,2),Size=UDim2.new(1,-20,0,13),BackgroundTransparency=1,Text="RAIN / CONTROL   •   RightShift",Font=Enum.Font.Code,TextSize=10,TextColor3=Color3.fromRGB(158,158,158),TextXAlignment=Enum.TextXAlignment.Left})
local nav=new("Frame",main,{Name="IconRail",Position=UDim2.fromOffset(5,27),Size=UDim2.new(0,62,1,-33),BackgroundColor3=Color3.fromRGB(8,8,8),BorderSizePixel=0})
new("UIStroke",nav,{Color=Color3.fromRGB(35,35,35),Thickness=1})
local pageDefinitions={{"Combat",0},{"Visuals",1},{"World",2},{"Movement",3},{"Player",4},{"Cosmetics",5},{"Config",7}}
local pages,pageColumns,navButtons={},{},{}
local currentPage
for i,definition in ipairs(pageDefinitions) do
    local name,iconIndex=definition[1],definition[2]
    local page=new("Frame",main,{Name=name,Position=UDim2.fromOffset(75,29),Size=UDim2.new(1,-82,1,-36),BackgroundTransparency=1,Visible=false})
    pages[name]=page
    pageColumns[name]={}
    for _,side in ipairs({"left","right"}) do
        local column=new("ScrollingFrame",page,{Name=side,Position=side=="left" and UDim2.fromOffset(0,0) or UDim2.new(.5,7,0,0),Size=UDim2.new(.5,-7,1,0),CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,ScrollBarImageColor3=Color3.fromRGB(96,96,96),BackgroundColor3=Color3.fromRGB(17,17,17),BorderSizePixel=0,Visible=true})
        new("UIStroke",column,{Color=Color3.fromRGB(42,42,42),Thickness=1})
        local layout=new("UIListLayout",column,{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder})
        table.insert(connections,layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() column.CanvasSize=UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+8) end))
        pageColumns[name][side]=column
    end
    local button=new("TextButton",nav,{Name=name.."Tab",Position=UDim2.fromOffset(6,5+(i-1)*49),Size=UDim2.fromOffset(49,43),Text="",BackgroundColor3=Color3.fromRGB(10,10,10),BorderSizePixel=0,AutoButtonColor=false})
    local border=new("UIStroke",button,{Color=Color3.fromRGB(36,36,36),Thickness=1})
    if iconAtlas then
        local icon=new("ImageLabel",button,{Name="Icon",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(30,30),BackgroundTransparency=1,Image=iconAtlas,ImageRectOffset=Vector2.new(iconIndex*40,0),ImageRectSize=Vector2.new(40,40),ImageTransparency=.30})
        navButtons[name]={button=button,border=border,icon=icon}
    else
        local fallback=new("TextLabel",button,{Name="Fallback",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=name:sub(1,1),Font=Enum.Font.Code,TextSize=21,TextColor3=Color3.fromRGB(175,175,175)})
        navButtons[name]={button=button,border=border,icon=fallback}
    end
end
local function selectPage(name)
    if not pages[name] then return end
    for key,page in pairs(pages) do
        local active=key==name
        page.Visible=active
        local navEntry=navButtons[key]
        navEntry.button.BackgroundColor3=active and Color3.fromRGB(30,30,30) or Color3.fromRGB(10,10,10)
        navEntry.border.Color=active and Color3.fromRGB(105,105,105) or Color3.fromRGB(36,36,36)
        if navEntry.icon:IsA("ImageLabel") then navEntry.icon.ImageTransparency=active and 0 or .38
        else navEntry.icon.TextColor3=active and Color3.fromRGB(235,235,235) or Color3.fromRGB(150,150,150) end
    end
    currentPage=pageColumns[name].left
end
local function useColumn(name,side)
    selectPage(name)
    currentPage=pageColumns[name][side]
end
for name,entry in pairs(navButtons) do
    table.insert(connections,entry.button.MouseButton1Click:Connect(function() selectPage(name) end))
end
local function section(label)
    local f=new("Frame",currentPage,{Size=UDim2.new(1,-12,0,23),BackgroundTransparency=1})
    new("TextLabel",f,{Position=UDim2.fromOffset(5,3),Size=UDim2.new(1,-10,0,15),BackgroundTransparency=1,Text=label,Font=Enum.Font.Code,TextSize=11,TextColor3=Color3.fromRGB(185,185,185),TextXAlignment=Enum.TextXAlignment.Left})
    new("Frame",f,{Position=UDim2.new(0,5,1,-2),Size=UDim2.new(1,-10,0,1),BackgroundColor3=Color3.fromRGB(45,45,45),BorderSizePixel=0})
end
local function row(label,height)
    local f=new("Frame",currentPage,{Size=UDim2.new(1,-12,0,height or 23),BackgroundTransparency=1})
    new("TextLabel",f,{Position=UDim2.fromOffset(8,2),Size=UDim2.new(1,-16,0,18),BackgroundTransparency=1,Text=label,Font=Enum.Font.Code,TextSize=10,TextColor3=Color3.fromRGB(180,180,180),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
    return f
end
local uiPainters={}
local function toggle(label,key)
    local f=row(label,21)
    local labelObject=f:FindFirstChildOfClass("TextLabel")
    labelObject.Position=UDim2.fromOffset(25,1)
    labelObject.Size=UDim2.new(1,-30,0,18)
    local b=new("TextButton",f,{Position=UDim2.fromOffset(8,4),Size=UDim2.fromOffset(12,12),BackgroundColor3=Color3.fromRGB(22,22,22),Text="",Font=Enum.Font.Code,TextSize=10,TextColor3=Color3.fromRGB(235,235,235),BorderSizePixel=0,AutoButtonColor=false})
    new("UIStroke",b,{Color=Color3.fromRGB(89,89,89),Thickness=1})
    local function paint()
        b.BackgroundColor3=state[key] and Color3.fromRGB(116,116,116) or Color3.fromRGB(22,22,22)
        b.Text=state[key] and "✓" or ""
    end
    paint();uiPainters[#uiPainters+1]=paint
    table.insert(connections,b.MouseButton1Click:Connect(function() state[key]=not state[key];paint() end))
    table.insert(connections,labelObject.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then state[key]=not state[key];paint() end end))
end
local activeSlider
local sliderControls={}
table.insert(connections,UIS.InputChanged:Connect(function(input)
    if activeSlider and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then activeSlider(input.Position.X) end
end))
table.insert(connections,UIS.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then activeSlider=nil end
end))
local function slider(label,key,min,max)
    local f=row(label,42)
    local value=new("TextLabel",f,{Position=UDim2.new(1,-42,0,1),Size=UDim2.fromOffset(34,18),BackgroundTransparency=1,TextColor3=Color3.fromRGB(207,207,207),Font=Enum.Font.Code,TextSize=10,TextXAlignment=Enum.TextXAlignment.Right})
    local track=new("Frame",f,{Position=UDim2.fromOffset(9,29),Size=UDim2.new(1,-18,0,4),BackgroundColor3=Color3.fromRGB(55,55,55),BorderSizePixel=0,Active=true})
    local fill=new("Frame",track,{Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(172,172,172),BorderSizePixel=0})
    local knob=new("Frame",track,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(0,.5),Size=UDim2.fromOffset(8,9),BackgroundColor3=Color3.fromRGB(223,223,223),BorderSizePixel=0,Active=true})
    local function paint()
        local alpha=math.clamp((state[key]-min)/(max-min),0,1)
        fill.Size=UDim2.fromScale(alpha,1)
        knob.Position=UDim2.fromScale(alpha,.5)
        value.Text=tostring(state[key])
    end
    local function update(x)
        state[key]=math.floor(min+(max-min)*math.clamp((x-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)+.5)
        paint()
    end
    paint();uiPainters[#uiPainters+1]=paint
    sliderControls[key]={track=track,fill=fill,knob=knob,dragAt=update,paint=paint}
    local function begin(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then activeSlider=update;update(input.Position.X) end
    end
    table.insert(connections,track.InputBegan:Connect(begin))
    table.insert(connections,knob.InputBegan:Connect(begin))
end
local function refreshControls()
    for _,paint in ipairs(uiPainters) do paint() end
end
local function actionButton(label,callback)
    local r=row("",28)
    local b=new("TextButton",r,{Position=UDim2.fromOffset(8,2),Size=UDim2.new(1,-16,0,23),Text=label,Font=Enum.Font.Code,TextSize=10,TextColor3=Color3.fromRGB(210,210,210),BackgroundColor3=Color3.fromRGB(30,30,30),BorderSizePixel=0})
    new("UIStroke",b,{Color=Color3.fromRGB(68,68,68),Thickness=1})
    table.insert(connections,b.MouseButton1Click:Connect(callback))
    return b
end
useColumn("Combat","left")
section("Aimbot")
toggle("Silent aim","silent")
slider("Silent FOV","aimAngle",1,180)
toggle("Wallbang","wallbang")
toggle("Auto fire on target","autoFire")
useColumn("Combat","right")
section("Accuracy")
toggle("No spread","noSpread")
toggle("No recoil","noRecoil")
toggle("Rapid fire","rapid")
slider("Rapid shots / sec","rapidRps",2,25)
useColumn("Visuals","left")
section("ESP")
toggle("Box / HP / name","esp")
toggle("Player chams","playerChams")
toggle("Bullet tracers","tracers")
useColumn("Visuals","right")
section("Chams")
toggle("Weapon ForceField","weaponChams")
toggle("Hand ForceField","handChams")
toggle("Cham glow","chamGlow")
slider("Cham hue","chamHue",0,360)
slider("Cham transparency","chamTransparency",0,90)
useColumn("World","left")
section("World")
toggle("World ambient","worldAmbient")
slider("Ambient hue","ambientHue",0,360)
slider("Ambient strength","ambientStrength",0,100)
slider("Fog distance","fogDistance",150,2000)
toggle("Legacy glow","glow")
useColumn("World","right")
section("Effects")
toggle("China hat","chinaHat")
toggle("3D world particles","worldParticles")
slider("Particle count","particleCount",8,60)
slider("Particle speed","particleSpeed",1,12)
useColumn("Movement","left")
section("Movement")
toggle("Bunnyhop · hold Space","bhop")
toggle("Air strafe","strafe")
slider("Strafe strength","strafeStrength",0,100)
toggle("Spin while jumping","jumpSpin")
slider("Jump spin speed","jumpSpinSpeed",90,1080)
useColumn("Movement","right")
section("Anti-aim")
toggle("Full-body yaw","yaw")
slider("Yaw angle","yawAngle",-180,180)
toggle("Pitch · torso/arms/head","pitch")
slider("Pitch angle","pitchAngle",-80,80)
toggle("Yaw / pitch jitter","jitter")
slider("Jitter range","jitterRange",0,90)
slider("Jitter speed","jitterSpeed",2,30)
useColumn("Player","left")
section("Camera")
toggle("Third person","third")
slider("Camera distance","zoom",3,15)
toggle("Main FOV override","mainFovEnabled")
slider("Main camera FOV","mainFov",50,120)
toggle("Hand FOV override","handFovEnabled")
slider("Hand FOV","handFov",50,120)
useColumn("Player","right")
section("Local")
toggle("Local player material","localMaterial")
section("Scope crosshair")
toggle("Replace scope overlay","scopeCrosshair")
toggle("Center dot","scopeDot")
slider("Scope gap","scopeGap",2,30)
slider("Line length","scopeLength",6,36)
slider("Thickness","scopeThickness",1,6)
slider("Scope hue","scopeHue",0,360)
useColumn("Config","left")
section("Profile")
local configStatus=row("Profile ready",24):FindFirstChildOfClass("TextLabel")
actionButton("Save profile",function()
    local ok,err=pcall(function() writefile("rain_skeet_profile.json",game:GetService("HttpService"):JSONEncode(state)) end)
    configStatus.Text=ok and "Profile saved" or ("Save error: "..tostring(err))
end)
actionButton("Load profile",function()
    local ok,result=pcall(function() return game:GetService("HttpService"):JSONDecode(readfile("rain_skeet_profile.json")) end)
    if ok and type(result)=="table" then
        for key,value in pairs(result) do if state[key]~=nil and type(state[key])==type(value) then state[key]=value end end
        refreshControls()
        configStatus.Text="Profile loaded"
        if G.RainPlaceSuite and G.RainPlaceSuite.updateAvatarModel then G.RainPlaceSuite.updateAvatarModel() end
    else configStatus.Text="Load error: "..tostring(result) end
end)
useColumn("Config","right")
section("Interface")
row("RightShift: show / hide",23)
row("Drag the top bar to move",23)
row("Icon atlas: 320 × 40",23)
selectPage("Combat")
currentPage=pageColumns.Cosmetics.left
local list=currentPage
local fovRing=new("Frame",gui,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(240,240),BackgroundTransparency=1,Visible=false,ZIndex=2})
new("UICorner",fovRing,{CornerRadius=UDim.new(1,0)})
new("UIStroke",fovRing,{Color=Color3.fromRGB(115,170,255),Thickness=2,Transparency=.1})
local fovText=new("TextLabel",fovRing,{AnchorPoint=Vector2.new(.5,0),Position=UDim2.fromScale(.5,0),Size=UDim2.fromOffset(75,18),BackgroundTransparency=1,Text="FOV 90°",TextColor3=Color3.fromRGB(190,220,255),Font=Enum.Font.GothamBold,TextSize=11,ZIndex=3})
local fovDot=new("Frame",gui,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(5,5),BackgroundColor3=Color3.fromRGB(180,216,255),BorderSizePixel=0,Visible=false,ZIndex=3})
new("UICorner",fovDot,{CornerRadius=UDim.new(1,0)})
local scopeCross=new("Frame",gui,{Name="RainScopeCrosshair",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(0,0),BackgroundTransparency=1,Visible=false,ZIndex=20})
local scopeLines={}
for _,name in ipairs({"left","right","top","bottom"}) do
    local outer=new("Frame",scopeCross,{Name=name.."Outline",BackgroundColor3=Color3.fromRGB(4,6,10),BorderSizePixel=0,ZIndex=20})
    local inner=new("Frame",outer,{Name=name.."Line",Position=UDim2.fromOffset(1,1),BackgroundColor3=Color3.fromRGB(110,220,255),BorderSizePixel=0,ZIndex=21})
    scopeLines[name]={outer=outer,inner=inner}
end
local scopeDotOuter=new("Frame",scopeCross,{Name="DotOutline",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(5,5),BackgroundColor3=Color3.fromRGB(4,6,10),BorderSizePixel=0,ZIndex=20})
local scopeDotInner=new("Frame",scopeDotOuter,{Name="Dot",Position=UDim2.fromOffset(1,1),Size=UDim2.fromOffset(3,3),BackgroundColor3=Color3.fromRGB(110,220,255),BorderSizePixel=0,ZIndex=21})
local nativeScopeFrame
local scopeSuppressedFrame
local nativeCrosshairFrame
local suppressedCrosshairFrame
local crosshairWasVisible
local scopeWatchers=setmetatable({}, {__mode="k"})
local function getNativeScopeFrame()
    if nativeScopeFrame and nativeScopeFrame.Parent then return nativeScopeFrame end
    local playerGui=LP:FindFirstChildOfClass("PlayerGui")
    local mainGui=playerGui and playerGui:FindFirstChild("MainGui")
    local gameplay=mainGui and mainGui:FindFirstChild("Gameplay")
    local middle=gameplay and gameplay:FindFirstChild("Middle")
    nativeScopeFrame=middle and middle:FindFirstChild("SniperScope")
    return nativeScopeFrame
end
local function getNativeCrosshairFrame()
    if nativeCrosshairFrame and nativeCrosshairFrame.Parent then return nativeCrosshairFrame end
    local playerGui=LP:FindFirstChildOfClass("PlayerGui")
    local mainGui=playerGui and playerGui:FindFirstChild("MainGui")
    local gameplay=mainGui and mainGui:FindFirstChild("Gameplay")
    local middle=gameplay and gameplay:FindFirstChild("Middle")
    nativeCrosshairFrame=middle and middle:FindFirstChild("Crosshair")
    return nativeCrosshairFrame
end
local function scopeIsActive()
    if LP:GetAttribute("IsSniperScoped")==true then return true end
    local weapon=InventoryController.peekCurrentEquippedForMovement()
    return weapon~=nil and weapon.IsSniperScoped==true
end
local function watchNativeOverlay(frame)
    if not frame or scopeWatchers[frame] then return end
    local connection=frame:GetPropertyChangedSignal("Visible"):Connect(function()
        if state.scopeCrosshair and scopeIsActive() and frame.Visible then frame.Visible=false end
    end)
    scopeWatchers[frame]=connection
    table.insert(connections,connection)
end
local function updateScopeCrosshair(scopedOverride)
    local native=getNativeScopeFrame()
    local nativeCrosshair=getNativeCrosshairFrame()
    watchNativeOverlay(native)
    watchNativeOverlay(nativeCrosshair)
    local scoped=scopedOverride
    if scoped==nil then
        scoped=scopeIsActive()
        if not scoped and not scopeSuppressedFrame and native and native.Visible then scoped=true end
    end
    local enabled=state.scopeCrosshair and scoped==true
    scopeCross.Visible=enabled
    if enabled then
        local gap,length,thickness=state.scopeGap,state.scopeLength,state.scopeThickness
        local color=Color3.fromHSV(state.scopeHue/360,.75,1)
        local function place(name,x,y,w,h)
            local line=scopeLines[name]
            line.outer.Position=UDim2.fromOffset(x-1,y-1)
            line.outer.Size=UDim2.fromOffset(w+2,h+2)
            line.inner.Size=UDim2.fromOffset(w,h)
            line.inner.BackgroundColor3=color
        end
        place("left",-gap-length,-math.floor(thickness/2),length,thickness)
        place("right",gap,-math.floor(thickness/2),length,thickness)
        place("top",-math.floor(thickness/2),-gap-length,thickness,length)
        place("bottom",-math.floor(thickness/2),gap,thickness,length)
        scopeDotOuter.Visible=state.scopeDot
        scopeDotInner.BackgroundColor3=color
        if native then
            scopeSuppressedFrame=native
            native.Visible=false
        end
        if nativeCrosshair then
            if suppressedCrosshairFrame~=nativeCrosshair then
                suppressedCrosshairFrame=nativeCrosshair
                crosshairWasVisible=nativeCrosshair.Visible
            end
            nativeCrosshair.Visible=false
        end
    elseif scopeSuppressedFrame then
        if scopeSuppressedFrame.Parent then scopeSuppressedFrame.Visible=scoped==true end
        scopeSuppressedFrame=nil
    end
    if not enabled and suppressedCrosshairFrame then
        if suppressedCrosshairFrame.Parent then suppressedCrosshairFrame.Visible=crosshairWasVisible==true end
        suppressedCrosshairFrame=nil
        crosshairWasVisible=nil
    end
end
local function restoreScopeOverlay()
    scopeCross.Visible=false
    if scopeSuppressedFrame and scopeSuppressedFrame.Parent then scopeSuppressedFrame.Visible=scopeIsActive() end
    scopeSuppressedFrame=nil
    if suppressedCrosshairFrame and suppressedCrosshairFrame.Parent then suppressedCrosshairFrame.Visible=crosshairWasVisible==true end
    suppressedCrosshairFrame=nil
    crosshairWasVisible=nil
end
section("Weapon skins")
local skinRow=row("Skin catalog",37)
local skinButton=new("TextButton",skinRow,{Position=UDim2.new(.45,0,0,5),Size=UDim2.new(.55,-9,0,24),Text="Select weapon",Font=Enum.Font.Code,TextSize=10,TextColor3=Color3.fromRGB(220,220,220),BackgroundColor3=Color3.fromRGB(28,28,28),BorderSizePixel=0})
new("UIStroke",skinButton,{Color=Color3.fromRGB(72,72,72),Thickness=1})
local knifeRow=row("Knife skins catalog",37)
local knifeButton=new("TextButton",knifeRow,{Position=UDim2.new(1,-93,0,5),Size=UDim2.fromOffset(84,24),Text="KNIVES",Font=Enum.Font.Code,TextSize=10,TextColor3=Color3.fromRGB(220,220,220),BackgroundColor3=Color3.fromRGB(28,28,28),BorderSizePixel=0})
new("UIStroke",knifeButton,{Color=Color3.fromRGB(72,72,72),Thickness=1})
local catalog=new("ScrollingFrame",list,{Size=UDim2.new(1,-12,0,110),CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,BackgroundColor3=Color3.fromRGB(18,18,18),BorderSizePixel=0,Visible=false})
new("UIStroke",catalog,{Color=Color3.fromRGB(54,54,54),Thickness=1})
local cl=new("UIListLayout",catalog,{Padding=UDim.new(0,2)})
table.insert(connections,cl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() catalog.CanvasSize=UDim2.fromOffset(0,cl.AbsoluteContentSize.Y) end))
local status=row("Local skin status: idle")
local statusLabel=status:FindFirstChildOfClass("TextLabel")
slider("Avatar model size %","modelScale",5,100)
slider("Avatar model height","modelYOffset",-30,30)
local function clearCatalog() for _,v in ipairs(catalog:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end end
local function menuItem(label,fn)
    local b=new("TextButton",catalog,{Size=UDim2.new(1,-5,0,25),Text=label,TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Code,TextSize=10,TextColor3=Color3.fromRGB(220,220,220),BackgroundColor3=Color3.fromRGB(30,30,30),BorderSizePixel=0})
    table.insert(connections,b.MouseButton1Click:Connect(fn))
end
local skinFolder=RS.Assets.Skins
local catalogKnives=false
local function isKnifeName(name)
    return string.find(name,"Knife",1,true)~=nil or name=="Karambit" or name=="M9 Bayonet" or name=="LightSaber"
end
local nativeOriginals=setmetatable({}, {__mode="k"})
local nativeApplied=setmetatable({}, {__mode="k"})
local oldViewmodelNew=ViewmodelClass.new
local oldComponentNew=WeaponComponentClass.new
local function selectedSkinFor(name)
    if not state.weapon or not state.skin or not name then return nil end
    if name~=state.weapon and not (isKnifeName(name) and isKnifeName(state.weapon)) then return nil end
    local folder=skinFolder:FindFirstChild(state.weapon)
    if not folder or not folder:FindFirstChild(state.skin) then return nil end
    return state.weapon,state.skin
end
ViewmodelClass.new=function(component,name,skin,inspecting)
    local selectedWeapon,selectedSkin
    if component and component.Player==LP then selectedWeapon,selectedSkin=selectedSkinFor(name) end
    if selectedSkin then
        if selectedWeapon~=name then component.ViewmodelCameraWeapon=selectedWeapon end
        skin=selectedSkin
    end
    return oldViewmodelNew(component,name,skin,inspecting)
end
WeaponComponentClass.new=function(player,identifier,id,slot,name,skin,float,statTrack,nameTag,originalOwner,charm,stickers)
    local selectedWeapon,selectedSkin
    if player==LP then selectedWeapon,selectedSkin=selectedSkinFor(name) end
    local originalSkin,originalId=skin,id
    if selectedSkin then skin=selectedSkin end
    local component=oldComponentNew(player,identifier,id,slot,name,skin,float,statTrack,nameTag,originalOwner,charm,stickers)
    if selectedSkin then
        nativeOriginals[component]={skin=originalSkin,id=originalId,camera=nil}
        component._id=selectedWeapon.."_"..selectedSkin
        nativeApplied[component]=component._id
    end
    return component
end
local function rebuildNativeViewmodel(component,oldCamera)
    local oldViewmodel=component.Viewmodel
    if not oldViewmodel or not LP.Character then return false,"viewmodel unavailable" end
    local wasEquipped=oldViewmodel.IsEquipped
    local thread=getthreadidentity()
    local ok,result=pcall(function()
        setthreadidentity(2)
        if oldCamera~=component.ViewmodelCameraWeapon then
            local newViewmodel=oldViewmodelNew(component,component.Name,component.Skin)
            if wasEquipped then newViewmodel:equip(true) end
            component.Viewmodel=newViewmodel
            oldViewmodel:destroy()
        else
            oldViewmodel.Skin=component.Skin
            oldViewmodel:construct(LP.Character,component)
            if wasEquipped then oldViewmodel:equip(true) end
        end
    end)
    setthreadidentity(thread)
    if not ok then
        pcall(function() if oldViewmodel and not oldViewmodel.IsDestroyed then oldViewmodel:equip(true) end end)
        return false,tostring(result)
    end
    return true,"native viewmodel"
end
local function applySelectedSkin()
    if not state.weapon or not state.skin then return false,"no skin selected" end
    local component=InventoryController.peekCurrentEquippedForMovement()
    if not component or component.IsDestroyed then return false,"equip weapon" end
    local selectedWeapon,selectedSkin=selectedSkinFor(component.Name)
    if not selectedSkin then return false,"equip selected weapon" end
    local id=selectedWeapon.."_"..selectedSkin
    if nativeApplied[component]==id then return true,"already applied" end
    if not nativeOriginals[component] then nativeOriginals[component]={skin=component.Skin,id=component._id,camera=component.ViewmodelCameraWeapon} end
    local previousCamera=component.ViewmodelCameraWeapon
    local previousSkin,previousId=component.Skin,component._id
    component.Skin=selectedSkin
    component._id=id
    component.ViewmodelCameraWeapon=selectedWeapon~=component.Name and selectedWeapon or nativeOriginals[component].camera
    local ok,message=rebuildNativeViewmodel(component,previousCamera)
    if not ok then
        component.Skin=previousSkin;component._id=previousId;component.ViewmodelCameraWeapon=previousCamera
        return false,message
    end
    nativeApplied[component]=id
    return true,message
end
local function restoreNativeSkins()
    for component,original in pairs(nativeOriginals) do
        if not component.IsDestroyed then
            local previousCamera=component.ViewmodelCameraWeapon
            component.Skin=original.skin;component._id=original.id;component.ViewmodelCameraWeapon=original.camera
            rebuildNativeViewmodel(component,previousCamera)
        end
        nativeOriginals[component]=nil
        nativeApplied[component]=nil
    end
end
local customModels={
    ["tung tung sahur"]={mesh="117017506009125",texture="116763513432566"},
    anime={mesh="6211683655",texture="6211683781"},
    lada={mesh="6716119535",texture="6716119636"},
}
local avatarOverlays=setmetatable({}, {__mode="k"})
local function hideAvatarObject(record,object)
    if object==record.part or object==record.root then return end
    local weaponRoot=record.character:FindFirstChild("WeaponModel")
    if weaponRoot and object:IsDescendantOf(weaponRoot) then return end
    if object:IsA("BasePart") then
        if not record.originals[object] then
            record.originals[object]={kind="part",transparency=object.Transparency,localAlpha=object.LocalTransparencyModifier}
        end
        object.Transparency=1
        object.LocalTransparencyModifier=1
    elseif object:IsA("Decal") or object:IsA("Texture") then
        if not record.originals[object] then record.originals[object]={kind="image",transparency=object.Transparency} end
        object.Transparency=1
    end
end
local function enforceAvatarHidden(record)
    for object,original in pairs(record.originals) do
        if object.Parent then
            object.Transparency=1
            if original.kind=="part" then object.LocalTransparencyModifier=1 end
        end
    end
end
local function removeAvatarModel(character)
    local record=avatarOverlays[character]
    if not record then return end
    if record.connection then record.connection:Disconnect() end
    for object,original in pairs(record.originals) do
        if object.Parent then
            object.Transparency=original.transparency
            if original.kind=="part" then object.LocalTransparencyModifier=original.localAlpha end
        end
    end
    if record.part.Parent then record.part:Destroy() end
    avatarOverlays[character]=nil
end
local function applyAvatarModel(character)
    if not character or not character.Parent or state.modelChoice=="Off" then return false end
    local preset=customModels[state.modelChoice]
    local root=character:FindFirstChild("HumanoidRootPart")
    if not preset or not root or not root:IsA("BasePart") then return false end
    local record=avatarOverlays[character]
    if record and record.choice==state.modelChoice and record.part.Parent then
        record.mesh.Scale=Vector3.new(1,1,1)*(state.modelScale/100)
        record.weld.C0=CFrame.new(0,state.modelYOffset/10,0)
        enforceAvatarHidden(record)
        return true
    end
    removeAvatarModel(character)
    record={character=character,root=root,choice=state.modelChoice,originals={}}
    for _,object in ipairs(character:GetDescendants()) do hideAvatarObject(record,object) end
    local part=Instance.new("Part")
    part.Name="RainAvatarModel"
    part.Size=Vector3.new(1,1,1)
    part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Massless=true
    part.CFrame=root.CFrame*CFrame.new(0,state.modelYOffset/10,0)
    local mesh=Instance.new("SpecialMesh")
    mesh.MeshType=Enum.MeshType.FileMesh
    mesh.MeshId="rbxassetid://"..preset.mesh
    mesh.TextureId="rbxassetid://"..preset.texture
    mesh.Scale=Vector3.new(1,1,1)*(state.modelScale/100)
    mesh.Parent=part
    part.Parent=character
    local weld=Instance.new("Weld")
    weld.Part0=root;weld.Part1=part;weld.C0=CFrame.new(0,state.modelYOffset/10,0);weld.Parent=part
    record.part=part;record.mesh=mesh;record.weld=weld
    record.connection=character.DescendantAdded:Connect(function(object) hideAvatarObject(record,object) end)
    avatarOverlays[character]=record
    return true
end
local function updateAvatarModel()
    local character=LP.Character
    if state.modelChoice~="Off" and character then applyAvatarModel(character) end
    for model in pairs(avatarOverlays) do if model~=character or state.modelChoice=="Off" then removeAvatarModel(model) end end
end
local chamOriginals=setmetatable({}, {__mode="k"})
local function restoreCham(part)
    local record=chamOriginals[part]
    if not record then return end
    if record.light and record.light.Parent then record.light:Destroy() end
    if part.Parent then
        part.Material=record.material
        part.Color=record.color
        part.Transparency=record.transparency
        part.Reflectance=record.reflectance
        local current=part:FindFirstChildOfClass("SurfaceAppearance")
        if current then current:Destroy() end
        if record.surface then record.surface:Clone().Parent=part end
    end
    if record.surface then record.surface:Destroy() end
    chamOriginals[part]=nil
end
local function restoreAllChams()
    for part in pairs(chamOriginals) do restoreCham(part) end
end
local function applyCham(part)
    if not part:IsA("BasePart") then return end
    local record=chamOriginals[part]
    if not record then
        local surface=part:FindFirstChildOfClass("SurfaceAppearance")
        record={material=part.Material,color=part.Color,transparency=part.Transparency,reflectance=part.Reflectance,surface=surface and surface:Clone() or false}
        chamOriginals[part]=record
    end
    local surface=part:FindFirstChildOfClass("SurfaceAppearance")
    if surface then surface:Destroy() end
    part.Material=Enum.Material.ForceField
    part.Color=Color3.fromHSV(state.chamHue/360,.85,1)
    part.Transparency=state.chamTransparency/100
    part.Reflectance=.08
    if state.chamGlow then
        if not record.light or not record.light.Parent then
            record.light=new("PointLight",part,{Name="RainChamGlow",Brightness=1.7,Range=7,Shadows=false})
        end
        record.light.Color=part.Color
    elseif record.light then record.light:Destroy();record.light=nil end
end
local function updateMaterialChams()
    local touched={}
    local camera=workspace.CurrentCamera
    for _,model in ipairs(camera:GetChildren()) do
        if model:IsA("Model") and model:FindFirstChild("Weapon") then
            local weaponRoot=model.Weapon
            for _,part in ipairs(model:GetDescendants()) do
                if part:IsA("MeshPart") then
                    local name=part.Name
                    local isHand=name:find("Arm",1,true) or name:find("Hand",1,true) or name:find("Sleeve",1,true)
                    if (state.weaponChams and part:IsDescendantOf(weaponRoot)) or (state.handChams and isHand and not part:IsDescendantOf(weaponRoot)) then
                        touched[part]=true;applyCham(part)
                    end
                end
            end
        end
    end
    local character=LP.Character
    if character and state.localMaterial then
        local weaponRoot=character:FindFirstChild("WeaponModel")
        for _,part in ipairs(character:GetDescendants()) do
            if part:IsA("MeshPart") and (not weaponRoot or not part:IsDescendantOf(weaponRoot)) and part.Name~="HumanoidRootPart" then
                touched[part]=true;applyCham(part)
            end
        end
    end
    if character and state.weaponChams then
        local weaponRoot=character:FindFirstChild("WeaponModel")
        if weaponRoot then for _,part in ipairs(weaponRoot:GetDescendants()) do if part:IsA("MeshPart") then touched[part]=true;applyCham(part) end end end
    end
    for part in pairs(chamOriginals) do if not touched[part] then restoreCham(part) end end
end
local function populateCatalog()
    catalog.Visible=true; clearCatalog()
    if not state.weapon then
        local folders=skinFolder:GetChildren(); table.sort(folders,function(a,b)return a.Name<b.Name end)
        for _,folder in ipairs(folders) do if not catalogKnives or isKnifeName(folder.Name) then menuItem(folder.Name,function() restoreNativeSkins();state.weapon=folder.Name;state.skin=nil; skinButton.Text=folder.Name.." ▾"; populateCatalog() end) end end
    else
        menuItem("← weapons",function() restoreNativeSkins();state.weapon=nil;state.skin=nil; skinButton.Text="Select weapon"; populateCatalog() end)
        local folder=skinFolder:FindFirstChild(state.weapon)
        if folder then local skins=folder:GetChildren(); table.sort(skins,function(a,b)return a.Name<b.Name end)
            for _,asset in ipairs(skins) do menuItem(asset.Name,function()
                restoreAllChams()
                state.skin=asset.Name; catalog.Visible=false; skinButton.Text=state.weapon.." | "..asset.Name
                local ok,result=applySelectedSkin()
                statusLabel.Text=ok and ("Local skin: "..state.weapon.." / "..asset.Name) or ("Local skin: "..result)
                print("[RAIN] local skin",state.weapon,asset.Name,ok,result)
            end) end
        end
    end
end
table.insert(connections,skinButton.MouseButton1Click:Connect(populateCatalog))
table.insert(connections,knifeButton.MouseButton1Click:Connect(function()
    restoreNativeSkins()
    catalogKnives=not catalogKnives
    state.weapon=nil
    state.skin=nil
    skinButton.Text="Select "..(catalogKnives and "knife" or "weapon")
    knifeButton.Text=catalogKnives and "ALL" or "KNIVES"
    populateCatalog()
end))
currentPage=pageColumns.Cosmetics.right
section("Player model")
local modelRow=row("Player avatar model",72)
local modelButtons={}
for i,name in ipairs({"Off","tung tung sahur","anime","lada"}) do
    local x=(i-1)%2
    local y=math.floor((i-1)/2)
    local b=new("TextButton",modelRow,{Position=UDim2.new(x*.5,8,0,23+y*23),Size=UDim2.new(.5,-15,0,20),Text=name,Font=Enum.Font.Code,TextSize=10,TextColor3=Color3.fromRGB(220,220,220),BackgroundColor3=Color3.fromRGB(28,28,28),BorderSizePixel=0})
    new("UIStroke",b,{Color=Color3.fromRGB(72,72,72),Thickness=1})
    modelButtons[name]=b
    table.insert(connections,b.MouseButton1Click:Connect(function()
        state.modelChoice=name
        updateAvatarModel()
        for choice,button in pairs(modelButtons) do button.BackgroundColor3=choice==name and Color3.fromRGB(92,92,92) or Color3.fromRGB(28,28,28) end
        statusLabel.Text="Model: "..name
    end))
end
modelButtons[state.modelChoice].BackgroundColor3=Color3.fromRGB(92,92,92)
local function alive(p)
    local c=p.Character
    if not c or not c.Parent or not c:FindFirstChild("Head") or c:GetAttribute("Dead")==true then return false end
    local hp=c:GetAttribute("Health")
    local hum=c:FindFirstChildOfClass("Humanoid")
    return (type(hp)=="number" and hp>0) or (hum and hum.Health>0) or (hp==nil and hum==nil)
end
local function enemy(p)
    local a=LP:GetAttribute("Team") or (LP.Team and LP.Team.Name)
    local b=p:GetAttribute("Team") or (p.Team and p.Team.Name)
    return not a or not b or a~=b
end
local function rayParams()
    local ignore={Cam}
    if LP.Character then ignore[#ignore+1]=LP.Character end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances=ignore
    params.IgnoreWater=true
    return params
end
local function closest()
    local best,bestAngle=nil,state.aimAngle*.5
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and enemy(p) and alive(p) then
            local head=p.Character.Head
            local dir=head.Position-Cam.CFrame.Position
            if dir.Magnitude>.01 then
                local angle=math.deg(math.acos(math.clamp(Cam.CFrame.LookVector:Dot(dir.Unit),-1,1)))
                if angle<bestAngle then
                    if state.wallbang then
                        best,bestAngle=p,angle
                    else
                        local hit=workspace:Raycast(Cam.CFrame.Position,head.Position-Cam.CFrame.Position,rayParams())
                        if hit and hit.Instance:IsDescendantOf(p.Character) then best,bestAngle=p,angle end
                    end
                end
            end
        end
    end
    return best
end
local lastTriggered=0
local function fireStep(mouseHeld,targetPresent,weaponOverride)
    if menuOpen or not ((state.rapid and mouseHeld) or (state.autoFire and targetPresent)) then return false,"inactive" end
    local weapon=weaponOverride or InventoryController.peekCurrentEquippedForMovement()
    if not weapon or weapon.IsDestroyed or not weapon.IsEquipped or not weapon.Bullet or (weapon.Rounds or 0)<=0 then return false,"no ready weapon" end
    if weapon.Properties and weapon.Properties.Class=="Melee" then return false,"melee" end
    local interval=state.rapid and 1/math.max(state.rapidRps,1) or (weapon.Properties and weapon.Properties.FireRate or .1)
    if os.clock()-lastTriggered<interval then return false,"cadence" end
    lastTriggered=os.clock()
    if state.rapid then
        if weapon.ShootDelayThread then pcall(task.cancel,weapon.ShootDelayThread); weapon.ShootDelayThread=nil end
        weapon.IsShooting=false
        weapon.NextShotDue=nil
    end
    local before=weapon.ShotSeq or 0
    local ok,err=pcall(function() weapon:shoot() end)
    if not ok then return false,tostring(err) end
    return (weapon.ShotSeq or 0)>before,"shot requested"
end
local activeTracers={}
local function drawTracer(shot,hitTarget)
    if not state.tracers or not shot or not shot.Origin or not shot.Direction then return end
    local finish=shot.Hits and shot.Hits[#shot.Hits] and shot.Hits[#shot.Hits].Position or (shot.Origin+shot.Direction*120)
    local delta=finish-shot.Origin
    if delta.Magnitude<.1 then return end
    local part=new("Part",workspace.CurrentCamera,{Name="RainBulletTracer",Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Material=Enum.Material.Neon,Color=hitTarget and Color3.fromRGB(255,105,170) or Color3.fromRGB(94,184,255),Size=Vector3.new(.055,.055,delta.Magnitude),CFrame=CFrame.lookAt((shot.Origin+finish)*.5,finish),Transparency=.05})
    activeTracers[#activeTracers+1]=part
    Tween:Create(part,TweenInfo.new(.35,Enum.EasingStyle.Quad),{Transparency=1}):Play()
    Debris:AddItem(part,.4)
end
local function redirectShot(self,shot,target)
    if not shot or not shot.Origin or not target or not target.Character or not target.Character:FindFirstChild("Head") then return shot,false end
    local head=target.Character.Head
    local dir=(head.Position-shot.Origin)
    if dir.Magnitude<.01 then return shot,false end
    local range=self.Properties and self.Properties.Range or 500
    if dir.Magnitude>range then return shot,false end
    local hit=workspace:Raycast(shot.Origin,dir.Unit*(dir.Magnitude+3),rayParams())
    if not state.wallbang and (not hit or not hit.Instance:IsDescendantOf(target.Character)) then return shot,false end
    shot.Direction=dir.Unit
    shot.Distance=state.wallbang and dir.Magnitude or hit.Distance
    shot.Hits={{Position=state.wallbang and head.Position or hit.Position,Instance=state.wallbang and head or hit.Instance,Material=state.wallbang and head.Material.Name or hit.Material.Name,Normal=state.wallbang and -dir.Unit or hit.Normal,Exit=false}}
    return shot,true
end
Bullet._performRaycast=function(self,spread)
    local shot=oldRay(self,state.noSpread and 0 or spread)
    if not (state.silent or state.wallbang) then drawTracer(shot,false); return shot end
    local changed,hit=redirectShot(self,shot,closest())
    drawTracer(changed,hit)
    return changed
end
local function removeHighlight(p)
    local item=adornments[p]
    if item then
        for k,v in pairs(item) do if k~="character" and typeof(v)=="Instance" then v:Destroy() end end
        adornments[p]=nil
    end
end
local espCanvas=new("Frame",gui,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Active=false,ZIndex=3})
local function createEsp(p,c)
    local box=new("Frame",espCanvas,{BackgroundTransparency=1,BorderSizePixel=0,ZIndex=3})
    local function corner(position,size)
        local edge=new("Frame",box,{Position=position,Size=size,BackgroundColor3=Color3.fromRGB(238,245,255),BorderSizePixel=0,ZIndex=4})
        new("UIStroke",edge,{Color=Color3.fromRGB(4,8,14),Thickness=1.2,Transparency=.1})
    end
    corner(UDim2.fromScale(0,0),UDim2.new(.27,0,0,2));corner(UDim2.fromScale(0,0),UDim2.new(0,2,.23,0))
    corner(UDim2.new(.73,0,0,0),UDim2.new(.27,0,0,2));corner(UDim2.new(1,-2,0,0),UDim2.new(0,2,.23,0))
    corner(UDim2.new(0,0,1,-2),UDim2.new(.27,0,0,2));corner(UDim2.new(0,0,.77,0),UDim2.new(0,2,.23,0))
    corner(UDim2.new(.73,0,1,-2),UDim2.new(.27,0,0,2));corner(UDim2.new(1,-2,.77,0),UDim2.new(0,2,.23,0))
    local label=new("TextLabel",espCanvas,{BackgroundColor3=Color3.fromRGB(10,14,21),BackgroundTransparency=.23,TextColor3=Color3.fromRGB(241,246,255),TextStrokeTransparency=.55,Font=Enum.Font.GothamBold,TextSize=11,Text=p.DisplayName,ZIndex=4})
    new("UICorner",label,{CornerRadius=UDim.new(0,4)})
    local bar=new("Frame",espCanvas,{BackgroundColor3=Color3.fromRGB(8,12,18),BorderSizePixel=0,ZIndex=3})
    new("UIStroke",bar,{Color=Color3.fromRGB(3,5,8),Thickness=1})
    local fill=new("Frame",bar,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(75,220,145),BorderSizePixel=0,ZIndex=3})
    local mark=new("Highlight",gui,{Adornee=c,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,FillColor=Color3.fromHSV(state.chamHue/360,.85,1),OutlineTransparency=1,FillTransparency=state.chamTransparency/100,Enabled=state.playerChams})
    adornments[p]={character=c,box=box,label=label,bar=bar,mark=mark,fill=fill}
end
local function updateEsp()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP then
            local c=p.Character
            local should=(state.esp or state.playerChams) and enemy(p) and alive(p)
            if should then
                if not adornments[p] or adornments[p].character~=c then removeHighlight(p); createEsp(p,c) end
                local item=adornments[p]
                local cf,size=c:GetBoundingBox()
                local loX,loY,hiX,hiY=math.huge,math.huge,-math.huge,-math.huge
                local seen=0
                for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
                    local world=cf:PointToWorldSpace(Vector3.new(size.X*x*.5,size.Y*y*.5,size.Z*z*.5))
                    local v=Cam:WorldToViewportPoint(world)
                    if v.Z>0 then loX=math.min(loX,v.X);loY=math.min(loY,v.Y);hiX=math.max(hiX,v.X);hiY=math.max(hiY,v.Y);seen=seen+1 end
                end end end
                local visible=seen==8 and hiX>=0 and loX<=Cam.ViewportSize.X and hiY>=0 and loY<=Cam.ViewportSize.Y
                item.box.Visible=state.esp and visible;item.label.Visible=state.esp and visible;item.bar.Visible=state.esp and visible
                item.mark.Enabled=state.playerChams
                item.mark.FillColor=Color3.fromHSV(state.chamHue/360,.85,1)
                item.mark.FillTransparency=state.chamTransparency/100
                item.mark.OutlineTransparency=1
                if visible then
                    local width=math.clamp(hiX-loX,16,500)
                    local height=math.clamp(hiY-loY,25,600)
                    item.box.Position=UDim2.fromOffset(loX,loY);item.box.Size=UDim2.fromOffset(width,height)
                    item.label.Position=UDim2.fromOffset(loX-8,loY-20);item.label.Size=UDim2.fromOffset(width+16,18)
                    local distance=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and math.floor((LP.Character.HumanoidRootPart.Position-cf.Position).Magnitude) or 0
                    item.label.Text=p.DisplayName.."  ["..distance.."m]"
                    item.bar.Position=UDim2.fromOffset(loX-6,loY);item.bar.Size=UDim2.fromOffset(3,height)
                    local hp=c:GetAttribute("Health") or 100;local maxhp=c:GetAttribute("MaxHealth") or 100
                    local ratio=math.clamp(hp/math.max(maxhp,1),0,1)
                    item.fill.Size=UDim2.fromScale(1,ratio)
                    item.fill.Position=UDim2.fromScale(0,1-ratio)
                    item.fill.BackgroundColor3=Color3.fromRGB(math.floor(255*(1-ratio)),math.floor(220*ratio),90)
                end
            else removeHighlight(p) end
        end
    end
end
table.insert(connections,Players.PlayerRemoving:Connect(removeHighlight))
local motors,lastCharacter={},nil
local airborneNow,lastGroundSample,spinPhase=false,0,0
local function restorePose()
    for _,entry in pairs(motors) do if entry.joint and entry.joint.Parent then entry.joint.C0=entry.base end end
    motors={}
end
local function findMotor(char,name)
    for _,v in ipairs(char:GetDescendants()) do if v:IsA("Motor6D") and v.Name==name then return v end end
end
local function antiAngles()
    local flip=state.jitter and (math.floor(os.clock()*state.jitterSpeed)%2==0 and 1 or -1) or 0
    local yaw=state.yaw and state.yawAngle+flip*state.jitterRange or 0
    local pitch=state.pitch and math.clamp(state.pitchAngle+flip*state.jitterRange*.5,-85,85) or 0
    return yaw,pitch
end
local function updatePose(dt)
    local char=LP.Character
    if char~=lastCharacter then
        restorePose(); lastCharacter=char
        if char then
            for _,name in ipairs({"Root","Waist","LeftShoulder","RightShoulder","Neck","Head"}) do
                local joint=findMotor(char,name)
                if joint then motors[name]={joint=joint,base=joint.C0} end
            end
        end
    end
    local yawDeg,pitchDeg=antiAngles()
    local airborne=airborneNow
    if os.clock()-lastGroundSample>.25 then
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        airborne=hum and hum.FloorMaterial==Enum.Material.Air or false
    end
    if state.jumpSpin and airborne then spinPhase=(spinPhase+math.rad(state.jumpSpinSpeed)*dt)%(math.pi*2) end
    local yaw=math.rad(yawDeg)+(state.jumpSpin and airborne and spinPhase or 0)
    local pitch=math.rad(pitchDeg)
    local angles={Root=CFrame.Angles(0,yaw,0),Waist=CFrame.Angles(pitch*.65,0,0),LeftShoulder=CFrame.Angles(pitch*.5,0,0),RightShoulder=CFrame.Angles(pitch*.5,0,0),Neck=CFrame.Angles(pitch*.35,0,0),Head=CFrame.Angles(pitch*.35,0,0)}
    for name,entry in pairs(motors) do
        if entry.joint.Parent then entry.joint.C0=entry.base*angles[name] end
    end
end
local baseYawFrames=setmetatable({}, {__mode="k"})
CharacterClass.PrepareInputFrame=function(self,...)
    local result=oldPrepareInputFrame(self,...)
    if self.Player==LP then
        local previous=baseYawFrames[self]
        local cameraYaw=self.CurrentFrameLookYaw
        baseYawFrames[self]={previous=previous and previous.current or cameraYaw,current=cameraYaw}
        local yaw,pitch=antiAngles()
        if state.yaw then self.CurrentFrameLookYaw=self.CurrentFrameLookYaw+math.rad(yaw) end
        -- Ladder movement uses VerticalLook; keep the camera value while climbing.
        if state.pitch and not self.IsClimbing then self.CurrentFrameVerticalLook=math.sin(math.rad(pitch)) end
    end
    return result
end
local spaceHeld=UIS:IsKeyDown(Enum.KeyCode.Space)
local mouseDelta=0
local movementActor,strafeSide,wasAirborne=nil,1,false
local movementStats={samples=0,bhopPulses=0,airOverrides=0,moveCorrections=0,lastButtons=0,lastMove=Vector2.zero,lastAirProjection=0,lastAirCap=0,lastHeadingError=0}
table.insert(connections,UIS.InputBegan:Connect(function(input)
    if input.KeyCode==Enum.KeyCode.Space then spaceHeld=true end
end))
table.insert(connections,UIS.InputEnded:Connect(function(input)
    if input.KeyCode==Enum.KeyCode.Space then spaceHeld=false end
end))
table.insert(connections,UIS.InputChanged:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseMovement then mouseDelta=input.Delta.X end
end))
local function movementStep(actor,sample,jumpHeld,deltaX,controlMove,cameraYaw)
    if not sample then return nil end
    if movementActor~=actor then movementActor=actor; strafeSide=1; wasAirborne=false end
    local ground=actor.OnGround
    if type(ground)~="boolean" then ground=actor.MovementState and actor.MovementState.OnGround end
    airborneNow=ground==false; lastGroundSample=os.clock()
    if ground then wasAirborne=false end
    if state.bhop and jumpHeld then
        sample.Buttons=MoveButtons.with(sample.Buttons,MoveButtons.Jump,ground==true)
        if ground then movementStats.bhopPulses=movementStats.bhopPulses+1 end
    end
    if state.strafe and not ground then
        local controls=controlMove or sample.Move
        local desired=CFrame.Angles(0,cameraYaw or sample.LookYaw,0):VectorToWorldSpace(Vector3.new(controls.X,0,controls.Y))
        if desired.Magnitude<.05 then
            local look=Cam.CFrame.LookVector
            desired=Vector3.new(look.X,0,look.Z)
        end
        if desired.Magnitude<.05 then desired=Vector3.new(0,0,-1) end
        desired=desired.Unit
        wasAirborne=true
        local source=(actor.MovementState and actor.MovementState.Velocity) or actor.GlobalVelocity or Vector3.zero
        local velocity=Vector3.new(source.X,0,source.Z)
        local config=MovementSettings.getMovementConfig()
        local airCap=math.max(.1,config.AirSpeedCap or 2.25)
        if velocity.Magnitude>.1 then
            local headingDot=math.clamp(velocity.Unit:Dot(desired),-1,1)
            movementStats.lastHeadingError=math.deg(math.acos(headingDot))
            -- Follow the requested heading. Only use a capped tangent when it
            -- is needed to turn; aligned movement must never orbit the player.
            if movementStats.lastHeadingError>8 and velocity:Dot(desired)>airCap*.5*(1-math.clamp(state.strafeStrength/100,0,1)) then
                local projectionTarget=airCap*.5*(1-math.clamp(state.strafeStrength/100,0,1))
                local angle=math.acos(math.clamp(projectionTarget/velocity.Magnitude,0,1))
                local left=CFrame.Angles(0,angle,0):VectorToWorldSpace(velocity.Unit)
                local right=CFrame.Angles(0,-angle,0):VectorToWorldSpace(velocity.Unit)
                if math.abs(left:Dot(desired)-right:Dot(desired))<1e-4 then
                    if deltaX>.1 then strafeSide=1 elseif deltaX<-.1 then strafeSide=-1 end
                else
                    strafeSide=left:Dot(desired)>right:Dot(desired) and 1 or -1
                end
                desired=strafeSide==1 and left or right
            end
        else
            movementStats.lastHeadingError=0
        end
        movementStats.lastAirProjection=velocity:Dot(desired)
        movementStats.lastAirCap=airCap
        local relative=CFrame.Angles(0,sample.LookYaw,0):VectorToObjectSpace(desired)
        sample.Move=Vector2.new(relative.X,relative.Z)
        movementStats.airOverrides=movementStats.airOverrides+1
    end
    movementStats.samples=movementStats.samples+1
    movementStats.lastButtons=sample.Buttons
    movementStats.lastMove=sample.Move
    return sample
end
CharacterClass.SampleInput=function(self,context)
    local jumpHeld=spaceHeld or UIS:IsKeyDown(Enum.KeyCode.Space) or self.JumpInputDown==true
    if self.Player==LP and state.bhop and jumpHeld and (self.OnGround==true or self.MovementState and self.MovementState.OnGround==true) then
        self.JumpPulsePending=true
    end
    local sample=oldSampleInput(self,context)
    if self.Player==LP and sample then
        local controlMove=sample.Move
        local frame=baseYawFrames[self]
        local look=Cam.CFrame.LookVector
        local baseYaw=math.atan2(-look.X,-look.Z)
        if frame then
            local alpha=math.clamp(context.FrameSampleAlpha or 1,0,1)
            local diff=frame.current-frame.previous
            baseYaw=frame.previous+math.atan2(math.sin(diff),math.cos(diff))*alpha
            local delta=math.atan2(math.sin(sample.LookYaw-baseYaw),math.cos(sample.LookYaw-baseYaw))
            if math.abs(delta)>1e-5 then
                local world=CFrame.Angles(0,baseYaw,0):VectorToWorldSpace(Vector3.new(sample.Move.X,0,sample.Move.Y))
                local localMove=CFrame.Angles(0,sample.LookYaw,0):VectorToObjectSpace(world)
                sample.Move=Vector2.new(localMove.X,localMove.Z)
                movementStats.moveCorrections=movementStats.moveCorrections+1
            end
        end
        local delta=UIS:GetMouseDelta().X
        return movementStep(self,sample,jumpHeld,math.abs(delta)>.1 and delta or mouseDelta,controlMove,baseYaw)
    end
    return sample
end
local hatParts,worldParticles={},{}
local function neonPart(name,size,color)
    return new("Part",Cam,{Name=name,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Material=Enum.Material.Neon,Color=color,Size=size,Transparency=.12})
end
local function linePart(part,a,b,width)
    local delta=b-a
    part.Size=Vector3.new(width,width,delta.Magnitude)
    part.CFrame=CFrame.lookAt((a+b)*.5,b)
end
local function clearParts(parts)
    for _,part in ipairs(parts) do if part.Parent then part:Destroy() end end
    table.clear(parts)
end
local function updateChinaHat(headOverride)
    local head=headOverride or (LP.Character and LP.Character:FindFirstChild("Head"))
    if not state.chinaHat or not head then clearParts(hatParts);return end
    if #hatParts==0 then
        for i=1,12 do
            hatParts[#hatParts+1]=neonPart("RainChinaHatSpoke",Vector3.new(.05,.05,1),Color3.fromRGB(90,183,255))
            hatParts[#hatParts+1]=neonPart("RainChinaHatRim",Vector3.new(.065,.065,1),Color3.fromRGB(204,237,255))
        end
    end
    local center=head.Position+Vector3.new(0,head.Size.Y*.55+.18,0)
    local apex=center+Vector3.new(0,.42,0)
    for i=1,12 do
        local a=(i-1)*math.pi/6
        local b=i*math.pi/6
        local rimA=center+Vector3.new(math.cos(a)*1.02,0,math.sin(a)*1.02)
        local rimB=center+Vector3.new(math.cos(b)*1.02,0,math.sin(b)*1.02)
        linePart(hatParts[i*2-1],apex,rimA,.052)
        linePart(hatParts[i*2],rimA,rimB,.065)
    end
end
local function updateWorldParticles()
    if not state.worldParticles then clearParts(worldParticles);return end
    local count=math.clamp(state.particleCount,8,60)
    while #worldParticles>count do local part=table.remove(worldParticles);part:Destroy() end
    while #worldParticles<count do
        local part=neonPart("RainWorldParticle",Vector3.new(.22,.22,.22),Color3.fromRGB(111,189,255))
        part.Shape=Enum.PartType.Ball
        worldParticles[#worldParticles+1]=part
    end
    local center=Cam.CFrame.Position
    local t=os.clock()*state.particleSpeed*.18
    for i,part in ipairs(worldParticles) do
        local phase=i*2.399963+t*(i%2==0 and 1 or -.7)
        local radius=9+(i%9)*2.2
        local height=((i*13)%19)-9+math.sin(t+i)*1.4
        part.Position=center+Vector3.new(math.cos(phase)*radius,height,math.sin(phase)*radius)
        local size=.13+(i%4)*.055
        part.Size=Vector3.new(size,size,size)
        part.Transparency=.12+(i%4)*.13
    end
end
local perspectiveApplied=false
table.insert(connections,Run.RenderStepped:Connect(function(dt)
    updatePose(dt)
    updateChinaHat()
    updateWorldParticles()
    updateEsp()
    fovRing.Visible=state.silent
    fovDot.Visible=state.silent
    local half=math.rad(state.aimAngle*.5)
    local radius=half>=math.rad(89) and Cam.ViewportSize.Magnitude*.48 or (math.tan(half)/math.tan(math.rad(Cam.FieldOfView*.5)))*Cam.ViewportSize.Y*.5
    radius=math.clamp(radius,12,Cam.ViewportSize.Magnitude*.48)
    fovRing.Size=UDim2.fromOffset(radius*2,radius*2)
    fovText.Text="FOV "..state.aimAngle.."°"
    if state.third then
        if not perspectiveApplied or LP.CameraMode~=Enum.CameraMode.Classic or LP.CameraMinZoomDistance~=state.zoom then
            pcall(function() oldPerspective(false,menuOpen,state.zoom) end)
            perspectiveApplied=true
        end
        local desired=menuOpen and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
        if UIS.MouseBehavior~=desired then pcall(function() CameraController.setMouseEnabled(menuOpen) end) end
    elseif perspectiveApplied then
        pcall(function() CameraController.setPerspective(true,false) end); perspectiveApplied=false
    end
    if menuOpen and UIS.MouseBehavior~=Enum.MouseBehavior.Default then
        pcall(function() CameraController.setMouseEnabled(true) end)
    end
    if menuOpen then
        UIS.MouseBehavior=Enum.MouseBehavior.Default
        UIS.MouseIconEnabled=true
    elseif state.third then
        UIS.MouseBehavior=Enum.MouseBehavior.LockCenter
        UIS.MouseIconEnabled=false
    end
end))
local lastSkinCheck=0
local wasNoRecoil=false
table.insert(connections,Run.Heartbeat:Connect(function()
    if state.noRecoil and not wasNoRecoil then CameraController.resetWeaponRecoil() end
    wasNoRecoil=state.noRecoil
    if state.rapid or state.autoFire then
        local target=state.autoFire and closest()~=nil or false
        fireStep(UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1),target)
    end
    if os.clock()-lastSkinCheck>.25 then
        lastSkinCheck=os.clock()
        local ok,message=applySelectedSkin()
        if ok and message~="already applied" then statusLabel.Text="Local skin: "..state.weapon.." / "..state.skin end
        updateAvatarModel()
    end
    updateMaterialChams()
    if state.worldAmbient then
        local hue=state.ambientHue/360
        local strength=state.ambientStrength/100
        Lighting.Ambient=Color3.fromHSV(hue,.35+strength*.35,.16+strength*.46)
        Lighting.OutdoorAmbient=Color3.fromHSV(hue,.25+strength*.25,.30+strength*.5)
        Lighting.FogColor=Color3.fromHSV(hue,.25+strength*.35,.35+strength*.3)
        Lighting.FogEnd=state.fogDistance
        Lighting.Brightness=1+strength*2
    elseif state.glow then Lighting.Ambient=Color3.fromRGB(42,55,85); Lighting.OutdoorAmbient=Color3.fromRGB(65,79,114); Lighting.FogEnd=750
    else for k,v in pairs(oldLighting) do Lighting[k]=v end end
end))
local dragging,start,origin=false,nil,nil
table.insert(connections,top.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;start=i.Position;origin=main.Position end end))
table.insert(connections,UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-start; main.Position=UDim2.new(origin.X.Scale,origin.X.Offset+d.X,origin.Y.Scale,origin.Y.Offset+d.Y) end end))
table.insert(connections,UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end))
local function setMenu(open)
    menuOpen=open==true
    main.Visible=menuOpen
    pcall(function() CameraController.setMouseEnabled(menuOpen) end)
    if menuOpen then UIS.MouseBehavior=Enum.MouseBehavior.Default;UIS.MouseIconEnabled=true end
end
local renderBinding="RainSuiteCursorFov"
local wasMainFov=false
Run:BindToRenderStep(renderBinding,Enum.RenderPriority.Last.Value+100,function()
    local avatarRecord=avatarOverlays[LP.Character]
    if avatarRecord and state.modelChoice~="Off" then enforceAvatarHidden(avatarRecord) end
    if state.mainFovEnabled then workspace.CurrentCamera.FieldOfView=state.mainFov
    elseif wasMainFov then workspace.CurrentCamera.FieldOfView=oldCameraFov end
    wasMainFov=state.mainFovEnabled
    if menuOpen then
        UIS.MouseBehavior=Enum.MouseBehavior.Default
        UIS.MouseIconEnabled=true
    end
    updateScopeCrosshair()
end)
table.insert(connections,UIS.InputBegan:Connect(function(i,gp) if not gp and i.KeyCode==Enum.KeyCode.RightShift then setMenu(not menuOpen) end end))
local suite={state=state,menu=main,pages=pages,selectPage=selectPage,sliderControls=sliderControls,setMenu=setMenu,setSpaceHeld=function(value) spaceHeld=value==true end,updateScopeCrosshair=updateScopeCrosshair,scopeCrosshair=scopeCross,restoreScopeOverlay=restoreScopeOverlay,applySkin=applySelectedSkin,restoreNativeSkins=restoreNativeSkins,applyAvatarModel=applyAvatarModel,updateAvatarModel=updateAvatarModel,removeAvatarModel=removeAvatarModel,applyHandFov=applyHandFov,updateMaterialChams=updateMaterialChams,restoreAllChams=restoreAllChams,drawTracer=drawTracer,redirectShot=redirectShot,updateChinaHat=updateChinaHat,updateWorldParticles=updateWorldParticles,updatePose=updatePose,getSpinPhase=function() return spinPhase end,movementStep=movementStep,movementStats=movementStats,fireStep=fireStep,antiAngles=antiAngles,closest=closest}
function suite.stop()
    Run:UnbindFromRenderStep(renderBinding)
    Bullet._performRaycast=oldRay
    Bullet.getTrueSpread=oldGetTrueSpread
    ViewmodelClass.render=oldViewmodelRender
    ViewmodelClass.new=oldViewmodelNew
    WeaponComponentClass.new=oldComponentNew
    CameraController.setPerspective=oldPerspective
    CameraController.weaponKick=oldWeaponKick
    CameraController.setWeaponRecoil=oldSetWeaponRecoil
    CharacterClass.SampleInput=oldSampleInput
    CharacterClass.PrepareInputFrame=oldPrepareInputFrame
    for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    restoreScopeOverlay()
    for p in pairs(adornments) do removeHighlight(p) end
    for _,part in ipairs(activeTracers) do if part.Parent then part:Destroy() end end
    clearParts(hatParts)
    clearParts(worldParticles)
    for model in pairs(avatarOverlays) do removeAvatarModel(model) end
    restoreAllChams()
    restoreNativeSkins()
    restorePose()
    for k,v in pairs(oldLighting) do Lighting[k]=v end
    if perspectiveApplied then pcall(function() CameraController.setPerspective(true,false) end) end
    pcall(function() workspace.CurrentCamera.FieldOfView=oldCameraFov end)
    pcall(function() UIS.MouseBehavior=oldMouseBehavior; UIS.MouseIconEnabled=oldMouseIcon end)
    pcall(function() gui:Destroy() end)
    if G.RainPlaceSuite==suite then G.RainPlaceSuite=nil end
    print("[RAIN] stopped")
end
G.RainPlaceSuite=suite
print("[RAIN] loaded",game.PlaceId,"PID client",LP.Name,"menu",gui.Parent and gui.Parent.Name,"bullet hook",Bullet._performRaycast~=oldRay)
