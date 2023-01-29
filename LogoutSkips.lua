local f = CreateFrame('frame', nil, WorldMapPlayerLower)
f:SetAllPoints()

settings = {
  ['disabled'] = true,
  ['gy_disabled'] = true,
}

local showing = false
local gy_showing = false

local voronoi_lines_kalimdor = kalimdor_partitions
local voronoi_lines = eastern_kingdom_partitions
local gy_voronoi_lines = eastern_kingdom_gy_partitions
local gy_voronoi_lines_kalimdor = kalimdor_gy_partitions

-- This is all for drawing a line on the map in zones that we're not currently in
-- We could just draw our line outside of the scrollframe and rotate it, and to be honest that may even be a better approach

local function GetMapSize() -- Return dimensions and offset of current map
	local currentMapID = WorldMapFrame:GetMapID()
	if not currentMapID then return end
	
	local mapID, topleft = C_Map.GetWorldPosFromMapPos(currentMapID, {x = 0, y = 0})
	local mapID, bottomright = C_Map.GetWorldPosFromMapPos(currentMapID, {x = 1, y = 1})
	if not mapID then return end
	
	local left, top = topleft.y, topleft.x
	local right, bottom = bottomright.y, bottomright.x
	local width, height = left - right, top - bottom
	return left, top, right, bottom, width, height, mapID
end

local function GetIntersect(px, py, a, sx, sy, ex, ey)
	a = (a + PI / 2) % (PI * 2)
	local dx, dy = -math.cos(a), math.sin(a)
	local d = dx * (sy - ey) + dy * (ex - sx)
	if d ~= 0 and dx ~= 0 then
		local s = (dx * (sy - py) - dy * (sx - px)) / d
		if s >= 0 and s <= 1 then
			local r = (sx + (ex - sx) * s - px) / dx
			if r >= 0 then
				return sx + (ex - sx) * s, sy + (ey - sy) * s, r, s
			end
		end
	end
end

local function getRatio(x, x1, x2) 
  if (x2 - x1) == 0 then
    return 0 
  end
  return (x - x1)/(x2 - x1)
end

local function rectContains(px, py, bx1, by1, bx2, by2)
    if (px >= bx1 and px <= bx2) or (px <= bx1 and px >= bx2) then
      if py >= by1 and py <= by2 then
	return 1, getRatio(px, bx1, bx2),getRatio(py, by2, by1) 
      end
    end
    return nil
end

local function GetIntersect2(p1x, p1y, p2x, p2y, p3x, p3y, p4x, p4y)
    local denom = (p4y-p3y)*(p2x-p1x) - (p4x-p3x)*(p2y-p1y)
    if denom == 0 then
        return nil
    end
    local ua = ((p4x-p3x)*(p1y-p3y) - (p4y-p3y)*(p1x-p3x)) / denom
    if ua < 0 or ua > 1 then 
        return nil
    end
    local ub = ((p2x-p1x)*(p1y-p3y) - (p2y-p1y)*(p1x-p3x)) / denom
    if ub < 0 or ub > 1 then
        return nil
    end
    x = p1x + ua * (p2x-p1x)
    y = p1y + ua * (p2y-p1y)
    return x, y, (x - p3x) / (p4x - p3x), (y - p3y) / (p4y - p3y)
end

local WorldMapButton = WorldMapFrame:GetCanvas()

local WorldMapUpdated, PlayerFacing = false, 0


local function drawIcon(px, py, tex, cont_id) 
	if mapMapID == pMapID or onMap or sameInstanceish then else return end
	if not px then return end -- we somehow do not have coordinates
	--local left, top, right, bottom, width, height, mapMapID = GetMapSize()
	local left, top, right, bottom, width, height, mapMapID = GetMapSize()
	if not width or width == 0 then return end -- map has no size?


	local currentMapID = WorldMapFrame:GetMapID()
	local uiMapID, pos = C_Map.GetMapPosFromWorldPos(cont_id, {['x'] = px, ['y'] = py}, currentMapID)

	if pos.x < 0 or pos.x > 1  then return end
	if pos.y < 0 or pos.y > 1  then return end


	local mWidth, mHeight = WorldMapFrame:GetCanvas():GetSize()
	tex:SetPoint('CENTER', WorldMapButton, 'TOPLEFT', mWidth* pos.x, mHeight*-pos.y)
	tex:Show()
end

