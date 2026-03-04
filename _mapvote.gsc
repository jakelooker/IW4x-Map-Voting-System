#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

//IW4
main(){
    replaceFunc(maps\mp\gametypes\_gamelogic::endGame, ::endGame_hook);
    replaceFunc(maps\mp\gametypes\_playerlogic::spawnIntermission, ::spawnIntermission_hook);
}

init(){
    shaders = strTok("popup_button_selection_bar,gradient_center,white,line_horizontal_scorebar,black",",");
	for(m = 0; m < shaders.size; m++)
	    precacheShader(shaders[m]);
    //1024 DVAR character limit
    SetDvarIfUninitialized("mapvote_small_maps", "mp_shipment,mp_rust,mp_dome,mp_killhouse");
    SetDvarIfUninitialized("mapvote_med_maps", "mp_crash,mp_vacant,mp_bog_sh");
    SetDvarIfUninitialized("mapvote_big_maps", "mp_afghan,mp_overgrown,mp_countdown");
    SetDvarIfUninitialized("mapvote_modes", "war,dom");
    SetDvarIfUninitialized("mapvote_map_timer", 15);
    SetDvarIfUninitialized("mapvote_gamemode_timer", 15);
    SetDvarIfUninitialized("mapvote_optionsCount", 15);
    SetDvarIfUninitialized("mapvote_disable_broken_modes", false);
    SetDvarIfUninitialized("mapvote_restricted_maps", "");
    SetDvarIfUninitialized("mapvote_restricted_modes", "");
}

startVote() {
    smallMaps = strtok(getDvar("mapvote_small_maps"), ",");
    medMaps = strtok(getDvar("mapvote_med_maps"), ",");
    bigMaps = strtok(getDvar("mapvote_big_maps"), ",");

    if(getDvarInt("mapvote_optionsCount") > 15)
        mapCount = 15;
    else if(getDvarInt("mapvote_optionsCount") < 2)
        mapCount = 2;
    else if(getDvarInt("mapvote_optionsCount"))
        mapCount = getDvarInt("mapvote_optionsCount");
    else
        mapCount = 15;

    gameModes = strtok(getDvar("mapvote_modes"), ",");
    gameModes = generateVoteList(gameModes, gameModes.size, false);

    mapSubGroupSize = int(mapCount / 3);
    diff = mapCount - (mapSubGroupSize * 3);
    if (diff == 0){
        smallMaps = generateVoteList(smallMaps, mapSubGroupSize, true);
        medMaps = generateVoteList(medMaps, mapSubGroupSize, true);
        bigMaps = generateVoteList(bigMaps, mapSubGroupSize, true);
        maps = array_combine(smallMaps, array_combine(medMaps, bigMaps));
    }    
    else if(diff == 1) {
        smallMaps = generateVoteList(smallMaps, (mapSubGroupSize + 1), true);
        medMaps = generateVoteList(medMaps, mapSubGroupSize, true);
        bigMaps = generateVoteList(bigMaps, mapSubGroupSize, true);
        maps = array_combine(smallMaps, array_combine(medMaps, bigMaps));
    }  
    else {
        smallMaps = generateVoteList(smallMaps, (mapSubGroupSize + 1), true);
        medMaps = generateVoteList(medMaps, (mapSubGroupSize + 1), true);
        bigMaps = generateVoteList(bigMaps, mapSubGroupSize, true);
        maps = array_combine(smallMaps, array_combine(medMaps, bigMaps));
    }
    level initVote(maps, gameModes);
}

generateVoteList(items, count, shuffle){
    if (shuffle == true){
        for (i = 0; i < items.size; i++){
            j = randomInt(items.size);
            temp = items[i];
            items[i] = items[j];
            items[j] = temp;
        }
    }
    selected = [];
    for(i = 0; i < count; i++)
    {
        if(isDefined(items[i]))
            selected[selected.size] = items[i];
    }
    return selected;
}

getValidGameModeTypes(winningMap, gameModes){
    mapName = mapToString(winningMap);
    mapGroup = strTok(mapName, " ")[0];
    restrictedGameModes = [];
    if (mapGroup != "[^3MW2^7]"){
        restrictedGameModes[restrictedGameModes.size] = "gtnw";
    }
    if (mapGroup == "[^1Custom^7]"){
        restrictedGameModes[restrictedGameModes.size] = "dd";
        restrictedGameModes[restrictedGameModes.size] = "oneflag";
        restrictedGameModes[restrictedGameModes.size] = "ctf";
    }
    validGameModes = [];
    for(i = 0; i < gameModes.size; i++)
    {
        isRestricted = false;
        for(j = 0; j < restrictedGameModes.size; j++)
        {
            if(gameModes[i] == restrictedGameModes[j])
            {
                isRestricted = true;
                break;
            }
        }

        // If it's not restricted, add it to our new list
        if(!isRestricted)
        {
            validGameModes[validGameModes.size] = gameModes[i];
        }
    }
    return validGameModes;
}


initVote(maps, gameModes){

    level.votingResults = [];
    for (i = 0; i < maps.size; i++){
        level.votingResults[i] = 0;
    }
    level.inMapVoting = true;
    level.timer = getDvarInt("mapvote_map_timer");
    level mapVoteUI("map", maps);
    foreach(player in level.players){
        if(!issubstr(player getGuid() + "", "bot"))
            player thread buttonMonitoring(maps.size);
    }
    level startVotingTimer();
    level notify("map_vote_over");
    level notify("destroy_scrollbar");
    for(i = 0; i < level.ui.size; i++) 
		level.ui[i] destroy();
    winningMap = maps[getHighestVote(level.votingResults)];
    gameModes = getValidGameModeTypes(winningMap, gameModes);
    
    level.votingResults = [];
    for (i = 0; i < gameModes.size; i++){
        level.votingResults[i] = 0;
    }
    level.timer = getDvarInt("mapvote_gamemode_timer");
    level mapVoteUI("gamemode", gameModes);
    foreach(player in level.players){
        if(!issubstr(player getGuid() + "", "bot"))
            player thread buttonMonitoring(gameModes.size);
    }
    level startVotingTimer();
    level notify("vote_over");
    level notify("destroy_scrollbar");
    for(i = 0; i < level.ui.size; i++) 
		level.ui[i] destroy();
    winningGameMode = gameModes[getHighestVote(level.votingResults)];

    setDvar("sv_maprotation", "gametype " + winningGameMode + " map " + winningMap);
    setDvar("sv_maprotationcurrent", "gametype " + winningGameMode + " map " + winningMap);
}

mapVoteUI(mode, options){
    textYaxis = 120;
    bgHeight = options.size * 20;
    hudsYaxis = 110 + bgHeight;
    level.ui = [];
    level.ui[0] = createText(&"VOTING PHASE: ", "LEFT", "TOP", -90, 100, 0.8, "hudBig", (1,1,1), 1, 5, true, level.timer);
    level.ui[1] = createShader("gradient_center", "TOP", "TOP", 0, 90, 350, 20, (0,0,0), 0.9, 1, true);
    level.ui[2] = createShader("line_horizontal_scorebar", "TOP", "TOP", 0, 110, 350, 2, (1,1,1), 1, 2, true);
    level.ui[3] = createShader("white", "TOP", "TOP", 0, 110, 350, bgHeight, (0.5, 0.5 ,0.5), 0.5, 1, true);
    level.ui[4] = createShader("line_horizontal_scorebar", "TOP", "TOP", 0, hudsYaxis - 2, 350, 2, (1,1,1), 1, 2, true);
    level.ui[5] = createShader("black", "TOP", "TOP", 0, hudsYaxis, 350, 20, (0,0,0), 0.7, 1, true);
    level.ui[6] = createText("Up ^3W^7/^3DPad Up ^7Down ^3S^7/^3DPad Down                    ^7Vote ^3[{+gostand}]", "LEFT", "TOP", -170, hudsYaxis + 10, 1, "objective", (1,1,1), 1, 5, true);
    if (mode == "map"){
        for(i = 0; i < options.size; i++){
            level.ui[i + 7] = createText(mapToString(options[i]) + " : " + level.votingResults[i], "RIGHT", "TOP", 170, textYaxis, 1, "objective", (1,1,1), 1, 5, true); textYaxis += 20; 
        }
    }
    else {
        for(i = 0; i < options.size; i++){
            level.ui[i + 7] = createText(gameModeToString(options[i]) + " : " + level.votingResults[i], "RIGHT", "TOP", 170, textYaxis, 1, "objective", (1,1,1), 1, 5, true); textYaxis += 20; 
        }
    }
}

