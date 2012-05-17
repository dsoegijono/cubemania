class Cubemania.Views.Timer extends Cubemania.BaseView
  template: JST["timer/timer"]

  events:
    "click a.toggle": "toggleManual"
    "submit #new_single": "submitSingle"
    "touchstart": "stopTimer"
    "touchend": "startTimer"
    "submit #add_comment": "addComment"
    "click a.add_comment": "toggleComment"
    "focus div.add_comment textarea": "disableTimer"
    "blur div.add_comment textarea": "enableTimer"

  initialize: ->
    @bindTo Cubemania.currentPuzzle, "change", @updateScramble, this
    @bindTo Cubemania.currentPuzzle, "change", @resetTime, this
    @timer = new Cubemania.Timer()
    @bindTo @timer, "stopped", @displayAddCommentBubble, this
    @bindTo @timer, "started", @hideAddCommentBubble, this
    @timerEnabled = true
    @scramble = Cubemania.scrambler.scramble(Cubemania.currentPuzzle.getName())
    $(document).keydown(@stopTimer)
    $(document).keyup(@startTimer)

  updateDisplay: =>
    @$(".time").html(formatTime(@timer.currentTime()))

  updateScramble: ->
    @scramble = Cubemania.scrambler.scramble(Cubemania.currentPuzzle.getName())
    @$(".scramble").html(formatScramble @scramble)

  resetTime: ->
    @timer.reset()
    @updateDisplay()

  render: ->
    $(@el).html(@template(currentTime: @timer.currentTime(), scramble: @scramble))
    this

  startTimer: (event) =>
    if (event.type == "touchend" or event.keyCode == 32) and !@timer.isRunning() and @timerEnabled
      if @justStopped
        @justStopped = false
      else
        @$(".time").removeClass("starting")
        if @timer.timeSinceStopped() > 2000
          @timer.start()
          Cubemania.flashView.slideUp()
        @intervalId = setInterval(@updateDisplay, 23)
      event.preventDefault()

  stopTimer: (event) =>
    if (event.type == "touchstart" or event.keyCode == 32) and @timerEnabled
      if @timer.isRunning()
        @timer.stop()
        @justStopped = true
        @updateDisplay()
        clearInterval(@intervalId)
        intervalId = null
        @createSingle(@timer.currentTime())
      else
        @$(".time").addClass("starting")
      event.preventDefault()

  toggleManual: (event) ->
    event.preventDefault()
    @$("#new_single").toggle()
    @$(".time").toggle()
    @timerEnabled = !@timerEnabled
    ct = event.currentTarget
    @$(ct).toggleText("Changed your mind?", "Set times manually")
    if @$(ct).text() == "Changed your mind?"
      @$("#single_human_time").focus()
    else
      @$("#single_human_time").blur()

  toggleComment: (event) ->
    event.preventDefault() if event?
    @$("div.add_comment form").toggle()
    @$("div.add_comment a").toggle()
    @$("div.add_comment form")[0].reset()

  enableTimer: ->
    @timerEnabled = true

  disableTimer: ->
    @timerEnabled = false

  submitSingle: (event) =>
    event.preventDefault()
    @collection.create({human_time: @$("#single_human_time").val(), scramble: @scramble})
    @updateScramble()
    @$("form")[0].reset()

  createSingle: (time) ->
    @collection.create({time: time, scramble: @scramble})
    @updateScramble() # TODO duplication

  addComment: (event) ->
    event.preventDefault()
    lastSingle = @collection.models[@collection.length - 1]
    lastSingle.set "comment", @$("#add_comment [name='comment']").val()
    lastSingle.save()
    @toggleComment()
    @hideAddCommentBubble()

  displayAddCommentBubble: ->
    @$("div.add_comment").slideDown()

  hideAddCommentBubble: ->
    @$("div.add_comment").slideUp()
    @$("div.add_comment form").hide()
    @$("div.add_comment a").show()

  onDispose: ->
    $(document).unbind("keydown")
    $(document).unbind("keyup")