local function drawLine(px, py, p2x, p2y, _line, start_point, end_point) 
		start_point:ClearAllPoints()
		end_point:ClearAllPoints()
		_line:Hide()
		if mapMapID == pMapID or onMap or sameInstanceish then else return end
		if not px then return end -- we somehow do not have coordinates
		--local left, top, right, bottom, width, height, mapMapID = GetMapSize()
		local left, top, right, bottom, width, height, mapMapID = GetMapSize()
		if not width or width == 0 then return end -- map has no size?
		
		
		local sameInstanceish = pMapID == mapMapID
		local onMap = false
		if sameInstanceish and (px <= left and px >= right and py <= top and py >= bottom) then
			mx, my = (left - px) / width, (top - py) / height
			onMap = true
		end

		local function findAndSetPoint(_point_frame, px, py, ox, oy, left, bottom, right, top, mWidth, mHeight)
			local rectx, recty, _inside, _top, _bottom, _left, _right
			_inside, rectx, recty = rectContains(px,py, left, bottom, right, top)
			if _inside then
			  _point_frame:SetPoint('CENTER', WorldMapButton, 'TOPLEFT', mWidth * rectx, -mHeight * recty)
			  return 1
			end
			_top, _, rectx, recty = GetIntersect2(px,py, ox, oy, left, top, right, top)
			if _top then
			  _point_frame:SetPoint('CENTER', WorldMapButton, 'TOPLEFT', mWidth * rectx, 0)
			  return 1
			end

			_bottom,_, rectx, recty = GetIntersect2(px,py, ox, oy, left, bottom, right, bottom)
			if _bottom then
			  _point_frame:SetPoint('CENTER', WorldMapButton, 'BOTTOMLEFT', mWidth * rectx, 0)
			  return 1
			end

			_left,_, rectx, recty = GetIntersect2(px,py, ox, oy, left, top, left, bottom)
			if _left then
			  _point_frame:SetPoint('CENTER', WorldMapButton, 'TOPLEFT', 0, -mHeight * recty)
			  return 1
			end

			_right,_, rectx, recty = GetIntersect2(px,py, ox, oy, right, top, right, bottom)
			if _right then
			  _point_frame:SetPoint('CENTER', WorldMapButton, 'TOPRIGHT', 0, -mHeight * recty)
			  return 1
			end
			return nil
		end

		local mWidth, mHeight = WorldMapFrame:GetCanvas():GetSize()
		if findAndSetPoint(start_point, px, py, p2x, p2y, left, bottom, right, top, mWidth, mHeight) and findAndSetPoint(end_point, p2x, p2y, px, py, left, bottom, right, top, mWidth, mHeight) then
			_line:Show()
		end
end


local LineFrame = CreateFrame('frame', nil, WorldMapButton)
LineFrame:SetAllPoints()
LineFrame:SetFrameLevel(15000)


line_frames = {}
start_points = {}
end_points = {}
lines = {}

for i=1,#voronoi_lines do
	local start_point = CreateFrame('frame', nil, LineFrame)
	start_point:SetSize(1, 1)
	table.insert(start_points, start_point)
	local end_point = CreateFrame('frame', nil, LineFrame)
	end_point:SetSize(1, 1)
	table.insert(end_points, end_point)
	local Line = LineFrame:CreateLine(nil, 'OVERLAY')
	Line:Hide()
	Line:SetTexture('interface/buttons/white8x8')
	Line:SetVertexColor(0.8, .2, .2, 0.6)
	Line:SetThickness(2)
	Line:SetStartPoint('CENTER', start_point, 0, 0)
	Line:SetEndPoint('CENTER', end_point, 0, 0)
	table.insert(lines, Line)
end

gy_start_points = {}
gy_end_points = {}
gy_lines = {}

for i=1,#gy_voronoi_lines do
	local start_point = CreateFrame('frame', nil, LineFrame)
	start_point:SetSize(1, 1)
	table.insert(gy_start_points, start_point)
	local end_point = CreateFrame('frame', nil, LineFrame)
	end_point:SetSize(1, 1)
	table.insert(gy_end_points, end_point)
	local Line = LineFrame:CreateLine(nil, 'OVERLAY')
	Line:Hide()
	Line:SetTexture('interface/buttons/white8x8')
	Line:SetVertexColor(0.0, 0.0, 0.0, 0.8)
	Line:SetThickness(2)
	Line:SetStartPoint('CENTER', start_point, 0, 0)
	Line:SetEndPoint('CENTER', end_point, 0, 0)
	table.insert(gy_lines, Line)
end

line_frames_kalimdor = {}
start_points_kalimdor = {}
end_points_kalimdor = {}
lines_kalimdor= {}

for i=1,#voronoi_lines_kalimdor do
	local start_point = CreateFrame('frame', nil, LineFrame)
	start_point:SetSize(1, 1)
	table.insert(start_points_kalimdor, start_point)
	local end_point = CreateFrame('frame', nil, LineFrame)
	end_point:SetSize(1, 1)
	table.insert(end_points_kalimdor, end_point)
	local Line = LineFrame:CreateLine(nil, 'OVERLAY')
	Line:Hide()
	Line:SetTexture('interface/buttons/white8x8')
	Line:SetVertexColor(0.8, .2, .2, 0.6)
	Line:SetThickness(2)
	Line:SetStartPoint('CENTER', start_point, 0, 0)
	Line:SetEndPoint('CENTER', end_point, 0, 0)
	table.insert(lines_kalimdor, Line)
