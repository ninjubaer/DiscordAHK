(command := SlashCommandBuilder(client))
.setName("screenshot")
.setDescription("Send a screenshot")
.setCallback(sendScreenshot)
(option := command.addBooleanOption())
.setName("Ephemeral")
.setDescription("Send the screenshot as an ephemeral message")
.setRequired(false)
.addChoice("Yes", "true")
.addChoice("No", "false")
msgbox command.addCommand()

sendScreenshot(interaction) {
    pBitmap := Gdip_BitmapFromScreen()
    attachment := AttachmentBuilder(pBitmap)
    embed := EmbedBuilder()
    .setTitle("Screenshot")
    .setImage(attachment)
    interaction.reply({
        type: 4,
        data: {
            embeds: [embed],
            files: [attachment],
            flags: interaction.data.options[1].value ? 64 : 0
        }
    })
    Gdip_DisposeImage(pBitmap)
}