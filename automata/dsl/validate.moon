_type = type
import type from require 'moon'
import concat from table

_validate = (argi, validations, value) ->
	validations = {validations} if (type validations) != 'table' or not validations[1]
	for validation in *validations
		if (type validation) == 'function'
			ok, msg = validation value
			error "Invalid argument #{argi}: #{msg or "doesn't pass validation function"}", 2 unless ok
		elseif (type validation) == 'string' or (type validation) == validation
			t = type value
			error "Invalid argument #{argi}: Is of type #{t}, expected #{validation}", 2 unless t == validation
		else
			error "Invalid validation #{validation} for argument #{argi}"
	value
validate = setmetatable {}, __call: (...) => _validate ...

validate.typein = (...) ->
	types = {...}
	(value) ->
		t = type value
		for ty in *types
			return true if t == ty
		false, "Is of type #{t}, expected one of #{concat [tostring ty for ty in *types]}"

validate.len = (min, max) ->
	if max and min > max
		error "Invalid validation validate.len #{min}, #{max}: max<min"
	if max == min
		max = nil
	(value) ->
		len = #value
		if max
			if len < min or len > max
				false, "Length is #{len}, should be between #{min} and #{max} inclusive"
			else
				true
		else
			if len != min
				false, "Length is #{len}, should be #{min}"
			else
				true

validate
