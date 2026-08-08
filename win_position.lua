-- win_position
-- Window placement driven by Fn + numeric keypad, with a lightweight HUD.

local module = {}

local canvas = require("hs.canvas")
local eventtap = require("hs.eventtap")
local event_types = eventtap.event.types
local raw_flag_masks = eventtap.event.rawFlagMasks
local geometry = require("hs.geometry")
local keycodes = require("hs.keycodes")
local screen = require("hs.screen")
local window = require("hs.window")

local EXCLUDED_APPS = {
   bundleIDs = {
      ["com.vmware.fusion"] = true,
   },
   names = {
      ["VMware Fusion"] = true,
   },
   namePatterns = {
      "VMware",
   },
}

local ANIMATION_DURATION = 0.12
local RESIZE_STEP = 32
local MIN_WINDOW_WIDTH = 320
local MIN_WINDOW_HEIGHT = 240
local FIXED_THEME = {
   panelFill = { red = 0.15, green = 0.19, blue = 0.24, alpha = 0.78 },
   panelStroke = { red = 0.33, green = 0.40, blue = 0.48, alpha = 0.28 },
   tileFill = { red = 0.26, green = 0.32, blue = 0.39, alpha = 0.22 },
   tileStroke = { red = 0.54, green = 0.63, blue = 0.72, alpha = 0.18 },
   tileActiveFill = { red = 0.33, green = 0.40, blue = 0.48, alpha = 0.34 },
   tileActiveStroke = { red = 0.76, green = 0.84, blue = 0.92, alpha = 0.28 },
   keyColor = { white = 0.93, alpha = 0.72 },
   previewFill = { red = 0.93, green = 0.45, blue = 0.18, alpha = 0.14 },
   previewStroke = { red = 0.98, green = 0.62, blue = 0.26, alpha = 0.96 },
   previewWindow = { red = 0.96, green = 0.54, blue = 0.22, alpha = 0.98 },
}

local RAW_KEY_ALIASES = {
   left = "pad4",
   right = "pad6",
   up = "arrowUp",
   down = "arrowDown",
   pad0 = "snapshotRestore",
}

local CHARACTER_ALIASES = {
   ["*"] = "pad*",
   ["+"] = "pad+",
   ["-"] = "pad-",
   ["0"] = "snapshotRestore",
}

local KEY_FONT = "Menlo-Bold"

local KEY_LAYOUTS = {
   pad7 = { title = "Top Left", mode = "cycle", cycle = "corner", anchorX = 0.0, anchorY = 0.0 },
   pad8 = { title = "Top", mode = "cycle", cycle = "edge", unit = { x = 0.0, y = 0.0, w = 1.0, h = 0.5 } },
   pad9 = { title = "Top Right", mode = "cycle", cycle = "corner", anchorX = 1.0, anchorY = 0.0 },
   pad4 = { title = "Left", mode = "cycle", cycle = "edge", unit = { x = 0.0, y = 0.0, w = 0.5, h = 1.0 } },
   pad5 = { title = "Center", mode = "cycle", cycle = "center" },
   pad6 = { title = "Right", mode = "cycle", cycle = "edge", unit = { x = 0.5, y = 0.0, w = 0.5, h = 1.0 } },
   pad1 = { title = "Bottom Left", mode = "cycle", cycle = "corner", anchorX = 0.0, anchorY = 1.0 },
   pad2 = { title = "Bottom", mode = "cycle", cycle = "edge", unit = { x = 0.0, y = 0.5, w = 1.0, h = 0.5 } },
   pad3 = { title = "Bottom Right", mode = "cycle", cycle = "corner", anchorX = 1.0, anchorY = 1.0 },
   arrowUp = { title = "Top Sizes", mode = "cycle", cycle = "band", anchorX = 0.5, anchorY = 0.0, highlightKey = "pad8" },
   arrowDown = { title = "Bottom Sizes", mode = "cycle", cycle = "band", anchorX = 0.5, anchorY = 1.0, highlightKey = "pad2" },
   ["pad*"] = { title = "Next Screen", mode = "screenNext" },
   ["pad+"] = { title = "Grow", mode = "resize", delta = RESIZE_STEP },
   ["pad-"] = { title = "Shrink", mode = "resize", delta = -RESIZE_STEP },
   snapshotRestore = { title = "Restore Snapshot", mode = "snapshotRestore", highlightKey = "pad0" },
}

