dump = require 'automata.dump'
import gsub from string
import concat from table

header = [[
return function(input)
	local self = require('automata.stdlib')()
	local f = {}
	local tfn = {}; self.tfn = tfn
	local star = {}; self.star = star
	local enter = {}; self.enter = enter
	local exit = {}; self.exit = exit
]]

footer = [[
	return self:execute(input)
end
]]

collector = (prefix='') ->
	collected = {}
	lastkey = 0
	collected, (str) ->
		if key = collected[str]
			return key
		key = prefix..lastkey
		lastkey += 1
		collected[str] = key
		key

(summary) ->
	-- make a buffer
	out, outi = {}, 0
	push = (...) ->
		n = select '#', ...
		for i=1, n
			out[outi+i] = select i, ...
		outi += n
	
	-- create a function collector
	fns, fncollect = collector 'fn'

	-- create the header, set state and list final states
	push header
	push '\tself.defaultstate = ', (dump summary.default), '\n'
	push '\tself.final = ', (dump summary.final), '\n'
	push '\n'

	-- save the buffer, so that the functions are inserted at the top
	sout, souti = out, outi
	out, outi = {}, 0

	-- add the enter and exit functions
	for state, fn in pairs summary.enter
		push '\tenter[', (dump state), '] = f.', (fncollect fn), '\n'
	for state, fn in pairs summary.exit
		push '\texit[', (dump state), '] = f.', (fncollect fn), '\n'
	push '\n'

	-- add the default functions
	for state, transition in pairs summary.star
		push '\tstar[', (dump state), '] = f.', (fncollect transition), '\n'
	push '\n'

	-- add the transition functions
	for state, rest in pairs summary.tfn
		push '\ttfn[', (dump state), '] = {\n'
		for char, rest in pairs rest
			push '\t\t[', (dump char), '] = {\n'
			for stack, transition in pairs rest
				push '\t\t\t[', (dump stack), '] = f.', (fncollect transition), ',\n'
			push '\t\t},\n'
		push '\t}\n'
	push '\n'

	-- swap buffers
	sout, souti, out, outi = out, outi, sout, souti

	-- add the function themselves
	for v, k in pairs fns
		push '\tf.', k, ' = function()\n'
		push (gsub (gsub v, '\n', '\n\t\t'), '^%s*', '\t\t')
		push '\n\tend\n'
	push '\n'

	-- write the main buffer and footer
	push concat sout, ''
	push footer

	-- and return the code
	concat out, ''
