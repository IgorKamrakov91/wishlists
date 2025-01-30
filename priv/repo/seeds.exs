# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Wishlists.Repo.insert!(%Wishlists.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Wishlists.Repo
alias Wishlists.Accounts.{User, Account}
alias Wishlists.Cards.{Card, FolderCard}
alias Wishlists.Folders.Folder

# Create Users with Accounts
{:ok, user1} =
  %User{
    email: "john@example.com",
    hashed_password: Bcrypt.hash_pwd_salt("password123"),
    confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    account: %Account{username: "john_doe"}
  }
  |> Repo.insert()

{:ok, user2} =
  %User{
    email: "jane@example.com",
    hashed_password: Bcrypt.hash_pwd_salt("password123"),
    confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    account: %Account{username: "jane_smith"}
  }
  |> Repo.insert()

# Create Folders
{:ok, tech_folder} =
  %Folder{
    name: "Tech Wishlist",
    description: "All the gadgets I want",
    user_id: user1.id
  }
  |> Repo.insert()

{:ok, books_folder} =
  %Folder{
    name: "Books to Read",
    description: "My reading list",
    user_id: user1.id
  }
  |> Repo.insert()

{:ok, travel_folder} =
  %Folder{
    name: "Travel Goals",
    description: "Places to visit",
    user_id: user2.id
  }
  |> Repo.insert()

# Create Cards
{:ok, laptop_card} =
  %Card{
    title: "MacBook Pro",
    description: "14-inch, M2 Pro chip",
    image_url: "https://example.com/macbook.jpg",
    link_url: "https://apple.com/macbook-pro",
    price: 1999.99,
    user_id: user1.id
  }
  |> Repo.insert()

{:ok, book_card} =
  %Card{
    title: "The Pragmatic Programmer",
    description: "20th Anniversary Edition",
    image_url: "https://example.com/pragprog.jpg",
    link_url: "https://pragprog.com",
    price: 49.99,
    user_id: user1.id
  }
  |> Repo.insert()

{:ok, _cosmetic} =
  %Card{
    title: "Creme",
    description: "Very cool creame",
    image_url: "https://example.com/creme.jpg",
    link_url: "https://creme.com",
    price: 19.99,
    user_id: user1.id
  }
  |> Repo.insert()

{:ok, vacation_card} =
  %Card{
    title: "Japan Trip",
    description: "Two weeks in Tokyo and Kyoto",
    image_url: "https://example.com/japan.jpg",
    link_url: "https://japan-guide.com",
    price: 3000.00,
    user_id: user2.id
  }
  |> Repo.insert()

# Associate Cards with Folders
[
  %FolderCard{folder_id: tech_folder.id, card_id: laptop_card.id, position: 1},
  %FolderCard{folder_id: books_folder.id, card_id: book_card.id, position: 1},
  %FolderCard{folder_id: travel_folder.id, card_id: vacation_card.id, position: 1}
]
|> Enum.each(&Repo.insert!/1)

IO.puts("Seeds planted successfully! 🌱")
