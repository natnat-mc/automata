CharClass 'Arith', '+-'
CharClass 'Ptr', '><'
CharClass 'IO', '.,'
CharClass 'LoopSt', '['
CharClass 'LoopEd', ']'

with State 'Brainfuck'
	\enter -> [[ @push {} ]]
	\on Arith, -> [[ @append {ty: 'arith', @char} ]]
	\on Ptr, -> [[ @append {ty: 'ptr', @char} ]]
	\on IO, -> [[ @append {ty: 'io', @char} ]]
	\on LoopSt, ->
		[[
			list = {}
			@append {ty: 'loop', list}
			@push list
		]], nil, 'loop'
	\on LoopEd, 'loop', -> [[ @pop! ]]
	\default -> [[ nil ]]
	\final!

Brainfuck
