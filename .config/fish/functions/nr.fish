function nr --description 'Remove note files from ~/Documents/Notes'
    set --local notes_dir ~/Documents/Notes

    if test (count $argv) -eq 0
        echo 'Usage: nr <note-filename>' >&2
        return 2
    end

    set --local note_paths
    for name in $argv
        if string match --quiet '*.md' -- $name
            set --append note_paths "$notes_dir/$name"
        else
            set --append note_paths "$notes_dir/$name.md"
        end
    end

    for note_path in $note_paths
        if not test -f "$note_path"
            echo "Not a note file: $note_path" >&2
            return 1
        end
    end

    rm -- $note_paths
    zk --working-dir $notes_dir index >/dev/null
end
