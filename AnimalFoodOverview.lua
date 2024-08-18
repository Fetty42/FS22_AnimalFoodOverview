-- Author: Fetty42
-- Date: 29.03.2024
-- Version: 1.1.2.0

local dbPrintfOn = false
local dbInfoPrintfOn = true

local function dbInfoPrintf(...)
	if dbInfoPrintfOn then
    	print(string.format(...))
	end
end

local function dbPrintf(...)
	if dbPrintfOn then
    	print(string.format(...))
	end
end

local function dbPrintHeader(ftName)
	if dbPrintfOn then
    	print(string.format("Call %s: g_currentMission:getIsServer()=%s | g_currentMission:getIsClient()=%s", ftName, g_currentMission:getIsServer(), g_currentMission:getIsClient()))
	end
end



AnimalFoodOverview = {}; -- Class

-- global variables
AnimalFoodOverview.dir = g_currentModDirectory
AnimalFoodOverview.modName = g_currentModName

AnimalFoodOverview.dlg			= nil

source(AnimalFoodOverview.dir .. "gui/DlgFrame.lua")

function AnimalFoodOverview:loadMap(name)
    dbPrintHeader("AnimalFoodOverview:loadMap()")

	if g_currentMission:getIsClient() then
		Player.registerActionEvents = Utils.appendedFunction(Player.registerActionEvents, AnimalFoodOverview.registerActionEvents);
		Enterable.onRegisterActionEvents = Utils.appendedFunction(Enterable.onRegisterActionEvents, AnimalFoodOverview.registerActionEvents);
		-- VIPOrderManager.eventName = {};

		-- g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
		-- g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, self.onMinuteChanged, self)
	end
end



function AnimalFoodOverview:registerActionEvents()
    -- dbPrintHeader("AnimalFoodOverview:registerActionEvents()")

	if g_currentMission:getIsClient() then --isOwner
		local result2, actionEventId2 = g_inputBinding:registerActionEvent('ShowAnimalFoodDlg',InputBinding.NO_EVENT_TARGET, AnimalFoodOverview.ShowAnimalFoodDlg ,false ,true ,false ,true)
		dbPrintf("Result2=%s | actionEventId2=%s | g_currentMission:getIsClient()=%s", result2, actionEventId2, g_currentMission:getIsClient())
		if result2 and actionEventId2 then
			g_inputBinding:setActionEventTextVisibility(actionEventId2, true)
			g_inputBinding:setActionEventActive(actionEventId2, true)
			g_inputBinding:setActionEventTextPriority(actionEventId2, GS_PRIO_VERY_LOW) -- GS_PRIO_VERY_HIGH, GS_PRIO_HIGH, GS_PRIO_LOW, GS_PRIO_VERY_LOW

			dbPrintf("Action event inserted successfully")
		end
	end
end


--
function AnimalFoodOverview:ShowAnimalFoodDlg(actionName, keyStatus, arg3, arg4, arg5)
    dbPrintHeader("AnimalFoodOverview:ShowAnimalFoodDlg()")

	AnimalFoodOverview.dlg = nil
	g_gui:loadProfiles(AnimalFoodOverview.dir .. "gui/guiProfiles.xml")
	local dlgFrame = DlgFrame.new(g_i18n)
	g_gui:loadGui(AnimalFoodOverview.dir .. "gui/DlgFrame.xml", "DlgFrame", dlgFrame)
	AnimalFoodOverview.dlg = g_gui:showDialog("DlgFrame")

	-- print("")
	-- print("** Start DebugUtil.printTableRecursively() ************************************************************")
	-- printf("==> %s", "g_currentMission.animalFoodSystem.animalMixtures")
	-- DebugUtil.printTableRecursively(g_currentMission.animalFoodSystem.animalMixtures, ".", 0, 4)
	-- print("** End DebugUtil.printTableRecursively() **************************************************************")
end



function AnimalFoodOverview:onListSelectionChanged(husbandry, cluster)
	
	for _, cluster in pairs(self.selectedHusbandry:getClusters()) do
		local subTypeIdx = cluster.subTypeIndex
		local subType = g_currentMission.animalSystem.subTypes[subTypeIdx]
		local food = subType.input["food"]
	end

--	for _, animalFood in pairs(g_currentMission.animalFoodSystem.animalFood) do
--		local animalType = g_currentMission.animalSystem:getTypeByIndex(animalFood.animalTypeIndex)
--	end

    local animalTypeIndex = self.selectedHusbandry:getAnimalTypeIndex()
	local foodGroupsData = {}
	DlgFrame:getFoodGroupsDataForAnimalTypeIndex(animalTypeIndex, foodGroupsData, nil, nil)

	local firstRun = (self.foodGroupElements == nil)
	if firstRun then
		self.foodGroupElements = {}
		for i=1,5 do
			local element = self.foodHeader:clone()
			element.textAutoWidth = false
			element.defaultTextSize = 0.009
			element.textLayoutMode = TextElement.LAYOUT_MODE.RESIZE
			-- element.textMaxNumLines = 2
			self.foodGroupElements[i] = element
			self.requirementsLayout:addElement(element)
		end
    end
	
	if self.foodGroupElements ~= nil then
		for i=1,5 do
            local text = ""
            if i <= #foodGroupsData then
                text = string.format("%s: %s", foodGroupsData[i].groupTitle, foodGroupsData[i].foodTypesLine)
            end
            self.foodGroupElements[i]:setText(text)
        end
        self.requirementsLayout:invalidateLayout()
	end
end

InGameMenuAnimalsFrame.onListSelectionChanged = Utils.appendedFunction(InGameMenuAnimalsFrame.onListSelectionChanged, AnimalFoodOverview.onListSelectionChanged)


function AnimalFoodOverview:onLoad(savegame)end;
function AnimalFoodOverview:onUpdate(dt)end;
function AnimalFoodOverview:deleteMap()end;
function AnimalFoodOverview:keyEvent(unicode, sym, modifier, isDown)end;
function AnimalFoodOverview:mouseEvent(posX, posY, isDown, isUp, button)end;

addModEventListener(AnimalFoodOverview);