-- Copyright 2018-2019, Firaxis Games
--
--   ###
--   ###	WARNING: Modders, this replacement file may be REMOVED in a future 
--	 ###	update as the base game's TopPanel with extensions is sufficient.
--   ###
--   
--   ###
--

-- ===========================================================================
--	HUD Top of Screen Area
-- ===========================================================================
include( "InstanceManager" );
include( "SupportFunctions" ); -- Round
include( "ToolTipHelper_PlayerYields" );


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
META_PADDING	= 100;	-- The amount of padding to give the meta area to make enough room for the (+) when there is resource overflow
FONT_MULTIPLIER	= 11;	-- The amount to multiply times the string length to approximate the width in pixels of the label control


-- ===========================================================================
-- VARIABLES
-- ===========================================================================
m_YieldButtonSingleManager	= InstanceManager:new( "YieldButton_SingleLabel", "Top", Controls.YieldStack );
m_YieldButtonDoubleManager	= InstanceManager:new( "YieldButton_DoubleLabel", "Top", Controls.YieldStack );
m_kResourceIM				= InstanceManager:new( "ResourceInstance", "Top", Controls.ResourceStack );
m_viewReportsX				= 0;	-- With of view report button
local m_OpenPediaId;


-- ===========================================================================
-- Yield handles
-- ===========================================================================
local m_ScienceYieldButton	:table = nil;
local m_CultureYieldButton	:table = nil;
local m_GoldYieldButton		:table = nil;
local m_TourismYieldButton	:table = nil;
local m_FaithYieldButton	:table = nil;
local m_FaithYieldButton2	:table = nil;
local m_PopulationButton 	:table = nil;


-- Turn-based gold thresholds:
local g_TurnGoldThresholds = {
    [30] = 300,
    [50] = 600,
    [75] = 1000,
    [100] = 1500,
    [120] = 2500,
    [150] = 3500
}

local g_TurnGoldThresholds_Culture = {
    [30] = 200,
    [50] = 400,
    [75] = 700,
    [100] = 1100,
    [120] = 1800,
    [150] = 2400
}


-- Placeholder variable:
-- If "Domination", we do the threshold-based coloring.
-- If nil or something else, no special coloring.
local chosenVictoryMethod = "Culture";  -- or nil


-- xiaoxiao: adding code
local m_FoodYieldButton:table = nil;
local m_ProductionYieldButton:table = nil;


-- xiaoxiao: end adding code

-- xiaoxiao: copied from TopPanel_Expansion2.lua
local m_FavorYieldButton:table = nil;
-- xiaoxiao: end copied from TopPanel_Expansion2.lua

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnCityInitialized( playerID:number, cityID:number )
	if playerID == Game.GetLocalPlayer() then
		RefreshYields();
	end	
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnLocalPlayerChanged( playerID:number , prevLocalPlayerID:number )	
	if playerID == -1 then return; end
	local player = Players[playerID];
	local pPlayerCities	:table = player:GetCities();	
	RefreshAll();
end

-- ===========================================================================
function OnMenu()
	LuaEvents.InGame_OpenInGameOptionsMenu();
end

-- ===========================================================================
--	Takes a value and returns the string verison with +/- and rounded to
--	the tenths decimal place.
-- ===========================================================================
function FormatValuePerTurn( value:number )
	if(value == 0) then
		return Locale.ToNumber(value);
	else
		return Locale.Lookup("{1: number +#,###.#;-#,###.#}", value);
	end
end

-- xiaoxiao: begin code
function OnScienceYieldButtonClicked ()
	ExposedMembers.GameEvents.ScienceYieldButtonClicked.Call();
end
function OnCivicYieldButtonClicked ()
    local localPlayerId = Game.GetLocalPlayer();
    local player = Players[localPlayerId];
    local playerCulture = player:GetCulture();
    local fakeCivicId = GameInfo.Civics['CIVIC_FAKE_CIVIC'].Index;
    local overflow = playerCulture:GetCulturalProgress(fakeCivicId);
    local progressingCivicId = playerCulture:GetProgressingCivic();
	if overflow > 0 then
		local canProgress = playerCulture:CanProgress(progressingCivicId);
		local progress = playerCulture:GetCulturalProgress(progressingCivicId);
		ExposedMembers.GameEvents.CivicYieldButtonClicked.Call(overflow, canProgress, progress);
    else
		ExposedMembers.GameEvents.CivicYieldButtonClicked.Call(overflow, false, 0);
    end
end
ExposedMembers.XXUtils = ExposedMembers.XXUtils or {};
ExposedMembers.XXUtils.CanProgress = function (playerId, civicId)
	local player = Players[playerId];
	local playerCulture = player:GetCulture();
	return playerCulture:CanProgress(civicId);
end
-- xiaoxiao: end code


-- ===========================================================================
--	Refresh Data and View
-- ===========================================================================

