function nf --description 'Find note filenames containing every search word'
    set --local notes_dir ~/Documents/Notes
    set --local original_dir $PWD
    cd $notes_dir; or return 1

    set --local filenames (command rg --files --glob '*.md')
    for term in $argv
        set filenames (printf '%s\n' $filenames | command grep --fixed-strings --ignore-case -- "$term")
    end
    printf '%s\n' $filenames
    set --local search_status $status
    cd $original_dir
    return $search_status
end