end

gy_start_points_kalimdor = {}
gy_end_points_kalimdor = {}
gy_lines_kalimdor = {}

for i=1,#gy_voronoi_lines_kalimdor do
	local start_point = CreateFrame('frame', nil, LineFrame)
	start_point:SetSize(1, 1)
	table.insert(gy_start_points_kalimdor, start_point)
	local end_point = CreateFrame('frame', nil, LineFrame)
	end_point:SetSize(1, 1)
	table.insert(gy_end_points_kalimdor, end_point)
	local Line = LineFrame:CreateLine(nil, 'OVERLAY')
	Line:Hide()
	Line:SetTexture('interface/buttons/white8x8')
	Line:SetVertexColor(0.0, 0.0, 0.0, 0.8)
	Line:SetThickness(2)
	Line:SetStartPoint('CENTER', start_point, 0, 0)
	Line:SetEndPoint('CENTER', end_point, 0, 0)
	table.insert(gy_lines_kalimdor, Line)
end

points_ = {}
texs_ = {}

for _,v in ipairs(eastern_kingdom_locs) do
  local p = CreateFrame('frame', nil, LineFrame)
  p:SetHeight(40)
  p:SetWidth(40)
  local tex = p:CreateTexture(nil, 'OVERLAY')
  tex:SetTexture("Interface\\Addons\\LogoutSkips\\Media\\icon_x.blp")
  tex:SetDrawLayer("OVERLAY", 4)
  tex:SetHeight(15)
  tex:SetWidth(15)
  tex:Hide()
  table.insert(points_, p)
  table.insert(texs_, tex)
end

eastern_kingdom_gy_points_ = {}
eastern_kingdom_gy_texs_ = {}

for _,v in ipairs(eastern_kingdom_gy_locs) do
  local p = CreateFrame('frame', nil, LineFrame)
  p:SetHeight(40)
  p:SetWidth(40)
  local tex = p:CreateTexture(nil, 'OVERLAY')
  tex:SetTexture("Interface\\Addons\\LogoutSkips\\Media\\icon_x.blp")
  tex:SetDrawLayer("OVERLAY", 4)
  tex:SetHeight(15)
  tex:SetWidth(15)
  tex:Hide()
  tex:SetVertexColor(0,0,0,1)
  table.insert(eastern_kingdom_gy_points_, p)
  table.insert(eastern_kingdom_gy_texs_, tex)
end

points_kalimdor_ = {}
texs_kalimdor_ = {}

for _,v in ipairs(kalimdor_locs) do
  local p = CreateFrame('frame', nil, LineFrame)
  p:SetHeight(40)
  p:SetWidth(40)
  local tex = p:CreateTexture(nil, 'OVERLAY')
  tex:SetTexture("Interface\\Addons\\LogoutSkips\\Media\\icon_x.blp")
  tex:SetDrawLayer("OVERLAY", 4)
  tex:SetHeight(15)
  tex:SetWidth(15)
  tex:Hide()
  table.insert(points_kalimdor_, p)
  table.insert(texs_kalimdor_, tex)
end

kalimdor_gy_points_ = {}
kalimdor_gy_texs_ = {}

for _,v in ipairs(kalimdor_gy_locs) do
  local p = CreateFrame('frame', nil, LineFrame)
  p:SetHeight(40)
  p:SetWidth(40)
  local tex = p:CreateTexture(nil, 'OVERLAY')
  tex:SetTexture("Interface\\Addons\\LogoutSkips\\Media\\icon_x.blp")
  tex:SetDrawLayer("OVERLAY", 4)
  tex:SetHeight(15)
  tex:SetWidth(15)
  tex:Hide()
  tex:SetVertexColor(0,0,0,1)
  table.insert(kalimdor_gy_points_, p)
  table.insert(kalimdor_gy_texs_, tex)
end

