ping := SlashCommandBuilder(Client)
    .setName("ping")
    .setDescription("Replies with Pong!")
    .setCallback(pingFunction)
    .addCommand()

pingFunction(interaction) {
    embed := EmbedBuilder()
    .setTitle("Pinging...")
    interaction.reply({
        type: 5
    })
    DllCall("GetSystemTimeAsFileTime", "Int64P", &time := 0)
    ms := (time-interaction.createdAt) // 10000
    embed := EmbedBuilder()
    .setTitle("Pong!")
    .setDescription("Ping: ``" ms "``ms 🏓")
    A_Clipboard := interaction.editReply({
            embeds: [embed.embedObj]
    })
}