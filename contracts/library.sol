// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BookLibrary is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) public {}
    // Define the structure of a book
    struct Book {
        string name; // Name of the book
        uint256 copies; // Number of copies of the book
        uint256 borrowed; // Number of borrowed copies of the book
        address[] allBorrowers; // Array of addresses of all borrowers of the book
    }
    // Array of all books in the library
    Book[] books;

    function getBooks() public view returns (Book[] memory) {
        return books;
    }

    // Mapping for easier access of ids based on book names
    mapping(string => uint256) bookNamesToIds;

    // Function to add a book to the library
    function addBook(string calldata _name, uint256 _copies) public onlyOwner {
        require(_copies > 0, "Please add at least one copy.");

        if (_isNewBook(_name)) {
            Book memory newBook = Book(_name, _copies, 0, new address[](0));
            books.push(newBook);
            bookNamesToIds[_name] = books.length - 1;
        } else {
            books[bookNamesToIds[_name]].copies =
                books[bookNamesToIds[_name]].copies +
                _copies;
        }
    }

    // Private function to check if a book is new
    function _isNewBook(string calldata _name) private view returns (bool) {
        bool newBook = true;

        for (uint256 i = 0; i < books.length; i++) {
            if (
                keccak256(abi.encodePacked(books[i].name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                newBook = false;
            }
        }
        return newBook;
    }

    // Mapping to track the status of books borrowed by each address
    mapping(address => mapping(uint256 => uint256)) borrowerToBookIdsToStatus;

    // Constants for the status of the book
    uint256 constant BORROWED = 1;
    uint256 constant RETURNED = 2;

    // Event used to signal the success of the operation
    event OperationSuccessful(string message);

    // Function to borrow a book from the library
    function borrowBook(uint256 _id) public bookMustExist(_id) {
        require(
            borrowerToBookIdsToStatus[msg.sender][_id] != BORROWED,
            "Please return the book first."
        );

        require(
            books[_id].copies - books[_id].borrowed > 0,
            "No available copies."
        );

        require(msg.sender != owner(), "Owner can't borrow the book.");

        if (borrowerToBookIdsToStatus[msg.sender][_id] != RETURNED) {
            books[_id].allBorrowers.push(msg.sender);
        }

        borrowerToBookIdsToStatus[msg.sender][_id] = BORROWED;
        books[_id].borrowed = books[_id].borrowed + 1;
    }

    // Function to get the status of a book for a specific address
    function getBookStatus(
        address _address,
        uint256 _id
    ) public view returns (uint256) {
        return borrowerToBookIdsToStatus[_address][_id];
    }

    // Function to return a borrowed book to the library
    function backBarrowBook(uint256 _id) public bookMustExist(_id) {
        require(
            borrowerToBookIdsToStatus[msg.sender][_id] == BORROWED,
            "You need to have the book first!"
        );

        borrowerToBookIdsToStatus[msg.sender][_id] = RETURNED;
        books[_id].borrowed = books[_id].borrowed - 1;
    }

    // Modifier to check if a book exists
    modifier bookMustExist(uint256 _id) {
        require(books.length > 0, "No books in the library.");
        require(_id <= books.length - 1, "Book with this ID doesn't exist.");
        _;
    }

    // Structure representing an available book
    struct AvailableBook {
        uint256 id;
        string book;
    }

    // Function to get all available books
    function getAvailableBooks() public view returns (AvailableBook[] memory) {
        uint256 counter = 0;
        for (uint256 i = 0; i < books.length; i++) {
            if (books[i].copies - books[i].borrowed > 0) {
                counter++;
            }
        }

        AvailableBook[] memory availableBooks = new AvailableBook[](counter);
        counter = 0;
        for (uint256 i = 0; i < books.length; i++) {
            if (books[i].copies - books[i].borrowed > 0) {
                availableBooks[counter] = AvailableBook(
                    bookNamesToIds[books[i].name],
                    books[i].name
                );
                counter++;
            }
        }
        return availableBooks;
    }

    // Mapping to track all borrowed books by each address
    mapping(address => string) allBorrowedBooks;

    // Function to get the names of all borrowed books
    function borrowedBooks() public view returns (string[] memory) {
        uint256 totalCount = 0;
        for (uint256 i = 0; i < books.length; i++) {
            if (books[i].borrowed > 0) {
                totalCount++;
            }
        }
        string[] memory borrowedBookNames = new string[](totalCount);
        uint256 count = 0;

        for (uint256 i = 0; i < books.length; i++) {
            if (books[i].borrowed > 0) {
                borrowedBookNames[count] = books[i].name;
                count++;
            }
        }
        return borrowedBookNames;
    }

    // Function to get all addresses that have borrowed a book
    function usersThatBorrowBooks() public view returns (address[] memory) {
        uint256 totalCount = 0;
        for (uint256 i = 0; i < books.length; i++) {
            if (books[i].allBorrowers.length > 0) {
                totalCount += books[i].allBorrowers.length;
            }
        }
        address[] memory allUsersThatBorrowedBooks = new address[](totalCount);
        uint256 currentCount = 0;
        for (uint256 i = 0; i < books.length; i++) {
            if (books[i].allBorrowers.length > 0) {
                for (uint256 j = 0; j < books[i].allBorrowers.length; j++) {
                    allUsersThatBorrowedBooks[currentCount++] = books[i]
                        .allBorrowers[j];
                }
            }
        }
        return allUsersThatBorrowedBooks;
    }
}
