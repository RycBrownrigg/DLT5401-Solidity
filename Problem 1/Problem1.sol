/*

Key points about this implementation:

1.) The contract uses the struct LoanRequest to store all information about a loan request, including borrower, amount, repayment date, interest, guarantor, lender, and various status flags.

2.) Loan requests are stored in a mapping with a unique ID, allowing easy access to each loan's details.

3.) The contract implements all required functionality:

    - Borrowers can request loans
    - Guarantors can provide guarantees
    - Borrowers can accept or reject guarantees
    - Lenders can view loan details and provide loans
    - Borrowers can repay loans
    - Lenders can withdraw guarantees if loans are not repaid on time


4.) Events are emitted for all major actions, allowing for easy tracking of contract activity off-chain.

5.) The contract includes various checks to prevent abuse:

    - Ensures all amounts are correct when providing guarantees, loans, or repayments
    - Checks that only authorized addresses (borrower, lender, or guarantor) can perform certain actions
    - Verifies that actions are taken in the correct order (e.g., guarantee must be provided before loan, loan must be funded before repayment)
    - Prevents double-funding or double-repayment of loans


6.) The getLoanDetails function allows anyone to view the full details of a loan request, satisfying the requirement for lenders to be able to view loan information.

7.) The contract uses the payable keyword and transfer function to handle Ether transactions securely.

How to use this system:

    1.) Deploy the Contract: deploy this contract to the Ethereum network.
    2.) Request a Loan: the borrower calls requestLoan(uint256 _amount, uint256 _repaymentDate, uint256 _interest)
    Example: requestLoan(1 ether, 1678900000, 0.1 ether) This creates a loan request with a unique ID.
    3.) Provide a Guarantee: a guarantor calls provideGuarantee(uint256 _loanId, uint256 _guarantorInterest) and sends the required Ether. This locks the guarantor's funds in the contract.
    4.) Accept or Reject the Guarantee: the borrower calls either acceptGuarantee(uint256 _loanId) or rejectGuarantee(uint256 _loanId). If rejected, the guarantor's funds are returned.
    5.) Provide the Loan: a lender calls provideLoan(uint256 _loanId) and sends the required Ether. This sends the loan amount to the borrower.
    6.) Repay the Loan: when the loan is due, the borrower calls repayLoan(uint256 _loanId) and sends the loan amount plus interest. This repays the loan, sends funds to the lender and guarantor
    7.) Withdraw Guarantee (if loan isn't repaid): if the loan isn't repaid by the due date, the lender can call withdrawGuarantee(uint256 _loanId). This sends the guarantee to the lender

At any point, anyone can call getLoanDetails(uint256 _loanId) to view the current state of a loan.

All functions that send Ether (like provideGuarantee, provideLoan, and repayLoan) need to be called with the correct amount of Ether attached to the transaction. This ensures that the contract can handle the funds correctly and that the loan process works as intended.

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // Solidity version

contract P2PLending { // Contract name - P2PLending
    struct LoanRequest { // Struct for LoanRequest with the following fields - borrower, amount, repaymentDate, interest, guarantor, guarantorInterest, lender, isActive, isGuaranteed, isRepaid 
        address payable borrower; // Address of borrower - payable
        uint256 amount; // Amount of loan requested - uint256
        uint256 repaymentDate; // Repayment date of loan - uint256
        uint256 interest; // Interest on loan - uint256  
        address payable guarantor; // Address of guarantor - payable
        uint256 guarantorInterest; // Interest of guarantor - uint256
        address payable lender; // Address of lender - payable
        bool isActive; // Boolean to check if loan is active
        bool isGuaranteed; // Boolean to check if loan is guaranteed
        bool isRepaid; // Boolean to check if loan is repaid
    }

    mapping(uint256 => LoanRequest) public loanRequests; // Mapping of loan requests with loanId as key and LoanRequest as value - uint256 => LoanRequest 
    uint256 public loanRequestCount; // Count of loan requests - uint256 

    event LoanRequested(uint256 indexed loanId, address borrower, uint256 amount, uint256 repaymentDate, uint256 interest); // Event for loan request with loanId, borrower, amount, repaymentDate, interest as parameters - uint256, address, uint256, uint256, uint256 
    event GuaranteeProvided(uint256 indexed loanId, address guarantor, uint256 guarantorInterest); // Event for guarantee provided with loanId, guarantor, guarantorInterest as parameters - uint256, address, uint256
    event GuaranteeAccepted(uint256 indexed loanId); // Event for guarantee accepted with loanId as parameter - uint256 
    event GuaranteeRejected(uint256 indexed loanId); // Event for guarantee rejected with loanId as parameter - uint256 
    event LoanFunded(uint256 indexed loanId, address lender); // Event for loan funded with loanId, lender as parameters - uint256, address 
    event LoanRepaid(uint256 indexed loanId); // Event for loan repaid with loanId as parameter - uint256 
    event GuaranteeWithdrawn(uint256 indexed loanId); // Event for guarantee withdrawn with loanId as parameter - uint256

    function requestLoan(uint256 _amount, uint256 _repaymentDate, uint256 _interest) external { // Function to request loan with amount, repaymentDate, interest as parameters - uint256, uint256, uint256 
        require(_amount > 0, "Loan amount must be greater than 0"); // Require loan amount to be greater than 0. if condition is not met, show message - "Loan amount must be greater than 0" and revert.
        require(_repaymentDate > block.timestamp, "Repayment date must be in the future"); // Require repayment date to be in the future. If condition is not met, show message - "Repayment date must be in the future" and revert.
        require(_interest > 0, "Interest must be greater than 0"); // Require interest to be greater than 0. If condition is not met, show message - "Interest must be greater than 0" and revert.

        loanRequestCount++; // Increment loan request count by 1. 
        loanRequests[loanRequestCount] = LoanRequest({ // Add loan request to loanRequests mapping with loanId as key and LoanRequest as value.  
            borrower: payable(msg.sender), // Set borrower as sender of transaction - payable.
            amount: _amount, // Set amount as input parameter - _amount. 
            repaymentDate: _repaymentDate, // Set repaymentDate as input parameter - _repaymentDate. 
            interest: _interest, // Set interest as input parameter - _interest. 
            guarantor: payable(address(0)), // Set guarantor as address(0) - payable. 
            guarantorInterest: 0, // Set guarantorInterest as 0. 
            lender: payable(address(0)), // Set lender as address(0) - payable
            isActive: true, // Set isActive as true.
            isGuaranteed: false, // Set isGuaranteed as false. 
            isRepaid: false // Set isRepaid as false.
        });

        emit LoanRequested(loanRequestCount, msg.sender, _amount, _repaymentDate, _interest); // Emit LoanRequested event with loanId, borrower, amount, repaymentDate, interest as parameters.
    }

    function provideGuarantee(uint256 _loanId, uint256 _guarantorInterest) external payable { // Function to provide guarantee with loanId, guarantorInterest as parameters - uint256, uint256
        LoanRequest storage loan = loanRequests[_loanId]; // Get loan request with loanId from loanRequests mapping. 
        require(loan.isActive, "Loan request is not active"); // Require loan request to be active. If condition is not met, show message - "Loan request is not active" and revert.
        require(!loan.isGuaranteed, "Loan is already guaranteed"); // Require loan to not be guaranteed. If condition is not met, show message - "Loan is already guaranteed" and revert.
        require(msg.value == loan.amount, "Incorrect guarantee amount"); // Require guarantee amount to be equal to loan amount. If condition is not met, show message - "Incorrect guarantee amount" and revert.
        require(_guarantorInterest < loan.interest, "Guarantor interest cannot exceed total interest"); // Require guarantor interest to be less than total interest. If condition is not met, show message - "Guarantor interest cannot exceed total interest" and revert. 

        loan.guarantor = payable(msg.sender); // Set guarantor as sender of transaction - payable.
        loan.guarantorInterest = _guarantorInterest; // Set guarantorInterest as input parameter - _guarantorInterest.
        loan.isGuaranteed = true; // Set isGuaranteed as true.

        emit GuaranteeProvided(_loanId, msg.sender, _guarantorInterest); // Emit GuaranteeProvided event with loanId, guarantor, guarantorInterest as parameters. 
    }

    function acceptGuarantee(uint256 _loanId) external { // Function to accept guarantee with loanId as parameter - uint256. 
        LoanRequest storage loan = loanRequests[_loanId]; // Get loan request with loanId from loanRequests mapping.
        require(msg.sender == loan.borrower, "Only borrower can accept guarantee"); // Require sender of transaction to be borrower. If condition is not met, show message - "Only borrower can accept guarantee" and revert.
        require(loan.isGuaranteed, "No guarantee to accept"); // Require loan to be guaranteed. If condition is not met, show message - "No guarantee to accept" and revert.
        require(loan.isActive, "Loan request is not active"); // Require loan request to be active. If condition is not met, show message - "Loan request is not active" and revert.

        emit GuaranteeAccepted(_loanId);
    }

    function rejectGuarantee(uint256 _loanId) external { // Function to reject guarantee with loanId as parameter - uint256.
        LoanRequest storage loan = loanRequests[_loanId]; // Get loan request with loanId from loanRequests mapping.
        require(msg.sender == loan.borrower, "Only borrower can reject guarantee"); // Require sender of transaction to be borrower. If condition is not met, show message - "Only borrower can reject guarantee" and revert.
        require(loan.isGuaranteed, "No guarantee to reject"); // Require loan to be guaranteed. If condition is not met, show message - "No guarantee to reject" and revert.
        require(loan.isActive, "Loan request is not active"); // Require loan request to be active. If condition is not met, show message - "Loan request is not active" and revert.

        address payable guarantor = loan.guarantor; // Get guarantor address from loan request. 
        uint256 guaranteeAmount = loan.amount; // Get guarantee amount from loan request.

        loan.guarantor = payable(address(0)); // Set guarantor as address(0) - payable.
        loan.guarantorInterest = 0; // Set guarantorInterest as 0.
        loan.isGuaranteed = false; // Set isGuaranteed as false.

        guarantor.transfer(guaranteeAmount); // Transfer guarantee amount to guarantor. 

        emit GuaranteeRejected(_loanId); // Emit GuaranteeRejected event with loanId as parameter.
    }

    function provideLoan(uint256 _loanId) external payable { // Function to provide loan with loanId as parameter - uint256. 
        LoanRequest storage loan = loanRequests[_loanId]; // Get loan request with loanId from loanRequests mapping. 
        require(loan.isActive, "Loan request is not active"); // Require loan request to be active. If condition is not met, show message - "Loan request is not active" and revert.
        require(loan.isGuaranteed, "Loan must be guaranteed"); // Require loan to be guaranteed. If condition is not met, show message - "Loan must be guaranteed" and revert.
        require(msg.value == loan.amount, "Incorrect loan amount"); // Require loan amount to be equal to input value. If condition is not met, show message - "Incorrect loan amount" and revert.
        require(loan.lender == address(0), "Loan already funded"); // Require loan to not be funded. If condition is not met, show message - "Loan already funded" and revert.

        loan.lender = payable(msg.sender); // Set lender as sender of transaction - payable.
        loan.borrower.transfer(loan.amount); // Transfer loan amount to borrower. 

        emit LoanFunded(_loanId, msg.sender); // Emit LoanFunded event with loanId, lender as parameters.
    }

    function repayLoan(uint256 _loanId) external payable { // Function to repay loan with loanId as parameter - uint256. 
        LoanRequest storage loan = loanRequests[_loanId]; // Get loan request with loanId from loanRequests mapping.  
        require(msg.sender == loan.borrower, "Only borrower can repay loan"); // Require sender of transaction to be borrower. If condition is not met, show message - "Only borrower can repay loan" and revert.
        require(loan.lender != address(0), "Loan not yet funded"); // Require loan to be funded. If condition is not met, show message - "Loan not yet funded" and revert.
        require(!loan.isRepaid, "Loan already repaid"); // Require loan to not be repaid. If condition is not met, show message - "Loan already repaid" and revert.
        require(msg.value == loan.amount + loan.interest, "Incorrect repayment amount"); // Require repayment amount to be equal to loan amount + interest. If condition is not met, show message - "Incorrect repayment amount" and revert.

        loan.isRepaid = true; // Set isRepaid as true.
        loan.isActive = false; // Set isActive as false.

        loan.guarantor.transfer(loan.amount + loan.guarantorInterest); // Transfer loan amount + guarantor interest to guarantor.
        loan.lender.transfer(loan.amount + loan.interest - loan.guarantorInterest); // Transfer loan amount + interest - guarantor interest to lender.

        emit LoanRepaid(_loanId); // Emit LoanRepaid event with loanId as parameter.
    }

    function withdrawGuarantee(uint256 _loanId) external { // Function to withdraw guarantee with loanId as parameter - uint256.
        LoanRequest storage loan = loanRequests[_loanId]; // Get loan request with loanId from loanRequests mapping.
        require(msg.sender == loan.lender, "Only lender can withdraw guarantee"); // Require sender of transaction to be lender. If condition is not met, show message - "Only lender can withdraw guarantee" and revert.
        require(loan.lender != address(0), "Loan not yet funded"); // Require loan to be funded. If condition is not met, show message - "Loan not yet funded" and revert.
        require(!loan.isRepaid, "Loan already repaid"); // Require loan to not be repaid. If condition is not met, show message - "Loan already repaid" and revert.
        require(block.timestamp > loan.repaymentDate, "Repayment date not yet passed"); // Require repayment date to be passed. If condition is not met, show message - "Repayment date not yet passed" and revert.

        loan.isActive = false;  // Set isActive as false. 
        loan.lender.transfer(loan.amount); // Transfer loan amount to lender.

        emit GuaranteeWithdrawn(_loanId); // Emit GuaranteeWithdrawn event with loanId as parameter.
    }

    function getLoanDetails(uint256 _loanId) external view returns ( // Function to get loan details with loanId as parameter - uint256.
        address borrower, // Return borrower address - address
        uint256 amount, // Return amount - uint256
        uint256 repaymentDate, // Return repaymentDate - uint256
        uint256 interest, // Return interest - uint256
        address guarantor, // Return guarantor address - address
        uint256 guarantorInterest, // Return guarantorInterest - uint256
        address lender, // Return lender address - address
        bool isActive, // Return isActive - bool
        bool isGuaranteed, // Return isGuaranteed - bool
        bool isRepaid // Return isRepaid - bool
    ) {
        LoanRequest storage loan = loanRequests[_loanId]; // Get loan request with loanId from loanRequests mapping. 
        return ( // Return loan details.
            loan.borrower,
            loan.amount,
            loan.repaymentDate,
            loan.interest,
            loan.guarantor,
            loan.guarantorInterest,
            loan.lender,
            loan.isActive,
            loan.isGuaranteed,
            loan.isRepaid
        );
    }
}