function RefreshYields()
    -- Debug: output current victory method selection
    print("RefreshYields called. Current chosenVictoryMethod: " .. tostring(chosenVictoryMethod))
    
    local ePlayer       :number = Game.GetLocalPlayer();
    local localPlayer   :table = nil;
    if ePlayer ~= -1 then
        localPlayer = Players[ePlayer];
        if localPlayer == nil then
            return;
        end
    else
        return;
    end


	---- SCIENCE ----
	if GameCapabilities.HasCapability("CAPABILITY_SCIENCE") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
		m_ScienceYieldButton = m_ScienceYieldButton or m_YieldButtonSingleManager:GetInstance();
		local playerTechnology		:table	= localPlayer:GetTechs();
		local currentScienceYield	:number = playerTechnology:GetScienceYield();
		m_ScienceYieldButton.YieldPerTurn:SetText( FormatValuePerTurn(currentScienceYield) );	

		m_ScienceYieldButton.YieldBacking:SetToolTipString( GetScienceTooltip() );
		m_ScienceYieldButton.YieldIconString:SetText("[ICON_ScienceLarge]");
		m_ScienceYieldButton.YieldButtonStack:CalculateSize();
	end	
	
	---- CULTURE----
	if GameCapabilities.HasCapability("CAPABILITY_CULTURE") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
		m_CultureYieldButton = m_CultureYieldButton or m_YieldButtonSingleManager:GetInstance();
		local playerCulture			:table	= localPlayer:GetCulture();
		local currentCultureYield	:number = playerCulture:GetCultureYield();
		m_CultureYieldButton.YieldPerTurn:SetText( FormatValuePerTurn(currentCultureYield) );	
		m_CultureYieldButton.YieldPerTurn:SetColorByName("ResCultureLabelCS");

		m_CultureYieldButton.YieldBacking:SetToolTipString( GetCultureTooltip() );
		m_CultureYieldButton.YieldBacking:SetColor(UI.GetColorValueFromHexLiteral(0x99fe2aec));
		m_CultureYieldButton.YieldIconString:SetText("[ICON_CultureLarge]");
		m_CultureYieldButton.YieldButtonStack:CalculateSize();
	end

	---- FAITH ----
	if GameCapabilities.HasCapability("CAPABILITY_FAITH") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
		m_FaithYieldButton = m_FaithYieldButton or m_YieldButtonDoubleManager:GetInstance();
		local playerReligion		:table	= localPlayer:GetReligion();
		local faithYield			:number = playerReligion:GetFaithYield();
		local faithBalance			:number = playerReligion:GetFaithBalance();
		m_FaithYieldButton.YieldBalance:SetText( Locale.ToNumber(faithBalance, "#,###.#") );	
		m_FaithYieldButton.YieldPerTurn:SetText( FormatValuePerTurn(faithYield) );
		m_FaithYieldButton.YieldBacking:SetToolTipString( GetFaithTooltip() );
		m_FaithYieldButton.YieldIconString:SetText("[ICON_FaithLarge]");
		m_FaithYieldButton.YieldButtonStack:CalculateSize();
		
	end

		---- POPULATION ----
	-- New section: calculate total population and breakdown per city.
	local totalPopulation = 0;
	local populationTooltip = "";
	for _, city in localPlayer:GetCities():Members() do
		local cityPopulation = city:GetPopulation();  -- Ensure this API returns the city's population
		totalPopulation = totalPopulation + cityPopulation;
		populationTooltip = populationTooltip .. "[NEWLINE]" .. Locale.Lookup(city:GetName()) .. ": " .. cityPopulation;
	end
	-- Prepend the total and an icon (adjust the icon as needed)
	populationTooltip = Locale.ToNumber(totalPopulation) .. " [ICON_Citizen]" .. populationTooltip;
	
	m_PopulationButton = m_PopulationButton or m_YieldButtonSingleManager:GetInstance();
	m_PopulationButton.YieldPerTurn:SetText( Locale.ToNumber(totalPopulation) );
	m_PopulationButton.YieldBacking:SetToolTipString( populationTooltip );
	m_PopulationButton.YieldIconString:SetText("[ICON_Citizen]");
	m_PopulationButton.YieldPerTurn:SetColorByName("ResPopulationLabelCS");
	m_PopulationButton.YieldBacking:SetColorByName("ResPopulationLabelCS");
	m_PopulationButton.YieldButtonStack:CalculateSize();

    ---- GOLD ----
    if GameCapabilities.HasCapability("CAPABILITY_GOLD") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        m_GoldYieldButton = m_GoldYieldButton or m_YieldButtonDoubleManager:GetInstance();
        local playerTreasury = localPlayer:GetTreasury();
        local goldYield = playerTreasury:GetGoldYield() - playerTreasury:GetTotalMaintenance();
        local goldBalance = math.floor(playerTreasury:GetGoldBalance());
        local currentTurn = Game.GetCurrentGameTurn();

        m_GoldYieldButton.YieldBalance:SetText( Locale.ToNumber(goldBalance, "#,###.#") );
        m_GoldYieldButton.YieldPerTurn:SetText( FormatValuePerTurn(goldYield) );
        m_GoldYieldButton.YieldIconString:SetText("[ICON_GoldLarge]");

        -- Determine threshold table based on chosenVictoryMethod
        local thresholdTable = nil;
        if chosenVictoryMethod == "Domination" then
            thresholdTable = g_TurnGoldThresholds;
        elseif chosenVictoryMethod == "Culture" then
            thresholdTable = g_TurnGoldThresholds_Culture;
        end

        print("Using threshold table for victory method: " .. tostring(chosenVictoryMethod))

    ---------------------------------------------------------------
    -- PART A: Color the GOLD BALANCE based on milestone thresholds.
    ---------------------------------------------------------------
    if thresholdTable then
        local threshold = nil;
        local largestKey = 0;
        for key,_ in pairs(thresholdTable) do
            if key > largestKey then largestKey = key; end
        end
        if currentTurn > largestKey then
            threshold = nil;
        else
            local sortedKeys = {};
            for key,_ in pairs(thresholdTable) do table.insert(sortedKeys, key); end
            table.sort(sortedKeys);
            for _, milestone in ipairs(sortedKeys) do
                if currentTurn <= milestone then
                    threshold = thresholdTable[milestone];
                    break;
                end
            end
        end

        if threshold == nil then
            m_GoldYieldButton.YieldBalance:SetColorByName("ResGoldLabelCS");
        else
            if goldBalance < threshold then
                m_GoldYieldButton.YieldBalance:SetColorByName("Red");
            else
                m_GoldYieldButton.YieldBalance:SetColorByName("COLOR_STANDARD_GREEN_LT");
            end
        end
    else
        m_GoldYieldButton.YieldBalance:SetColorByName("ResGoldLabelCS");
    end

    ---------------------------------------------------------------
    -- PART B: For gold YIELD, project future gold based on current yield.
    -- Only apply if victory method is "Domination" or "Culture".
    ---------------------------------------------------------------
    local yieldTooltipAddition = "";
    if chosenVictoryMethod == "Domination" or chosenVictoryMethod == "Culture" then
        if goldYield < 0 then
            m_GoldYieldButton.YieldPerTurn:SetColorByName("Red");
        else
            if thresholdTable then
                local sortedMilestones = {};
                for key,_ in pairs(thresholdTable) do table.insert(sortedMilestones, key); end
                table.sort(sortedMilestones);
                local thresholdYield = nil;
                local milestoneTurn = nil;
                for _, mk in ipairs(sortedMilestones) do
                    if currentTurn <= mk then
                        thresholdYield = thresholdTable[mk];
                        milestoneTurn = mk;
                        break;
                    end
                end
                if thresholdYield == nil or milestoneTurn == nil then
                    m_GoldYieldButton.YieldPerTurn:SetColorByName("ResGoldLabelCS");
                else
                    local turnsLeft = milestoneTurn - currentTurn;
                    if turnsLeft <= 0 then
                        m_GoldYieldButton.YieldPerTurn:SetColorByName("ResGoldLabelCS");
                    else
                        local expectedGold = goldBalance + (goldYield * turnsLeft);
                        if expectedGold >= thresholdYield then
                            m_GoldYieldButton.YieldPerTurn:SetColorByName("COLOR_STANDARD_GREEN_LT");
                        else
                            m_GoldYieldButton.YieldPerTurn:SetColorByName("Red");
                        end
                        local requiredYield = (thresholdYield - goldBalance) / turnsLeft;
                        yieldTooltipAddition = "[NEWLINE]Target: " .. thresholdYield .. " by turn " .. milestoneTurn ..
                                                "[NEWLINE]Required yield: " .. FormatValuePerTurn(requiredYield) .. " per turn";
                    end
                end
            else
                m_GoldYieldButton.YieldPerTurn:SetColorByName("ResGoldLabelCS");
            end
        end
    else
        if goldYield < 0 then
            m_GoldYieldButton.YieldPerTurn:SetColorByName("Red");
        else
            m_GoldYieldButton.YieldPerTurn:SetColorByName("ResGoldLabelCS");
        end
    end

    ---------------------------------------------------------------
    -- PART C: Append additional yield info to the gold tooltip.
    ---------------------------------------------------------------
    local baseGoldTooltip = GetGoldTooltip();
    local finalGoldTooltip = baseGoldTooltip .. yieldTooltipAddition;
    m_GoldYieldButton.YieldBacking:SetToolTipString( finalGoldTooltip );
    m_GoldYieldButton.YieldBacking:SetColorByName("ResGoldLabelCS");
    m_GoldYieldButton.YieldButtonStack:CalculateSize();