local function update()
	if settings['disabled'] and showing then
	  for _,v in ipairs(lines) do
	      v:Hide()
	  end
	  for _,v in ipairs(lines_kalimdor) do
	      v:Hide()
	  end

	  for i,v in ipairs(eastern_kingdom_locs) do
	    texs_[i]:Hide()
	  end
	  for i,v in ipairs(kalimdor_locs) do
	    texs_kalimdor_[i]:Hide()
	  end
	  showing = false
	  return 
	end

	if settings['gy_disabled'] and gy_showing then
	  for _,v in ipairs(gy_lines) do
	      v:Hide()
	  end
	  for _,v in ipairs(gy_lines_kalimdor) do
	      v:Hide()
	  end

	  for i,v in ipairs(eastern_kingdom_gy_locs) do
	    eastern_kingdom_gy_texs_[i]:Hide()
	  end
	  for i,v in ipairs(kalimdor_gy_locs) do
	    kalimdor_gy_texs_[i]:Hide()
	  end
	  gy_showing = false
	  return 
	end

	if settings['disabled'] == false then
		local currentMapID = WorldMapFrame:GetMapID()
		local cont, _ = C_Map.GetWorldPosFromMapPos(currentMapID, {x = 0, y = 0})

		if cont == 0 and currentMapID ~= 947 then 
		  for i,v in ipairs(voronoi_lines) do
			drawLine(v[1], v[2], v[3], v[4], lines[i], start_points[i], end_points[i])
		  end
		  for _,v in ipairs(lines_kalimdor) do
		      v:Hide()
		  end
		elseif cont == 1 and currentMapID ~= 947 then
		  for i,v in ipairs(voronoi_lines_kalimdor) do
			drawLine(v[1], v[2], v[3], v[4], lines_kalimdor[i], start_points_kalimdor[i], end_points_kalimdor[i])
		  end
		  for _,v in ipairs(lines) do
		      v:Hide()
		  end
		else
		  for _,v in ipairs(lines) do
		      v:Hide()
		  end
		  for _,v in ipairs(lines_kalimdor) do
		      v:Hide()
		  end
		end

		for i,v in ipairs(eastern_kingdom_locs) do
		  texs_[i]:Hide()
		  if cont == 0 and currentMapID ~= 947 then
			  drawIcon(v[2], v[1], texs_[i], 0)
		  end
		end

		for i,v in ipairs(kalimdor_locs) do
		  texs_kalimdor_[i]:Hide()
		  if cont == 1 and currentMapID ~= 947 then
			  drawIcon(v[2], v[1], texs_kalimdor_[i], 1)
		  end
		end

		WorldMapUpdated = false
		showing = true
      end

      if settings['gy_disabled'] == false then
	      local currentMapID = WorldMapFrame:GetMapID()
	      local cont, _ = C_Map.GetWorldPosFromMapPos(currentMapID, {x = 0, y = 0})

	      if cont == 0 and currentMapID ~= 947 then 
		for i,v in ipairs(gy_voronoi_lines) do
		      drawLine(v[1], v[2], v[3], v[4], gy_lines[i], gy_start_points[i], gy_end_points[i])
		end
		for _,v in ipairs(gy_lines_kalimdor) do
		    v:Hide()
		end
	      elseif cont == 1 and currentMapID ~= 947 then
		for i,v in ipairs(gy_voronoi_lines_kalimdor) do
		      drawLine(v[1], v[2], v[3], v[4], gy_lines_kalimdor[i], gy_start_points_kalimdor[i], gy_end_points_kalimdor[i])
		end
		for _,v in ipairs(gy_lines) do
		    v:Hide()
		end
	      else
		for _,v in ipairs(gy_lines) do
		    v:Hide()
		end
		for _,v in ipairs(gy_lines_kalimdor) do
		    v:Hide()
		end
	      end

	      for i,v in ipairs(eastern_kingdom_gy_locs) do
		eastern_kingdom_gy_texs_[i]:Hide()
		if cont == 0 and currentMapID ~= 947 then
			drawIcon(v[2], v[1], eastern_kingdom_gy_texs_[i], 0)
		end
	      end

	      for i,v in ipairs(kalimdor_gy_locs) do
		kalimdor_gy_texs_[i]:Hide()
		if cont == 1 and currentMapID ~= 947 then
			drawIcon(v[2], v[1], kalimdor_gy_texs_[i], 1)
		end
	      end

	      WorldMapUpdated = false
	      gy_showing = true
    end
end


LineFrame:SetScript('OnUpdate', function(self, elapsed)
  if WorldMapUpdated == false then 
    return 
  end
  update()
end)

hooksecurefunc(WorldMapFrame, 'OnMapChanged', function()
	WorldMapUpdated = true
end)

if settings['disabled'] then
  LogoutSkips_Toggle:SetText("Show LogoutSkips")
else
  LogoutSkips_Toggle:SetText("Hide LogoutSkips")
end

function LogoutSkips_Toggle_Click()
  settings['disabled'] = not settings['disabled']
  if settings['disabled'] then
    LogoutSkips_Toggle:SetText("Show LogoutSkips")
  else
    LogoutSkips_Toggle:SetText("Hide LogoutSkips")
  end
  update()
end

function DeathSkips_Toggle_Click()
  settings['gy_disabled'] = not settings['gy_disabled']
  if settings['gy_disabled'] then
    DeathSkips_Toggle:SetText("Show DeathSkips")
  else
    DeathSkips_Toggle:SetText("Hide DeathSkips")
  end
  update()
end
