try
    {Robot, Adapter, TextMessage} = require "hubot"
catch
    prequire = require("parent-require")
    {Robot, Adapter, TextMessage} = prequire "hubot"

Discord = require "discord.js"

class DiscordAdapter extends Adapter
    constructor: (robot) ->
        super robot
        @rooms = {}

    send: (envelope, messages...) ->
        for message in messages
            @discord.sendMessage @rooms[envelope.room], message

    reply: (envelope, messages...) ->
        for message in messages
            @discord.sendMessage @rooms[envelope.room], "#{envelope.user.name} #{message}"

    run: ->
        @token = process.env.DISBOT_TOKEN

        if not @token?
            @robot.logger.error "Disbot Error: No token specified, please set an environment variable named DISBOT_TOKEN"
            return

        @discord = new Discord.Client

        @discord.on "ready", @.onready
        @discord.on "message", @.onmessage

        @discord.loginWithToken @token

    onready: =>
        @robot.logger.info "Disbot: Logged with User: " + @discord.user.username
        @robot.name = @discord.user.username.toLowerCase()

        @robot.logger.info "Disbot: My name is " + @robot.name

        @emit "connected"

    onmessage: (message) =>
        return if message.author.id == @discord.user.id # skip messages from the bot itself

        user = @robot.brain.userForId message.author.id

        user.name = message.author.name
        user.room = message.channel.id

        @rooms[user.room] ?= message.channel

        text = message.cleanContent

        if message.channel.isPrivate
            return # TODO: ignore private channels for now...

        @robot.logger.debug "Disbot - Received Message: " + text
        @receive new TextMessage(user, text, message.id)


exports.use = (robot) ->
    new DiscordAdapter robot
