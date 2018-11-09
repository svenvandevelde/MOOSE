--- **Functional** - (R2.5) - Manages aircraft operations on carriers.
-- 
-- Practice carrier landings.
--
-- Features:
--
--    * CASE I recovery.
--    * Performance evaluation.
--    * Feedback about performance during flight.
--
-- Please not that his class is work in progress and in an **alpha** stage.
-- At the moment training parameters are optimized for F/A-18C Hornet as aircraft and USS Stennis as carrier.
-- Other aircraft and carriers **might** be possible in future but would need a different set of parameters.
--
-- ===
--
-- ### Authors: **funkyfranky** (MOOSE class implementation and enhancements), **Bankler** (original idea and script) 
--
-- @module Functional.Airboss
-- @image MOOSE.JPG

--- AIRBOSS class.
-- @type AIRBOSS
-- @field #string ClassName Name of the class.
-- @field #string lid Class id string for output to DCS log file.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field Wrapper.Unit#UNIT carrier Aircraft carrier unit on which we want to practice.
-- @field #string carriertype Type name of aircraft carrier.
-- @field #string alias Alias of the carrier trainer.
-- @field Core.Radio#BEACON beacon Carrier beacon for TACAN and ICLS.
-- @field #number TACANchannel TACAN channel.
-- @field #string TACANmode TACAN mode, i.e. "X" or "Y".
-- @field #number ICLSchannel ICLS channel.
-- @field Core.Radio#RADIO LSOradio Radio for LSO calls.
-- @field Core.Radio#RADIO Carrierradio Radio for carrier calls.
-- @field Core.Zone#ZONE_UNIT startZone Zone in which the pattern approach starts.
-- @field Core.Zone#ZONE_UNIT giantZone Large zone around the carrier to welcome players.
-- @field Core.Zone#ZONE_UNIT registerZone Zone behind the carrier to register for a new approach.
-- @field #table players Table of players. 
-- @field #table menuadded Table of units where the F10 radio menu was added.
-- @field #AIRBOSS.Checkpoint Upwind Upwind checkpoint.
-- @field #AIRBOSS.Checkpoint BreakEarly Early break checkpoint.
-- @field #AIRBOSS.Checkpoint BreakLate Late brak checkpoint.
-- @field #AIRBOSS.Checkpoint Abeam Abeam checkpoint.
-- @field #AIRBOSS.Checkpoint Ninety At the ninety checkpoint.
-- @field #AIRBOSS.Checkpoint Wake Right behind the carrier.
-- @field #AIRBOSS.Checkpoint Groove In the groove checkpoint.
-- @field #AIRBOSS.Checkpoint Trap Landing checkpoint.
-- @field #number rwyangle Angle of the runway wrt to carrier "nose". For the Stennis ~ -10 degrees.
-- @field #number sterndist Distance in meters from carrier coordinate to the end of the deck.
-- @field #number deckheight Height of the deck in meters.
-- @extends Core.Fsm#FSM

--- Practice Carrier Landings
--
-- ===
--
-- ![Banner Image](..\Presentations\AIRBOSS\CarrierTrainer_Main.png)
--
-- # The Trainer Concept
--
-- bla bla
--
-- @field #AIRBOSS
AIRBOSS = {
  ClassName    = "AIRBOSS",
  lid          = nil,
  Debug        = true,
  carrier      = nil,
  carriertype  = nil,
  alias        = nil,
  beacon       = nil,
  TACANchannel = nil,
  TACANmode    = nil,
  ICLSchannel  = nil,
  LSOradio     = nil,
  LSOfreq      = nil,
  Carrierradio = nil,
  Carrierfreq  = nil,
  registerZone = nil,
  startZone    = nil,
  giantZone    = nil,
  players      =  {},
  menuadded    =  {},
  Upwind       =  {},
  Abeam        =  {},
  BreakEarly   =  {},
  BreakLate    =  {},
  Ninety       =  {},
  Wake         =  {},
  Groove       =  {},
  Trap         =  {},
  rwyangle     = -10,
  sterndist    =-100,
  deckheight   =  22,
  Qpattern     =  {},
  Qmarshal     =  {},
}

--- Aircraft types.
-- @type AIRBOSS.AircraftType
-- @field #string AV8B AV-8B Night Harrier.
-- @field #string HORNET F/A-18C Lot 20 Hornet.
AIRBOSS.AircraftType={
  AV8B="AV8BNA",
  HORNET="FA-18C_hornet",
}

--- Carrier types.
-- @type AIRBOSS.CarrierType
-- @field #string STENNIS USS John C. Stennis (CVN-74)
-- @field #string VINSON USS Carl Vinson (CVN-70)
-- @field #string TARAWA USS Tarawa (LHA-1)
-- @field #string KUZNETSOV Admiral Kuznetsov (CV 1143.5)
AIRBOSS.CarrierType={
  STENNIS="Stennis",
  VINSON="Vinson",
  TARAWA="LHA_Tarawa",
  KUZNETSOV="KUZNECOW"
}

--- Pattern steps.
-- @type AIRBOSS.PatternStep
AIRBOSS.PatternStep={
  UNREGISTERED="Unregistered",
  PATTERNENTRY="Pattern Entry",
  EARLYBREAK="Early Break",
  LATEBREAK="Late Break",
  ABEAM="Abeam",
  NINETY="Ninety",
  WAKE="Wake",
  GROOVE_X0="Groove Entry",
  GROOVE_XX="Groove X",
  GROOVE_RB="Groove Roger Ball",
  GROOVE_IM="Groove In the Middle",
  GROOVE_IC="Groove In Close",
  GROOVE_AR="Groove At the Ramp",
  GROOVE_IW="Groove In the Wires",
}

--- LSO calls.
-- @type AIRBOSS.LSOcall
-- @field Core.UserSound#USERSOUND RIGHTFORLINEUPL "Right for line up!" call (loud).
-- @field Core.UserSound#USERSOUND RIGHTFORLINEUPS "Right for line up." call.
-- @field #string RIGHTFORLINEUPT "Right for line up" text.
-- @field Core.UserSound#USERSOUND COMELEFTL "Come left!" call (loud).
-- @field Core.UserSound#USERSOUND COMELEFTS "Come left." call.
-- @field #string COMELEFTT "Come left" text.
-- @field Core.UserSound#USERSOUND HIGHL "You're high!" call (loud).
-- @field Core.UserSound#USERSOUND HIGHS "You're high." call.
-- @field #string HIGHT "You're high" text.
-- @field Core.UserSound#USERSOUND POWERL "Power!" call (loud).
-- @field Core.UserSound#USERSOUND POWERS "Power." call.
-- @field #string POWERT "Power" text.
-- @field Core.UserSound#USERSOUND CALLTHEBALL "Call the ball." call.
-- @field #string CALLTHEBALLT "Call the ball." text.
-- @field Core.UserSound#USERSOUND ROGERBALL "Roger, ball." call.
-- @field #string ROGERBALLT "Roger, ball." text.
-- @field Core.UserSound#USERSOUND WAVEOFF "Wave off!" call.
-- @field #string WAVEOFFT "Wave off!" text.
-- @field Core.UserSound#USERSOUND BOLTER "Bolter, bolter!" call.
-- @field #string BOLTERT "Bolter, bolter!" text.
-- @field Core.UserSound#USERSOUND LONGGROOVE "You're long in the groove. Depart and re-enter." call.
-- @field #string LONGGROOVET "You're long in the groove. Depart and re-enter." text.
AIRBOSS.LSOcall={
  RIGHTFORLINEUPL=USERSOUND:New("LSO - RightLineUp(L).ogg"),
  RIGHTFORLINEUPS=USERSOUND:New("LSO - RightLineUp(S).ogg"),
  RIGHTFORLINEUPT="Right for line up",
  COMELEFTL=USERSOUND:New("LSO - ComeLeft(L).ogg"),
  COMELEFTS=USERSOUND:New("LSO - ComeLeft(S).ogg"),
  COMELEFTT="Come left",
  HIGHL=USERSOUND:New("LSO - High(L).ogg"),
  HIGHS=USERSOUND:New("LSO - High(S).ogg"),
  HIGHT="You're high",
  POWERL=USERSOUND:New("LSO - Power(L).ogg"),
  POWERS=USERSOUND:New("LSO - Power(S).ogg"),
  POWERT="Power",
  CALLTHEBALL=USERSOUND:New("LSO - Call the Ball.ogg"),
  CALLTHEBALLT="Call the ball.",
  ROGERBALL=USERSOUND:New("LSO - Roger.ogg"),
  ROGERBALLT="Roger ball!",
  WAVEOFF=USERSOUND:New("LSO - WaveOff.ogg"),
  WAVEOFFT="Wave off!",
  BOLTER=USERSOUND:New("LSO - Bolter.ogg"),
  BOLTERT="Bolter, Bolter!",
  LONGGROOVE=USERSOUND:New("LSO - Long in Groove.ogg"),
  LONGGROOVET="You're long in the groove. Depart and re-enter.",
}

--- Difficulty level.
-- @type AIRBOSS.Difficulty
-- @field #string EASY Easy difficulty: error margin 10 for high score and 20 for low score. No score for deviation >20.
-- @field #string NORMAL Normal difficulty: error margin 5 deviation from ideal for high score and 10 for low score. No score for deviation >10.
-- @field #string HARD Hard difficulty: error margin 2.5 deviation from ideal value for high score and 5 for low score. No score for deviation >5.
AIRBOSS.Difficulty={
  EASY="Flight Student",
  NORMAL="Naval Aviator",
  HARD="TOPGUN Graduate",
}

--- Groove position.
-- @type AIRBOSS.GroovePos
-- @field #string X0 Entering the groove.
-- @field #string XX At the start, i.e. 3/4 from the run down.
-- @field #string RB Roger ball.
-- @field #string IM In the middle.
-- @field #string IC In close.
-- @field #string AR At the ramp.
-- @field #string IW In the wires.
AIRBOSS.GroovePos={
  X0="X0",
  XX="X",
  RB="RB",
  IM="IM",
  IC="IC",
  AR="AR",
  IW="IW",
}

--- Groove data.
-- @type AIRBOSS.GrooveData
-- @field #number Step Current step.
-- @field #number AoA Angle of Attack.
-- @field #number Alt Altitude in meters.
-- @field #number GSE Glide slope error in degrees.
-- @field #number LUE Lineup error in degrees.
-- @field #number Roll Roll angle.

--- LSO grade
-- @type AIRBOSS.LSOgrade
-- @field #string grade LSO grade, i.e. _OK_, OK, (OK), --, CUT
-- @field #number points Points received.
-- @field #string details Detailed flight analyis analysis.

--- Player data table holding all important parameters of each player.
-- @type AIRBOSS.PlayerData
-- @field Wrapper.Client#CLIENT client Client object of player.
-- @field Wrapper.Unit#UNIT unit Aircraft of the player.
-- @field Wrapper.Group#GROUP group Aircraft group the player is in.
-- @field #string callsign Callsign of player.
-- @field #string difficulty Difficulty level.
-- @field #number passes Number of passes.
-- @field #boolean attitudemonitor If true, display aircraft attitude and other parameters constantly.
-- @field #table debrief Debrief analysis of the current step of this pass.
-- @field #table grades LSO grades of player passes.
-- @field #boolean inbigzone If true, player is in the big zone.
-- @field #boolean landed If true, player landed or attempted to land.
-- @field #boolean bolter If true, LSO told player to bolter.
-- @field #boolean boltered If true, player boltered.
-- @field #boolean waveoff If true, player was waved off during final approach.
-- @field #boolean patternwo If true, player was waved of during the pattern.
-- @field #boolean lig If true, player was long in the groove.
-- @field #number Tlso Last time the LSO gave an advice.
-- @field #AIRBOSS.GroovePos groove Data table at each position in the groove. Elemets are of type @{#AIRBOSS.GrooveData}.

