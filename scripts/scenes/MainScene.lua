local scheduler = require("framework.scheduler")

local MainScene = class("MainScene", function()
	return display.newScene("MainScene")
end)

local totalScore = 0
local bestScore = 0
local configFile = device.writablePath.."game.config"

math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )
local random = math.random

local matrix = {}
for i=1,32 do
    matrix[i] = {}
    for j=1,32 do
        matrix[i][j] = {x=i, y=j}
    end
end

local cells = {}
local dots = {}
local Grid = nil
local mySnake = nil

--方块的构造函数
Cell = {
	x,
	y,
}
function Cell:new(x, y, m, f)
	--args = args or {x=0, y=0}
	local this = {x=0, y=0, m=true, f=0}
	this.x = x
	this.y = y
	this.cellSprite = display.newSprite("cell.png", x*18-8, y*18-8)
	Grid:addChild(this.cellSprite)

	self.__index = self
	return setmetatable(this, self)
end

function Cell:disappear()
	self.cellSprite:removeSelf()
	self.cellSprite = nil
end

function Cell:move(dir)
	local dx
	local dy
	if dir=="up" then
		if self.y<32 then
			dy = 1
		else
			self.m = false
		end
		dx = 0
	elseif dir=="down" then
		if self.y>1 then
			dy = -1
		else
			self.m = false
		end
		dx = 0
	elseif dir=="left" then
		if self.x>1 then
			dx = -1
		else
			self.m = false
		end
		dy = 0
	elseif dir=="right" then
		if self.x<32 then
			dx = 1
		else
			self.m = false
		end
		dy = 0
	else
		dx = 0
		dy = 0
		self.m = false
	end

	--print("matrix[self.x+dx][self.y+dy].f: "..matrix[self.x+dx][self.y+dy].f)

	if matrix[self.x+dx][self.y+dy].f==0 then
		self.m = false
	end

	if ( self.m == true) then
		transition.execute(self.cellSprite, CCMoveTo:create(0, CCPoint((self.x+dx)*18-8, (self.y+dy)*18-8)), {
			onComplete = function()
				self.x = self.x+dx
				self.y = self.y+dy
				if matrix[self.x][self.y].t == "food" then
					self:eat(self.x, self.y)
					dropFood()
				end
				matrix[self.x][self.y]=self
			end,
		})

	end
	
end

function Cell:moveTo(x, y)
	if (x>0 and x<33) then
		if (y>0 and y<33) then
			matrix[self.x][self.y] = {self.x, self.y}
			transition.execute(self.cellSprite, CCMoveTo:create(0, CCPoint(x*18-8, y*18-8)), {
				onComplete = function()
					self.x = x
					self.y = y
					matrix[self.x][self.y]=self
				end,
			})
		else
			self.m = false
		end
	else
		self.m = false
	end
end

function Cell:eat(x, y)
	if matrix[x][y].t=="food" then
		matrix[x][y].dotSprite:removeSelf()
		matrix[x][y] = nil
		self.f=1
	end
end

--蛇的食物，构造和蛇的身体类似
Dot = {
	x,
	y,
}

function Dot:new(x, y, t)
    local this = {x=0, y=0, t="food"}
	this.x = x
	this.y = y
	this.dotSprite = display.newSprite("dot.png", x*18-8, y*18-8)
	Grid:addChild(this.dotSprite)

	self.__index = self
	return setmetatable(this, self)
end

--蛇的构造
Snake = {
	body,
	dir
}
function Snake:new(body, dir)
	local this = {}
	this.body = body or {Cell:new(1, 1)}
	this.dir = dir or "stay"
	for i=1,#this.body do
		matrix[this.body[i].x][this.body[i].y] = this.body[i]
	end

	self.__index = self
	return setmetatable(this, self)
