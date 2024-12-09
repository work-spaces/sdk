""" Spaces SDK Dependencies """

load("star/checkout.star", "checkout_add_repo")

checkout_add_repo(
    "@sources",
    url = "https://github.com/work-spaces/sources",
    rev = "fb0d339c43234b533651ffd24c6c51ab44699716",
    clone = "Blobless"
)

checkout_add_repo(
    "@packages",
    url = "https://github.com/work-spaces/packages",
    rev = "a2827ef33ea705e8d3c9d79fc6e1f11efc6e8b15",
    clone = "Blobless"
)