getHighestVote(votingResults){
    highest = 0;
    winners = [];
    for (i = 0; i < votingResults.size; i++){
        if (votingResults[i] > highest)
            highest = votingResults[i];
    }
    for (i = 0; i < votingResults.size; i++){
        if (votingResults[i] == highest)
            winners[winners.size] = i;
    }
    return winners[randomInt(winners.size)];
}

startVotingTimer(){
    for(i = 0; i <= level.timer; i++)
    {
        if(i >= (level.timer - 5))
        {
            level.ui[0].label = &"VOTING PHASE: ^1";
        }
        wait 1;
    }
}

buttonMonitoring(optionCount) {
    self endon("disconnect");
    level endon("vote_over");
    level endon("map_vote_over");

    scrollbarY = 110;
    index = 0;
    selected = -1;
    scrollbar = self createShader("popup_button_selection_bar", "TOP", "TOP", 0, scrollbarY, 347, 20, (0, 0, 0), 0.7, 4, false);

    self freezeControlsWrapper( true );
    self thread destroyScrollbar(scrollbar);

	self notifyonplayercommand("up", "+attack");
    self notifyonplayercommand("up", "+forward");
    self notifyonplayercommand("up", "+actionslot 1");
    self notifyonplayercommand("down", "+toggleads_throw");
    self notifyonplayercommand("down", "+speed_throw");
    self notifyonplayercommand("down", "+back");
    self notifyonplayercommand("down", "+actionslot 2");
    self notifyonplayercommand("select", "+activate");
    self notifyOnPlayerCommand("select", "+gostand");

    for(;;)
    {
        command = self waittill_any_return("up", "down", "select"); 

        if(command == "up" && index >= 0) 
        {
            if(index < 1){
                index = (optionCount- 1);
                scrollbar.y = scrollbarY + (optionCount- 1) * 20;
            }else{
                index--;
                scrollbar.y -= 20;
            }
            self playLocalSound("mouse_over");
        } 
        else if(command == "down" && index <= (optionCount- 1))
        {   
            if(index > (optionCount- 2)){
                index = 0;
                scrollbar.y = scrollbarY;
            }else{
                index++;
                scrollbar.y += 20;
            }
            self playLocalSound("mouse_over");
        } 
        else if(command == "select")
        {
            if(selected == -1) 
            {
                selected = index;
                self updateVoteSelection(selected, 1);
                
                self playLocalSound("mouse_click");
            } 
            else if(selected != index)
            {                
                updateVoteSelection(selected, -1);
                selected = index;
                updateVoteSelection(selected, 1);

                self playLocalSound("mouse_click");
            }
        }        
    }
}

destroyScrollbar(hud){
    self endon("disconnect");
    level waittill("destroy_scrollbar");
    hud destroy();
}

updateVoteSelection(selected, value){
    level.votingResults[selected] += value;
    if (value == 1){
        level.ui[selected + 7].text = strTok(level.ui[selected + 7].text, ":")[0] + ": ^1" + level.votingResults[selected];
    }
    else {
        level.ui[selected + 7].text = strTok(level.ui[selected + 7].text, ":")[0] + ": ^7" + level.votingResults[selected];
    }
    level.ui[selected + 7] setText(level.ui[selected + 7].text);
}

createText(text, align, relative, x, y, fontscale, font, color, alpha, sort, server, timer) {
    if(server)
    {
        if(isdefined(timer))
            fontElem = createServerTimer( font, fontscale );
        else
            fontElem = createServerFontString( font, fontscale ); 
    }
    else 
        fontElem = self createFontString( font, fontscale ); 

    fontElem.hidewheninmenu = true;
    fontElem.foreground = true;
    fontElem.color = color;
    fontElem.alpha = alpha;
    fontElem.sort = sort;
    fontElem setpoint(align, relative, x, y);

    if(isdefined(timer)) {
        fontElem.label = text;
        fontElem setTimer(timer);
    } else {
        fontElem.text = text;
        fontElem.value = 0;
        fontElem setText(text); }

    return fontElem;
}

