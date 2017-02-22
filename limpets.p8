pico-8 cartridge // http://www.pico-8.com
version 10
__lua__
-- vim: set ft=lua ts=1 sw=1 noet:
--current game state
state=nil
--table of all game states
states={}
--default states
states.splash={}
states.briefing={}
states.play={}
states.summary={}
states.gameover={}
-- all activities
activity={}
activity.mining={}
activity.collection={}
activity.rescue={}
activity.piracy={}
activity.fuelratting={}
-- legacy
activities={}
--hack
--global event timer
objtimer=0
--limpet list
limpets={}
current_limpet=0
names={"huey","dewey","louie","tick","trick","track","groucho","chico","zeppo","harpo","alvin","simon","theodore","curly","larry","moe","barry","robin","maurice","alan","wayne","merrill","jay","donny","marie","jimmy"}
limpet_colors={{12,1},{10,4},{14,2},{11,3},{13,5},{9,4},{8,3},{7,5}}
--mission status
mission={}
mission_number=0

function states.splash:init()
	dead_this_game={}
	self.next_state="briefing"
	self:init_activities_missions()
	current_limpet=1
end

function states.splash:draw()
	cls()
	local pc=9
	rect(4,4,123,123,pc)
	camera(-8,-8)
	print("limpet control",0,0,pc)
	print("--------------",0,6,pc)
	print("retrieve space junk",4,12,pc)
	print("drop it when bay is green",4,18,pc)
	print("avoid laser",4,24,pc)

	print("‹‘”ƒ to control thrust",4,36,pc)
	print("hold — (z key) to grab",4,42,pc)

	print("get correct item to refuel",4,54,pc)
	print("complete mission to restock",4,66,pc)
	print("(c)	3303 sYNpLEASURE ents.",4,104,pc)
	camera()
end

function states.splash:update()
	if(btnp(4) or btnp(5)) then update_state() end
end