local HUD_KEY_SPECS = {
   { key = "padclear", legend = "x",     col = 1, row = 1 },
   { key = "pad=",     legend = "=",     col = 2, row = 1 },
   { key = "pad/",     legend = "/",     col = 3, row = 1 },
   { key = "pad*",     legend = "*",     col = 4, row = 1 },
   { key = "pad7",     legend = "7",     col = 1, row = 2 },
   { key = "pad8",     legend = "8",     col = 2, row = 2 },
   { key = "pad9",     legend = "9",     col = 3, row = 2 },
   { key = "pad-",     legend = "-",     col = 4, row = 2 },
   { key = "pad4",     legend = "4",     col = 1, row = 3 },
   { key = "pad5",     legend = "5",     col = 2, row = 3 },
   { key = "pad6",     legend = "6",     col = 3, row = 3 },
   { key = "pad+",     legend = "+",     col = 4, row = 3 },
   { key = "pad1",     legend = "1",     col = 1, row = 4 },
   { key = "pad2",     legend = "2",     col = 2, row = 4 },
   { key = "pad3",     legend = "3",     col = 3, row = 4 },
   { key = "padenter", legend = "Invio", col = 4, row = 4, rowSpan = 2 },
   { key = "pad0",     legend = "0",     col = 1, row = 5, colSpan = 2 },
   { key = "pad.",     legend = ".",     col = 3, row = 5 },
}

local hud_canvas = nil
local hud_screen_id = nil
local hud_elements = nil
local hud_theme = nil
local fn_active = false
local key_tap = nil
local cycle_state = {}
local snapshot_state = {}
local last_snapshot_key = nil
local preview_current_frame = nil

local function clamp(value, min_value, max_value)
   if value < min_value then return min_value end
   if value > max_value then return max_value end
   return value
end

local function withAlpha(color, alpha)
   return { red = color.red, green = color.green, blue = color.blue, alpha = alpha }
end

local function darken(color, amount)
   return {
      red = clamp(color.red * (1 - amount), 0.0, 1.0),
      green = clamp(color.green * (1 - amount), 0.0, 1.0),
      blue = clamp(color.blue * (1 - amount), 0.0, 1.0),
      alpha = color.alpha or 1.0,
   }
end

local function copyFrame(frame)
   return geometry.rect(frame.x, frame.y, frame.w, frame.h)
end

local function framesMatch(frame_a, frame_b)
   if frame_a == nil or frame_b == nil then return false end
   return math.abs(frame_a.x - frame_b.x) < 1
       and math.abs(frame_a.y - frame_b.y) < 1
       and math.abs(frame_a.w - frame_b.w) < 1
       and math.abs(frame_a.h - frame_b.h) < 1
end

local function fitSizeToScreen(screen_frame, width, height)
   return clamp(math.floor(width), 1, screen_frame.w), clamp(math.floor(height), 1, screen_frame.h)
end

local function anchoredCoordinate(origin, span, item_span, anchor)
   if anchor <= 0.0 then return origin end
   if anchor >= 1.0 then return origin + span - item_span end
   return origin + math.floor((span - item_span) / 2)
end

local function anchoredFrame(screen_frame, width, height, anchor_x, anchor_y)
   local bounded_width, bounded_height = fitSizeToScreen(screen_frame, width, height)
   return geometry.rect(
      anchoredCoordinate(screen_frame.x, screen_frame.w, bounded_width, anchor_x),
      anchoredCoordinate(screen_frame.y, screen_frame.h, bounded_height, anchor_y),
      bounded_width,
      bounded_height
   )
end

local function frameFromUnit(screen_frame, unit)
   local width = math.floor(screen_frame.w * unit.w)
   local height = math.floor(screen_frame.h * unit.h)
   local x = screen_frame.x + math.floor(screen_frame.w * unit.x)
   local y = screen_frame.y + math.floor(screen_frame.h * unit.y)
   return geometry.rect(x, y, width, height)
