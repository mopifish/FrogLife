pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

local stats -- Global stats variable, stats exist indepent of scene
local button_map --Global button map. Maps the buttons for the lobby.
local button_x, button_y--This is global because we want it to store data without being changed
local panel_open -- Distinct from screen_fading variable as it freezes only button inputs, not player inputs.
local screen_fading -- Dictates when the screen is fading. Freezes all inputs while screen is fading
local active  -- Assigned value in initiate function | Index of the currently active scene
local ground_level --Current ground level for non-opponent objects
local scenes --Global scenes table. Stores all scenes
local global_objects -- Objects that exist independent of scenes, such as player and effects
local color_list

function _init()
	panel_open = false 
	screen_fading = false
	ground_level = 96
	global_objects = {}
	color_list = {
		{14, 2},
		{15, 4},
		{10, 9},
		{11} ,
		{7, 6},
		{13, 5},
		{2, 1},
	}
	scenes = {
		make().scene("home", 0, 0, 4), --Home scene: Located at 0, 0
		make().scene("run", 0, 16, 2, {49,50}), --Run Scene: Located at cells 0, 16. Has two obstacle sprites, 49 and 50
		make().scene("hop", 17, 0, 2, {52}), --Hop scene: located at 17, 0. One obstacle sprite, 52
		make().scene("swim", 18, 16, 2, {55}, 1), --Swim Scene: Located at 18, 16. One obstacle sprite, 55. Background color 1
		make().scene("race_select", 35, 0, 4, {}, 4),
		make().scene("shop", 51, 0, 4, {}, 4),

		make().scene("race", 0, 32, 1, {}, 12, 16, 30, 10, 15), --1st race scene, grassy sprint
		make().scene("race", 17, 32, 1, {}, 12, 16, 30, 10, 15), --2nd race scene, Cliffy Hop
		make().scene("race", 34, 32, 1, {}, 12, 16, 30,  10, 15),  --3rd race scene, Mucky pond
		make().scene("race", 51, 32, 1, {}, 12, 32, 50, 15, 20),  --4th race scene, mild loop

		make().scene("race", 0, 48, 1, {}, 12, 16, 50, 20, 25), --5th race, rokcy run
		make().scene("race", 17, 48, 1, {}, 12, 16, 50, 20, 25), --6th race, spikey leap
		make().scene("race", 34, 48, 1, {}, 12, 16, 50, 20, 25), --7th race, splish splash
		make().scene("race", 51, 48, 1, {}, 12, 38, 70, 25, 30), --8th race, mediary loop

		make().scene("race", 36, 16, 1, {}, 12, 66, 150, 30, 48),

		make().scene("start", 103, 16, 0)
	}
	stats = { -- Stats are set to 5 by default. Coins are set to 0.
		swim = 30,
		run = 30,
		hop = 30,
		energy =30,
		coins = 600,
		color = 11,
		dark_color = 3,
		hat = 60, 
		num_seeds = {3,0}, -- Seeds in pile, seeds on floor
		owned_items = {"pond"},
	}

	initiate("start") --Initiate the home scene
end

function _draw()
	--Resets the palette when the screen isn't fading. This allows for different colored frog sprites.
	cls(scenes[active].color) --Makes background color to scenes set color
	map(scenes[active].x, scenes[active].y, 0, 0, scenes[active].width, 16) --Draws the current screen. This method simply changes the background, as opposed to the player location.
	local obj
	for obj in all(scenes[active].scene_objects) do --Draws all game objects in current scene
		obj:draw()
	end	
	if not screen_fading then 
		pal()
	end

end

function _update()
	local obj
	for obj in all(scenes[active].scene_objects) do --Updates all scene objects
		obj:update()
	end
	for obj in all(global_objects) do --Updates global objects
		obj:update()
	end

	input() --Gets current scene input
end

function initiate(scn, active_race)
	music(-1, 300)
	local active_race = active_race or nil
	for scene in all(scenes) do
		scene.scene_objects = {} --Empties scene list before its reinitialized.
		scene.xp_gained = 0
	end
	if active ~= nil and scenes[active].name == "home" then --If the scene prior to switching is home
		stats.num_seeds[1] += stats.num_seeds[2] --Makes sure seeds left over get returned to the pile
		stats.num_seeds[2] = 0
	end
	--Sets certain variables to default.
	panel_open = false 
	ground_level = 96
	reload(0x2000, 0x2000, 0x1000) -- Reloads map back to default, this is important for training games where the map is changed during run time.
	camera(0,0) -- Resets camera in case it was moved

	local obj = {
		home = function()
			active = 1
			button_map = {
				{{},{},{},},
				{{},{},{},},
			}
			button_x, button_y = 3, 1 

			make().stat_box("energ", 8, 8, "energy")
			make().stat_box("run", 8, 24, "run")
			make().stat_box("swim", 32, 8, "swim")
			make().stat_box("hop", 32, 24, "hop")

			button_map[1][1] = make().button("race_select", 72, 8, 33) 
			button_map[1][2] = make().button("swim", 96, 8, 37)
			button_map[2][1] = make().button("run", 72, 24, 37)
			button_map[2][2] = make().button("hop", 96, 24, 37)
			button_map[2][3] = make().button("shop", 112, 24, 39)
			button_map[1][3] = make().button("stats", 112, 8, 35)--Drawn after so the label appears on top

			make().seed_pile()

			make().player(32, ground_level)
		end,
		run = function()
			active = 2
			make().screen_scroller(10, 3)
			make().obstacle_spawner(12, 7, 20)
			make().player(32, ground_level)
		end,
		hop = function()
			active = 3
			ground_level = 93
			make().screen_scroller(10, 3)
			make().obstacle_spawner(13, 7, 10)
			make().player(32, ground_level)
		end,
		swim = function()
			active = 4
			make().screen_scroller(10, 3)
			make().obstacle_spawner(nil, 2, 0)
			make().player(32, 64)
		end,
		race_select = function()
			local second_set_locked = true
			local final_locked = true
			active = 5 
			button_map = {
				{{}},
				{{}},
				{{}},
				{{}},
				{{}},
				{{}},
				{{}},
				{{}},
				{{}},
			}

			button_x, button_y = 1, 1 
			button_map[1][1] = make().button("grassy sprint", 40, 8, nil, 1)
			button_map[2][1] = make().button("cliffy hop", 40, 16, nil, 2)
			button_map[3][1] = make().button("mucky pond", 40, 24, nil, 3)
			button_map[4][1] = make().button("mild loop", 40, 32, nil, 4)

			if scenes[7].won and scenes[8].won and scenes[9].won and scenes[10].won then
				second_set_locked = false 
			end 
			if scenes[11].won and scenes[12].won and scenes[13].won and scenes[14].won then
				final_locked = false 
			end 
			button_map[5][1] = make().button("rocky run", 40, 48, nil, 5, second_set_locked)
			button_map[6][1] = make().button("spikey leap", 40, 56, nil, 6, second_set_locked)
			button_map[7][1] = make().button("sunny splash", 40, 64, nil, 7, second_set_locked)
			button_map[8][1] = make().button("mediary loop", 40, 72, nil, 8, second_set_locked)

			button_map[9][1] = make().button("tricky trek", 40, 88, nil, 9, final_locked)

			make().label(45, 110, 38, 8, "❎ to quit")
		end,
		shop = function()
			active = 6 
			button_map = {
				{{}, {}, {}},
				{{}, {}, {}},
				{{}, {}, {}},
				{{}, {}, {}},
				{{}, {}, {}}, 
				{{}, {}, {}},
				{{}, {}, {}},
				{{}, {}, {}},
			}

			button_x, button_y = 1, 1 

			make().label(48, 4, 26, 8, " shop", 1, 6)
			make().label(10, 4, 26, 8, nil, 1, 6)

			make().label(10, 20, 46, 16, "        $15", 1, 6)
			button_map[1][1] = make().button("feed", 14, 24, 62, nil, false, 10)

			make().label(10, 40, 46, 64, "", 1, 6)
			button_map[2][1] = make().button("pond", 14, 44, 7, nil, true, 0, {11, 3})
			button_map[3][1] = make().button("blush", 14, 52, 7, nil, true, 50, {14, 2})
			button_map[4][1] = make().button("sand", 14, 60, 7, nil, true, 50, {15, 4})
			button_map[5][1] = make().button("daisy", 14, 68, 7, nil, true, 50, {10, 9})
			button_map[6][1] = make().button("ghost", 14, 76, 7, nil, true, 50, {7, 6})
			button_map[7][1] = make().button("lilac", 14, 84, 7, nil, true, 50, {13, 5})
			button_map[8][1] = make().button("grape", 14, 92, 7, nil, true, 50, {2, 1})

			make().label(62, 20, 58, 84, " hats", 1, 6)
			button_map[1][2] = make().button("pnk", 68, 32, 80, nil, true, 40)
			button_map[2][2] = make().button("top", 68, 40, 82, nil, true, 50)
			button_map[3][2] = make().button("rbn", 68, 48, 84, nil, true, 50)
			button_map[4][2] = make().button("pta", 68, 56, 86, nil, true, 50)
			button_map[5][2] = make().button("ber", 68, 64, 88, nil, true, 60)
			button_map[6][2] = make().button("cwn", 68, 72, 90, nil, true, 70)
			button_map[7][2] = make().button("cat", 68, 80, 92, nil, true, 70)
			button_map[8][2] = make().button("dug", 68, 88, 94, nil, true, 80)
			button_map[1][3] = make().button("fed", 92, 32, 96, nil, true, 80)
			button_map[2][3] = make().button("cow", 92, 40, 98, nil, true, 90)
			button_map[3][3] = make().button("hic", 92, 48, 100, nil, true, 100)
			button_map[4][3] = make().button("acn", 92, 56, 102, nil, true, 100)
			button_map[5][3] = make().button("hsy", 92, 64, 104, nil, true, 100)
			button_map[6][3] = make().button("wiz", 92, 72, 106, nil, true, 100)
			button_map[7][3] = make().button("tpe", 92, 80, 108, nil, true, 100)
			button_map[8][3] = make().button("snl", 92, 88, 110, nil, true, 150)

			make().label(45, 110, 38, 8, "❎ to quit")

			for i = 1, #button_map do --Makes sure purchased items are unlocked.
				for j = 1, #button_map[i] do
					if button_map[i][j].locked == true then button_map[i][j].locked = not tools().in_list(stats.owned_items, button_map[i][j].name) end
				end
			end
		end,
		race = function()
			if active_race ~= nil then
				active = 6 + active_race-- Race 1 is at 7, so 6 + 1 = 7
			end
			scenes[active].race_winners = {}
			scenes[active].number_of_racers = 4
			if scenes[active].won then scenes[active].reward_money = 0 end
			local strong_stat = scenes[active].max_stats
			local weak_stat = scenes[active].min_stats
			local med_stat = tools().clamp(flr(rnd(strong_stat)+weak_stat), 0, weak_stat + (strong_stat-weak_stat)/2, strong_stat -(strong_stat-weak_stat)/2)

			for i = 0, 15 do -- Initiates ground level
				if not fget(mget(scenes[active].x, i + scenes[active].y), 3) then
					ground_level = i*8
				else
					break
				end
			end

			color_list = {
				{14, 2},
				{15, 4},
				{10, 9},
				{11, 3},
				{7, 6},
				{13, 5},
				{2, 1},
			}
			del(color_list, color_list[tools().index(color_list, stats.color)])

			make().racer(0, ground_level, med_stat, strong_stat, weak_stat, 1)
			make().racer(0, ground_level, strong_stat, weak_stat, med_stat, 1)
			make().racer(0, ground_level, weak_stat, med_stat, strong_stat, 1)
			make().player(0, ground_level)
		end,
		start = function()
			music(0)
			active = 16
			make().label(48, 12, 38, 8, "frog life")
			make().label(45, 110, 38, 8, "🅾️ to start")
		end,
	}
	
	obj[scn]() -- Calls given scene by its name
	music(scenes[active].music, 300)
