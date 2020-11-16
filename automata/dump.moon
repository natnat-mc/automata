import concat, sort from table
import gsub from string

(obj, indent='', indentchar = '\t') ->
	tab, i = {}, 1
	p = (s) -> tab[i], i = s, i+1
	imp = (obj, indent) ->
		switch type obj
			when 'string'
				p '"'
				for pair in *({{'\\', '\\\\'}, {'\n', '\\n'}, {'\r', '\\r'}, {'\t', '\\t'}, {'\"', '\\"'}})
					obj = gsub obj, pair[1], pair[2]
				p obj
				p '"'

			when 'table'
				keys, ki = {}, 1
				istable = true
				issmall = true
				allstr = true
				for k, v in pairs obj
					keys[ki], ki = k, ki+1
					istable = false if (type k) != 'number'
					allstr = false if (type k) != 'string'
					issmall = false if issmall and (type v) != 'number' and ( (type v) != 'string' or #v>10 )
					issmall = false if ki == 11
				sort keys if allstr or istable
				nindent = issmall and '' or indent..indentchar

				p '{'
				unless issmall
					p '\n'
					p nindent
				for i, k in ipairs keys
					unless istable
						p '['
						imp k, ''
						p '] = '
					imp obj[k], nindent
					p ',' if i != ki-1
					if issmall
						p ' ' if i != ki-1
					else
						p '\n'
						p nindent if i != ki-1
				unless issmall
					p indent
				p '}'

			when 'number'
				p tostring obj

			when 'nil'
				p 'nil'

			when 'boolean'
				p tostring obj

			else
				error "Cannot dump #{type obj}"

	imp obj, indent
	concat tab, ''


