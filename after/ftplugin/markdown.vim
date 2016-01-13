" folding for Markdown headers, both styles (atx- and setex-)
" http://daringfireball.net/projects/markdown/syntax#header
"
" this code can be placed in file
"   $HOME/.vim/after/ftplugin/markdown.vim
"
" original version from Steve Losh's gist: https://gist.github.com/1038710

function! s:is_mkdCode(lnum)
    return synIDattr(synID(a:lnum, 1, 0), 'name') == 'mkdCode'
endfunction

if get(g:, "vim_markdown_folding_style_pythonic", 0)
    function! Foldexpr_markdown(lnum)
        let l2 = getline(a:lnum+1)
        if  l2 =~ '^==\+\s*' && !s:is_mkdCode(a:lnum+1)
            " next line is underlined (level 1)
            return '>0'
        elseif l2 =~ '^--\+\s*' && !s:is_mkdCode(a:lnum+1)
            " next line is underlined (level 2)
            return '>1'
        endif

        let l1 = getline(a:lnum)
        if l1 =~ '^#' && !s:is_mkdCode(a:lnum)
            " current line starts with hashes
            return '>'.(matchend(l1, '^#\+') - 1)
        elseif a:lnum == 1
            " fold any 'preamble'
            return '>1'
        else
            " keep previous foldlevel
            return '='
        endif
    endfunction

    function! Foldtext_markdown()
        let line = getline(v:foldstart)
        let has_numbers = &number || &relativenumber
        let nucolwidth = &fdc + has_numbers * &numberwidth
        let windowwidth = winwidth(0) - nucolwidth - 6
        let foldedlinecount = v:foldend - v:foldstart
        let line = strpart(line, 0, windowwidth - 2 -len(foldedlinecount))
        let line = substitute(line, '\%("""\|''''''\)', '', '')
        let fillcharcount = windowwidth - len(line) - len(foldedlinecount) + 1
        return line . ' ' . repeat("-", fillcharcount) . ' ' . foldedlinecount
    endfunction
else
    function! Foldexpr_markdown(lnum)
        if (a:lnum == 1)
            let l0 = ''
        else
            let l0 = getline(a:lnum-1)
        endif
        " keep track of fenced code blocks
        if l0 =~ '````*' || l0 =~ '~~~~*'
            if b:fenced_block == 0
                let b:fenced_block = 1
            elseif b:fenced_block == 1
                let b:fenced_block = 0
            endif
        endif

        let l2 = getline(a:lnum+1)
        if  l2 =~ '^==\+\s*' && !s:is_mkdCode(a:lnum+1)
            " next line is underlined (level 1)
            return '>1'
        elseif l2 =~ '^--\+\s*' && !s:is_mkdCode(a:lnum+1)
            " next line is underlined (level 2)
            return '>2'
        endif

        let l1 = getline(a:lnum)
        if l1 =~ '^#' && !s:is_mkdCode(a:lnum)
            " fold level according to option
            " (in vim -1 is visible, >= 0 is folded)
            let l:level = matchend(l1, '^#\+')
            if g:vim_markdown_folding_level == 1 || l:level > g:vim_markdown_folding_level
                return -1
            else
                " code blocks are always folded
                return b:fenced_block
            endif
        endif

        if l0 =~ '^#' && !s:is_mkdCode(a:lnum-1)
            " collapse comments in fenced code blocks into a single fold
            if b:fenced_block == 1
                return 1
            endif
            " current line starts with hashes
            return '>'.matchend(l0, '^#\+')
        else
            " keep previous foldlevel
            return '='
        endif
    endfunction
endif


let b:fenced_block = 0
let g:vim_markdown_folding_level = get(g:, "vim_markdown_folding_level", 1)

if !get(g:, "vim_markdown_folding_disabled", 0)
    setlocal foldexpr=Foldexpr_markdown(v:lnum)
    setlocal foldmethod=expr
    if get(g:, "vim_markdown_folding_style_pythonic", 0)
        setlocal foldtext=Foldtext_markdown()
    endif
endif
