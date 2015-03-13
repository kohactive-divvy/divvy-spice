# attach functions to Divvy to avoid polluting the global namespace
window.Divvy = {}

window.divvyApp = angular.module('divvyApp', ['ngResource'])

divvyApp
  # temporary http factory
  .factory "Result", ($http) ->
    get: ->
      result = ""
      $http.get("http://localhost:3000/assets/test-data.json").success (response) ->
        response

  .controller 'divvyController', ($scope, Result) ->
    $scope.areResultsShowing = false

    # map defaults to kohactive if no geolocation
    $scope.mapData =
      map: ''
      center:
        latitude: 41.895535
        longitude: -87.648056
      zoom: 14

    $scope.clickToggleResults = (e) ->
      if !$scope.areResultsShowing
        Divvy.addLoadingCursor()
        
        # temporary timer for effect
        setTimeout ->
          Result.get().success (result) ->
            console.log result
            $scope.result = result
            $scope.areResultsShowing = true
            Divvy.removeLoadingCursor()
        , 3000
      else
        $scope.areResultsShowing = false

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

        # if geolocation is allowed, set current
        # coordinates and initialize the map
        if navigator.geolocation
          navigator.geolocation.getCurrentPosition(setCoords)
        
        # otherwise set the map with the defaults
        else
          setMap()

      google.maps.event.addDomListener window, "load", initMap

      # TODO: update $scope.map.center on map pan

      $scope.$watch 'map.center', (coords) ->
        if $scope.mapData.map
          $scope.mapData.map.setCenter new google.maps.LatLng(coords.latitude, coords.longitude)
