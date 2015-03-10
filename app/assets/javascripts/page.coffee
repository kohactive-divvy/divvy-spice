sizeSidebarResult = ->
  $sidebarResultBody = $('.sidebar-result-body')
  
  $sidebarResultBody.css
    'max-height' : $(window).height() - $('.sidebar-result-header').outerHeight() - (parseInt $sidebarResultBody.css('margin-bottom'), 10)

$ ->
  $.material.init()
  sizeSidebarResult()

$(window).resize ->
  sizeSidebarResult()
