root = exports ? this

Array.max = (array) ->
  Math.max.apply(Math, array)

Array.min = (array) ->
  Math.min.apply(Math, array)

Array.sum = (array) ->
  total = 0
  total += item for item in array
  total

$.fn.toggleText = (open, close) ->
  $(this).text(if $(this).text() is open then close else open)

root.calculateDst = ->
  rightNow = new Date()
  jan1 = new Date(rightNow.getFullYear(), 0, 1, 0, 0, 0, 0)
  june1 = new Date(rightNow.getFullYear(), 6, 1, 0, 0, 0, 0)
  temp = jan1.toGMTString()
  jan2 = new Date(temp.substring(0, temp.lastIndexOf(" ") - 1))
  temp = june1.toGMTString()
  june2 = new Date(temp.substring(0, temp.lastIndexOf(" ") - 1))
  std_time_offset = (jan1 - jan2) / (1000 * 60 * 60)
  daylight_time_offset = (june1 - june2) / (1000 * 60 * 60)
  if std_time_offset is daylight_time_offset
    0
  else
    1

# code from https://github.com/rmm5t/jquery-timeago
root.timeInWords = (distanceMillis) ->
  l =
    seconds: "less than a minute"
    minute: "about a minute"
    minutes: "%d minutes"
    hour: "about an hour"
    hours: "about %d hours"
    day: "a day"
    days: "%d days"
    month: "about a month"
    months: "%d months"
    year: "about a year"
    years: "%d years"
    wordSeparator: " "

  seconds = Math.abs(distanceMillis) / 1000
  minutes = seconds / 60
  hours = minutes / 60
  days = hours / 24
  years = days / 365

  substitute = (string, value) ->
    string.replace(/%d/i, value)

  words = seconds < 45 && substitute(l.seconds, Math.round(seconds)) ||
    seconds < 90 && substitute(l.minute, 1) ||
    minutes < 45 && substitute(l.minutes, Math.round(minutes)) ||
    minutes < 90 && substitute(l.hour, 1) ||
    hours < 24 && substitute(l.hours, Math.round(hours)) ||
    hours < 42 && substitute(l.day, 1) ||
    days < 30 && substitute(l.days, Math.round(days)) ||
    days < 45 && substitute(l.month, 1) ||
    days < 365 && substitute(l.months, Math.round(days / 30)) ||
    years < 1.5 && substitute(l.year, 1) ||
    substitute(l.years, Math.round(years))

tooltip = ->
  xOffset = 10
  yOffset = 20
  $(".tooltip").hover((e) ->
    return if this.title is ""
    this.t = this.title
    this.title = ""
    $("#tooltip").text this.t
    $("#tooltip").animate({top: (e.pageY - xOffset) + "px", left: (e.pageX + yOffset) + "px"}, {queue: false, duration: 400}).fadeIn("normal")
  , ->
    return if this.t is null
    this.title = this.t
    $("#tooltip").hide()
  )
