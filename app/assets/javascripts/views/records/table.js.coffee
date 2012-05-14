class Cubemania.Views.RecordsTable extends Cubemania.BaseView

  template: JST["records/table"]

  initialize: ->
    @bindTo @collection, "reset", @render, this
    @bindTo @collection, "remove", @render, this

  render: ->
    $(@el).html(@template(records: @collection, timerPath: "/puzzles/#{Cubemania.currentPuzzle.puzzle.get("slug")}/timer"))
    _.each(@collection.models, @appendRecord)
    this

  appendRecord: (record, index) ->
    view = new Cubemania.Views.Record(model: record, index: index)
    @$("#records tbody").append(view.render().el)
