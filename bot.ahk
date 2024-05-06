#SingleInstance Force
#Requires AutoHotkey v2.0
Persistent

#Include lib\DiscordAHK\
#Include Discord.ahk
client := Discord(IniRead("settings/config.ini","Discord","BotToken"))
client.On("ready", () => MsgBox("ready"))
client.On("message", (msg,*) => msg.content = "!ping" ? msg.reply("Pong!") : "")
client.On("interaction", (interaction, * ) => interaction is Discord.Interaction ? interaction.reply("Pong!") : "")