end

local function getWindowStateKey(win)
   local app = win:application()
   local app_name = app and app:name() or "Window"
   return tostring(win:id() or (app_name .. ":" .. (win:title() or "window")))
end

local function getThemeForScreen(_)
   return FIXED_THEME
end

local function resolveActionKey(raw_key_name, typed_characters)
   if KEY_LAYOUTS[raw_key_name] ~= nil then
      return raw_key_name
   end

   local aliased_raw = RAW_KEY_ALIASES[raw_key_name]
   if aliased_raw ~= nil then
      return aliased_raw
   end

   if typed_characters ~= nil and typed_characters ~= "" then
      return CHARACTER_ALIASES[typed_characters]
   end

   return nil
end

local function storeSnapshot(win, frame, screen_frame)
   local state_key = getWindowStateKey(win)
   snapshot_state[state_key] = {
      windowID = win:id(),
      frame = copyFrame(frame),
      screenFrame = copyFrame(screen_frame),
   }
   last_snapshot_key = state_key
end

local function getSnapshotForWindow(win)
   local state_key = getWindowStateKey(win)
   local current_id = win:id()
   local snapshot = snapshot_state[state_key]

   if snapshot ~= nil and snapshot.windowID == current_id then
      return snapshot, state_key
   end

   if last_snapshot_key ~= nil then
      local fallback = snapshot_state[last_snapshot_key]
      if fallback ~= nil and fallback.windowID == current_id then
         return fallback, last_snapshot_key
      end
   end

   return nil, nil
end

local function getTargetWindow()
   local win = window.focusedWindow() or window.frontmostWindow()
   if win == nil or not win:isStandard() or not win:isVisible() then return nil end

   local app = win:application()
   if app == nil then return nil end

   local bundle_id = app:bundleID()
   if bundle_id ~= nil and EXCLUDED_APPS.bundleIDs[bundle_id] then return nil end

   local app_name = app:name() or ""
   if EXCLUDED_APPS.names[app_name] then return nil end
   for _, pattern in ipairs(EXCLUDED_APPS.namePatterns) do
      if string.find(app_name, pattern) ~= nil then return nil end
   end

   return win
end

local function getOverlayScreen(win)
   if win ~= nil then return win:screen() end
   return screen.mainScreen() or screen.primaryScreen()
end

local function applyFrame(win, frame)
   win:setFrameInScreenBounds(frame, ANIMATION_DURATION)
   return true
end

local function computeResizeFrame(win, delta)
   local current = win:frame()
   local bounds = win:screen():frame()
   local new_width = clamp(current.w + delta, MIN_WINDOW_WIDTH, bounds.w)
   local new_height = clamp(current.h + delta, MIN_WINDOW_HEIGHT, bounds.h)
   if new_width == current.w and new_height == current.h then return nil end

   local width_delta = new_width - current.w
   local height_delta = new_height - current.h
   return geometry.rect(
      current.x - math.floor(width_delta / 2),
      current.y - math.floor(height_delta / 2),
      new_width,
      new_height
   )
end

local function computeNextScreenPlan(win)
   local current_frame = win:frame()
   local current_screen = win:screen()
   local next_screen = current_screen:next()
   if next_screen == nil or next_screen:id() == current_screen:id() then return nil end

   local next_screen_frame = next_screen:frame()
   local unit = current_screen:toUnitRect(current_frame)
   return {
      frame = frameFromUnit(next_screen_frame, unit),
      screenFrame = copyFrame(next_screen_frame),
      overlayScreen = next_screen,
      cycleLabel = "Next screen",
   }
end

local function clearCycleState(win)
   cycle_state[getWindowStateKey(win)] = nil
end

