#SingleInstance Force
#Requires AutoHotkey v2.0
Persistent

#Include lib\DiscordAHK\
#Include Discord.ahk
client := Discord(IniRead("settings/config.ini","Discord","BotToken"))
client.On("message", (msg,*) => msg.content = "!ping" ? msg.reply("Pong!") : "")
client.On("interaction", interactionHandler)


interactionHandler(interaction,*) {
    Switch interaction.data.data.name {
        case "blep":
            interaction.reply({
                type: 4,
                data: {
                    embeds: [{
                        title: "**BLEP**",
                        color: 0x2b2d31
                    }]
                }
            })
            msgbox interaction.react("👍")
    }

}