---@diagnostic disable: undefined-field, need-check-nil
-- win_position
-- Window placement driven by Fn + numeric keypad, with a lightweight HUD.

local module = {}

local canvas = require("hs.canvas")
local eventtap = require("hs.eventtap")
local event_types = eventtap.event.types
local raw_flag_masks = eventtap.event.rawFlagMasks
local fs = require("hs.fs")
local geometry = require("hs.geometry")
local http = require("hs.http")
local image = require("hs.image")
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

local DEFAULT_ACCENT = { red = 0.18, green = 0.52, blue = 0.82, alpha = 1.00 }

local HUD_THEME = {
   panelBase = { red = 0.05, green = 0.06, blue = 0.08, alpha = 0.72 },
   tileBase = { red = 0.08, green = 0.09, blue = 0.12, alpha = 0.58 },
   tileActiveBase = { red = 0.18, green = 0.52, blue = 0.82, alpha = 0.86 },
   textStrong = { white = 0.98, alpha = 1.00 },
   textSoft = { white = 0.78, alpha = 0.96 },
   textDim = { white = 0.66, alpha = 0.92 },
}

local TITLE_FONT = "HelveticaNeue-Bold"
local BODY_FONT = "HelveticaNeue"
local KEY_FONT = "Menlo-Bold"
local LABEL_FONT = "HelveticaNeue-Bold"
local COLOR_SAMPLE_POINTS = {
   { 0.18, 0.20 },
   { 0.50, 0.28 },
   { 0.82, 0.22 },
   { 0.30, 0.74 },
   { 0.68, 0.78 },
}

local KEY_LAYOUTS = {
   pad7 = { title = "Top Left", mode = "cycle", cycle = "corner", anchorX = 0.0, anchorY = 0.0, legend = "7", short = "TL" },
   pad8 = { title = "Top", mode = "cycle", cycle = "edge", unit = { x = 0.0, y = 0.0, w = 1.0, h = 0.5 }, legend = "8", short = "Top" },
   pad9 = { title = "Top Right", mode = "cycle", cycle = "corner", anchorX = 1.0, anchorY = 0.0, legend = "9", short = "TR" },
   pad4 = { title = "Left", mode = "cycle", cycle = "edge", unit = { x = 0.0, y = 0.0, w = 0.5, h = 1.0 }, legend = "4", short = "Left" },
   pad5 = { title = "Center", mode = "cycle", cycle = "center", legend = "5", short = "Ctr" },
   pad6 = { title = "Right", mode = "cycle", cycle = "edge", unit = { x = 0.5, y = 0.0, w = 0.5, h = 1.0 }, legend = "6", short = "Right" },
   pad1 = { title = "Bottom Left", mode = "cycle", cycle = "corner", anchorX = 0.0, anchorY = 1.0, legend = "1", short = "BL" },
   pad2 = { title = "Bottom", mode = "cycle", cycle = "edge", unit = { x = 0.0, y = 0.5, w = 1.0, h = 0.5 }, legend = "2", short = "Bot" },
   pad3 = { title = "Bottom Right", mode = "cycle", cycle = "corner", anchorX = 1.0, anchorY = 1.0, legend = "3", short = "BR" },
   ["pad*"] = { title = "Next Screen", mode = "screenNext", legend = "*", short = "Next" },
   ["pad+"] = { title = "Grow", mode = "resize", delta = RESIZE_STEP, legend = "+", short = "+32" },
   ["pad-"] = { title = "Shrink", mode = "resize", delta = -RESIZE_STEP, legend = "-", short = "-32" },
}

local GRID_ROWS = {
   { "pad7", "pad8", "pad9" },
   { "pad4", "pad5", "pad6" },
   { "pad1", "pad2", "pad3" },
}

local ACTION_ROW = { "pad*", "pad+", "pad-" }

local hud_canvas = nil
local hud_screen_id = nil
local hud_elements = nil
local hud_theme = nil
local fn_active = false
local key_tap = nil
local theme_cache = {}
local cycle_state = {}

local function clamp(value, min_value, max_value)
   if value < min_value then
      return min_value
   end
   if value > max_value then
      return max_value
   end
   return value
end

local function rgb(red, green, blue, alpha)
   return { red = red, green = green, blue = blue, alpha = alpha or 1.00 }
end

