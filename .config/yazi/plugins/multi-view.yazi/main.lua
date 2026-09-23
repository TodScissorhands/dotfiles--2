--- @since 26.5.6
--- @sync entry

-- Multi-View Plugin for Yazi (Cleaned & Simplified)
-- Displays native Yazi tabs simultaneously in an automatic btop-style structural grid:
--   1 tab  -> Native Yazi (all multi-view chrome visually disabled)
--   2 tabs -> Equal split
--   3 tabs -> 2 views on top + 1 full-width view below (2+1)
--   4 tabs -> Equal 2x2 grid
-- Navigation: Alt+Left/Right/Up/Down, Alt+Tab, Alt+Shift+Tab, Mouse click.
-- Toggle: \

local mv = nil
local saved = {}

local function tab_id_val(id)
	if not id then return nil end
	if type(id) == "number" then return id end
	if type(id) == "userdata" and id.value then return id.value end
	return tostring(id)
end

local function get_tab_by_id(id)
	local v = tab_id_val(id)
	if not v then return nil end
	for _, tab in ipairs(cx.tabs) do
		if tab_id_val(tab.id) == v then
			return tab
		end
	end
	return nil
end

local function get_tab_idx_by_id(id)
	local v = tab_id_val(id)
	if not v then return nil end
	for idx, tab in ipairs(cx.tabs) do
		if tab_id_val(tab.id) == v then
			return idx
		end
	end
	return nil
end

-- Minimal component: renders static UI elements
local Overlay = {}
function Overlay:new(id, area, elements, slot_num)
	return setmetatable({ _id = id, _area = area, _elements = elements or {}, _slot_num = slot_num }, { __index = self })
end

function Overlay:reflow() return { self } end

function Overlay:redraw() return self._elements end

local focus_slot -- forward declaration

function Overlay:click(event, up)
	if self._slot_num and mv and mv.active then
		focus_slot(self._slot_num)
	end
end

-- Polyfill: Marker lacks reflow() in some contexts, which would crash Tab:reflow() on resize.
if Marker and not Marker.reflow then
	Marker.reflow = function() return {} end
end

-- Wraps a Current component to suppress cursor highlight via mv._no_cursor flag
-- when rendering an inactive view slot.
local Pane = {}
function Pane:new(id, area, tab, active, slot_num)
	return setmetatable({
		_id = id,
		_area = area,
		_tab = tab,
		_active = active,
		_slot_num = slot_num,
		_inner = Current:new(area, tab),
	}, { __index = self })
end

function Pane:reflow() return { self } end

function Pane:redraw()
	if mv then
		mv._no_cursor = not self._active
	end
	local elements = self._inner:redraw()
	if mv then
		mv._no_cursor = nil
	end
	return elements
end

function Pane:click(event, up)
	if mv and mv.active then
		focus_slot(self._slot_num)
	end
	return self._inner:click(event, up)
end

function Pane:scroll(event, step)
	if mv and mv.active then
		focus_slot(self._slot_num)
	end
	return self._inner:scroll(event, step)
end

-- Automatic layout geometry calculator based solely on visible view count:
-- 1 view:  Native Yazi full area
-- 2 views: Equal split with shared 1-cell divider
-- 3 views: 2 on top + 1 full-width below (2+1)
-- 4 views: Equal 2x2 grid
local function compute_layout(area, view_count)
	local rects = {}
	if view_count <= 1 then
		rects[1] = area
		return rects
	elseif view_count == 2 then
		local w1 = math.floor(area.w / 2)
		local w2 = area.w - w1
		rects[1] = ui.Rect { x = area.x, y = area.y, w = w1 + 1, h = area.h }
		rects[2] = ui.Rect { x = area.x + w1, y = area.y, w = w2, h = area.h }
		return rects
	elseif view_count == 3 then
		local w1 = math.floor(area.w / 2)
		local w2 = area.w - w1
		local h1 = math.floor(area.h / 2)
		local h2 = area.h - h1
		rects[1] = ui.Rect { x = area.x, y = area.y, w = w1 + 1, h = h1 + 1 }
		rects[2] = ui.Rect { x = area.x + w1, y = area.y, w = w2, h = h1 + 1 }
		rects[3] = ui.Rect { x = area.x, y = area.y + h1, w = area.w, h = h2 }
		return rects
	else
		local w1 = math.floor(area.w / 2)
		local w2 = area.w - w1
		local h1 = math.floor(area.h / 2)
		local h2 = area.h - h1
		rects[1] = ui.Rect { x = area.x, y = area.y, w = w1 + 1, h = h1 + 1 }
		rects[2] = ui.Rect { x = area.x + w1, y = area.y, w = w2, h = h1 + 1 }
		rects[3] = ui.Rect { x = area.x, y = area.y + h1, w = w1 + 1, h = h2 }
		rects[4] = ui.Rect { x = area.x + w1, y = area.y + h1, w = w2, h = h2 }
		return rects
	end
