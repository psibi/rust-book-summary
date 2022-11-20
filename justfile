# List all recipies
default:
    just --list --unsorted

# Serve book
serve:
    mdbook serve --dest-dir ./docs
