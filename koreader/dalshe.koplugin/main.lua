local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

local Dalshe = WidgetContainer:extend({
    name = "dalshe",
    is_doc_only = false,
})

local direct_launch_flag = "/mnt/us/koreader/settings/eschepyat-direct-launch"

function Dalshe:init()
    self.ui.menu:registerToMainMenu(self)

    local flag = io.open(direct_launch_flag, "r")
    if flag then
        flag:close()
        os.remove(direct_launch_flag)
        UIManager:scheduleIn(1, function()
            self:showStartScreen()
        end)
    end
end

function Dalshe:addToMainMenu(menu_items)
    menu_items.dalshe = {
        text = _("Ещё пять"),
        sorting_hint = "more_tools",
        callback = function()
            self:showStartScreen()
        end,
    }
end

function Dalshe:showStartScreen()
    local title = self.ui and self.ui.document and self.ui.document:getProps().title
    local book = title or _("Текущая книга")
    UIManager:show(InfoMessage:new({
        text = _("Когда продолжим?") .. "\n\n" .. book .. "\n\n" .. _("Только 5 страниц — можно остановиться раньше."),
    }))
end

return Dalshe
