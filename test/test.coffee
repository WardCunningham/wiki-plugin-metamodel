# build time tests for metamodel plugin
# see http://mochajs.org/

metamodel = require '../client/metamodel'
expect = require 'expect.js'

describe 'metamodel plugin', ->

  describe 'parse', ->

    it 'sees indent', ->
      result = metamodel.parse '[]\n  []'
      expect(result[1].in).to.equal 1

  describe 'run', ->

    it 'reports size of array in array', ->
      data = [['foo','bar']]
      parse = metamodel.parse '[]\n  []'
      result = metamodel.run data, parse
      expect(result[1].hover).to.equal '2 elements'