createShader(shader, align, relative, x, y, width, height, color, alpha, sort, server) {
    if(server) 
        iconElem = createServerIcon( shader, width, height );
    else
        iconElem = self createIcon( shader, width, height );

    iconElem.hidewheninmenu = true;
    iconElem.foreground = true;
    iconElem.align = align;
    iconElem.relative = relative;
    iconElem.sort = sort;
    iconElem.color = color;
    iconElem.alpha = alpha;
    iconElem setPoint(align, relative, x, y);

    return iconElem;
}

isDedicatedServer(){
    if(!getDvarInt( "party_host" ))
        return true;
    return false;
}

endGame_hook( winner, endReasonText, nukeDetonated ){
	if ( !isDefined(nukeDetonated) )
		nukeDetonated = false;
	
	// return if already ending via host quit or victory, or nuke incoming
	if ( game["state"] == "postgame" || level.gameEnded || (isDefined(level.nukeIncoming) && !nukeDetonated) && ( !isDefined( level.gtnw ) || !level.gtnw ) )
		return;

	game["state"] = "postgame";

	level.gameEndTime = getTime();
	level.gameEnded = true;
	level.inGracePeriod = false;
	level notify ( "game_ended", winner );
	levelFlagSet( "game_over" );
	levelFlagSet( "block_notifies" );
	waitframe(); // give "game_ended" notifies time to process
	
	setGameEndTime( 0 ); // stop/hide the timers
	
	maps\mp\gametypes\_playerlogic::printPredictedSpawnpointCorrectness();
	
	if ( isDefined( winner ) && isString( winner ) && winner == "overtime" )
	{
		maps\mp\gametypes\_gamelogic::endGameOvertime( winner, endReasonText );
		return;
	}
	
	if ( isDefined( winner ) && isString( winner ) && winner == "halftime" )
	{
		maps\mp\gametypes\_gamelogic::endGameHalftime();
		return;
	}

	game["roundsPlayed"]++;
	
	if ( level.teamBased )
	{
		if ( winner == "axis" || winner == "allies" )
			game["roundsWon"][winner]++;

		maps\mp\gametypes\_gamescore::updateTeamScore( "axis" );
		maps\mp\gametypes\_gamescore::updateTeamScore( "allies" );
	}
	else
	{
		if ( isDefined( winner ) && isPlayer( winner ) )
			game["roundsWon"][winner.guid]++;
	}
	
	maps\mp\gametypes\_gamescore::updatePlacement();

	maps\mp\gametypes\_gamelogic::rankedMatchUpdates( winner );

	foreach ( player in level.players )
		player setClientDvar( "ui_opensummary", 1 );
	
	setDvar( "g_deadChat", 1 );
	setDvar( "ui_allow_teamchange", 0 );

	// freeze players
	foreach ( player in level.players )
	{
		player thread maps\mp\gametypes\_gamelogic::freezePlayerForRoundEnd( 1.0 );
		player thread maps\mp\gametypes\_gamelogic::roundEndDoF( 4.0 );
		
		player maps\mp\gametypes\_gamelogic::freeGameplayHudElems();

		player setClientDvars( "cg_everyoneHearsEveryone", 1 );
		player setClientDvars( "cg_drawSpectatorMessages", 0,
							   "g_compassShowEnemies", 0 );
							   
		if ( player.pers["team"] == "spectator" )
			player thread maps\mp\gametypes\_playerlogic::spawnIntermission();
	}		
	
	// End of Round
	if ( !wasOnlyRound() && !nukeDetonated )
	{
		setDvar( "scr_gameended", 2 );
	
		maps\mp\gametypes\_gamelogic::displayRoundEnd( winner, endReasonText );

		if ( level.showingFinalKillcam )
		{
			foreach ( player in level.players )
				player notify ( "reset_outcome" );

			level notify ( "game_cleanup" );

			maps\mp\gametypes\_gamelogic::waittillFinalKillcamDone();
		}
				
		if ( !wasLastRound() )
		{
			levelFlagClear( "block_notifies" );
			if ( maps\mp\gametypes\_gamelogic::checkRoundSwitch() )
				maps\mp\gametypes\_gamelogic::displayRoundSwitch();

			foreach ( player in level.players )
				player.pers["stats"] = player.stats;

        	level notify ( "restarting" );
            game["state"] = "playing";
            map_restart( true );
            return;
		}
		
		if ( !level.forcedEnd )
			endReasonText = maps\mp\gametypes\_gamelogic::updateEndReasonText( winner );
	}

	setDvar( "scr_gameended", 1 );
	
	if ( !isDefined( game["clientMatchDataDef"] ) )
	{
		game["clientMatchDataDef"] = "mp/clientmatchdata.def";
		setClientMatchDataDef( game["clientMatchDataDef"] );
	}

	maps\mp\gametypes\_missions::roundEnd( winner );

	maps\mp\gametypes\_gamelogic::displayGameEnd( winner, endReasonText );

	if ( level.showingFinalKillcam && wasOnlyRound() )
	{
		foreach ( player in level.players )
			player notify ( "reset_outcome" );

		level notify ( "game_cleanup" );

		maps\mp\gametypes\_gamelogic::waittillFinalKillcamDone();
	}

	levelFlagClear( "block_notifies" );

	level.intermission = true;

	level notify ( "spawning_intermission" );
	
	foreach ( player in level.players )
	{
        player closeMenus();
		player notify ( "reset_outcome" );
    }

    if(scripts\mp\_mapvote::isDedicatedServer())
        scripts\mp\_mapvote::startVote();

    if( !nukeDetonated )
        visionSetNaked( "mpOutro", 0.5 );

    foreach ( player in level.players )
        player thread maps\mp\gametypes\_playerlogic::spawnIntermission();

	maps\mp\gametypes\_gamelogic::processLobbyData();

	if ( matchMakingGame() )
		sendMatchData();

	foreach ( player in level.players )
		player.pers["stats"] = player.stats;

	logString( "game ended" );
	if( !nukeDetonated && !level.postGameNotifies )
	{
		if ( !wasOnlyRound() )
			wait 6.0;
		else
			wait 3.0;
	}
	else
		wait ( min( 10.0, 4.0 + level.postGameNotifies ) );

	level notify( "exitLevel_called" );
	exitLevel( false );
}

