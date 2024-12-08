""" Spaces SDK Dependencies """

load("star/checkout.star", "checkout_add_repo")

checkout_add_repo(
    "@sources",
    url = "https://github.com/work-spaces/sources",
    rev = "20b6b1bb56eb0f2809c77cf566f0c0b701d66fe6",
    clone = "Blobless"
)

checkout_add_repo(
    "@packages",
    url = "https://github.com/work-spaces/packages",
    rev = "f516050d37154bd38be20755db820f6eeafba41d",
    clone = "Blobless"
)
