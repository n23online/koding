
jraphical       = require 'jraphical'
JCredentialData = require './credentialdata'
JName           = require '../name'
JUser           = require '../user'
JGroup          = require '../group'

module.exports = class JCredential extends jraphical.Module

  KodingError        = require '../../error'

  {secure, ObjectId, signature, daisy} = require 'bongo'
  {Relationship}     = jraphical
  {permit}           = require '../group/permissionset'
  Validators         = require '../group/validators'

  @trait __dirname, '../../traits/protected'

  @share()

  @set

    softDelete        : yes

    permissions       :
      'create credential' : ['member']
      'update credential' : ['member']
      'list credentials'  : ['member']
      'delete credential' : ['member']

    sharedMethods     :
      static          :
        one           :
          (signature String, Function)
        create        :
          (signature Object, Function)
        some          : [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
      instance        :
        delete        :
          (signature Function)
        shareWith     :
          (signature Object, Function)
        fetchUsers    :
          (signature Function)
        # update        :
        #   (signature Object, Function)
        fetchData     :
          (signature Function)

    sharedEvents      :
      static          : [ ]
      instance        : [
        { name : 'updateInstance' }
      ]

    indexes           :
      publicKey       : 'unique'

    schema            :

      vendor          :
        type          : String
        required      : yes

      title           :
        type          : String
        required      : yes

      publicKey       :
        type          : String
        required      : yes

    relationships     :

      data            :
        targetType    : "JCredentialData"
        as            : "data"

  failed = (err, callback, rest...)->
    return false  unless err

    if rest
      obj.remove?()  for obj in rest

    callback err
    return true


  @create = permit 'create credential',

    success: (client, data, callback)->

      {delegate} = client.connection
      {vendor, title, meta} = data

      credData = new JCredentialData { meta }
      credData.save (err)->
        return  if failed err, callback

        {publicKey} = credData
        credential = new JCredential { vendor, title, publicKey }

        credential.save (err)->
          return  if failed err, callback, credData

          delegate.addCredential credential, as: "owner", (err)->
            return  if failed err, callback, credential, credData

            credential.addData credData, (err)->
              return  if failed err, callback, credential, credData
              callback null, credential


  @one$: permit 'list credentials',

    success: (client, publicKey, callback)->

      options  = { limit : 1 }
      selector = { publicKey }

      {delegate} = client.connection
      delegate.fetchCredentials {},
        targetOptions : {
          selector, options
        }, (err, res = [])->
          callback err, res[0]


  @some$: permit 'list credentials',

    success: (client, selector, options, callback)->

      [options, callback] = [callback, options]  unless callback
      options ?= { limit : 10 }

      {delegate} = client.connection
      delegate.fetchCredentials {},
        targetOptions : {
          selector, options
        }, callback

  fetchUsers: permit

    advanced: [
      { permission: 'update credential', validateWith: Validators.own }
    ]

    success: (client, callback)->

      Relationship.someData targetId : @getId(), {
        as:1, sourceId:1, sourceName:1
      }, (err, cursor)->

        return callback err  if err?

        cursor.toArray (err, arr)->
          return callback err  if err?

          if arr.length > 0
            callback null, ({
              constructorName : u.sourceName
              _id : u.sourceId
              as  : u.as
            } for u in arr)
          else
            callback null, []

  # .share can be used like this:
  #
  # JCredentialInstance.share { user: yes, owner: no, target: "gokmen"}, cb
  #                                      group or user slug -> ^^^^^^

  shareWith: permit

    advanced: [
      { permission: 'update credential', validateWith: Validators.own }
    ]

    success: (client, options, callback)->

      {target, user, owner} = options
      user ?= yes

      setPermissionFor = (target, callback)=>

        Relationship.remove {
          targetId : @getId()
          sourceId : target.getId()
        }, (err)=>

          if user
            as = if owner then 'owner' else 'user'
            target.addCredential this, { as }, (err)-> callback err
          else
            callback err

      JName.fetchModels target, (err, result)=>

        if err or not result
          return callback new KodingError "Target not found."

        { models } = result
        [ target ] = models

        if target instanceof JUser
          target.fetchOwnAccount (err, account)=>
            if err or not account
              return callback new KodingError "Failed to fetch account."
            setPermissionFor account, callback

        else if target instanceof JGroup
          setPermissionFor target, callback

        else
          callback new KodingError "Target does not support credentials."

  delete: permit

    advanced: [
      { permission: 'delete credential', validateWith: Validators.own }
    ]

    success: (client, callback)->

      @fetchData (err, credentialData) =>
        return callback err  if err
        credentialData.remove (err) =>
          return callback err  if err
          @remove callback

  fetchData$: permit

    advanced: [
      { permission: 'update credential', validateWith: Validators.own }
    ]

    success: (client, callback)->

      @fetchData callback

