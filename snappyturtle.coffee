_DEBUG_ = true

MAIN_LOOP = 0

tokenizer = (s) ->
  s = s.trim()
  s = s.toUpperCase()
  r = s.match(/[A-Z0-9\-]+/g)
  return r

rand = (min = 0, max = 255) -> 
  Math.floor(Math.random() * (max - min + 1)) + min
#vector calc stuff
Point = {}

#SVG
S = {}

DEFAULT_TURTLE = 
  _old_x: 49
  _old_y: 50
  _x: 50
  _y: 50
  _next_r: 0
  _step: 100
  stroke: '#000'
  fill: '#000'
  strokeWidth: 2
  _visible: true

MyTu  = _.clone(DEFAULT_TURTLE)

_T_U_R_T_L_E_I_C_O_N_ = false 
drawTurtle = (turtle, svg = S) -> 
  x = turtle._x
  y = turtle._y
  if _T_U_R_T_L_E_I_C_O_N_
    _T_U_R_T_L_E_I_C_O_N_.remove()

  if turtle._visible is false then return false
  
  _T_U_R_T_L_E_I_C_O_N_ = S.group(
    S.circle(x,y-10,4).attr({fill:'lightgreen'})
    S.circle(x+6,y-4,3).attr({fill:'lightgreen'})
    S.circle(x-6,y-4,3).attr({fill:'lightgreen'})
    S.circle(x+6,y+4,3).attr({fill:'lightgreen'})
    S.circle(x-4,y+4,3).attr({fill:'lightgreen'})
    S.circle(x,y,8).attr({fill:'green'})
  )
  _T_U_R_T_L_E_I_C_O_N_.attr({'opacity':0.8})
  r = 90+Snap.angle(x,y, turtle._old_x, turtle._old_y)
  _T_U_R_T_L_E_I_C_O_N_.attr({'transform': 'rotate('+r+', '+x+','+y+')'})
  return true



calc = (turtle, length = 0, rotate_degrees = null, update = true) ->
  vector = new Point( turtle._x - turtle._old_x, turtle._y - turtle._old_y)
  vector.normalize()
  if length isnt 0
    vector.length = length

  rotate_degrees = rotate_degrees or turtle._next_r
  if rotate_degrees isnt 0
    vector.angle = vector.angle + rotate_degrees

  turtle._next_r = 0 
  new_x = turtle._x + vector.x
  new_y = turtle._y + vector.y

  return [new_x, new_y]

updateTurtle = (turtle, x, y) ->
  turtle._old_y = turtle._y
  turtle._old_x = turtle._x
  turtle._x = x
  turtle._y = y
  drawTurtle(turtle)
  return turtle

dlog = (msg, debug = _DEBUG_ ) -> 
  if debug then console.log(msg)
  return msg
error = (msg) -> console.log('ERROR' + msg)

F =
  "SET": (args, tokens) -> set(MyTu, args); return tokens
  "GO": (args, tokens) -> go(MyTu, args); return tokens
  "JUMP": (args, tokens) -> jump(MyTu, args); return tokens
  "LEFT": (args, tokens) -> MyTu._next_r = MyTu._next_r + args[0]*-1; return tokens
  "RIGHT": (args, tokens) -> MyTu._next_r = MyTu._next_r + args[0]; return tokens
  "COLOR": (args, tokens) -> color(MyTu, args); return tokens
  "POINT": (args, tokens) -> point(MyTu, args); return tokens
  "REPEAT": (args, tokens) -> repeat(args, tokens) #function returns tokens
  "STEP": (args, tokens) -> step(MyTu, args); return tokens
  "MAKE": (args, tokens) -> make(args, tokens) # function returns tokens
  "LOOP": (args, tokens) -> error('repeat/loop end without start'); return tokens #do nothing as there is no loop-start
  "MAKEEND": (args, tokens) -> error('makeend without start'); return tokens
  "RESET": (args, tokens) -> reset(MyTu, args); return tokens
  "CLEAN": (args, tokens) -> clean(MyTu, args); return tokens
  "HIDE": (args, tokens) -> MyTu._visible = false; return tokens
  "SHOW": (args, tokens) -> MyTu._visible = true; return tokens
  "TOGGLE": (args, tokens) -> MyTu._visible = !MyTu._visible; return tokens

clean = (turtle, args) ->
  S.clear()
  return turtle

