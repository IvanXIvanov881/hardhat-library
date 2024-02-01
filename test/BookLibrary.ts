import { BookLibrary } from "../typechain-types";
import { expect } from "chai";
import { Signer } from "ethers";
import { ethers } from "hardhat";

describe("BookLibrary", function () {
    let bookLibrary: BookLibrary;
    let signers: Signer[];

    before(async () => {
        const BookLibraryFactory = await ethers.getContractFactory("BookLibrary");
        signers = await ethers.getSigners();
        const ownerAddress = await signers[0].getAddress();
        bookLibrary = await BookLibraryFactory.deploy(ownerAddress);
        console.log("Deployed for testing");
    });

    it("Should return an empty array if no books are added", async () => {
        const booksArray = await bookLibrary.connect(signers[0]).getBooks();
        expect(booksArray.length).to.equal(0);
    });

    it("Should return the newly added book after a new book is added and books length should be 1", async () => {
        await bookLibrary.connect(signers[0]).addBook("Book1", 2);
        
        const booksArray = await bookLibrary.connect(signers[0]).getBooks();
        expect(booksArray.length).to.equal(1);
    });

    it("Should allow a non-owner to borrow a book", async () => {
        await bookLibrary.connect(signers[0]).addBook("Book1", 2);
        await bookLibrary.connect(signers[1]).borrowBook(0);
    
        const borrowedBooksArray = await bookLibrary.borrowedBooks();
        expect(borrowedBooksArray[0]).to.equal("Book1");
    });

    it("Should get all available books", async () => {
        await bookLibrary.connect(signers[0]).addBook("Book2", 2);
    
        const availableBooks = await bookLibrary.connect(signers[1]).getAvailableBooks();
        expect(availableBooks[1][1]).to.equal('Book2');
    });

    it("Should correctly handle the borrowing of a book by a non-owner", async() => {
        await bookLibrary.connect(signers[2]).borrowBook(1);

        const borrowedBooksArray = await bookLibrary.connect(signers[1]).borrowedBooks();
        expect(borrowedBooksArray[1]).to.equal("Book2");
    });

    it("Should allow a non-owner to borrow a book and check the user status", async () => {
        await bookLibrary.connect(signers[0]).addBook("Book3", 2);
        await bookLibrary.connect(signers[3]).borrowBook(2);
    
        const borrowersArray = await bookLibrary.connect(signers[3]).usersThatBorrowBooks();
        const signerAddress = await signers[3].getAddress();
        expect(borrowersArray.includes(signerAddress)).to.equal(true);
    });

    it("Should return all books", async () => {        
    
        const booksArray = await bookLibrary.connect(signers[3]).getBooks();
        expect(booksArray.length).to.equal(3);
        expect(booksArray[0].name).to.equal("Book1");
        expect(booksArray[1].name).to.equal("Book2");
        expect(booksArray[2].name).to.equal("Book3");
    });
    
    it("Should add a new book", async () => {
        await bookLibrary.connect(signers[0]).addBook("Book5", 2);
    
        const booksArray = await bookLibrary.connect(signers[3]).getBooks();
        expect(booksArray.length).to.equal(4);
        expect(booksArray[3].name).to.equal("Book5");
    });

    it("Should allow a non-owner to return a borrowed book", async () => {
        await bookLibrary.connect(signers[1]).backBarrowBook(0);
    
        const borrowedBooksArray = await bookLibrary.connect(signers[0]).borrowedBooks();
        expect(borrowedBooksArray.includes("Book1")).to.equal(false);
    });

    it("Should prevent adding a book with no copies", async () => {
        await expect(bookLibrary.connect(signers[0]).addBook("Book11", 0)).to.be.revertedWith("Please add at least one copy.");
    });
    
    it("Should prevent owner from borrowing a book", async () => {
        await bookLibrary.connect(signers[0]).addBook("Book1", 1);
        await expect(bookLibrary.connect(signers[0]).borrowBook(0)).to.be.revertedWith("Owner can't borrow the book.");
    });
    
    it("Should prevent returning a book that hasn't been borrowed", async () => {
        await bookLibrary.addBook("Book1", 1);
        await expect(bookLibrary.connect(signers[0]).backBarrowBook(0)).to.be.revertedWith("You need to have the book first!");
    });
    
    it("Should prevent borrowing a book that is already borrowed", async () => {
        await bookLibrary.connect(signers[1]).borrowBook(0);
        await expect(bookLibrary.connect(signers[1]).borrowBook(0)).to.be.revertedWith("Please return the book first.");
    });

    it("Should correctly update the status of a book", async () => {

        await bookLibrary.connect(signers[11]).borrowBook(0);

        let status = await bookLibrary.connect(signers[0]).getBookStatus(signers[11], 0);
        expect(status).to.equal(1);
    
        await bookLibrary.connect(signers[11]).backBarrowBook(0);

        status = await bookLibrary.connect(signers[0]).getBookStatus(signers[11], 0);
        expect(status).to.equal(2); 
    });

    it("Should correctly get the book status", async () => {
  
        await bookLibrary.connect(signers[1]).backBarrowBook(0);
        await bookLibrary.connect(signers[1]).borrowBook(0);
    
        let status = await bookLibrary.getBookStatus(signers[1].getAddress(), 0);
        expect(status).to.equal(1);
        await bookLibrary.connect(signers[1]).backBarrowBook(0);
    
        status = await bookLibrary.getBookStatus(signers[1].getAddress(), 0);
        expect(status).to.equal(2);
    });

})