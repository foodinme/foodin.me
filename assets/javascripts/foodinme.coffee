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
    route $.deparam(params)

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

  gimme: =>
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
    @outlet.html """<section class="gimme">#{gimme_view}#{source_view}</section>"""
    $('.js-yeah').click ->
      History.pushState null, 'Go Get It.', '/getit'
    $('.js-nah').click (event) =>
      new_url = $(event.currentTarget).data('new-result')
      History.pushState null, 'Maybe something else...', "/gimme-another?url=#{encodeURIComponent(new_url)}"

  foodIconFor: (category) ->
    icon_table =
      diners: 'burger'
      italian: 'spaghetti'
    "/assets/#{icon_table[category]}-icon.svg"

  gimmeAnother: (params) =>
    @getGimmeAnother(params.url).done(@gimmeView).error (error) =>
      @displayError error

  getIt: =>
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