spawnIntermission_hook(){
	self endon( "disconnect" );
	
	self notify( "spawned" );
	self notify( "end_respawn" );
	
	self maps\mp\gametypes\_playerlogic::setSpawnVariables();
	self closeMenus();
	
	self clearLowerMessages();
	
	self freezeControlsWrapper( true );
	
	self setClientDvar( "cg_everyoneHearsEveryone", 1 );

    if(isDefined(level.inVoting) && level.inVoting)// Late joiners after intermission
    {
        if(!issubstr(self getGuid() + "", "bot"))
            self thread scripts\mp\_mapvote::buttonMonitoring();

        level waittill("vote_over");
    }
    else if(game["state"] == "postgame" && (isDefined(level.intermission) && !level.intermission)) // We're in the victory screen, but before intermission
		level waittill("vote_over");

	if ( level.rankedMatch && ( self.postGamePromotion || self.pers["postGameChallenges"] ) )
	{
		if ( self.postGamePromotion )
			self playLocalSound( "mp_level_up" );
		else
			self playLocalSound( "mp_challenge_complete" );

		if ( self.postGamePromotion > level.postGameNotifies )
			level.postGameNotifies = 1;

		if ( self.pers["postGameChallenges"] > level.postGameNotifies )
			level.postGameNotifies = self.pers["postGameChallenges"];

		self closeMenus();	

		self openMenu( game["menu_endgameupdate"] );

		waitTime = 4.0 + min( self.pers["postGameChallenges"], 3 );		
		while ( waitTime )
		{
			wait ( 0.25 );
			waitTime -= 0.25;

			self openMenu( game["menu_endgameupdate"] );
		}
		
		self closeMenu( game["menu_endgameupdate"] );
	}
	
	self.sessionstate = "intermission";
	self ClearKillcamState();
	self.friendlydamage = undefined;
	
	spawnPoints = getEntArray( "mp_global_intermission", "classname" );
	assertEx( spawnPoints.size, "NO mp_global_intermission SPAWNPOINTS IN MAP" );

	spawnPoint = spawnPoints[0];
	self spawn( spawnPoint.origin, spawnPoint.angles );
	
	self maps\mp\gametypes\_playerlogic::checkPredictedSpawnpointCorrectness( spawnPoint.origin );
	
	self setDepthOfField( 0, 128, 512, 4000, 6, 1.8 );
}