reset = (turtle, args) ->
  clean()
  turtle = MyTu = _.clone(DEFAULT_TURTLE)
  return turtle

step = (turtle, args) ->
  if args[0]
    turtle._step = args[0]
  return turtle

collectTokens = (tokens, start, end) ->
  nested = 1
  collected_tokens = []
  cloned_tokens = tokens.slice(0)
  for t in tokens
    if t is start
      nested = nested + 1
    else if t is end
      nested = nested - 1
      if nested is 0
        return collected_tokens
    collected_tokens.push(cloned_tokens.shift())
  error(start+' without a '+end)
  return tokens

make = (args, tokens) ->
  if not args[0] then return tokens
  tokens_clone = tokens.slice(0)
  collected_tokens = collectTokens(tokens, 'MAKE', 'END')
  #dlog(tokens_clone)
  tokens_clone = tokens_clone.slice(collected_tokens.length+1)
  #dlog(tokens_clone)
  for t,i in tokens_clone
    if t is args[0]
      tokens_clone[i] = collected_tokens
  _.flatten(tokens_clone)
  
repeat = (args, tokens) ->
  if not args[0] then return tokens
  tokens_clone = tokens.slice(0)
  collected_tokens = collectTokens(tokens, 'REPEAT', 'LOOP')
  tokens_clone = tokens_clone.slice(collected_tokens.length+1)
  for i in [0 ... args[0]]
    tokens_clone.unshift(collected_tokens)
  _.flatten(tokens_clone)


set = (turtle, args) ->
  temp_x = args[0] ? turtle._x
  temp_y = args[1] ? turtle._y
  turtle._old_x = temp_x - (turtle._x - turtle._old_x)
  turtle._old_y = temp_y - (turtle._y - turtle._old_y)  
  turtle._x = temp_x
  turtle._y = temp_y 
  return turtle

lengthparser = (args) ->
  if args.length is 0 then return false

  if args.length is 1
    le = parseInt(args[0])

  if args.length > 1
    le = rand(parseInt(args[0]), parseInt(args[1]))

  return le

go = (turtle, args) ->
  le = lengthparser(args)
  if le is false then return false

  [new_x, new_y] = calc(turtle, le)
  l = S.line(turtle._x, turtle._y, new_x, new_y).attr(turtle)
  updateTurtle(turtle, new_x, new_y)

jump = (turtle, args) ->
  le = lengthparser(args)
  if le is false then return false
  
  [new_x, new_y] = calc(turtle, args[0])
  updateTurtle(turtle, new_x, new_y)

color = (turtle, args) ->
  if args.length >= 3
    turtle.stroke = turtle.fill = 'rgb('+args[0]+','+args[1]+','+args[3]+')'
  else
    if args[0] is 'BUNT'
      turtle.stroke = turtle.fill = 'rgb('+rand()+','+rand()+','+rand()+')'
    else
      turtle.stroke = turtle.fill = args[0]
  return turtle

point = (turtle, args) ->
  d = args[0] ? 5
  S.circle(turtle._x, turtle._y, d).attr(turtle)

type_it = (x) ->
  if (xi = parseInt(x))+'' is x
    return xi
  else
    return x

preparser = () -> console.log('preparser')

execute_loop = (tokens) ->
  t = tokens.shift()
  args = []
  if (e = F[t])
    tokens_clone = tokens.slice(0)
    for x in tokens_clone
      if not F[x]
        args.push(type_it(tokens.shift()))
      else
        break
    tokens = e(args, tokens)

  if tokens.length > 0
    MAIN_LOOP =  Meteor.setTimeout((->execute_loop(tokens)), MyTu._step)


if Meteor.isClient
  Point = window.paper.Point
  editor = {}

  getAndExecute = () ->
    Meteor.clearTimeout(MAIN_LOOP)
    Session.set('code', editor.getValue())
    tokens = tokenizer(Session.get('code'))
    execute_loop(tokens)

  keypress.combo('meta r', (e) ->
    e.preventDefault()
    getAndExecute()
  )

  svg_render_count = 0 
  Template.svgworld.rendered = () ->
      if svg_render_count is 0
        S = Snap('#svg')
      svg_render_count = svg_render_count + 1

  editor_render_count = 0
  Template.editor.rendered = () ->
    if editor_render_count is 0
      editor = ace.edit("editor")
      getAndExecute()
    editor_render_count = editor_render_count + 1






