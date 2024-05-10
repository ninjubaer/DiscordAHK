#SingleInstance Force
#Requires AutoHotkey v2.0
Persistent
#Include .\..\lib\DiscordAHK\
#Include Discord.ahk
#Include Builders\
#Include SlashCommandBuilder.ahk
#Include EmbedBuilder.ahk
#Include AttachmentBuilder.ahk
#Include %A_ScriptDir%\..\lib\Gdip_All.ahk
#Include %A_ScriptDir%\functions\isSetV.ahk
;* if intents are omitted; those intents are used
;OnError (e,mode) => mode = "Return" ? -1 : 0
pToken := Gdip_Startup()
includeCommands() {
    if A_Args.Length
        return
    if FileExist(".\commands\__includeCommands.ahk")
        FileDelete(".\commands\__includeCommands.ahk")
    includes := '__includeCommands := true`r`n'
    loop files ".\commands\*.ahk", "R"
        if A_LoopFileName != "__includeCommands.ahk"
            includes .= "#Include *i " A_LoopFileFullPath "`r`n"
    (f:=FileOpen(".\commands\__includeCommands.ahk", "w")).Write(IsSetV(&includes)), f.Close()
    run '"' A_AhkPath '" "' A_ScriptFullPath '" /restart 1'
}
includeCommands()
Client := Discord(IniRead(".\..\settings\config.ini", "Discord", "BotToken"), [Discord.intents.GUILDS, Discord.intents.GUILD_MESSAGES, Discord.intents.GUILD_MESSAGE_REACTIONS, Discord.intents.GUILD_MESSAGE_TYPING, Discord.intents.MESSAGE_CONTENT])
Client.Once("READY", (*) => msgbox("The bot is online`nserving as: " . Client.User.Username))
attachment := AttachmentBuilder("bot.ahk")
#Include %A_ScriptDir%\Handlers\commandHandler.ahk
#include *i %A_ScriptDir%\commands\__includeCommands.ahk
Client.On("INTERACTION_CREATE", interactionHandler)