mapToString(map) {
    mapNames = [];
    // Custom Maps
    mapNames["mp_bank"] = "[^1Custom^7] Bank";
    mapNames["mp_csgo_monastery"] = "[^1Custom^7] CSGO Monastery";
    mapNames["mp_decay"] = "[^1Custom^7] Decay";
    mapNames["mp_efa_market"] = "[^1Custom^7] EFA Market";
    mapNames["mp_firestation"] = "[^1Custom^7] Firestation";
    mapNames["mp_icbm"] = "[^1Custom^7] ICBM";
    mapNames["mp_osg_2"] = "[^1Custom^7] OSG 2";
    mapNames["mp_redzone"] = "[^1Custom^7] Redzone";
    mapNames["mp_shipment_snow"] = "[^1Custom^7] Shipment Snow";
    // COD2
    mapNames["mp_carentan44"] = "[^8COD2^7] Carentan";
    mapNames["mp_waw_toujane"] = "[^8COD2^7] Toujane";
    // World at War (WAW)
    mapNames["mp_waw_castle"] = "[^0WAW^7] Castle";
    // Modern Warfare 3 (MW3)
    mapNames["mp_alpha"] = "[^2MW3^7] Lockdown";
    mapNames["mp_bravo"] = "[^2MW3^7] Mission";
    mapNames["mp_dome"] = "[^2MW3^7] Dome";
    mapNames["mp_hardhat"] = "[^2MW3^7] Hardhat";
    mapNames["mp_paris"] = "[^2MW3^7] Resistance";
    mapNames["mp_plaza2"] = "[^2MW3^7] Arkaden";
    mapNames["mp_seatown"] = "[^2MW3^7] Seatown";
    mapNames["mp_underground"] = "[^2MW3^7] Underground";
    mapNames["mp_village"] = "[^2MW3^7] Village";
    mapNames["mp_aground_ss"] = "[^2MW3^7] Aground";
    mapNames["mp_boardwalk"] = "[^2MW3^7] Boardwalk";
    mapNames["mp_bootleg"] = "[^2MW3^7] Bootleg";
    mapNames["mp_burn_ss"] = "[^2MW3^7] U-Turn";
    mapNames["mp_carbon"] = "[^2MW3^7] Carbon";
    mapNames["mp_cement"] = "[^2MW3^7] Foundation";
    mapNames["mp_courtyard_ss"] = "[^2MW3^7] Erosion";
    mapNames["mp_crosswalk_ss"] = "[^2MW3^7] Intersection";
    mapNames["mp_exchange"] = "[^2MW3^7] Downturn";
    mapNames["mp_hillside_ss"] = "[^2MW3^7] Getaway";
    mapNames["mp_interchange"] = "[^2MW3^7] Interchange";
    mapNames["mp_italy"] = "[^2MW3^7] Piazza";
    mapNames["mp_lambeth"] = "[^2MW3^7] Fallen";
    mapNames["mp_meteora"] = "[^2MW3^7] Sanctuary";
    mapNames["mp_moab"] = "[^2MW3^7] Gulch";
    mapNames["mp_mogadishu"] = "[^2MW3^7] Bakaara";
    mapNames["mp_morningwood"] = "[^2MW3^7] Black Box";
    mapNames["mp_nola"] = "[^2MW3^7] Parish";
    mapNames["mp_overwatch"] = "[^2MW3^7] Overwatch";
    mapNames["mp_park"] = "[^2MW3^7] Liberation";
    mapNames["mp_qadeem"] = "[^2MW3^7] Oasis";
    mapNames["mp_radar"] = "[^2MW3^7] Outpost";
    mapNames["mp_restrepo_ss"] = "[^2MW3^7] Lookout";
    mapNames["mp_roughneck"] = "[^2MW3^7] Off Shore";
    mapNames["mp_shipbreaker"] = "[^2MW3^7] Decommission";
    mapNames["mp_six_ss"] = "[^2MW3^7] Vortex";
    mapNames["mp_terminal_cls"] = "[^2MW3^7] Terminal";
    mapNames["mp_winter_bakaara"] = "[^2MW3^7] Bakaara Winter";
    mapNames["mp_seatown_snow"] = "[^2MW3^7] Seatown Winter";
    // Modern Warfare 2 (MW2)
    mapNames["mp_abandon"] = "[^3MW2^7] Carnival";
    mapNames["mp_afghan"] = "[^3MW2^7] Afghan";
    mapNames["mp_boneyard"] = "[^3MW2^7] Scrapyard";
    mapNames["mp_brecourt"] = "[^3MW2^7] Wasteland";
    mapNames["mp_checkpoint"] = "[^3MW2^7] Karachi";
    mapNames["mp_compact"] = "[^3MW2^7] Salvage";
    mapNames["mp_complex"] = "[^3MW2^7] Bailout";
    mapNames["mp_derail"] = "[^3MW2^7] Derail";
    mapNames["mp_estate"] = "[^3MW2^7] Estate";
    mapNames["mp_estate_tropical"] = "[^3MW2^7] Estate Tropical";
    mapNames["mp_favela"] = "[^3MW2^7] Favela";
    mapNames["mp_fav_tropical"] = "[^3MW2^7] Favela Tropical";
    mapNames["mp_fuel2"] = "[^3MW2^7] Fuel";
    mapNames["mp_highrise"] = "[^3MW2^7] Highrise";
    mapNames["mp_invasion"] = "[^3MW2^7] Invasion";
    mapNames["mp_nightshift"] = "[^3MW2^7] Skidrow";
    mapNames["oilrig"] = "[^3MW2^7] Oil Rig";
    mapNames["mp_quarry"] = "[^3MW2^7] Quarry";
    mapNames["mp_rundown"] = "[^3MW2^7] Rundown";
    mapNames["mp_rust"] = "[^3MW2^7] Rust";
    mapNames["mp_rust_long"] = "[^3MW2^7] Rust Long";
    mapNames["mp_subbase"] = "[^3MW2^7] Sub Base";
    mapNames["mp_terminal"] = "[^3MW2^7] Terminal";
    mapNames["mp_trailerpark"] = "[^3MW2^7] Trailer Park";
    mapNames["mp_underpass"] = "[^3MW2^7] Underpass";
    mapNames["mp_storm"] = "[^3MW2^7] Storm";
    mapNames["mp_storm_spring"] = "[^3MW2^7] Chemical Plant";    
    // Black Ops 2 (BO2)
    mapNames["mp_bo2plaza"] = "[^4BO2^7] Plaza";
    mapNames["mp_bo2slums"] = "[^4BO2^7] Slums";
    mapNames["mp_raid"] = "[^4BO2^7] Raid";
    mapNames["mp_village_sh"] = "[^4BO2^7] Standoff";
    mapNames["mp_ad_bo2frost"] = "[^4BO2^7] Frost";
    // Black Ops 1 (BO1)
    mapNames["mp_firingrange"] = "[^5BO1^7] Firing Range";
    mapNames["mp_nuked"] = "[^5BO1^7] Nuketown";
    mapNames["mp_rasalem"] = "[^5BO1^7] Rasalem";
    mapNames["mp_winter_rasalem"] = "[^5BO1^7] Rasalem Winter";
    mapNames["mp_csgo_monastery"] = "[^5BO1^7] Monastery";
    mapNames["mp_mountain"] = "[^5BO1^7] Summit";
    mapNames["mp_summit"] = "[^5BO1^7] Summit";
    mapNames["mp_radiation_sh"] = "[^5BO1^7] Radiation";
    // Call of Duty 4 (COD4)
    mapNames["mp_backlot"] = "[^6COD4^7] Backlot";
    mapNames["mp_bloc"] = "[^6COD4^7] Bloc";
    mapNames["mp_bloc_sh"] = "[^6COD4^7] Forgotten City";
    mapNames["mp_bog_sh"] = "[^6COD4^7] Bog";
    mapNames["mp_broadcast"] = "[^6COD4^7] Broadcast";
    mapNames["mp_carentan"] = "[^6COD4^7] Chinatown";
    mapNames["mp_cargoship"] = "[^6COD4^7] Wet Work";
    mapNames["mp_cargoship_sh"] = "[^6COD4^7] Freighter";
    mapNames["mp_citystreets"] = "[^6COD4^7] District";
    mapNames["mp_convoy"] = "[^6COD4^7] Ambush";
    mapNames["mp_countdown"] = "[^6COD4^7] Countdown";
    mapNames["mp_crash"] = "[^6COD4^7] Crash";
    mapNames["mp_crash_snow"] = "[^6COD4^7] Winter Crash";
    mapNames["mp_crash_tropical"] = "[^6COD4^7] Crash Tropical";
    mapNames["mp_cross_fire"] = "[^6COD4^7] Crossfire";
    mapNames["mp_farm"] = "[^6COD4^7] Downpour";
    mapNames["mp_killhouse"] = "[^6COD4^7] Killhouse";
    mapNames["mp_overgrown"] = "[^6COD4^7] Overgrown";
    mapNames["mp_pipeline"] = "[^6COD4^7] Pipeline";
    mapNames["mp_shipment"] = "[^6COD4^7] Shipment";
    mapNames["mp_shipment_long"] = "[^6COD4^7] Shipment Long";
    mapNames["mp_showdown"] = "[^6COD4^7] Showdown";
    mapNames["mp_strike"] = "[^6COD4^7] Strike";
    mapNames["mp_vacant"] = "[^6COD4^7] Vacant";
    mapNames["mp_bloc_2_night"] = "[^6COD4^7] Bloc Night";
    mapNames["mp_creek"] = "[^6COD4^7] Creek";
    mapNames["mp_shipment_snow"] = "[^6COD4^7] Shipment Winter";
    mapNames["mp_backlot_snow"] = "[^6COD4^7] Backlot Winter";
    mapNames["mp_vac_2_snow"] = "[^6COD4^7] Vacant Winter";
    // Call of Duty Online (COD-OL)
    mapNames["mp_boomtown"] = "[^9COD-OL^7] Western Paradise";
    mapNames["mp_bootleg_sh"] = "[^9COD-OL^7] Bootleg Revamped";
    mapNames["mp_cha_quad"] = "[^9COD-OL^7] Monastery";
    mapNames["mp_highrise_sh"] = "[^9COD-OL^7] Highrise Revamped";
    mapNames["mp_mideast"] = "[^9COD-OL^7] Oasis V2";
    mapNames["mp_melee_resort"] = "[^9COD-OL^7] Melee Resort";
    mapNames["mp_nukearena_sh"] = "[^9COD-OL^7] Nuke Arena";
    mapNames["mp_sd_jardin"] = "[^9COD-OL^7] Royal Garden";
    mapNames["mp_seatown_sh"] = "[^9COD-OL^7] Seatown Revamped";
    mapNames["mp_tunisia"] = "[^9COD-OL^7] Tunisia";

    mapName = mapNames[map];
    if (isDefined(mapName)){
        return mapName;
    }
    else {
        return map;
    }
}

gameModeToString(gameMode){
    gameTypes = [];
    gameTypes["arena"] = "Arena";
    gameTypes["conf"] = "Kill Confirmed";
    gameTypes["ctf"] = "Capture The Flag";
    gameTypes["dd"] = "Demolition";
    gameTypes["dm"] = "Free For All";
    gameTypes["dom"] = "Domination";
    gameTypes["gtnw"] = "Global ThermoNuclear War";
    gameTypes["gun"] = "Gun Game";
    gameTypes["infect"] = "Infected";
    gameTypes["koth"] = "Headquarters";
    gameTypes["oneflag"] = "One Flag CTF";
    gameTypes["sab"] = "Sabotage";
    gameTypes["sd"] = "Search & Destroy";
    gameTypes["vip"] = "VIP";
    gameTypes["war"] = "Team Deathmatch";

    gameTypeSuffix = gameTypes[gameMode];
    if (isDefined(gameTypeSuffix))
        return gameTypeSuffix;
    else
        return gameMode;
}
