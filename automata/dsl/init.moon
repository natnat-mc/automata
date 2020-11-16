import loadstring, to_lua from require 'moonscript.base'
validate = require 'automata.dsl.validate'
odump = require 'automata.dump'
import sub, char, byte, dump, match, gsub from string
import concat from table

combine = (...) ->
	out, outi = {}, 1
	push = (a) -> out[outi], outi = a, outi+1
	for i=1, select '#', ...
		fn = select i, ...
		code, state, symbol = fn!
		push '@pushsymbol '..odump symbol if symbol
		push '@setstate '..odump state if state
		if code
			prefix = match code, '^(%s*)'
			push gsub (sub code, 1+#prefix), '\n'..prefix, '\n'
	code = concat out, '\n'
	-> code

compile = (code) ->
	return nil unless code
	code = (combine code)! if (type code) == 'function'
	prefix = match code, '^(%s*)'
	code = gsub (sub code, #prefix), '\n'..prefix, '\n'
	lua, err = to_lua code, implicitly_return_root: false
	error "Error compiling:\n#{code}\n#{err}" unless lua
	lua

class CharClass
	new: (...) =>
		@chars = {}
		for argi=1, select '#', ...
			arg = select argi, ...
			if (type arg) == 'string'
				@chars[sub arg, i, i] = true for i=1, #arg
			else
				@chars[c] = true for c in pairs arg.chars

	__tostring: =>
		"Class(#{concat [k for k in pairs @chars]})"

CharRange = (...) ->
	argv = select '#', ...
	chars = {}
	for i=1, argv/2
		st = select i*2-1, ...
		ed = select i*2, ...
		stb = byte st
		edb = byte ed
		error "End character is before start character: #{ed}<#{st}: #{edb}<#{stb}" if edb<stb
		chars[char b] = true for b=stb, edb
	CharClass :chars

class State
	new: (@name) =>
		@_enter = nil
		@_exit = nil
		@_matches = {}
		@_default = nil
		@_final = false

	__tostring: =>
		"State(#{@name}#{@_final and ", final" or ""})"

	enter: (fn) =>
		validate 1, 'function', fn
		@_enter = combine fn

	exit: (fn) =>
		validate 1, 'function', fn
		@_exit = combine fn

	on: (match, symbol, fn) =>
		validate 1, CharClass, match
		if (type symbol) == 'function'
			error "Already a match for #{match} in state #{@name}" if @_matches[match]
			code = combine symbol
			@_matches[match] = none: code
		else
			validate 2, (validate.typein 'string', 'table'), symbol
			validate 3, 'function', fn
			@_matches[match] or= {}
			error "Already a match for #{match}, #{symbol} in state #{@name}" if @_matches[match][symbol]
			code = combine fn
			@_matches[match][symbol] = code

	replace: (match, symbol, fn) =>
		validate 1, CharClass, match
		if (type symbol) == 'function'
			error "No match for #{match} in state #{@name}" unless @_matches[match]
			code = combine symbol
			@_matches[match] = none: code
		else
			validate 2, (validate.typein 'string', 'table'), symbol
			validate 3, 'function', fn
			@_matches[match] or= {}
			error "No a match for #{match}, #{symbol} in state #{@name}" unless @_matches[match][symbol]
			code = combine fn
			@_matches[match][symbol] = code

	default: (fn) =>
		error "Already a default match in state #{@name}" if @_default
		code = combine fn
		@_default = code

	final: (val) =>
		if val==nil
			@_final = true
		else
			@_final = val

	extend: (state) =>
		@_enter = state._enter
		@_exit = state._exit
		@_matches = {k1, v1 and {k2, v2 for k2, v2 in pairs v1} for k1, v1 in pairs state._matches}
		@_default = state._default
		@_final = state._final

class DSLEnv
	new: (code) =>
		@classes = {}
		@states = {}
		fn, err = loadstring code
		error err unless fn
		if setfenv
			setfenv fn, @env!
		else
			code = dump fn
			fn = load code, 'syntax', 'b', @env!
		@default = validate 0, State, fn!

	env: =>
		setmetatable {},
			__index: (e, i) ->
				if construct = @['_'..i]
					construct @
				elseif charclass = @classes[i]
					charclass
				elseif state = @states[i]
					state
				elseif global = rawget _G, i
					global
				else
					error "No such construct: #{i}"
			__newindex: (e, i, v) ->
				error "Cannot define construct: #{i} with global assignment"

	summary: =>
		tfn = {}
		for name, state in pairs @states
			tfn[name] = {}
			for matcher, mp in pairs state._matches
				import chars from matcher
				transition = {}
				for stack, action in pairs mp
					transition[stack] = compile action
				for char in pairs chars
					tfn[name][char] = transition
		default = @default.name
		final = [name for name, state in pairs @states when state._final]
		enter = {name, compile state._enter for name, state in pairs @states}
		exit = {name, compile state._exit for name, state in pairs @states}
		star = {name, compile state._default for name, state in pairs @states}
		{ :tfn, :default, :final, :enter, :exit, :star }

	_CharClass: => (name, ...) ->
		validate 1, 'string', name
		validate argi, (validate.typein 'string', CharClass), select argi, ... for argi=1, select '#', ...
		clazz = CharClass ...
		@classes[name] = clazz
		clazz

	_CharRange: => (name, ...) ->
		argc = select '#', ...
		validate 1, 'string', name
		validate argi, {'string', validate.len 1}, select argi, ... for argi=1, argc
		validate argc, { -> argc%2 == 0, "Should get even number of bounds, got #{argc}"}, argc
		clazz = CharRange ...
		@classes[name] = clazz
		clazz

	_State: => (name) ->
		validate 1, 'string', name
		state = State name
		@states[name] = state
		state

	_Combine: => combine
