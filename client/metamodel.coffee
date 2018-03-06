
expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

stringify = (obj) ->
  expand JSON.stringify(obj, null, ' ').replace(/"/g,'')

parse = (text) ->
  steps = []
  for num, line of text.split /\r?\n/
    m = line.match /^( *)(.*)$/
    steps.push
      num: num
      in: m[1].length/2
      line: m[2]
  steps

run = (data, steps) ->
  nodes = {}
  rels = {}

  count = (obj) ->
    obj['count']||=0
    obj['count']++

  spec = (num, data) ->
    return unless steps[num]?
    return steps[num].error = 'out of data' unless data?
    # console.log 'spec: num', num, 'line', steps[num].line, 'data',data
    step = steps[num]
    if step.line.match /^\[ *\] *(.*)$/
      return step.error = "no array here" unless data.length?
      step.hover = "#{data.length} elements"
      for d in data
        spec num+1, d
    else if step.line.match /^\{ *\} *(.*)$/
      step.hover = "hash"
      if m = step.line.match /(NODE|REL) (\w+)/
        reify num, data, m[2]
      else if m = step.line.match /(\w+) (NODE|REL)/
        if data[m[1]]?
          reify num, data, data[m[1]]
      else
        step.error = 'expected NODE or REL'
    else
      step.error = 'want [ ] or { }'

  reify = (num, data, type) ->
    step = steps[num]
    step.node = {type}
    fields num, step.in, step, data
    here = nodes[step.node.type.toUpperCase()] ||= {}
    here[step.node.name] = step.node
    step.hover = "node #{stringify step.node}"

  field = (step, field, data) ->
    if m = field.line.match /^(\w+)$/
      if data[m[1]]?
        eg = step.node[m[1]] = data[m[1]]
        count field
        field.hover = "#{field.count} found, last:\n#{eg}"
    else if m = field.line.match /^(\w+) NAME$/
      if data[m[1]]?
        eg = step.node[m[1]] = data[m[1]]
        count field
        field.hover = "#{field.count} NAME found, last:\n#{eg}"
        step.node.name = eg
    else if m = field.line.match /^(\w+) (=>|<=) NODE (\w+) (\w+)$/
      if data[m[1]]?
        eg = step.node[m[1]] = data[m[1]]
        count field
        out = m[2] == '=>'
        dir = if out then '⇒' else '⇐'
        field.hover = "#{field.count} found, last:\n#{dir} #{m[3]}{#{m[4]}: #{eg}}"
        here = rels[m[1].toUpperCase()] ||= []
        here.push {from: step.node.name, to: eg}
    else
      field.error = 'field too complex'

  fields = (num, indent, step, data) ->
    while (afield = steps[++num])?.in > indent
      if m = afield.line.match /^CASE (\w+) (\w+)$/
        if (eg = data[m[1]])? and eg == m[2]
          count afield
          afield.hover = "#{afield.count} found, last: data #{stringify data}"
          fields num, afield.in, step, data
      else
        field step, steps[num], data

  spec 0, data
  console.log 'nodes', nodes, 'rels', rels
  steps

report = (steps) ->
  lines = []
  for step in steps
    color = if step.error? then '#fcc' else '#eee'
    lines.push """
      <span style='color:#ccc'>#{'| &nbsp; '.repeat step.in}</span>
      <span style='background-color:#{color}' title="#{step.error || step.hover || ''}"> #{step.line}</span>
    """
  lines.join "<br>"

emit = ($item, item) ->
  data = null

  resource = (steps) ->
    source = $item.parents('.page').find('.json:first')
    unless source.length
      steps[0].error = 'page has no json'
    else unless (data = source.data('item')['resource'])?
      steps[0].error = 'json has no data'

  steps = parse item.text
  resource steps
  run data, steps

  $item.append """
    <p style="background-color:#eee;padding:15px;">
      #{report steps}
    </p>
  """

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item

window.plugins.metamodel = {emit, bind} if window?
module.exports = {parse, run} if module?

