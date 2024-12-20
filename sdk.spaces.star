""" Spaces SDK Dependencies """

load("star/checkout.star", "checkout_add_repo")

checkout_add_repo(
    "//@sdk/packages",
    url = "https://github.com/work-spaces/packages",
    rev = "main",
    clone = "Worktree"
)
