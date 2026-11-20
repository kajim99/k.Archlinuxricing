

-- Violet/blue cursor for apps
hl.env("XCURSOR_THEME", "Bibata-Violet")
hl.env("XCURSOR_SIZE", "24")


-- Own scripts (~/.local/bin: wp, tools, autofile...) visible to the bar/search and anything Hyprland starts
do
    local bin, path = os.getenv("HOME") .. "/.local/bin", os.getenv("PATH") or "/usr/local/bin:/usr/bin"
    if not (":" .. path .. ":"):find(":" .. bin .. ":", 1, true) then
        hl.env("PATH", bin .. ":" .. path)
    end
end
