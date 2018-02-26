
expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

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
      if m = step.line.match /\b(NODE|REL)\s+(\w+)/
        node = {type:m[2]}
        while (field = steps[++num])?.in > step.in
          if field.line.match /^\w+$/
            if data[field.line]?
              eg = node[field.line] = data[field.line]
              field.count||=0
              field.count++
              field.hover = "#{field.count} found, last:\n#{eg}"
          else
            field.error = 'complex field'
        nodes[node.name] = node
      else
        step.error = 'expected NODE or REL'
    else
      step.error = 'want [ ] or { }'

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

