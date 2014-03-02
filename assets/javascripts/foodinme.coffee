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


class GoogleMap
  constructor: ->
    @directionsService = new google.maps.DirectionsService()
    initialize()

  initialize: ->
    navigator.geolocation.getCurrentPosition startMap

  startMap: (geo) ->
    lat = geo.coords.latitude
    long = geo.coords.longitude
    @directionsDisplay = new google.maps.DirectionsRenderer()
    start_location = new google.maps.LatLng(lat, long)
    mapOptions =
      zoom: 16
      center: start_location

    map = new google.maps.Map(document.getElementById("map-canvas"), mapOptions)
    directionsDisplay.setMap map

    @calcRoute start_location

  calcRoute: (start_location, end_location) ->
    start = start_location
    end = end_location
    request =
      origin: start
      destination: end
      travelMode: google.maps.TravelMode.DRIVING

    @directionsService.route request, (response, status) ->
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
    @getGimme().done @gimmeView
    .error (error) =>
      @displayError error

  gimmeView: (data) ->
    console.log data
    gimme_view = """
      <h2>#{data.result.name}</h2>
    """
    source_view = @sourceViewFor data.result.source, data.result.source_details
    @outlet.html gimme_view + source_view

  gettingView: =>
    # Triggering map here, probably needs tweaking but not alot.
    # $(document).ready ->
    #   $(".js-start").click ->
    #     new GoogleMap

  sourceViewFor: (source, details)->
    if source is 'yelp'
      console.log details
      """
      <section class="yelp">
        <img src="#{details.rating_img}" />
        <a class="reviews">#{details.review_count} Reviews</a>
        <a href="http://yelp.com"><img src="/assets/yelp-logo.png" alt="Yelp"/></a>
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

  router: ->
    new Router @


@app = new App $('section.content:first')
