function __ne_note_titles
    zk --working-dir ~/Documents/Notes list --format '{{filename-stem}}' --no-pager 2>/dev/null
end

complete --command ne --no-files --arguments '(__ne_note_titles)'
