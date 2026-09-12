function nl --description 'List zk notes'
    zk --working-dir ~/Documents/Notes list --format oneline --no-pager $argv
end