--- Checkpoint parameters triggering the next step in the pattern.
-- @type AIRBOSS.Checkpoint
-- @field #string name Name of checkpoint.
-- @field #number Xmin Minimum allowed longitual distance to carrier.
-- @field #number Xmax Maximum allowed longitual distance to carrier.
-- @field #number Zmin Minimum allowed latitudal distance to carrier.
-- @field #number Zmax Maximum allowed latitudal distance to carrier.
-- @field #number LimitXmin Latitudal threshold for triggering the next step if X<Xmin.
-- @field #number LimitXmax Latitudal threshold for triggering the next step if X>Xmax.
-- @field #number LimitZmin Latitudal threshold for triggering the next step if Z<Zmin.
-- @field #number LimitZmax Latitudal threshold for triggering the next step if Z>Zmax.
-- @field #number Altitude Optimal altitude at this point.
-- @field #number AoA Optimal AoA at this point.
-- @field #number Distance Optimal distance at this point.
-- @field #number Speed Optimal speed at this point.
-- @field #table Checklist Table of checklist text items to display at this point.

--- Main radio menu.
-- @field #table MenuF10
AIRBOSS.MenuF10={}

--- Carrier trainer class version.
-- @field #string version
AIRBOSS.version="0.2.1w"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: Add scoring to radio menu.
-- DONE: Optimized debrief.
-- DONE: Add automatic grading.
-- TODO: Get board numbers.
-- TODO: Get fuel state in pounds.
-- TODO: Add user functions.
-- TODO: Generalize parameters for other carriers.
-- TODO: Generalize parameters for other aircraft.
-- TODO: CASE II.
-- TODO: CASE III.
-- TODO: Foul deck check.
-- DONE: Fix radio menu.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create new carrier trainer.
-- @param #AIRBOSS self
-- @param carriername Name of the aircraft carrier unit as defined in the mission editor.
-- @param alias (Optional) Alias for the carrier. This will be used for radio messages and the F10 radius menu. Default is the carrier name as defined in the mission editor.
-- @return #AIRBOSS self or nil if carrier unit does not exist.
function AIRBOSS:New(carriername, alias)

  -- Inherit everthing from FSM class.
  local self = BASE:Inherit(self, FSM:New()) -- #AIRBOSS

  -- Set carrier unit.
  self.carrier=UNIT:FindByName(carriername)
  
  if self.carrier then
    -- Carrier zones.
    self.registerZone = ZONE_UNIT:New("registerZone", self.carrier,  2500, {dx = -5000, dy = 100, relative_to_unit=true})
    self.startZone    = ZONE_UNIT:New("startZone",    self.carrier,  1000, {dx = -2000, dy = 100, relative_to_unit=true})
    self.giantZone    = ZONE_UNIT:New("giantZone",    self.carrier, 30000, {dx =  0,    dy = 0,   relative_to_unit=true})
  else
    -- Carrier unit does not exist error.
    local text=string.format("ERROR: Carrier unit %s could not be found! Make sure this UNIT is defined in the mission editor and check the spelling of the unit name carefully.", carriername)
    MESSAGE:New(text, 120):ToAll()
    self:E(text)
    return nil
  end
      
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("AIRBOSS %s | ", carriername)
  
  -- Get carrier type.
  self.carriertype=self.carrier:GetTypeName()
  
  -- Set alias.
  self.alias=alias or carriername
  
  -- Get carrier group template.
  local grouptemplate=self.carrier:GetGroup():GetTemplate()
  -- TODO: Now I need to get TACAN and ICLS if they were set in the ME.
  
  -- Create carrier beacon.
  self.beacon=BEACON:New(self.carrier)
  
  self.Carrierradio=RADIO:New(self.carrier)
  self.LSOradio=RADIO:New(self.carrier)
  
  if self.carriertype==AIRBOSS.CarrierType.STENNIS then
    self:_InitStennis()
  elseif self.carriertype==AIRBOSS.CarrierType.VINSON then
    -- TODO: Carl Vinson parameters.
    self:_InitStennis()
  elseif self.carriertype==AIRBOSS.CarrierType.TARAWA then
    -- TODO: Tarawa parameters.
    self:_InitStennis()
  elseif self.carriertype==AIRBOSS.CarrierType.KUZNETSOV then
    -- TODO: Kusnetsov parameters - maybe...
    self:_InitStennis()
  else
    self:E(self.lid.."ERROR: Unknown carrier type!")
    return nil
  end
  
  -----------------------
  --- FSM Transitions ---
  -----------------------
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event   -->   To State
  self:AddTransition("Stopped",       "Start",      "Running")
  self:AddTransition("Running",       "Status",     "Running")
  self:AddTransition("Running",       "Stop",       "Stopped")


  --- Triggers the FSM event "Start" that starts the carrier trainer. Initializes parameters and starts event handlers.
  -- @function [parent=#AIRBOSS] Start
  -- @param #AIRBOSS self

  --- Triggers the FSM event "Start" after a delay that starts the carrier trainer. Initializes parameters and starts event handlers.
  -- @function [parent=#AIRBOSS] __Start
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop" that stops the carrier trainer. Event handlers are stopped.
  -- @function [parent=#AIRBOSS] Stop
  -- @param #AIRBOSS self

  --- Triggers the FSM event "Stop" that stops the carrier trainer after a delay. Event handlers are stopped.
  -- @function [parent=#AIRBOSS] __Stop
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set TACAN channel of carrier.
-- @param #AIRBOSS self
-- @param #number channel TACAN channel.
-- @param #string mode TACAN mode, i.e. "X" or "Y".
-- @return #AIRBOSS self
function AIRBOSS:SetTACAN(channel, mode)

  self.TACANchannel=channel
  self.TACANmode=mode or "X"

  return self
end

--- Set ICLS channel of carrier.
-- @param #AIRBOSS self
-- @param #number channel ICLS channel.
-- @return #AIRBOSS self
function AIRBOSS:SetICLS(channel)

  self.ICLSchannel=channel

  return self
end


--- Set LSO radio frequency.
-- @param #AIRBOSS self
-- @param #number freq Frequency in MHz.
-- @return #AIRBOSS self
function AIRBOSS:SetLSOradio(freq)

  self.LSOfreq=freq

  return self
end

--- Set carrier radio frequency.
-- @param #AIRBOSS self
-- @param #number freq Frequency in MHz.
-- @return #AIRBOSS self
function AIRBOSS:SetCarrierradio(freq)

  self.Carrierfreq=freq

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM states
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the warehouse. Addes event handlers and schedules status updates of reqests and queue.
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AIRBOSS:onafterStart(From, Event, To)

  -- Events are handled my MOOSE.
  self:I(self.lid..string.format("Starting Carrier Training %s for carrier unit %s of type %s.", AIRBOSS.version, self.carrier:GetName(), self.carriertype))
  
  -- Activate TACAN.
  if self.TACANchannel~=nil and self.TACANmolde~=nil then
    self.beacon:ActivateTACAN(self.TACANchannel, self.TACANmode, "STN", true)
  end
  
  -- Activate ICLS.
  if self.ICLSchannel then
    self.beacon:ActivateICLS(self.ICLSchannel, "STN")
  end  
    
  -- Handle events.
  self:HandleEvent(EVENTS.Birth)
  self:HandleEvent(EVENTS.Land)
  --self:HandleEvent(EVENTS.Crash)

  -- Init status check
  self:__Status(1)
end

--- On after Status event. Checks player status.
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AIRBOSS:onafterStatus(From, Event, To)

  -- Check player status.
  self:_CheckPlayerStatus()

  -- Call status again in 0.25 seconds.
  self:__Status(-0.25)
end

--- On after Stop event. Unhandle events and stop status updates. 
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AIRBOSS:onafterStop(From, Event, To)
  self:UnHandleEvent(EVENTS.Birth)
  self:UnHandleEvent(EVENTS.Land)
end

--- Carrier trainer event handler for event birth.
-- @param #AIRBOSS self
function AIRBOSS:_CheckPlayerStatus()

  -- Loop over all players.
  for _playerName,_playerData in pairs(self.players) do  
    local playerData = _playerData --#AIRBOSS.PlayerData
    
    if playerData then
    
      -- Player unit.
      local unit = playerData.unit
      
      if unit:IsAlive() then
      
        -- Display aircraft attitude and other parameters as message text.
        if playerData.attitudemonitor then
          self:_DetailedPlayerStatus(playerData)
        end

        if unit:IsInZone(self.giantZone) then
          
          -- Check if player was previously not inside the zone.
          if playerData.inbigzone==false then
          
            -- Welcome player once he enters the carrier zone.
            local text=string.format("Welcome back, %s! TCN 74X, ICLS 1, BRC 354 (MAG HDG).\n", playerData.callsign)
            
            -- Heading and distance to register for approach.
            local heading=playerData.unit:GetCoordinate():HeadingTo(self.registerZone:GetCoordinate())
            local distance=playerData.unit:GetCoordinate():Get2DDistance(self.registerZone:GetCoordinate())
            
            -- Send message.
            text=text..string.format("Fly heading %d for %.1f NM and turn to BRC.", heading, distance)
            MESSAGE:New(text, 5):ToClient(playerData.client)
          
          end
                 
          if playerData.step==0 and unit:InAir() then
            -- New approach.
            self:_NewRound(playerData)
            
            -- Jump to Groove for testing.
            if self.groovedebug then     
              playerData.step=90
              self.groovedebug=false
            end
          elseif playerData.step == 1 then
            -- Entering the pattern.
            self:_Start(playerData)
          elseif playerData.step == 2 then
            -- Upwind leg.
            self:_Upwind(playerData)
          elseif playerData.step == 3 then
            -- Early break.
            self:_Break(playerData, "early")
          elseif playerData.step == 4 then
            -- Late break.
            self:_Break(playerData, "late")
          elseif playerData.step == 5 then
            -- Abeam position.
            self:_Abeam(playerData)
          elseif playerData.step == 6 then
            -- Check long down wind leg.
            self:_CheckForLongDownwind(playerData)
            -- At the ninety.
            self:_Ninety(playerData)
          elseif playerData.step==7 then
            -- In the wake.
            self:_Wake(playerData)
          elseif playerData.step==90 then
            -- Entering the groove.
            self:_Groove(playerData)
          elseif playerData.step>=91 and playerData.step<=99 then
            -- In the groove.
            self:_CallTheBall(playerData)
          elseif playerData.step==999 then
            -- Debriefing.
            SCHEDULER:New(nil, self._Debrief, {self, playerData}, 10)
            playerData.step=-1
          end
          
        else
          playerData.inbigzone=false
        end
        
      else
        -- Unit not alive.
        self:E(self.lid.."WARNING: Player unit is not alive!")
      end
    end
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EVENT functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Carrier trainer event handler for event birth.
-- @param #AIRBOSS self
-- @param Core.Event#EVENTDATA EventData
function AIRBOSS:OnEventBirth(EventData)
  self:F3({eventbirth = EventData})
  
  local _unitName=EventData.IniUnitName
  local _unit, _playername=self:_GetPlayerUnitAndName(_unitName)
  
  self:T3(self.lid.."BIRTH: unit   = "..tostring(EventData.IniUnitName))
  self:T3(self.lid.."BIRTH: group  = "..tostring(EventData.IniGroupName))
  self:T3(self.lid.."BIRTH: player = "..tostring(_playername))
      
  if _unit and _playername then
  
    local _uid=_unit:GetID()
    local _group=_unit:GetGroup()
    local _callsign=_unit:GetCallsign()
    
    -- Debug output.
    local text=string.format("Player %s, callsign %s entered unit %s (ID=%d) of group %s", _playername, _callsign, _unitName, _uid, _group:GetName())
    self:T(self.lid..text)
    MESSAGE:New(text, 5):ToAllIf(self.Debug)
    
    
    local rightaircraft=false
    local aircraft=_unit:GetTypeName()
    for _,actype in pairs(AIRBOSS.AircraftType) do
      if actype==aircraft then
        rightaircraft=true
      end
    end
    if rightaircraft==false then
      self:E(string.format("Player aircraft %s not supported of CARRIERTRAINTER.", aircraft))
      return
    end
        
    -- Add Menu commands.
    self:_AddF10Commands(_unitName)
    
    -- Init player data.
    self.players[_playername]=self:_InitPlayer(_unitName)
    
    -- Start in the groove for debugging.
    self.groovedebug=false
    
  end 
end

--- Carrier trainer event handler for event land.
-- @param #AIRBOSS self
-- @param Core.Event#EVENTDATA EventData
function AIRBOSS:OnEventLand(EventData)
  self:F3({eventland = EventData})
  
  local _unitName=EventData.IniUnitName
  local _unit, _playername=self:_GetPlayerUnitAndName(_unitName)
  
  self:T3(self.lid.."LAND: unit   = "..tostring(EventData.IniUnitName))
  self:T3(self.lid.."LAND: group  = "..tostring(EventData.IniGroupName))
  self:T3(self.lid.."LAND: player = "..tostring(_playername))
      
  if _unit and _playername then
  
    local _uid=_unit:GetID()
    local _group=_unit:GetGroup()
    local _callsign=_unit:GetCallsign()
    
    -- Debug output.
    local text=string.format("Player %s, callsign %s unit %s (ID=%d) of group %s landed.", _playername, _callsign, _unitName, _uid, _group:GetName())
    self:T(self.lid..text)
    MESSAGE:New(text, 5):ToAllIf(self.Debug)
    
    -- Player data.
    local playerData=self.players[_playername] --#AIRBOSS.PlayerData
    
    -- Coordinate at landing event
    local coord=playerData.unit:GetCoordinate()
    
    -- Debug mark of player landing coord.
    local lp=coord:MarkToAll("Landing coord.")
    coord:SmokeGreen()
    
    -- Debug marks of wires.
    local w1=self.carrier:GetCoordinate():Translate(-104, 0):MarkToAll("Wire 1")
    local w2=self.carrier:GetCoordinate():Translate( -92, 0):MarkToAll("Wire 2")
    local w3=self.carrier:GetCoordinate():Translate( -80, 0):MarkToAll("Wire 3")
    local w4=self.carrier:GetCoordinate():Translate( -68, 0):MarkToAll("Wire 4")
    
    -- We did land.
    env.info("FF landed")
    playerData.landed=true
    
    playerData.step=-1
    
    --TODO: maybe check that we actually landed on the right carrier.
    
    -- Call trapped function in 3 seconds to make sure we did not bolter.
    SCHEDULER:New(nil, self._Trapped,{self, playerData, coord}, 3)
      
  end 
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CARRIER TRAINING functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Initialize player data.
-- @param #AIRBOSS self
-- @param #string unitname Name of the player unit.
-- @return #AIRBOSS.PlayerData Player data.
function AIRBOSS:_InitPlayer(unitname) 

  -- Player data.
  local playerData={} --#AIRBOSS.PlayerData
  
  -- Player unit, client and callsign.
  playerData.unit     = UNIT:FindByName(unitname)
  playerData.client   = CLIENT:FindByName(unitname, nil, true)
  playerData.callsign = playerData.unit:GetCallsign()
  
  -- Number of passes done by player.
  playerData.passes=playerData.passes or 0
    
  -- LSO grades.
  playerData.grades=playerData.grades or {}
  
  -- Attitude monitor.
  playerData.attitudemonitor=false
  
  -- Set difficulty level.
  playerData.difficulty=playerData.difficulty or AIRBOSS.Difficulty.NORMAL
  
  -- Player is in the big zone around the carrier.
  playerData.inbigzone=playerData.unit:IsInZone(self.giantZone)

  -- Init stuff for this round.
  playerData=self:_InitNewRound(playerData)
  
  return playerData
end

--- Initialize new approach for player by resetting parmeters to initial values.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @return #AIRBOSS.PlayerData Initialized player data.
function AIRBOSS:_InitNewRound(playerData)
  self:I(self.lid..string.format("New round for player %s.", playerData.callsign))
  playerData.step=0
  playerData.groove={}
  playerData.debrief={}
  playerData.patternwo=false
  playerData.lig=false
  playerData.waveoff=false
  playerData.bolter=false
  playerData.boltered=false
  playerData.landed=false
  playerData.Tlso=timer.getTime()
  return playerData
end

--- Initialize player data.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
function AIRBOSS:_NewRound(playerData) 
    
  if playerData.unit:IsInZone(self.registerZone) then
    local text="Cleared for approach."
    self:_SendMessageToPlayer(text, 10, playerData)
  
    self:_InitNewRound(playerData)
  
    -- Next step: start of pattern.
    playerData.step=1
  end
end

--- Start pattern when player enters the start zone.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Start(playerData)

  -- Check if player is in start zone and about to enter the pattern.
  if playerData.unit:IsInZone(self.startZone) then
  
    -- Inform player.
    local hint = string.format("Entering the pattern.")
    if playerData.difficulty==AIRBOSS.Difficulty.EASY then
      hint=hint.."Aim for 800 feet and 350 kts at the break entry."
    end
    
    -- Send message.
    self:_SendMessageToPlayer(hint, 8, playerData)
  
    -- Next step: upwind.
    playerData.step=2
  end
  
end 

--- Upwind leg.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Upwind(playerData)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z = self:_GetDistances(playerData.unit)
  
  -- Abort condition check.
  if self:_CheckAbort(X, Z, self.Upwind) then
    self:_AbortPattern(playerData, X, Z, self.Upwind)
    return
  end
  
  -- Check if we are in front of the boat (diffX > 0).
  if self:_CheckLimits(X, Z, self.Upwind) then
  
    -- Get altitiude.
    local altitude=playerData.unit:GetAltitude()
  
    -- Get altitude.
    local hint, debrief=self:_AltitudeCheck(playerData, self.Upwind, altitude)
        
    -- Message to player
    self:_SendMessageToPlayer(hint, 10, playerData)
    
    -- Debrief.
    self:_AddToSummary(playerData, "Entering the Break", debrief)
    
    -- Next step.
    playerData.step=3
  end
end


--- Break.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #string part Part of the break.
function AIRBOSS:_Break(playerData, part)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z = self:_GetDistances(playerData.unit)
  
  -- Early or late break.  
  local breakpoint = self.BreakEarly
  if part=="late" then
    breakpoint = self.BreakLate
  end
    
  -- Check abort conditions.
  if self:_CheckAbort(X, Z, breakpoint) then
    self:_AbortPattern(playerData, X, Z, breakpoint)
    return
  end

  -- Check limits.
  if self:_CheckLimits(X, Z, breakpoint) then
  
    -- Get current altitude.
    local altitude=playerData.unit:GetAltitude()
  
    -- Grade altitude.
    local hint, debrief=self:_AltitudeCheck(playerData, breakpoint, altitude)
    
    -- Send message to player.
    self:_SendMessageToPlayer(hint, 10, playerData)

    -- Debrief
    if part=="late" then
      self:_AddToSummary(playerData, "Late Break", debrief)
    else
      self:_AddToSummary(playerData, "Early Break", debrief)
    end

    -- Next step: late break or abeam.
    if part=="early" then
      playerData.step = 4
    else
      playerData.step = 5
    end
  end
end

--- Long downwind leg check.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_CheckForLongDownwind(playerData)
  
  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z=self:_GetDistances(playerData.unit)

  -- Get relative heading.
  local relhead=self:_GetRelativeHeading(playerData.unit)

  -- One NM from carrier is too far.  
  local limit=UTILS.NMToMeters(-1.5)
  
  local text=string.format("Long groove check: X=%d, relhead=%.1f", X, relhead)
  self:T(text)
  --MESSAGE:New(text, 1):ToAllIf(self.Debug)
  
  -- Check we are not too far out w.r.t back of the boat.
  if X<limit then --and relhead<45 then
  
    -- Message to player.
    self:_SendMessageToPlayer(AIRBOSS.LSOcall.LONGGROOVET, 10, playerData)
    
    -- Sound output.
    AIRBOSS.LSOcall.LONGGROOVE:ToGroup(playerData.unit:GetGroup())
    
    -- Debrief.
    self:_AddToSummary(playerData, "Downwind", "Long in the groove.")
    
    --grade="LIG PATTERN WAVE OFF - CUT 1 PT"
    playerData.lig=true
    
    -- Next step: Debriefing.
    playerData.step=999
  end
  
end

--- Abeam.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Abeam(playerData)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z = self:_GetDistances(playerData.unit)
  
  -- Check abort conditions.
  if self:_CheckAbort(X, Z, self.Abeam) then
    self:_AbortPattern(playerData, X, Z, self.Abeam)
    return
  end

  -- Check nest step threshold.  
  if self:_CheckLimits(X, Z, self.Abeam) then

    -- Get AoA and altitude.
    local aoa = playerData.unit:GetAoA()
    local alt = playerData.unit:GetAltitude()
    
    -- Grade Altitude.
    local hintAlt, debriefAlt=self:_AltitudeCheck(playerData, self.Abeam, alt)
    
    -- Grade AoA.
    local hintAoA, debriefAoA=self:_AoACheck(playerData, self.Abeam, aoa)    
    
    -- Grade distance to carrier.
    local hintDist, debriefDist=self:_DistanceCheck(playerData, self.Abeam, math.abs(Z))
    
    -- Compile full hint.
    local hint=string.format("%s\n%s\n%s", hintAlt, hintAoA, hintDist)
    local debrief=string.format("%s\n%s\n%s", debriefAlt, debriefAoA, debriefDist)
    
    -- Send message to playerr.
    self:_SendMessageToPlayer(hint, 10, playerData)
    
    -- Add to debrief.
    self:_AddToSummary(playerData, "Abeam Position", debrief)
    
    -- Next step: ninety.
    playerData.step=6
  end
end

--- Ninety.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Ninety(playerData) 
  
  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z = self:_GetDistances(playerData.unit)
  
  -- Check abort conditions.
  if self:_CheckAbort(X, Z, self.Ninety) then
    self:_AbortPattern(playerData, X, Z, self.Ninety)
    return
  end
  
  -- Get Realtive heading player to carrier.
  local relheading=self:_GetRelativeHeading(playerData.unit)
  
  -- At the 90, i.e. 90 degrees between player heading and BRC of carrier.
  if relheading<=90 then
  
    -- Get altitude and aoa.
    local alt=playerData.unit:GetAltitude()
    local aoa=playerData.unit:GetAoA()
    
    -- Grade altitude.
    local hintAlt, debriefAlt=self:_AltitudeCheck(playerData, self.Ninety, alt)
    
    -- Grade AoA.
    local hintAoA, debriefAoA=self:_AoACheck(playerData, self.Ninety, aoa)
    
    -- Compile full hint.
    local hint=string.format("%s\n%s", hintAlt, hintAoA)
    local debrief=string.format("%s\n%s", debriefAlt, debriefAoA)
    
    -- Message to player.
    self:_SendMessageToPlayer(hint, 10, playerData)
    
    -- Add to debrief.
    self:_AddToSummary(playerData, "At the 90", debrief)
    
    -- Next step: wake.
    playerData.step=7
    
  elseif relheading>90 and self:_CheckLimits(X, Z, self.Wake) then
    -- Message to player.
    self:_SendMessageToPlayer("You are already at the wake and have not passed the 90! Turn faster next time!", 10, playerData)
  end
end

--- Wake.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Wake(playerData) 

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z = self:_GetDistances(playerData.unit)
    
  -- Check abort conditions.
  if self:_CheckAbort(X, Z, self.Wake) then
    self:_AbortPattern(playerData, X, Z, self.Wake)
    return
  end
  
  -- Right behind the wake of the carrier dZ>0.
  if self:_CheckLimits(X, Z, self.Wake) then
  
    -- Get player altitude and AoA.
    local alt=playerData.unit:GetAltitude()
    local aoa=playerData.unit:GetAoA()
  
    -- Grade altitude.
    local hintAlt, debriefAlt=self:_AltitudeCheck(playerData, self.Wake, alt)
    
    -- Grade AoA.
    local hintAoA, debriefAoA=self:_AoACheck(playerData, self.Wake, aoa)

    -- Compile full hint.
    local hint=string.format("%s\n%s", hintAlt, hintAoA)
    local debrief=string.format("%s\n%s", debriefAlt, debriefAoA)
    
    -- Message to player.
    self:_SendMessageToPlayer(hint, 10, playerData)
    
    -- Add to debrief.
    self:_AddToSummary(playerData, "At the Wake", debrief)

    -- Next step: Groove.
    playerData.step=90
  end
end

--- Entering the Groove.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Groove(playerData)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi = self:_GetDistances(playerData.unit)

  -- In front of carrier or more than 4 km behind carrier. 
  if self:_CheckAbort(X, Z, self.Groove) then
    self:_AbortPattern(playerData, X, Z, self.Groove)
    return
  end
   
  local relhead=self:_GetRelativeHeading(playerData.unit)+self.rwyangle
  local lineup=self:_Lineup(playerData)-self.rwyangle
  local roll=playerData.unit:GetRoll()
  
  env.info(string.format("FF relhead=%d  lineup=%d  roll=%d", relhead, lineup, roll))
  
  if math.abs(lineup)<5 and math.abs(relhead)<10 then

    -- Get player altitude and AoA.
    local alt = playerData.unit:GetAltitude()
    local aoa = playerData.unit:GetAoA()

    -- Grade altitude.
    local hintAlt, debriefAlt=self:_AltitudeCheck(playerData, self.Groove, alt)

    -- AoA feed back 
    local hintAoA, debriefAoA=self:_AoACheck(playerData, self.Groove, aoa)
    
    -- Compile full hint.
    local hint=string.format("%s\n%s", hintAlt, hintAoA)
    local debrief=string.format("%s\n%s", debriefAlt, debriefAoA)
    
    -- Message to player.
    self:_SendMessageToPlayer(hint, 10, playerData)

    -- Add to debrief.
    self:_AddToSummary(playerData, "Enter Groove", debrief)
    
    -- Gather pilot data.
    local groovedata={} --#AIRBOSS.GrooveData
    groovedata.Step=playerData.step
    groovedata.Alt=alt
    groovedata.AoA=aoa
    groovedata.GSE=self:_Glideslope(playerData)-3.5
    groovedata.LUE=self:_Lineup(playerData)-self.rwyangle
    groovedata.Roll=roll
        
    -- Groove 
    playerData.groove.X0=groovedata
    
    -- Next step: X start & call the ball.
    playerData.step=91
  end

end


--- Call the ball, i.e. 3/4 NM distance between aircraft and carrier.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_CallTheBall(playerData)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi = self:_GetDistances(playerData.unit)
  
  -- Player altitude
  local alt=playerData.unit:GetAltitude()
  
  -- Player group.
  local player=playerData.unit:GetGroup()

  -- Check abort conditions.
  if self:_CheckAbort(X, Z, self.Trap) then
    self:_AbortPattern(playerData, X, Z, self.Trap)
    return
  end

  -- Lineup with runway centerline.
  local lineup=self:_Lineup(playerData)
  local lineupError=lineup-self.rwyangle
  
  -- Glide slope.
  local glideslope=self:_Glideslope(playerData)
  local glideslopeError=glideslope-3.5   --TODO: maybe 3.0?
  
  -- Get AoA.
  local AoA=playerData.unit:GetAoA()
  
  -- Ranges in the groove.
  local RXX=UTILS.NMToMeters(0.750)+math.abs(self.sterndist) -- Start of groove.      0.75  = 1389 m
  local RRB=UTILS.NMToMeters(0.500)+math.abs(self.sterndist) -- Roger Ball! call.     0.5   =  926 m
  local RIM=UTILS.NMToMeters(0.375)+math.abs(self.sterndist) -- In the Middle 0.75/2. 0.375 =  695 m 
  local RIC=UTILS.NMToMeters(0.100)+math.abs(self.sterndist) -- In Close.             0.1   =  185 m
  local RAR=UTILS.NMToMeters(0.000)+math.abs(self.sterndist) -- At the Ramp.

  -- Data  
  local groovedata={} --#AIRBOSS.GrooveData
  groovedata.Step=playerData.step  
  groovedata.Alt=alt
  groovedata.AoA=AoA
  groovedata.GSE=glideslopeError
  groovedata.LUE=lineupError
  groovedata.Roll=playerData.unit:GetRoll()
  
  if rho<=RXX and playerData.step==91 then
  
    -- LSO "Call the ball" call.
    self:_SendMessageToPlayer("Call the ball.", 8, playerData)
    AIRBOSS.LSOcall.CALLTHEBALL:ToGroup(playerData.unit:GetGroup())
    playerData.Tlso=timer.getTime()
        
    -- Store data.
    playerData.groove.XX=groovedata
    
    -- Next step: roger ball.
    playerData.step=92    
  
  elseif rho<=RRB and playerData.step==92 then

    -- Pilot: "Roger ball" call.
    self:_SendMessageToPlayer(AIRBOSS.LSOcall.ROGERBALLT, 8, playerData)
    AIRBOSS.LSOcall.ROGERBALL:ToGroup(player)
    playerData.Tlso=timer.getTime()+1
    
    -- Store data.
    playerData.groove.RB=groovedata
    
    -- Next step: in the middle.
    playerData.step=93
    
  elseif rho<=RIM and playerData.step==93 then
  
    -- Debug.
    self:_SendMessageToPlayer("IM", 8, playerData)
    env.info(string.format("FF IM=%d", rho))
    
    -- Store data.
    playerData.groove.IM=groovedata    
    
    -- Next step: in close.
    playerData.step=94
  
  elseif rho<=RIC and playerData.step==94 then

    -- Check if player was already waved off.
    if playerData.waveoff==false then

      -- Debug
      self:_SendMessageToPlayer("IC", 8, playerData)
      env.info(string.format("FF IC=%d", rho))
      
      -- Store data.
      playerData.groove.IC=groovedata
      
      -- Check if player should wave off.
      local waveoff=self:_CheckWaveOff(glideslopeError, lineupError, AoA)
      
      -- Let's see..
      if waveoff then
              
        -- Wave off player.
        self:_SendMessageToPlayer(AIRBOSS.LSOcall.WAVEOFFT, 10, playerData)
        AIRBOSS.LSOcall.WAVEOFF:ToGroup(playerData.unit:GetGroup())
        playerData.Tlso=timer.getTime()
        
        -- Player was waved off!
        playerData.waveoff=true
              
        return
      else
        -- Next step: AR at the ramp.      
        playerData.step=95
      end
      
    end
    
  elseif rho<=RAR and playerData.step==95 then
  
    -- Debug.
    self:_SendMessageToPlayer("AR", 8, playerData)
    env.info(string.format("FF AR=%d", rho))
    
    -- Store data.
    playerData.groove.AR=groovedata
    
    -- Next step: in the wires.
    playerData.step=96
  end
  
  -- Time since last LSO call.
  local time=timer.getTime()
  local deltaT=time-playerData.Tlso
  
  -- Check if we are beween 3/4 NM and end of ship.
  if rho>=RAR and rho<RXX and deltaT>=3 then

    -- LSO call if necessary.
    self:_LSOcall(playerData, glideslopeError, lineupError)

  elseif X>100 then
           
    if playerData.landed then
      
      -- Add to debrief.
      if playerData.waveoff then
        self:_AddToSummary(playerData, "Wave Off", "You were waved off but landed anyway. Airboss wants to talk to you!")
      else
        self:_AddToSummary(playerData, "Bolter", "You boltered.")
      end
            
    else
      
      -- Add to debrief.
      self:_AddToSummary(playerData, "Wave Off", "You were waved off.")
      
      -- Next step: debrief.
      playerData.step=999
    end
  end 
end

--- LSO check if player needs to wave off.
-- Wave off conditions are:
-- 
-- * Glide slope error > 3 degrees.
-- * Line up error > 3 degrees.
-- * AoA<6.9 or AoA>9.3.
-- @param #AIRBOSS self
-- @param #number glideslopeError Glide slope error in degrees.
-- @param #number lineupError Line up error in degrees.
-- @param #number AoA Angle of attack of player aircraft.
-- @return #boolean If true, player should wave off!
function AIRBOSS:_CheckWaveOff(glideslopeError, lineupError, AoA)

  local waveoff=false
  
  -- Too high or too low?
  if math.abs(glideslopeError)>1 then
    self:I(self.lid.."Wave off due to glide slope error >1 degrees!")
    waveoff=true
  end
  
  -- Too far from centerline?
  if math.abs(lineupError)>3 then
    self:I(self.lid.."Wave off due to line up error >3 degrees!")
    waveoff=true
  end
  
  -- Too slow or too fast?
  if AoA<6.9 or AoA>9.3 then
    self:I(self.lid.."DEACTIVE! Wave off due to AoA<6.9 or AoA>9.3!")
    --waveoff=true
  end

  return waveoff
end

--- Get name of the current pattern step.
-- @param #AIRBOSS self
-- @param #number step Step
-- @return #string Name of the step
function AIRBOSS:_GS(step)
  local gp
  if step==90 then
    gp="X0"  -- Entering the groove.
  elseif step==91 then
    gp="X"  -- Starting the groove.
  elseif step==92 then
    gp="RB"  -- Roger ball call.
  elseif step==93 then
    gp="IM"  -- In the middle.
  elseif step==94 then
    gp="IC"  -- In close.
  elseif step==95 then
    gp="AR"  -- At the ramp.
  elseif step==96 then
    gp="IW"  -- In the wires.
  end
  return gp
end

--- Trapped?
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param Core.Point#COORDINATE pos Position of aircraft on landing event.
function AIRBOSS:_Trapped(playerData, pos)

  env.info("FF TRAPPED")

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi = self:_GetDistances(pos)
  
  if playerData.unit:InAir()==false then
    -- Seems we have successfully landed.
    
    -- Little offset for the exact wire positions.
    local wdx=11
    
    -- Which wire was caught?
    local wire
    if X<-104+wdx then
      wire=1
    elseif X<-92+wdx then
      wire=2
    elseif X<-80+wdx then
      wire=3
    elseif X<68+wdx then
      wire=4
    else
      wire=0
    end
       
    local text=string.format("TRAPPED! %d-wire.", wire)
    self:_SendMessageToPlayer(text, 10, playerData)
    
    local text2=string.format("Distance X=%.1f meters resulted in a %d-wire estimate.", X, wire)
    MESSAGE:New(text,30):ToAllIf(self.Debug)
    env.info(text2)
       
    local hint = string.format("Trapped catching the %d-wire.", wire)
    self:_AddToSummary(playerData, "Recovered", hint)
    
  else
    --Boltered!
    playerData.boltered=true
  end
  
  -- Next step: debriefing.
  playerData.step=999
end

--- Entering the Groove.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #number glideslopeError Error in degrees.
-- @param #number lineupError Error in degrees.
function AIRBOSS:_LSOcall(playerData, glideslopeError, lineupError)

  -- Player group.
  local player=playerData.unit:GetGroup()
  
  -- Glideslope high/low calls.
  local text=""
  if glideslopeError>1 then
    text="You're high!" 
    AIRBOSS.LSOcall.HIGHL:ToGroup(player)
  elseif glideslopeError>0.5 then
    text="You're a little high."
    AIRBOSS.LSOcall.HIGHS:ToGroup(player)
  elseif glideslopeError<-1.0 then
    text="Power!"
    AIRBOSS.LSOcall.POWERL:ToGroup(player)
  elseif glideslopeError<-0.5 then
    text="You're a little low."
    AIRBOSS.LSOcall.POWERS:ToGroup(player)
  else
    text="Good altitude."
  end

  text=text..string.format(" Glideslope Error = %.2f°", glideslopeError)
  text=text.."\n"
  
  local delay=0
  if math.abs(glideslopeError)>0.5 then
    --text=text.."\n"
    delay=1.5
  end
  
  -- Lineup left/right calls.
  if lineupError<-3 then
    text=text.."Come left!"
    AIRBOSS.LSOcall.COMELEFTL:ToGroup(player, delay)
  elseif lineupError<-1 then
    text=text.."Come left."
    AIRBOSS.LSOcall.COMELEFTS:ToGroup(player, delay)
  elseif lineupError>3 then
    text=text.."Right for lineup!"
    AIRBOSS.LSOcall.RIGHTFORLINEUPL:ToGroup(player, delay)
  elseif lineupError>1 then
    text=text.."Right for lineup."
    AIRBOSS.LSOcall.RIGHTFORLINEUPS:ToGroup(player, delay)
  else
    text=text.."Good lineup."
  end
  
  text=text..string.format(" Lineup Error = %.1f°\n", lineupError)
  
  -- Get AoA.
  local aoa=playerData.unit:GetAoA()
  
  if aoa>=9.3 then
    text=text.."Your're slow!"
  elseif aoa>=8.8 and aoa<9.3 then
    text=text.."Your're a little slow."
  elseif aoa>=7.4 and aoa<8.8 then
    text=text.."You're on speed."
  elseif aoa>=6.9 and aoa<7.4 then
    text=text.."You're a little fast."
  elseif aoa>=0 and aoa<6.9 then
    text=text.."You're fast!"
  else
    text=text.."Unknown AoA state."
  end
  
  text=text..string.format(" AoA = %.1f", aoa)
   
  -- LSO Message to player.
  self:_SendMessageToPlayer(text, 5, playerData, false)

  -- Set last time.
  playerData.Tlso=timer.getTime()   
end

--- Get glide slope of aircraft.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @return #number Glide slope angle in degrees measured from the 
function AIRBOSS:_Glideslope(playerData)

 -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi = self:_GetDistances(playerData.unit)

  -- Glideslope. Wee need to correct for the height of the deck. The ideal glide slope is 3.5 degrees.
  local h=playerData.unit:GetAltitude()-self.deckheight
  local x=math.abs(-86-X) --math.abs(self.sterndist-X) --TODO: maybe sterndist should be replaced by position of 3-wire!
  local glideslope=math.atan(h/x)  

  return math.deg(glideslope)
end

--- Get line up of player wrt to carrier runway.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @return #number Line up with runway heading in degrees. 0 degrees = perfect line up. +1 too far left. -1 too far right.
-- @return #number Distance from carrier tail to player aircraft in meters.
function AIRBOSS:_Lineup(playerData) 

 -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi = self:_GetDistances(playerData.unit)  
  
  -- Position at the end of the deck. From there we calculate the angle.
  local b={x=self.sterndist, z=0}
  
  -- Position of the aircraft wrt carrier coordinates.
  local a={x=X, z=Z}

  -- Vector from plane to ref point on boad.
  local c={x=b.x-a.x, y=0, z=b.z-a.z}
  
  -- Current line up and error wrt to final heading of the runway.
  local lineup=math.atan2(c.z, c.x)

  return math.deg(lineup), UTILS.VecNorm(c)
end


---------
-- Bla functions
---------

--- Append text to debrief text.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #string step Current step in the pattern.
-- @param #string item Text item appeded to the debrief.
function AIRBOSS:_AddToSummary(playerData, step, item)
  table.insert(playerData.debrief, {step=step, hint=item})
end

--- Show debriefing message.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
function AIRBOSS:_Debrief(playerData)
  env.info("FF debrief")

  -- Debriefing text.
  local text=string.format("Debriefing:\n")
  text=text..string.format("================================\n")
  for _,_data in pairs(playerData.debrief) do
    local step=_data.step
    local comment=_data.hint
    text=text..string.format("* %s:\n",step)
    text=text..string.format("%s\n", comment)
  end
  
  -- Send debrief message to player
  self:_SendMessageToPlayer(text, 30, playerData, true, "Paddles")
  
  -- LSO grade, points, and flight data analyis.
  local grade, points, analysis=self:_LSOgrade(playerData)
    
  local mygrade={} --#AIRBOSS.LSOgrade  
  mygrade.grade=grade
  mygrade.points=points
  mygrade.details=analysis
  
  -- Add to table.
  table.insert(playerData.grades, mygrade)
  
  -- LSO grade message.
  text=string.format("%s %.1f PT - %s", grade, points, analysis)
  self:_SendMessageToPlayer(text, 10, playerData, true, "Paddles", 30)

  -- New approach.
  if playerData.boltered or playerData.waveoff or playerData.patternwo then
    -- Get heading and distance to register zone ~3 NM astern.
    local heading=playerData.unit:GetCoordinate():HeadingTo(self.registerZone:GetCoordinate())
    local distance=playerData.unit:GetCoordinate():Get2DDistance(self.registerZone:GetCoordinate())
    local text=string.format("fly heading %d for %d NM to re-enter the pattern.", heading, UTILS.MetersToNM(distance))
    self:_SendMessageToPlayer(text, 10, playerData, false, nil, 30)
  end  
  
  -- Next step.
  playerData.step=0
end

--- Get relative heading of player wrt carrier.
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit Player unit.
-- @return #number Relative heading in degrees.
function AIRBOSS:_GetRelativeHeading(unit)
  local vC=self.carrier:GetOrientationX()
  local vP=unit:GetOrientationX()
  
  -- Get angle between the two orientation vectors in rad.
  local relHead=math.acos(UTILS.VecDot(vC,vP)/UTILS.VecNorm(vC)/UTILS.VecNorm(vP))
  
  -- Return heading in degrees.
  return math.deg(relHead)
end


--- Get name of the current pattern step.
-- @param #AIRBOSS self
-- @param #number step Step
-- @return #string Name of the step
function AIRBOSS:_StepName(step)

  local name="unknown"
  if step==0 then
    name="Unregistered"
  elseif step==1 then
    name="Pattern Entry"
  elseif step==2 then
    name="Break Entry"
  elseif step==3 then
    name="Early break"
  elseif step==4 then
    name="Late break"
  elseif step==5 then
    name="Abeam position"
  elseif step==6 then
    name="Ninety"
  elseif step==7 then
    name="Wake"
  elseif step==8 then
    name="unkown"
  elseif step==90 then
    name="Entering the Groove"
  elseif step==91 then
    name="Groove: X At the Start"
  elseif step==92 then
    name="Groove: Roger Ball"
  elseif step==93 then
    name="Groove: IM In the Middle"
  elseif step==94 then
    name="Groove: IC In Close"
  elseif step==95 then
    name="Groove: AR: At the Ramp"
  elseif step==96 then
    name="Groove: IW: In the Wires"
  end
  
  return name
end

--- Calculate distances between carrier and player unit.
-- @param #AIRBOSS self 
-- @param Wrapper.Unit#UNIT unit Player unit
-- @return #number Distance [m] in the direction of the orientation of the carrier.
-- @return #number Distance [m] perpendicular to the orientation of the carrier.
-- @return #number Distance [m] to the carrier.
-- @return #number Angle [Deg] from carrier to plane. Phi=0 if the plane is directly behind the carrier, phi=90 if the plane is starboard, phi=180 if the plane is in front of the carrier.
function AIRBOSS:_GetDistances(unit)

  -- Vector to carrier
  local a=self.carrier:GetVec3()
  
  -- Vector to player
  local b=unit:GetVec3()
  
  -- Vector from carrier to player.
  local c={x=b.x-a.x, y=0, z=b.z-a.z}
  
  -- Orientation of carrier.
  local x=self.carrier:GetOrientationX()
  
  -- Projection of player pos on x component.
  local dx=UTILS.VecDot(x,c)
  
  -- Orientation of carrier.
  local z=self.carrier:GetOrientationZ()
  
  -- Projection of player pos on z component.  
  local dz=UTILS.VecDot(z,c)
  
  -- Polar coordinates
  local rho=math.sqrt(dx*dx+dz*dz)
  local phi=math.deg(math.atan2(dz,dx))
  if phi<0 then
    phi=phi+360
  end
  -- phi=0 if the plane is directly behind the carrier, phi=180 if the plane is in front of the carrier
  phi=phi-180
  
  return dx,dz,rho,phi
end

--- Check if a player is within the right area.
-- @param #AIRBOSS self
-- @param #number X X distance player to carrier.
-- @param #number Z Z distance player to carrier.
-- @param #AIRBOSS.Checkpoint pos Position data limits.
-- @return #boolean If true, approach should be aborted.
function AIRBOSS:_CheckAbort(X, Z, pos)

  local abort=false
  if pos.Xmin and X<pos.Xmin then
    abort=true
  elseif pos.Xmax and X>pos.Xmax then
    abort=true
  elseif pos.Zmin and Z<pos.Zmin then
    abort=true
  elseif pos.Zmax and Z>pos.Zmax then
    abort=true
  end
  
  return abort
end

--- Generate a text if a player is too far from where he should be.
-- @param #AIRBOSS self
-- @param #number X X distance player to carrier.
-- @param #number Z Z distance player to carrier.
-- @param #AIRBOSS.Checkpoint posData Checkpoint data.
function AIRBOSS:_TooFarOutText(X, Z, posData)

  local text="You are too far "
  
  local xtext=nil
  if posData.Xmin and X<posData.Xmin then
    xtext="ahead"
  elseif posData.Xmax and X>posData.Xmax then
    xtext="behind"
  end
  
  local ztext=nil
  if posData.Zmin and Z<posData.Zmin then
    ztext="port (left)"
  elseif posData.Zmax and Z>posData.Zmax then
    ztext="starboard (right)"
  end
  
  if xtext and ztext then
    text=text..xtext.." and "..ztext
  elseif xtext then
    text=text..xtext
  elseif ztext then
    text=text..ztext
  end
  
  text=text.." of the carrier."
  
  return text
end

--- Pattern aborted.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #number X X distance player to carrier.
-- @param #number Z Z distance player to carrier.
-- @param #AIRBOSS.Checkpoint posData Checkpoint data.
function AIRBOSS:_AbortPattern(playerData, X, Z, posData)

  -- Text where we are wrong.
  local toofartext=self:_TooFarOutText(X, Z, posData)
  
  -- Send message to player.
  self:_SendMessageToPlayer(toofartext.." Depart and re-enter!", 15, playerData, true)
  
  -- Debug.
  local text=string.format("Abort: X=%d Xmin=%s, Xmax=%s | Z=%d Zmin=%s Zmax=%s", X, tostring(posData.Xmin), tostring(posData.Xmax), Z, tostring(posData.Zmin), tostring(posData.Zmax))
  self:E(self.lid..text)
  --MESSAGE:New(text, 60):ToAllIf(self.Debug)
  
  -- Add to debrief.
  self:_AddToSummary(playerData, string.format("%s", self:_StepName(playerData.step)), string.format("Pattern wave off: %s", toofartext))
  
  -- Pattern wave off!
  playerData.patternwo=true

  -- Next step debrief.  
  playerData.step=999
end


--- Provide info about player status on the fly.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
function AIRBOSS:_DetailedPlayerStatus(playerData)

  -- Player unit.
  local unit=playerData.unit
  
  -- Aircraft attitude.
  local aoa=unit:GetAoA()
  local yaw=unit:GetYaw()
  local roll=unit:GetRoll()
  local pitch=unit:GetPitch()
  
  -- Distance to the boat.
  local dist=playerData.unit:GetCoordinate():Get2DDistance(self.carrier:GetCoordinate())
  local dx,dz,rho,phi=self:_GetDistances(unit)

  -- Wind vector.
  local wind=unit:GetCoordinate():GetWindWithTurbulenceVec3()
  
  -- Aircraft veloecity vector.
  local velo=unit:GetVelocityVec3()
  
  -- Relative heading Aircraft to Carrier.
  local relhead=self:_GetRelativeHeading(playerData.unit)
 
  -- Output 
  local text=string.format("AoA=%.1f | Vx=%.1f Vy=%.1f Vz=%.1f\n", aoa, velo.x, velo.y, velo.z)  
  text=text..string.format("Pitch=%.1f° | Roll=%.1f° | Yaw=%.1f° | Climb=%.1f°\n", pitch, roll, yaw, unit:GetClimbAngle())
  text=text..string.format("Relheading=%.1f°\n", relhead)
  text=text..string.format("Distance: X=%d m Z=%d m | R=%d m Phi=%.1f\n", dx, dz, rho, phi)
  if playerData.step>=90 and playerData.step<=99 then
    local lineup=self:_Lineup(playerData)-self.rwyangle
    local glideslope=self:_Glideslope(playerData)-3.5
    text=text..string.format("Lineup Error = %.1f°\n", lineup)
    text=text..string.format("Glideslope Error = %.1f°\n", glideslope)
  end
  text=text..string.format("Current step: %s\n", self:_StepName(playerData.step))
  
  --text=text..string.format("Wind Vx=%.1f Vy=%.1f Vz=%.1f\n", wind.x, wind.y, wind.z)
  --text=text..string.format("rho=%.1f m phi=%.1f degrees\n", rho,phi)

  MESSAGE:New(text, 1, nil , true):ToClient(playerData.client)
end

--- Init parameters for USS Stennis carrier.
-- @param #AIRBOSS self
function AIRBOSS:_InitStennis()

  -- Carrier Parameters.
  self.rwyangle   = -10
  self.sterndist  =-150
  self.deckheight =  22
  self.wire1      =-100
  self.wire2      =-90
  self.wire3      =-80
  self.wire4      =-70

  --[[
  q0=self.carrier:GetCoordinate():SetAltitude(25)
  q0:BigSmokeSmall(0.1)
  q1=self.carrier:GetCoordinate():Translate(-104,0):SetAltitude(22)  --1st wire
  q1:BigSmokeSmall(0.1)--:SmokeGreen()
  q2=self.carrier:GetCoordinate():Translate(-68,0):SetAltitude(22)   --4th wire ==> distance between wires 12 m
  q2:BigSmokeSmall(0.1)--:SmokeBlue()
  ]]
  
  -- Upwind leg
  self.Upwind.name="Upwind"
  self.Upwind.Xmin=-4000  -- TODO Should be withing 4 km behind carrier. Why?
  self.Upwind.Xmax=nil
  self.Upwind.Zmin=0
  self.Upwind.Zmax=1200
  self.Upwind.LimitXmin=0
  self.Upwind.LimitXmax=nil
  self.Upwind.LimitZmin=0
  self.Upwind.LimitZmax=nil
  self.Upwind.Altitude=UTILS.FeetToMeters(800)
  self.Upwind.AoA=8.1
  self.Upwind.Distance=nil

  -- Early break
  self.BreakEarly.name="Early Break"
  self.BreakEarly.Xmin=-500
  self.BreakEarly.Xmax=UTILS.NMToMeters(5)
  self.BreakEarly.Zmin=-3700
  self.BreakEarly.Zmax=1500
  self.BreakEarly.LimitXmin=0
  self.BreakEarly.LimitXmax=nil
  self.BreakEarly.LimitZmin=-370   -- 0.2 NM port of carrier
  self.BreakEarly.LimitZmax=nil
  self.BreakEarly.Altitude=UTILS.FeetToMeters(800)
  self.BreakEarly.AoA=8.1
  self.BreakEarly.Distance=nil
  
  -- Late break
  self.BreakLate.name="Late Break"
  self.BreakLate.Xmin=-500
  self.BreakLate.Xmax=UTILS.NMToMeters(5)
  self.BreakLate.Zmin=-3700
  self.BreakLate.Zmax=1500
  self.BreakLate.LimitXmin=0
  self.BreakLate.LimitXmax=nil
  self.BreakLate.LimitZmin=-1470  --0.8 NM
  self.BreakLate.LimitZmax=nil
  self.BreakLate.Altitude=UTILS.FeetToMeters(800)
  self.BreakLate.AoA=8.1
  self.BreakLate.Distance=nil  
  
  -- Abeam position
  self.Abeam.name="Abeam Position"
  self.Abeam.Xmin=nil
  self.Abeam.Xmax=nil
  self.Abeam.Zmin=-4000
  self.Abeam.Zmax=-1000
  self.Abeam.LimitXmin=-200
  self.Abeam.LimitXmax=nil
  self.Abeam.LimitZmin=nil
  self.Abeam.LimitZmax=nil
  self.Abeam.Altitude=UTILS.FeetToMeters(600)  
  self.Abeam.AoA=8.1
  self.Abeam.Distance=UTILS.NMToMeters(1.2)

  -- At the ninety
  self.Ninety.name="Ninety"
  self.Ninety.Xmin=-4000
  self.Ninety.Xmax=0
  self.Ninety.Zmin=-3700
  self.Ninety.Zmax=nil
  self.Ninety.LimitXmin=nil
  self.Ninety.LimitXmax=nil
  self.Ninety.LimitZmin=nil
  self.Ninety.LimitZmax=-1111
  self.Ninety.Altitude=UTILS.FeetToMeters(500)
  self.Ninety.AoA=8.1
  self.Ninety.Distance=nil

  -- Wake position
  self.Wake.name="Wake"
  self.Wake.Xmin=-4000
  self.Wake.Xmax=0
  self.Wake.Zmin=-2000
  self.Wake.Zmax=nil
  self.Wake.LimitXmin=nil
  self.Wake.LimitXmax=nil
  self.Wake.LimitZmin=0
  self.Wake.LimitZmax=nil
  self.Wake.Altitude=UTILS.FeetToMeters(370)
  self.Wake.AoA=8.1
  self.Wake.Distance=nil

  -- In the groove
  self.Groove.name="Groove"
  self.Groove.Xmin=-4000
  self.Groove.Xmax=  100
  self.Groove.Zmin=-1000
  self.Groove.Zmax=nil
  self.Groove.LimitXmin=nil
  self.Groove.LimitXmax=nil
  self.Groove.LimitZmin=nil
  self.Groove.LimitZmax=nil
  self.Groove.Altitude=UTILS.FeetToMeters(300)
  self.Groove.AoA=8.1
  self.Groove.Distance=nil
  
  -- Landing trap
  self.Trap.name="Trap"
  self.Trap.Xmin=-3000
  self.Trap.Xmax=nil
  self.Trap.Zmin=-2000
  self.Trap.Zmax=2000
  self.Trap.LimitXmin=nil
  self.Trap.LimitXmax=nil
  self.Trap.LimitZmin=nil
  self.Trap.LimitZmax=nil
  self.Trap.Altitude=nil
  self.Trap.AoA=nil
  self.Trap.Distance=nil 

end

--- Check limits for reaching next step.
-- @param #AIRBOSS self
-- @param #number X X position of player unit.
-- @param #number Z Z position of player unit.
-- @param #AIRBOSS.Checkpoint check Checkpoint.
-- @return #boolean If true, checkpoint condition for next step was reached.
function AIRBOSS:_CheckLimits(X, Z, check)

  -- Limits
  local nextXmin=check.LimitXmin==nil or (check.LimitXmin and (check.LimitXmin<0 and X<=check.LimitXmin or check.LimitXmin>=0 and X>=check.LimitXmin))
  local nextXmax=check.LimitXmax==nil or (check.LimitXmax and (check.LimitXmax<0 and X>=check.LimitXmax or check.LimitXmax>=0 and X<=check.LimitXmax))
  local nextZmin=check.LimitZmin==nil or (check.LimitZmin and (check.LimitZmin<0 and Z<=check.LimitZmin or check.LimitZmin>=0 and Z>=check.LimitZmin))
  local nextZmax=check.LimitZmax==nil or (check.LimitZmax and (check.LimitZmax<0 and Z>=check.LimitZmax or check.LimitZmax>=0 and Z<=check.LimitZmax))
  
  -- Proceed to next step if all conditions are fullfilled.
  local next=nextXmin and nextXmax and nextZmin and nextZmax
  
  -- Debug info.
  local text=string.format("step=%s: next=%s: X=%d Xmin=%s Xmax=%s | Z=%d Zmin=%s Zmax=%s", 
  check.name, tostring(next), X, tostring(check.LimitXmin), tostring(check.LimitXmax), Z, tostring(check.LimitZmin), tostring(check.LimitZmax))
  self:T(self.lid..text)
  --MESSAGE:New(text, 1):ToAllIf(self.Debug)

  return next
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MISC functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Grade approach.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @return #string LSO grade, i.g. _OK_, OK, (OK), --, etc.
-- @return #number Points.
-- @return #string LSO analysis of flight path.
function AIRBOSS:_LSOgrade(playerData)
  
  local function count(base, pattern)
    return select(2, string.gsub(base, pattern, ""))
  end

  -- Analyse flight data and conver to LSO text.
  local GXX,nXX=self:_Flightdata2Text(playerData.groove.XX)
  local GIM,nIM=self:_Flightdata2Text(playerData.groove.IM)
  local GIC,nIC=self:_Flightdata2Text(playerData.groove.IC)
  local GAR,nAR=self:_Flightdata2Text(playerData.groove.AR)
  
  -- Put everything together.
  local G=GXX.." "..GIM.." ".." "..GIC.." "..GAR
  
  -- Ground number of minor, normal and major deviations.
  local N=nXX+nIM+nIC+nAR
  local nL=count(G, '_')/2
  local nS=count(G, '%(')
  local nN=N-nS-nL
  
  local grade
  local points
  if N==0 then
    -- No deviations, should be REALLY RARE!
    grade="_OK_"
    points=5.0
  else
    if nL>0 then
      -- Larger deviations ==> "No grade" 2.0 points.
      grade="--" 
      points=2.0
    elseif nN>0 then
      -- No larger but average deviations ==>  "Fair Pass" Pass with average deviations and corrections.
      grade="(OK)"
      points=3.0
    else
      -- Only minor corrections
      grade="OK"
      points=4.0
    end
  end
  
  -- Replace" )"( and "__" 
  G=G:gsub("%)%(", "")
  G=G:gsub("__","")  
  
  -- Debug info
  local text="LSO grade:\n"
  text=text..G.."\n"
  text=text.."Grade = "..grade.." points = "..points.."\n"
  text=text.."# of total deviations   = "..N.."\n"
  text=text.."# of large deviations _ = "..nL.."\n"
  text=text.."# of norma deviations _ = "..nN.."\n"
  text=text.."# of small deviations ( = "..nS.."\n"
  self:I(self.lid..text)
  
  if playerData.patternwo or playerData.waveoff then
    grade="CUT"
    points=1.0
    if playerData.lig then
      G="LIG PWO"
    elseif playerData.patternwo then
      G="PWO "..G
    end
    if playerData.landed then
      --AIRBOSS wants to talk to you!
    end
  elseif playerData.boltered then
    grade="-- (BOLTER)"
    points=2.5 
  end

  return grade, points, G
end

--- Grade flight data.
-- @param #AIRBOSS self
-- @param #AIRBOSS.GrooveData fdata Flight data in the groove.
-- @return #string LSO grade or empty string if flight data table is nil.
-- @return #number Number of deviations from perfect flight path.
function AIRBOSS:_Flightdata2Text(fdata)

  local function little(text)
    return string.format("(%s)",text)
  end
  local function underline(text)
    return string.format("_%s_", text)
  end

  -- No flight data ==> return empty string.
  if fdata==nil then
    self:E(self.lid.."Flight data is nil.")
    return "", 0
  end

  -- Flight data.
  local step=fdata.Step
  local AOA=fdata.AoA
  local GSE=fdata.GSE
  local LUE=fdata.LUE
  local ROL=fdata.Roll

  -- Speed.
  local S=nil
  if AOA>9.8 then
    S=underline("SLO")
  elseif AOA>9.3 then
    S="SLO"
  elseif AOA>8.8 then
    S=little("SLO")
  elseif AOA<6.4 then
    S=underline("F")
  elseif AOA<6.9 then
    S="F"
  elseif AOA<7.4 then
    S=little("F")
  end
  
  -- Alitude.
  local A=nil
  if GSE>1 then
    A=underline("H")
  elseif GSE>0.5 then
    A=little("H")
  elseif GSE>0.25 then
    A="H"
  elseif GSE<-1 then
    A=underline("LO")
  elseif GSE<-0.5 then
    A=little("LO")
  elseif GSE<-0.25 then
    A="LO"
  end
  
  -- Line up.
  local D=nil
  if LUE>3 then
    D=underline("LUL")
  elseif LUE>1 then
    D="LUL"
  elseif LUE>0.5 then
    D=little("LUL")
  elseif LUE<-3 then
    D=underline("LUR")
  elseif LUE<-1 then
    D="LUR"
  elseif LUE<-0.5 then
    D=little("LUR")
  end
  
  -- Compile.
  local G=""
  local n=0
  if S then
    G=G..S
    n=n+1
  end
  if A then
    G=G..A
    n=n+1
  end
  if D then
    G=G..D
    n=n+1
  end
  
  -- Add current step.
  local step=self:_GS(step)
  step=step:gsub("XX","X")
  if G~="" then
    G=G..step
  end
  
  -- Debug info.
  local text=string.format("LSO Grade at %s:\n", step)
  text=text..string.format("AOA=%.1f\n",AOA)
  text=text..string.format("GSE=%.1f\n",GSE)
  text=text..string.format("LUE=%.1f\n",LUE)
  text=text..string.format("ROL=%.1f\n",ROL)    
  text=text..G
  self:T(self.lid..text)
  
  return G,n
end

--- Evaluate player's altitude at checkpoint.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @return #number Low score.
-- @return #number Bad score.
function AIRBOSS:_GetGoodBadScore(playerData)

  local lowscore
  local badscore
  if playerData.difficulty==AIRBOSS.Difficulty.EASY then
    lowscore=10
    badscore=20    
  elseif playerData.difficulty==AIRBOSS.Difficulty.NORMAL then
    lowscore=5
    badscore=10     
  elseif playerData.difficulty==AIRBOSS.Difficulty.HARD then
    lowscore=2.5
    badscore=5
  end
  
  return lowscore, badscore
end

--- Evaluate player's altitude at checkpoint.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #AIRBOSS.Checkpoint checkpoint Checkpoint.
-- @param #number altitude Player's current altitude in meters.
-- @return #string Feedback text.
-- @return #string Debriefing text.
function AIRBOSS:_AltitudeCheck(playerData, checkpoint, altitude)

  -- Player altitude.
  local altitude=playerData.unit:GetAltitude()
  
  -- Get relative score.
  local lowscore, badscore=self:_GetGoodBadScore(playerData)
  
  -- Altitude error +-X%
  local _error=(altitude-checkpoint.Altitude)/checkpoint.Altitude*100
  
  local hint
  if _error>badscore then
    hint=string.format("You're high. ")
  elseif _error>lowscore then
    hint= string.format("You're slightly high. ")
  elseif _error<-badscore then
    hint=string.format("You're low. ")
  elseif _error<-lowscore then
    hint=string.format("You're slightly low. ")
  else
    hint=string.format("Good altitude. ")
  end
  
  -- Extend or decrease depending on skill.
  if playerData.difficulty==AIRBOSS.Difficulty.EASY then
    hint=hint..string.format("Optimal altitude is %d ft.", UTILS.MetersToFeet(checkpoint.Altitude))
  elseif playerData.difficulty==AIRBOSS.Difficulty.NORMAL then
    --hint=hint.."\n"
  elseif playerData.difficulty==AIRBOSS.Difficulty.HARD then
    hint=""
  end
  
  -- Debrief text.
  local debrief=string.format("Altitude %d ft = %d%% deviation from %d ft optimum.", UTILS.MetersToFeet(altitude), _error, UTILS.MetersToFeet(checkpoint.Altitude))
  
  return hint, debrief
end

--- Evaluate player's altitude at checkpoint.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #AIRBOSS.Checkpoint checkpoint Checkpoint.
-- @param #number distance Player's current distance to the boat in meters.
-- @return #string Feedback message text.
-- @return #string Debriefing text.
function AIRBOSS:_DistanceCheck(playerData, checkpoint, distance)

  -- Get relative score.
  local lowscore, badscore = self:_GetGoodBadScore(playerData)
  
  -- Altitude error +-X%
  local _error=(distance-checkpoint.Distance)/checkpoint.Distance*100
  
  local hint
  if _error>badscore then
    hint=string.format("You're too far from the boat! ")
  elseif _error>lowscore then 
    hint=string.format("You're slightly too far from the boat. ")
  elseif _error<-badscore then
    hint=string.format( "You're too close to the boat! ")
  elseif _error<-lowscore then
    hint=string.format("You're slightly too far from the boat. ")
  else
    hint=string.format("Perfect distance to the boat. ")
  end
  
  -- Extend or decrease depending on skill.
  if playerData.difficulty==AIRBOSS.Difficulty.EASY then
    hint=hint..string.format(" Optimal distance is %d NM.", UTILS.MetersToNM(checkpoint.Distance))
  elseif playerData.difficulty==AIRBOSS.Difficulty.NORMAL then
    --hint=hint.."\n"
  elseif playerData.difficulty==AIRBOSS.Difficulty.HARD then
    hint=""
  end

  -- Debriefing text.
  local debrief=string.format("Distance %.1f NM = %d%% deviation from %.1f NM optimum.",UTILS.MetersToNM(distance), _error, UTILS.MetersToNM(checkpoint.Distance))
   
  return hint, debrief
end

--- Score for correct AoA.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #AIRBOSS.Checkpoint checkpoint Checkpoint.
-- @param #number aoa Player's current Angle of attack.
-- @return #string Feedback message text or easy and normal difficulty level or nil for hard.
-- @return #string Debriefing text.
function AIRBOSS:_AoACheck(playerData, checkpoint, aoa)

  -- Get relative score.
  local lowscore, badscore = self:_GetGoodBadScore(playerData)
  
  -- Altitude error +-X%
  local _error=(aoa-checkpoint.AoA)/checkpoint.AoA*100

  local hint
  if _error>badscore then --Slow
    hint="You're slow. "
  elseif _error>lowscore then --Slightly slow
    hint="You're slightly slow. "
  elseif _error<-badscore then --Fast
    hint="You're fast. "
  elseif _error<-lowscore then --Slightly fast
    hint="You're slightly fast. "
  else --On speed
    hint="You're on speed. "
  end

  -- Extend or decrease depending on skill.
  if playerData.difficulty==AIRBOSS.Difficulty.EASY then
    hint=hint..string.format(" Optimal AoA is %.1f.", checkpoint.AoA)
  elseif playerData.difficulty==AIRBOSS.Difficulty.NORMAL then
    --hint=hint.."\n"
  elseif playerData.difficulty==AIRBOSS.Difficulty.HARD then
    hint=""
  end
  
  -- Debriefing text.
  local debrief=string.format("AoA %.1f = %d%% deviation from %.1f optimum.", aoa, _error, checkpoint.AoA)
  
  return hint, debrief
end


--- Send message to playe client.
-- @param #AIRBOSS self
-- @param #string message The message to send.
-- @param #number duration Display message duration.
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #boolean clear If true, clear screen from previous messages.
-- @param #string sender The person who sends the message. Default is carrier alias.
-- @param #number delay Delay in seconds, before the message is send.
function AIRBOSS:_SendMessageToPlayer(message, duration, playerData, clear, sender, delay)
  if message then
  
    delay=delay or 0
    sender=sender or self.alias
          
    local text=string.format("%s, %s, %s", sender, playerData.callsign, message)
    env.info(text)
      
    if delay>0 then
      SCHEDULER:New(nil,self._SendMessageToPlayer, {self, message, duration, playerData, clear, sender}, delay)
    else
      if playerData.client then
        MESSAGE:New(text, duration, nil, clear):ToClient(playerData.client)
      end        
      --MESSAGE:New(text, duration, nil, clear):ToAll()    
    end
    
  end
end

--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned. 
-- @param #AIRBOSS self
-- @param #string _unitName Name of the player unit.
-- @return Wrapper.Unit#UNIT Unit of player or nil.
-- @return #string Name of the player or nil.
function AIRBOSS:_GetPlayerUnitAndName(_unitName)
  self:F2(_unitName)

  if _unitName ~= nil then
  
    -- Get DCS unit from its name.
    local DCSunit=Unit.getByName(_unitName)
    
    if DCSunit then
    
      local playername=DCSunit:getPlayerName()
      local unit=UNIT:Find(DCSunit)
    
      self:T2({DCSunit=DCSunit, unit=unit, playername=playername})
      if DCSunit and unit and playername then
        return unit, playername
      end
      
    end
    
  end
  
  -- Return nil if we could not find a player.
  return nil,nil
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Menu Functions
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add menu commands for player.
-- @param #AIRBOSS self
-- @param #string _unitName Name of player unit.
function AIRBOSS:_AddF10Commands(_unitName)
  self:F(_unitName)
  
  -- Get player unit and name.
  local _unit, playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check for player unit.
  if _unit and playername then

    -- Get group and ID.
    local group=_unit:GetGroup()
    local _gid=group:GetID()
  
    if group and _gid then
  
      if not self.menuadded[_gid] then
      
        -- Enable switch so we don't do this twice.
        self.menuadded[_gid] = true
  
        -- Main F10 menu: F10/Carrier Trainer/<Carrier Name>/
        if AIRBOSS.MenuF10[_gid] == nil then
          AIRBOSS.MenuF10[_gid]=missionCommands.addSubMenuForGroup(_gid, "Carrier Trainer")
        end
        
        -- Player Data.
        local playerData=self.players[playername]
        
        -- F10/Carrier Trainer/<Carrier Name>
        local _trainPath = missionCommands.addSubMenuForGroup(_gid, self.alias, AIRBOSS.MenuF10[_gid])
        
        -- F10/Carrier Trainer/<Carrier Name>/Results
        local _statsPath = missionCommands.addSubMenuForGroup(_gid, "LSO Grades", _trainPath)
        
        -- F10/Carrier Trainer/<Carrier Name>/My Settings/Difficulty
        local _difficulPath = missionCommands.addSubMenuForGroup(_gid, "Difficulty", _trainPath)

        -- F10/Carrier Trainer/<Carrier Name>/Results/
        missionCommands.addCommandForGroup(_gid, "Greenie Board", _statsPath, self._DisplayScoreBoard, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "My Grades",     _statsPath, self._DisplayPlayerGrades, self, _unitName)
        --missionCommands.addCommandForGroup(_gid, "(Clear ALL Results)", _statsPath, self._ResetRangeStats, self, _unitName)
        
        -- F10/Carrier Trainer/<Carrier Name>/Difficulty
        missionCommands.addCommandForGroup(_gid, "Flight Student",  _difficulPath, self._SetDifficulty, self, playername, AIRBOSS.Difficulty.EASY)
        missionCommands.addCommandForGroup(_gid, "Naval Aviator",   _difficulPath, self._SetDifficulty, self, playername, AIRBOSS.Difficulty.NORMAL)
        missionCommands.addCommandForGroup(_gid, "TOPGUN Graduate", _difficulPath, self._SetDifficulty, self, playername, AIRBOSS.Difficulty.HARD)
        
        -- F10/Carrier Trainer/<Carrier Name>/
        missionCommands.addCommandForGroup(_gid, "Carrier Info",            _trainPath, self._DisplayCarrierInfo,    self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Weather Report",          _trainPath, self._DisplayCarrierWeather, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Attitude Monitor ON/OFF", _trainPath, self._AttitudeMonitor,       self, playername)
        --TODO: Flare carrier.
        
        
      end
    else
      self:T(self.lid.."Could not find group or group ID in AddF10Menu() function. Unit name: ".._unitName)
    end
  else
    self:T(self.lid.."Player unit does not exist in AddF10Menu() function. Unit name: ".._unitName)
  end

end

--- Display top 10 player scores.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_DisplayPlayerGrades(_unitName)
  self:F(_unitName)
  
  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData=self.players[_playername] --#AIRBOSS.PlayerData
    
    if playerData then
    
      -- Grades of player:
      local text=string.format("Your grades, %s:", _playername)
      
      local p=0
      for i,_grade in pairs(playerData.grades) do
        local grade=_grade --#AIRBOSS.LSOgrade
        
        text=text..string.format("\n[%d] %s %.1f PT - %s", i, grade.grade, grade.points, grade.details)
        p=p+grade.points
      end
      
      -- Number of grades.
      local n=#playerData.grades
      
      if n>0 then
        text=text..string.format("\nAverage points = %.1f", p/n)
      else
        text=text..string.format("\nNo data available.")
      end
      
      env.info("FF:\n"..text)
      
      -- Send message.
      if playerData.client then
        MESSAGE:New(text, 30, nil, true):ToClient(playerData.client)
      end
    end
  end
end


--- Display top 10 player scores.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_DisplayScoreBoard(_unitName)
  self:F(_unitName)
  
  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if we have a unit which is a player.
  if _unit and _playername then
  
    -- Results table.
    local _playerResults={}
    
    -- Player data of requestor.
    local playerData=self.players[_playername]  --#AIRBOSS.PlayerData
  
    -- Message text.
    local text = string.format("Greenie Board:")
    
    for _playerName,_playerData in pairs(self.players) do
    
      local Paverage=0
      for _,_grade in pairs(_playerData.grades) do
        Paverage=Paverage+_grade.points
      end
      _playerResults[_playerName]=Paverage
    
    end
    
    --Sort list!
    local _sort=function(a, b) return a>b end
    table.sort(_playerResults,_sort)
    
    local i=1
    for _playerName,_points in pairs(_playerResults) do
      text=text..string.format("\n[%d] %.1f %s", i,_points,_playerName)
      i=i+1
    end
    
    env.info("FF:\n"..text)

    -- Send message.
    if playerData.client then
      MESSAGE:New(text, 30, nil, true):ToClient(playerData.client)
    end
  
  end
end


--- Turn player's aircraft attitude display on or off.
-- @param #AIRBOSS self
-- @param #string playername Player name.
function AIRBOSS:_AttitudeMonitor(playername)
  self:E({playername=playername})
  
  local playerData=self.players[playername]  --#AIRBOSS.PlayerData
  
  if playerData then
    playerData.attitudemonitor=not playerData.attitudemonitor
  end
end

--- Set difficulty level.
-- @param #AIRBOSS self
-- @param #string playername Player name.
-- @param #AIRBOSS.Difficulty difficulty Difficulty level.
function AIRBOSS:_SetDifficulty(playername, difficulty)
  self:E({difficulty=difficulty, playername=playername})
  
  local playerData=self.players[playername]  --#AIRBOSS.PlayerData
  
  if playerData then
    playerData.difficulty=difficulty
    local text=string.format("Your difficulty level is now: %s.", difficulty)
    self:_SendMessageToPlayer(text, 5, playerData)
  else
    self:E(self.lid..string.format("ERROR: Could not get player data for player %s.", playername))
  end
end

--- Report information about carrier.
-- @param #AIRBOSS self
-- @param #string _unitname Name of the player unit.
function AIRBOSS:_DisplayCarrierInfo(_unitname)
  self:E(_unitname)
  
  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName(_unitname)
  
  -- Check if we have a player.
  if unit and playername then
  
    -- Player data.  
    local playerData=self.players[playername]  --#AIRBOSS.PlayerData
    
    if playerData then
    
      -- Message text.
      local text=string.format("%s info:\n", self.alias)
   
      -- Current coordinates.
      local coord=self.carrier:GetCoordinate()    
    
      -- Carrier speed and heading.
      local carrierheading=self.carrier:GetHeading()
      local carrierspeed=UTILS.MpsToKnots(self.carrier:GetVelocityMPS())
        
      -- Tacan/ICLS.
      local tacan="unknown"
      local icls="unknown"
      if self.TACAN~=nil then
        tacan=tostring(self.TACAN)
      end
      if self.ICLSchannel~=nil then
        icls=tostring(self.ICLS)
      end

      -- Message text
      text=text..string.format("BRC %d°\n", carrierheading)
      text=text..string.format("Speed %d kts\n", carrierspeed)      
      text=text..string.format("TACAN Channel %s\n", tacan)
      text=text..string.format("ICLS Channel %s", icls)
      
      -- Send message.
      self:_SendMessageToPlayer(text, 20, playerData)
      
    else
      self:E(self.lid..string.format("ERROR: Could not get player data for player %s.", playername))
    end   
  end  
  
end


--- Report weather conditions at the carrier location. Temperature, QFE pressure and wind data.
-- @param #AIRBOSS self
-- @param #string _unitname Name of the player unit.
function AIRBOSS:_DisplayCarrierWeather(_unitname)
  self:E(_unitname)

  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName(_unitname)
  self:E({playername=playername})
  
  -- Check if we have a player.
  if unit and playername then
  
    -- Message text.
    local text=""
   
    -- Current coordinates.
    local coord=self.carrier:GetCoordinate()
    
    -- Get atmospheric data at carrier location.
    local T=coord:GetTemperature()
    local P=coord:GetPressure()
    local Wd,Ws=coord:GetWind()
    
    -- Get Beaufort wind scale.
    local Bn,Bd=UTILS.BeaufortScale(Ws)  
    
    local WD=string.format('%03d°', Wd)
    local Ts=string.format("%d°C",T)
    
    local hPa2inHg=0.0295299830714
    local hPa2mmHg=0.7500615613030
    
    local settings=_DATABASE:GetPlayerSettings(playername) or _SETTINGS --Core.Settings#SETTINGS
    local tT=string.format("%d°C",T)
    local tW=string.format("%.1f m/s", Ws)
    local tP=string.format("%.1f mmHg", P*hPa2mmHg)
    if settings:IsImperial() then
      tT=string.format("%d°F", UTILS.CelciusToFarenheit(T))
      tW=string.format("%.1f knots", UTILS.MpsToKnots(Ws))
      tP=string.format("%.2f inHg", P*hPa2inHg)      
    end
              
    -- Report text.
    text=text..string.format("Weather Report at Carrier %s:\n", self.alias)
    text=text..string.format("--------------------------------------------------\n")
    text=text..string.format("Temperature %s\n", tT)
    text=text..string.format("Wind from %s at %s (%s)\n", WD, tW, Bd)
    text=text..string.format("QFE %.1f hPa = %s", P, tP)
       
    -- Debug output.
    self:T2(self.lid..text)
    
    -- Send message to player group.
    self:_SendMessageToPlayer(text, 30, self.players[playername])
    
  else
    self:E(self.lid..string.format("ERROR! Could not find player unit in CarrierWeather! Unit name = %s", _unitname))
  end      
end
