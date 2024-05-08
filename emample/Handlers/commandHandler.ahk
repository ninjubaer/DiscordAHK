interactionHandler(interaction,*) {
    if !interaction.isCommand() {
        client.request("DELETE", "/applications/" interaction.data.application_id "/commands/" interaction.data.data.id,, Map("User-Agent", "DiscordAHK by ninju and ferox"))
        return interaction.reply({
            type: 4,
            data: {
                content: "This is not a command",
                flags: Discord.flags.EPHEMERAL
            }
        })
    }
    if client.commandCallback.HasProp(interaction.data.data.name)
        (client.commandCallback.%interaction.data.data.name%)(interaction)
    else {
        interaction.reply({
            type: 4,
            data: {
                content: "Command has no callback function",
                flags: Discord.flags.EPHEMERAL
            }
        })
        client.request("DELETE", "/applications/" interaction.data.application_id "/commands/" interaction.data.data.id,, Map("User-Agent", "DiscordAHK by ninju and ferox"))
    }
}
