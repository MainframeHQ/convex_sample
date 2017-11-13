class Chat {

  static init(socket){
    var $messages  = $("#messages")
    var $input     = $("#message-input")

    socket.onOpen(e => console.log("OPEN", e))
    socket.onError(e => console.log("ERROR", e))
    socket.onClose(e => console.log("CLOSE", e))

    socket.connect()

    var chan = socket.channel("rooms:" + window.roomName, {})
    chan.join()
      .receive("ignore", () => console.log("auth error"))
      .receive("timeout", () => console.log("Connection interruption"))
      .receive("ok", (res) => console.log("join ok", res))
    chan.onError(e => console.log("something went wrong", e))
    chan.onClose(e => console.log("channel closed", e))

    $input.off("keypress").on("keypress", e => {
      if (e.keyCode == 13) {
        chan.push("post", {message: $input.val()}, 10000)
        $input.val("")
      }
    })

    chan.on("posted", msg => {
      $messages.append(this.messageTemplate(msg))
      scrollTo(0, document.body.scrollHeight)
    })

    chan.on("joined", msg => {
      var nick = this.sanitize(msg.nick)
      $messages.append(`<br/><i>[${nick} joined]</i>`)
    })

    chan.on("left", msg => {
      var nick = this.sanitize(msg.nick)
      $messages.append(`<br/><i>[${nick} left]</i>`)
    })
  }

  static sanitize(html){ return $("<div/>").text(html).html() }

  static messageTemplate(msg){
    let nick = this.sanitize(msg.nick)
    let body = this.sanitize(msg.body)

    return(`<p><strong>[${nick}]</strong>&nbsp; ${body}</p>`)
  }

}

export default Chat