end

function make()--Function that stores make functions. 
	local obj = {
		--Objects
		object= function(x, y, frame, frames, frame_increment, props, owner)
			local obj = {
				name = "object", -- Name. Used in the get_object function
				x = x,
				y = y,
				frame = frame, --Current frame (sprite num)
				frames = frames, --How many frames the animation is total
				start_frame = frame, --The starting frame 
				frame_increment = frame_increment, --Current increment on frame increment 
				animation_delay = frame_increment, --How many frames to wait before playing the next animation frame 
				owner = owner or scenes[active].scene_objects, -- Whether the object is global or belongs to current scene
				animate_sound = nil, --Defined in player/racer. Saves tokens as animation doesn't have to be rewritten.
				update = function(self)
				end,
				draw = function(self)
				end,
				animate = function(self) --Function plays a frame, waits four frames, then plays the next frame
					self.frame_increment -= 1
					if self.frame_increment < 0 then 
						self.frame += 1
						self.frame_increment = self.animation_delay
						if self.frame == self.start_frame + self.frames then --If its reached the end of the animation, then restart
							self.frame -= self.frames
							sfx(self.animate_sound)
						end
					end
				end,
			}
			local key,value
			for key,value in pairs(props) do --Adds every table key value pair in the props parameter to the object
				obj[key] = value
			end
			add(obj.owner, obj) --Adds either the list of scene objects, or global list
			return obj
		end,
		scene = function(name, x, y, music, obs_sprs, clr, width, reward, min_stats, max_stats)
			local scene = {
				name = name,
				music = music or 0,
				x = x,
				y = y,
				width = width or 16,
				scene_objects = {},
				obstacle_sprites = obs_sprs or {},
				xp_gained = 0,
				color = clr or 12,
				race_winners = {},
				reward_money = reward or 0,
				won = false,
				min_stats = min_stats or 0,
				max_stats = max_stats or 5, 
				number_of_racers = 4,
			}
			return scene
		end,
		player = function(x, y)
			make().object(x, y, 1, 5, 4, {
				name = "player",
				--Wander and movement variables
				wander_speed = 0.5, --Speed player wanders at 
				new_x_pos = x, --The new target position the frog will move too when wandering
				new_y_pos = y, --Used when jumping
				wait_increment = flr(rnd(180)) + 30, --How many frames to wait between each hop
				wait_limit = 180, --The max amount of waitable frames (6 seconds, 30fps * 6)
				--The following are variables exclsuive to training
				jump_speed = 2, 
				gravity = 1, 
				jump_height = 25,
				jumped = false,
				fainted = false,
				xp_gain = 0.0033, -- Xp gained per frame
				bonus_xp_gain = 0.002, --Bonus xp 
				bonus_start = 10, --When you start getting bonus xp
				--The following are for the race. 
				hop_prompt = false,
				swim_prompt = false, 
				hop_up_prompt = false, --prompt to hop up a single block.
				win_prompt = false, 
				energy = stats.energy,
				-- Sprite affectors
				flipped_x = false,
				--Sound Effects
				animate_sound = 0, -- Sound played during animation

				update = function(self)
					if not self.fainted and not screen_fading then
					 	self[scenes[active].name](self) -- Fetches player function that matches the scene and runs it.
					 	self:search()
					end
				end,
				draw = function(self)
					--Sets player color
					if not screen_fading then 
						pal(11, stats.color)
						pal(3, stats.dark_color)
					end

					--If in a race, draws energy bar to "canvas layer" (a position on screen relative to camera/player)
					--Camera must be updated before player, or else it will cause jitters.
					if scenes[active].name == "race" then
						camera(tools().clamp(self.x-64, 0, 0, (scenes[active].width*8)-128), 0) 
						print("energy", tools().clamp(self.x-64, 0, 0,(scenes[active].width*8)-128), 1, 7)
						sspr(88, 16 , 8, 8, tools().clamp(self.x-64, 0, 0,(scenes[active].width*8)-128), 8, 24, 8) --empty bar 
						sspr(96, 16 , 8, 8, tools().clamp(self.x-64, 0, 0,(scenes[active].width*8)-128), 8, self.energy, 8) --full bar
					end

					--Draws player
					spr(self.frame, self.x, self.y, 1, 1, self.flipped_x)
					--The following is optional polish
					if self.frame == 2 or self.frame == 3 then
						spr(stats.hat, self.x, self.y-1, 1, 1, self.flipped_x)
					elseif self.frame == 6 then
						spr(stats.hat, self.x, self.y+1, 1, 1, self.flipped_x)
					else
						spr(stats.hat, self.x, self.y, 1, 1, self.flipped_x)
					end
				end,

				--Scene functions
				home = function(self) --Wander function that dictates player movements in home scene.
				
					if self.x == self.new_x_pos then --If the frog is at the target position
				 		self.frame = self.start_frame --Set the frog back to frame one since its not moving
				 		self.wait_increment -= 1
				 		if self.wait_increment < 0 then 
				 			self.wait_increment = flr(rnd(self.wait_limit)) + 30 --Grabs a random integer between 1 second and 6 seconds
					 		repeat --Fetches new target positions until it gets a position that is more than 10 pixels away
					 			self.new_x_pos = flr(rnd(108)) + 10
					 		until self.new_x_pos - self.x > 10 or self.new_x_pos - self.x < -10
					 	end
				 	else --If the frog isn't at the target position
					 	if self.x < self.new_x_pos then 
					 		self.x += self.wander_speed 
					 		self.flipped_x = false
					 	else
					 		self.x -= self.wander_speed 
					 		self.flipped_x = true 
					 	end  
					 	self:animate()
					end
				end,
				run = function(self)
					--Moves with: Forward speed, backward speed, upward acceleration, downward acceleration, whether ot not to animate, and right boundary
					self:move(1, 0.5, 0.3, 0.5, true, 32)
				end,
				hop = function(self)
					--Moves with: Forward speed, backward speed, upward acceleration, downward acceleration, whether ot not to animate, and right boundary
					self:move(1.5, 1.5, 0.3, 0.3, false, 0)
				end,
				swim = function(self)
					scenes[active].xp_gained += self.xp_gain --Translates to roughly 1 xp per second
					self.frame = 1 --Set frame to default 
					--Moves frog left/right or up/down one square. Sets frame to 2 for "animation"
					if btnp(⬆️) then
						sfx(11)
						self.frame = 2
						self.y = tools().clamp(self.y, -8, 8, 112)
					elseif btnp(⬇️) then
						sfx(11)
						self.frame = 2
						self.y = tools().clamp(self.y, 8, 8, 112)
					end
					if btnp(➡️) then 
						sfx(11)
						self.frame = 2
						self.x = tools().clamp(self.x, 8, 8, 112)
					elseif btnp(⬅️) then
						sfx(11)
						self.frame = 2
						self.x = tools().clamp(self.x, -8, 8, 112)
					end
				end,
				race = function(self)
					if not self.win_prompt then --If you haven't won then
						--Player loses 1 energy per second, if it reaches 0 player faints and is given loss prompt
						self.energy -= 0.033 
						if self.energy < 0 then 
							self:faint()
							if not tools().get_object(scenes[active].scene_objects, "prompt") then
								make().prompt_popup("   you lost \n  try again?\n yes: 🅾️ no: ❎")
							end
						else -- If player still has energy then...
							if not self.jumped then self:animate() end
							if not self.hop_up_prompt then self.x += 0.025 * stats.run end -- If you aren't hopping up a block, which happens at a fixed speed, then add your run speed to your current speed.
							if self.hop_prompt or self.hop_up_prompt then --If some sort of jump prompt
								if self.hop_prompt then --If you're hopping, use your jump stat to jump
									self:jump(0.04*stats.hop, 0.055*stats.hop, true, flr(tools().clamp(stats.hop, 0, 7, 25)))--The clamp prevents the hop height from being too small or large
								else --Otherwise, you're moving up/down one block. Move at fixed speed.
									self:jump(0.4, 0.6, true, 14)
								end
								if self.y == ground_level then self.hop_prompt, self.jumped, self.hop_up_prompt = false, false, false end --If you land on the ground, reset and end the prompts.
							end
							if self.swim_prompt then --If you're swimming, apply swim speed. 
								self.x += 0.025 * stats.swim
							end	
						end
					else --If you've reached the finish line, then 
						--Add yourself to the list of winners
						if not tools().in_list(scenes[active].race_winners, self) then
							add(scenes[active].race_winners, self)
							sfx(12)
						end
						--New x_pos is equal to your placement. Winners then wander to line up from right to left.
						self.new_x_pos = (scenes[active].width * 8) - (tools().index(scenes[active].race_winners, self) * 8)
						if flr(self.x) == self.new_x_pos then --If the frog is at the target position
							self.x = self.new_x_pos
					 		self.frame = self.start_frame --Set the frog back to frame one since its not moving
					 		self.flipped_x = true
					 	else --If the frog isn't at the target position
						 	if self.x < self.new_x_pos then 
						 		self.x += self.wander_speed 
						 		self.flipped_x = false
						 	else
						 		self.x -= self.wander_speed 
						 		self.flipped_x = true 
						 	end  
						 	self:animate()
						end
						if self.y < ground_level then 
							self.y += self.gravity
						end
						if #scenes[active].race_winners == scenes[active].number_of_racers and self.x == self.new_x_pos then --If all racers have finished, and you're in your place then 
							local place = tools().index(scenes[active].race_winners, self) 
							if place == 1 then 
								place = "1st"
							elseif place == 2 then 
								place = "2nd"
							elseif place == 3 then 
								place = "3rd"
							elseif place == 4
								then place = "4th"
							end
							if place == "1st" then 
								if not scenes[active].won then
									stats.coins += scenes[active].reward_money
								end
								if not tools().get_object(scenes[active].scene_objects, "prompt") then
									make().prompt_popup("  you got ".. place .."!  \n  reward: $".. scenes[active].reward_money .. "\n ❎ to continue ")
								end
								scenes[active].won = true
							else 
								if not tools().get_object(scenes[active].scene_objects, "prompt") then
									make().prompt_popup("  you got ".. place .."!  \n   no reward\n ❎ to continue ")
								end
							end
						end
					end
				end,

				--Utility functions
				search = function(self) -- this function searches for objects to interact with, primarily using flags
					--Flag cheat sheet:
						--0: Seeds
						--1: Obstacles
						--2: Coins
						--3: Ground
					for item in all(scenes[active].scene_objects) do -- For every game object
				 		if fget(item.frame, 0) then -- If the object is flagged as a seed
				 			self.new_x_pos = item.x -- Set new wander destination to seed
				 			if self.x == item.x then --If you're at the seed
					 			item:animate() -- Eat the seed
					 		end
				 		end
				 	end

				 	local cellx, celly = flr((self.x + 4)/8) +scenes[active].x, flr((self.y + 4)/8) + scenes[active].y --Gets cell that the center of the player is in

				 	if fget(mget(cellx,celly), 1) then -- If the cell you're currently on is occupied by an obstacle
						self:faint()
						if stats[scenes[active].name] ~= nil then -- If the scene is a training game (It's name is in the stats list)
							stats[scenes[active].name] = tools().clamp(stats[scenes[active].name], scenes[active].xp_gained, 5, 48) --Add earned XP to given stat
							make().prompt_popup(" xp gained: " .. flr(scenes[active].xp_gained) .. "\n  try again?\n yes: 🅾️ no: ❎")
						else --Otherwise, you're in a race. And you lost.
							make().prompt_popup("   you lost \n  try again?\n yes: 🅾️ no: ❎")
						end
					elseif fget(mget(cellx,celly), 2) then -- Else if the cell youre currently on is occupied by a coin
						mset(cellx,celly, 61)
						sfx(8)
						stats.coins += 1
					end

					--Below: Updates ground level for the column inhabited by the player. This makes ground level dynamic
					if scenes[active].name == "hop" or (self.y ~= ground_level and self.jumped) then --Prevents the ground from changing when frog is jumping up. If ground level changes, so too does jump height.
						for i = 0, 15 do
							if not fget(mget(cellx, i + scenes[active].y), 3) then
								ground_level = i*8
							else
								break
							end
						end
					end

					--Hop scene is shifted down 5 pixels to make visual/functional sense. (Ground is updated in chunks of 8, but lilypads are smaller than a chunk)
					if scenes[active].name == "hop" then 
						ground_level += 5 
					end

					if scenes[active].name == "race" then
						if mget(cellx, celly) == 27 then self.swim_prompt = true else self.swim_prompt = false end --If you're in water then
						if mget(cellx, (ground_level/8) +scenes[active].y) == 58 and mget(flr(self.x/8)+1, celly) ~= 58 then self.hop_prompt = true end --Frog will jump once as long as he's left the jump flag.
						if (tools().in_list({24,17}, mget(cellx+1, celly)) or tools().in_list({0, 27}, mget(cellx+1, celly+1))) and mget(cellx, celly) ~= 68 then self.hop_up_prompt = true end --If theres a ground block in front of you, or the ground level is lower,  AND you're not at a hop flag, then 
						if mget(cellx, (ground_level/8) +scenes[active].y) == 57 then self.win_prompt = true end -- If you're on a tile with a race flag.
					end
				end,
				move = function(self, f_spd, b_spd, u_accel, d_accel, anim, boundary)
					scenes[active].xp_gained += self.xp_gain --Translates to roughly 1 xp per second
					if scenes[active].xp_gained > self.bonus_start then
						scenes[active].xp_gained += self.bonus_xp_gain --Xp bonus for survival time
					end
					if anim then --Anim variable distinguished hop from run
						if btn(➡️) then 
							self.x += f_spd
						end
						if btn(⬅️) then
							self.x -= b_spd
						end
					elseif self.y ~= ground_level then -- This is set specifically to distinguish hop and run. Player can't run on the ground in hop.
						if btn(➡️) then 
							self.x += f_spd
						end
						if btn(⬅️) then
							self.x -= b_spd
						end
					end
					
					self:jump(u_accel, d_accel, false, self.jump_height, boundary)

					if self.y == ground_level then 
						if anim then 
							self:animate()
						else
							self.frame = 1
						end
						self.jumped = false
						local screen_scroller = tools().get_object(scenes[active].scene_objects, "screen_scroller")
						self.x = tools().clamp(self.x, -10/(screen_scroller.animation_delay), boundary, (scenes[active].width * 8)-8)
					end
				end,
				jump = function(self, jump_acceleration, jump_deceleration, auto, jump_height, boundary)
					local auto = auto or false
					local jump_height = jump_height or self.jump_height
					local boundary = boundary or 0
					if (auto or (btn(⬆️) and not auto)) and not self.jumped then 
						if self.y == ground_level then 
							sfx(5)
						end
						self.new_y_pos = tools().clamp(self.y, flr(-jump_height/4), ground_level - jump_height, ground_level) --New y pos "lerps" to max jump height
						self.frame = 2 -- Set frame to jumping
					end

					if (self.y == self.new_y_pos or self.y == 0) and self.new_y_pos ~= ground_level then  -- If you've reached the pinnacle of your jump ( Reached target y, and target y isnt the ground)
						self.jumped = true
						self.new_y_pos = ground_level -- Start heading towards ground
						self.frame = 4 --Set frame to falling
					end

					if self.y > self.new_y_pos then -- If jumping (New y pos is above you)
				 		self.y -= self.jump_speed -- Move up at jump speed
				 		self.x = tools().clamp(self.x, jump_acceleration, boundary, (scenes[active].width * 8)-8) -- Move forward at jump acceleration
					elseif self.y < self.new_y_pos then -- If falling (new y pos is below you)
						self.y = tools().clamp(self.y, self.gravity, 0, ground_level) -- Move down at gravity speed, clamping when you hit ground level
						self.x = tools().clamp(self.x, jump_deceleration, boundary, (scenes[active].width * 8)-8) -- Move forward at jump jump_deceleration (speed you fall forward/down)
					end
					if self.y == ground_level and self.jumped then 
						sfx(7)
					end
				end,
				faint = function(self)
					self.fainted = true
					self.y = ground_level
					self.frame = 6
					sfx(6)
				end,
			})
		end,
		racer = function(x, y, run, hop, swim, scale)
			make().object(x, y, 1, 5, 4, {
				ground_level = ground_level,
				wander_speed = 0.5,
				hop_prompt = false,
				swim_prompt = false, 
				hop_up_prompt = false, --prompt to hop up a single block.
				win_prompt = false, 
				scale = scale,
				run = run,
				jump_speed = 2, 
				gravity = 1, 
				jump_height = 25,
				jumped = false,
				hop = hop,
				swim = swim,
				color = nil,
				dark_color = nil,
				new_x_pos = x, --The new target position the frog will move too when wandering
				new_y_pos = y, --Used when jumping
				fainted = false,
				update = function(self)
					if self.color == nil then --Gives frog a random color and removes it from the list of choosable colors.
						local num = flr(rnd(#color_list)+1)
						self.color = color_list[num][1]
						self.dark_color = color_list[num][2]
						del(color_list, color_list[num])
					end
				 	if not screen_fading and not self.fainted then
				 		self:race()
				 		self:search()
				 	end
				end,
				draw = function(self)
					local sx, sy = (self.frame % 16) * 8, (self.frame \ 16) * 8
					pal(11, self.color)
					pal(3, self.dark_color)
					sspr(sx, sy, 8, 8, self.x, self.y, 8*self.scale, 8*self.scale, self.flipped_x)
				end,
				animate = function(self) --Function plays a frame, waits four frames, then plays the next frame
					self.frame_increment -= 1
					if self.frame_increment < 0 then 
						self.frame += 1
						self.frame_increment = self.animation_delay
						if self.frame == self.start_frame + self.frames then --If its reached the end of the animation, then restart
							self.frame -= self.frames 
							sfx(0)
						end
					end
				end,
				search = function(self) -- this function searches for objects to interact with, primarily using flags
					--Below: Updates ground level for the column inhabited by the player. This makes ground level dynamic
					local cellx, celly = flr((self.x + 4)/8) +scenes[active].x, flr((self.y + 4)/8) + scenes[active].y
					if self.y ~= ground_level and self.jumped then 
						for i = 0, 15 do
							if not fget(mget(cellx, i + scenes[active].y), 3) then
								self.ground_level = i*8
							else
								break
							end
						end
					end

					if fget(mget(cellx,celly), 1) then -- If the cell you're currently on is occupied by an obstacle
						self.fainted = true
						self.y = self.ground_level
						self.frame = 6
						sfx(6)
						scenes[active].number_of_racers -= 1
					end
					if mget(cellx, celly) == 27 then self.swim_prompt = true else self.swim_prompt = false end
					if mget(cellx, (self.ground_level/8) +scenes[active].y) == 58 and mget(flr(self.x/8)+1, celly) ~= 58 then self.hop_prompt = true end --Frog will jump once as long as he's left the jump flag.
					if (tools().in_list({24,17}, mget(cellx+1, celly)) or tools().in_list({0, 27}, mget(cellx+1, celly+1))) and mget(cellx, celly) ~= 58 then self.hop_up_prompt = true end --If theres a ground block in front of you, or the ground level is lower,  AND you're not at a hop flag, then 
					if mget(cellx, (self.ground_level/8) +scenes[active].y) == 57 then self.win_prompt = true end
				end,
				race = function(self)
					if not self.win_prompt then
						if not self.jumped then self:animate() end
						if not self.hop_up_prompt then self.x += 0.025 * self.run end
						if self.hop_prompt or self.hop_up_prompt then
							if self.hop_prompt then 
								self:jump(0.04*self.hop, 0.055*self.hop, flr(tools().clamp(self.hop, 0, 7, 25)))--The clamp prevents the hop height from being too small or large
							else 
								self:jump(0.4, 0.6, 14)
							end
							if self.y >= self.ground_level then self.hop_prompt, self.jumped, self.hop_up_prompt = false, false, false end
						end
						if self.swim_prompt then 
							self.x += 0.025 * self.swim
						end	
					else
						if not tools().in_list(scenes[active].race_winners, self) then
							add(scenes[active].race_winners, self)
						end
						self.new_x_pos = (scenes[active].width * 8) - (tools().index(scenes[active].race_winners, self) * 8) 
						if flr(self.x) == self.new_x_pos then --If the frog is at the target position
							self.flipped_x = true
							self.x = self.new_x_pos
					 		self.frame = self.start_frame --Set the frog back to frame one since its not moving
					 	else --If the frog isn't at the target position
						 	if self.x < self.new_x_pos then 
						 		self.x += self.wander_speed 
						 		self.flipped_x = false
						 	else
						 		self.x -= self.wander_speed 
						 		self.flipped_x = true 
						 	end  
						 	self:animate()
						end
						if self.y < self.ground_level then 
							self.y += self.gravity
						end
					end
				end,
				jump = function(self, jump_acceleration, jump_deceleration, jump_height)
					local auto = auto or false
					local jump_height = jump_height or self.jump_height
					if not self.jumped then 
						if self.y ==self.ground_level then 
							sfx(5)
						end
						self.new_y_pos = tools().clamp(self.y, flr(-jump_height/4), self.ground_level - jump_height, self.ground_level) --New y pos "lerps" to max jump height
						self.frame = 2 -- Set frame to jumping
					end

					if (self.y == self.new_y_pos or self.y == 0) and self.new_y_pos ~= self.ground_level then  -- If you've reached the pinnacle of your jump ( Reached target y, and target y isnt the ground)
						self.jumped = true
						self.new_y_pos = self.ground_level -- Start heading towards ground
						self.frame = 4 --Set frame to falling
					end

					if self.y > self.new_y_pos then -- If jumping (New y pos is above you)
				 		self.y -= self.jump_speed -- Move up at jump speed
				 		self.x = tools().clamp(self.x, jump_acceleration , 0, self.x + 8) -- Move forward at jump acceleration
					elseif self.y < self.new_y_pos then -- If falling (new y pos is below you)
						self.y = tools().clamp(self.y, self.gravity, 0, self.ground_level) -- Move down at gravity speed, clamping when you hit ground level
						self.x = tools().clamp(self.x, jump_deceleration, 0, self.x + 8) -- Move forward at jump jump_deceleration (speed you fall forward/down)
					end
					if self.y == self.ground_level and self.jumped then 
						sfx(7)
					end
				end,
			})
		end,
		seed = function()
			make().object(112, ground_level, 21, 3, 5,{
				dx = rnd(3) + 3, -- X velocity, set to random value between 3 and 6
				dy= rnd(3) + 3, -- Y velocity, set to random value between 3 and 6
				gravity = 0.5, --How much vertical velocity is lost every frame
				air_friction = 0.1, --How much horizontal velocity is lost every frame while in air
				friction = 0.4,  --How much horizontal velocity is lost every frame while on the ground
				energy_increase = 1, -- How much energy is given to the player frog for eating the seed
				update = function(self)
					if self.y < ground_level then --If in the air
						self.dx = tools().clamp(self.dx, -self.air_friction, 0, 128) --Apply air friction
					else
						self.dx = tools().clamp(self.dx, -self.friction, 0, 128) -- Apply ground friction
					end
					self.dy = tools().clamp(self.dy, -self.gravity, -3, 128) -- Apply gravity

					self.x = tools().clamp(self.x, -self.dx, 0, ground_level) -- Applies velocity to x position as long as x is within scene bounds
					self.y = tools().clamp(self.y, -self.dy, 0, ground_level) -- Applies velocity to y position as long as y is within scene bounds
					self.x = flr(self.x) -- Sets x position to an integer value. If it's not, frog can never reach that position
				end,
				draw = function(self)
					spr(self.frame, flr(self.x), self.y)
				end,
				animate = function(self)
					self.frame_increment -= 1
					if self.frame_increment < 0 then 
						self.frame += 1
						sfx(4)
						self.frame_increment = self.animation_delay
						if self.frame == self.start_frame + self.frames then
							del(scenes[active].scene_objects, self) -- Once the animation ends and the seed is eaten, delete the seed
							stats.num_seeds[2] -= 1
							stats.energy = tools().clamp(stats.energy, self.energy_increase, 0, 92)
						end
					end
				end,
			})
		end,
		seed_pile = function()
			make().object(120, 96, 18, 0, 0, {
				draw = function(self)
					if stats.num_seeds[1] >= 1 then
						if stats.num_seeds[1] <= 3 then 
							spr(self.frame, self.x, self.y)
						elseif stats.num_seeds[1] <= 5 then 
							spr(19, self.x, self.y)
						elseif stats.num_seeds[1] <= 7 then 
							spr(19, self.x, self.y, 1, 1, true)
							spr(19, self.x-8, self.y)
						elseif stats.num_seeds[1] <= 9 then
							spr(20, self.x, self.y)
							spr(19, self.x-8, self.y)
							spr(23, self.x, self.y-8)
						elseif stats.num_seeds[1] > 9 then
							spr(20, self.x, self.y)
							spr(19, self.x-8, self.y)
							spr(18, self.x, self.y-8)
						end
					end
				end,

			})
		end,
		--UI elements
		button = function(name, x, y, sprite, race_num, locked, price, color)
			return make().object(x, y, sprite, 0, 0,{
				race_num = race_num or nil, --Disntinguishes races from eachother
				name = name,
				pressed = false,
				x = x,
				y = y,
				locked = locked or false,
				price = price or 0,
				color = color or nil,
				update = function(self)	--Handles button inputs that change the current scene
					if self.pressed then 
						if scenes[active].name == "shop" then --If you're in the shop
							if not self.locked then -- If unlocked, it can be equipped
								if self.color ~= nil then  --If its a color
									sfx(13)
									stats.color = self.color[1]
									stats.dark_color = self.color[2]
									self.pressed = false
								elseif self.frame >= 80 then --If its a hat (Hats make up all frames greater than 80)
									if stats.hat ~=  (self.frame - 16) - (self.frame-80)/2 then
										sfx(13)
										stats.hat = (self.frame - 16) - (self.frame-80)/2
									else 
										sfx(9)
										stats.hat = 60
									end
									self.pressed = false
								elseif stats.coins >= self.price then --The only remaining button type in shop is seed
									sfx(10)
									stats.coins -= self.price
									stats.num_seeds[1] += 1
									self.pressed = false
								elseif stats.coins <= self.price then sfx(9) self.pressed = false end
							elseif stats.coins >= self.price then --Otherwise, it can be purchased if you have enough coins.
								sfx(10)
								stats.coins -= self.price
								add(stats.owned_items, self.name)
								self.locked = false
								self.pressed = false
							elseif stats.coins <= self.price then 
								sfx(9)
								self.pressed = false
							end
						elseif self.race_num ~= nil and not self.locked then -- is a race button and not locked
							sfx(2)
							make().fade_into("race", self.race_num)
							self.pressed = false
						elseif self.name ~= "stats" then --otherwise if its a scene changer
							make().fade_into(self.name)
							self.pressed = false
						end
					end
				end,
				draw = function(self) --Handles button inputs that draw something to the screen.
					if sprite ~= nil then 
						if color ~= nil then pal(12, color[1]) end	
						if not self.locked then 
							if button_map[button_y][button_x].name == self.name then --Highlights current button
								spr(sprite, self.x, self.y)
							else
								spr(sprite+1, self.x, self.y)
							end
						else
							if self.color == nil then
								spr((sprite + 32) - (sprite-80)/2, self.x, self.y) --formula to get lock frame for hat buttons
							else 
								spr(9, self.x, self.y)
							end
						end
						
					end

					if scenes[active].name == "race_select" then
						if not self.locked then
							--Gives player a medal based on their place
							local place
							local racers = scenes[6 + race_num].race_winners
							for i = 1, #racers do
								if racers[i].name == "player" then 
									place = i
								end
							end 
							if place == 1 or scenes[6 + race_num].won then 
								spr(12, 24, self.y)
							elseif place == 2 then 
								spr(11, 24, self.y)
							elseif place == 3 then 
								spr(10, 24, self.y)
							end

							if button_map[button_y][button_x].name == self.name then
								make().panel(self.x, self.y, 56, 8, self.name, 6)
							else 
								make().panel(self.x, self.y, 56, 8, self.name)
							end
						else
							make().panel(self.x, self.y, 56, 8, self.name, 5)
						end
					end

					if scenes[active].name == "shop" and button_map[button_y][button_x].name == self.name then 
						if self.locked then 
							print("$"..self.price, self.x + 10, self.y + 2, 7)
						else
							print(self.name, self.x + 10, self.y + 2, 7)
						end
					end

					if self.color ~= nil and self.color[1] == stats.color then  --Highlights equipped color!
						rect(self.x, self.y, self.x+7, self.y+7, 7)
					end
					if sprite ~= nil and stats.hat == (sprite - 16) - (sprite-80)/2 then --Highlights equipped hat
						rect(self.x, self.y, self.x+7, self.y+7, 7)
					end

					if self.pressed then --Draws stats
						if self.name == "stats" then 
							make().panel(8, 8, 103, 32, "stats\n\nenergy: " .. flr(stats.energy) .. "   swim: ".. flr(stats.swim).."\nrun:    ".. flr(stats.run).."   hop:  " .. flr(stats.hop))     
						end 
					end
				end,
			})
		end,
		panel = function(x, y, width, height, text, color) --Draws a panel of the given specifications
		    local color = color or 1
			rectfill(x, y, x+width, y+height, color)
			rect(x,y,x+width,y+height, 7)
			print(text, x + 2, y + 2)
		end,
		label = function(x, y, width, height, text, color, border)
			local color = color or nil
			local border = border or nil
			make().object(x, y, 0, 0, 0, {
				draw = function(self)
					local txt = text
					if text == nil then txt = "$: " .. stats.coins end --Hack to update money number when buying things.
					if color ~= nil then rectfill(x, y, x+width, y+height, color) end
					if border ~= nil then 
						rect(x,y,x+width,y+height, border)
						print(txt, x + 2, y + 2)
					else
						print(txt, x + 2, y + 2, 7)
					end
				end,
			}) --UI equivalent of a panel. Exists as a standalone object. --Panel, but instead of a draw function it's an  object
		end,
		stat_box = function(stat, x, y, level)  -- Draws a stat bar with title
			make().object(x, y, 0, 0, 0,{
				stat = stat,
				level = level,
				draw = function(self)
					print(stat, self.x, self.y+1, 7)
					sspr(88, 16 , 8, 8, self.x, self.y + 8, 24, 8) --empty bar 
					sspr(96, 16 , 8, 8, self.x, self.y + 8, stats[self.level]*2, 8) --full bar
				end,
			})
		end,
		prompt_popup = function(text) --Pops up a panel that changes or resets scene
			local player = tools().get_object(scenes[active].scene_objects, "player")
			make().object(player.x, player.y, 0, 0, 0,{
				text = text,
				name = "prompt",
				draw = function(self)
					make().panel(tools().clamp(self.x-64, 0, 0, (scenes[active].width*8)-128)+32, 32, 64, 24, self.text)
				end,
				update = function(self)
					if btnp(🅾️) and #scenes[active].race_winners ~= scenes[active].number_of_racers then --Only resets scene if its not at the end of a race
						make().fade_into(scenes[active].name)
						del(scenes[active].scene_objects, self)
						scenes[active].xp_gained = 0
					elseif btnp(❎) then 
						make().fade_into("home")
						del(scenes[active].scene_objects, self)
					end
				end,
			})	
		end,
		--Tools/Functioning objects
		screen_scroller = function(start_speed, top_speed) --Screen scroller, moves tiles left at a changing speed.
			make().object(0, 0, 0, 0, start_speed, {
				name = "screen_scroller",
				start_speed = start_speed,
				top_speed = top_speed,
				speed_increase = start_speed/400, --Variable that decides the rate at which screen scrolling increases
				update = function(self) --Scrolls the screen at a predetermined speed
					--These are required because even though the scenes are drawn in same X position, the cells are different
					local ox = scenes[active].x -- x cell offset
					local oy = scenes[active].y -- y cell offset
					self.frame_increment -= 1
					if self.frame_increment < 0 then 
						for i = 0, 16 do --Scroll is set to 16 to prevent obstacle duplication.
							for j = 0, 15 do
								mset(i - 1 + ox, j+oy, mget(i+ox, j+oy))
							end
						end
						self.animation_delay = tools().clamp(self.animation_delay, -self.speed_increase, self.top_speed, self.start_speed)
						self.frame_increment = self.animation_delay
					end
				end,
			})
		end,
		obstacle_spawner = function(obs_y, cells_between_obstacles, random_spacing)
			--These variables are static upon initiation. Saves way more tokens.
			local screen_scroller = tools().get_object(scenes[active].scene_objects, "screen_scroller")
			local scn = scenes[active]
			local ox = scn.x -- x cell offset
			local oy = scn.y -- y cell offset
			make().object(0,0,0,0, cells_between_obstacles*screen_scroller.start_speed, { --The animation delay is the placement delay (Number of spaces between obstacles) times the time it takes to scroll a single block.
				speed_increase = (cells_between_obstacles*screen_scroller.start_speed)/400, -- obstacle spawning speed/400. This makes sure its equivalent to the screen scroller.
				top_speed = cells_between_obstacles * screen_scroller.top_speed, -- The fastest the screen can scroll
				cells_between_obstacles = cells_between_obstacles, 
				obstacle_spacing = random_spacing,
				start_speed = cells_between_obstacles * screen_scroller.start_speed, -- The speed the screen starts at
				obs_y = obs_y, --Where obstacles are placed on the y axis
				update = function(self)
					--These are required because even though the scenes are drawn in same X position, the cells are different
					self.frame_increment -= 1
					if self.frame_increment < 0 then
						if self.obs_y ~= nil then --If theres a defined y placement  
							mset(15+ox, self.obs_y+oy, self.get_spr())
							mset(15+ox, self.get_coin().y+oy, self.get_coin().spr)
							
						else --If y placement is undefined, place it at a random y coordinate
							for i = 0, flr(rnd(3)+1) do 
								mset(15+ox, flr(rnd(14)+1)+oy, self.get_spr())
							end
							mset(15+ox, flr(rnd(13)+1)+oy, self.get_coin().spr)
						end

						self.animation_delay = screen_scroller.animation_delay * self.cells_between_obstacles --Update animation delay to be equivocal to screen scrollers
						self.frame_increment = self.animation_delay
						self.frame_increment = tools().clamp(self.frame_increment, rnd(self.obstacle_spacing *2) -self.obstacle_spacing/2, self.top_speed, self.start_speed) --Sets obstacles apart by a random amount.
					end
				end,
				get_spr = function()
					local spr = scn.obstacle_sprites[flr(rnd(count(scn.obstacle_sprites)))+1] --Gets a random sprite from the scenes obstacle list

					if spr == 50 then --Sprite 50 is a log, this makes the log two high
						mset(15+ox, 11+oy, 50)
					elseif spr == 52 then --Produces lilypads. Lilypads are 2 wide
						mset(15+ox, 12+oy, 54)
						mset(14+ox, 12+oy, 53)
						mset(14+ox, 13+oy, 51)
					end
					return spr
				end,
				get_coin = function()
					local obj = {
						spr = flr(rnd(3)) + 59,
						y = 9 + flr(rnd(3)),
					}	
					if mget(15+scn.x, obj.y+scn.y) ~= 0 then 
						obj.y = 10
					end
					return obj
				end,
			})
		end,	
		fade_into = function(scn, race_num) --Scene switching functon. Makes a global object that uses the fade_scr tool function to fade in and out of a scene.
			make().object(0, 0, 0, 0, 1, {
				step = 0,
				step_amount = 0.1,
				race_num = race_num or nil,
				update = function(self)
					screen_fading = true --Freezes all inputs while fading
					self.frame_increment -= 1
					if self.frame_increment < 0 then 
						tools().fade_scr(self.step)
						self.frame_increment = self.animation_delay
						self.step += self.step_amount
					end
					if self.step > 1 then --if the screen is completely black, change scenes and start unfading.  
						self.step_amount = -self.step_amount
						self.step = 0.9
						initiate(scn, self.race_num)
					elseif self.step < 0 then --Once its unfaded, delete self from global objects.
						del(global_objects, self)
						screen_fading = false
					end 
				end,
			}, global_objects)
		end,
	}
	return obj
end

function input() 
--Stores inputs for every scene, but only when independent of player. Consider reworking.
	local obj = {
		home = function()
			local bmap = button_map[button_y][button_x]

			if btnp(❎) then
				if stats.num_seeds [1] > 0 then
					sfx(3) 
					make().seed()
					stats.num_seeds[1] -= 1
					stats.num_seeds[2] += 1
				end
			end

			if not panel_open then
				if btnp(⬅️) then
					sfx(1)
					button_x = tools().clamp(button_x, -1, 1, 3)
				end
				if btnp(➡️) then 
					sfx(1)
					button_x = tools().clamp(button_x, 1, 1, 3)
				end
				if btnp(⬆️) then
					sfx(1)
					button_y = tools().clamp(button_y, -1, 1, 2)
				end
				if btnp(⬇️) then 
					sfx(1)
					button_y = tools().clamp(button_y, 1, 1, 2)
				end
			end

			if btnp(🅾️) then
				sfx(2)
				bmap.pressed = not bmap.pressed
				panel_open = bmap.pressed
			end
		end,
		race_select = function()
			local bmap = button_map[button_y][button_x]
			if bmap.locked then button_y -= 1 end

			if btnp(❎) then
				sfx(9)
				make().fade_into("home")
			end

			if btnp(⬅️) then
				sfx(1)
				button_x = tools().clamp(button_x, -1, 1, 1)
			end
			if btnp(➡️) then 
				sfx(1)
				button_x = tools().clamp(button_x, 1, 1, 1)
			end
			if btnp(⬆️) then
				sfx(1)
				button_y = tools().clamp(button_y, -1, 1, 9)
			end
			if btnp(⬇️) then 
				sfx(1)
				button_y = tools().clamp(button_y, 1, 1, 9)
			end

			if btnp(🅾️) then
				bmap.pressed = not bmap.pressed
				panel_open = bmap.pressed
			end
		end,
		shop = function()
			local bmap = button_map[button_y][button_x]

			if btnp(❎) then
				sfx(9)
				make().fade_into("home")
			end

			if btnp(⬅️) then
				sfx(1)
				button_x = tools().clamp(button_x, -1, 1, #button_map[button_y])
				button_y = tools().clamp(button_y, 0, 1, #button_map)
			end
			if btnp(➡️) then 
				sfx(1)
				button_x = tools().clamp(button_x, 1, 1, #button_map[button_y])
				button_y = tools().clamp(button_y, 0, 1, #button_map)
			end
			if btnp(⬆️) then
				sfx(1)
				button_y = tools().clamp(button_y, -1, 1, #button_map)
				button_x = tools().clamp(button_x, 0, 1, #button_map[button_y])
			end
			if btnp(⬇️) then 
				sfx(1)
				button_y = tools().clamp(button_y, 1, 1, #button_map)
				button_x = tools().clamp(button_x, 0, 1, #button_map[button_y])
			end

			if btnp(🅾️) then
				bmap.pressed = not bmap.pressed
			end
		end,
		start = function()
			if btnp(🅾️) then
				
				make().fade_into("home")
			end
		end,
		--The following functions are empty, but replacing them with an if statement saves literally 0 tokens.
		run = function()
		end,
		swim = function()
		end,
		hop = function()
		end,
		race = function()
		end,

	}

	if not screen_fading then obj[scenes[active].name]() end
end

function tools()
	--Storage function that stores all my helper functions. In order to access a helper function, type tools().function_name
	local obj = {
		clamp = function(x1, x2, min, max)
		--Tool function, used to clamp a number between a min and max value 
			x3 = x1 + x2
			if x3 > max then
				return max 
			elseif x3 < min then
				return min 
			end 
			return x3
		end,
		in_list = function(list, item)
		-- Tool function to check if an object is in a list
			for i in all(list) do
				if i == item then return true end
			end 
		end,
		index = function(list, item) 
		--Returns index of item in list
			for i = 1, #list do
				if type(list[i]) == "table" then
					for j = 1, #list[i] do 
						if item == list[i][j] then return i end
					end
				end
				if item == list[i] then return i end
			end
		end,
		fade_scr = function(fa)
		--Changes screen color palette to fade to black
			fa=max(min(1,fa),0)
			local fn=8
			local pn=15
			local fc=1/fn
			local fi=flr(fa/fc)+1
			local fades={
				{1,1,1,1,0,0,0,0},
				{2,2,2,1,1,0,0,0},
				{3,3,4,5,2,1,1,0},
				{4,4,2,2,1,1,1,0},
				{5,5,2,2,1,1,1,0},
				{6,6,13,5,2,1,1,0},
				{7,7,6,13,5,2,1,0},
				{8,8,9,4,5,2,1,0},
				{9,9,4,5,2,1,1,0},
				{10,15,9,4,5,2,1,0},
				{11,11,3,4,5,2,1,0},
				{12,12,13,5,5,2,1,0},
				{13,13,5,5,2,1,1,0},
				{14,9,9,4,5,2,1,0},
				{15,14,9,4,5,2,1,0}
			}
			
			for n=1,pn do
				pal(n,fades[n][fi],1)
			end--Function found at: https://gist.github.com/smallfx/c46645b7279e7d64ec37
		end,
		get_object = function(list, obj_name)
		--Returns and object within a list 
			for obj in all(list) do
				if obj.name == obj_name then 
					return obj
				end
			end
		end,
	}

	return obj 
end

__gfx__
00000000000000000000000000000000000000000000000000000000666666661111111111111111000000000000000000000000111111111111111111111111
00000000000000000000000000000000000000000000000000000000666c66c6111c11c1111c11c1002fff0000566600009aaa00111111111111111111111111
0070070000000000000000000000000000000000000000000000000066ccc66611ccc11111c8811102fffff00566666009aaaaa0177171717771777117771777
0007700000000000000bbbb0000bbbb000000000000000000000000066ccccc611ccccc1118cc8c12fff222f566655569aaa999a171171711711777117171717
00077000000bbbb00001bb1000b1bb1000bbbbb0000bbbb00000000066ccccc611ccccc1118888c12ff2222f566555569aa9999a117177711711717117711777
0070070000b1bb1000bbaab00bbbaab00bb1bb1000b1bb10000bbbb0666ccc66111ccc11118888112ff22f2f566556569aa99a9a177177717771717117171717
000000000bbbaab00bbb00b0033b00b0033baab00bbbaab00bb1bb106cc666661cc111111cc1111102fffff00566666009aaaaa0111111111111111111111111
00000000033b00b00330000000000000000b00b0033b00b033bbaabb666666661111111111111111002fff0000566600009aaa00111111111111111111111111
0000000044444444000000000000000911119111000000000000000000000000bbbbbbbb0000000000000000cccccccc00000000111111111111111111111111
0011110044444444000000000000001111111191000000000000000000000000bbbbbbbb0000000000000000cccccccc00000000111111111111111111111111
0111111044444444000000000000019119111111000000000000000000000000bbbbbbbb0000000000aaa000cccccccc0b000bb0171717771777111117717771
1111111144444444000190000000111111111111000000000000000000000000bbbbbbbb0066600000a9a000ccc1111100b00b00171717171717111117117771
1111111144444444001111000001111111111911000090000000000000000000bbbbbbbb0069600000aaa0001111111100b00b00177717171777111117117111
1111111144444444011191100911911111191111001111000000010000000000bbbbbbbb0066600000030000111111110bb30b00171717771711111117717771
0111111044444444911111119191111111111111001191100011911000009100bbbbbbbb0003300000330000111111110300333b111111111111111111111111
0011110044444444119119111111111919111111019111900191119001911190bbbbbbbb000300000003000011111111033333b3111111111111111111111111
44444444777867771118611177777777111111117777777711111111777777771111111177777777111111110000000000000000111111111111111144444444
44444444788887771888811177777777111111117577775715111151777733771111331177777777111111110000000000000000111111111111111144444444
44444444788887771888811178777777181111117557755715511551777a3337111a333177777777111111115555555500000000177717171771111144444444
4445444488888777888881117879777718191111655665566556655677a3a33711a3a331777777771111111155555555aa00000017171717171711114445e4e4
44525444778867771188611178797777181911117557755715511551733a3a77133a3a11777777771111111155555555aa000000177117171717111144525e44
4455e444777767771111611178797e7718191e1175777757151111517333a7771333a11177777777111111115555555500000000171717771717111144554444
4444e444777767771111611178797e7718191e117777777711111111773377771133111177777777111111110000000000000000111111111111111144444444
444e4444777767771111611177777777111111117777777711111111777777771111111177777777111111110000000000000000111111111111111144444444
44444444000000000044440011333333333333110000000000000000000000000000000000016000000360000000000000000000000000006666666611111111
4444444400000000004444001113333333333111000000000000000000303b000000f00007171000033330000000000000000000000000006666f6661111f111
4444444400000000004444001111112222111111000000000000000003b33300000ff0000171700003333000000000000000000000000000666fff66111fff11
44511544000000000044440411111112211111110000000000000000b3333b3b000fff001717100033333000000aa000000000000000000066f99ff611f99ff1
44e1115400066600004444401111111221111111000000000000000003b3333000fff4000071600000336000000aa00000000000000000006ff9ff461ff9ff41
45622654006666600044440011111112211111110b333333333333b03333333b004f4400000060000000600000000000000000000000000064ff446614ff4411
45545444066666660044440011111122211111110bbbbbbbbbbbbbb0003333300044440000006000000060000000000000000000000000006664466611144111
44444444666666660044440011111122211111110333333333333330003b00000044440000006000000060000000000000000000000000006666666611111111
00000000000000000000000000000000000000000000000000000000000777000000000000000000000000000000000000070000000000000000000000000000
0a000000002222200880000000700000000000000000000000000000007777700000000000040040004000040004000007706000026220000000000000000000
00eee00000222220008bb00007a7ee000440004400a000a0056000560077777000dddd000004444000ff55ff0000400070066600602222000000000000900009
000eaee000ddddd003bbbbb3007eeee004f4444f009a8a9006e5656e007777700066666000499994000dddd00004f4f0006666600022622000444440000b00b0
00aee000022222220033333002222222004000040099999000500005009999900ddddddd0044444400dddddd004f4f4f005555500262222200444044ff000000
000000000000000000000000000000000000000000000000000000000777777700000000000000000000000000000000000000000000000000000000ff000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666111111116666666611111111666666661111111166666666111111116666666611111111666666661111111166666666111111116667766611177111
66666666111111116666666611111111666666661111111166666666111111116666666611111111666666661111111166666666111111116677776611777711
6a6666661a1111116622226611222211688666661881111166666666111111116666666611111111666666661111111166666666111111116677776611777711
66eee66611eee1116622226611222211668b6666118b1111666ee666111ee11164466446144114416a6666a61a1111a165d665d6156115616677776611777711
666eaee6111eaee166dddd6611dddd1163bbbb3613bbbb3166eeee6611eeee1164f444f614f444f169a88a9619a88a916de55de616e556e16699996611999911
66aee66611aee1116222222612222221663333661133331162222226122222216646664611411141699999961999999166566656115111516777777617777771
66666666111111116666666611111111666666661111111166666666111111116666666611111111666666661111111166666666111111116666666611111111
66666666111111116666666611111111666666661111111166666666111111116666666611111111666666661111111166666666111111116666666611111111
66666666111111116666666611111111666666661111111166666666111111116666666611111111666666661111111166666666111111116666666611111111
66666666111111116666666611111111666666661111111166666666111111116667666611171111666666661111111166666666111111116666666611111111
66666666111111116646646611411411646666461411114166466666114111116776d6661771611162d226661262211166666666111111116696669611911191
66ddd66611ddd11166444466114444116ff55ff61ff55ff16664666611141111766ddd6671166611d6222266612222116444446614444411666b6b66111b1b11
6677776611777711649999461499994166dddd6611dddd11664f4f66114f4f1166ddddd6116666616622d2261122622164446446144414416ff666661ff11111
6dddddd61dddddd164444446144444416dddddd61dddddd164f4f4f614f4f4f1665555561155555162d222221262222266666666111111116ff666661ff11111
66666666111111116666666611111111666666661111111166666666111111116666666611111111666666661111111166666666111111116666666611111111
66666666111111116666666611111111666666661111111166666666111111116666666611111111666666661111111166666666111111116666666611111111
11111111111111111111111111111111111111111111111111111111111551111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111115555111111111111111111111111111111111111151111111111111111111111111111
15111111115555111551111111111111111111111111111111111111115555111111111111511511151111511151111115515111155551111111111111511151
11555111115555111155111111155111155115511511115115511551115555111155511111555511155555511115111151155511515555111555551111151511
11155551115555111555555111555511155555511555555115555551115555111155551115555551115555111155551111555551115555511555155115511111
11555111155555511155551115555551115111511555555111511151155555511555555115555551155555511555555111555551155555551111111115511111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000a1000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000818100a300000000000000000000000000000000000000000000000000000000000000000000000000a30000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000009181811111818100000000000000000000000000000000000000000000000000000000000000000000008181810000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000008111111111111100000000000000000000000000000000000000000000000000000000000000000091811111110000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000081910000000000000000001111111111111100000000000000000000000000000000000000000000000000000000000000008181111111110000
00000000000000000000910000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a10000910081118100000000a1009393001111111111119100a19100000000939300c1c100000000000000000000c1919393000000a10081111111111111a100
0000c1c10000000000c181c1000000c1009393000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
818181818111111181818181818181810011111111111181818181818181818181008181b1b1b1b1b1b1b1b1b1b1818181810081818181111111111111118181
81818181b1b1b1b1b1818181b1b1b181818181000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111001111111111111111111111111111111100111111a2a2a2a2a2a2a21111111111110011111111111111111111111111
1111111111a2a2111111111111a21111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111001111111111111111111111111111111100111111111111111111111111111111110011111111111111111111111111
11111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c100000000000000a3000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008181b1b1b1b1b1b1b181910000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111a2a2a2a2a21111810000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000a30000000000000000000000000000000000000000000000000000000000000011111111111111111111118100
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000810000000000000000000000000000c10000000000000000000000000000000011111111111111111111111100
83000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000008111830000000000000000000000000081b1b1000000000000000000000000000011111111111111111111111183
23000000000000000000000000c100000000c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000081111123001383000000000000000000001111a2b1000000000000000000a193930011111111111111111111110023
2300000000000000830000000081b1b1b1b181000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000c100000000a100910093930011111123008123000000830091009393001111a2a2b1b1b1b1b1b1b1b1818181810011111111111111111111c1a123
23138313a1000000230000008111a2a2a2111181c100009393000000000000000000000000000000000000000000000000000000000000000000000000000000
00a30000138181818181818181818181001111112381112383000023a18181818100111111a2a2a2a2a2a2a2a211111111110011111111111111111111818181
818181818181130023818181111111a2111111118181818181000000000000000000000000000000000000000000000000000000000000000000000000000000
818113131111111111111111111111110011111181111181230000231111111111001111111111a2a2a2a2a2a211111111110011111111111111111111111111
11111111111181818111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111001111111111111111818111111111111100111111111111111111111111111111110011111111111111111111111111
11111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbb999999999999999999999999cccccccc8888888888888888111111119999999999999999111111116666666611111111
cccccccc777b77bb777b777bb77b7b7b977979797779777999999999cccccccc8888888888888888151111519999999999999999151111516666666611111111
cccccccc7bbb7b7b7bbb7b7b7bbb7b7b799979799799777999999999cccccccc8888888888888888155115519999999999999999155115516666666618111111
cccccccc77bb7b7b77bb77bb7bbb777b777979799799797999999999cccccccc888888888888888865566556999999999999999ground0level5566556666666
cccccccc7bbb7b7b7bbb7b7b7b7bbb7b997977799799797999999999cccccccc8888888888888888155115519999999999999999155115516666666618191111
cccccccc777b7b7b777b7b7b777b777b779977797779797999999999cccccccc8888888888888888151111519999999999999999151111516666666618191e11
ccccccccbbbbbbbbbbbbbbbbbbbbbbbb999999999999999999999999cccccccc8888888888888888111111119999999999999999111111116666666618191e11
ccccccccbbbbbbbbbbbbbbbbbbbbbbbb999999999999999999999999cccccccc8888888888888888111111119999999999999999111111116666666611111111
ccccccccbbbbbbbbbbbbbbbbbbbbbbbb999999999999999999999999cccccccc88888888888888888888888899999999999999999999999ground0level66666
ccccccccbbbbbbbbbbbbbbbbbbbbbbbb999999999999999999999999cccccccc88888888888888888888888899999999999999999999999ground0level66666
cccccccc111111111111111111111111111111111111111111111111cccccccc88888888888888888888888899999999999999999999999ground0level66666
ccccccccaaaaaaaaaaaaaaaaaaaaaaa1aaaaaaaa1111111111111111cccccccc88888888888888888888888899999999999999999999999ground0level66666
ccccccccaaaaaaaaaaaaaaaaaaaaaaa1aaaaaaaa1111111111111111cccccccc88888888888888888888888899999999999999999999999ground0level66666
cccccccc111111111111111111111111111111111111111111111111cccccccc88888888888888888888888899999999999999999999999ground0level66666
ccccccccbbbbbbbbbbbbbbbbbbbbbbbb999999999999999999999999cccccccc88888888888888888888888899999999999999999999999ground0level66666
ccccccccbbbbbbbbbbbbbbbbbbbbbbbb999999999999999999999999cccccccc88888888888888888888888899999999999999999999999ground0level66666
cccccccc888888888888888888888888eeeeeeeeeeeeeeeeeeeeeeeecccccccceeeeeeeeeeeeeeee111111116666666666666666111861116666666611111111
cccccccc7778787877888888888888887e7ee77e777eeeeeeeeeeeeecccccccceeeeeeeeeeeeeeee1511115166666666666666661888811166666666111aa111
cccccccc7878787878788888888888887e7e7e7e7e7eeeeeeeeeeeeecccccccceeeeeeeeeeeeeeee155115516666666666666666188881116666666611a11a11
cccccccc778878787878888888888888777e7e7e777eeeeeeeeeeeeecccccccceeeeeeeeeeeeeeee655665566666666666666666888881116666666611a11a11
cccccccc7878787878788888888888887e7e7e7e7eeeeeeeeeeeeeeecccccccceeeeeeeeeeeeeeee15511551666666666666666611886111666666661aaaaaa1
cccccccc7878877878788888888888887e7e77ee7eeeeeeeeeeeeeeecccccccceeeeeeeeeeeeeeee15111151666666666666666611116111666666661aaaaaa1
cccccccc888888888888888888888888eeeeeeeeeeeeeeeeeeeeeeeecccccccceeeeeeeeeeeeeeee11111111666666666666666611116111666666661aaaaaa1
cccccccc888888888888888888888888eeeeeeeeeeeeeeeeeeeeeeeecccccccceeeeeeeeeeeeeeee11111111666666666666666611116111666666661aaaaaa1
cccccccc888888888888888888888888eeeeeeeeeeeeeeeeeeeeeeeecccccccceeeeeeeeeeeeeeeeeeeeeeee6666666666666666666666666666666666666666
cccccccc888888888888888888888888eeeeeeeeeeeeeeeeeeeeeeeecccccccceeeeeeeeeeeeeeeeeeeeeeee6666666666666666666666666666666666666666
cccccccc111111111111111111111111111111111111111111111111cccccccceeeeeeeeeeeeeeeeeeeeeeee6666666666666666666666666666666666666666
ccccccccaaaaaaaaaaaaaaaaaaaaaa11aaaa11111111111111111111cccccccceeeeeeeeeeeeeeeeeeeeeeee6666666666666666666666666666666666666666
ccccccccaaaaaaaaaaaaaaaaaaaaaa11aaaa11111111111111111111cccccccceeeeeeeeeeeeeeeeeeeeeeee6666666666666666666666666666666666666666
cccccccc111111111111111111111111111111111111111111111111cccccccceeeeeeeeeeeeeeeeeeeeeeee6666666666666666666666666666666666666666
cccccccc888888888888888888888888eeeeeeeeeeeeeeeeeeeeeeeecccccccceeeeeeeeeeeeeeeeeeeeeeee6666666666666666666666666666666666666666
cccccccc888888888888888888888888eeeeeeeeeeeeeeeeeeeeeeeecccccccceeeeeeeeeeeeeeeeeeeeeeee6666666666666666666666666666666666666666
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc19ccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111cc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111911c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc91111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11911911
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc911119111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111191
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc19119111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccbbbbcccccccccccccccccccccccccccccccccccccccccccc1111111111911
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccb1bb1cccccccccccccccccccccccccccccccccccccccccc911911111191111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccbbbaabccccccccccccccccccccccccccccccccccccccccc9191111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc33bccbccccccccccccccccccccccccccccccccccccccccc1111111919111111
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444

__gff__
0000000000000000000000000000000000080000000101010800000000000000010000000000000000000a00000000010102020808080802020000040000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000181818181818181818181818181818181818181818181818181818181818181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002a2a2a2a2a2a0f1f2a0d0e2a2a2a0000000000000000000000000000000000000000000000103000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002a2a2a2a2a2a2a2a2a2a2a2a2a2a0000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002a2a2a2a2a2a2d2e2a1d1e2a2a2a000000000000000000000000000000000000000000200010000000000000002f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002a2a2a2a2a2a2a2a2a2a2a2a2a2a0000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000002f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000003000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000002f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000002f0000100000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00190000000000000000001a0000000000000000353635363536353635363536000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18181818181818181818181818181818002a2a2a3334333433343334333433342a2a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111002a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111100111111111111111111111111111111111100000000000000000000000000000000000000000000000000002f00300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000001b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018180000000000000000000000001800000000000000000000000000000000000000000c00000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018181111000000000000000000000018111a00000000000000000000000000000000000a0000000b0000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018111111113131000038000000000000111118000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001800000000000000000000000000000000000000001a1811111111111818000032000000003831111111000000000000000000000000000000000000000200000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003a38001811001c000000000000000000000000000000000019181111111111111111380032000000003218111111003800000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000181818323811113118000000000000000000000000000000191818111111111111111111320032003800003211111111183200000000000000000000000000000039000019390000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000019181111113232111118110000000000000000000000001c0018181111111111111111111111323832003238003211111111111800000000000000000000000000001918181818180000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000001818111111111818111111111b000000000000000000001c18181111111111111111111111111132323238321800321111111111111800000000000000000000000000181111111111181c000000000000000000000000
00190000000000000000001a00000000000000000000000000000000000000000000000000001a00181111111111111111111111112a1b1b1b1b1b1b1b1b1b1b181111111111111111111111111111111818323218110018111111111111110000001c003939000000311c181111111111111118381900000000000000000000
18181818181818181818181818181818180000000000000000000000000000000000000018181818111111111111111111111111112a2a2a2a2a2a2a2a2a2a2a111111111111111111111111111111111111183211111811111111111111111b1b1b18181818001a1c181811111111111111111118181c1a0000000000000000
1111111111111111111111111111111111000000001c0000001c00000000001c000000001111111111111111111111111111111111112a2a2a2a2a2a2a2a2a1111111111111111111111111111111111111111181111111111111111111111112a11111111110018181111111111111111111111111118180000000000000000
1111111111111111111111111111111111111111111111111111111111111111111111001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110011111111111111111111111111111111110000000000000000
__sfx__
49010000170301f13019030180000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001953008500060000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001b02027020290200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200000c74011040086401550004500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
490200001b51019150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
490300000b130156300f050300000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01080000170500e0500a050060500a050040500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
490200000b6500d150101500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050800002a1202c120351203212000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000e0500a050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1108000022130001002a130271001b1000b1002c100291002b1002c1002d1002e1002f100311003210034100141001510016100191001c1001e10021100231002510027100291002b1002c1002c1002c10000000
6101000013540185401d540225401a540255202750029500083002a5002e500083000930008300093000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
590f0000297402a7402b7402e7402b600265002e500367003670037700397003d7003f7002f7002e7002c7002c7002b7002a7002970028700287002770027700277003e50027700287002a7002d7002f70032700
01100000240552605025000290002b005250001900000000190051b000190002000019005250001900000000190001b000190002000019000250001900000000190001b000190002000019000250001900000000
011000000c050000000c050000000c050000000c050000000c050000000c050000000c050000000c050000000c050000000c050000000c050000000c050000000c050000000c050000000c050000000c05000000
79100000270202702027020270200000025020250202502022020220202202020020200201e0201b020190201b0201e02019020190201b0201e020190201e0201902019020190201b0201b0201b0201b0201e020
0110000013050180501305015050000001305018050130501505000000150501a050150501705000000150501a0501505017050000001705018050170501a0501a0501c0501c0501d0501f050170501505013050
0110000013050000001505000000170500000017050000001505000000130500000018050000001a050000001c050000001d0501f050000001c050000001a0500000018050000001705000000150500000013050
011000001f0500000021050000002305000000230500000021050000001f050000002405000000260500000028050000001d0501f0501c050000001a050000001805000000170500000015050000001305000000
000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
901000000f0000c0000a00007000040000300002000010000100001000010000100002000030000500006000080000b0000d0000e0000f000110001100011000110000f0000e0000b00009000090000800007000
__music__
03 4e4f5050
03 4e504f44
01 4e515244
02 4e524344
03 4f531444

