-- Author: Fetty42
-- Date: 08.05.2022
-- Version: 1.1.0.0


local dbPrintfOn = false

local function dbPrintf(...)
	if dbPrintfOn then
    	print(string.format(...))
	end
end



-- DlgFrame = {
-- 	CONTROLS = {
-- 		DIALOG_TITLE = "dialogTitleElement",
--         TABLE = "overviewTable",
--         TABLE_TEMPLATE = "orderRowTemplate",
-- 	}
-- }

DlgFrame = {
	CONTROLS = {
		"dialogTitleElement",
        "overviewTable",
        "orderRowTemplate",
		"overviewTableDetail",
		"detailHeader"
	}
}

local DlgFrame_mt = Class(DlgFrame, MessageDialog)

function DlgFrame.new(target, custom_mt)
	dbPrintf("DlgFrame:new()")
	local self = MessageDialog.new(target, custom_mt or DlgFrame_mt)

	self:registerControls(DlgFrame.CONTROLS)

	return self
end

function DlgFrame:onGuiSetupFinished()
	dbPrintf("DlgFrame:onGuiSetupFinished()")
	DlgFrame:superClass().onGuiSetupFinished(self)
	self.overviewTable:setDataSource(self)
	self.overviewTable:setDelegate(self)

	self.overviewTableDetail:setDataSource(self)
	self.overviewTableDetail:setDelegate(self)

end

function DlgFrame:onCreate()
	dbPrintf("DlgFrame:onCreate()")
	DlgFrame:superClass().onCreate(self)    
end


function DlgFrame:onOpen()
	dbPrintf("DlgFrame:onOpen()")
	DlgFrame:superClass().onOpen(self)

	-- Fill data structure
	self.overviewTableData = {}
	
	--[[g_currentMission.animalFoodSystem.animalFood{}
		- consumptionType --> 1 = sequential 2=parallel
		- animalTypeIndex --> 1-5 (AnimalType.HORSE,PIG,COW,SHEEP,CHICKEN)
		- groups{}
			- title
			- productionWeight
			- eatWeight
			- fillTypes{}
	]]
	local animalNames = {}
	animalNames[AnimalType.HORSE]=g_i18n:getText("txt_horse")
	animalNames[AnimalType.PIG]=g_i18n:getText("txt_pig")
	animalNames[AnimalType.COW]=g_i18n:getText("txt_cow")
	animalNames[AnimalType.SHEEP]=g_i18n:getText("txt_sheep")
	animalNames[AnimalType.CHICKEN]=g_i18n:getText("txt_chicken")

	for _, animalFood in pairs(g_currentMission.animalFoodSystem.animalFood) do
		
		local animalName = animalNames[animalFood.animalTypeIndex]
		local sectionText = string.format("%s (%s)", animalName, (animalFood.consumptionType == 1) and g_i18n:getText("txt_sequentiel") or g_i18n:getText("txt_Parallel"))
		local section = {animalName = animalName, sectionTitle = sectionText, items = {}}

		for _, foodGroup in pairs(animalFood.groups) do
			local item = {groupTitle=foodGroup.title, productionWeight=string.format("%.2f", foodGroup.productionWeight), eatWeight=string.format("%.2f", foodGroup.eatWeight), foodTypes="", fillTypes={}}
			local foodTypes = ""

			for _, ftIndex in pairs(foodGroup.fillTypes) do
				local fillType = g_fillTypeManager:getFillTypeByIndex(ftIndex)
				if string.sub(fillType.name, 1, -2) ~= "SLIDER0" then
					local fillTypeTitle = fillType.title
					table.insert(item.fillTypes, fillType)	
					foodTypes = foodTypes .. (foodTypes == "" and "" or ", ") .. fillTypeTitle
				end
			end
			item.foodTypes = foodTypes
			table.insert(section.items, item)
		end
		table.insert(self.overviewTableData, section)
	end
	
	-- finilaze dialog 
	self.overviewTable:reloadData()    
	self.overviewTableDetail:reloadData()    

	self:setSoundSuppressed(true)
    FocusManager:setFocus(self.overviewTable)
    self:setSoundSuppressed(false)

end


function DlgFrame:getNumberOfSections(list)
	dbPrintf("DlgFrame:getNumberOfSections()")
	if list == self.overviewTable then
		return #self.overviewTableData
	else
		return 1
	end
end


function DlgFrame:getNumberOfItemsInSection(list, section)
	dbPrintf("DlgFrame:getNumberOfItemsInSection()")
	if list == self.overviewTable then
		return #self.overviewTableData[section].items
	else
		local selectedSectionIndex = self.overviewTable.selectedSectionIndex
		local selectedIndex = self.overviewTable.selectedIndex

		foodGroupEntry = self.overviewTableData[selectedSectionIndex].items[selectedIndex]    
		local detailHeaderTxt = string.format("%s - %s", self.overviewTableData[selectedSectionIndex].animalName, foodGroupEntry.groupTitle )
		return #foodGroupEntry.fillTypes
	end
end


function DlgFrame:getTitleForSectionHeader(list, section)
	dbPrintf("DlgFrame:getTitleForSectionHeader()")
	if list == self.overviewTable then
		return self.overviewTableData[section].sectionTitle
	else
		return nil
	end
end


function DlgFrame:populateCellForItemInSection(list, section, index, cell)
	dbPrintf("DlgFrame:populateCellForItemInSection()")
	if list == self.overviewTable then
		local foodGroupEntry = self.overviewTableData[section].items[index]    
		cell:getAttribute("FoodGroup"):setText(foodGroupEntry.groupTitle)
		cell:getAttribute("ProductionWeight"):setText(foodGroupEntry.productionWeight)
		cell:getAttribute("EatWeight"):setText(foodGroupEntry.eatWeight)
		cell:getAttribute("FoodTypes"):setText(foodGroupEntry.foodTypes)
	else
		local selectedSectionIndex = self.overviewTable.selectedSectionIndex
		local selectedIndex = self.overviewTable.selectedIndex

		foodGroupEntry = self.overviewTableData[selectedSectionIndex].items[selectedIndex]    
		local detailHeaderTxt = string.format("%s - %s", self.overviewTableData[selectedSectionIndex].animalName, foodGroupEntry.groupTitle )
		
		self.detailHeader:setText(detailHeaderTxt)
		cell:getAttribute("fillTypeIcon"):setImageFilename(foodGroupEntry.fillTypes[index].hudOverlayFilename)
		cell:getAttribute("FoodType"):setText(foodGroupEntry.fillTypes[index].title)

	end
end


function DlgFrame:onListSelectionChanged(list, section, index)
	dbPrintf("DlgFrame:onListSelectionChanged()")
    if list == self.overviewTable then
        self.overviewTableDetail:reloadData()
	end
end


function DlgFrame:onClose()
	dbPrintf("DlgFrame:onClose()")
	DlgFrame:superClass().onClose(self)
end


function DlgFrame:onClickBack(sender)
	dbPrintf("DlgFrame:onClickBack()")
	self:close()
end

