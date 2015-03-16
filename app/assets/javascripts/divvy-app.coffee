# attach functions to Divvy to avoid polluting the global namespace
window.Divvy = {}

window.divvyApp = angular.module('divvyApp', ['restangular', 'ngSanitize'])

divvyApp
  .controller 'divvyController', ['$scope', 'Restangular', ($scope, Restangular) ->
    $scope.areResultsShowing = false

    # map defaults to kohactive if no geolocation
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

          # remove old overlays(markers & polylines)
          i = 0
          while i < $scope.mapData.overlays.length
            $scope.mapData.overlays[i].setMap null
            i++

          # reset bounds object
          $scope.mapData.bounds = new google.maps.LatLngBounds()
          
          originMarker = new google.maps.Marker
            position: new google.maps.LatLng $scope.result.divvy.origin_latlng[0], $scope.result.divvy.origin_latlng[1]
            title: "Origin"
            map: $scope.mapData.map
          $scope.mapData.overlays.push originMarker
          $scope.mapData.bounds.extend originMarker.position

          $scope.walkingToDirections    = result.divvy.routes.walking_to.DirectionsResponse.route.leg.step
          $scope.walkingToPolyline      = result.divvy.routes.walking_to.DirectionsResponse.route.overview_polyline.points
          walkingToMapPolyline = new google.maps.Polyline
            path: google.maps.geometry.encoding.decodePath $scope.walkingToPolyline
          $scope.mapData.overlays.push(walkingToMapPolyline)

          bikingStartMarker = new google.maps.Marker
            position: new google.maps.LatLng $scope.result.divvy.origin_station.lat, $scope.result.divvy.origin_station.lng
            title: "Divvy Origin Station"
            map: $scope.mapData.map
          $scope.mapData.overlays.push(bikingStartMarker)
          $scope.mapData.bounds.extend bikingStartMarker.position

          $scope.bikingDirections       = result.divvy.routes.biking.DirectionsResponse.route.leg.step
          $scope.bikingPolyline         = result.divvy.routes.biking.DirectionsResponse.route.overview_polyline.points
          bikingMapPolyline = new google.maps.Polyline
            path: google.maps.geometry.encoding.decodePath $scope.bikingPolyline
          $scope.mapData.overlays.push(bikingMapPolyline)
          
          bikingEndMarker = new google.maps.Marker
            position: new google.maps.LatLng $scope.result.divvy.destination_station.lat, $scope.result.divvy.destination_station.lng
            title: "Divvy Destination Station"
            map: $scope.mapData.map
          $scope.mapData.overlays.push(bikingEndMarker)
          $scope.mapData.bounds.extend bikingEndMarker.position

          $scope.walkingFromDirections  = result.divvy.routes.walking_from.DirectionsResponse.route.leg.step
          $scope.walkingFromPolyline    = result.divvy.routes.walking_from.DirectionsResponse.route.overview_polyline.points
          walkingFromMapPolyline = new google.maps.Polyline
            path: google.maps.geometry.encoding.decodePath $scope.walkingFromPolyline
          $scope.mapData.overlays.push(walkingFromMapPolyline)

          destinationMarker = new google.maps.Marker
            position: new google.maps.LatLng $scope.result.divvy.destination_latlng[0], $scope.result.divvy.destination_latlng[1]
            title: "Destination"
            map: $scope.mapData.map
          $scope.mapData.overlays.push(destinationMarker)
          $scope.mapData.bounds.extend destinationMarker.position

          walkingToMapPolyline.setMap $scope.mapData.map
          bikingMapPolyline.setMap $scope.mapData.map
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
