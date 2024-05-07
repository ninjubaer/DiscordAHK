#SingleInstance Force
#Requires AutoHotkey v2.0
Persistent

#Include .\..\lib\DiscordAHK\
#Include Discord.ahk
#Include Builders\
#Include SlashCommandBuilder.ahk
#Include EmbedBuilder.ahk
#Include %A_ScriptDir%\Handlers\commandHandler.ahk
;* if intents are omitted; those intents are used
Client := Discord(IniRead(".\..\settings\config.ini", "Discord", "BotToken"), [Discord.intents.GUILDS, Discord.intents.GUILD_MESSAGES, Discord.intents.GUILD_MESSAGE_REACTIONS, Discord.intents.GUILD_MESSAGE_TYPING, Discord.intents.MESSAGE_CONTENT]) 

Client.Once("READY", (*) => msgbox("The bot is online`nserving as: " . Client.User.Username))
includeCommands()
Client.On("INTERACTION_CREATE", interactionHandler)


#Include %A_ScriptDir%\commands\util\ping.ahk