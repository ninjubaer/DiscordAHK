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
    pBitmap := Gdip_BitmapFromScreen()
    attachment := AttachmentBuilder(pBitmap)
    embed := EmbedBuilder()
    .setTitle("Screenshot")
    .setImage(attachment)
    A_Clipboard := Discord.JSON.stringify(interaction, true)
    interaction.reply({
        type: 4,
        data: {
            embeds: [embed],
            files: [attachment],
            flags: !interaction.data.data.hasProp("options") || !interaction.data.data.options.has(1) ? 0 : interaction.data.data.options[1].value ? 64 : 0
        }
    })
    interaction.editReply({
        embeds: [f:=EmbedBuilder()
            .setTitle("Screenshot")
            .setDescription("Screenshot has been sent!")]
        , flags: 64
    })
    Gdip_DisposeImage(pBitmap)
}