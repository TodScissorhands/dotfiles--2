function np --description 'Search notes for an exact phrase'
    if test (count $argv) -eq 0
        echo 'Usage: np <exact phrase>' >&2
        return 2
    end

    set --local phrase (string join ' ' -- $argv)
    set --local notes_dir ~/Documents/Notes
    set --local original_dir $PWD
    cd $notes_dir; or return 1
    command rg --smart-case --fixed-strings --line-number --with-filename --no-heading --glob '*.md' --regexp "$phrase"
    set --local search_status $status
    cd $original_dir
    return $search_status
end
