window.divvyApp = angular.module('divvyApp', [])

divvyApp
  .controller 'divvyController', ($scope) ->
    $scope.areResultsShowing = false

    # map defaults if no geolocation
    $scope.mapData =
      map: ''
      center:
        latitude: 41.8781136
        longitude: -87.62979819999998
      zoom: 14

    $scope.clickToggleResults = ->
      $scope.areResultsShowing = !$scope.areResultsShowing

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
