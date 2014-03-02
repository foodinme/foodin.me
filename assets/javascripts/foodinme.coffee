class Router
  constructor: (@app) ->
    @getRoute()
    @app.history.bind window, 'statechange', @getRoute

  getRoute: =>
    @current_state = History.getState()
    path = @current_state.hash.split('?')[0]
    route_name = @route_table[path]
    route = @app[route_name]
    route()

  route_table: {
    '/': 'index'
    '/gimme': 'gimme'
  }


class App
  constructor: (@outlet) ->
    @router()

  history: History.Adapter

  index: =>
    index_view = """
      <a href="javascript:void(0)" class="js-gimme">Food In Me.</a>
    """
    @outlet.html index_view
    $('.js-gimme').click ->
      History.pushState null, 'Gimme Food!', '/gimme'

  gimme: =>
    @getGimme().done (data) =>
      console.log data
      gimme_view = """
        <h2>#{data.result.name}</h2>

      """
      @outlet.html gimme_view
    .error (error) =>
      @displayError error

  displayError: (error) ->
    $('body').prepend """<section class="error">#{error}</section>"""

  getGimme: ->
    $.ajax
      url: '/api/gimme'
      type: 'get'

  router: ->
    new Router @


@app = new App $('section.content:first')
