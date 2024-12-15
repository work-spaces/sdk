""" Spaces SDK Dependencies """

load("star/checkout.star", "checkout_add_repo")

checkout_add_repo(
    "@sources",
    url = "https://github.com/work-spaces/sources",
    rev = "main",
    clone = "Worktree"
)

checkout_add_repo(
    "@packages",
    url = "https://github.com/work-spaces/packages",
    rev = "main",
    clone = "Worktree"
)
