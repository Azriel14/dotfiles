-- ═══════════════════════════════════════════
-- MONITORS
-- ═══════════════════════════════════════════
hl.monitor({
    output = "DP-2",
    mode = "3440x1440@165",
    position = "0x0",
    scale = "1",
    bitdepth = 10,
})

-- ═══════════════════════════════════════════
-- VARIABLES
-- ═══════════════════════════════════════════
local terminal = "kitty"
local fileManager = "nemo"
local menu = "/home/weebus/.config/rofi/scripts/launcher_t2"

-- ═══════════════════════════════════════════
-- ENVIRONMENT
-- ═══════════════════════════════════════════
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("ecosystem:no_update_news", "true")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "qt6ct")
hl.env("WLR_DRM_NO_MODIFIERS", "1")
hl.env("GTK_THEME", "TokyoNight")

-- ═══════════════════════════════════════════
-- BEZIER CURVES
-- ═══════════════════════════════════════════
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("md3_standard", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })
hl.curve("md3_decel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("md3_accel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.1 } } })
hl.curve("crazyshot", { type = "bezier", points = { { 0.1, 1.5 }, { 0.76, 0.92 } } })
hl.curve("hyprnostretch", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.0 } } })
hl.curve("menu_decel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
hl.curve("menu_accel", { type = "bezier", points = { { 0.38, 0.04 }, { 1, 0.07 } } })
hl.curve("easeInOutCirc", { type = "bezier", points = { { 0.85, 0 }, { 0.15, 1 } } })
hl.curve("easeOutCirc", { type = "bezier", points = { { 0, 0.55 }, { 0.45, 1 } } })
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("softAcDecel", { type = "bezier", points = { { 0.26, 0.26 }, { 0.15, 1 } } })
hl.curve("md2", { type = "bezier", points = { { 0.4, 0 }, { 0.2, 1 } } })

-- ═══════════════════════════════════════════
-- ANIMATIONS
-- ═══════════════════════════════════════════
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 3,
    bezier = "md3_decel",
    style = "popin 60%",
})
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 3,
    bezier = "md3_decel",
    style = "popin 60%",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 3,
    bezier = "md3_accel",
    style = "popin 60%",
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 10,
    bezier = "default",
})
hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 3,
    bezier = "md3_decel",
})
hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 3,
    bezier = "menu_decel",
    style = "popin 80%",
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 7,
    bezier = "menu_decel",
    style = "slidefade 15%",
})
hl.animation({
    leaf = "specialWorkspace",
    enabled = true,
    speed = 3,
    bezier = "md3_decel",
    style = "slidefadevert 15%",
})
hl.animation({
    leaf = "specialWorkspace",
    enabled = true,
    speed = 3,
    bezier = "md3_decel",
    style = "slidevert",
})

-- ═══════════════════════════════════════════
-- KEYBINDS
-- ═══════════════════════════════════════════
local mainMod = "SUPER"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + 1", hl.dsp.exec_cmd("librewolf"))
hl.bind(mainMod .. " + 2", hl.dsp.exec_cmd("flatpak run dev.vencord.Vesktop"))
hl.bind(mainMod .. " + 3", hl.dsp.exec_cmd("steam"))
hl.bind(mainMod .. " + 4", hl.dsp.exec_cmd("obsidian"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | /home/weebus/.config/rofi/scripts/launcher_t1 -dmenu | cliphist decode | wl-copy"))

hl.bind("SUPER + O", hl.dsp.window.tag({ tag = "opaque" }))

hl.window_rule({
    match = { tag = "opaque" },
    opacity = "1 override 1 override 1 override",
})

hl.bind("PRINT", hl.dsp.exec_cmd("grim -o DP-2 - | swappy -f -"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("GEOM=$(slurp) && sleep 0.25 && grim -g \"$GEOM\" - | swappy -f -"))

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

hl.bind(mainMod .. " + page_up", hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind(mainMod .. " + page_down", hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
hl.bind(mainMod .. " + page_up", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })
hl.bind(mainMod .. " + page_down", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })

for i = 1, 9 do
    hl.bind(mainMod .. " + CTRL + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + CTRL + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + CTRL + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + CTRL + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- ═══════════════════════════════════════════
-- WINDOW RULES
-- ═══════════════════════════════════════════
hl.window_rule({
    name = "suppress-maximize-events",
    match = {
        class = ".*",
    },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    name = "floating-pavu",
    match = {
        class = "^(org.pulseaudio.pavucontrol)",
    },
    float = true,
    size = "1600 960",
    center = true,
})

-- ═══════════════════════════════════════════
-- CORE CONFIG
-- ═══════════════════════════════════════════
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 1,
        col = {
            active_border = "rgba(7aa2f7aa)",
            inactive_border = "rgba(414868aa)",
        },
        layout = "dwindle",
    },
    decoration = {
        rounding = 20,
        blur = {
            enabled = true,
            new_optimizations = true,
            size = 10,
            passes = 1,
            brightness = 1,
            noise = 0.01,
            contrast = 1,
            popups = true,
            popups_ignorealpha = 0.6,
            xray = true,
            special = false,
        },
        active_opacity = 1.0,
        inactive_opacity = 0.7,
        fullscreen_opacity = 1.0,
        dim_inactive = false,
        dim_strength = 0.1,
        dim_special = 0,
    },
    animations = {
        enabled = true,
    },
    dwindle = {
        preserve_split = true,
        smart_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = true,
    },
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

-- ═══════════════════════════════════════════
-- AUTOSTART
-- ═══════════════════════════════════════════
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")  
    hl.exec_cmd("waybar")
    hl.exec_cmd("mpvpaper -o \"no-audio --loop-playlist\" '*' /home/weebus/Pictures/Background/va11.mp4")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("seafile-applet")
    hl.exec_cmd("mako")
    hl.exec_cmd("~/.local/bin/sunshine-start.sh")
end)
