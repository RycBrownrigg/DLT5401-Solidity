/*
This test suite covers the following aspects:

    1.) Loan Request creation and validation
    2.) Providing, accepting, and rejecting guarantees
    3.) Loan funding and repayment
    4.) Guarantee withdrawal
    4.) Edge cases and restrictions (e.g., non-borrower actions, duplicate guarantees)
    5.) View function for loan details

These tests ensure that both the intended functionality works correctly and that invalid operations are properly prevented. They cover positive scenarios (actions that should succeed) and negative scenarios (actions that should fail with specific error messages).

How to use these tests:

Set up a Hardhat project with the necessary dependencies. Make sure to place the P2PLending contract in the contracts folder and this test file in the test folder. Then, run the tests using the 'npx hardhat test' command.

*/

const { expect } = require("chai"); // Import Chai
const { ethers } = require("hardhat"); // Import Hardhat

describe("P2PLending", function () {
  // Start of test suite
  // Declare variables to be used across tests
  let P2PLending, p2pLending, owner, borrower, guarantor, lender, addr1;
  let loanId;

  // Before each test, deploy a new instance of the contract
  beforeEach(async function () {
    // Get the ContractFactory and Signers
    P2PLending = await ethers.getContractFactory("P2PLending");
    [owner, borrower, guarantor, lender, addr1] = await ethers.getSigners();

    // Deploy the contract
    p2pLending = await P2PLending.deploy();
    await p2pLending.deployed();
  });

  describe("Loan Request", function () {
    it("Should create a loan request", async function () {
      // Set up loan request parameters
      const amount = ethers.utils.parseEther("1");
      const repaymentDate = Math.floor(Date.now() / 1000) + 86400; // 1 day from now
      const interest = ethers.utils.parseEther("0.1");

      // Create a loan request and check if the LoanRequested event is emitted with correct parameters
      await expect(
        p2pLending
          .connect(borrower)
          .requestLoan(amount, repaymentDate, interest)
      )
        .to.emit(p2pLending, "LoanRequested")
        .withArgs(1, borrower.address, amount, repaymentDate, interest);

      // Verify the loan request details
      const loanRequest = await p2pLending.loanRequests(1);
      expect(loanRequest.borrower).to.equal(borrower.address);
      expect(loanRequest.amount).to.equal(amount);
      expect(loanRequest.repaymentDate).to.equal(repaymentDate);
      expect(loanRequest.interest).to.equal(interest);
      expect(loanRequest.isActive).to.be.true;
    });

    it("Should not create a loan request with invalid parameters", async function () {
      // Test with invalid amount (0)
      const amount = 0;
      const repaymentDate = Math.floor(Date.now() / 1000) - 86400; // 1 day ago
      const interest = 0;

      await expect(
        p2pLending
          .connect(borrower)
          .requestLoan(amount, repaymentDate, interest)
      ).to.be.revertedWith("Loan amount must be greater than 0");

      // Test with invalid repayment date (in the past)
      await expect(
        p2pLending
          .connect(borrower)
          .requestLoan(ethers.utils.parseEther("1"), repaymentDate, interest)
      ).to.be.revertedWith("Repayment date must be in the future");

      // Test with invalid interest (0)
      await expect(
        p2pLending
          .connect(borrower)
          .requestLoan(
            ethers.utils.parseEther("1"),
            Math.floor(Date.now() / 1000) + 86400,
            interest
          )
      ).to.be.revertedWith("Interest must be greater than 0");
    });
  });

  describe("Guarantee", function () {
    // Before each test in this describe block, create a loan request
    beforeEach(async function () {
      const amount = ethers.utils.parseEther("1");
      const repaymentDate = Math.floor(Date.now() / 1000) + 86400; // 1 day from now
      const interest = ethers.utils.parseEther("0.1");

      await p2pLending
        .connect(borrower)
        .requestLoan(amount, repaymentDate, interest);
      loanId = 1;
    });

    it("Should provide guarantee", async function () {
      const guarantorInterest = ethers.utils.parseEther("0.05");
      const amount = ethers.utils.parseEther("1");

      // Provide guarantee and check if the GuaranteeProvided event is emitted with correct parameters
      await expect(
        p2pLending
          .connect(guarantor)
          .provideGuarantee(loanId, guarantorInterest, { value: amount })
      )
        .to.emit(p2pLending, "GuaranteeProvided")
        .withArgs(loanId, guarantor.address, guarantorInterest);

      // Verify the updated loan request details
      const loanRequest = await p2pLending.loanRequests(loanId);
      expect(loanRequest.guarantor).to.equal(guarantor.address);
      expect(loanRequest.guarantorInterest).to.equal(guarantorInterest);
      expect(loanRequest.isGuaranteed).to.be.true;
    });

    it("Should not provide guarantee with invalid parameters", async function () {
      const guarantorInterest = ethers.utils.parseEther("0.05");
      const amount = ethers.utils.parseEther("0.5");

      // Test with incorrect guarantee amount
      await expect(
        p2pLending
          .connect(guarantor)
          .provideGuarantee(loanId, guarantorInterest, { value: amount })
      ).to.be.revertedWith("Incorrect guarantee amount");

      // Test with guarantor interest exceeding total interest
      await expect(
        p2pLending
          .connect(guarantor)
          .provideGuarantee(loanId, ethers.utils.parseEther("0.2"), {
            value: ethers.utils.parseEther("1"),
          })
      ).to.be.revertedWith("Guarantor interest cannot exceed total interest");
    });

    it("Should accept guarantee", async function () {
      const guarantorInterest = ethers.utils.parseEther("0.05");
      const amount = ethers.utils.parseEther("1");

      // Provide guarantee
      await p2pLending
        .connect(guarantor)
        .provideGuarantee(loanId, guarantorInterest, { value: amount });

      // Accept guarantee and check if the GuaranteeAccepted event is emitted
      await expect(p2pLending.connect(borrower).acceptGuarantee(loanId))
        .to.emit(p2pLending, "GuaranteeAccepted")
        .withArgs(loanId);
    });

    it("Should reject guarantee", async function () {
      const guarantorInterest = ethers.utils.parseEther("0.05");
      const amount = ethers.utils.parseEther("1");

      // Provide guarantee
      await p2pLending
        .connect(guarantor)
        .provideGuarantee(loanId, guarantorInterest, { value: amount });

      // Reject guarantee and check if the GuaranteeRejected event is emitted
      await expect(p2pLending.connect(borrower).rejectGuarantee(loanId))
        .to.emit(p2pLending, "GuaranteeRejected")
        .withArgs(loanId);

      // Verify that the guarantee details are reset
      const loanRequest = await p2pLending.loanRequests(loanId);
      expect(loanRequest.guarantor).to.equal(ethers.constants.AddressZero);
      expect(loanRequest.guarantorInterest).to.equal(0);
      expect(loanRequest.isGuaranteed).to.be.false;
    });
  });

  describe("Loan Funding and Repayment", function () {
    // Before each test in this describe block, create a loan request and provide guarantee
    beforeEach(async function () {
      const amount = ethers.utils.parseEther("1");
      const repaymentDate = Math.floor(Date.now() / 1000) + 86400; // 1 day from now
      const interest = ethers.utils.parseEther("0.1");

      await p2pLending
        .connect(borrower)
        .requestLoan(amount, repaymentDate, interest);
      loanId = 1;

      const guarantorInterest = ethers.utils.parseEther("0.05");
      await p2pLending
        .connect(guarantor)
        .provideGuarantee(loanId, guarantorInterest, { value: amount });
      await p2pLending.connect(borrower).acceptGuarantee(loanId);
    });

    it("Should provide loan", async function () {
      const amount = ethers.utils.parseEther("1");

      // Provide loan and check if the LoanFunded event is emitted
      await expect(
        p2pLending.connect(lender).provideLoan(loanId, { value: amount })
      )
        .to.emit(p2pLending, "LoanFunded")
        .withArgs(loanId, lender.address);

      // Verify that the lender is set correctly
      const loanRequest = await p2pLending.loanRequests(loanId);
      expect(loanRequest.lender).to.equal(lender.address);
    });

    it("Should repay loan", async function () {
      const amount = ethers.utils.parseEther("1");
      await p2pLending.connect(lender).provideLoan(loanId, { value: amount });

      const repaymentAmount = ethers.utils.parseEther("1.1"); // loan + interest

      // Repay loan and check if the LoanRepaid event is emitted
      await expect(
        p2pLending
          .connect(borrower)
          .repayLoan(loanId, { value: repaymentAmount })
      )
        .to.emit(p2pLending, "LoanRepaid")
        .withArgs(loanId);

      // Verify that the loan is marked as repaid and inactive
      const loanRequest = await p2pLending.loanRequests(loanId);
      expect(loanRequest.isRepaid).to.be.true;
      expect(loanRequest.isActive).to.be.false;
    });

    it("Should withdraw guarantee", async function () {
      const amount = ethers.utils.parseEther("1");
      await p2pLending.connect(lender).provideLoan(loanId, { value: amount });

      // Increase time to pass repayment date
      await ethers.provider.send("evm_increaseTime", [86401]); // 1 day + 1 second
      await ethers.provider.send("evm_mine");

      // Withdraw guarantee and check if the GuaranteeWithdrawn event is emitted
      await expect(p2pLending.connect(lender).withdrawGuarantee(loanId))
        .to.emit(p2pLending, "GuaranteeWithdrawn")
        .withArgs(loanId);

      // Verify that the loan is marked as inactive
      const loanRequest = await p2pLending.loanRequests(loanId);
      expect(loanRequest.isActive).to.be.false;
    });
  });

  describe("Edge Cases and Restrictions", function () {
    // Before each test in this describe block, create a loan request
    beforeEach(async function () {
      const amount = ethers.utils.parseEther("1");
      const repaymentDate = Math.floor(Date.now() / 1000) + 86400; // 1 day from now
      const interest = ethers.utils.parseEther("0.1");

      await p2pLending
        .connect(borrower)
        .requestLoan(amount, repaymentDate, interest);
      loanId = 1;
    });

    it("Should not allow non-borrower to accept/reject guarantee", async function () {
      const guarantorInterest = ethers.utils.parseEther("0.05");
      const amount = ethers.utils.parseEther("1");

      await p2pLending
        .connect(guarantor)
        .provideGuarantee(loanId, guarantorInterest, { value: amount });

      // Test that non-borrower cannot accept guarantee
      await expect(
        p2pLending.connect(addr1).acceptGuarantee(loanId)
      ).to.be.revertedWith("Only borrower can accept guarantee");

      // Test that non-borrower cannot reject guarantee
      await expect(
        p2pLending.connect(addr1).rejectGuarantee(loanId)
      ).to.be.revertedWith("Only borrower can reject guarantee");
    });

    it("Should not allow providing guarantee twice", async function () {
      const guarantorInterest = ethers.utils.parseEther("0.05");
      const amount = ethers.utils.parseEther("1");

      // Provide guarantee once
      await p2pLending
        .connect(guarantor)
        .provideGuarantee(loanId, guarantorInterest, { value: amount });

      // Test that providing guarantee again fails
      await expect(
        p2pLending
          .connect(addr1)
          .provideGuarantee(loanId, guarantorInterest, { value: amount })
      ).to.be.revertedWith("Loan is already guaranteed");
    });

    it("Should not allow funding an unguaranteed loan", async function () {
      const amount = ethers.utils.parseEther("1");

      // Test that funding an unguaranteed loan fails
      await expect(
        p2pLending.connect(lender).provideLoan(loanId, { value: amount })
      ).to.be.revertedWith("Loan must be guaranteed");
    });

    it("Should not allow repayment by non-borrower", async function () {
      const guarantorInterest = ethers.utils.parseEther("0.05");
      const amount = ethers.utils.parseEther("1");

      // Set up loan with guarantee and funding
      await p2pLending
        .connect(guarantor)
        .provideGuarantee(loanId, guarantorInterest, { value: amount });
      await p2pLending.connect(borrower).acceptGuarantee(loanId);
      await p2pLending.connect(lender).provideLoan(loanId, { value: amount });

      const repaymentAmount = ethers.utils.parseEther("1.1"); // loan + interest

      // Test that repayment by non-borrower fails
      await expect(
        p2pLending.connect(addr1).repayLoan(loanId, { value: repaymentAmount })
      ).to.be.revertedWith("Only borrower can repay loan");
    });

    it("Should not allow withdrawing guarantee before repayment date", async function () {
      const guarantorInterest = ethers.utils.parseEther("0.05");
      const amount = ethers.utils.parseEther("1");

      // Set up loan with guarantee and funding
      await p2pLending
        .connect(guarantor)
        .provideGuarantee(loanId, guarantorInterest, { value: amount });
      await p2pLending.connect(borrower).acceptGuarantee(loanId);
      await p2pLending.connect(lender).provideLoan(loanId, { value: amount });

      // Test that withdrawing guarantee before repayment date fails
      await expect(
        p2pLending.connect(lender).withdrawGuarantee(loanId)
      ).to.be.revertedWith("Repayment date not yet passed");
    });
  });

  describe("View Functions", function () {
    it("Should return correct loan details", async function () {
      // Create a loan request
      const amount = ethers.utils.parseEther("1");
      const repaymentDate = Math.floor(Date.now() / 1000) + 86400; // 1 day from now
      const interest = ethers.utils.parseEther("0.1");

      await p2pLending
        .connect(borrower)
        .requestLoan(amount, repaymentDate, interest);
      loanId = 1;

      // Get loan details using the view function
      const loanDetails = await p2pLending.getLoanDetails(loanId);

      // Verify all loan details are correct
      expect(loanDetails.borrower).to.equal(borrower.address);
      expect(loanDetails.amount).to.equal(amount);
      expect(loanDetails.repaymentDate).to.equal(repaymentDate);
      expect(loanDetails.interest).to.equal(interest);
      expect(loanDetails.isActive).to.be.true;
      expect(loanDetails.isGuaranteed).to.be.false;
      expect(loanDetails.isRepaid).to.be.false;
    });
  });
});