local function mixColors(color_a, color_b, weight)
   local inverse = 1 - weight
   return {
      red = (color_a.red * inverse) + (color_b.red * weight),
      green = (color_a.green * inverse) + (color_b.green * weight),
      blue = (color_a.blue * inverse) + (color_b.blue * weight),
      alpha = (color_a.alpha or 1.00) * inverse + (color_b.alpha or 1.00) * weight,
   }
end

local function withAlpha(color, alpha)
   return {
      red = color.red,
      green = color.green,
      blue = color.blue,
      alpha = alpha,
   }
end

local function brighten(color, amount)
   return mixColors(color, rgb(1.0, 1.0, 1.0, color.alpha or 1.0), amount)
end

local function darken(color, amount)
   return mixColors(color, rgb(0.0, 0.0, 0.0, color.alpha or 1.0), amount)
end

local function warmTint(color, amount)
   return {
      red = clamp(color.red + amount, 0.0, 1.0),
      green = clamp(color.green + (amount * 0.45), 0.0, 1.0),
      blue = clamp(color.blue - (amount * 0.55), 0.0, 1.0),
      alpha = color.alpha or 1.0,
   }
end

local function coolTint(color, amount)
   return {
      red = clamp(color.red - (amount * 0.40), 0.0, 1.0),
      green = clamp(color.green + (amount * 0.18), 0.0, 1.0),
      blue = clamp(color.blue + amount, 0.0, 1.0),
      alpha = color.alpha or 1.0,
   }
end

local function copyFrame(frame)
   return geometry.rect(frame.x, frame.y, frame.w, frame.h)
end

local function framesMatch(frame_a, frame_b)
   if frame_a == nil or frame_b == nil then
      return false
   end

   return math.abs(frame_a.x - frame_b.x) < 1
      and math.abs(frame_a.y - frame_b.y) < 1
      and math.abs(frame_a.w - frame_b.w) < 1
      and math.abs(frame_a.h - frame_b.h) < 1
end

local function fitSizeToScreen(screen_frame, width, height)
   return clamp(math.floor(width), 1, screen_frame.w), clamp(math.floor(height), 1, screen_frame.h)
end

local function anchoredCoordinate(origin, span, item_span, anchor)
   if anchor <= 0.0 then
      return origin
   end
   if anchor >= 1.0 then
      return origin + span - item_span
   end
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

local function resolveDesktopImagePath(target_screen)
   local image_url = target_screen:desktopImageURL()
   if type(image_url) ~= "string" or image_url == "" then
      return nil
   end

   local url_parts = http.urlParts(image_url)
   if url_parts == nil or not url_parts.isFileURL then
      return nil
   end

   return url_parts.fileSystemRepresentation or url_parts.path
end

local function sampleDesktopAccent(target_screen)
   local image_path = resolveDesktopImagePath(target_screen)
   if image_path == nil or fs.attributes(image_path) == nil then
      return DEFAULT_ACCENT, image_path
   end

   local wallpaper = image.imageFromPath(image_path)
   if wallpaper == nil then
      return DEFAULT_ACCENT, image_path
   end

   local bitmap = wallpaper:bitmapRepresentation({ w = 24, h = 24 })
   local size = bitmap:size()
   if size == nil or size.w <= 1 or size.h <= 1 then
      return DEFAULT_ACCENT, image_path
   end

   local red = 0
   local green = 0
   local blue = 0
   local samples = 0

   for _, point in ipairs(COLOR_SAMPLE_POINTS) do
      local x = clamp(math.floor((size.w - 1) * point[1]), 0, size.w - 1)
      local y = clamp(math.floor((size.h - 1) * point[2]), 0, size.h - 1)
      local sampled = bitmap:colorAt({ x = x, y = y })
      if sampled ~= nil then
         local sample_red = sampled.red or sampled.white or 0
         local sample_green = sampled.green or sampled.white or 0
         local sample_blue = sampled.blue or sampled.white or 0
         red = red + sample_red
         green = green + sample_green
         blue = blue + sample_blue
         samples = samples + 1
      end
   end

   if samples == 0 then
      return DEFAULT_ACCENT, image_path
   end

   local sampled_accent = rgb(red / samples, green / samples, blue / samples, 1.0)
   return mixColors(sampled_accent, DEFAULT_ACCENT, 0.40), image_path
end

