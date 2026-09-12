function na --description 'Search notes containing every word'
    if test (count $argv) -eq 0
        echo 'Usage: na <search words>' >&2
        return 2
    end

    set --local notes_dir ~/Documents/Notes
    set --local original_dir $PWD
    cd $notes_dir; or return 1

    set --local matches (command rg --files-with-matches --smart-case --fixed-strings --glob '*.md' --regexp "$argv[1]")
    for term in $argv[2..-1]
        set --local next_matches
        for note_path in $matches
            if command rg --quiet --smart-case --fixed-strings --regexp "$term" -- "$note_path"
                set --append next_matches "$note_path"
            end
        end
        set matches $next_matches
    end

    if test (count $matches) -gt 0
        set --local patterns
        for term in $argv
            set --append patterns --regexp "$term"
        end
        command rg --smart-case --fixed-strings --line-number --with-filename --no-heading $patterns -- $matches
    end
    set --local search_status $status
    cd $original_dir
    return $search_status
end
