includeCommands() {
    #Include %A_ScriptDir%\functions\isSetV.ahk
    loop files ".\commands\*.ahk", "R"
        if A_LoopFileName != "__includeCommands.ahk"
            includes .= "#Include " A_LoopFileFullPath "`r`n"
    (f:=FileOpen(".\commands\__includeCommands.ahk", "w")).Write(IsSetV(&includes)), f.Close()
}

interactionHandler(interaction,*) {
    if !interaction.isCommand()
        return interaction.reply({
            type: 4,
            data: {
                content: "This is not a command",
                flags: Discord.flags.EPHEMERAL
            }
        })
    ;timestamp:
    A_Clipboard := Discord.JSON.stringify(interaction.data)
    if client.commandCallback.HasProp(interaction.data.data.name)
        (client.commandCallback.%interaction.data.data.name%)(interaction)
    else
        interaction.reply({
            type: 4,
            data: {
                content: "Command has no callback function",
                flags: Discord.flags.EPHEMERAL
            }
        })
}