local function buildThemeForScreen(target_screen)
   local accent, image_path = sampleDesktopAccent(target_screen)
   local warm_accent = warmTint(accent, 0.10)
   local cool_accent = coolTint(accent, 0.12)
   local panel_fill = withAlpha(mixColors(HUD_THEME.panelBase, cool_accent, 0.18), 0.72)
   local panel_stroke = withAlpha(brighten(cool_accent, 0.26), 0.60)
   local accent_bar = withAlpha(brighten(warm_accent, 0.14), 0.78)
   local accent_glow = withAlpha(warm_accent, 0.24)
   local tile_fill = withAlpha(mixColors(HUD_THEME.tileBase, cool_accent, 0.12), 0.58)
   local tile_stroke = withAlpha(brighten(mixColors(HUD_THEME.tileBase, cool_accent, 0.30), 0.10), 0.50)
   local tile_active_fill = withAlpha(mixColors(HUD_THEME.tileActiveBase, warm_accent, 0.52), 0.88)
   local tile_active_stroke = withAlpha(brighten(cool_accent, 0.34), 0.94)
   local preview_fill = withAlpha(mixColors(cool_accent, warm_accent, 0.30), 0.34)
   local preview_stroke = withAlpha(brighten(cool_accent, 0.30), 0.80)
   local preview_window = withAlpha(mixColors(warm_accent, cool_accent, 0.42), 0.92)

   return {
      imagePath = image_path,
      panelFill = panel_fill,
      panelStroke = panel_stroke,
      accentBar = accent_bar,
      accentGlow = accent_glow,
      tileFill = tile_fill,
      tileStroke = tile_stroke,
      tileActiveFill = tile_active_fill,
      tileActiveStroke = tile_active_stroke,
      titleColor = HUD_THEME.textStrong,
      subtitleColor = HUD_THEME.textSoft,
      keyColor = HUD_THEME.textStrong,
      labelColor = HUD_THEME.textDim,
      labelActiveColor = HUD_THEME.textStrong,
      previewFill = preview_fill,
      previewStroke = preview_stroke,
      previewWindow = preview_window,
   }
end

local function getThemeForScreen(target_screen)
   local screen_key = target_screen:getUUID() or tostring(target_screen:id())
   local image_path = resolveDesktopImagePath(target_screen)
   local cached = theme_cache[screen_key]

   if cached ~= nil and cached.imagePath == image_path then
      return cached
   end

   local built = buildThemeForScreen(target_screen)
   theme_cache[screen_key] = built
   return built
end

local function getTargetWindow()
   local win = window.focusedWindow() or window.frontmostWindow()
   if win == nil or not win:isStandard() or not win:isVisible() then
      return nil
   end

   local app = win:application()
   if app == nil then
      return nil
   end

   local bundle_id = app:bundleID()
   if bundle_id ~= nil and EXCLUDED_APPS.bundleIDs[bundle_id] then
      return nil
   end

   local app_name = app:name() or ""
   if EXCLUDED_APPS.names[app_name] then
      return nil
   end

   for _, pattern in ipairs(EXCLUDED_APPS.namePatterns) do
      if string.find(app_name, pattern) ~= nil then
         return nil
      end
   end

   return win
end

local function getOverlayScreen(win)
   if win ~= nil then
      return win:screen()
   end
   return screen.mainScreen() or screen.primaryScreen()
end

