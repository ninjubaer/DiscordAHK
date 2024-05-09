(command := SlashCommandBuilder(client))
.setName("screenshot")
.setDescription("Send a screenshot")
.setCallback(sendScreenshot)
.addCommand()

sendScreenshot(interaction) {
    pBitmap := Gdip_BitmapFromScreen()
    attachment := AttachmentBuilder(pBitmap)
    msgbox interaction.reply({
        files: [attachment.file]
    })
    Gdip_DisposeImage(pBitmap)
}