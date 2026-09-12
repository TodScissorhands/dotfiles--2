function ns --description 'Search zk notes'
    if test (count $argv) -eq 0
        echo 'Usage: ns <search words>' >&2
        return 2
    end

    set --local notes_dir ~/Documents/Notes
    set --local rg_patterns
    for term in $argv
        set --append rg_patterns --regexp "$term"
    end

    set --local original_dir $PWD
    cd $notes_dir; or return 1
    command rg --smart-case --fixed-strings --line-number --with-filename --no-heading --glob '*.md' $rg_patterns
    set --local search_status $status
    cd $original_dir
    return $search_status
end