end

-- Directional focus target calculator
local function directional_target(current_slot, dir, view_count)
	if view_count <= 1 then return 1 end

	if view_count == 2 then
		if dir == "left" then return 1
		elseif dir == "right" then return 2
		end
		return current_slot
	elseif view_count == 3 then
		if current_slot == 1 then
			if dir == "right" then return 2
			elseif dir == "down" then return 3
			end
		elseif current_slot == 2 then
			if dir == "left" then return 1
			elseif dir == "down" then return 3
			end
		elseif current_slot == 3 then
			if dir == "up" then return (mv and mv._last_top_slot) or 1
			end
		end
		return current_slot
	elseif view_count >= 4 then
		if current_slot == 1 then
			if dir == "right" then return 2
			elseif dir == "down" then return 3
			end
		elseif current_slot == 2 then
			if dir == "left" then return 1
			elseif dir == "down" then return 4
			end
		elseif current_slot == 3 then
			if dir == "up" then return 1
			elseif dir == "right" then return 4
			end
		elseif current_slot == 4 then
			if dir == "up" then return 2
			elseif dir == "left" then return 3
			end
		end
		return current_slot
	end
	return current_slot
end

-- Synchronize slots with open tabs and ensure the currently active tab is focused.
local function sync_slots_with_active_tab()
	if not mv or not mv.active then return end

	-- View count is determined automatically by open native tabs (capped at 4)
	mv.view_count = math.min(4, math.max(1, #cx.tabs))

	local active_val = tab_id_val(cx.active.id)

	-- 1. Invalidate slots whose tabs were closed
	for i = 1, 4 do
		if mv.slots[i] and not get_tab_by_id(mv.slots[i]) then
			mv.slots[i] = nil
		end
	end

	-- 2. Populate unassigned visible slots from existing native tabs
	local assigned = {}
	for i = 1, mv.view_count do
		if mv.slots[i] then
			assigned[mv.slots[i]] = true
		end
	end

	for i = 1, mv.view_count do
		if not mv.slots[i] then
			for _, tab in ipairs(cx.tabs) do
				local tid = tab_id_val(tab.id)
				if not assigned[tid] then
					mv.slots[i] = tid
					assigned[tid] = true
					break
				end
			end
		end
	end

	-- 3. Determine focused slot matching cx.active
	local found = false
	for i = 1, mv.view_count do
		if mv.slots[i] and tab_id_val(mv.slots[i]) == active_val then
			mv.focused_slot = i
			if i <= 2 then
				mv._last_top_slot = i
			end
			found = true
			break
		end
	end

	if not found then
		mv.slots[mv.focused_slot] = active_val
		if mv.focused_slot <= 2 then
			mv._last_top_slot = mv.focused_slot
		end
	end
end

local function apply_tab_patch()
	Tab.layout = function(self)
		if not mv or not mv.active then
			return saved.tab_layout(self)
		end

		sync_slots_with_active_tab()

		-- When only 1 view, completely fall back to native layout
		if mv.view_count <= 1 then
			return saved.tab_layout(self)
		end

		self._view_rects = compute_layout(self._area, mv.view_count)

		self._chunks = ui.Layout()
			:direction(ui.Layout.HORIZONTAL)
			:constraints({
				ui.Constraint.Fill(1),
				ui.Constraint.Fill(1),
				ui.Constraint.Length(0),
			})
			:split(self._area)
	end

	Tab.build = function(self, ...)
		if not mv or not mv.active then
			return saved.tab_build(self, ...)
		end

		sync_slots_with_active_tab()

		-- When only 1 view, completely fall back to native build (Miller columns, rails, preview)
		if mv.view_count <= 1 then
			return saved.tab_build(self, ...)
		end

		local rects = self._view_rects
		if not rects or #rects == 0 then
			return saved.tab_build(self, ...)
		end

		local children = {}
		local max_slots = #rects

		for slot_num = 1, max_slots do
			local col_area = rects[slot_num]
			local tab_id = mv.slots[slot_num]
			local tab = get_tab_by_id(tab_id)
			local is_focused = (mv.focused_slot == slot_num)

			-- Restrained visual hierarchy (btop-like shared separators)
			local border_style
			if is_focused then
				border_style = th.tabs.active:patch(ui.Style():bg("reset"))
			else
				border_style = th.mgr.border_style or th.tabs.inactive:patch(ui.Style():bg("reset"))
			end

			-- Technical typography integrated into separator line: " 1 ~/Documents "
			local path_str = tab and ya.readable_path(tostring(tab.current.cwd)) or "Empty"
			local max_path_w = math.max(6, col_area.w - 10)
			local truncated_path = ui.truncate(path_str, { max = max_path_w, rtl = true })

			local num_style = is_focused and th.tabs.active:patch(ui.Style():bg("reset"):bold(true)) or th.tabs.inactive:patch(ui.Style():bg("reset"))
			local path_style = is_focused and th.tabs.active:patch(ui.Style():bg("reset")) or th.tabs.inactive:patch(ui.Style():bg("reset"))

			local title_line = ui.Line {
				ui.Span(string.format(" %d ", slot_num)):style(num_style),
				ui.Span(truncated_path .. " "):style(path_style),
			}

			local border = ui.Border(ui.Edge.ALL)
				:area(col_area)
				:type(ui.Border.PLAIN)
				:style(border_style)
				:merge(true)
				:title(title_line)

			children[#children + 1] = Overlay:new("slot-frame-" .. slot_num, col_area, { border }, slot_num)

			-- Inner area for directory entries (padded 1 cell inside border)
			local inner_area = ui.Rect {
				x = col_area.x + 1,
				y = col_area.y + 1,
				w = math.max(0, col_area.w - 2),
				h = math.max(0, col_area.h - 2),
			}

			if tab and slot_num <= mv.view_count then
				local pane_id = is_focused and "current" or ("pane-inactive-" .. slot_num)
				children[#children + 1] = Pane:new(pane_id, inner_area, tab, is_focused, slot_num)
				children[#children + 1] = Marker:new(inner_area, tab.current)
			else
				local placeholder = {
					ui.Line(""),
					ui.Line(string.format("  Slot %d: Empty", slot_num)),
					ui.Line("  (press 't' to create a tab)"),
				}
				children[#children + 1] = Overlay:new("slot-empty-" .. slot_num, inner_area, {
					ui.Text(placeholder):area(inner_area):align(ui.Align.CENTER),
				}, slot_num)
			end
		end

		-- Zero-width "preview" component ensures Reflow::act sets layout.preview.height > 0
		-- so that Folder::make does not clamp window entries to 0.
		children[#children + 1] = Overlay:new("preview", ui.Rect { x = 0, y = 0, w = 0, h = self._area.h }, {})

		self._children = children
	end
end

local function apply_header_patch()
	Header.cwd = function(self)
		return saved.header_cwd(self)
	end
end

local function apply_entity_patch()
	Entity.style = function(self)
		if mv and mv.active and mv._no_cursor then
			return self._file:style() or ui.Style()
		end
		return saved.entity_style(self)
	end
end

local function restore_all()
	if saved.tab_layout then Tab.layout = saved.tab_layout end
	if saved.tab_build then Tab.build = saved.tab_build end
	if saved.header_cwd then Header.cwd = saved.header_cwd end
	if saved.entity_style then Entity.style = saved.entity_style end
	saved = {}
end

local function setup_pubsub()
	ps.sub("ind-watch", function(args)
		if not mv or not mv.active then return end
		args.files = args.files or {}
		for _, id in ipairs(mv.slots) do
			local tab = get_tab_by_id(id)
			if tab and tab.current and tab.current.file then
				args.files[#args.files + 1] = tab.current.file
			end
		end
		return args
	end)

	ps.sub("relay-update-files", function(args)
		if not mv or not mv.active then return end
		args.tabs = args.tabs or {}
		for _, id in ipairs(mv.slots) do
			args.tabs[#args.tabs + 1] = id
		end
		return args
	end)
end

local function teardown_pubsub()
	ps.unsub("ind-watch")
	ps.unsub("relay-update-files")
end

local function activate()
	if mv and mv.active then return end

	saved.tab_layout = Tab.layout
	saved.tab_build = Tab.build
	saved.header_cwd = Header.cwd
	saved.entity_style = Entity.style

	local count = math.min(4, math.max(1, #cx.tabs))
	local slots = {}
	for i = 1, math.min(count, #cx.tabs) do
		slots[i] = tab_id_val(cx.tabs[i].id)
	end

	local cur_id = tab_id_val(cx.active.id)
	local focused = 1
	for i = 1, count do
		if slots[i] and tab_id_val(slots[i]) == cur_id then
			focused = i
			break
		end
	end

	mv = {
		active = true,
		view_count = count,
		slots = slots,
		focused_slot = focused,
		_no_cursor = nil,
		_last_top_slot = (focused <= 2) and focused or 1,
	}

	apply_tab_patch()
	apply_header_patch()
	apply_entity_patch()

	setup_pubsub()
	ui.render()
end

local function deactivate()
	if not mv or not mv.active then return end

	teardown_pubsub()
	restore_all()
	mv = nil
	ui.render()
end

focus_slot = function(slot_num)
	if not mv or not mv.active then return end
	if slot_num < 1 or slot_num > mv.view_count then return end

	local target_id = mv.slots[slot_num]
	if not target_id then
		mv.focused_slot = slot_num
		if slot_num <= 2 then
			mv._last_top_slot = slot_num
		end
		ui.render()
		return
	end

	local target_idx = get_tab_idx_by_id(target_id)
	if not target_idx then
		mv.focused_slot = slot_num
		if slot_num <= 2 then
			mv._last_top_slot = slot_num
		end
		ui.render()
		return
	end

	mv.focused_slot = slot_num
	if slot_num <= 2 then
		mv._last_top_slot = slot_num
	end

	if target_idx ~= cx.tabs.idx then
		ya.emit("tab_switch", { target_idx - 1 })
	end
	ui.render()
end

local function focus_dir(dir)
	if not mv or not mv.active then return end
	local target = directional_target(mv.focused_slot, dir, mv.view_count)
	if target and target ~= mv.focused_slot then
		focus_slot(target)
	end
end

local function focus_next()
	if not mv or not mv.active then return end
	local target = (mv.focused_slot % mv.view_count) + 1
	focus_slot(target)
end

local function focus_prev()
	if not mv or not mv.active then return end
	local target = (mv.focused_slot - 2 + mv.view_count) % mv.view_count + 1
	focus_slot(target)
end

local function entry(_, job)
	local act = job and job.args and job.args[1] or "toggle"

	if act == "toggle" then
		if mv and mv.active then
			deactivate()
		else
			activate()
		end
	elseif act == "focus_left" then
		focus_dir("left")
	elseif act == "focus_right" then
		focus_dir("right")
	elseif act == "focus_up" then
		focus_dir("up")
	elseif act == "focus_down" then
		focus_dir("down")
	elseif act == "focus_next" then
		focus_next()
	elseif act == "focus_prev" then
		focus_prev()
	end
end

return { entry = entry }
