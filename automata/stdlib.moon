import insert from table
import sub from string

->
	-- build the lib and set defaults
	@ =
		char: nil
		state: nil
		pos: 0
		tfn: {}
		enter: {}
		exit: {}
		star: {}
		final: {}

	-- output stack
	@outstack, @outstacktop = {}, 0

	@push = (obj) =>
		@outstacktop += 1
		@outstack[@outstacktop] = obj

	@append = (obj) =>
		insert @top!, obj

	@pop = =>
		@fail "Nothing on the output stack" if @outstacktop == 0
		obj = @outstack[@outstacktop]
		@outstack[@outstacktop] = nil
		@outstacktop -= 1
		obj
	
	@top = =>
		@fail "Nothing on the output stack" if @outstacktop == 0
		@outstack[@outstacktop]

	-- symbol stack
	@symbolstack, @symbolstacktop = {}, 0

	@pushsymbol = (sym) =>
		@symbolstacktop += 1
		@symbolstack[@symbolstacktop] = sym

	@popsymbol = =>
		@fail "Nothing on the symbol stack" if @symbolstacktop == 0
		sym = @symbolstack[@symbolstacktop]
		@symbolstack[@symbolstacktop] = nil
		@symbolstacktop -= 1
		sym

	@topsymbol = =>
		@symbolstack[@symbolstacktop]

	-- state stack
	@statestack, @statestacktop = {}, 0

	@pushstate = (state=@state) =>
		@statestacktop += 1
		@statestack[@statestacktop] = state

	@setstate = (newstate) =>
		oldstate = @state
		@oldstate, @newstate = oldstate, newstate
		changes = oldstate != newstate
		if fn = changes and @exit[oldstate]
			fn @
		@state = newstate
		if fn = changes and @enter[newstate]
			fn @
		@oldstate, @newstate = nil, nil

	@popstate = =>
		@fail "Nothing on the state stack" if @statestacktop == 0
		newstate = @statestack[@statestacktop]
		@statestack[@statestacktop] = nil
		@statestacktop -= 1
		@setstate newstate

	-- other stuff
	@fail = (msg="Unspecified error") =>
		error "In state #{@state}, at pos #{@pos}: #{msg}"

	-- execute the whole thing
	@execute = (input) =>
		@setstate @defaultstate

		len = #input
		for i=1, len
			char = sub input, i, i
			import state from @
			@char = char
			@pos = i

			--io.write "#{string.char 0x1b}[2J#{string.char 0x1b}[1;1H"
			print "#{@pos}: (#{@state}, #{(require 'automata.dump') @char}, #{@topsymbol!}) #{@outstacktop} out, #{@symbolstacktop} symbols, #{@statestacktop} states"

			matched = false
			if forstate = @tfn[state]
				if forchar = forstate[char]
					if fn = forchar.none
						fn @
						matched = true
					elseif fn = forchar[@topsymbol!]
						@popsymbol!
						fn @
						matched = true
					elseif next forchar
						@fail "No match for triple (#{state}, #{char}, #{@topsymbol!}): wrong symbol on stack"
			else
				@fail "No known state #{state}"
			if fn = (not matched) and @star[state]
				fn @
				matched = true
			@fail "No match for triple (#{state}, #{char}, #{@topsymbol!}): no match and no default" unless matched

			--print (require 'automata.dump') @outstack
			--io.read!

		finalstate = @state
		@setstate nil

		@fail "Finished with #{@symbolstacktop} symbols on the stack" if @symbolstacktop != 0
		@fail "Finished with #{@statestacktop} states on the stack" if @statestacktop != 0

		for state in *@final
			return @outstack if state==finalstate
		@fail "Finished in non-final state #{finalstate}"

	-- return the lib
	@
