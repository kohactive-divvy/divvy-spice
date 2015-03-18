# attach functions to Divvy to avoid polluting the global namespace
window.Divvy = {}

# this symbol is repeated along a polyline to create a dashed line
lineSymbol = 
  path: 'M 0,-1 0,1'
  strokeOpacity: 0.7
  strokeWeight: 6
  scale: 1

iconBase  = '//www.google.com/mapfiles/ms/micons/'
icons     = 
  origin      : "#{iconBase}green-dot.png"
  destination : "#{iconBase}red-dot.png"
  divvy       : "#{iconBase}ltblue-dot.png"
  dashed      : [ {
                    icon: lineSymbol
                    offset: '0'
                    repeat: '13px'
                  } ]

resultColors = [
  {limit: 117, percentage: 90},
  {limit: 54, percentage: 80}, 
  {limit: 30, percentage: 70},
  {limit: 18, percentage: 60},
  {limit: 11, percentage: 50},
  {limit: 7, percentage: 40},
  {limit: 4, percentage: 30},
  {limit: 2, percentage: 20},
  {limit: 1, percentage: 10}
]

window.divvyApp = angular.module('divvyApp', ['restangular', 'ngSanitize', 'ngAutocomplete'])

divvyApp
  .controller 'divvyController', ['$scope', 'Restangular', ($scope, Restangular) ->
    $scope.areResultsShowing = false

    # map defaults to kohactive
    $scope.mapData =
      map         : ''
      center      :
        latitude  : 41.895535
        longitude : -87.648056
      zoom        : 14
      overlays    : []
      bounds      : ''

    # Maneuvers almost always end in the word we need to apply the
    # correct arrow icon class. This splits the string at the hyphen(s)
    # and returns it if it is 'left' or 'right' since that's
    # all that's supported for now.
    $scope.maneuverToIcon = (maneuver) ->
      maneuverSplit     = maneuver.split '-'
      maneuverLastWord  = maneuverSplit[maneuverSplit.length - 1]
      if maneuverLastWord == 'left' or maneuverLastWord == 'right'
        maneuverLastWord

    # serverError is null by default
    $scope.serverError = null

    $scope.dismissError = ->
      $('#error-modal').modal 'hide'

    $scope.clickToggleResults = (e) ->
      if !$scope.areResultsShowing
        Divvy.addLoadingCursor()

        Restangular.all('api').customGET('trips.json', {"origin": $scope.directionsOrigin, "destination": $scope.directionsDestination}).then (result) ->
          $scope.result = result
          $scope.bikingDirections = $scope.walkingToDirections = $scope.walkingFromDirections = ''

          # remove old overlays(markers & polylines)
          i = 0
          while i < $scope.mapData.overlays.length
            $scope.mapData.overlays[i].setMap null
            i++

          # reset bounds object
          $scope.mapData.bounds = new google.maps.LatLngBounds()
          
          # set the results header color based on trip count
          trips = result.divvy.trips
          $scope.resultColor = switch
            when trips >= resultColors[0].limit
              if trips == 8506
                $scope.confidence = 100
              else
                $scope.confidence = resultColors[0].percentage
              "sidebar-result-color-1"
            when trips > resultColors[1].limit
              $scope.confidence = resultColors[1].percentage
              "sidebar-result-color-2"
            when trips > resultColors[2].limit
              $scope.confidence = resultColors[2].percentage
              "sidebar-result-color-3"
            when trips > resultColors[3].limit
              $scope.confidence = resultColors[3].percentage
              "sidebar-result-color-4"
            when trips > resultColors[4].limit
              $scope.confidence = resultColors[4].percentage
              "sidebar-result-color-5"
            when trips > resultColors[5].limit
              $scope.confidence = resultColors[5].percentage
              "sidebar-result-color-6"
            when trips > resultColors[6].limit
              $scope.confidence = resultColors[6].percentage
              "sidebar-result-color-7"
            when trips > resultColors[7].limit
              $scope.confidence = resultColors[7].percentage
              "sidebar-result-color-8"
            when trips > resultColors[8].limit
              $scope.confidence = resultColors[8].percentage
              "sidebar-result-color-9"
            else
              $scope.confidence = 10
              "sidebar-result-color-10"

          originMarker = new google.maps.Marker
            position: new google.maps.LatLng $scope.result.divvy.origin_latlng[0], $scope.result.divvy.origin_latlng[1]
            title: "Origin"
            map: $scope.mapData.map
            icon: icons['origin']
          $scope.mapData.overlays.push originMarker
          $scope.mapData.bounds.extend originMarker.position

          if result.divvy.routes.walking_to.DirectionsResponse.route
            $scope.walkingToDirections = result.divvy.routes.walking_to.DirectionsResponse.route.leg.step
            
            # if there's only one step, the api doesn't return the step enclosed which
            # messes with the view loop. This encloses it for proper view rendering
            if $scope.walkingToDirections.travel_mode
              walkingToEdit =
                maneuver          : result.divvy.routes.walking_to.DirectionsResponse.route.leg.step.maneuver
                html_instructions : result.divvy.routes.walking_to.DirectionsResponse.route.leg.html_instructions
                duration          : result.divvy.routes.walking_to.DirectionsResponse.route.leg.step.duration
                distance          : result.divvy.routes.walking_to.DirectionsResponse.route.leg.distance

              $scope.walkingToDirections = [walkingToEdit]

            $scope.walkingToPolyline      = result.divvy.routes.walking_to.DirectionsResponse.route.overview_polyline.points
            walkingToMapPolyline = new google.maps.Polyline
              path: google.maps.geometry.encoding.decodePath $scope.walkingToPolyline
              strokeColor: 'green'
              strokeOpacity: 0
              icons: icons.dashed
            $scope.mapData.overlays.push(walkingToMapPolyline)
            # $scope.mapData.bounds.extend $scope.mapData.bounds.extend result.divvy.routes.walking_to.DirectionsResponse.route.bounds

          bikingStartMarker = new google.maps.Marker
            position: new google.maps.LatLng $scope.result.divvy.origin_station.lat, $scope.result.divvy.origin_station.lng
            title: "Divvy Origin Station"
            map: $scope.mapData.map
            icon: icons['divvy']
          $scope.mapData.overlays.push(bikingStartMarker)
          $scope.mapData.bounds.extend bikingStartMarker.position

          if result.divvy.routes.biking.DirectionsResponse.status == 'OK'
            $scope.bikingDirections       = result.divvy.routes.biking.DirectionsResponse.route.leg.step
            
            if result.divvy.routes.biking.DirectionsResponse.route
              $scope.bikingDirections = result.divvy.routes.biking.DirectionsResponse.route.leg.step
              
              # if there's only one step, the api doesn't return the step enclosed which
              # messes with the view loop. This encloses it for proper view rendering
              if $scope.bikingDirections.travel_mode
                bikingToEdit =
                  maneuver          : result.divvy.routes.walking_to.DirectionsResponse.route.leg.step.maneuver
                  html_instructions : result.divvy.routes.walking_to.DirectionsResponse.route.leg.html_instructions
                  duration          : result.divvy.routes.walking_to.DirectionsResponse.route.leg.step.duration
                  distance          : result.divvy.routes.walking_to.DirectionsResponse.route.leg.distance

                $scope.bikingDirections = [bikingToEdit]

            $scope.bikingPolyline         = result.divvy.routes.biking.DirectionsResponse.route.overview_polyline.points
            bikingMapPolyline = new google.maps.Polyline
              path: google.maps.geometry.encoding.decodePath $scope.bikingPolyline
              strokeColor: '#3db7e4'
              strokeWeight: 8
              strokeOpacity: 0.7
            $scope.mapData.overlays.push(bikingMapPolyline)
            # $scope.mapData.bounds.extend result.divvy.routes.biking.DirectionsResponse.route.bounds
            
            bikingMapPolyline.setMap $scope.mapData.map

          bikingEndMarker = new google.maps.Marker
            position: new google.maps.LatLng $scope.result.divvy.destination_station.lat, $scope.result.divvy.destination_station.lng
            title: "Divvy Destination Station"
            map: $scope.mapData.map
            icon: icons['divvy']
          $scope.mapData.overlays.push(bikingEndMarker)
          $scope.mapData.bounds.extend bikingEndMarker.position

          if result.divvy.routes.walking_to.DirectionsResponse.route
            $scope.walkingFromDirections = result.divvy.routes.walking_from.DirectionsResponse.route.leg.step
            
            # if there's only one step, the api doesn't return the step enclosed which
            # messes with the view loop. This encloses it for proper view rendering
            if $scope.walkingFromDirections.travel_mode
              walkingFromEdit =
                maneuver          : result.divvy.routes.walking_to.DirectionsResponse.route.leg.step.maneuver
                html_instructions : result.divvy.routes.walking_to.DirectionsResponse.route.leg.html_instructions
                duration          : result.divvy.routes.walking_to.DirectionsResponse.route.leg.step.duration
                distance          : result.divvy.routes.walking_to.DirectionsResponse.route.leg.distance

              $scope.walkingFromDirections = [walkingFromEdit]
          
            $scope.walkingFromPolyline    = result.divvy.routes.walking_from.DirectionsResponse.route.overview_polyline.points
            walkingFromMapPolyline = new google.maps.Polyline
              path: google.maps.geometry.encoding.decodePath $scope.walkingFromPolyline
              strokeColor: 'red'
              strokeOpacity: 0
              icons: icons.dashed
            $scope.mapData.overlays.push(walkingFromMapPolyline)
            # $scope.mapData.bounds.extend result.divvy.routes.walking_from.DirectionsResponse.route.bounds

          destinationMarker = new google.maps.Marker
            position: new google.maps.LatLng $scope.result.divvy.destination_latlng[0], $scope.result.divvy.destination_latlng[1]
            title: "Destination"
            map: $scope.mapData.map
            icon: icons['destination']
          $scope.mapData.overlays.push(destinationMarker)
          $scope.mapData.bounds.extend destinationMarker.position

          walkingToMapPolyline.setMap $scope.mapData.map
          walkingFromMapPolyline.setMap $scope.mapData.map

          # Only markers are added to this bounds object, so it allows for
          # a few edge cases. Nbd though (AJR)
          $scope.mapData.map.fitBounds $scope.mapData.bounds

          $scope.areResultsShowing = true
          Divvy.removeLoadingCursor()

        , (error) ->
          Divvy.removeLoadingCursor()
          $scope.serverError = error.data.error
          $('#error-modal').modal()

      else
        $scope.areResultsShowing = false
  ]

  .directive 'initializeMap', ->
    link: ($scope) ->
      initMap = ->

        setMap = ->
          myOptions =
            zoom: 14
            center: new google.maps.LatLng($scope.mapData.center.latitude, $scope.mapData.center.longitude)
            mapTypeId: google.maps.MapTypeId.ROADMAP
            styles: [{"featureType":"road","stylers":[{"hue":"#5e00ff"},{"saturation":-79}]},{"featureType":"poi","stylers":[{"saturation":-78},{"hue":"#6600ff"},{"lightness":-47},{"visibility":"off"}]},{"featureType":"road.local","stylers":[{"lightness":22}]},{"featureType":"landscape","stylers":[{"hue":"#6600ff"},{"saturation":-11}]},{},{},{"featureType":"water","stylers":[{"saturation":-65},{"hue":"#1900ff"},{"lightness":8}]},{"featureType":"road.local","stylers":[{"weight":1.3},{"lightness":30}]},{"featureType":"transit","stylers":[{"visibility":"simplified"},{"hue":"#5e00ff"},{"saturation":-16}]},{"featureType":"transit.line","stylers":[{"saturation":-72}]},{}]

          $scope.mapData.map = new google.maps.Map(document.getElementById("map"), myOptions)

        setCoords = (coords) ->
          $scope.mapData.center =
            latitude: coords.coords.latitude
            longitude: coords.coords.longitude
          setMap()

        # took out geolocation...seems too cumbersome for this (AJR)
        # if geolocation is allowed, set current
        # coordinates and initialize the map
        # if navigator.geolocation
        #   navigator.geolocation.getCurrentPosition(setCoords)
        
        # # otherwise set the map with the defaults
        # else
        setMap()

      google.maps.event.addDomListener window, "load", initMap

      # TODO: update $scope.map.center on map pan

      $scope.$watch 'map.center', (coords) ->
        if $scope.mapData.map
          $scope.mapData.map.setCenter new google.maps.LatLng(coords.latitude, coords.longitude)

  # * adding on to included autocomplete directive *
  #
  # Enter tries to submit the form before the autocompleted
  # data is in the input. This disables the enter key if the
  # autocomplete window is visible. Double-enter to submit.
  #
  .directive 'ngAutocomplete', ->
    link: ($scope, element) ->
      google.maps.event.addDomListener element[0], 'keydown', (e) ->
        if e.keyCode == 13 and $('.pac-container').is ':visible'
          e.preventDefault()

  .directive 'ngPopover', ->
    link: ($scope, element) ->
      element.hover ->        
        element.popover
          container : 'body'
          placement : 'right'
          content   : "This Divvy route has been ridden #{$scope.result.divvy.trips} times. Relative to the complete dataset, this average time has a #{$scope.confidence}% confidence score(100% confidence is the route with the most trips). The average time is calculated by: walking time to the Divvy origin station + average time this route took via 2013 – 2014 Divvy trip data + walking time to destination from destination Divvy station"
        
        element.popover 'show'
      , ->
        element.popover 'destroy'
