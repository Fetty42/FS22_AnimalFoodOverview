-- Author: Fetty42
-- Date: 12.02.2023
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


DlgFrame.mixDlg	= nil
source(AnimalFoodOverview.dir .. "gui/MixDlgFrame.lua")


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
	self.mixFillTypeIdxToAnimalTitle = {}
	
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
		
		-- fix for other animals to not show nil in the dialog. Use either the filltype name which belongs to it or the type name itself
		if animalName == nil then
			local animalType = g_currentMission.animalSystem:getTypeByIndex(animalFood.animalTypeIndex)
			
			if animalType.name ~= nil then
				local fillType = g_fillTypeManager:getFillTypeByName(animalType.name)
				if fillType ~= nil then
					animalNames[animalFood.animalTypeIndex] = fillType.title
				else
					animalNames[animalFood.animalTypeIndex] = animalType.name
				end
				animalName = animalNames[animalFood.animalTypeIndex];
			end
		end
		
		local sectionText = string.format("%s (%s)", animalName, (animalFood.consumptionType == 1) and g_i18n:getText("txt_sequentiel") or g_i18n:getText("txt_Parallel"))
		local section = {animalName = animalName, sectionTitle = sectionText, items = {}}

		-- Collect allowed filltypes for each food group
		for _, foodGroup in pairs(animalFood.groups) do
			local item = {groupTitle=foodGroup.title, productionWeight=string.format("%.2f", foodGroup.productionWeight), eatWeight=string.format("%.2f", foodGroup.eatWeight), foodTypesLine="", fillTypes={}, fillTypesTitle={}}
			local foodGroupFillTypes = {}	-- for a faster search at the mixtures
			
			-- direct fill types
			for _, ftIndex in pairs(foodGroup.fillTypes) do
				foodGroupFillTypes[ftIndex] = 1
				local fillType = g_fillTypeManager:getFillTypeByIndex(ftIndex)
				if string.sub(fillType.name, 1, -3) ~= "SLIDER" then
					table.insert(item.fillTypes, fillType)
					table.insert(item.fillTypesTitle, fillType.title)
				end
			end

			-- mixture fill types
			if g_currentMission.animalFoodSystem.animalMixtures[animalFood.animalTypeIndex] ~= nil then
				local lastDirectFillTypePos = #item.fillTypes
				for i, mixFtIndex in pairs(g_currentMission.animalFoodSystem.animalMixtures[animalFood.animalTypeIndex]) do
					local mixFt = g_fillTypeManager:getFillTypeByIndex(mixFtIndex)
					self.mixFillTypeIdxToAnimalTitle[mixFtIndex] = animalName
					-- printf("MixFillType: Animal=%s Group=%s Mixture=%s", animalName, foodGroup.title, mixFt.title)
					
					local found = false
					for _, ingredient in pairs(g_currentMission.animalFoodSystem.mixtureFillTypeIndexToMixture[mixFtIndex].ingredients) do
						local weight = ingredient.weight
						for _, ftIndex in pairs(ingredient.fillTypes) do
							if foodGroupFillTypes[ftIndex] ~= nil and not found then
								local mixFillTypeTitle = string.format("%s (%.0f%%)", mixFt.title, weight*100)
								found = true

								if string.find(mixFt.name, "FORAGE") ~= nil then
									-- insert at end
									table.insert(item.fillTypes, mixFt)
									table.insert(item.fillTypesTitle, mixFillTypeTitle)
								else
									-- insert direct after direct fill types
									table.insert(item.fillTypes, lastDirectFillTypePos+1, mixFt)
									table.insert(item.fillTypesTitle, lastDirectFillTypePos+1, mixFillTypeTitle)
								end
							end
						end
					end
				end
			end

			-- create foodTypesLine for overview table
			local foodTypesLine = ""
			for index, ftTitle in pairs(item.fillTypesTitle) do
				if string.sub(ftTitle, 1, -3) ~= "SLIDER" then
					item.foodTypesLine = item.foodTypesLine .. (item.foodTypesLine == "" and "" or ", ") .. ftTitle
				end
			end
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

		local foodGroupEntry = self.overviewTableData[selectedSectionIndex].items[selectedIndex]
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
		cell:getAttribute("FoodTypes"):setText(foodGroupEntry.foodTypesLine)
	else
		local selectedSectionIndex = self.overviewTable.selectedSectionIndex
		local selectedIndex = self.overviewTable.selectedIndex

		local foodGroupEntry = self.overviewTableData[selectedSectionIndex].items[selectedIndex]
		local detailHeaderTxt = string.format("%s - %s", self.overviewTableData[selectedSectionIndex].animalName, foodGroupEntry.groupTitle )
		
		self.detailHeader:setText(detailHeaderTxt)
		cell:getAttribute("fillTypeIcon"):setImageFilename(foodGroupEntry.fillTypes[index].hudOverlayFilename)
		cell:getAttribute("FoodType"):setText(foodGroupEntry.fillTypesTitle[index])
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


function DlgFrame:onClickShowMixtureRecipes(sender)
	dbPrintf("DlgFrame:onClickShowMixtureRecipes()")

	DlgFrame.mixDlg	= nil
    local modDir = AnimalFoodOverview.dir
	g_gui:loadProfiles(modDir .. "gui/guiProfiles.xml")
	local mixDlgFrame = MixDlgFrame.new(g_i18n)
	g_gui:loadGui(modDir .. "gui/MixDlgFrame.xml", "MixDlgFrame", mixDlgFrame)
	DlgFrame.mixDlg = g_gui:showDialog("MixDlgFrame")

	if DlgFrame.mixDlg ~= nil then
		DlgFrame.mixDlg.target:InitData(self.mixFillTypeIdxToAnimalTitle)		
    end
end

