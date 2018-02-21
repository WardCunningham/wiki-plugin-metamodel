
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
  console.log 'steps',steps
  steps

run = ($item, steps) ->
  nodes = {}
  rels = {}

  spec = (num,data) ->
    return unless data?
    step = steps[num]
    if step.line.match /^\[ *\] *(.*)$/
      return step.error = "no array here" unless data.length?
      step.hover = "#{data.length} elements"
      for d in data
        spec num+1, d
    else if step.line.match /^\{ *\} *(.*)$/
      step.hover = "hash"
      while true
        num += 1
        return unless steps[num]?.in > step.in
        spec num, data
    else
      step.error = 'want [ ] or { }'

  source = $item.parents('.page').find('.json:first')
  unless source.length
    steps[0].error = 'page has no json'
  else unless (data = source.data('item')['resource'])?
    steps[0].error = 'json has no data'
  else
    spec 0, data

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
  $item.append """
    <p style="background-color:#eee;padding:15px;">
      #{report run $item, parse item.text}
    </p>
  """

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item

window.plugins.metamodel = {emit, bind} if window?
module.exports = {expand} if module?