function states.splash:init_activities_missions()
	mission_number=0 -- starts with 0
	activity.mining={
			name="mining",
			verb="mine",
			material=0,
			scooprect={60,103,68,111}, -- aabb rect coords
			objects={16,17,18,19,20,21},
			missions={{{16,1}},{{18,2},{20,2}},{{21,3},{18,2},{19,1}}},
			init=function(state)
			end,
			draw_bg=function(state)
				-- asteroid
				circfill(64,-64,80,5)
				for i in all(state.burn_decals) do
					palt(0,false)
					palt(5,true)
					spr(24,i.x,i.y)
					palt()
				end

				camera(state.foffx,state.foffy)
				-- mining laser
				if(state:laser_on()) then
					local lcolor = 2
					if(flr(objtimer)%2==0)then
						lcolor = 14
					end
					line(state.lorigx,state.lorigy,state.laserx,state.lasery,lcolor)
				end
				camera()
			end,
			draw_hud=function(state)
				-- laser indicator
				if (state.laser>0)then
					line(state.lorigx,126,state.lorigx,117+(state.laser/(state.laserson*30))*10,12)
				else
					line(state.lorigx,126,state.lorigx,117-(state.laser/(state.lasersoff*30))*10,2)
				end
			end,
			spawn_objects=function(state)
				if(state:laser_on())then
					if(objtimer % (20+flr(rnd(5)-2.5)) == 0)then
						obj = spawn_object(state,state.laserx,state.lasery,rnd(1)-0.5,rnd(1)+0.2,mission.objects[flr(rnd(#mission.objects))+1],30*8,0,true)
						add(state.burn_decals,{x=state.laserx-4,y=state.lasery-4,ttl=15})
						state:make_explosion(obj,obj.vx,obj.vy)
						sfx(7)
					end
				end
			end,
			envt_update=function(state)
				update_laser(state)
			end,
			envt_damage=function(state)
				do_laser_check(state)
			end,
			check_fail=function(state)
			end
			}
	activity.collection={
			name="collection",
			verb="collect",
			material=1,
			scooprect={57,103,71,111},
			objects={26,27,28,29,30,31},
			missions={{{26,1}},{{27,2},{28,2}},{{29,3}}},
			init=function(state)
				init_static_objects(state)
			end,
			draw_bg=function(state)
			end,
			draw_hud=function(state)
			end,
			spawn_objects=function(state)
			end,
			envt_update=function(state)
			end,
			envt_damage=function(state)
			end,
			check_fail=function(state)
			end
	}
	activity.rescue={
			name="rescue",
			verb="rescue",
			material=2,
			scooprect={60,103,68,111},
			objects={36},
			missions={{{36,1}},{{36,2}},{{36,3}}},
			init=function(state)
				init_static_objects(state,true)
			end,
			draw_bg=function(state)
				-- type-6 hull
				map(8,0,32,0,8,2)
				palt(0,false)
				palt(5,true)
				spr(24,48,0)
				spr(24,76,-2,1,1,true)
				palt()
			end,
			draw_hud=function(state)
			end,
			spawn_objects=function(state)
			end,
			envt_update=function(state)
				--wreck sparks
				local interval=((5+flr(rnd(3)-1.5))*3)
				if(objtimer%interval==0)then
					state:make_explosion({x=rnd(64)+32,y=rnd(16),material=0},0,0)
				end
			end,
			envt_damage=function(state)
				do_laser_check(state)
			end,
			check_fail=function(state)
				return not state:critical_objects_present()
			end
	}
	activity.fuelratting={
			name="fuelratting",
			verb="refuel",
			material=0,
			scooprect={60,16,68,24},
			objects={35},
			missions={{{35,1}},{{35,2}},{{35,3}}},
			init=function(state)
			end,
			draw_bg=function(state)
				draw_other_ship()
			end,
			draw_hud=function(state)
			end,
			spawn_objects=function(state)
			end,
			envt_update=function(state)
			end,
			envt_damage=function(state)
			end,
			check_fail=function(state)
			end
	}
	activity.piracy={
			name="piracy",
			verb="pirate",
			material=1,
			scooprect={60,103,68,111},
			objects={26},
			missions={{{26,1}},{{26,2}},{{26,3}}},
			init=function(state)
			end,
			draw_bg=function(state)
				camera(state.foffx,state.foffy)
				local lcolor=9
				if(state:laser_on()) then
					if(objtimer%20<10)then
						line(state.lorigx,state.lorigy,state.laserx,state.lasery,lcolor)
					end
					-- target shield
					local shield_color=(objtimer%2==0 and 12 or 1)
					if(state.tshldf)then
						shield_color=12
						state.tshldf=false
					end
					circ(state.tshldx,state.tshldy,state.tshldr,shield_color)
				end

				draw_other_ship()

				if(objtimer%2==0)then -- thrust of both ships
					map(0,2,92,-4,2,1)
					map(0,2,96,120,2,1)
				end
				camera()
			end,
			draw_hud=function(state)
			end,
			spawn_objects=function(state)
				if(state:laser_on())then
					if(objtimer % 30 == 0)then
						obj = spawn_object(state,64,10,rnd(1)-0.5,rnd(1)+0.2,mission.objects[flr(rnd(#mission.objects))+1],30*8,0,true)
					end
				end
				if(state.limpet.health>0)then
					if(objtimer%3==0)then
						-- fire pdt
						state.pdt = objtimer % ((state.laserson/2+state.lasersoff*2)*30) - state.lasersoff*2*30
						if(state.pdt>0 and distance(state.x,state.y,80,6)<40)then
							sol=intercept({x=80,y=6},state,2)
							if(sol)then
								vx,vy=aimpoint_to_v_comps({x=80,y=6},sol,2)
								--bang
								spawn_object(state,80,6,vx,vy,41,60,1,true)
							end
						end
					 -- target shield effects
						if(state:hit_shield(state.tshldx,state.tshldy,state.tshldr,state)) then
							state.tshldf=true
							state:make_explosion(state,0,0)
							state.limpet.health-=state:laser_damage()
							if(state.limpet.health<0)then
								state:do_death()
							end
						end
					end
				end
			end,
			envt_update=function(state)
				update_laser(state)
				-- scroll bg stars when in motion
				for star in all(state.stars) do
					star.x+=0.4
					if(star.x>127)then star.x-=127 end
				end
			end,
			envt_damage=function(state)
				do_laser_check(state)
			end,
			check_fail=function(state)
			end
	}
	add(activities,activity.piracy)
	add(activities,activity.mining)
	add(activities,activity.rescue)
	add(activities,activity.fuelratting)
	add(activities,activity.collection)
end

function states.briefing:init()
	self.next_state="play"
	populate_limpets()
	self:init_mission()
end

function states.briefing:draw()
	cls()
	local pc=9
	rect(4,4,123,123,pc)
	camera(-8,-8)
	local h=draw_limpets_status(0,false,current_limpet)
	draw_mission_status(h+6)
	camera()
end

function states.briefing:update()
	objtimer+=1
	if(btnp(3))then
		current_limpet=next_live_limpet_index()
	end
	if(btnp(4) or btnp(5))then
		update_state()
	end
end

function states.briefing:init_mission()
	-- assumes game is made up of n activities x m missions
	-- this will break if activities do not each have the same number of missions
	local missioncount = #activities[1].missions
	local activity_i=flr(mission_number / missioncount)+1
	local mission_i=(mission_number % missioncount)+1
	printh("mission_number "..mission_number..", #missions "..missioncount..", activity_i "..activity_i..", mission_i "..mission_i)
	local activity=activities[activity_i]
	local mission_data=activity.missions[mission_i]
	mission={}
	mission.name=activity.name
	mission.objects=activity.objects
	mission.verb=activity.verb
	mission.material=activity.material
	mission.scooprect=activity.scooprect
	mission.required={}
	mission.complete=false
	printh("mission: "..mission.name..", verb: "..mission.verb)
	for m in all(mission_data) do
		add(mission.required,{obj=m[1],count=m[2],got=0})
		printh("  obj: "..m[1]..", count: "..m[2])
	end
end

function states.play:init()
	sfx(6)
	tinc=0.05
	tdec=tinc*2
	tmax=1
	maxv=3
	self.lindex=current_limpet
	self.limpet=limpets[self.lindex]
	self.next_state="briefing"
	self.foffx=0
	self.foffy=0
	self.shldx=64
	self.shldy=160
	self.shldr=64
	self.tshldx=64
	self.tshldy=-32
	self.tshldr=50
	self.lorigx = 40
	self.lorigy = 113
	self.laser=0
	self.laserx=0
	self.lasery=0
	self.laserson=7
	self.lasersoff=2 -- fixme 8
	self.x=60
	self.y=105
	self.vx=0
	self.vy=0
	self.tx=0
	self.ty=0
	self.txneg=false
	self.txpos=false
	self.tyneg=false
	self.typos=false
	self.grabber_cooldown=0
	self.grabbed=false
	self.object=nil
	self.stars={}
	self.particles={}
	self.burn_decals={}
	self.deathtimer=0

	self.objects={}
	self.stars={}
	self.dead_this_mission={}
	--local testrock={}
	--testrock.x = 64
	--testrock.y = 32
	--testrock.vx = 0
	--testrock.vy = 0
	--testrock.c = 0
	--add(self.objects,testrock)

	-- init background objects
	for i=1,100 do
		local star = {}
		star.x = rnd(128)
		star.y = rnd(128)
		add(self.stars,star)
	end

	activity[mission.name].init(self)
end

function states.play:draw()
	cls()
	-- frame offset for motion effect
	if(mission.name=="piracy")then
		self.foffx=rnd(2)
		self.foffy=rnd(2)
	end
	-- background
	-- stars
	for i=1,#self.stars do
	local star=self.stars[i]
		line(star.x,star.y,star.x,star.y,(objtimer*i%2==0) and 12 or 1)
	end
	-- here goes nothing
	activity[mission.name].draw_bg(self)

	draw_own_ship(self)

	local spare=0
	for i=1,#limpets do
		local limpet=limpets[i]
		local x
		-- don't draw active limpet here
		if(limpet==self.limpet)then goto continue end
		spare+=1
		if(spare==1) then
			x=21
		else
			x=100
		end
		local spritenum = (limpet.health>0 and i-1 or 25)
		pal(13,limpet.fg)
		pal(5,limpet.bg)
		spr(spritenum,x,120)
		pal()
  ::continue::
	end

	-- foreground objects
	-- drone
	pal(13,self.limpet.fg)
	pal(5,self.limpet.bg)
	spr(self.lindex-1, self.x, self.y)
	spr(22,self.x-8,self.y)
	spr(23,self.x+8,self.y)
	pal()

	-- grabbed object
	if(self.object != nil)then
	spr(self.object.c,self.x,self.y-8)
	end

	-- grabber
	if(self.grabbed)then
	spr(15, self.x, self.y-8)
	else
	spr(14, self.x, self.y-8)
	end	

	-- thrust
	local toff=0
	local tmin=0.001
	local tbig=tmax*0.66
	if(self.txneg)then
		sfx(2)
		if(abs(self.tx)>tbig) then
			toff=5
		end
		spr(4+toff,self.x+8, self.y)
	end
	if(self.txpos)then
		sfx(2)
		if(abs(self.tx)>tbig) then
			toff=5
		end
		spr(5+toff,self.x-8, self.y)
	end
	if(self.tyneg)then
		sfx(2)
		if(abs(self.ty)>tbig) then
			toff=5
		end
		spr(8+toff,self.x, self.y+8)
	end
	if(self.typos)then
		sfx(2)
		if(abs(self.ty)>tbig) then
			toff=5
		end
		spr(6+toff,self.x-8, self.y)
		spr(7+toff,self.x+8, self.y)
	end

	-- other objects
	for item in all(self.objects)do
		if(item != self.object) then
			local soffset=0
			-- special cased animation for spacemen
			if(item.c==36)then
				soffset = flr((objtimer%20) / 5)
			end
			spr(item.c+soffset, item.x, item.y)
		end
	end

 -- particles
	for p in all(self.particles) do
		local pcolor=0
		-- flames
		if(p.kind==0)then
			pcolor = p.ttl > 12 and 10 or (p.ttl > 7 and 9 or 8)
		end
		-- scrap
		if(p.kind==1)then
			pcolor = p.ttl > 12 and 7 or (p.ttl > 7 and 6 or 7)
		end
		-- gore
		if(p.kind==2)then
			pcolor = p.ttl > 12 and 8 or (p.ttl > 7 and 2 or 1)
		end
		line(p.x,p.y,p.x-p.xv,p.y-p.yv,pcolor)
	end

	-- hud
 -- health
	local hpercent=self.limpet.health/100
	rect(126,126,127,127-hpercent*127,hpercent > 0.8 and 3 or (hpercent>0.5 and 11 or (hpercent>0.2 and 9 or 8)))

	activity[mission.name].draw_hud(self)

	-- required items
	self:draw_shopping_list()

 -- debug
	if(false) then
		print("vx:"..self.vx, 0, 100, 7)
		print("vy:"..self.vy, 45, 100, 7)
		print("tx:"..self.tx, 0, 107, 7)
		print("ty:"..self.ty, 45, 107, 7)
		print("i:"..(self.object and self.object.c or '%'), 0, 114, 7)
	end
	print(self.limpet.name,96,2,9)
end

function states.play:draw_shopping_list()
	local count=1
	for reqt in all(mission.required) do
		if(reqt.got < reqt.count) then
			spr(reqt.obj,2+(count-1)*7,1)
			count+=1
		end
	end
	rect(0,0,2+(count-1)*8,10,9)
end

function states.play:update()
	local vx = self.vx
	local vy = self.vy
	local x = self.x
	local y = self.y
	local grabbed = self.grabbed

	-- controls
	self.txpos=false
	self.txneg=false
	self.typos=false
	self.tyneg=false

	if(self.limpet.health>0)then
		if(btn(4)) then
			if(not grabbed and self.grabber_cooldown==0) then
				sfx(0)
				grabbed = true
				self.grabber_cooldown=30
			end
		else
			grabbed = false
		end

		if(self.grabber_cooldown>0) then
			self.grabber_cooldown-=1
		end

		if(btn(0)) then
			self.txneg=true
		end
		if(btn(1)) then
			self.txpos=true
		end
		if(btn(2)) then
			self.tyneg=true
		end
		if(btn(3)) then
			self.typos=true
		end
	else -- dead
		self.deathtimer-=1
		if(self.deathtimer==2*30 or self.deathtimer==30)then
			self:make_explosion(self,0,0)
		end
		if(self.deathtimer==15)then
		 -- explosion sfx
		end
		if(self.deathtimer==0)then
			self.next_state="summary"
			update_state()
		end
	end

	-- set thrust from thruster flags
	-- x thrust
	if(self.txneg)then
		self:consume_fuel()
		self.tx=max(self.tx-tinc, -tmax)
	else
		if(self.txpos)then
			self:consume_fuel()
			self.tx=min(self.tx+tinc, tmax)
		else
			if(abs(self.tx)<0.01)then
				self.tx=0
			else
				self.tx-=self.tx/4
			end
		end
	end
	-- y thrust
	if(self.tyneg)then
		self:consume_fuel()
		self.ty=max(self.ty-tinc, -tmax)
	else
		if(self.typos)then
			self:consume_fuel()
			self.ty=min(self.ty+tinc, tmax)
		else
			if(abs(self.ty)<0.01)then
				self.ty=0
			else
				self.ty-=self.ty/4
			end
		end
	end
	-- apply acceleration
	vx+=self.tx
	vy+=self.ty
	-- abs limits
	vx=clamp(vx,-maxv,maxv)
	vy=clamp(vy,-maxv,maxv)
	-- drag
	vx-=vx/12
	vy-=vy/12
	-- null out residuals
	if (abs(vx) < 0.005) then
		vx = 0
	end
	if (abs(vy) < 0.005) then
		vy = 0
	end
	-- update position
	x+=vx
	y+=vy
	if(x<=0 or x>=120)then vx=0 self.tx=0 end
	if(y<=0 or y>=120)then vy=0 self.ty=0 end
	x=clamp(x,0,120)
	y=clamp(y,0,120)

	-- save temporaries
	self.vx = vx
	self.vy = vy
	self.x = x
	self.y = y
	self.grabbed = grabbed

	-- update event timer
	objtimer+=1

	activity[mission.name].spawn_objects(self)

	activity[mission.name].envt_update(self)

	activity[mission.name].envt_damage(self)

	-- move objects
	for item in all(self.objects) do
		-- piracy: ships in motion
		if(mission.name=="piracy")then
			item.x+=0.4
		end
		item.x += item.vx
		item.y += item.vy
		item.vx-=item.vx/(rnd(25)+75)
		item.vy-=item.vy/(rnd(25)+75)
		if(item.ttl!=-1)then
			item.ttl-=1
		end
		local dead=false
		if(self:hit_shield(self.shldx,self.shldy,self.shldr,item) and item!=self.object) then
			self.shldf=true
			dead=true
		end
		if(item.x>128 or item.y>128 or item.ttl==0)then
			dead=true
		end
		if(dead)then
			sfx(9)
			self:make_explosion(item,item.vx,-item.vy)
			del(self.objects,item)
		end
	end

	-- object release
	if(not self.grabbed and self.object)then
		sfx(1)
		-- in scoop?
		if (self:in_scoop())then
			self:do_score(self.object)
			if(self:is_mission_complete())then
				sfx(5)
				mission_number+=1
				self.next_state="summary"
				update_state()
			end
			del(self.objects,self.object)
			self.object=nil
		else
			self.object.x=self.x
			self.object.y=self.y-10
			self.object.vx=self.vx
			self.object.vy=self.vy-0.5
			self.object=nil
		end
	end

	-- collision detection
	for item in all(self.objects) do
		-- is it within the grab area
		-- the grab area is 8 pixels above the drone +- 4
		local x = self.x
		local y = self.y
		if(self.object==nil)then
			if(self.grabbed==true and item.x > x-6 and item.x < x+6 and item.y > y-12 and item.y < y-8)then
				self.object=item
			end
		end
		-- crashes
		if(item.collision and item!=self.object)then
			if(item.x > x-6 and item.x < x+6 and item.y > y-6 and item.y < y+6)then
				self.limpet.health-=collision_damage(item,self)
				if(self.limpet.health<0)then
					self:do_death()
				end
				sfx(9)
				self:make_explosion(item,item.vx,item.vy)
				del(self.objects,item)
			end
		end
	end

	if(activity[mission.name].check_fail(self))then
		self.limpet.health=0
		self:do_death()
	end

	for p in all(self.particles) do
		p.x += p.xv
		p.y += p.yv
		p.xv *= 0.95
		p.yv *= 0.95
	end
	age_transients(self.burn_decals)
	age_transients(self.particles)
end

function states.play:critical_objects_present()
	-- this needs to be updated on scoop
	local criticals_outstanding={}
	for i in all(mission.required) do
		for j=1,i.count do
			add(criticals_outstanding,i.obj)
		end
	end

	for i in all(criticals_outstanding)do
		for j in all(self.objects)do
			if(j.c==i) then
				del(criticals_outstanding,i)
				break;
			end
		end
	end
	return #criticals_outstanding == 0
end

function states.play:make_explosion(point,xv,yv)
	xv=xv or 0
	yv=yv or 0
	for i=1,8 do
		add(self.particles,{x=point.x,y=point.y,xv=xv+rnd(2)-1,yv=yv+rnd(2)-1,ttl=20,kind=point.material})
	end
end

function states.play:consume_fuel()
	self.limpet.health-=0.33
	if(self.limpet.health<30)then
		sfx(3,3)
	end
	if(self.limpet.health<=0)then
		self:do_death()
	end
end

function states.play:do_death()
	if(self.deathtimer==0)then
		sfx(-1,3)
		sfx(-1,2)
		self.limpet.health=0
		self.deathtimer=3*30
		self:make_explosion(self,0,0)
		self.txneg=false
		self.txpos=false
		self.tyneg=false
		self.typos=false
		self.grabbed=false
		self.tx=0
		self.ty=0
	end
end

function states.play:do_score(item)
	for i in all(mission.required) do
		if(i.obj==item.c)then
			self.limpet.health=min(self.limpet.health+20,100)
			if(self.limpet.health>=30)then
				sfx(-1,3)
			end
			i.got+=1
			self:do_drone_score(item)
			break
		end
	end
end

function states.play:do_drone_score(item)
	local found=false
	for i in all(self.limpet.score) do
		if(i.obj==item.c)then
			i.count+=1
			found=true
			break;
		end
	end
	if(not found) then
		add(self.limpet.score,{obj=item.c,count=1})
	end
end

function states.play:hit_shield(sx,sy,sr,item)
	local i_off_x=item.x-sx
	local i_off_y=item.y-sy
	return((i_off_x*i_off_x + i_off_y*i_off_y) < (sr * sr))
end

function states.play:in_scoop()
	return (self.x>mission.scooprect[1] and self.x<mission.scooprect[3] and self.y>mission.scooprect[2] and self.y<mission.scooprect[4])
end

function states.play:is_mission_complete(dropped_object)
	local complete = true
	for i in all(mission.required) do
		complete = complete and (i.count<=i.got)
	end
	mission.complete=complete
	return complete
end

function states.play:laser_hit()
	p0={x=self.x+1,y=self.y}
	p1={x=self.x+6,y=self.y}
	p2={x=self.x+6,y=self.y+7}
	p3={x=self.x+1,y=self.y+7}
	drone_hit_box={p0,p1,p2,p3}
	return line_intersects_convex_poly(self.lorigx,self.lorigy,self.laserx,self.lasery,drone_hit_box)
end

function states.play:laser_damage()
	return 2
end

function states.play:laser_on()
	return self.laser > 0 and self.limpet.health > 0
end

function spawn_object(state,x,y,vx,vy,c,ttl,material,collision)
	printh("collision: "..(collision and "true" or "false").."material: "..material)
	local obj={}
	obj.x=x
	obj.y=y
	obj.vx=vx
	obj.vy=vy
	obj.c=c
	obj.ttl=ttl
	obj.material=material
 obj.collision=collision
	add(state.objects,obj)
	return obj
end

-- 3 way switch: play(next life), briefing(new mission), gameover
function states.summary:init()
	sfx(-1,2)
	sfx(-1,3)
	if(mission.complete)then
		self:reap_dead_limpets()
		self.next_state="briefing"
	else
		if(self:they_are_all_dead())then
			self:reap_dead_limpets()
			self.next_state="gameover"
		else
			if(limpets[current_limpet].health<=0)then
				current_limpet=next_live_limpet_index()
			end
			self.next_state="play"
		end
	end
end

function states.summary:draw()
	cls()
	local pc=9
	rect(4,4,123,123,pc)
	camera(-8,-8)
	local not_in_mission=(mission.complete or self:they_are_all_dead())
	local h=draw_limpets_status(0,true,(not_in_mission and 0 or current_limpet))
	h=draw_mission_status(h+6,not_in_mission)
	draw_rip_status(h,states.play.dead_this_mission)
	camera()
end

function states.summary:update()
	objtimer+=1
	if(btnp(3))then
		current_limpet=next_live_limpet_index()
	end
	if(btnp(4) or btnp(5)) then
		for i in all(states.play.dead_this_mission) do
			add(dead_this_game,i)
		end
		self.dead_this_mission={}
		update_state()
	end
end

function states.summary:reap_dead_limpets()
	for limpet in all(limpets)do
		if(limpet.health<=0)then
			add(states.play.dead_this_mission,limpet.name)
			del(limpets,limpet)
		end
	end
end

function states.summary:they_are_all_dead()
	return next_live_limpet_index()==0
end

function states.gameover:init()
	sfx(4)
	self.next_state="splash"
end

function states.gameover:draw()
	cls()
	local pc=9
	rect(4,4,123,123,pc)
	camera(-8,-8)
	print("/ame over :(",0,0,9)
	draw_rip_status(12,dead_this_game)
	camera()
end

function states.gameover:update()
	if(btnp(4) or btnp(5)) then
		dead_this_game={}
		update_state()
	end
end

function update_state()
	local next_state=states[state].next_state
	if(next_state)then
		state=next_state
		states[state]:init()
	end
end

function collision_damage(o1,o2)
	local dx=o1.vx-o2.vx
	local dy=o1.vy-o2.vy
	local vsquared=(dx*dx+dy*dy)
	return vsquared*5
end

function age_transients(transient_array)
	for t in all(transient_array) do
		t.ttl-=1
			if t.ttl < 0 then
				del(transient_array,t)
			end
	end
end

function clamp(val,minv,maxv)
	return max(minv,min(val,maxv))
end

function aimpoint_to_v_comps(src,aim,pv)
	local dy = aim[2]-src.y
	local dx = aim[1]-src.x
	local a=atan2(dx,dy)
	local shotvx=pv*cos(a)
	local shotvy=pv*sin(a)
	return shotvx,shotvy
end

function intercept(src,dst,v)
	local tx=(dst.x-src.x)/4
	local ty=(dst.y-src.y)/4
	local tvx=dst.vx/4
	local tvy=dst.vy/4
	local v = v/4

	-- get quadratic components
	local a = tvx*tvx + tvy*tvy - v*v
	local b = 2*(tvx*tx+tvy*ty)
	local c = tx*tx + ty*ty
	assert( c>0)

	-- solve quadratic
 local ts = quad(a,b,c)

 -- find smallest positive solution
	local sol = nil
	if(ts != nil)then
		local t0=ts[1]
		local t1=ts[2]
		printh("t0: "..t0..",t1: "..t1)
		local t=min(t0,t1)
		if(t<0)then
			t=max(t0,t1)
		end
		if(t>0)then
			sol={(dst.x+dst.vx*t),(dst.y+dst.vy*t)}
		end
	end
	return sol
end

function quad(a,b,c)
	local sol=nil
	if(abs(a)<0.00001)then
		if(abs(b)<0.00001)then
			if (abs(c)<0.00001) then
				printh("a,b,c are zero")
				sol={0,0}
			end
		else
			sol={-c/b,-c/b}
		end
	else
		local disc = b*b-4*a*c
		if(disc>=0)then
			disc=mysqrt(disc)
			assert(disc!=32768)
			a=2*a
			sol={(-b-disc)/a,(-b+disc)/a}
		else
			printh("disc is negative")
		end
	end
	return sol
end

function mysqrt(x)
	if x <= 0 then return 0 end
	local r = sqrt(x)
	if r < 0 then return 32768 end
	return r
end

function distance(x1,y1,x2,y2)
	local x=x1-x2
	local y=y1-y2
	return mysqrt(x*x+y*y)
end

function do_laser_check(state)
	-- has laser hit limpet?
	local hit
	local hx
	local hy
	hit,hx,hy=state:laser_hit()
	if(hit)then
		-- only do laser damage on every 3rd update
		if(objtimer % 3 == 0)then
			state:make_explosion({x=hx,y=hy},0,0)
			state.limpet.health-=state:laser_damage()
			if(state.limpet.health<0)then
				state:do_death()
			end
		end
	end
end

function draw_other_ship()
	map(8,0,32,0,8,2)
end

function draw_own_ship(state)
	camera(state.foffx,state.foffy)
	-- ship hull
	map(0,0,32,112,8,2)
	-- drop indicator
	if((objtimer%15)<7 and state.object)then
		local sr=mission.scooprect
		local icolor=9
		if(state:in_scoop())then
			icolor=12
		end
		line(sr[1],sr[2],sr[1]-1,sr[2]-1,icolor)
		line(sr[1],sr[4],sr[1]-1,sr[4]+1,icolor)
		line(sr[3],sr[2],sr[3]+1,sr[2]-1,icolor)
		line(sr[3],sr[4],sr[3]+1,sr[4]+1,icolor)
	end
	local shield_color=1
	if(state.shldf)then
		shield_color=12
		state.shldf=false
	end
	-- ship shield
	circ(state.shldx, state.shldy, state.shldr, shield_color)
	camera()
end

function draw_limpets_status(yorig,score,active)
	yorig=yorig or 0
	score=score or false
	active=active or 0
	local pc=9
	print("your limpets"..(active>0 and " (ƒ cycle)" or ""),0,yorig,pc)
	yorig+=6
	for i=1,#limpets do
		local limpet = limpets[i]
		if(active == i and objtimer % 30 < 15)then
			spr(34,0,yorig)
		end
		print(""..i..". "..limpet.name.." : "..limpet.health.."%",4,yorig,limpet.health>0 and limpet.fg or 5)
		yorig+=6
		if(score and #limpet.score>0)then
			for i=1,#limpet.score do
				local score_item=limpet.score[i]
				print(score_item.count,8+11*i,yorig,(score_item.count>2 and (score_item.count>4 and 10 or 6) or 9))
				spr(score_item.obj, 12+11*i-1,yorig-1)
			end
			yorig+=6
		end
	end
	return yorig
end

function draw_mission_status(yorig, retro)
	yorig=yorig or 0
	retro=retro or false
	local pc=9
	print("your "..((mission_number==0 or retro) and "" or "next ").."mission "..(retro and "was " or "is ").."to "..mission.verb,0,yorig,pc)
	yorig+=6
	for j=1,#mission.required do
		local requirement=mission.required[j]
		local i=requirement
		spr(requirement.obj,4,yorig)
		print(' x ',12,yorig,12)
		print(requirement.count.." ("..requirement.got..")",24,yorig,requirement.got>=requirement.count and 11 or 8)
		yorig+=6
	end
	if(mission.complete)then
		yorig+=6
		print("well done!!!",0,yorig,pc)
		yorig+=6
	end
	return yorig
end

function draw_rip_status(yorig,dead_list)
	yorig=yorig or 0
	if(#dead_list>0)then
		yorig+=6
		print("rip ",0,yorig,9)
		for i=1,#dead_list do
			print(dead_list[i],16+(i-1)*4*6,yorig,4)
		end
		yorig+=6
	end
	return yorig
end

function init_static_objects(state,collision)
	-- create array of object types containing required ones
	local objs={}
	for i in all(mission.required) do
		for j=1,i.count do
			add(objs,i.obj)
		end
	end

	for i in all(objs) do
		spawn_object(states.play,rnd(100+10),rnd(80)+20,0,0,i,-1,mission.material,collision)
	end
end

function line_intersects_convex_poly(x1,y1,x2,y2,poly)
	-- returns bool,x,y (hit, one point of intersection if hit)
	local hit
	local hitx
	local hity
	local point1
	local point2
	for i=1,count(poly) do
		if i<count(poly) then
			point1 = poly[i]
			point2 = poly[i+1]
		else
			point1 = poly[i]
			point2 = poly[1]
		end
		hit,hitx,hity=line_intersects_line(x1,y1,x2,y2,point1.x,point1.y,point2.x,point2.y)
		if hit then return hit,hitx,hity end
	end
	return false,0,0
end

function line_intersects_line(x0,y0,x1,y1,x2,y2,x3,y3)
	local s
	local t
	local s1x = x1-x0
	local s1y = y1-y0
	local s2x = x3-x2
	local s2y = y3-y2
	local denom=-s2x*s1y+s1x*s2y
	s=(-s1y*(x0-x2)+s1x*(y0-y2))/denom
	t=(s2x*(y0-y2)-s2y*(x0-x2))/denom
	if(s>=0 and s<=1 and t>=0 and t<=1) then
		-- intersection!
		return true,x0+t*s1x,y0+t*s1y
	else
		return false,0,0
	end
end

function next_live_limpet_index()
	local i = current_limpet
	if(#limpets==0)then
		return 0
	end
	while(true)do
		i+=1
		-- back to start and none alive
		if(i==current_limpet)then
			i=0
			break
		end
		if(i>#limpets)then
			i=1
		end
		if(limpets[i].health>0)then
			break
		end
	end
	return i
end

function populate_limpets()
	-- renew the gang
	assert(#names>0)
	while(#limpets<3)do
		colorscheme=limpet_colors[1]
		add(limpets,{name=names[1],health=100,score={},fg=colorscheme[1],bg=colorscheme[2]})
		del(limpet_colors,colorscheme)
		add(limpet_colors,colorscheme)
		del(names,names[1])
	end
end

function update_laser(state)
	-- move laser aim
	state.laserx=64+sin((objtimer%100)/100)*20
	state.lasery=8+cos((objtimer%100)/100)*5

	-- update laser state
	state.laser = objtimer % ((state.laserson+state.lasersoff)*30) - state.lasersoff*30
	if(state.laser>0)then
		sfx(8,2)
	else
		sfx(-1,2)
	end

	-- laser burn trace
	if(state.laser>0 and objtimer % 2 == 0)then
		add(state.particles,{x=state.laserx,y=state.lasery,xv=0,yv=0,ttl=10})
	end
end

function _init()
	state="splash"
	states[state]:init()
end

function _draw()
	states[state]:draw()
end

function _update()
	states[state]:update()
end
__gfx__
0dddddd00dddddd00dddddd000000000000000000000000000000001100000000000000000000000000000000000000cc0000000000cc0000000000000000000
0d00dd500d000d500d000d500000000000000000000000000000000cc0000000000cc00000000000000000000000000cc000000000cccc000000000000000000
0dd0dd500ddd0d500dd00d5000000000000000000000000000000000000000000001100000000000000000000000000000000000001cc1000000000000000000
ddd0dd5ddd0ddd5ddddd0d5d000000000c100000000001c00000000000000000000000000cc1000000001cc00000000000000000000110000300003000033000
0d000d500d000d500d000d500000000000000000000000000000000000000000000000000000000000000000000000000000000000011000b030030b00b33b00
0ddddd500ddddd500ddddd500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b000000b00b00b00
0ddddd500ddddd500ddddd5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0000b00b0000b0
05555550055555500555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0000b00b0000b0
00000000000000000000000000000000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000000000000
004440000033300000bbb00000ccc000002220000099900000000000000000005550505500022000000000000000000000000000000000000000000000000000
04004400030033000b00bb000c00cc0002002200090099000000000dd00000005050055500022000000777000007760000077600000677000007770000067700
04044400030333000b0bbb000c0ccc0002022200090999000000000dd00000005502200502222220007666600077766000666660006666600066667000667770
04444000033330000bbbb0000cccc000022220000999900000000000000000005002805502222220007666600077766000666660006666600066667000667770
004400000033000000bb000000cc0000002200000099000000000000000000005550050500022000000655000006650000066500000566000005560000056600
00000000000000000000000000000000000000000000000000000000000000005505055500022000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005555555500022000000000000000000000000000000000000000000000000000
0000000000000000ccc0000000333300000000000000000000000c0000c00000000000c000000000000000000000000000000000000000000000000000000000
0000000000ccc000ccc000000ab000b0000c0c0000c0000000000c00000c0000000c0c0c00000000000000000000000000000000000000000000000000000000
000677000cc0cc00ccc000003b303333000cc0c00c0c0c0000c0c00ccc0c00000000ccc000000000000000000000000000000000000000000000000000000000
0066666000c0c0000c0000003b300353000ccc0000ccc000000cccc000ccccc000cccccc000b0000000000000000000000000000000000000000000000000000
0066666000ccc000c0c00000033035300cccc0000ccccc0000ccc000000ccc000c00c00000000000000000000000000000000000000000000000000000000000
000566000c0c0c000000000000333300c00c0c000000c0cc0c0cc00000c0c0c0000c000000000000000000000000000000000000000000000000000000000000
000000000c0c0c00000000000000000000c000000000c00000c0c00000000c00000c000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000c0000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000bbbbb0000000000000000000000000000000000000000000000000000000000077777000000000000000000000000000000000000000000000
00000000000bbb00000bbbbbbbbbbbbbbbbbbbbb0000000000000000b00000000000000000077700000777777777777777777777000000000000000070000000
00000000bbb00333bbb000000b00000000000000bbbb0000000000bb0bb000000000000077700000777000000700000000000000777700000000007777700000
0000bbbb00033bbb000333330b0333333330bbb00000bbbb0000bb00300bb0000000777700000777000000000700000000007770000077770000770000077000
0003b00033bbb000333333330b0333333333000333330000bbbb003333300bb00007700000777000000000000700000000000000000000007777000000000770
003eb333bb0003333333333330b0333333333333333333330000bbbb3330b0b0007c700077000000000000000070000000000000000000000000777700000070
03eeb3bb003333300333333330b03333333333333333333333330000bbbb30b007cc707700000000000000000070000000000000000000000000000077770070
03eebb003333330cc033333330b000000333333333333003333333330000bbb007cc770000000007700000000070000000000000000000000000000000007770
03333b000003333003333333330bbbbbb000000333330cc0333333333333330b0777770000000007700000000007777770000000000007700000000000000007
03eeeebbbbb0000003333333333000000bbbbbb000000003333333333333330b07cccc7777700000000000000000000007777770000000000000000000000007
003eeebe000bbbbb00000333333333333000000bbbbbb000003333333333000b007ccc7c00077777000000000000000000000007777770000000000000000007
000333eebb000000bbbbb000003333333333333000000bbbbb0000003330cc0b000777cc77000000777770000000000000000000000007777700000000007707
00000033bbb000bb00000bbbbb000000333333333333300000bbbbbb0000000b0000007777700000000007777700000000000000000000000077777700000007
000000000b0bbb000333300000bbbbbb000000333333333333000000bbbbbbbb0000000007077700000000000077777700000000000000000000000077777777
0000000000b000bbb000333333000000bbbbbb0000003333333333330000000b0000000000700077700000000000000077777700000000000000000000000007
00000000000bb0000bbb000333333333000000bbbbbb0000003333333333330b0000000000077000077700000000000000000077777700000000000000000007
00002cc20eeee020eeeee02000020eeeeeeeeeeeeeeeeeeeeeeeeee02e0200000000000000000000000000000000000000000000000000000000000000000000
00002cc20eeee020eeeee02222220eeeeeeeeeeeeeeeeeeeeeeeeee02e0200000000000000000000000000000000000000000000000000000000000000000000
00002cc200000020eeeeee000000eeeeeeeeeeeeeeeeeeeeeeeeeee02e0200000000000000000000000000000000000000000000000000000000000000000000
0000222222222220eeeeee0000eeeeeeeeeeeee0000eeeeeeeeeeee02e0200000000000000000000000000000000000000000000000000000000000000000000
00002cc200000020eeeee088880eeeeeeeeeee088880eeeeeeeee0002e0200000000000000000000000000000000000000000000000000000000000000000000
000002c20eeee020eeeee088880eeeeeeeeeee088880eeeeee000222e02000000000000000000000000000000000000000000000000000000000000000000000
000000222000e020eeeeee0000eeeeeeeeeeeee0000eeee00022200e020000000000000000000000000000000000000000000000000000000000000000000000
00000000022200200000000000000000000000000000000222000ee0200000000000000000000000000000000000000000000000000000000000000000000000
000c100000222222222222222222222222222222222222200eeee022000000000000000000000000000000000000000000000000000000000000000000000000
00cc1c10000022000000000000000000000222222222002220000200000000000000000000000000000000000000000000000000000000000000000000000000
0c7ccc1000000022eeeeeeeeeeeeeeeeee2000000000000002222000000000000000000000000000000000000000000000000000000000000000000000000000
077777cc000000002222222222222222220000000000000000000000cc1110000000000000000000000000000000000000000000000000000000000000000000
077777cc000000000000000000000000000000000000000000000000cc1110000000000000000000000000000000000000000000000000000000000000000000
0c7ccc10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cc1c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4041424344454647606162636465666700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50515253545556573f7172737475763f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200000c3200c3300a3300230022350233502435022340233000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001e33021350213401d330213000b3300c3400c3400b3300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000039610396103a6003a60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000d0a5000a5000a5002b5002c500005003335035350333503535033350005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000e0000310503604024050280401b0501e0400605006050060200601000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007000013050131500010013050131500010013050131501a1001805018150101001805018150181001805018150001001f0501f1501d1001f0501f150001001f0501f1501f1002405024150240502414024140
00130000182501a2401c25020240202401d2402024020240202001d2002020024200182001a2001c20022200182001a2001c20021200182001a2001c200202001e2001d200202000020000200002000020000200
000200002f6410565130651056512f6510565128651066512065111641106310d6310b6210a621096210962108621076210761105611056110561103611000010000100001000010000100001000010000100001
000300032154019130046100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000f6300d640126500d650126500d650126400d6300b62009610086100d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

