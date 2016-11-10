
if !has('folding')
    finish
endif

set foldtext=vimcleanfold#FoldText()

autocmd! CursorMoved * :set foldtext=vimcleanfold#FoldText()

function! vimcleanfold#FoldText()
    let l:line = s:MangleLine(getline(v:foldstart))

    let l:fold_size  = v:foldend - v:foldstart + 1
    let l:fold_level = &shiftwidth * v:foldlevel

    if getcurpos()[1] == v:foldstart
        let l:extra = '∙'
    else
        let l:extra = ' '
    endif

    let l:padding =
        \ winwidth(0) -
        \ s:GetInfoColumnsWidth() -
        \ len(l:line) -
        \ len(l:fold_size) -
        \ l:fold_level -
        \ strchars(l:extra)

    return
        \ repeat(' ', l:fold_level).
        \ l:line.
        \ repeat(' ', l:padding).
        \ l:fold_size.
        \ l:extra

endfunction

function! s:MangleLine(line)
    let l:line = a:line
    let commentstring = split(&commentstring, "%s")[0]

    for marker in split(&foldmarker, ",")
        " Remove marker if it is apart of a comment
        let l:line = substitute(l:line, commentstring.'.*\zs'.marker, '', 'g')
    endfor

    if commentstring[0] != ''
        " Remove commentstring and comment if there is text before it.
        let l:line = substitute(l:line, '\w.*\zs'.commentstring.'.*', '', 'g')

        " Remove commentstring if there is only whitespace before it.
        let l:line = substitute(l:line, '^\s*'.commentstring, '', 'g')
    endif

    "Remove leading whitespace
    let l:line = substitute(l:line, '^\s*' , '', 'g')

    return l:line
endfunction

function! s:GetInfoColumnsWidth()
    let l:decorationColumns = s:GetNumberWidth()

    if has('folding')
        let l:decorationColumns += &l:foldcolumn
    endif

    if has('signs')
        " Redirect command output to variable
        redir => l:signsOutput
        " List all placed signs for current buffer
        silent execute 'sign place buffer=' . bufnr('')
        redir END

        " The ':sign place' output contains two header lines.
        " The sign column is fixed at two columns.
        if len(split(l:signsOutput, "\n")) > 2
            let l:decorationColumns += 2
        endif
    endif

    return l:decorationColumns
endfunction

function! s:GetNumberWidth()
    if &l:number
        let l:maxNumber = line('$')
    elseif exists('+relativenumber') && &l:relativenumber
        let l:maxNumber = winheight(0)
    else
        return 0
    endif

    " +1 to account for padding
    let l:actualnumberwidth = strlen(string(l:maxNumber)) + 1
    return max([l:actualnumberwidth, &l:numberwidth])
endfunction
