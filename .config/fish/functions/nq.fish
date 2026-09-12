function nq --description 'Fuzzy-pick a note by filename or content, then edit it'
    set --local notes_dir ~/Documents/Notes
    set --local original_dir $PWD
    cd $notes_dir; or return 1

    set --local selection (
        for note_path in *.md
            test -f "$note_path"; or continue
            set --local content (string collect < "$note_path")
            set content (string replace --all \n ' ' -- "$content")
            printf '%s\t%s\n' "$note_path" "$content"
        end | fzf --delimiter '\t' --with-nth=1,2 --nth=1,2 --prompt='notes> ' --height=60% --reverse
    )
    set --local picker_status $status
    cd $original_dir

    if test $picker_status -eq 0; and test -n "$selection"
        set --local note_path (string split \t -- $selection)[1]
        zk --working-dir $notes_dir edit "$note_path"
    end
end
