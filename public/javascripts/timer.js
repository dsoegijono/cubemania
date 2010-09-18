var timerStarted = false;
var startTime;
var intervalId = null;
var justStopped = false;
var timerEnabled = true;

$(document).ready(function() {
  $('#timer #single_human_time').hide();
  $('#timer form input[type=submit]').hide();

  $('#timer #toggle').bind('click', function() {
    $('#single_human_time').toggle();
    $("#timer time").toggle();
    $('#timer form input[type=submit]').toggle();
    $(this).text($(this).text() == 'Set times manually' ? 'Changed your mind?' : 'Set times manually');
    timerEnabled = timerEnabled ? false : true;
  });

  // get the javascript object for the graph
  $("#timer #singles li time").map(function() {
    return $(this).attr("data-time");
  }).get();

  $(document).keyup(function(event) {
    if (event.keyCode == 32 && !timerStarted && timerEnabled) {
      if (justStopped) {
        justStopped = false;
      } else {
        startTimer();
      }
      return false;
    }
  });

  $(document).keydown(function(event) {
    if (event.keyCode == 32 && timerEnabled) {
      if (timerStarted) {
        stopTimer();
        justStopped = true;
      }
      return false;
    }
  });
});

function startTimer() {
  timerStarted = true;
  startTime = new Date().getTime();
  intervalId = setInterval(updateDisplay, 20)
}

function updateDisplay() {
  $("#timer time").text(formatTime(new Date().getTime() - startTime));
}

function stopTimer() {
  updateDisplay();
  $("#timer #single_time").val(new Date().getTime() - startTime);
  $("#timer form").submit();
  clearInterval(intervalId);
  timerStarted = false;
}