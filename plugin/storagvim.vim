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

if !exists('g:table')
	:echo 'Remember to configure g:table to use storagvim:updateWithGlobalInformation'
endif

if !exists('g:column')
	:echo 'Remember to configure g:column to use storagvim:updateWithGlobalInformation'
endif

if !exists('g:where')
	:echo 'Remember to configure g:where to use storagvim:updateWithGlobalInformation'
endif

function! storagvim:updateWithGlobalInformation()
	:call storagvim:updateColumn(g:table, g:column, g:where)	
endfunction

function! storagvim:updateColumn(table, column, where)
	let text = storagvim:getText(getpos("'<"), getpos("'>"))
	if(g:storagvim_escape == 1)
		let text = substitute(text, "'", "''", "g") 
	endif

	:call storagvim:executeQuery("UPDATE " . a:table . " SET " . a:column . " = '". join(text, g:storagvim_crlf) . "' WHERE " . a:where)
endfunction

function! storagvim:getText(s, e)
	let texts = getline(a:s[1], a:e[1])
	let texts[0] = texts[0][a:s[2]-1:]
	let texts[-1] = texts[-1][0:a:e[2]-1]
	return texts
endfunction

function! storagvim:executeQuery(query)
	:silent execute '!java -jar ' . $VIMHOME . '/sgvim.jar "' . a:query . '"'
endfunction

function! storagvim:selectFromGlobalTable()
	:call storagvim:executeQuery('SELECT * FROM ' . g:table)
endfunction

function! storagvim:saveAndUpdate()
	let lastLine = line('$')
	setpos('.', [0, lastLine, 1, 0])
	let lastCol = getpos('.')
	let text = storagvim:getText([0, 1, 1, 0], [0, lastLine, lastCol, 0])

	if(g:storagvim_escape == 1)
		let text = substitute(text, "'", "''", "g") 
	endif
	call storagvim:executeQuery("UPDATE " . g:table . " SET " . g:column . " = '". join(text, g:storagvim_crlf) . "' WHERE " . g:where)

	write
	echo 'saved'
endfunction

if g:storagvim_map_keys == 1
	nnoremap <F5> :call storagvim:selectFromGlobalTable()<CR>
	vnoremap <F5> :call storagvim:updateWithGlobalInformation()<CR>
	cnoremap _w call storagvim:saveAndUpdate()
endif