end
function Snake:move(newDir)
	if newDir==nil then
		if self.dir=="stop" or self.body[1].m==false then
			--todo
		else
			self.body[1]:move(self.dir)
			for i=2,#self.body do
				self.body[i]:moveTo(self.body[i-1].x, self.body[i-1].y)
			end
		end
	else
		if newDir=="stop" then
			self.dir="stop"
		elseif self.dir=="stop" and newDir~=nil then
			self.dir = newDir
		elseif self.dir=="up"and newDir=="down" then
			--todo
		elseif self.dir=="down"and newDir=="up" then
			--todo
		elseif self.dir=="left"and newDir=="right" then
			--todo
		elseif self.dir=="right"and newDir=="left" then
			--todo
		elseif self.dir==newDir then
			--todo
		else
			self.dir=newDir
			self.body[1]:move(self.dir)
			for i=2,#self.body do
				self.body[i]:moveTo(self.body[i-1].x, self.body[i-1].y)
				matrix[self.body[i-1].x][self.body[i-1].y]=self.body[i]
			end
		end
	end


	if self.body[1].f==1 then
		table.insert(self.body, Cell:new(self.body[#self.body].x, self.body[#self.body].y))
		self.body[1].f = self.body[1].f - 1
	end

end


function MainScene:createButtons(x, y, k)
	local btnX = x
	local btnY = y
	local btnK = k

	local images = {
		normal = btnK.."_normal.png",
		pressed = btnK.."_pressed.png",
	}
	return cc.ui.UIPushButton.new(images, {scale9 = false})
		:setButtonLabel("normal", ui.newTTFLabel({
			text = "",
			size = 32
		}))
		:align(display.CENTER, btnX, btnY)
		:addTo(self)
end

function MainScene:ctor()

	Grid = CCLayerColor:create(ccc4(219, 219, 208, 255), 578, 578)
	Grid:setPosition(31, 302)
	self:addChild(Grid)

	local frame = display.newSprite("panel_"..random(4)..".png", display.cx, display.cy)
	frame:setOpacity(255)
	self:addChild(frame)

	self.gameTItle = cc.ui.UILabel.new({text = "SNAKE", size = 24, color = ccc3(88, 88, 88)})
		:align(display.CENTER, display.cx, display.top - 40)
		:addTo(self)

	--MainScene:initGame()

	matrix[3][12] = Dot:new(3, 12)

	--mySnake = Snake:new({Cell:new(3, 13), Cell:new(3, 12), Cell:new(3, 11), Cell:new(3, 10), Cell:new(3, 9), Cell:new(3, 8), Cell:new(3, 7), Cell:new(3, 6), Cell:new(3, 5), Cell:new(3, 4), Cell:new(3, 3), Cell:new(3, 2)}, "up")
	mySnake = Snake:new({Cell:new(3, 5), Cell:new(3, 4), Cell:new(3, 3), Cell:new(3, 2)}, "up")


	local arrowUp = self:createButtons(display.cx, display.bottom+220, "arrow_up"):onButtonClicked(function(event)
		--mySnake:move("up")
		mySnake.dir = "up"
	end)

	local arrowDown = self:createButtons(display.cx, display.bottom+60, "arrow_down"):onButtonClicked(function (event)
		--mySnake:move("down")
		mySnake.dir = "down"
	end)

	local arrowLeft = self:createButtons(display.cx-80, display.bottom+140, "arrow_left"):onButtonClicked(function (event)
		--mySnake:move("left")
		mySnake.dir = "left"
	end)

	local arrowRight = self:createButtons(display.cx+80, display.bottom+140, "arrow_right"):onButtonClicked(function (event)
		--mySnake:move("right")
		mySnake.dir = "right"
	end)

	local btnPause = self:createButtons(display.cx, display.bottom+140, "btn_pause"):onButtonClicked(function (event)
		--self:unscheduleUpdate()
		--self:unscheduleGlobal()
		-- if matrix[3][2].f then
		-- 	print("matrix[3][2].f: "..matrix[3][2].f)
		-- end
		
		dump(matrix[3])
	end) 

	local btnUp = cc.ui.UIPushButton.new({normal="btn_stop_normal.png", pressed="btn_stop_pressed.png"})
		:align(display.CENTER,display.cx+200, 140)
		:addTo(self)
		:onButtonClicked(function()
			mySnake:move("stop")
			--mySnake.dir = "stop"
		end)

	scheduler.scheduleGlobal(function()
            mySnake:move()
    end, 0.2)
end

-- function MainScene:initGame()
-- 	for i=1,32 do
-- 		for j=1,32 do
-- 			matrix[i][j] = Cell:new(i, j)
-- 		end
-- 	end
-- end


function MainScene:onEnter()

end

function dropFood()
	for i=1,#mySnake.body do
		matrix[mySnake.body[i].x][mySnake.body[i].y] = 1
	end
	local m = 1
    while m <= #matrix do
        local n = 1
        while n <= #matrix[m] do
            local cell = matrix[m][n]
            if cell==1 then
                table.remove(matrix[m], n)
            else
                n = n+1
            end
        end
        m = m+1
    end

    local pool = {}

	for i=1,#matrix do
		for j=1,#matrix[i] do
			table.insert(pool, {i, j})
		end
	end
	local dot = pool[random(#pool)]
	local x = dot[1]
	local y = dot[2]
	matrix[x][y] = Dot:new(x, y)
	
end


return MainScene
