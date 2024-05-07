#DllLoad winhttp.dll
Class Discord {
    static baseApi := "https://discord.com/api/v10"
    , intents := {
        GUILDS: 1 << 0
        , GUILD_MEMBERS: 1 << 1
        , GUILD_BANS: 1 << 2
        , GUILD_EMOJIS: 1 << 3
        , GUILD_INTEGRATIONS: 1 << 4
        , GUILD_WEBHOOKS: 1 << 5
        , GUILD_INVITES: 1 << 6
        , GUILD_VOICE_STATES: 1 << 7
        , GUILD_PRESENCES: 1 << 8
        , GUILD_MESSAGES: 1 << 9
        , GUILD_MESSAGE_REACTIONS: 1 << 10
        , GUILD_MESSAGE_TYPING: 1 << 11
        , DIRECT_MESSAGES: 1 << 12
        , DIRECT_MESSAGE_REACTIONS: 1 << 13
        , DIRECT_MESSAGE_TYPING: 1 << 14
        , MESSAGE_CONTENT: 1 << 15
        , GUILD_SCHEDULED_EVENTS: 1 << 16
    },
    flags := {
        crossposted: 1 << 0,
        is_crosspost: 1 << 1,
        suppress_embeds: 1 << 2,
        source_message_deleted: 1 << 3,
        urgent: 1 << 4,
        has_thread: 1 << 5,
        ephemeral: 1 << 6,
        loading: 1 << 7,
        FAILED_TO_MENTION_SOME_ROLES_IN_THREAD: 1 << 8
    }
    __New(token, intents := [Discord.intents.GUILDS, Discord.intents.GUILD_MESSAGES, Discord.intents.GUILD_MESSAGE_REACTIONS, Discord.intents.GUILD_MESSAGE_TYPING, Discord.intents.MESSAGE_CONTENT]) {
        this.ready := false
        this.token := token
        this.intents := 0
        this.commandCallback := {}
        if intents is Array
            for i, v in intents
                this.intents |= v
        else this.intents := intents
        this.ws := Discord.WebSocket("wss://gateway.discord.gg/?v=10&encoding=json", {
            message: (self, data) => this.OnMSG(data),
        })
        this.ws.sendText(Discord.JSON.stringify({
            op: 2,
            d: {
                token: token,
                intents: this.intents,
                properties: {
                    os: "windows",
                    browser: "ahk",
                    device: "ahk"
                },
                presence: {
                    since: 0,
                    activities: [{
                        name: "DiscordAHK",
                        type: 0
                    }],
                    status: "online",
                    afk: false
                }
            }
        }))
        
    }
    setPresence(content) {
        static activityTypes := Map("playing", 0, "streaming", 1, "listening", 2, "watching", 3, "custom", 4, "competing", 5)
        if !content.HasProp("name") || !content.HasProp("type")
            throw Error("Invalid presence content")
        if content.type is String {
            content.type := StrLower(content.type)
            if !activityTypes.Has(content.type)
                throw Error("Invalid activity type")
            content.type := activityTypes[content.type]
        }
        this.ws.sendText(Discord.JSON.stringify({
            op: 3,
            d: {
                since: 0,
                activities: [{ name: content.name, type: content.type }],
                status: "online",
                afk: false
            }
        }))
    }
    fetchCommands() {
        return this.Request("GET", "/applications/" this.user.id "/commands", "", Map("User-Agent", "DiscordAHK by ninju and ferox"))
    }
    OnMSG(data) {
        data := Discord.JSON.parse(data,,false)
        switch data.op {
            case 0:
                this.Once%data.t% := true
                switch data.t,0 {
                    case "READY":
                        this.sessionId := data.d.session_id
                        this.user := data.d.user
                        this.commandArray := Discord.JSON.parse(this.fetchCommands())
                        this.emit("ready")
                    case "MESSAGE_CREATE":
                        data.d.reply := (self,content,*) => this.sendMessage(data.d.channel_id, content, data.d.id)
                        data.d.isBot := data.d.author.HasProp("bot") && data.d.author.bot ? true : false, data.d.isWebhook := data.d.author.HasProp("webhook_id") ? true : false
                        this.emit("message_create", data.d)
                    case "interaction_create":
                        this.emit("interaction_create", Discord.Interaction(this,data.d))
                    default:
                        this.emit(data.t, data.d)
                }
            case 7,9:
                this.ws.reconnect()
            case 10:
                try SetTimer(this.sendHeartBeat, 0)
                SetTimer(this.sendHeartBeat.Bind(this), data.d.heartbeat_interval)
        }
    }
    sendHeartBeat(*) {
        this.ws.sendText(Discord.JSON.stringify({
            op: 1,
            d: this.sessionId
        }))
    }
    emit(event, args*) => this.HasProp("On" event) ? this.On%event%.call(args*) : ""
    Once(event, func) {
        if event != "ready"
            this.Once%event% := false
        while !this.HasProp("Once" event or !this.Once%event%)
            continue
        func.call()
    }
    On(event, func) => this.On%event% := func
    /**
     * Request(method, edpoint, data, headers)
     * authorization already included
     * @param {String} method 
     * @param {String} edpoint 
     * @param {String} data 
     * @param {Map} headers 
     */
    Request(method := "GET", edpoint := "", data := "", headers := Map()) {
        h := ComObject("WinHttp.WinHttpRequest.5.1")
        h.Option[9] := 0x800
        h.Open(method, Discord.baseApi edpoint, true)
        h.SetRequestHeader("Authorization", "Bot " this.token)
        for k, v in headers
            h.SetRequestHeader(k, v)
        h.Send(data)
        h.WaitForResponse()
        return h.ResponseText
    }
    sendContent(channel, content, replyid?) {
        return this.Request("POST", "/channels/" channel "/messages", Discord.JSON.stringify({
            content: content,
            message_reference: IsSet(replyid) ? { message_id: replyid } : ""
        }), Map("User-Agent", "DiscordAHK by ninju and ferox", "Content-Type", "application/json"))
    }
    sendMessage(channel, data, replyId?) {
        if IsSet(replyId)
            data.message_reference := { message_id: replyId }
        return this.Request("POST", "/channels/" channel "/messages", Discord.JSON.stringify(data), Map("User-Agent", "DiscordAHK by ninju and ferox", "Content-Type", "application/json"))
    }
    react(channel, message, emoji) {
        return this.Request("PUT", "/channels/" channel "/messages/" message "/reactions/" emoji "/@me", "", Map("User-Agent", "DiscordAHK by ninju and ferox"))
    }
    deleteMessage(channel, message) {
        return this.Request("DELETE", "/channels/" channel "/messages/" message, "", Map("User-Agent", "DiscordAHK by ninju and ferox"))
    }
    editMessage(channel, message, content) {
        return this.Request("PATCH", "/channels/" channel "/messages/" message, Discord.JSON.stringify(content), Map("User-Agent", "DiscordAHK by ninju and ferox", "Content-Type", "application/json"))
    }
    class Interaction {
        __New(self, data) {
            this.bot := self
            this.id := data.id
            this.token := data.token
            this.data := data
            this.member := data.member
            this.guild_id := data.guild_id
            this.channel_id := data.channel_id
            this.application_id := data.application_id
            this.type := data.type
            this.user := data.member.user
            A_Clipboard := Discord.JSON.stringify(this.data)
        }
        reply(content) {
            return this.bot.Request("POST", "/interactions/" this.id "/" this.token "/callback", Discord.JSON.stringify(content), Map("User-Agent", "DiscordAHK by ninju and ferox", "Content-Type", "application/json"))
        }
        isCommand() {
            for k,v in this.bot.commandArray
                if this.data.data.name = v["name"]
                    return true
            return false
        }
    }
    /************************************************************************
     * @description The websocket client implemented through winhttp,
     * requires that the system version be no less than win8.
     * @author thqby
     * @date 2024/01/27
     * @version 1.0.7
     ***********************************************************************/

    class WebSocket {
        Ptr := 0, async := 0, readyState := 0, url := ''

        ; The array of HINTERNET handles, [hSession, hConnect, hRequest(onOpen) | hWebSocket?]
        HINTERNETs := []

        ; when request is opened
        onOpen() => 0
        ; when server sent a close frame
        onClose(status, reason) => 0
        ; when server sent binary message
        onData(data, size) => 0
        ; when server sent UTF-8 message
        onMessage(msg) => 0
        reconnect() => 0

        /**
         * @param {String} Url the url of websocket
         * @param {Object} Events an object of `{open:(this)=>void,data:(this, data, size)=>bool,message:(this, msg)=>bool,close:(this, status, reason)=>void}`
         * @param {Integer} Async Use asynchronous mode
         * @param {Object|Map|String} Headers Additional request headers to use when creating connections
         * @param {Integer} TimeOut Set resolve, connect, send and receive timeout
         */
        __New(Url, Events := 0, Async := true, Headers := '', TimeOut := 0, InitialSize := 8192) {
            static contexts := Map()
            if (!RegExMatch(Url, 'i)^((?<SCHEME>wss?)://)?((?<USERNAME>[^:]+):(?<PASSWORD>.+)@)?(?<HOST>[^/:\s]+)(:(?<PORT>\d+))?(?<PATH>/\S*)?$', &m))
                Throw Discord.Websocket.Error('Invalid websocket url')
            if !hSession := DllCall('Winhttp\WinHttpOpen', 'ptr', 0, 'uint', 0, 'ptr', 0, 'ptr', 0, 'uint', Async ? 0x10000000 : 0, 'ptr')
                Throw Discord.Websocket.Error()
            this.async := Async := !!Async, this.url := Url
            this.HINTERNETs.Push(hSession)
            port := m.PORT ? Integer(m.PORT) : m.SCHEME = 'ws' ? 80 : 443
            dwFlags := m.SCHEME = 'wss' ? 0x800000 : 0
            if TimeOut
                DllCall('Winhttp\WinHttpSetTimeouts', 'ptr', hSession, 'int', TimeOut, 'int', TimeOut, 'int', TimeOut, 'int', TimeOut, 'int')
            if !hConnect := DllCall('Winhttp\WinHttpConnect', 'ptr', hSession, 'wstr', m.HOST, 'ushort', port, 'uint', 0, 'ptr')
                Throw Discord.Websocket.Error()
            this.HINTERNETs.Push(hConnect)
            switch Type(Headers) {
                case 'Object', 'Map':
                    s := ''
                    for k, v in Headers is Map ? Headers : Headers.OwnProps()
                        s .= '`r`n' k ': ' v
                    Headers := LTrim(s, '`r`n')
                case 'String':
                default:
                    Headers := ''
            }
            if (Events) {
                for k, v in Events.OwnProps()
                    if (k ~= 'i)^(open|data|message|close)$')
                        this.DefineProp('on' k, { call: v })
            }
            if (Async) {
                this.DefineProp('shutdown', { call: async_shutdown })
                    .DefineProp('receive', { call: receive })
                    .DefineProp('_send', { call: async_send })
            } else this.__cache_size := InitialSize
            connect(this), this.DefineProp('reconnect', { call: connect })

            connect(self) {
                if !self.HINTERNETs.Length
                    Throw Discord.Websocket.Error('The connection is closed')
                self.shutdown()
                if !hRequest := DllCall('Winhttp\WinHttpOpenRequest', 'ptr', hConnect, 'wstr', 'GET', 'wstr', m.PATH, 'ptr', 0, 'ptr', 0, 'ptr', 0, 'uint', dwFlags, 'ptr')
                    Throw Discord.Websocket.Error()
                self.HINTERNETs.Push(hRequest), self.onOpen()
                if (Headers)
                    DllCall('Winhttp\WinHttpAddRequestHeaders', 'ptr', hRequest, 'wstr', Headers, 'uint', -1, 'uint', 0x20000000, 'int')
                if (!DllCall('Winhttp\WinHttpSetOption', 'ptr', hRequest, 'uint', 114, 'ptr', 0, 'uint', 0, 'int')
                    || !DllCall('Winhttp\WinHttpSendRequest', 'ptr', hRequest, 'ptr', 0, 'uint', 0, 'ptr', 0, 'uint', 0, 'uint', 0, 'uptr', 0, 'int')
                    || !DllCall('Winhttp\WinHttpReceiveResponse', 'ptr', hRequest, 'ptr', 0)
                    || !DllCall('Winhttp\WinHttpQueryHeaders', 'ptr', hRequest, 'uint', 19, 'ptr', 0, 'wstr', status := '00000', 'uint*', 10, 'ptr', 0, 'int')
                    || status != '101')
                    Throw IsSet(status) ? Discord.Websocket.Error('Invalid status: ' status) : Discord.Websocket.Error()
                if !self.Ptr := DllCall('Winhttp\WinHttpWebSocketCompleteUpgrade', 'ptr', hRequest, 'ptr', 0)
                    Throw Discord.Websocket.Error()
                DllCall('Winhttp\WinHttpCloseHandle', 'ptr', self.HINTERNETs.Pop())
                self.HINTERNETs.Push(self.Ptr), self.readyState := 1
                (Async && async_receive(self))
            }

            async_receive(self) {
                static on_read_complete := get_sync_callback(), hHeap := DllCall('GetProcessHeap', 'ptr')
                static msg_gui := Gui(), wm_ahkmsg := DllCall('RegisterWindowMessage', 'str', 'AHK_WEBSOCKET_STATUSCHANGE', 'uint')
                static pHeapReAlloc := DllCall('GetProcAddress', 'ptr', DllCall('GetModuleHandle', 'str', 'kernel32', 'ptr'), 'astr', 'HeapReAlloc', 'ptr')
                static pSendMessageW := DllCall('GetProcAddress', 'ptr', DllCall('GetModuleHandle', 'str', 'user32', 'ptr'), 'astr', 'SendMessageW', 'ptr')
                static pWinHttpWebSocketReceive := DllCall('GetProcAddress', 'ptr', DllCall('GetModuleHandle', 'str', 'winhttp', 'ptr'), 'astr', 'WinHttpWebSocketReceive', 'ptr')
                static _ := (OnMessage(wm_ahkmsg, WEBSOCKET_READ_WRITE_COMPLETE, 0xff), DllCall('SetParent', 'ptr', msg_gui.Hwnd, 'ptr', -3))
                ; #DllLoad E:\projects\test\test\x64\Debug\test.dll
                ; on_read_complete := DllCall('GetProcAddress', 'ptr', DllCall('GetModuleHandle', 'str', 'test', 'ptr'), 'astr', 'WINHTTP_STATUS_READ_COMPLETE', 'ptr')
                NumPut('ptr', pws := ObjPtr(self), 'ptr', msg_gui.Hwnd, 'uint', wm_ahkmsg, 'uint', InitialSize, 'ptr', hHeap,
                    'ptr', cache := DllCall('HeapAlloc', 'ptr', hHeap, 'uint', 0, 'uptr', InitialSize, 'ptr'), 'uptr', 0, 'uptr', InitialSize,
                    'ptr', pHeapReAlloc, 'ptr', pSendMessageW, 'ptr', pWinHttpWebSocketReceive,
                    contexts[pws] := context := Buffer(11 * A_PtrSize)), self.__send_queue := []
                context.DefineProp('__Delete', { call: self => DllCall('HeapFree', 'ptr', hHeap, 'uint', 0, 'ptr', NumGet(self, 3 * A_PtrSize + 8, 'ptr')) })
                DllCall('Winhttp\WinHttpSetOption', 'ptr', self, 'uint', 45, 'ptr*', context.Ptr, 'uint', A_PtrSize)
                DllCall('Winhttp\WinHttpSetStatusCallback', 'ptr', self, 'ptr', on_read_complete, 'uint', 0x80000, 'uptr', 0, 'ptr')
                if err := DllCall('Winhttp\WinHttpWebSocketReceive', 'ptr', self, 'ptr', cache, 'uint', InitialSize, 'uint*', 0, 'uint*', 0)
                    self.onError(err)
            }

            static WEBSOCKET_READ_WRITE_COMPLETE(wp, lp, msg, hwnd) {
                static map_has := Map.Prototype.Has
                if !map_has(contexts, ws := NumGet(wp, 'ptr')) || (ws := ObjFromPtrAddRef(ws)).readyState != 1
                    return
                switch lp {
                    case 5:		; WRITE_COMPLETE
                        try ws.__send_queue.Pop()
                    case 4:		; WINHTTP_WEB_SOCKET_CLOSE_BUFFER_TYPE
                        if err := NumGet(wp, A_PtrSize, 'uint')
                            return ws.onError(err)
                        rea := ws.QueryCloseStatus(), ws.shutdown()
                        return ws.onClose(rea.status, rea.reason)
                    default:	; WINHTTP_WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE, WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE
                        data := NumGet(wp, A_PtrSize, 'ptr')
                        size := NumGet(wp, 2 * A_PtrSize, 'uptr')
                        if lp == 2
                            return ws.onMessage(StrGet(data, size, 'utf-8'))
                        else return ws.onData(data, size)
                }
            }

            static async_send(self, type, buf, size) {
                if (self.readyState != 1)
                    Throw Discord.Websocket.Error('websocket is disconnected')
                (q := self.__send_queue).InsertAt(1, buf)
                while (err := DllCall('Winhttp\WinHttpWebSocketSend', 'ptr', self, 'uint', type, 'ptr', buf, 'uint', size, 'uint')) = 4317 && A_Index < 60
                    Sleep(15)
                if err
                    q.RemoveAt(1), self.onError(err)
            }

            static async_shutdown(self) {
                if self.Ptr
                    DllCall('Winhttp\WinHttpSetOption', 'ptr', self, 'uint', 45, 'ptr*', 0, 'uint', A_PtrSize)
                (Discord.Websocket.Prototype.shutdown)(self)
                try contexts.Delete(ObjPtr(self))
            }

            static get_sync_callback() {
                mcodes := ['g+wMVot0JBiF9g+E0QAAAItEJBw9AAAQAHUVi0YkagVW/3YI/3YE/9Beg8QMwhQAPQAACAAPhaYAAACLBolEJASLRCQgU1VXi1AEx0QkFAAAAADHRCQYAAAAAIP6BHRsi04Yi+qLAI0MAYlOGIPlAXV2i0YUiUQkFI1EJBBSUP92CItGJP92BIlMJCjHRhgAAAAA/9CNfhyFwHQHi14MOx91UYsHK0YYagBqAFCLRhQDRhhQ/3QkMItGKP/QhcB0HT3dEAAAdBaJRCQUagSNRCQUUP92CItGJP92BP/QX11bXoPEDMIUAIteHI1+HDvLcrED24tGIFP/dhRqAP92EP/QhcB0B4lGFIkf65aF7XSSx0QkFA4AB4DrsQ==',
                    'SIXSD4QvAQAASIlcJCBBVkiD7FBIi9pMi/FBgfgAABAAdR9Ii0sITIvCi1IQQbkFAAAA/1NASItcJHhIg8RQQV7DQYH4AAAIAA+F3gAAAEiLAkljUQRIiWwkYEiJRCQwM8BIiXQkaEiJfCRwSMdEJDgAAAAASIlEJECD+gQPhIYAAABFiwGL6kiLQyhNjQQATIlDKIPlAQ+FnAAAAEiLQyBMi8qLUxBIi0sITIlEJEBMjUQkMEiJRCQ4SMdDKAAAAAD/U0BIjXswSIXAdAiLcxRIOzd1c0SLB0UzyUiLUyBJi85EK0MoSANTKEjHRCQgAAAAAP9TSIXAdCM93RAAAHQci8BIiUQkOItTEEyNRCQwSItLCEG5BAAAAP9TQEiLdCRoSItsJGBIi3wkcEiLXCR4SIPEUEFew0iLczBIjXswTDvGcpBIA/ZMi0MgTIvOSItLGDPS/1M4SIXAdAxIiUMgSIk36Wz///+F7Q+EZP///0jHRCQ4DgAHgOuM']
                DllCall('crypt32\CryptStringToBinary', 'str', hex := mcodes[A_PtrSize >> 2], 'uint', 0, 'uint', 1, 'ptr', 0, 'uint*', &s := 0, 'ptr', 0, 'ptr', 0) &&
                    DllCall('crypt32\CryptStringToBinary', 'str', hex, 'uint', 0, 'uint', 1, 'ptr', code := Buffer(s), 'uint*', &s, 'ptr', 0, 'ptr', 0) &&
                    DllCall('VirtualProtect', 'ptr', code, 'uint', s, 'uint', 0x40, 'uint*', 0)
                return code
                /*c++ source, /FAc /O2 /GS-
                struct Context {
                	void *obj;
                	HWND hwnd;
                	UINT msg;
                	UINT initial_size;
                	HANDLE heap;
                	BYTE *data;
                	size_t size;
                	size_t capacity;
                	decltype(&HeapReAlloc) ReAlloc;
                	decltype(&SendMessageW) Send;
                	decltype(&WinHttpWebSocketReceive) Receive;
                };
                void __stdcall WINHTTP_STATUS_READ_WRITE_COMPLETE(
                	void *hInternet,
                	Context *dwContext,
                	DWORD dwInternetStatus,
                	WINHTTP_WEB_SOCKET_STATUS *lpvStatusInformation,
                	DWORD dwStatusInformationLength) {
                	if (!dwContext)
                		return;
                	auto &context = *dwContext;
                	if (dwInternetStatus == WINHTTP_CALLBACK_FLAG_WRITE_COMPLETE)
                		return (void)context.Send(context.hwnd, context.msg, (WPARAM)dwContext, 5);
                	else if (dwInternetStatus != WINHTTP_CALLBACK_FLAG_READ_COMPLETE)
                		return;
                	UINT_PTR param[3] = { (UINT_PTR)context.obj, 0 };
                	DWORD err;
                	switch (auto bt = lpvStatusInformation->eBufferType)
                	{
                	case WINHTTP_WEB_SOCKET_CLOSE_BUFFER_TYPE:
                		goto close;
                	default:
                		size_t new_size;
                		auto is_fragment = bt & 1;
                		context.size += lpvStatusInformation->dwBytesTransferred;
                		if (!is_fragment) {
                			param[1] = (UINT_PTR)context.data;
                			param[2] = context.size;
                			context.size = 0;
                			if (!context.Send(context.hwnd, context.msg, (WPARAM)param, bt) ||
                				(new_size = (size_t)context.initial_size) == context.capacity)
                				break;
                		}
                		else if (context.size >= context.capacity)
                			new_size = context.capacity << 1;
                		else break;
                		if (auto p = context.ReAlloc(context.heap, 0, context.data, new_size))
                			context.data = (BYTE *)p, context.capacity = new_size;
                		else if (is_fragment) {
                			param[1] = E_OUTOFMEMORY;
                			goto close;
                		}
                		break;
                	}
                	err = context.Receive(hInternet, context.data + context.size, DWORD(context.capacity - context.size), 0, 0);
                	if (err && err != ERROR_INVALID_OPERATION) {
                		param[1] = err;
                	close: context.Send(context.hwnd, context.msg, (WPARAM)param, WINHTTP_WEB_SOCKET_CLOSE_BUFFER_TYPE);
                	}
                }*/
            }

            static receive(*) {
                Throw Discord.Websocket.Error('Used only in synchronous mode')
            }
        }

        __Delete() {
            this.shutdown()
            while (this.HINTERNETs.Length)
                DllCall('Winhttp\WinHttpCloseHandle', 'ptr', this.HINTERNETs.Pop())
        }

        onError(err, what := 0) {
            if err != 12030
                Throw Discord.Websocket.Error(err, what - 5)
            if this.readyState == 3
                return
            this.readyState := 3
            try this.onClose(1006, '')
        }

        class Error extends Error {
            __New(err := A_LastError, what := -4) {
                static module := DllCall('GetModuleHandle', 'str', 'winhttp', 'ptr')
                if err is Integer
                    if (DllCall("FormatMessage", "uint", 0x900, "ptr", module, "uint", err, "uint", 0, "ptr*", &pstr := 0, "uint", 0, "ptr", 0), pstr)
                        err := (msg := StrGet(pstr), DllCall('LocalFree', 'ptr', pstr), msg)
                    else err := OSError(err).Message
                super.__New(err, what)
            }
        }

        queryCloseStatus() {
            if (!DllCall('Winhttp\WinHttpWebSocketQueryCloseStatus', 'ptr', this, 'ushort*', &usStatus := 0, 'ptr', vReason := Buffer(123), 'uint', 123, 'uint*', &len := 0))
                return { status: usStatus, reason: StrGet(vReason, len, 'utf-8') }
            else if (this.readyState > 1)
                return { status: 1006, reason: '' }
        }

        /** @param type BINARY_MESSAGE = 0, BINARY_FRAGMENT = 1, UTF8_MESSAGE = 2, UTF8_FRAGMENT = 3 */
        _send(type, buf, size) {
            if (this.readyState != 1)
                Throw Discord.Websocket.Error('websocket is disconnected')
            if err := DllCall('Winhttp\WinHttpWebSocketSend', 'ptr', this, 'uint', type, 'ptr', buf, 'uint', size, 'uint')
                return this.onError(err)
        }

        ; sends a utf-8 string to the server
        sendText(str) {
            if (size := StrPut(str, 'utf-8') - 1) {
                StrPut(str, buf := Buffer(size), 'utf-8')
                this._send(2, buf, size)
            } else
                this._send(2, 0, 0)
        }

        send(buf) => this._send(0, buf, buf.Size)

        receive() {
            if (this.readyState != 1)
                Throw Discord.Websocket.Error('websocket is disconnected')
            ptr := (cache := Buffer(size := this.__cache_size)).Ptr, offset := 0
            while (!err := DllCall('Winhttp\WinHttpWebSocketReceive', 'ptr', this, 'ptr', ptr + offset, 'uint', size - offset, 'uint*', &dwBytesRead := 0, 'uint*', &eBufferType := 0)) {
                switch eBufferType {
                    case 1, 3:
                        offset += dwBytesRead
                        if offset == size
                            cache.Size := size *= 2, ptr := cache.Ptr
                    case 0, 2:
                        offset += dwBytesRead
                        if eBufferType == 2
                            return StrGet(ptr, offset, 'utf-8')
                        cache.Size := offset
                        return cache
                    case 4:
                        rea := this.QueryCloseStatus(), this.shutdown()
                        try this.onClose(rea.status, rea.reason)
                        return
                }
            }
            (err != 4317 && this.onError(err))
        }

        shutdown() {
            if (this.readyState = 1) {
                this.readyState := 2
                DllCall('Winhttp\WinHttpWebSocketClose', 'ptr', this, 'ushort', 1006, 'ptr', 0, 'uint', 0)
                this.readyState := 3
            }
            while (this.HINTERNETs.Length > 2)
                DllCall('Winhttp\WinHttpCloseHandle', 'ptr', this.HINTERNETs.Pop())
            this.Ptr := 0
        }
    }

    ; ws := WebSocket(wss_or_ws_url, {
    ; 	message: (self, data) => FileAppend(Data '`n', '*', 'utf-8'),
    ; 	close: (self, status, reason) => FileAppend(status ' ' reason '`n', '*', 'utf-8')
    ; })
    ; ws.sendText('hello'), Sleep(100)
    ; ws.send(0, Buffer(10), 10), Sleep(100)
    /************************************************************************
     * @description: JSON格式字符串序列化和反序列化, 修改自[HotKeyIt/Yaml](https://github.com/HotKeyIt/Yaml)
     * 增加了对true/false/null类型的支持, 保留了数值的类型
     * @author thqby, HotKeyIt
     * @date 2024/02/24
     * @version 1.0.7
     ***********************************************************************/

    class JSON {
        static null := ComValue(1, 0), true := ComValue(0xB, 1), false := ComValue(0xB, 0)

        /**
         * Converts a AutoHotkey Object Notation JSON string into an object.
         * @param text A valid JSON string.
         * @param keepbooltype convert true/false/null to Discord.JSON.true / Discord.JSON.false / Discord.JSON.null where it's true, otherwise 1 / 0 / ''
         * @param as_map object literals are converted to map, otherwise to object
         */
        static parse(text, keepbooltype := false, as_map := true) {
            keepbooltype ? (_true := Discord.JSON.true, _false := Discord.JSON.false, _null := Discord.JSON.null) : (_true := true, _false := false, _null := "")
            as_map ? (map_set := (maptype := Map).Prototype.Set) : (map_set := (obj, key, val) => obj.%key% := val, maptype := Object)
            NQ := "", LF := "", LP := 0, P := "", R := ""
            D := [C := (A := InStr(text := LTrim(text, " `t`r`n"), "[") = 1) ? [] : maptype()], text := LTrim(SubStr(text, 2), " `t`r`n"), L := 1, N := 0, V := K := "", J := C, !(Q := InStr(text, '"') != 1) ? text := LTrim(text, '"') : ""
            Loop Parse text, '"' {
                Q := NQ ? 1 : !Q
                NQ := Q && RegExMatch(A_LoopField, '(^|[^\\])(\\\\)*\\$')
                if !Q {
                    if (t := Trim(A_LoopField, " `t`r`n")) = "," || (t = ":" && V := 1)
                        continue
                    else if t && (InStr("{[]},:", SubStr(t, 1, 1)) || A && RegExMatch(t, "m)^(null|false|true|-?\d+(\.\d*(e[-+]\d+)?)?)\s*[,}\]\r\n]")) {
                        Loop Parse t {
                            if N && N--
                                continue
                            if InStr("`n`r `t", A_LoopField)
                                continue
                            else if InStr("{[", A_LoopField) {
                                if !A && !V
                                    throw Error("Malformed JSON - missing key.", 0, t)
                                C := A_LoopField = "[" ? [] : maptype(), A ? D[L].Push(C) : map_set(D[L], K, C), D.Has(++L) ? D[L] := C : D.Push(C), V := "", A := Type(C) = "Array"
                                continue
                            } else if InStr("]}", A_LoopField) {
                                if !A && V
                                    throw Error("Malformed JSON - missing value.", 0, t)
                                else if L = 0
                                    throw Error("Malformed JSON - to many closing brackets.", 0, t)
                                else C := --L = 0 ? "" : D[L], A := Type(C) = "Array"
                            } else if !(InStr(" `t`r,", A_LoopField) || (A_LoopField = ":" && V := 1)) {
                                if RegExMatch(SubStr(t, A_Index), "m)^(null|false|true|-?\d+(\.\d*(e[-+]\d+)?)?)\s*[,}\]\r\n]", &R) && (N := R.Len(0) - 2, R := R.1, 1) {
                                    if A
                                        C.Push(R = "null" ? _null : R = "true" ? _true : R = "false" ? _false : IsNumber(R) ? R + 0 : R)
                                    else if V
                                        map_set(C, K, R = "null" ? _null : R = "true" ? _true : R = "false" ? _false : IsNumber(R) ? R + 0 : R), K := V := ""
                                    else throw Error("Malformed JSON - missing key.", 0, t)
                                } else {
                                    ; Added support for comments without '"'
                                    if A_LoopField == '/' {
                                        nt := SubStr(t, A_Index + 1, 1), N := 0
                                        if nt == '/' {
                                            if nt := InStr(t, '`n', , A_Index + 2)
                                                N := nt - A_Index - 1
                                        } else if nt == '*' {
                                            if nt := InStr(t, '*/', , A_Index + 2)
                                                N := nt + 1 - A_Index
                                        } else nt := 0
                                        if N
                                            continue
                                    }
                                    throw Error("Malformed JSON - unrecognized character.", 0, A_LoopField " in " t)
                                }
                            }
                        }
                    } else if A || InStr(t, ':') > 1
                        throw Error("Malformed JSON - unrecognized character.", 0, SubStr(t, 1, 1) " in " t)
                } else if NQ && (P .= A_LoopField '"', 1)
                    continue
                else if A
                    LF := P A_LoopField, C.Push(InStr(LF, "\") ? UC(LF) : LF), P := ""
                else if V
                    LF := P A_LoopField, map_set(C, K, InStr(LF, "\") ? UC(LF) : LF), K := V := P := ""
                else
                    LF := P A_LoopField, K := InStr(LF, "\") ? UC(LF) : LF, P := ""
            }
            return J
            UC(S, e := 1) {
                static m := Map(Ord('"'), '"', Ord("a"), "`a", Ord("b"), "`b", Ord("t"), "`t", Ord("n"), "`n", Ord("v"), "`v", Ord("f"), "`f", Ord("r"), "`r")
                local v := ""
                Loop Parse S, "\"
                    if !((e := !e) && A_LoopField = "" ? v .= "\" : !e ? (v .= A_LoopField, 1) : 0)
                        v .= (t := InStr("ux", SubStr(A_LoopField, 1, 1)) ? SubStr(A_LoopField, 1, RegExMatch(A_LoopField, "i)^[ux]?([\dA-F]{4})?([\dA-F]{2})?\K") - 1) : "") && RegexMatch(t, "i)^[ux][\da-f]+$") ? Chr(Abs("0x" SubStr(t, 2))) SubStr(A_LoopField, RegExMatch(A_LoopField, "i)^[ux]?([\dA-F]{4})?([\dA-F]{2})?\K")) : m.has(Ord(A_LoopField)) ? m[Ord(A_LoopField)] SubStr(A_LoopField, 2) : "\" A_LoopField, e := A_LoopField = "" ? e : !e
                return v
            }
        }

        /**
         * Converts a AutoHotkey Array/Map/Object to a Object Notation JSON string.
         * @param obj A AutoHotkey value, usually an object or array or map, to be converted.
         * @param expandlevel The level of JSON string need to expand, by default expand all.
         * @param space Adds indentation, white space, and line break characters to the return-value JSON text to make it easier to read.
         */
        static stringify(obj, expandlevel := false, space := "  ") {
            expandlevel := IsSet(expandlevel) ? Abs(expandlevel) : 10000000
            return Trim(CO(obj, expandlevel))
            CO(O, J := 0, R := 0, Q := 0) {
                static M1 := "{", M2 := "}", S1 := "[", S2 := "]", N := "`n", C := ",", S := "- ", E := "", K := ":"
                if (OT := Type(O)) = "Array" {
                    D := !R ? S1 : ""
                    for key, value in O {
                        F := (VT := Type(value)) = "Array" ? "S" : InStr("Map,Object", VT) ? "M" : E
                        Z := VT = "Array" && value.Length = 0 ? "[]" : ((VT = "Map" && value.count = 0) || (VT = "Object" && ObjOwnPropCount(value) = 0)) ? "{}" : ""
                        D .= (J > R ? "`n" CL(R + 2) : "") (F ? (%F%1 (Z ? "" : CO(value, J, R + 1, F)) %F%2) : ES(value)) (OT = "Array" && O.Length = A_Index ? E : C)
                    }
                } else {
                    D := !R ? M1 : ""
                    for key, value in (OT := Type(O)) = "Map" ? (Y := 1, O) : (Y := 0, O.OwnProps()) {
                        F := (VT := Type(value)) = "Array" ? "S" : InStr("Map,Object", VT) ? "M" : E
                        Z := VT = "Array" && value.Length = 0 ? "[]" : ((VT = "Map" && value.count = 0) || (VT = "Object" && ObjOwnPropCount(value) = 0)) ? "{}" : ""
                        D .= (J > R ? "`n" CL(R + 2) : "") (Q = "S" && A_Index = 1 ? M1 : E) ES(key) K (F ? (%F%1 (Z ? "" : CO(value, J, R + 1, F)) %F%2) : ES(value)) (Q = "S" && A_Index = (Y ? O.count : ObjOwnPropCount(O)) ? M2 : E) (J != 0 || R ? (A_Index = (Y ? O.count : ObjOwnPropCount(O)) ? E : C) : E)
                        if J = 0 && !R
                            D .= (A_Index < (Y ? O.count : ObjOwnPropCount(O)) ? C : E)
                    }
                }
                if J > R
                    D .= "`n" CL(R + 1)
                if R = 0
                    D := RegExReplace(D, "^\R+") (OT = "Array" ? S2 : M2)
                return D
            }
            ES(S) {
                switch Type(S) {
                    case "Float":
                        if (v := '', d := InStr(S, 'e'))
                            v := SubStr(S, d), S := SubStr(S, 1, d - 1)
                        if ((StrLen(S) > 17) && (d := RegExMatch(S, "(99999+|00000+)\d{0,3}$")))
                            S := Round(S, Max(1, d - InStr(S, ".") - 1))
                        return S v
                    case "Integer":
                        return S
                    case "String":
                        S := StrReplace(S, "\", "\\")
                        S := StrReplace(S, "`t", "\t")
                        S := StrReplace(S, "`r", "\r")
                        S := StrReplace(S, "`n", "\n")
                        S := StrReplace(S, "`b", "\b")
                        S := StrReplace(S, "`f", "\f")
                        S := StrReplace(S, "`v", "\v")
                        S := StrReplace(S, '"', '\"')
                        return '"' S '"'
                    default:
                        return S == Discord.JSON.true ? "true" : S == Discord.JSON.false ? "false" : "null"
                }
            }
            CL(i) {
                Loop (s := "", space ? i - 1 : 0)
                    s .= space
                return s
            }
        }
    }

}