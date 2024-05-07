#SingleInstance Force
#Requires AutoHotkey v2.0
Persistent

#Include lib\DiscordAHK\
#Include Discord.ahk
#include SlashCommandBuilder.ahk
#Include EmbedBuilder.ahk
client := Discord(IniRead("settings/config.ini","Discord","BotToken")) ;, [Discord.intents.GUILDS, Discord.intents.GUILD_MESSAGES, Discord.intents.MESSAGE_CONTENT])
client.Once("ready", () => (ToolTip("ready"), Sleep(1000), ToolTip()))
client.On("interaction_create", interactionHandler)

client.setPresence({
    name: "ninju 👀",
    type: "watching"
})

ninju := SlashCommandBuilder(client)
.setName("ninju")
.setDescription("ninju command")
.setCallback(ninjuCommand)
ninju.addCommand()

blep2 := SlashCommandBuilder(client)
.setName("blep2")
.setDescription("blep command")
.setCallback(blep2Command)
option := blep2.addOption()
.setName("blep2")
.setRequired("true")
.setDescription("get bleped")
.addChoice('ninju', 'ninju')
.addChoice('blep', 'blep')
.addChoice('blep2', 'blep2')
blep2.addCommand()
;A_Clipboard := Discord.JSON.stringify(blep2.commandObject, 100000)
A_Clipboard := Discord.JSON.stringify(client.commandArray)

interactionHandler(interaction,*) {
    if !interaction.isCommand()
        return
    if client.commandCallback.HasProp(interaction.data.data.name)
        (client.commandCallback.%interaction.data.data.name%)(interaction)
    else
        interaction.reply({
            type: 4,
            data: {
                content: "Command not found",
                flags: 64
            }
        })
}

ninjuCommand(interaction) {
    interaction.reply({
        type: 4,
        data: {
            content: "hi ninju!",
            flags: Discord.flags.EPHEMERAL
        }
    })
}
blep2Command(interaction) {
    embed := EmbedBuilder()
    .setTitle("**BLEP2**")
    .setTimeStamp()
    interaction.reply({
        type: 4,
        data: {
            embeds: [embed.embedObj]
        }
    })
}