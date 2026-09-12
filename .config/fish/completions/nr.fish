function __nr_note_filenames
    zk --working-dir ~/Documents/Notes list --format '{{filename-stem}}' --no-pager 2>/dev/null
end

complete --command nr --no-files --arguments '(__nr_note_filenames)'
