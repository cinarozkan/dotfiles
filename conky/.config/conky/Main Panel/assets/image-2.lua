-- image-2.lua
-- by @wim66
-- Modified June 07 2025, added animation, animate setting, and crossfade effect

require 'cairo'

-- Attempt to safely require the 'cairo_xlib' module
local status, cairo_xlib = pcall(require, 'cairo_xlib')
if not status then
    cairo_xlib = setmetatable({}, { __index = _G })
end

-- === Settings ===
local settings = {
    animate = true,           -- Enable/disable animation (true/false)
    animation_interval = 10,  -- Seconds between image switches
    fade_duration = 2,        -- Duration of crossfade effect in seconds
}

-- === Table of drawable images ===
local images = {
    {
        path = "assets/BG-split.png",
        x = 0, y = 0, w = 297, h = 676,
        rotation = 0,  -- degrees
        draw_me = true
    },
    {
        path = "assets/BG.png",
        x = 0, y = 0, w = 297, h = 676,
        rotation = 0,  -- degrees
        draw_me = true  -- Changed to true to include in animation
    },
    {
        path = "assets/BG2.png",
        x = 0, y = 0, w = 297, h = 676,
        rotation = 0,  -- degrees
        draw_me = true
    },
    {
        path = "assets/BG3.png",
        x = 0, y = 0, w = 297, h = 676,
        rotation = 0,  -- degrees
        draw_me = true  -- Changed to true to include in animation
    },
    {
        path = "assets/BG4.png",
        x = 0, y = 0, w = 297, h = 676,
        rotation = 0,  -- degrees
        draw_me = true  -- Changed to true to include in animation
    },
}

-- === Animation state ===
local current_image_index = 1
local previous_image_index = 1
local last_switch_time = os.time()
local fade_start_time = os.time()
local is_fading = false

-- === Image drawing function with rotation and alpha ===
function draw_image(path, x, y, w, h, rotation, alpha)
    if not conky_window then return end

    local cs = cairo_xlib_surface_create(conky_window.display,
                                         conky_window.drawable,
                                         conky_window.visual,
                                         conky_window.width,
                                         conky_window.height)
    local cr = cairo_create(cs)

    local image = cairo_image_surface_create_from_png(path)
    if image then
        local img_width = cairo_image_surface_get_width(image)
        local img_height = cairo_image_surface_get_height(image)
        local scale_x = w / img_width
        local scale_y = h / img_height

        local center_x = x + w / 2
        local center_y = y + h / 2

        cairo_save(cr)
        cairo_translate(cr, center_x, center_y)
        cairo_rotate(cr, math.rad(rotation or 0))
        cairo_scale(cr, scale_x, scale_y)
        cairo_set_source_surface(cr, image, -img_width / 2, -img_height / 2)
        cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
        cairo_paint_with_alpha(cr, alpha or 1.0)
        cairo_restore(cr)

        cairo_surface_destroy(image)
    else
        print("Failed to load image: " .. path)
    end

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end

-- === Get the list of drawable images ===
function get_drawable_images()
    local drawable = {}
    for i, img in ipairs(images) do
        if img.draw_me then
            table.insert(drawable, i)
        end
    end
    return drawable
end

-- === Main drawing function ===
function conky_draw_image()
    if not conky_window then return end

    local drawable_images = get_drawable_images()
    if #drawable_images == 0 then
        print("No images set to draw_me = true")
        return
    end

    -- Handle animation
    local current_time = os.time()
    if settings.animate then
        if current_time - last_switch_time >= settings.animation_interval then
            -- Start crossfade to the next image
            previous_image_index = current_image_index
            current_image_index = current_image_index + 1
            if current_image_index > #drawable_images then
                current_image_index = 1
            end
            last_switch_time = current_time
            fade_start_time = current_time
            is_fading = true
        end
    else
        -- If animation is disabled, show the first drawable image without fading
        current_image_index = 1
        previous_image_index = 1
        is_fading = false
    end

    -- Calculate alpha for crossfade effect
    local alpha = 1.0
    if is_fading and settings.animate then
        local elapsed = current_time - fade_start_time
        alpha = elapsed / settings.fade_duration
        if alpha >= 1.0 then
            alpha = 1.0
            is_fading = false
        end
        alpha = math.min(math.max(alpha, 0.0), 1.0) -- Clamp alpha between 0 and 1
    end

    -- Draw images
    local current_img = images[drawable_images[current_image_index]]
    if is_fading and settings.animate then
        -- Draw previous image (fading out)
        local prev_img = images[drawable_images[previous_image_index]]
        draw_image(
            prev_img.path, prev_img.x, prev_img.y, prev_img.w, prev_img.h,
            prev_img.rotation or 0, 1.0 - alpha
        )
        -- Draw current image (fading in)
        draw_image(
            current_img.path, current_img.x, current_img.y, current_img.w, current_img.h,
            current_img.rotation or 0, alpha
        )
    else
        -- Draw only the current image at full opacity
        draw_image(
            current_img.path, current_img.x, current_img.y, current_img.w, current_img.h,
            current_img.rotation or 0, 1.0
        )
    end
end