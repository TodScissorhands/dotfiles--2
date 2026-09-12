function ne --description 'Edit a zk note'
    set --local notes_dir ~/Documents/Notes
    zk --working-dir $notes_dir index >/dev/null

    if test (count $argv) -eq 0
        zk --working-dir $notes_dir edit --interactive
    else
        set --local query (string join ' ' -- $argv)
        if test -f "$notes_dir/$query.md"
            zk --working-dir $notes_dir edit "$query.md"
        else
            zk --working-dir $notes_dir edit --match "$query"
        end
    end
end
