if has('win32') || has ('win64')
    let $VIMHOME = $VIM."/vimfiles"
else
    let $VIMHOME = $HOME."/.vim"
endif

if !exists('g:storagvim_map_keys')
	let g:storagvim_map_keys = 1
endif

if !exists('g:storagvim_crlf')
	let g:storagvim_crlf = '\n' 
endif

if !exists('g:storagvim_escape')
	let g:storagvim_escape = 0
endif

if !exists('g:storagvim_max_command_buffer')
	let g:storagvim_max_command_buffer = 5000
endif

function! storagvim:executeWithGlobalInformation()
	let text = join(storagvim:getText(getpos("'<"), getpos("'>")), g:storagvim_crlf)

	if text[0:5] ==? 'select' || text[0:5] ==? 'insert' || text[0:5] ==? 'update'
		silent call storagvim:executeQuery(text)
	else
		call storagvim:requireInformation()
		silent call storagvim:updateColumn(g:table, g:column, g:where)	
	endif

endfunction

function! storagvim:updateColumn(table, column, where)
	let text = storagvim:getText(getpos("'<"), getpos("'>"))
	if(g:storagvim_escape == 1)
		let text = substitute(text, "'", "''", "g") 
	endif

	let joined = join(text, g:storagvim_crlf)
	let mb = g:storagvim_max_command_buffer
	let parts = strlen(joined) / mb

	if parts == 0
		call storagvim:executeQuery("UPDATE " . g:table . " SET " . g:column . " = '". joined . "' WHERE " . g:where)
	else
		call storagvim:executeQuery("UPDATE " . g:table . " SET " . g:column . " = '". strpart(joined, 0, mb) . "' WHERE " . g:where)
		let i = 1
		while i < parts + 1
			let start = mb*i
			call storagvim:executeQuery("UPDATE " . g:table . " SET " 
\				. g:column . " = CONCAT(" . g:column . ", '". strpart(joined, start, mb) 
\				. "') WHERE " . g:where)
			let i += 1
		endwhile
	endif

endfunction

function! storagvim:getText(s, e)
	let texts = getline(a:s[1], a:e[1])
	let texts[0] = texts[0][a:s[2]-1:]
	let texts[-1] = texts[-1][0:a:e[2]-1]
	return texts
endfunction

function! storagvim:executeQuery(query)
	let q = escape(a:query, '"!#')
	:execute '!java -jar ' . $VIMHOME . '/sgvim.jar "' . q . '"'
endfunction

function! storagvim:selectFromGlobalTable()
	call storagvim:requireInformation()
	:call storagvim:executeQuery('SELECT * FROM ' . g:table)
endfunction

function! storagvim:saveAndUpdate()
	call storagvim:requireInformation()
	let lastLine = line('$')
	call setpos('.', [0, lastLine, 1, 0])
	let lastCol = col('$')
	let text = storagvim:getText([0, 1, 1, 0], [0, lastLine, lastCol, 0])

	if(g:storagvim_escape == 1)
		let text = substitute(text, "'", "''", "g") 
	endif

	let joined = join(text, g:storagvim_crlf)
	let mb = g:storagvim_max_command_buffer
	let parts = strlen(joined) / mb

	if parts == 0
		call storagvim:executeQuery("UPDATE " . g:table . " SET " . g:column . " = '". joined . "' WHERE " . g:where)
	else
		call storagvim:executeQuery("UPDATE " . g:table . " SET " . g:column . " = '". strpart(joined, 0, mb) . "' WHERE " . g:where)
		let i = 1
		while i < parts + 1
			let start = mb*i
			call storagvim:executeQuery("UPDATE " . g:table . " SET " 
\				. g:column . " = CONCAT(" . g:column . ", '". strpart(joined, start, mb) 
\				. "') WHERE " . g:where)
			let i += 1
		endwhile
	endif

	write
	echo 'saved'
endfunction

function! storagvim:requireInformation()
	if !exists('g:table')
		let g:table = input('Table: ')
	endif

	if !exists('g:column')
		let g:column = input('Column: ')
	endif

	if !exists('g:where')
		let g:where = input('Where: ')
	endif
endfunction

if g:storagvim_map_keys == 1
	nnoremap <F5> :call storagvim:selectFromGlobalTable()<CR>
	vnoremap <F5> :call storagvim:executeWithGlobalInformation()<CR>
	cnoremap _w call storagvim:saveAndUpdate()
endif
