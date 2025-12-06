---@alias WebUIInputMode
---| 0 # GameOnly_NoInput (no UI input, game only)
---| 1 # UIOnly_FullInput (full UI input, no game input)
---| 2 # GameAndUI_MouseFocus (game + UI, mouse focus on UI)

---@class WebUIInstance
---@field Browser any
---@field Name string
---@field Path string
---@field InputMode WebUIInputMode
---@field BringToFront fun(self: WebUIInstance)
---@field SetStackOrder fun(self: WebUIInstance, order: integer)
---@field SetInputMode fun(self: WebUIInstance, mode: WebUIInputMode)
---@field RegisterEventHandler fun(self: WebUIInstance, eventName: string, handler: fun(...: any), callback?: any)
--- for some reason, helix has both event handlers, i believe the registereventhandler is deprecated, subscribe sounds better
---@field Subscribe fun(self: WebUIInstance, eventName: string, handler: fun(...: any), callback?: any)
---@field SendEvent fun(self: WebUIInstance, eventName: string, payload: any)
---@field CallFunction fun(self: WebUIInstance, functionName: string, ...: any)
---@field Destroy fun(self: WebUIInstance)
---@class WebUIClass
local WebUIClass = {}
WebUIClass.__index = WebUIClass

---@param Name string
---@param Path string
---@param InputMode? WebUIInputMode
---@return WebUIInstance
function WebUI(Name, Path, InputMode)
    return {}
end