local function buildCycleSteps(action, state)
   local original_frame = copyFrame(state.originalFrame)
   local screen_frame = state.originalScreenFrame

   if action.cycle == "center" then
      return {
         { frame = anchoredFrame(screen_frame, original_frame.w, original_frame.h, 0.5, 0.5),         cycleLabel = "1/4 Keep size" },
         { frame = copyFrame(screen_frame),                                                           cycleLabel = "2/4 Max" },
         { frame = anchoredFrame(screen_frame, screen_frame.w * 0.5, screen_frame.h * 0.5, 0.5, 0.5), cycleLabel = "3/4 50%" },
         { frame = original_frame,                                                                    cycleLabel = "4/4 Restore",  restore = true },
      }
   end

   if action.cycle == "corner" then
      return {
         { frame = anchoredFrame(screen_frame, original_frame.w, original_frame.h, action.anchorX, action.anchorY),                 cycleLabel = "1/5 Keep size" },
         { frame = anchoredFrame(screen_frame, screen_frame.w / 3, screen_frame.h / 3, action.anchorX, action.anchorY),             cycleLabel = "2/5 33%" },
         { frame = anchoredFrame(screen_frame, screen_frame.w * 0.5, screen_frame.h * 0.5, action.anchorX, action.anchorY),         cycleLabel = "3/5 50%" },
         { frame = anchoredFrame(screen_frame, screen_frame.w * (2 / 3), screen_frame.h * (2 / 3), action.anchorX, action.anchorY), cycleLabel = "4/5 67%" },
      }
   end

   if action.cycle == "band" then
      return {
         { frame = anchoredFrame(screen_frame, original_frame.w, original_frame.h, action.anchorX, action.anchorY),                 cycleLabel = "1/5 Keep size" },
         { frame = anchoredFrame(screen_frame, screen_frame.w / 3, screen_frame.h / 3, action.anchorX, action.anchorY),             cycleLabel = "2/5 33%" },
         { frame = anchoredFrame(screen_frame, screen_frame.w * 0.5, screen_frame.h * 0.5, action.anchorX, action.anchorY),         cycleLabel = "3/5 50%" },
         { frame = anchoredFrame(screen_frame, screen_frame.w * (2 / 3), screen_frame.h * (2 / 3), action.anchorX, action.anchorY), cycleLabel = "4/5 67%" },
         { frame = original_frame,                                                                                                  cycleLabel = "5/5 Restore",  restore = true },
      }
   end

   if action.cycle == "edge" then
      return {
         { frame = frameFromUnit(screen_frame, action.unit), cycleLabel = "1/2 50%" },
         { frame = original_frame,                           cycleLabel = "2/2 Restore", restore = true },
      }
   end

   return nil
end

local function performCycleAction(win, action, key_name)
   local state_key = getWindowStateKey(win)
   local current_frame = win:frame()
   local current_screen = win:screen()
   local current_screen_frame = copyFrame(current_screen:frame())
   local state = cycle_state[state_key]

   if state == nil
       or state.keyName ~= key_name
       or state.screenID ~= current_screen:id()
       or not framesMatch(current_frame, state.lastFrame) then
      storeSnapshot(win, current_frame, current_screen_frame)
      state = {
         keyName = key_name,
         screenID = current_screen:id(),
         originalFrame = copyFrame(current_frame),
         originalScreenFrame = current_screen_frame,
         stepIndex = 0,
         lastFrame = copyFrame(current_frame),
      }
   end

   local steps = buildCycleSteps(action, state)
   if steps == nil or #steps == 0 then return nil end

   local next_step = state.stepIndex + 1
   if next_step > #steps then next_step = 1 end

   local plan = steps[next_step]
   plan.screenFrame = current_screen_frame
   plan.overlayScreen = current_screen

   applyFrame(win, plan.frame)

   if plan.restore then
      cycle_state[state_key] = nil
   else
      state.stepIndex = next_step
      state.lastFrame = copyFrame(plan.frame)
      cycle_state[state_key] = state
   end

   return plan
end

