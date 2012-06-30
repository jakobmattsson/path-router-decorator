async = require 'async'

exports.middleware = (page) -> (params) ->
  augmented = 
    callback: (args, done) ->
      mid = params.middleware ? []
      params.callback args, (doneArgs...) ->
        async.forEach mid, (item, callback) ->
          item.callback(args, callback)
        , () ->
          done(doneArgs...)

  page(_.extend({}, params, augmented))



exports.source = (page, resolver) -> (params) ->
  augmented = 
    callback: (args, done) ->
      sources = params.sources ? {}
      Object.keys(sources).forEach (key) ->
        replaced = sources[key].split('/').map (unit) ->
          args[unit.slice(1)] ? unit
        sources[key] = replaced.join('/')

      resolver sources, (data) ->
        mergedArgs = _.extend({}, args, data)
        params.callback(mergedArgs, done)

  page(_.extend({}, params, augmented))



exports.view = (page, conf) ->

  compiledViews = {}

  (params) ->

    return page(params) if !params[conf.viewIdentifier]?

    augmented =
      callback: (args, done) ->
        params.callback args, (mo) ->
          view = params[conf.viewIdentifier]
          compiledViews[view] = conf.compileView(view) if !compiledViews[view]?
          node = conf.render(compiledViews[view], mo)
          done({ html: node })

    page(_.extend({}, params, augmented))



exports.nodeReplacer = (page, conf) -> (params) ->
  return page(params) if !params[conf.nodeIdentifier]?

  augmented =
    callback: (args, done) ->
      params.callback args, (mo) ->
        throw "Returned object must contain an html-attribute" if !mo.html?
        target = document.getElementById params[conf.nodeIdentifier]

        for child in target.children
          target.removeChild(child)

        target.appendChild(mo.html)
        done(arguments...)

  page(_.extend({}, params, augmented))



exports.modalHtml = (page, modal) -> (params) ->
  augmented =
    callback: (args, done) ->

      augArgs =
        callback: (err, data) ->
          modal.close()
          args.callback(err, data) if args.callback?

      allArgs = _.extend({}, args, augArgs)

      params.callback allArgs, (data) ->
        throw "Returned object must contain an html-attribute" if !data.html?
        modal.show(data.html)
        done(arguments...)

  page(_.extend({}, params, augmented))
