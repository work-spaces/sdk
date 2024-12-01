""" Spaces SDK Dependencies """

load("star/checkout.star", "checkout_add_repo")

checkout_add_repo(
    "@packages",
    url = "https://github.com/work-spaces/packages",
    rev = "main",
    clone = "Shallow"
)
