Class SlashCommandBuilder {
    __New(client) {
        this.bot := client
        this.commandObject := {}
    }
    remove() {
        if !this.HasProp('id')
            throw Error('Command needs to be created before it can be removed.')
        this.bot.request('DELETE', '/applications/' client.user.id '/commands' this.id )
    }
    setName(name) {
        this.commandObject.name := name
        this.name := name
        return this
    }
    setDescription(description) {
        this.commandObject.description := description
        return this
    }
    addStringOption() {
        if !this.commandObject.hasProp('options')
            this.commandObject.options := [{type:3}]
        else
            this.commandObject.options.push({type:3})
        return SlashCommandBuilder.Option(this,this.commandObject.options[this.commandObject.options.length])
    }
    addIntegerOption() {
        if !this.commandObject.hasProp('options')
            this.commandObject.options := [{type:4}]
        else
            this.commandObject.options.push({type:4})
        return SlashCommandBuilder.Option(this,this.commandObject.options[this.commandObject.options.length])
    }
    addBooleanOption() {
        if !this.commandObject.hasProp('options')
            this.commandObject.options := [{type:5}]
        else
            this.commandObject.options.push({type:5})
        return SlashCommandBuilder.Option(this,this.commandObject.options[this.commandObject.options.length])
    }
    addUserOption() {
        if !this.commandObject.hasProp('options')
            this.commandObject.options := [{type:6}]
        else
            this.commandObject.options.push({type:6})
        return SlashCommandBuilder.Option(this,this.commandObject.options[this.commandObject.options.length])
    }
    Class Option {
        __New(command, optionsObject) {
            this.command := command
            this.option:=optionsObject

        }
        setName(name) {
            this.option.name := name
            return this
        }
        setDescription(description) {
            this.option.description := description
            return this
        }
        setType(type) {
            this.option.type := type
            return this
        }
        setRequired(required) {
            this.option.required := Discord.JSON.%(required ? "true": "false")%
            return this
        }
        addChoice(name, value) {
            value := value = "true" ? Discord.JSON.true : value = "false" ? Discord.JSON.false : value
            if this.option.hasProp('choices')
                this.option.choices.push({name: name, value: value})
            else
                this.option.choices := [{name: name, value: value}]
            return this
        }
        addOption(options) {
            if this.option.hasProp('options')
                this.option.options.push(options)
            else
                this.option.options := [options]
            return SlashCommandBuilder.Option(this.command, this.option.options[this.option.options.length])
        }
    }

    setDefaultPermission(perm) {
        this.commandObject.default_permission := perm
        return this
    }
    setPermissions(permissions) {
        this.commandObject.permissions := permissions
        return this
    }
    setGuild(guildID) {
        this.guildID := guildID
        return this
    }
    setCallback(callback) {
        this.bot.commandCallback.%this.name% := callback
        return this
    }
    setGlobal() {
        this.guildID := 0
        return this
    }
    addCommand() {
        if !this.commandObject.hasProp('name') || !this.commandObject.hasProp('description')
            throw Error('Command needs a name and description to be created.')
        if this.HasProp('guildID') && this.guildID
            return this.bot.request('POST', '/applications/' this.bot.user.id '/guilds/' this.guildID '/commands', Discord.JSON.stringify(this.commandObject), Map("User-Agent", "DiscordAHK by ninju and ferox", "Content-Type", "application/json"))
        this.bot.request('POST', '/applications/' this.bot.user.id '/commands', Discord.JSON.stringify(this.commandObject), Map("User-Agent", "DiscordAHK by ninju and ferox", "Content-Type", "application/json"))
        this.bot.commandArray := Discord.JSON.parse(this.bot.fetchCommands())
    }
}