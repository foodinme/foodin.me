class Router
  constructor: (@app) ->
    @getRoute()
    @app.history.bind window, 'statechange', @getRoute

  getRoute: =>
    @current_state = History.getState()
    path = @current_state.hash.split('?')[0]
    params = @current_state.hash.split('?')[1]
    route_name = @route_table[path]
    route = @app[route_name]
    if !!params
      route $.deparam(params)
    else
      route()

  route_table:
    '/': 'index'
    '/gimme': 'gimme'
    '/getit': 'getIt'
    '/gimme-another': 'gimmeAnother'


class GoogleMap
  constructor: (@app) ->
    @directionsService = new google.maps.DirectionsService()
    @addMapCanvas()
    @initialize()

  addMapCanvas: ->
    map_canvas = """
      <section class="map-canvas"></section>
    """
    $('section.map').append map_canvas
    @map_canvas = $('.map-canvas:first')[0]

  initialize: ->
    navigator.geolocation.getCurrentPosition @startMap

  startMap: (geo) =>
    lat = geo.coords.latitude
    long = geo.coords.longitude
    @directionsDisplay = new google.maps.DirectionsRenderer()
    start_location = new google.maps.LatLng(lat, long)
    mapOptions =
      zoom: 16
      center: start_location

    map = new google.maps.Map @map_canvas, mapOptions
    @directionsDisplay.setMap map

    @calcRoute start_location

  calcRoute: (start_location) =>
    request =
      origin: start_location
      destination: @app.destination
      travelMode: google.maps.TravelMode.WALKING

    @directionsService.route request, (response, status) =>
      @directionsDisplay.setDirections response  if status is google.maps.DirectionsStatus.OK


class App
  constructor: (@outlet) ->
    @router()

  history: History.Adapter

  index: =>
    index_view = """
      <section class="start">
        <span class="top-teeth"></span>
        <span class="top-teeth-shadow"></span>
        <h1><a href="javascript:void(0)" class="js-gimme"><img src="/assets/logo.svg" alt="FoodInMe" /></a></h1>
        <span class="bottom-teeth-shadow"></span>
        <span class="bottom-teeth"></span>
      </section>
    """
    @outlet.html index_view
    $('.js-gimme').click ->
      History.pushState null, 'Gimme Food!', '/gimme'

    @last_view = 'index'

  gimme: =>
    @url = false
    @getGimme().done(@gimmeView).error (error) =>
      @displayError error

  gimmeView: (data) =>
    gimme_view = """
        <section class="gladware">
          <img src="#{@foodIconFor(data.result.categories[0])}" class="food" />
        </section>
        <h2>#{data.result.name}</h2>

        <a href="javascript:void(0)" class="js-yeah"><img src="/assets/yeah.svg" alt="Yeaah!" /></a>
        <br />
        <a href="javascript:void(0)" class="js-nah" data-new-result="#{data.meh}"><img src="/assets/nah.svg" alt="nah..." /></a>
    """
    source_view = @sourceViewFor data.result.source, data.result.source_details
    if @last_view is 'index'
      $('span.top-teeth, span.top-teeth-shadow, span.bottom-teeth, span.bottom-teeth-shadow').addClass 'close'
      $('h1').fadeOut 500, =>
        console.log 'Executing?'
        @outlet.prepend """<section class="gimme" style="display: none;"">#{gimme_view}#{source_view}</section>"""
        $('section.gimme').fadeIn(100)
        $('span.top-teeth, span.top-teeth-shadow, span.bottom-teeth, span.bottom-teeth-shadow').removeClass('close').fadeOut 500, =>
          $('section.start').remove()
          @gimmeBindings()
    else
      @outlet.html """<section class="gimme">#{gimme_view}#{source_view}</section>"""
      @gimmeBindings()

    @last_view = 'gimme'

  gimmeBindings: ->
    $('.js-yeah').click (event) ->
      url = if app.url then "?url=#{encodeURIComponent(app.url)}" else ''
      History.pushState null, 'Go Get It.', "/getit#{url}"
    $('.js-nah').click (event) =>
      new_url = $(event.currentTarget).data('new-result')
      History.pushState null, 'Maybe something else...', "/gimme-another?url=#{encodeURIComponent(new_url)}"

  foodIconFor: (category) ->
    icon_table =
      diners: 'burger'
      newamerican: 'burger'
      tradamerican: 'burger'
      italian: 'spaghetti'
      mexican: 'taco'
      latin: 'taco'

    icon_name = if !!icon_table[category] then icon_table[category] else 'default'
    "/assets/#{icon_name}-icon.svg"

  gimmeAnother: (params) =>
    @url = params.url
    @getGimmeAnother(@url).done(@gimmeView).error (error) =>
      @displayError error

  getIt: (params) =>
    if params.url?
      @url = params.url
      @getGimmeAnother(@url).done(@getItView).error (error) =>
        @displayError error
    else
      @getGimme().done(@getItView).error (error) =>
        @displayError error

  getItView: (data) =>
    @destination = data.result.location.display_address.join ', '
    @outlet.html """<section class="map"></section>"""
    new GoogleMap @

  sourceViewFor: (source, details)->
    if source is 'yelp'
      """
      <section class="yelp">
        <img src="#{details.rating_img}" class="stars" />
        <a class="reviews">#{details.review_count} Reviews</a>
        <a href="http://yelp.com" class="yelp"><img src="/assets/yelp-logo.png" alt="Yelp"/></a>
      </section>
      """
    else
      # Stub for foursqure
      ''

  displayError: (error) ->
    $('body').prepend """<section class="error">#{error}</section>"""

  getGimme: ->
    $.ajax
      url: '/api/gimme'
      type: 'get'

  getGimmeAnother: (url) ->
    $.ajax
      url: url
      type: 'get'

  router: ->
    new Router @


@app = new App $('section.content:first')