local function performAction(win, key_name)
   local action = KEY_LAYOUTS[key_name]
   if action == nil then return nil end

   if action.mode == "cycle" then
      return performCycleAction(win, action, key_name)
   end

   clearCycleState(win)

   if action.mode == "resize" then
      local next_frame = computeResizeFrame(win, action.delta)
      if next_frame == nil then return nil end
      applyFrame(win, next_frame)
      return {
         frame = next_frame,
         screenFrame = copyFrame(win:screen():frame()),
         overlayScreen = win:screen(),
         cycleLabel = action.delta > 0 and "+32 px" or "-32 px",
      }
   end

   if action.mode == "screenNext" then
      local plan = computeNextScreenPlan(win)
      if plan == nil then return nil end
      applyFrame(win, plan.frame)
      return plan
   end

   if action.mode == "snapshotRestore" then
      local snapshot = getSnapshotForWindow(win)
      if snapshot == nil then return nil end

      clearCycleState(win)
      applyFrame(win, snapshot.frame)
      return {
         frame = copyFrame(snapshot.frame),
         screenFrame = copyFrame(snapshot.screenFrame),
         overlayScreen = win:screen(),
         cycleLabel = "Restore snapshot",
      }
   end

   return nil
end

local function destroyHud()
   preview_current_frame = nil

   if hud_canvas ~= nil then
      hud_canvas:delete()
      hud_canvas = nil
      hud_screen_id = nil
      hud_elements = nil
      hud_theme = nil
   end
end

local function applyPreviewFrame(frame)
   if hud_canvas == nil or hud_elements == nil or hud_theme == nil then return end
   local preview = hud_elements.preview
   if preview == nil or preview.window == nil then return end

   hud_canvas[preview.window].frame = frame
   hud_canvas[preview.window].fillColor = withAlpha(hud_theme.previewWindow, 0.46)
   hud_canvas[preview.window].strokeColor = withAlpha(hud_theme.previewStroke, 1.00)
   preview_current_frame = copyFrame(frame)
end

local function makeHudFrame(target_screen)
   local screen_frame = target_screen:frame()
   local aspect_ratio = screen_frame.w / screen_frame.h
   local width = clamp(math.floor(screen_frame.w * 0.24), 300, 460)
   local height = math.floor(width / aspect_ratio)

   if height > math.floor(screen_frame.h * 0.30) then
      height = math.floor(screen_frame.h * 0.30)
      width = math.floor(height * aspect_ratio)
   end

   if height < 180 then
      height = 180
      width = math.floor(height * aspect_ratio)
   end

   return geometry.rect(
      screen_frame.x + math.floor((screen_frame.w - width) / 2),
      screen_frame.y + math.floor((screen_frame.h - height) / 2),
      width,
      height
   )
end