end

	-- xiaoxiao: adding code
	-- calculate food and production
	local FOOD_INDEX = GameInfo.Yields["YIELD_FOOD"].Index;
	local PRODUCTION_INDEX = GameInfo.Yields["YIELD_PRODUCTION"].Index;
	local totalFood = 0;
	local foodTooltip = "";
	local totalProduction = 0;
	local productionTooltip = "";
	for _, city in localPlayer:GetCities():Members() do
		local cityFood = city:GetYield(FOOD_INDEX);
		local cityProduction = city:GetYield(PRODUCTION_INDEX);
		totalFood = totalFood + cityFood;
		totalProduction = totalProduction + cityProduction;
		foodTooltip = foodTooltip .. "[NEWLINE]" .. Locale.Lookup(city:GetName()) .. ": " .. FormatValuePerTurn(cityFood) .. " [ICON_FOOD]";
		productionTooltip = productionTooltip .. "[NEWLINE]" .. Locale.Lookup(city:GetName()) .. ": " .. FormatValuePerTurn(cityProduction) .. " [ICON_PRODUCTION]";
	end
	foodTooltip = FormatValuePerTurn(totalFood) .. " [ICON_FOOD]" .. foodTooltip;
	productionTooltip = FormatValuePerTurn(totalProduction) .. " [ICON_PRODUCTION]" .. productionTooltip;

	---- FOOD ----
	m_FoodYieldButton = m_FoodYieldButton or m_YieldButtonSingleManager:GetInstance();
	m_FoodYieldButton.YieldPerTurn:SetText( FormatValuePerTurn(totalFood) );
	m_FoodYieldButton.YieldBacking:SetToolTipString( foodTooltip );
	m_FoodYieldButton.YieldIconString:SetText("[ICON_FoodLarge]");
	m_FoodYieldButton.YieldPerTurn:SetColorByName("ResFoodLabelCS");
	m_FoodYieldButton.YieldBacking:SetColorByName("ResFoodLabelCS");
	m_FoodYieldButton.YieldButtonStack:CalculateSize();
	
	---- PRODUCTION----
	m_ProductionYieldButton = m_ProductionYieldButton or m_YieldButtonSingleManager:GetInstance();
	m_ProductionYieldButton.YieldPerTurn:SetText( FormatValuePerTurn(totalProduction) );
	m_ProductionYieldButton.YieldBacking:SetToolTipString( productionTooltip );
	m_ProductionYieldButton.YieldIconString:SetText("[ICON_ProductionLarge]");
	m_ProductionYieldButton.YieldPerTurn:SetColorByName("ResProductionLabelCS");
	m_ProductionYieldButton.YieldBacking:SetColorByName("ResProductionLabelCS");
	m_ProductionYieldButton.YieldButtonStack:CalculateSize();
	-- xiaoxiao: end adding code

	---- TOURISM ----
	if GameCapabilities.HasCapability("CAPABILITY_TOURISM") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
		m_TourismYieldButton = m_TourismYieldButton or m_YieldButtonSingleManager:GetInstance();
		local tourismRate = Round(localPlayer:GetStats():GetTourism(), 1);
		local tourismRateTT:string = Locale.Lookup("LOC_WORLD_RANKINGS_OVERVIEW_CULTURE_TOURISM_RATE", tourismRate);
		local tourismBreakdown = localPlayer:GetStats():GetTourismToolTip();
		if(tourismBreakdown and #tourismBreakdown > 0) then
			tourismRateTT = tourismRateTT .. "[NEWLINE][NEWLINE]" .. tourismBreakdown;
		end
		
		m_TourismYieldButton.YieldPerTurn:SetText( tourismRate );	
		m_TourismYieldButton.YieldBacking:SetToolTipString(tourismRateTT);
		m_TourismYieldButton.YieldPerTurn:SetColorByName("ResTourismLabelCS");
		m_TourismYieldButton.YieldBacking:SetColorByName("ResTourismLabelCS");
		m_TourismYieldButton.YieldIconString:SetText("[ICON_TourismLarge]");
		if (tourismRate > 0) then
			m_TourismYieldButton.Top:SetHide(false);
		else
			m_TourismYieldButton.Top:SetHide(true);
		end 
	end

	Controls.YieldStack:CalculateSize();
	Controls.StaticInfoStack:CalculateSize();
	Controls.InfoStack:CalculateSize();

	Controls.YieldStack:RegisterSizeChanged( RefreshResources );
	Controls.StaticInfoStack:RegisterSizeChanged( RefreshResources );

	-- xiaoxiao: copied from TopPanel_Expansion2.lua
	local localPlayerID = Game.GetLocalPlayer();
	if localPlayerID ~= -1 then 
		local localPlayer = Players[localPlayerID];

		--Favor
		m_FavorYieldButton = m_FavorYieldButton or m_YieldButtonDoubleManager:GetInstance();
		local playerFavor	:number = localPlayer:GetFavor();
		local favorPerTurn	:number = localPlayer:GetFavorPerTurn();
		local tooltip		:string = Locale.Lookup("LOC_WORLD_CONGRESS_TOP_PANEL_FAVOR_TOOLTIP");

		local details = localPlayer:GetFavorPerTurnToolTip();
		if(details and #details > 0) then
			tooltip = tooltip .. "[NEWLINE]" .. details;
		end

		m_FavorYieldButton.YieldBalance:SetText(Locale.ToNumber(playerFavor, "#,###.#"));
		m_FavorYieldButton.YieldBalance:SetColorByName("ResFavorLabelCS");
		m_FavorYieldButton.YieldPerTurn:SetText(FormatValuePerTurn(favorPerTurn));	
		m_FavorYieldButton.YieldPerTurn:SetColorByName("ResFavorLabelCS");
		m_FavorYieldButton.YieldBacking:SetToolTipString(tooltip);
		m_FavorYieldButton.YieldBacking:SetColorByName("ResFavorLabelCS");
		m_FavorYieldButton.YieldIconString:SetText("[ICON_FAVOR_LARGE]");
		m_FavorYieldButton.YieldButtonStack:CalculateSize();
	end	
	-- xiaoxiao: end copied from TopPanel_Expansion2.lua
end

-- ===========================================================================
--	Game Engine Event
function OnRefreshYields()
	ContextPtr:RequestRefresh();
end

-- ===========================================================================
function RefreshTrade()

	local localPlayer = Players[Game.GetLocalPlayer()];
	if (localPlayer == nil) or not GameCapabilities.HasCapability("CAPABILITY_TRADE") then
		Controls.TradeRoutes:SetHide(true);
		return;
	end

	---- ROUTES ----
	local playerTrade	:table	= localPlayer:GetTrade();
	local routesActive	:number = playerTrade:GetNumOutgoingRoutes();
	local sRoutesActive :string = "" .. routesActive;
	local routesCapacity:number = playerTrade:GetOutgoingRouteCapacity();
	if (routesCapacity > 0) then
		if (routesActive > routesCapacity) then
			sRoutesActive = "[COLOR_RED]" .. sRoutesActive .. "[ENDCOLOR]";
		elseif (routesActive < routesCapacity) then
			sRoutesActive = "[COLOR_GREEN]" .. sRoutesActive .. "[ENDCOLOR]";
		end
		Controls.TradeRoutesActive:SetText(sRoutesActive);
		Controls.TradeRoutesCapacity:SetText(routesCapacity);

		local sTooltip = Locale.Lookup("LOC_TOP_PANEL_TRADE_ROUTES_TOOLTIP_ACTIVE", routesActive);
		sTooltip = sTooltip .. "[NEWLINE]";
		sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_TRADE_ROUTES_TOOLTIP_CAPACITY", routesCapacity);
		sTooltip = sTooltip .. "[NEWLINE][NEWLINE]";
		sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_TRADE_ROUTES_TOOLTIP_SOURCES_HELP");
		Controls.TradeRoutes:SetToolTipString(sTooltip);
		Controls.TradeRoutes:SetHide(false);
	else
		Controls.TradeRoutes:SetHide(true);
	end

	Controls.TradeStack:CalculateSize();
end

-- ===========================================================================
function RefreshInfluence()
	if GameCapabilities.HasCapability("CAPABILITY_TOP_PANEL_ENVOYS") then
		local localPlayer = Players[Game.GetLocalPlayer()];
		if (localPlayer == nil) then
			return;
		end

		local playerInfluence	:table	= localPlayer:GetInfluence();
		local influenceBalance	:number	= Round(playerInfluence:GetPointsEarned(), 1);
		local influenceRate		:number = Round(playerInfluence:GetPointsPerTurn(), 1);
		local influenceThreshold:number	= playerInfluence:GetPointsThreshold();
		local envoysPerThreshold:number = playerInfluence:GetTokensPerThreshold();
		local currentEnvoys		:number = playerInfluence:GetTokensToGive();
		
		local sTooltip = "";

		if (currentEnvoys > 0) then
			sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_ENVOYS", currentEnvoys);
			sTooltip = sTooltip .. "[NEWLINE][NEWLINE]";
		end
		sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_POINTS_THRESHOLD", envoysPerThreshold, influenceThreshold);
		sTooltip = sTooltip .. "[NEWLINE][NEWLINE]";
		sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_POINTS_BALANCE", influenceBalance);
		sTooltip = sTooltip .. "[NEWLINE]";
		sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_POINTS_RATE", influenceRate);
		sTooltip = sTooltip .. "[NEWLINE][NEWLINE]";
		sTooltip = sTooltip .. Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_SOURCES_HELP");
		
		local meterRatio = influenceBalance / influenceThreshold;
		if (meterRatio < 0) then
			meterRatio = 0;
		elseif (meterRatio > 1) then
			meterRatio = 1;
		end
		Controls.EnvoysMeter:SetPercent(meterRatio);
		Controls.EnvoysNumber:SetText(tostring(currentEnvoys));
		Controls.Envoys:SetToolTipString(sTooltip);
		Controls.EnvoysStack:CalculateSize();
	else
		Controls.Envoys:SetHide(true);
	end
end

-- ===========================================================================
function RefreshTime()
	local format = UserConfiguration.GetClockFormat();
	
	local strTime;
	
	if(format == 1) then
		strTime = os.date("%H:%M");
	else
		strTime = os.date("%I:%M %p");

		-- Remove the leading zero (if any) from 12-hour clock format
		if(string.sub(strTime, 1, 1) == "0") then
			strTime = string.sub(strTime, 2);
		end
	end

	Controls.Time:SetText( strTime );
	local d = Locale.Lookup("{1_Time : datetime full}", os.time());
	Controls.Time:SetToolTipString(d);
end

-- ===========================================================================
function RefreshResources()

	--[[ xiaoxiao: these are overrided in TopPanel_Expansion2.lua, thus removed here.
	if not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_RESOURCES") then
		m_kResourceIM:ResetInstances();
		return;
	end
	local localPlayerID = Game.GetLocalPlayer();
	if (localPlayerID ~= -1) then
		m_kResourceIM:ResetInstances(); 
		local pPlayerResources	=  Players[localPlayerID]:GetResources();
		local yieldStackX		= Controls.YieldStack:GetSizeX();
		local infoStackX		= Controls.StaticInfoStack:GetSizeX();
		local metaStackX		= Controls.RightContents:GetSizeX();
		local screenX, _:number = UIManager:GetScreenSizeVal();
		local maxSize = screenX - yieldStackX - infoStackX - metaStackX - m_viewReportsX - META_PADDING;
		if (maxSize < 0) then maxSize = 0; end
		local currSize = 0;
		local isOverflow = false;
		local overflowString = "";
		local plusInstance:table;
		for resource in GameInfo.Resources() do
			if (resource.ResourceClassType ~= nil and resource.ResourceClassType ~= "RESOURCECLASS_BONUS" and resource.ResourceClassType ~="RESOURCECLASS_LUXURY" and resource.ResourceClassType ~="RESOURCECLASS_ARTIFACT") then
				local amount = pPlayerResources:GetResourceAmount(resource.ResourceType);
				if (amount > 0) then
					local resourceText = "[ICON_"..resource.ResourceType.."] ".. amount;
					local numDigits = 3;
					if (amount >= 10) then
						numDigits = 4;
					end
					local guessinstanceWidth = math.ceil(numDigits * FONT_MULTIPLIER);
					if(currSize + guessinstanceWidth < maxSize and not isOverflow) then
						if (amount ~= 0) then
							local instance:table = m_kResourceIM:GetInstance();
							instance.ResourceText:SetText(resourceText);
							instance.ResourceText:SetToolTipString(Locale.Lookup(resource.Name).."[NEWLINE]"..Locale.Lookup("LOC_TOOLTIP_STRATEGIC_RESOURCE"));
							instanceWidth = instance.ResourceText:GetSizeX();
							currSize = currSize + instanceWidth;
						end
					else
						if (not isOverflow) then 
							overflowString = amount.. "[ICON_"..resource.ResourceType.."]".. Locale.Lookup(resource.Name);
							local instance:table = m_kResourceIM:GetInstance();
							instance.ResourceText:SetText("[ICON_Plus]");
							plusInstance = instance.ResourceText;
						else
							overflowString = overflowString .. "[NEWLINE]".. amount.. "[ICON_"..resource.ResourceType.."]".. Locale.Lookup(resource.Name);
						end
						isOverflow = true;
					end
				end
			end
		end
		if (plusInstance ~= nil) then
			plusInstance:SetToolTipString(overflowString);
		end
		Controls.ResourceStack:CalculateSize();
		if(Controls.ResourceStack:GetSizeX() == 0) then
			Controls.Resources:SetHide(true);
		else
			Controls.Resources:SetHide(false);
		end
	end
	--]]
	-- xiaoxiao: copied from TopPanel_Expansion2.lua
	if not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_RESOURCES") then
		m_kResourceIM:ResetInstances();
		return;
	end
	local localPlayerID = Game.GetLocalPlayer();
	local localPlayer = Players[localPlayerID];
	if (localPlayerID ~= -1) then
		m_kResourceIM:ResetInstances(); 
		local pPlayerResources:table	=  localPlayer:GetResources();
		local yieldStackX:number		= Controls.YieldStack:GetSizeX();
		local infoStackX:number		= Controls.StaticInfoStack:GetSizeX();
		local metaStackX:number		= Controls.RightContents:GetSizeX();
		local screenX, _:number = UIManager:GetScreenSizeVal();
		local maxSize:number = screenX - yieldStackX - infoStackX - metaStackX - m_viewReportsX - META_PADDING;
		if (maxSize < 0) then maxSize = 0; end
		local currSize:number = 0;
		local isOverflow:boolean = false;
		local overflowString:string = "";
		local plusInstance:table;
		for resource in GameInfo.Resources() do
			if (resource.ResourceClassType ~= nil and resource.ResourceClassType ~= "RESOURCECLASS_BONUS" and resource.ResourceClassType ~="RESOURCECLASS_LUXURY" and resource.ResourceClassType ~="RESOURCECLASS_ARTIFACT") then

				local stockpileAmount:number = pPlayerResources:GetResourceAmount(resource.ResourceType);
				local stockpileCap:number = pPlayerResources:GetResourceStockpileCap(resource.ResourceType);
				local reservedAmount:number = pPlayerResources:GetReservedResourceAmount(resource.ResourceType);
				local accumulationPerTurn:number = pPlayerResources:GetResourceAccumulationPerTurn(resource.ResourceType);
				local importPerTurn:number = pPlayerResources:GetResourceImportPerTurn(resource.ResourceType);
				local bonusPerTurn:number = pPlayerResources:GetBonusResourcePerTurn(resource.ResourceType);
				local unitConsumptionPerTurn:number = pPlayerResources:GetUnitResourceDemandPerTurn(resource.ResourceType);
				local powerConsumptionPerTurn:number = pPlayerResources:GetPowerResourceDemandPerTurn(resource.ResourceType);
				local totalConsumptionPerTurn:number = unitConsumptionPerTurn + powerConsumptionPerTurn;
				local totalAmount:number = stockpileAmount + reservedAmount;

				if (totalAmount > stockpileCap) then
					totalAmount = stockpileCap;
				end

				local iconName:string = "[ICON_"..resource.ResourceType.."]";

				local totalAccumulationPerTurn:number = accumulationPerTurn + importPerTurn + bonusPerTurn;

				resourceText = iconName .. " " .. stockpileAmount;

				local numDigits:number = 3;
				if (stockpileAmount >= 10) then
					numDigits = 4;
				end
				local guessinstanceWidth:number = math.ceil(numDigits * FONT_MULTIPLIER);

				local tooltip:string = iconName .. " " .. Locale.Lookup(resource.Name);
				if (reservedAmount ~= 0) then
					--instance.ResourceText:SetColor(UI.GetColorValue("COLOR_YELLOW"));
					tooltip = tooltip .. "[NEWLINE]" .. totalAmount .. "/" .. stockpileCap .. " " .. Locale.Lookup("LOC_RESOURCE_ITEM_IN_STOCKPILE");
					tooltip = tooltip .. "[NEWLINE]-" .. reservedAmount .. " " .. Locale.Lookup("LOC_RESOURCE_ITEM_IN_RESERVE");
				else
					--instance.ResourceText:SetColor(UI.GetColorValue("COLOR_WHITE"));
					tooltip = tooltip .. "[NEWLINE]" .. totalAmount .. "/" .. stockpileCap .. " " .. Locale.Lookup("LOC_RESOURCE_ITEM_IN_STOCKPILE");
				end
				if (totalAccumulationPerTurn >= 0) then
					tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN", totalAccumulationPerTurn);
				else
					tooltip = tooltip .. "[NEWLINE][COLOR_RED]" .. Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN", totalAccumulationPerTurn) .. "[ENDCOLOR]";
				end
				if (accumulationPerTurn > 0) then
					tooltip = tooltip .. "[NEWLINE] " .. Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_EXTRACTED", accumulationPerTurn);
				end
				if (importPerTurn > 0) then
					tooltip = tooltip .. "[NEWLINE] " .. Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_FROM_CITY_STATES", importPerTurn);
				end
				if (bonusPerTurn > 0) then
					tooltip = tooltip .. "[NEWLINE] " .. Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_FROM_BONUS_SOURCES", bonusPerTurn);
				end
				if (totalConsumptionPerTurn > 0) then
					tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_RESOURCE_CONSUMPTION", totalConsumptionPerTurn);
					if (unitConsumptionPerTurn > 0) then
						tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_RESOURCE_UNIT_CONSUMPTION_PER_TURN", unitConsumptionPerTurn);
					end
					if (powerConsumptionPerTurn > 0) then
						tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_RESOURCE_POWER_CONSUMPTION_PER_TURN", powerConsumptionPerTurn);
					end
				end

				if (stockpileAmount > 0 or totalAccumulationPerTurn > 0 or totalConsumptionPerTurn > 0) then
					if(currSize + guessinstanceWidth < maxSize and not isOverflow) then
						if (stockpileCap > 0) then
							local instance:table = m_kResourceIM:GetInstance();
							if (totalAccumulationPerTurn > totalConsumptionPerTurn) then
								instance.ResourceVelocity:SetHide(false);
								instance.ResourceVelocity:SetTexture("CityCondition_Rising");
							elseif (totalAccumulationPerTurn < totalConsumptionPerTurn) then
								instance.ResourceVelocity:SetHide(false);
								instance.ResourceVelocity:SetTexture("CityCondition_Falling");
							else
								instance.ResourceVelocity:SetHide(true);
							end

							instance.ResourceText:SetText(resourceText);
							instance.ResourceText:SetToolTipString(tooltip);
							instanceWidth = instance.ResourceText:GetSizeX();
							currSize = currSize + instanceWidth;
						end
					else
						if (not isOverflow) then 
							overflowString = tooltip;
							local instance:table = m_kResourceIM:GetInstance();
							instance.ResourceText:SetText("[ICON_Plus]");
							plusInstance = instance.ResourceText;
						else
							overflowString = overflowString .. "[NEWLINE]" .. tooltip;
						end
						isOverflow = true;
					end
				end
			end
		end

		if (plusInstance ~= nil) then
			plusInstance:SetToolTipString(overflowString);
		end
		
		Controls.ResourceStack:CalculateSize();
		
		if(Controls.ResourceStack:GetSizeX() == 0) then
			Controls.Resources:SetHide(true);
		else
			Controls.Resources:SetHide(false);
		end
	end
	-- xiaoxiao: end copied from TopPanel_Expansion2.lua
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnRefreshResources()
	if UI.IsInGame() == false then
		return;
	end
	if not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_RESOURCES") then
		m_kResourceIM:ResetInstances();
		return;
	end
	RefreshResources();
end

-- ===========================================================================
--	Use an animation control to occasionally (not per frame!) callback for
--	an update on the current time.
-- ===========================================================================
function OnRefreshTimeTick()
	RefreshTime();
	Controls.TimeCallback:SetToBeginning();
	Controls.TimeCallback:Play();
end

-- ===========================================================================
function RefreshTurnsRemaining()

	local endTurn = Game.GetGameEndTurn();		-- This EXCLUSIVE, i.e. the turn AFTER the last playable turn.
	local turn = Game.GetCurrentGameTurn();

	if GameCapabilities.HasCapability("CAPABILITY_DISPLAY_NORMALIZED_TURN") then
		turn = (turn - GameConfiguration.GetStartTurn()) + 1; -- Keep turns starting at 1.
		if endTurn > 0 then
			endTurn = endTurn - GameConfiguration.GetStartTurn();
		end
	end

	if endTurn > 0 then
		-- We have a hard turn limit
		Controls.Turns:SetText(tostring(turn) .. "/" .. tostring(endTurn - 1));
	else
		Controls.Turns:SetText(tostring(turn));
	end

	local strDate = Calendar.MakeYearStr(turn);
	Controls.CurrentDate:SetText(strDate);
end

-- ===========================================================================
function OnWMDUpdate(owner, WMDtype)
	local eLocalPlayer = Game.GetLocalPlayer();
	if ( eLocalPlayer ~= -1 and owner == eLocalPlayer ) then
		local player = Players[owner];
		local playerWMDs = player:GetWMDs();

		for entry in GameInfo.WMDs() do
			if (entry.WeaponType == "WMD_NUCLEAR_DEVICE") then
				local count = playerWMDs:GetWeaponCount(entry.Index);
				if (count > 0) then
					Controls.NuclearDevices:SetHide(false);
					Controls.NuclearDeviceCount:SetText(count);
				else
					Controls.NuclearDevices:SetHide(true);
				end

			elseif (entry.WeaponType == "WMD_THERMONUCLEAR_DEVICE") then
				local count = playerWMDs:GetWeaponCount(entry.Index);
				if (count > 0) then
					Controls.ThermoNuclearDevices:SetHide(false);
					Controls.ThermoNuclearDeviceCount:SetText(count);
				else
					Controls.ThermoNuclearDevices:SetHide(true);
				end
			end
		end

		Controls.YieldStack:CalculateSize();
	end

	OnRefreshYields();	-- Don't directly refresh, call EVENT version so it's queued in the next context update.
end

-- ===========================================================================
function OnGreatPersonActivated(playerID:number)
	if ( Game.GetLocalPlayer() == playerID ) then
		OnRefreshYields();
	end
end

-- ===========================================================================
function OnGreatWorkCreated(playerID:number)
	if ( Game.GetLocalPlayer() == playerID ) then
		OnRefreshYields();
	end
end

-- ===========================================================================
function RefreshAll()
	RefreshTurnsRemaining();
	RefreshTrade();
	RefreshInfluence();
	RefreshYields();
	RefreshTime();
	RefreshResources();
	OnWMDUpdate( Game.GetLocalPlayer() );
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnTurnBegin()	
	RefreshAll();
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnUpdateUI( type:number, tag:string, iData1:number, iData2:number, strData1:string)
	if type == SystemUpdateUI.ScreenResize then
		-- TODO?		
	end
end

-- ===========================================================================
function OnRefresh()
	ContextPtr:ClearRequestRefresh();
	RefreshYields();
end



-- ===========================================================================
--	Game Engine Event
--	Wait until the game engine is done loading before the initial refresh,
--	otherwise there is a chance the load of the LUA threads (UI & core) will 
--  clash and then we'll all have a bad time. :(
-- ===========================================================================
function OnLoadGameViewStateDone()
	print("HELLO: My mod is active!");
	RefreshAll();
end


-- ===========================================================================
function LateInitialize()	

	-- UI Callbacks	
	Controls.CivpediaButton:RegisterCallback( Mouse.eLClick, function() LuaEvents.ToggleCivilopedia(); end);
	Controls.CivpediaButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.MenuButton:RegisterCallback( Mouse.eLClick, OnMenu );
	Controls.MenuButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.TimeCallback:RegisterEndCallback( OnRefreshTimeTick );

	-- Game Events
	Events.AnarchyBegins.Add(				OnRefreshYields );
	Events.AnarchyEnds.Add(					OnRefreshYields );
	Events.BeliefAdded.Add(					OnRefreshYields );
	Events.CityInitialized.Add(				OnCityInitialized );
	Events.CityFocusChanged.Add(            OnRefreshYields );
	Events.CityWorkerChanged.Add(           OnRefreshYields );
	Events.DiplomacySessionClosed.Add(		OnRefreshYields );
	Events.FaithChanged.Add(				OnRefreshYields );
	Events.GovernmentChanged.Add(			OnRefreshYields );
	Events.GovernmentPolicyChanged.Add(		OnRefreshYields );
	Events.GovernmentPolicyObsoleted.Add(	OnRefreshYields );
	Events.GreatWorkCreated.Add(            OnGreatWorkCreated );
	Events.ImprovementAddedToMap.Add(		OnRefreshResources );
	Events.ImprovementRemovedFromMap.Add(	OnRefreshResources );
	Events.InfluenceChanged.Add(			RefreshInfluence );
	Events.LoadGameViewStateDone.Add(		OnLoadGameViewStateDone );
	Events.LocalPlayerChanged.Add(			OnLocalPlayerChanged );
	Events.PantheonFounded.Add(				OnRefreshYields );
	Events.PlayerAgeChanged.Add(			OnRefreshYields );
	Events.ResearchCompleted.Add(			OnRefreshResources );
	Events.PlayerResourceChanged.Add(		OnRefreshResources );
	Events.SystemUpdateUI.Add(				OnUpdateUI );
	Events.TradeRouteActivityChanged.Add(	RefreshTrade );
	Events.TradeRouteCapacityChanged.Add(	RefreshTrade );
	Events.TreasuryChanged.Add(				OnRefreshYields );
	Events.TurnBegin.Add(					OnTurnBegin );
	Events.UnitAddedToMap.Add(				OnRefreshYields );
	Events.UnitGreatPersonActivated.Add(    OnGreatPersonActivated );
	Events.UnitKilledInCombat.Add(			OnRefreshYields );
	Events.UnitRemovedFromMap.Add(			OnRefreshYields );
	Events.VisualStateRestored.Add(			OnTurnBegin );
	Events.WMDCountChanged.Add(				OnWMDUpdate );	
	Events.CityProductionChanged.Add(		OnRefreshResources);
	

	-- If no expansions function are in scope, ready to refresh and show values.
	if not XP1_LateInitialize then
		RefreshYields();
	end

	-- xiaoxiao: copied from TopPanel_Expansion1.lua
	Events.LocalPlayerTurnBegin.Add( OnLocalPlayerTurnBegin );
	RealizeEraBacking();
	if not XP1_LateInitialize then
		RefreshYields();
	end
	-- xiaoxiao: end copied from TopPanel_Expansion1.lua

	-- xiaoxiao: copied from TopPanel_Expansion2.lua
	Events.FavorChanged.Add( OnRefreshYields );
	if not XP2_LateInitialize then
		RefreshYields();
	end
	-- xiaoxiao: end copied from TopPanel_Expansion1.lua

	-- xiaoxiao: code
	Events.ResearchChanged.Add( OnRefreshYields );
	Events.CivicChanged.Add( OnRefreshYields );
	-- xiaoxiao: end code
end

-- xiaoxiao: copied from TopPanel_Expansion1.lua
function RealizeEraBacking()
	local kEras			:table = Game.GetEras();
	local localPlayerID	:number = Game.GetLocalPlayer();

	if localPlayerID == PlayerTypes.NONE then
		Controls.Backing:SetTexture("TopBar_Bar");
	else
		local pGameEras:table = Game.GetEras();
		if kEras:HasHeroicGoldenAge(localPlayerID) then
			Controls.Backing:SetTexture("TopBar_Bar_Heroic");
		elseif kEras:HasGoldenAge(localPlayerID) then
			Controls.Backing:SetTexture("TopBar_Bar_Golden");
		elseif kEras:HasDarkAge(localPlayerID) then
			Controls.Backing:SetTexture("TopBar_Bar_Dark");
		else
			Controls.Backing:SetTexture("TopBar_Bar");
		end
	end
end

function OnLocalPlayerTurnBegin()
	RealizeEraBacking();
end
-- xiaoxiao: end copied from TopPanel_Expansion1.lua

-- ===========================================================================
function OnInit( isReload:boolean )
	LateInitialize();
	RefreshYields()
end

-- ===========================================================================
function Initialize()	
	-- UI Callbacks	
	ContextPtr:SetInitHandler( OnInit );	
	ContextPtr:SetRefreshHandler( OnRefresh );
end
Initialize();
