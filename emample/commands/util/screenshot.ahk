(command := SlashCommandBuilder(client))
.setName("screenshot")
.setDescription("Send a screenshot")
.setCallback(sendScreenshot)
(option := command.addBooleanOption())
.setName("ephemeral")
.setDescription("Send the screenshot as an ephemeral message")
.setRequired(false)
command.addCommand()

sendScreenshot(interaction) {
    interaction.reply({
        type: 4,
        data: {
            embeds: [embed := EmbedBuilder()
                .setTitle("Screenshot")
                .setImage(attachment:=AttachmentBuilder(pBitmap := Gdip_BitmapFromScreen()))],
            files: [attachment],
            flags: !interaction.data.data.hasProp("options") || !interaction.data.data.options.has(1) ? 0 : interaction.data.data.options[1].value ? 64 : 0
        }
    })
    Gdip_DisposeImage(pBitmap)
}