local function buildHudElements(frame, _, theme)
   local elements = {}
   local element_map = { tiles = {}, preview = {} }

   local outer = 12
   local cell_gap = 8
   local columns = 4
   local rows = 5
   local content_frame = {
      x = outer,
      y = outer,
      w = frame.w - (outer * 2),
      h = frame.h - (outer * 2),
   }

   local max_keypad_width = math.floor(content_frame.w * 0.48)
   local max_keypad_height = math.floor(content_frame.h * 0.78)
   local cell_width = clamp(math.floor((max_keypad_width - (cell_gap * (columns - 1))) / columns), 28, 46)
   local cell_height = clamp(math.floor((max_keypad_height - (cell_gap * (rows - 1))) / rows), 24, 40)
   local keypad_frame = {
      x = content_frame.x + math.floor((content_frame.w - ((cell_width * columns) + (cell_gap * (columns - 1)))) / 2),
      y = content_frame.y + math.floor((content_frame.h - ((cell_height * rows) + (cell_gap * (rows - 1)))) / 2),
      w = (cell_width * columns) + (cell_gap * (columns - 1)),
      h = (cell_height * rows) + (cell_gap * (rows - 1)),
   }

   table.insert(elements, {
      type = "rectangle",
      action = "fill",
      roundedRectRadii = { xRadius = 18, yRadius = 18 },
      fillColor = theme.panelFill,
      strokeColor = withAlpha(theme.panelStroke, 0.24),
      strokeWidth = 1.0,
      frame = { x = 0, y = 0, w = frame.w, h = frame.h },
   })

   table.insert(elements, {
      type = "rectangle",
      action = "fill",
      roundedRectRadii = { xRadius = 18, yRadius = 18 },
      fillColor = withAlpha(theme.previewFill, 0.16),
      strokeColor = withAlpha(theme.previewStroke, 0.30),
      strokeWidth = 1.1,
      frame = content_frame,
   })

   local function addTile(spec)
      local x = keypad_frame.x + ((spec.col - 1) * (cell_width + cell_gap))
      local y = keypad_frame.y + ((spec.row - 1) * (cell_height + cell_gap))
      local width = (cell_width * (spec.colSpan or 1)) + (cell_gap * ((spec.colSpan or 1) - 1))
      local height = (cell_height * (spec.rowSpan or 1)) + (cell_gap * ((spec.rowSpan or 1) - 1))
      local is_active = KEY_LAYOUTS[spec.key] ~= nil

      local fill_color = is_active and theme.tileFill or withAlpha(darken(theme.tileFill, 0.18), 0.16)
      local stroke_color = is_active and theme.tileStroke or withAlpha(darken(theme.tileStroke, 0.25), 0.14)
      local key_color = is_active and theme.keyColor or withAlpha(theme.keyColor, 0.28)

      table.insert(elements, {
         type = "rectangle",
         action = "fill",
         roundedRectRadii = { xRadius = 14, yRadius = 14 },
         fillColor = fill_color,
         strokeColor = stroke_color,
         strokeWidth = 1.0,
         frame = { x = x, y = y, w = width, h = height },
      })
      local rect_index = #elements

      table.insert(elements, {
         type = "text",
         text = spec.legend,
         textFont = KEY_FONT,
         textSize = spec.key == "padenter" and 11 or 15,
         textColor = key_color,
         frame = { x = x + 7, y = y + math.floor((height - 18) / 2), w = width - 14, h = 18 },
      })

      element_map.tiles[spec.key] = { rect = rect_index, label = nil }
   end

   for _, spec in ipairs(HUD_KEY_SPECS) do
      addTile(spec)
   end

   table.insert(elements, {
      type = "rectangle",
      action = "fill",
      roundedRectRadii = { xRadius = 12, yRadius = 12 },
      fillColor = withAlpha(theme.previewWindow, 0.38),
      strokeColor = withAlpha(theme.previewStroke, 0.98),
      strokeWidth = 1.8,
      frame = { x = content_frame.x + 8, y = content_frame.y + 8, w = cell_width, h = cell_height },
   })

   element_map.preview.window = #elements
   element_map.preview.contentFrame = content_frame

   return elements, element_map
end

local function updatePreview(preview_info)
   if hud_canvas == nil or hud_elements == nil or hud_theme == nil then return end

   local preview = hud_elements.preview
   if preview == nil or preview.window == nil or preview.contentFrame == nil then return end

   local screen_frame = preview_info and preview_info.screenFrame or nil
   local target_frame = preview_info and preview_info.frame or nil
   if screen_frame == nil or target_frame == nil then return end

   local inner_margin = 8
   local monitor = preview.contentFrame
   local inner = {
      x = monitor.x + inner_margin,
      y = monitor.y + inner_margin,
      w = monitor.w - (inner_margin * 2),
      h = monitor.h - (inner_margin * 2),
   }

   local relative_x = clamp((target_frame.x - screen_frame.x) / screen_frame.w, 0.0, 1.0)
   local relative_y = clamp((target_frame.y - screen_frame.y) / screen_frame.h, 0.0, 1.0)
   local relative_w = clamp(target_frame.w / screen_frame.w, 0.10, 1.0)
   local relative_h = clamp(target_frame.h / screen_frame.h, 0.10, 1.0)

   local target_preview_frame = {
      x = inner.x + math.floor(inner.w * relative_x),
      y = inner.y + math.floor(inner.h * relative_y),
      w = math.max(12, math.floor(inner.w * relative_w)),
      h = math.max(10, math.floor(inner.h * relative_h)),
   }

   applyPreviewFrame(target_preview_frame)
end

