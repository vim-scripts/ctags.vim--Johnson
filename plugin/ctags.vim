" ctags.vim: Display function name in the title bar and/or status line.
" Author:	Alexey Marinichev <lyosha-vim@lyosha.no-ip.org>
" Contributor:	Gary Johnson <garyjohn@spk.agilent.com>
" Last Change:	2003-04-02 21:22:14
" Version:	2.0
" URL:		http://vim.sourceforge.net/scripts/script.php?script_id=12

" DETAILED DESCRIPTION:
" This script uses exuberant ctags to build the list of tags for the current
" file.  CursorHold event is then used to update titlestring and/or statusline.
" 
" Upon sourcing an autocommand is created with event type CursorHold.  It
" updates the title string or a buffer-local variable using the function
" GetTagName.  Another autocommand of type BufEnter is created to generate
" tags for *.c, *.cpp, *.h, *.py and *.vim files.
" 
" Function GenerateTags builds an array of tag names.
" 
" Function GetTagName takes line number argument and returns the tag name.
"
" Function SetStatusline sets the value of 'statusline'.
"
" Function TagName returns the cached tag name.
"
" INSTALL DETAILS:
" Before sourcing the script do:
"    let g:ctags_path='/path/to/ctags'
"    let g:ctags_args='-I __declspec+'
"        (or whatever other additional arguments you want to pass to ctags)
"    let g:ctags_title=1	" To show tag name in title bar.
"    let g:ctags_statusline=1	" To show tag name in status line.
"    let generate_tags=1	" To start automatically when a supported
"				" file is opened.
" :CTAGS command starts the script.

" Exit quickly when already loaded.
"
if exists("loaded_ctags")
    finish
endif
let loaded_ctags = 1

" Allow the use of line-continuation, even if user has 'compatible' set.
"
let s:save_cpo = &cpo
set cpo&vim

if !exists("ctags_path")
    "let g:ctags_path='ctags'
    "let g:ctags_args=''
    let g:ctags_path=$VIM.'/ctags/ctags'
    let g:ctags_args='-I __declspec+'
endif

" If user doesn't specify either g:ctags_title or g:ctags_statusline,
" revert to the original behavior, which was equivalent to g:ctags_title.
"
if !exists("g:ctags_title") && !exists("g:ctags_statusline")
    let g:ctags_title=1
endif

command! CTAGS let generate_tags=1|call GenerateTags()

autocmd BufEnter *.c,*.cpp,*.h,*.py,*.vim
\   if    exists('generate_tags')
\      && !exists('b:lines')
\      && filereadable(expand("<afile>"))
\ | call GenerateTags()
\ | endif

set updatetime=500

if exists("g:ctags_title")
    autocmd CursorHold *
    \   if exists('generate_tags')
    \ |     let &titlestring='%t%( %M%)%( (%{expand("%:~:.:h")})%)%( %a%)%='.GetTagName(line("."))
    \ | endif
endif

if exists("g:ctags_statusline")
    autocmd CursorHold *
    \   if exists('generate_tags')
    \ |     call s:SetStatusline()
    \ | endif
endif

"set titlestring=%t%(\ %M%)%(\ (%{expand(\"%:~:.:h\")})%)%(\ %a%)%=%(tag:\ %-{GetTagName(line("."))}%)



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" No changes should be reqired below (unless there are bugs).
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if version < 600
    function! Stridx(haysack, needle)
	return match(a:haysack, a:needle)
    endfunction
else
    function! Stridx(haysack, needle)
	return stridx(a:haysack, a:needle)
    endfunction
endif

let g:ctags_obligatory_args = '-n --sort=no -o -'
let g:ctags_pattern="^\\(.\\{-}\\)\t.\\{-}\t\\(\\d*\\).*"

" This function builds an array of tag names.  b:lines contains line numbers;
" b:l<number> is the tag value for the line <number>.
function! GenerateTags()
    let ctags = system(g:ctags_path.' '.g:ctags_args.' '.g:ctags_obligatory_args.' "'.expand('%').'"')

    " b:length is one greater than the length of maximum line number.
    let b:length = 8
    let b:lines = ''

    " strlen(spaces) must be at least b:length.
    let spaces = '               '
    let i = 1
    let len = strlen(ctags)

    while strlen(ctags) > 0
	let one_tag = strpart(ctags, 0, Stridx(ctags, "\n"))
	let tag_name = substitute(one_tag, g:ctags_pattern, '\1', '')
	let tag_line_number = substitute(one_tag, g:ctags_pattern, '\2', '')
	execute "let b:l".tag_line_number . " = '".tag_name."'"
	let b:lines = strpart(b:lines.tag_line_number.spaces, 0, b:length*i)
	let i = i+1

	" vim 5.x insists that strpart takes 3 arguments.
	let ctags = strpart(ctags, Stridx(ctags, "\n")+1, len)
    endwhile

    let b:lines = b:lines."9999999"
endfunction

" This function returns the tag name for given index.
function! GetLine(i)
    return strpart(b:lines, a:i*b:length, b:length)+0
endfunction

" This function does binary search in the array of tag names and returns
" corresponding tag.
function! GetTagName(curline)
    if !exists("b:lines")
	return ""
    endif

    let left = 0
    let right = strlen(b:lines)/b:length

    if a:curline < GetLine(left)
	return ""
    endif

    while left<right
	let middle = (right+left+1)/2
	let middleline = GetLine(middle)

	if middleline == a:curline
	    let left = middle
	    break
	endif

	if middleline > a:curline
	    let right = middle-1
	else
	    let left = middle
	endif
    endwhile

    exe "let ret=b:l".GetLine(left)
    return ret
endfunction

" This function sets the value of 'statusline'.
function! s:SetStatusline()
    let w:tag_name = GetTagName(line("."))
    if &ruler
	let &statusline='%<%f %(%h%m%r %)%=%{TagName()} %-15.15(%l,%c%V%)%P'
					" Equivalent to default status
					" line with 'ruler' set:
					"
					" '%<%f %h%m%r%=%-15.15(%l,%c%V%)%P'
    else
	let &statusline='%<%f %(%h%m%r %)%=%{TagName()}'
    endif
					" The %(%) pair around the "%h%m%r "
					" is there to suppress the extra
					" space between the file name and
					" the function name when those
					" elements are null.
endfunction

" This function returns the value of w:tag_name if it exists, otherwise
" ''.
function! TagName()
    if exists('w:tag_name')
	return w:tag_name
    else
	return ''
    endif
endfunction

" Restore cpo.
let &cpo= s:save_cpo
unlet s:save_cpo

" vim:set ts=8 sts=4 sw=4:
