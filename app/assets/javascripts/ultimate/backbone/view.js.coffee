#  * Require ./../underscore/underscore.outcasts
#  * Require ./../underscore/underscore.string
#= require ./base

class Ultimate.Backbone.View extends Backbone.View

  loadingState: null
  loadingWidthMethodName: "innerWidth"
  loadingHeightMethodName: "innerHeight"
  loadingStateClass: "loading"
  loadingOverlayClass: "loading-overlay"

  viewOptions: -> []

  constructor: ->
    Ultimate.Backbone.debug ".View.constructor()", @
    super



  # Overload parent method Backbone.View.setElement() as hook for findNodes() and trick for data("views").
  setElement: (element, delegate, sideCall = false) ->
    if @$el?.length and not sideCall
      views = @$el.data("views")
      for view in views  when view isnt @
        view.setElement element, delegate, true
      @$el.data("views", [])
    super
    if @$el.length
      if views = @$el.data("views")
        views.push @
      else
        @$el.data "views", [@]
    @findNodes()
    @

  findNodes: (jRoot = @$el, nodes = @nodes) ->
    jNodes = {}
    nodes = if _.isFunction(nodes) then @nodes.call(@) else _.clone(nodes)
    if _.isObject(nodes)
      for nodeName, selector of nodes
        _isObject = _.isObject(selector)
        if _isObject
          nestedNodes = selector
          selector = _.outcasts.delete(nestedNodes, "selector")
        jNodes[nodeName] = @[nodeName] = jRoot.find(selector)
        if _isObject
          _.extend jNodes, @findNodes(jNodes[nodeName], nestedNodes)
    jNodes



  # Overload and proxy parent method Backbone.View.delegateEvents() as hook for normalizeEvents().
  delegateEvents: (events) ->
    args = _.toArray(arguments)
    args[0] = @normalizeEvents(events)
    super args...

  # Cached regex to split keys for `delegate`, from backbone.js.
  delegateEventSplitter = /^(\S+)\s*(.*)$/

  normalizeEvents: (events) ->
    events = _.result(@, "events")  unless events
    if events
      normalizedEvents = {}
      for key, method of events
        [[], eventName, selector] = key.match(delegateEventSplitter)
        selector = _.result(@, selector)
        selector = selector.selector  if selector instanceof jQuery
        if _.isString(selector)
          selector = selector.replace(@$el.selector, '')  if _.string.startsWith(selector, @$el.selector)
          key = "#{eventName} #{selector}"
        normalizedEvents[key] = method
      events = normalizedEvents
    events



  # Overload parent method Backbone.View._configure() as hook for reflectOptions().
  _configure: (options) ->
    super
    @reflectOptions()

  reflectOptions: (viewOptions = _.result(@, "viewOptions"), options = @options) ->
    @[attr] = options[attr]  for attr in viewOptions  when typeof options[attr] isnt "undefined"
    @[attr] = value  for attr, value of options  when typeof @[attr] isnt "undefined"
    @

  # Overloadable getter for jQuery-container that will be blocked.
  getJLoadingContainer: -> @$el

  loading: (state, text = "", circle = false) ->
    jLoadingContainer = @getJLoadingContainer()
    if jLoadingContainer?.length
      jLoadingContainer.removeClass @loadingStateClass
      jLoadingContainer.children(".#{@loadingOverlayClass}").remove()
      if @loadingState = state
        jLoadingContainer.addClass @loadingStateClass
        style = []
        if @loadingWidthMethodName
          style.push "width: #{jLoadingContainer[@loadingWidthMethodName]()}px;"
        if @loadingHeightMethodName
          height = jLoadingContainer[@loadingHeightMethodName]()
          style.push "height: #{height}px; line-height: #{height}px;"
        text = if text then "<span class=\"text\">#{text}</span>" else ''
        circle = if circle then "<span class=\"circle\"></span>" else ''
        jLoadingContainer.append "<div class=\"#{@loadingOverlayClass}\" style=\"#{style.join(' ')}\">#{circle}#{text}</div>"



  # Improve templating.
  jst: (name, context = @) ->
    JST["backbone/templates/#{name}"] context
