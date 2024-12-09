""" Spaces SDK Dependencies """

load("star/checkout.star", "checkout_add_repo")

checkout_add_repo(
    "@sources",
    url = "https://github.com/work-spaces/sources",
    rev = "8e0d72289bdbc3a06bd7d5a22b9ef3b0a907117e",
    clone = "Blobless"
)

checkout_add_repo(
    "@packages",
    url = "https://github.com/work-spaces/packages",
    rev = "a2827ef33ea705e8d3c9d79fc6e1f11efc6e8b15",
    clone = "Blobless"
)
