newCommand(name, dataValue, funcRef:="") => commands[name]:=dataValue, if (funcRef!="") {commandFunc[name]:=funcRef}

runCommand(interation){
    name:=interaction.data.data.name
    try {
        commandFunc.Get(name, "")
        interaction.reply(commands[name])
    }
}

commandFunc:=Map()
commands:=Map()

dataValue:={
    type: 4,
    data: {
        embeds: [{
            title: "**BLEP**",
            color: 0x2b2d31
        }]
    }
}
blep() => MsgBox("Test! Function called.")
newCommand("blep", dataValue, Func("blep"))