local function ensureHud(target_screen, subtitle, theme)
   local target_frame = makeHudFrame(target_screen)

   if hud_canvas == nil or hud_screen_id ~= target_screen:id() then
      destroyHud()
      hud_canvas = canvas.new(target_frame)
      hud_canvas:level(canvas.windowLevels.overlay)
      hud_canvas:behaviorAsLabels({ "canJoinAllSpaces", "stationary" })
      hud_canvas:clickActivating(false)
      hud_canvas:wantsLayer(true)
      hud_screen_id = target_screen:id()
   else
      hud_canvas:frame(target_frame)
   end

   local elements, element_map = buildHudElements(target_frame, subtitle, theme)
   hud_canvas:replaceElements(elements)
   hud_elements = element_map
   hud_theme = theme
end

local function highlightAction(key_name)
   if hud_canvas == nil or hud_elements == nil or hud_theme == nil then return end

   for current_key, indices in pairs(hud_elements.tiles) do
      if KEY_LAYOUTS[current_key] ~= nil then
         hud_canvas[indices.rect].fillColor = hud_theme.tileFill
         hud_canvas[indices.rect].strokeColor = hud_theme.tileStroke
         if indices.label ~= nil then
            hud_canvas[indices.label].textColor = hud_theme.labelColor
         end
      end

      if current_key == key_name then
         hud_canvas[indices.rect].fillColor = hud_theme.tileActiveFill
         hud_canvas[indices.rect].strokeColor = hud_theme.tileActiveStroke
         if indices.label ~= nil then
            hud_canvas[indices.label].textColor = hud_theme.labelActiveColor
         end
      end
   end
end

local function showHud(win, selected_key, preview_info, overlay_screen)
   local target_screen = overlay_screen or getOverlayScreen(win)
   if target_screen == nil then return end

   ensureHud(target_screen, "", getThemeForScreen(target_screen))

   if hud_canvas == nil then return end

   highlightAction(selected_key)
   updatePreview(preview_info)

   if not hud_canvas:isShowing() then
      hud_canvas:show(0.06)
   end
   hud_canvas:bringToFront(true)
end

local function hideHud()
   preview_current_frame = nil

   if hud_canvas ~= nil and hud_canvas:isShowing() then
      hud_canvas:hide(0.08)
   end
end

local function handleFlagChange(event)
   local flags = event:getFlags()
   local raw_flags = event:rawFlags()
   local is_fn_down = flags.fn or (raw_flags & raw_flag_masks.secondaryFn > 0)
   if is_fn_down == fn_active then return false end

   fn_active = is_fn_down
   if fn_active then
      local win = getTargetWindow()
      if win ~= nil then
         showHud(win, nil, {
            frame = copyFrame(win:frame()),
            screenFrame = copyFrame(win:screen():frame()),
            animate = false,
         }, win:screen())
      end
   else
      hideHud()
   end

   return false
end

local function handleKeyDown(event)
   if not fn_active then return false end

   local raw_key_name = keycodes.map[event:getKeyCode()]
   local typed_characters = event:getCharacters(true)
   local key_name = resolveActionKey(raw_key_name, typed_characters)
   local action = key_name and KEY_LAYOUTS[key_name] or nil
   if action == nil then return false end

   local win = getTargetWindow()
   if win == nil then return true end

   local plan = performAction(win, key_name)
   if plan ~= nil then
      showHud(win, action.highlightKey or key_name, {
         frame = copyFrame(plan.frame),
         screenFrame = copyFrame(plan.screenFrame),
      }, plan.overlayScreen)
   end

   return true
end

local function eventHandler(event)
   local event_type = event:getType()
   if event_type == event_types.flagsChanged then return handleFlagChange(event) end
   if event_type == event_types.keyDown then return handleKeyDown(event) end
   return false
end

function module.start()
   if key_tap ~= nil then return module end
   key_tap = eventtap.new({ event_types.flagsChanged, event_types.keyDown }, eventHandler)
   key_tap:start()
   return module
end

function module.stop()
   fn_active = false
   if key_tap ~= nil then
      key_tap:stop()
      key_tap = nil
   end
   destroyHud()
   return module
end

module.start()

return module
