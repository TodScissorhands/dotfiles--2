function nn --description 'Create a new zk note'
    if test (count $argv) -eq 0
        zk --working-dir ~/Documents/Notes new
    else
        zk --working-dir ~/Documents/Notes new --title (string join ' ' -- $argv)
    end
end
