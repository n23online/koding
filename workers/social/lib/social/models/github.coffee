{ Base, signature } = require 'bongo'

{ argv }  = require 'optimist'
GithubAPI = require 'github'
KONFIG    = require('koding-config-manager').load("main.#{argv.c}")


module.exports = class Github extends Base

  OAUTH_PROVIDER = 'github'
  USER_AGENT     = 'Koding-Bridge'

  @trait __dirname, '../traits/protected'

  { revive } = require './computeproviders/computeutils'
  { permit } = require './group/permissionset'

  @share()

  @set
    permissions           :
      'api access'        : ['member','moderator']

    sharedMethods         :
      static              :
        api               :
          (signature Object, Function)


  ###*
   * Inline hepler to initialize GithubAPI instance for provided `client`
   *
   * @param  {Object} client - Revived client object which includes required
   *                           oauth info in `client.r.oauth.token`
   * @return {Object}        - GithubAPI instance
  ###
  initGithubFor = (client) ->

    { oauth: {token} } = client.r

    gh = new GithubAPI
      version        : '3.0.0'
      debug          : true
      timeout        : 5000
      headers        :
        'user-agent' : USER_AGENT

    gh.authenticate { type: 'oauth', token }

    return gh


  ###*
   * Provides a bridge between node-gitub api with Koding client
   * In the revive it checks and verifies the oauth requirements
   * for provided `OAUTH_PROVIDER`. If fails it will return callback
   * with missing oauth error.
   *
   * _param {Object} client     - this will be injected
   * @param {Object} _options   - includes `method` and `options`
   *                          	 	method will consist of `base.method` string
   *                             	api: http://mikedeboer.github.io/node-github/
   * @param {Function} callback - function to call when the request is
   *                            	finished with an error as first argument
   *                            	and result data as second argument.
  ###
  @api = permit 'api access', success: revive

    shouldReviveProvider : no
    shouldHaveOauth      : OAUTH_PROVIDER

  , (client, _options, callback) ->

    cbErr = (message) -> callback {
      message: message or 'Insufficient parameters provided'
    }

    # Make sure all required parameteres provided
    { method, options } = _options
    return cbErr()  if not method

    [ base, method ]    = method.split '.'
    return cbErr()  if not base or not method

    # Callback wrapper to add some more
    # functionality to default callback
    cb = (err, response) ->

      if err and err.toJSON?

        err = err.toJSON()

        # Unifying error object, original Error object includes
        # err.message as another object but stringified, so we are
        # making it ready for the client side here. If anything
        # goes wrong it will be send to client as is
        try
          err.details = JSON.parse err.message
          err.message = err.details.message
          delete err.details.message

      callback err, response

    # FIXME Forcing `per_page` option to max 10
    # because of max_call_stack_size issue in Bongo
    # Requires extensive debugging on Bongo.Base ~ GG
    (options ?= {}).per_page = 10

    # Initialize Github api with client object
    # client object includes required token
    gh = initGithubFor client

    # Make sure provided base and method exists
    unless gh[base]?[method]?
      return cbErr "No such base:'#{base}' or method:'#{method}'"

    try
      # TODO We can add a whitelist of accepted methods/bases
      # and check them before we try to execute them ~ CS, GG
      gh[base][method] options, cb
    catch err
      cb err
