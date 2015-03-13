cursorPosition = ''

# values to position the cursor image correctly
# should be half width & height of the cursor image
cursorOffset =
  top: 20
  left: 26.5

getLoadingCursor = ->
  $('.loading-cursor')

positionCursor = ->
  $loadingCursor = getLoadingCursor()
  $loadingCursor.offset
    left: cursorPosition.pageX - cursorOffset.left
    top: cursorPosition.pageY - cursorOffset.top


# Add/Remove Loading Cursor
#
# call Divvy.addLoadingCursor() to initialize the cursor switch
# call Divvy.removeLoadingCursor() once the action is complete
#
Divvy.addLoadingCursor = ->
  $loadingCursor = getLoadingCursor()
  positionCursor()
  $('body').addClass 'loading-cursor-enabled'

Divvy.removeLoadingCursor = ->
  $('body').removeClass 'loading-cursor-enabled'
  $loadingCursor = getLoadingCursor()
  $loadingCursor.removeAttr 'style'

$ ->
  # cursor position is tracked and held throughout the whole app
  $('body').on 'mousemove', (e) ->
    cursorPosition = e

    # positioning of the loading cursor only happens when the cursor is showing
    $loadingCursor = getLoadingCursor()
    if $loadingCursor.is ':visible'
      positionCursor()
