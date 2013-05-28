# TODO: refactor this ugliness

module.exports = class FetchAllActivityParallel
  _              = require "underscore"
  async          = require "async"
  Graph          = require "./graph"
  GraphDecorator = require "./graphdecorator"

  constructor:(requestOptions)->
    {startDate, neo4j, group} = requestOptions

    @graph = new Graph {config : neo4j}
    @startDate            = startDate
    @group                = group
    @randomIdToOriginal   = {}
    @usedIds              = {}
    @cacheObjects         = {}
    @overviewObjects      = []
    @newMemberBucketIndex = null

  get:(callback)->
    methods = [@fetchSingles, @fetchTagFollows, @fetchMemberFollows, @fetchInstalls, @fetchNewMembers]
    holder = []
    boundMethods = holder.push method.bind this for method in methods
    async.parallel holder, (err, results)=>
      callback @decorateAll(err, results)

  fetchSingles:(callback)->
    @graph.fetchAll @group, @startDate, (err, rawResponse=[])->
      GraphDecorator.decorateSingles rawResponse, (decoratedResponse)->
        callback err, decoratedResponse

  fetchTagFollows: (callback)->
    @graph.fetchTagFollows @group, @startDate, (err, rawResponse=[])->
      GraphDecorator.decorateFollows rawResponse, (decoratedResponse)->
        callback err, decoratedResponse

  fetchMemberFollows: (callback)->
    @graph.fetchMemberFollows @group, @startDate, (err, rawResponse=[])->
      GraphDecorator.decorateFollows rawResponse, (decoratedResponse)->
        callback err, decoratedResponse

  fetchInstalls: (callback)->
    @graph.fetchNewInstalledApps @group, @startDate, (err, rawResponse=[])->
      GraphDecorator.decorateInstalls rawResponse, (decoratedResponse)->
        callback err, decoratedResponse

  fetchNewMembers: (callback)->
    @graph.fetchNewMembers @group, @startDate, (err, rawResponse=[])->
      GraphDecorator.decorateMembers rawResponse, (decoratedResponse)->
        callback err, decoratedResponse

  bucketNames:->
    return {
      "CFollowerBucketActivity"  : true
      "CInstallerBucketActivity" : true
      "CNewMemberBucketActivity" : true
    }

  decorateAll: (err, decoratedObjects)->
    for objects in decoratedObjects
      for key, value of objects when key isnt "overview"
        randomId = @generateUniqueRandomKey()
        @randomIdToOriginal[key] = randomId
        value._id = randomId

        if @bucketNames()[value.type]
          oldSnapshot = JSON.parse(value.snapshot)
          oldSnapshot._id = randomId
          value.snapshot = JSON.stringify oldSnapshot

        @cacheObjects[randomId] = value

      for activity in objects.overview
        ids = []
        for originalId in activity.ids
          ids.push @randomIdToOriginal[originalId]

        activity.ids = ids

      @overviewObjects.push objects.overview

    overview = _.flatten @overviewObjects

    return {}  if overview.length is 0


    # TODO: we're throwing away results if more than 20, ideally we'll only
    # get the right number of results
    overview = overview[-20..overview.length]

    overview = _.sortBy(overview, (activity)-> activity.createdAt.first)
    allTimes = _.map(overview, (activity)-> activity.createdAt)
    allTimes = _.flatten allTimes
    sortedAllTimes = _.sortBy(allTimes, (activity)-> activity)

    for activity, index in overview when activity.type is "CNewMemberBucketActivity"
      @newMemberBucketIndex = index

    return @decorateResponse overview, sortedAllTimes

  decorateResponse: (overview, sortedAllTimes)->
    response            = {}
    response.activities = @cacheObjects
    response.overview   = overview
    response._id        = "1"
    response.isFull     = true
    response.from       = sortedAllTimes.first
    response.to         = sortedAllTimes.last
    response.newMemberBucketIndex = @newMemberBucketIndex  if @newMemberBucketIndex

    return response

  generateUniqueRandomKey: ->
    randomId = Math.floor(Math.random()*1000)
    if @usedIds[randomId]
      @generateUniqueRandomKey()
    else
      @usedIds[randomId] = true
      return randomId