local function getAppLabel(win)
   if win == nil then
      return "No active window"
   end

   local app = win:application()
   if app == nil then
      return "Window"
   end

   return app:name() or "Window"
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

   if new_width == current.w and new_height == current.h then
      return nil
   end

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

   if next_screen == nil or next_screen:id() == current_screen:id() then
      return nil
   end

   local next_screen_frame = next_screen:frame()
   local unit = current_screen:toUnitRect(current_frame)

   return {
      frame = frameFromUnit(next_screen_frame, unit),
      screenFrame = copyFrame(next_screen_frame),
      overlayScreen = next_screen,
      title = "Next Screen",
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
         { frame = anchoredFrame(screen_frame, original_frame.w, original_frame.h, 0.5, 0.5), cycleLabel = "1/4 Keep size" },
         { frame = copyFrame(screen_frame), cycleLabel = "2/4 Max" },
         { frame = anchoredFrame(screen_frame, screen_frame.w * 0.5, screen_frame.h * 0.5, 0.5, 0.5), cycleLabel = "3/4 50%" },
         { frame = original_frame, cycleLabel = "4/4 Restore", restore = true },
      }
   end

   if action.cycle == "corner" then
      return {
         { frame = anchoredFrame(screen_frame, original_frame.w, original_frame.h, action.anchorX, action.anchorY), cycleLabel = "1/5 Keep size" },
         { frame = anchoredFrame(screen_frame, screen_frame.w * 0.35, screen_frame.h * 0.35, action.anchorX, action.anchorY), cycleLabel = "2/5 35%" },
         { frame = anchoredFrame(screen_frame, screen_frame.w * 0.5, screen_frame.h * 0.5, action.anchorX, action.anchorY), cycleLabel = "3/5 50%" },
         { frame = anchoredFrame(screen_frame, screen_frame.w * 0.75, screen_frame.h * 0.75, action.anchorX, action.anchorY), cycleLabel = "4/5 75%" },
         { frame = original_frame, cycleLabel = "5/5 Restore", restore = true },
      }
   end

   if action.cycle == "edge" then
      return {
         { frame = frameFromUnit(screen_frame, action.unit), cycleLabel = "1/2 50%" },
         { frame = original_frame, cycleLabel = "2/2 Restore", restore = true },
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
   if steps == nil or #steps == 0 then
      return nil
   end

   local next_step = state.stepIndex + 1
   if next_step > #steps then
      next_step = 1
   end

   local plan = steps[next_step]
   plan.stepIndex = next_step
   plan.totalSteps = #steps
   plan.title = action.title
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
   if action == nil then
      return nil
   end

   if action.mode == "cycle" then
      return performCycleAction(win, action, key_name)
   end

   clearCycleState(win)

   if action.mode == "resize" then
      local next_frame = computeResizeFrame(win, action.delta)
      if next_frame == nil then
         return nil
      end

      applyFrame(win, next_frame)
      return {
         frame = next_frame,
         screenFrame = copyFrame(win:screen():frame()),
         overlayScreen = win:screen(),
         title = action.title,
         cycleLabel = action.delta > 0 and "+32 px" or "-32 px",
      }
   end

   if action.mode == "screenNext" then
      local plan = computeNextScreenPlan(win)
      if plan == nil then
         return nil
      end

      applyFrame(win, plan.frame)
      return plan
   end

   return nil
end

local function destroyHud()
   if hud_canvas ~= nil then
      hud_canvas:delete()
      hud_canvas = nil
      hud_screen_id = nil
      hud_elements = nil
      hud_theme = nil
   end
end

local function makeHudFrame(target_screen)
   local screen_frame = target_screen:frame()
   local width = clamp(math.floor(screen_frame.w * 0.26), 320, 400)
   local height = clamp(math.floor(screen_frame.h * 0.40), 340, 430)
   local x = screen_frame.x + math.floor((screen_frame.w - width) / 2)
   local y = screen_frame.y + math.floor((screen_frame.h - height) / 2)

   return geometry.rect(x, y, width, height)
end

local function buildHudElements(frame, subtitle, theme)
   local elements = {}
   local element_map = { tiles = {}, subtitle = 0, preview = {} }

   local outer = 18
   local top = 18
   local title_height = 20
   local subtitle_height = 16
   local preview_top = top + title_height + subtitle_height + 20
   local preview_height = 88
   local grid_top = preview_top + preview_height + 16
   local cell_gap = 10
   local cell_width = math.floor((frame.w - (outer * 2) - (cell_gap * 2)) / 3)
   local cell_height = 48
   local action_top = grid_top + (cell_height * 3) + (cell_gap * 2) + 14

   table.insert(elements, {
      type = "rectangle",
      action = "fill",
      roundedRectRadii = { xRadius = 22, yRadius = 22 },
      fillColor = theme.panelFill,
      strokeColor = theme.panelStroke,
      strokeWidth = 2,
      frame = { x = 0, y = 0, w = frame.w, h = frame.h },
   })

   table.insert(elements, {
      type = "rectangle",
      action = "fill",
      roundedRectRadii = { xRadius = 20, yRadius = 20 },
      fillColor = theme.accentGlow,
      frame = { x = 14, y = 14, w = frame.w - 28, h = 34 },
   })

   table.insert(elements, {
      type = "rectangle",
      action = "fill",
      roundedRectRadii = { xRadius = 3, yRadius = 3 },
      fillColor = theme.accentBar,
      frame = { x = 22, y = 18, w = 84, h = 4 },
   })

   table.insert(elements, {
      type = "text",
      text = "Fn Window",
      textFont = TITLE_FONT,
      textSize = 19,
      textColor = theme.titleColor,
      frame = { x = outer, y = top - 2, w = frame.w - (outer * 2), h = title_height },
   })

   table.insert(elements, {
      type = "text",
      text = subtitle,
      textFont = BODY_FONT,
      textSize = 12,
      textColor = theme.subtitleColor,
      frame = { x = outer, y = top + 20, w = frame.w - (outer * 2), h = subtitle_height },
   })
   element_map.subtitle = #elements

   table.insert(elements, {
      type = "rectangle",
      action = "fill",
      roundedRectRadii = { xRadius = 16, yRadius = 16 },
      fillColor = withAlpha(theme.previewFill, 0.20),
      strokeColor = withAlpha(theme.previewStroke, 0.36),
      strokeWidth = 1.2,
      frame = { x = outer, y = preview_top, w = frame.w - (outer * 2), h = preview_height },
   })

   local preview_monitor_frame = {
      x = outer + 12,
      y = preview_top + 12,
      w = 108,
      h = preview_height - 24,
   }

   table.insert(elements, {
      type = "rectangle",
      action = "fill",
      roundedRectRadii = { xRadius = 10, yRadius = 10 },
      fillColor = withAlpha(theme.previewFill, 0.40),
      strokeColor = withAlpha(theme.previewStroke, 0.70),
      strokeWidth = 1.4,
      frame = preview_monitor_frame,
   })

   table.insert(elements, {
      type = "rectangle",
      action = "fill",
      roundedRectRadii = { xRadius = 7, yRadius = 7 },
      fillColor = theme.previewWindow,
      strokeColor = withAlpha(theme.previewStroke, 0.92),
      strokeWidth = 1.2,
      frame = { x = preview_monitor_frame.x + 18, y = preview_monitor_frame.y + 12, w = 48, h = 32 },
   })
   element_map.preview.window = #elements
   element_map.preview.monitorFrame = preview_monitor_frame

   table.insert(elements, {
      type = "text",
      text = "Current frame",
      textFont = BODY_FONT,
      textSize = 12,
      textColor = theme.titleColor,
      frame = { x = preview_monitor_frame.x + preview_monitor_frame.w + 14, y = preview_top + 14, w = frame.w - preview_monitor_frame.w - (outer * 2) - 26, h = 18 },
   })
   element_map.preview.caption = #elements

   table.insert(elements, {
      type = "text",
      text = "Press the same key to rotate layout states",
      textFont = BODY_FONT,
      textSize = 11,
      textColor = theme.labelColor,
      frame = { x = preview_monitor_frame.x + preview_monitor_frame.w + 14, y = preview_top + 36, w = frame.w - preview_monitor_frame.w - (outer * 2) - 26, h = 30 },
   })
   element_map.preview.help = #elements

   local function addTile(key_name, label, short_label, x, y, width, height)
      table.insert(elements, {
         type = "rectangle",
         action = "fill",
         roundedRectRadii = { xRadius = 14, yRadius = 14 },
         fillColor = theme.tileFill,
         strokeColor = theme.tileStroke,
         strokeWidth = 1.5,
         frame = { x = x, y = y, w = width, h = height },
      })
      local rect_index = #elements

      table.insert(elements, {
         type = "text",
         text = label,
         textFont = KEY_FONT,
         textSize = 16,
         textColor = theme.keyColor,
         frame = { x = x + 10, y = y + 6, w = width - 20, h = 18 },
      })

      table.insert(elements, {
         type = "text",
         text = short_label,
         textFont = LABEL_FONT,
         textSize = 11,
         textColor = theme.labelColor,
         frame = { x = x + 10, y = y + height - 20, w = width - 20, h = 14 },
      })
      local label_index = #elements

      element_map.tiles[key_name] = {
         rect = rect_index,
         label = label_index,
      }
   end

   for row_index, row_keys in ipairs(GRID_ROWS) do
      for col_index, key_name in ipairs(row_keys) do
         local layout = KEY_LAYOUTS[key_name]
         local x = outer + ((col_index - 1) * (cell_width + cell_gap))
         local y = grid_top + ((row_index - 1) * (cell_height + cell_gap))
         addTile(key_name, layout.legend, layout.short, x, y, cell_width, cell_height)
      end
   end

   for index, key_name in ipairs(ACTION_ROW) do
      local layout = KEY_LAYOUTS[key_name]
      local x = outer + ((index - 1) * (cell_width + cell_gap))
      addTile(key_name, layout.legend, layout.short, x, action_top, cell_width, 42)
   end

   return elements, element_map
end

local function updatePreview(preview_info)
   if hud_canvas == nil or hud_elements == nil or hud_theme == nil then
      return
   end

   local preview = hud_elements.preview
   if preview == nil or preview.window == nil or preview.monitorFrame == nil then
      return
   end

   local screen_frame = preview_info and preview_info.screenFrame or nil
   local target_frame = preview_info and preview_info.frame or nil
   if screen_frame == nil or target_frame == nil then
      return
   end

   local inner_margin = 5
   local monitor = preview.monitorFrame
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

   hud_canvas[preview.window].frame = {
      x = inner.x + math.floor(inner.w * relative_x),
      y = inner.y + math.floor(inner.h * relative_y),
      w = math.max(12, math.floor(inner.w * relative_w)),
      h = math.max(10, math.floor(inner.h * relative_h)),
   }

   if preview.caption ~= nil then
      hud_canvas[preview.caption].text = preview_info.caption or "Current frame"
   end

   if preview.help ~= nil then
      hud_canvas[preview.help].text = preview_info.detail or "Press the same key to rotate layout states"
   end
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

local function highlightAction(key_name, subtitle)
   if hud_canvas == nil or hud_elements == nil or hud_theme == nil then
      return
   end

   for current_key, indices in pairs(hud_elements.tiles) do
      hud_canvas[indices.rect].fillColor = hud_theme.tileFill
      hud_canvas[indices.rect].strokeColor = hud_theme.tileStroke
      hud_canvas[indices.label].textColor = hud_theme.labelColor

      if current_key == key_name then
         hud_canvas[indices.rect].fillColor = hud_theme.tileActiveFill
         hud_canvas[indices.rect].strokeColor = hud_theme.tileActiveStroke
         hud_canvas[indices.label].textColor = hud_theme.labelActiveColor
      end
   end

   if hud_elements.subtitle > 0 then
      hud_canvas[hud_elements.subtitle].text = subtitle
   end
end

local function showHud(win, selected_key, preview_info, overlay_screen)
   local target_screen = overlay_screen or getOverlayScreen(win)
   if target_screen == nil then
      return
   end

   local subtitle = getAppLabel(win)
   ensureHud(target_screen, subtitle, getThemeForScreen(target_screen))
   highlightAction(selected_key, subtitle)
   updatePreview(preview_info)

   if not hud_canvas:isShowing() then
      hud_canvas:show(0.06)
   end
   hud_canvas:bringToFront(true)
end

local function hideHud()
   if hud_canvas ~= nil and hud_canvas:isShowing() then
      hud_canvas:hide(0.08)
   end
end

local function handleFlagChange(event)
   local flags = event:getFlags()
   local raw_flags = event:rawFlags()
   local is_fn_down = flags.fn or (raw_flags & raw_flag_masks.secondaryFn > 0)

   if is_fn_down == fn_active then
      return false
   end

   fn_active = is_fn_down

   if fn_active then
      local win = getTargetWindow()
      if win ~= nil then
         showHud(win, nil, {
            frame = copyFrame(win:frame()),
            screenFrame = copyFrame(win:screen():frame()),
            caption = "Current frame",
            detail = "Choose a keypad key to move or cycle the layout",
         }, win:screen())
      end
   else
      hideHud()
   end

   return false
end

local function handleKeyDown(event)
   if not fn_active then
      return false
   end

   local key_name = keycodes.map[event:getKeyCode()]
   local action = KEY_LAYOUTS[key_name]
   if action == nil then
      return false
   end

   local win = getTargetWindow()
   if win == nil then
      return true
   end

   local plan = performAction(win, key_name)
   if plan ~= nil then
      showHud(win, key_name, {
         frame = copyFrame(plan.frame),
         screenFrame = copyFrame(plan.screenFrame),
         caption = action.title,
         detail = plan.cycleLabel or action.title,
      }, plan.overlayScreen)
      highlightAction(key_name, getAppLabel(win) .. " - " .. (plan.cycleLabel or action.title))
   end

   return true
end

local function eventHandler(event)
   local event_type = event:getType()

   if event_type == event_types.flagsChanged then
      return handleFlagChange(event)
   end

   if event_type == event_types.keyDown then
      return handleKeyDown(event)
   end

   return false
end

function module.start()
   if key_tap ~= nil then
      return module
   end

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
