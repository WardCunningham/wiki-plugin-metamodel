# build time tests for metamodel plugin
# see http://mochajs.org/

metamodel = require '../client/metamodel'
expect = require 'expect.js'

describe 'metamodel plugin', ->

  describe 'expand', ->

    # it 'can make itallic', ->
    #   result = metamodel.expand 'hello *world*'
    #   expect(result).to.be 'hello <i>world</i>'
