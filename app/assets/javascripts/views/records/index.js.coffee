class Cubemania.Views.RecordsIndex extends Cubemania.BaseView

  template: JST["records/index"]

  events:
    "click .tabs .single": "clickSingle"
    "click .tabs .avg5": "clickAvg5"
    "click .tabs .avg12": "clickAvg12"

  initialize: ->
    @recordsTable = @addSubview new Cubemania.Views.RecordsTable(collection: @collection)
    @bindTo Cubemania.currentPuzzle, "change", @puzzleChanged, this
    @selectedType = "avg5"

  render: ->
    $(@el).html(@template())
    @recordsTable.setElement(@$("div.table")).render()
    this

  clickSingle: (event) ->
    event.preventDefault()
    @$(".tabs a").removeClass("selected")
    @$(".tabs a.single").addClass("selected")
    @selectedType = "single"
    @refetchRecords()

  clickAvg5: (event) ->
    event.preventDefault()
    @$(".tabs a").removeClass("selected")
    @$(".tabs a.avg5").addClass("selected")
    @selectedType = "avg5"
    @refetchRecords()

  clickAvg12: (event) ->
    event.preventDefault()
    @$(".tabs a").removeClass("selected")
    @$(".tabs a.avg12").addClass("selected")
    @selectedType = "avg12"
    @refetchRecords()

  puzzleChanged: (puzzle) ->
    @collection.setPuzzleId puzzle.get("id")
    @refetchRecords()

  refetchRecords: ->
    @collection.fetch(data: $.param(type: @selectedType))
