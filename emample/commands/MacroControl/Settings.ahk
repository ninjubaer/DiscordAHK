(command:=SlashCommandBuilder(Client)
.setName("settings")
.setCallback(GetCommand)
.setDescription("Get or Set a value from config"))
op := command.addStringOption()
.setName("key")
.setDescription("The key you want to get or set")
.setRequired(true)
for i in (sections := StrSplit(section := IniRead('.\..\settings\config.ini'), "`n", "`r")).Length ? sections : [section]
    for j in StrSplit(IniRead('.\..\settings\config.ini', i), "`n", "`r")
        op.addChoice(SubStr(j, 1, InStr(j, "=") - 1), SubStr(j, 1, InStr(j, "=") - 1))
command.addStringOption()
.setName("value")
.setDescription("The value you want to set")
.setRequired(false)
command.addCommand()

GetCommand(interaction) {
    for i in (sections := StrSplit(section := IniRead('.\..\settings\config.ini'), "`n", "`r")).Length ? sections : [section]
        for j in StrSplit(IniRead('.\..\settings\config.ini', i), "`n", "`r")
            if SubStr(j, 1, InStr(j, "=") - 1) == interaction.data.data.options[1].value
                value := SubStr(j, InStr(j, "=") + 1), section := i
    if !IsSet(value) {
        embed := EmbedBuilder()
        .setTitle("Error")
        .setDescription("Couldn't find the key in the config")
        .setColor(0xFF0000)
        interaction.reply({
            type: 4,
            data: {
                embeds: [embed.embedObj],
                flags: Discord.flags.EPHEMERAL
            }
        })
    }
    else {
        if interaction.data.data.options.has(2)
            IniWrite(interaction.data.data.options[2].value, '.\..\settings\config.ini', section, interaction.data.data.options[1].value)
        embed := EmbedBuilder()
        .setTitle(interaction.data.data.options[1].value)
        .setDescription((interaction.data.data.options.has(2) ? "Set to: " interaction.data.data.options[2].value : value))
        interaction.reply({
            type: 4,
            data: {
                embeds: [embed.embedObj],
                flags: Discord.flags.EPHEMERAL
            }
        })
    }
}
