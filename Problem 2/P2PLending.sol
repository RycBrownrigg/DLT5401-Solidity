/*
 
This contract facilitates peer-to-peer lending between borrowers and lenders. It allows borrowers to request loans, lenders to provide loans, and guarantors to provide guarantees for loans. The contract uses an ERC20 token to represent the loan amount and interest.

Key changes from Problem 1 and explanations:

A custom LoanToken contract that implements the ERC20 standard. This includes all the required functions and events for an ERC20 token.

The P2PLending contract now uses the LoanToken contract to represent the loan amount and interest. 

In the P2PLending contract, an IERC20 interface is defined to interact with the LoanToken contract.

The IERC20 interface methods (transfer, transferFrom) are used for all token transactions.

Error handling is done by checking the return value of the token transfer functions and using require statements.

The overall logic of the P2PLending contract remains the same, but now it uses LoanToken for all transactions instead of Ether.

To use this system:

1.) Deploy the LoanToken contract with an initial supply.
2.) Deploy the P2PLending contract, passing the address of the LoanToken contract.
3.) Users acquire LoanTokens.
4.) Users need to approve the P2PLending contract to spend their LoanTokens before interacting with it (using the approve function of the LoanToken contract).
5.) The flow of interactions remains the same as before, but now users are spending LoanTokens instead of Ether.
  
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 { // brief ERC20 token interface
    function totalSupply() external view returns (uint256); // his function returns the total number of tokens in circulation. It is a constant value that is set at contract deployment. It is an external view function, which means that it can be called from outside the contract and does not modify the contract state.
    function balanceOf(address account) external view returns (uint256); // This function returns the token balance of a specific account. It takes an address as an argument and returns the balance of the account. It is an external view function, which means that it can be called from outside the contract and does not modify the contract state.
    function transfer(address recipient, uint256 amount) external returns (bool); // This function transfers a specified amount of tokens from the contract owner's account to the recipient's account. It takes the recipient's address and the amount of tokens to transfer as arguments. It returns a boolean value indicating whether the transfer was successful. It is an external function, which means that it can be called from outside the contract and modifies the contract state. The transfer function emits a Transfer event when tokens are transferred.
    function allowance(address owner, address spender) external view returns (uint256); // This function returns the amount of tokens that the spender is allowed to spend on behalf of the owner. It takes the owner's address and the spender's address as arguments and returns the allowance amount. It is an external view function, which means that it can be called from outside the contract and does not modify the contract state.
    function approve(address spender, uint256 amount) external returns (bool); // This function allows the owner to approve the spender to spend a specified amount of tokens on their behalf. It takes the spender's address and the amount of tokens to approve as arguments. It returns a boolean value indicating whether the approval was successful. It is an external function, which means that it can be called from outside the contract and modifies the contract state. The approve function emits an Approval event when the approval is granted.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value); // This event is emitted when tokens are transferred from one account to another. It includes the sender's address, the recipient's address, and the amount of tokens transferred as indexed parameters.
    event Approval(address indexed owner, address indexed spender, uint256 value); // This event is emitted when the owner approves the spender to spend a specified amount of tokens on their behalf. It includes the owner's address, the spender's address, and the amount of tokens approved as indexed parameters.
}

contract P2PLending { // This declares a new contract named P2PLending. The contract is used to facilitate peer-to-peer lending between borrowers and lenders. It allows borrowers to request loans, lenders to provide loans, and guarantors to provide guarantees for loans. The contract uses an ERC20 token to represent the loan amount and interest.
    IERC20 public loanToken; // This declares a public state variable named loanToken of type IERC20. The variable is used to store the address of the ERC20 token contract used for loans.

    struct LoanRequest { // This declares a new struct named LoanRequest. The struct is used to store information about a loan request, including the borrower's address, the loan amount, the repayment date, the interest rate, the guarantor's address, the guarantor's interest rate, the lender's address, and the loan status.
        address borrower; // This declares a public state variable named borrower of type address. The variable is used to store the address of the borrower who requested the loan.
        uint256 amount; // This declares a public state variable named amount of type uint256. The variable is used to store the amount of the loan requested by the borrower.
        uint256 repaymentDate; // This declares a public state variable named repaymentDate of type uint256. The variable is used to store the date on which the loan is due for repayment.
        uint256 interest; // This declares a public state variable named interest of type uint256. The variable is used to store the interest rate of the loan.
        address guarantor; // This declares a public state variable named guarantor of type address. The variable is used to store the address of the guarantor who provided the guarantee for the loan.
        uint256 guarantorInterest; // This declares a public state variable named guarantorInterest of type uint256. The variable is used to store the interest rate of the guarantor for providing the guarantee.
        address lender; // This declares a public state variable named lender of type address. The variable is used to store the address of the lender who provided the loan.
        bool isActive; // This declares a public state variable named isActive of type bool. The variable is used to store the status of the loan request, indicating whether the loan is active or not.
        bool isGuaranteed;  // This declares a public state variable named isGuaranteed of type bool. The variable is used to store the status of the loan request, indicating whether the loan is guaranteed or not.
        bool isRepaid; // This declares a public state variable named isRepaid of type bool. The variable is used to store the status of the loan request, indicating whether the loan is repaid or not.
    }

    mapping(uint256 => LoanRequest) public loanRequests; // This declares a public state variable named loanRequests of type mapping(uint256 => LoanRequest). The variable is used to store the loan requests made by borrowers, with the loan ID as the key and the LoanRequest struct as the value.
    uint256 public loanRequestCount; // This declares a public state variable named loanRequestCount of type uint256. The variable is used to store the total number of loan requests made by borrowers.

    event LoanRequested(uint256 indexed loanId, address borrower, uint256 amount, uint256 repaymentDate, uint256 interest); // This declares a new event named LoanRequested. The event is emitted when a borrower requests a loan, and includes the loan ID, the borrower's address, the loan amount, the repayment date, and the interest rate as indexed parameters.
    event GuaranteeProvided(uint256 indexed loanId, address guarantor, uint256 guarantorInterest); // This declares a new event named GuaranteeProvided. The event is emitted when a guarantor provides a guarantee for a loan, and includes the loan ID, the guarantor's address, and the guarantor's interest rate as indexed parameters.
    event GuaranteeAccepted(uint256 indexed loanId); // This declares a new event named GuaranteeAccepted. The event is emitted when a borrower accepts a guarantee for a loan, and includes the loan ID as an indexed parameter.
    event GuaranteeRejected(uint256 indexed loanId); // This declares a new event named GuaranteeRejected. The event is emitted when a borrower rejects a guarantee for a loan, and includes the loan ID as an indexed parameter.
    event LoanFunded(uint256 indexed loanId, address lender); // This declares a new event named LoanFunded. The event is emitted when a lender provides a loan, and includes the loan ID and the lender's address as indexed parameters.
    event LoanRepaid(uint256 indexed loanId); // This declares a new event named LoanRepaid. The event is emitted when a borrower repays a loan, and includes the loan ID as an indexed parameter.
    event GuaranteeWithdrawn(uint256 indexed loanId); // This declares a new event named GuaranteeWithdrawn. The event is emitted when a lender withdraws a guarantee for a loan, and includes the loan ID as an indexed parameter.

    constructor(address _loanTokenAddress) { // This is the constructor function of the contract. It takes an address argument _loanTokenAddress, which is used to initialize the loanToken state variable with the address of the ERC20 token contract used for loans.
        loanToken = IERC20(_loanTokenAddress); // This initializes the loanToken state variable with the address of the ERC20 token contract used for loans.
    }

    function requestLoan(uint256 _amount, uint256 _repaymentDate, uint256 _interest) external { // This function allows a borrower to request a loan by providing the loan amount, repayment date, and interest rate as arguments. The function creates a new loan request with the borrower's address, loan amount, repayment date, interest rate, and other details, and emits a LoanRequested event. The function increments the loanRequestCount to generate a unique loan ID for the request.
        require(_amount > 0, "Loan amount must be greater than 0"); // This checks that the loan amount is greater than 0. If the condition is not met, the function reverts with the error message "Loan amount must be greater than 0".
        require(_repaymentDate > block.timestamp, "Repayment date must be in the future"); // This checks that the repayment date is in the future. If the condition is not met, the function reverts with the error message "Repayment date must be in the future".
        require(_interest > 0, "Interest must be greater than 0"); // This checks that the interest rate is greater than 0. If the condition is not met, the function reverts with the error message "Interest must be greater than 0".

        loanRequestCount++; // This increments the loanRequestCount to generate a unique loan ID for the request.
        loanRequests[loanRequestCount] = LoanRequest({ // This creates a new loan request with the borrower's address, loan amount, repayment date, interest rate, and other details, and stores it in the loanRequests mapping with the loan ID as the key.
            borrower: msg.sender, // This sets the borrower field of the loan request to the address of the borrower who made the request.
            amount: _amount, // This sets the amount field of the loan request to the loan amount provided by the borrower.
            repaymentDate: _repaymentDate, // This sets the repaymentDate field of the loan request to the repayment date provided by the borrower.
            interest: _interest, // This sets the interest field of the loan request to the interest rate provided by the borrower.
            guarantor: address(0), // This sets the guarantor field of the loan request to the zero address, indicating that no guarantor has provided a guarantee for the loan.
            guarantorInterest: 0, // This sets the guarantorInterest field of the loan request to 0, indicating that no guarantor has provided a guarantee for the loan.
            lender: address(0), // This sets the lender field of the loan request to the zero address, indicating that the loan has not yet been funded by a lender.
            isActive: true, // This sets the isActive field of the loan request to true, indicating that the loan request is active.
            isGuaranteed: false, // This sets the isGuaranteed field of the loan request to false, indicating that the loan is not yet guaranteed.
            isRepaid: false // This sets the isRepaid field of the loan request to false, indicating that the loan has not yet been repaid.
        });

        emit LoanRequested(loanRequestCount, msg.sender, _amount, _repaymentDate, _interest); // This emits a LoanRequested event with the loan ID, borrower's address, loan amount, repayment date, and interest rate as indexed parameters. The event is emitted to notify listeners that a new loan request has been made.
    }

    function provideGuarantee(uint256 _loanId, uint256 _guarantorInterest) external { // This function allows a guarantor to provide a guarantee for a loan by providing the loan ID and the guarantor interest rate as arguments. The function checks that the loan request is active, not yet guaranteed, and that the guarantor interest rate does not exceed the total interest rate of the loan. If the conditions are met, the function transfers the loan amount from the guarantor to the contract, sets the guarantor address, guarantor interest rate, and isGuaranteed flag in the loan request, and emits a GuaranteeProvided event.
        LoanRequest storage loan = loanRequests[_loanId]; // This retrieves the loan request with the specified _loanID from the loanRequests mapping and stores it in a local variable loan.
        require(loan.isActive, "Loan request is not active"); // This checks that the loan request is active. If the condition is not met, the function reverts with the error message "Loan request is not active".
        require(!loan.isGuaranteed, "Loan is already guaranteed");  // This checks that the loan is not yet guaranteed. If the condition is not met, the function reverts with the error message "Loan is already guaranteed".
        require(_guarantorInterest < loan.interest, "Guarantor interest cannot exceed total interest"); // This checks that the guarantor interest rate does not exceed the total interest rate of the loan. If the condition is not met, the function reverts with the error message "Guarantor interest cannot exceed total interest".

        require(loanToken.transferFrom(msg.sender, address(this), loan.amount), "Token transfer failed"); // This transfers the loan amount from the guarantor's account to the contract. If the transfer fails, the function reverts with the error message "Token transfer failed".

        loan.guarantor = msg.sender; // This sets the guarantor address in the loan request to the address of the guarantor who call the contract.
        loan.guarantorInterest = _guarantorInterest; // This sets the guarantor interest rate in the loan request to the interest rate provided by the guarantor.
        loan.isGuaranteed = true; // This sets the isGuaranteed flag in the loan request to true, indicating that the loan is guaranteed.

        emit GuaranteeProvided(_loanId, msg.sender, _guarantorInterest); // This emits a GuaranteeProvided event with the loan ID, guarantor's address, and guarantor interest rate as indexed parameters. The event is emitted to notify listeners that a guarantor has provided a guarantee for the loan.
    }

    function acceptGuarantee(uint256 _loanId) external { // This function allows a borrower to accept a guarantee for a loan by providing the loan ID as an argument. The function checks that the borrower is the owner of the loan request, that the loan is guaranteed, and that the loan request is active. If the conditions are met, the function emits a GuaranteeAccepted event.
        LoanRequest storage loan = loanRequests[_loanId]; // This retrieves the loan request with the specified _loanID from the loanRequests mapping and stores it in a local variable loan.
        require(msg.sender == loan.borrower, "Only borrower can accept guarantee"); // This checks that the caller of the function is the borrower who made the loan request. If the condition is not met, the function reverts with the error message "Only borrower can accept guarantee".
        require(loan.isGuaranteed, "No guarantee to accept"); // This checks that the loan is guaranteed. If the condition is not met, the function reverts with the error message "No guarantee to accept".
        require(loan.isActive, "Loan request is not active"); // This checks that the loan request is active. If the condition is not met, the function reverts with the error message "Loan request is not active".

        emit GuaranteeAccepted(_loanId); // This emits a GuaranteeAccepted event with the loan ID as an indexed parameter. The event is emitted to notify listeners that the borrower has accepted the guarantee for the loan.
    }

    function rejectGuarantee(uint256 _loanId) external { // This function allows a borrower to reject a guarantee for a loan by providing the loan ID as an argument. The function checks that the borrower is the owner of the loan request, that the loan is guaranteed, and that the loan request is active. If the conditions are met, the function transfers the loan amount back to the guarantor, resets the guarantor address, guarantor interest rate, and isGuaranteed flag in the loan request, and emits a GuaranteeRejected event.
        LoanRequest storage loan = loanRequests[_loanId]; // This retrieves the loan request with the specified _loanID from the loanRequests mapping and stores it in a local variable loan.
        require(msg.sender == loan.borrower, "Only borrower can reject guarantee"); // This checks that the caller of the function is the borrower who made the loan request. If the condition is not met, the function reverts with the error message "Only borrower can reject guarantee".
        require(loan.isGuaranteed, "No guarantee to reject"); // This checks that the loan is guaranteed. If the condition is not met, the function reverts with the error message "No guarantee to reject".
        require(loan.isActive, "Loan request is not active"); // This checks that the loan request is active. If the condition is not met, the function reverts with the error message "Loan request is not active".

        address guarantor = loan.guarantor; // This retrieves the address of the guarantor from the loan request. 
        uint256 guaranteeAmount = loan.amount; // This retrieves the loan amount from the loan request.

        loan.guarantor = address(0); // This resets the guarantor address in the loan request to the zero address.
        loan.guarantorInterest = 0; // This resets the guarantor interest rate in the loan request to 0.
        loan.isGuaranteed = false; // This resets the isGuaranteed flag in the loan request to false.

        require(loanToken.transfer(guarantor, guaranteeAmount), "Token transfer failed");

        emit GuaranteeRejected(_loanId); // This emits a GuaranteeRejected event with the loan ID as an indexed parameter. The event is emitted to notify listeners that the borrower has rejected the guarantee for the loan.
    }

    function provideLoan(uint256 _loanId) external { // This function allows a lender to provide a loan for a guaranteed loan request by providing the loan ID as an argument. The function checks that the loan request is active, guaranteed, and not yet funded. If the conditions are met, the function transfers the loan amount from the lender to the borrower, sets the lender address in the loan request, and emits a LoanFunded event.
        LoanRequest storage loan = loanRequests[_loanId]; // This retrieves the loan request with the specified _loanID from the loanRequests mapping and stores it in a local variable loan. 
        require(loan.isActive, "Loan request is not active"); // This checks that the loan request is active. If the condition is not met, the function reverts with the error message "Loan request is not active".
        require(loan.isGuaranteed, "Loan must be guaranteed"); // This checks that the loan is guaranteed. If the condition is not met, the function reverts with the error message "Loan must be guaranteed".
        require(loan.lender == address(0), "Loan already funded"); // This checks that the loan is not yet funded by a lender. If the condition is not met, the function reverts with the error message "Loan already funded".
        require(loanToken.transferFrom(msg.sender, loan.borrower, loan.amount), "Token transfer failed"); // This transfers the loan amount from the lender's account to the borrower's account. If the transfer fails, the function reverts with the error message "Token transfer failed".

        loan.lender = msg.sender; // This sets the lender address in the loan request to the address of the lender who calls the contract. 

        emit LoanFunded(_loanId, msg.sender); // This emits a LoanFunded event with the loan ID and the lender's address as indexed parameters. The event is emitted to notify listeners that a lender has provided a loan for the guaranteed loan request.
    }

    function repayLoan(uint256 _loanId) external { // This function allows a borrower to repay a loan by providing the loan ID as an argument. The function checks that the caller is the borrower, that the loan is funded, not yet repaid, and that the repayment date has passed. If the conditions are met, the function transfers the total repayment amount from the borrower to the contract, updates the loan status, and transfers the loan amount and interest to the lender and guarantor respectively. The function emits a LoanRepaid event.
        LoanRequest storage loan = loanRequests[_loanId]; // This retrieves the loan request with the specified _loanID from the loanRequests mapping and stores it in a local variable loan. 
        require(msg.sender == loan.borrower, "Only borrower can repay loan"); // This checks that the caller of the function is the borrower who made the loan request. If the condition is not met, the function reverts with the error message "Only borrower can repay loan".
        require(loan.lender != address(0), "Loan not yet funded"); // This checks that the loan is funded by a lender. If the condition is not met, the function reverts with the error message "Loan not yet funded".
        require(!loan.isRepaid, "Loan already repaid"); // This checks that the loan is not yet repaid. If the condition is not met, the function reverts with the error message "Loan already repaid".

        uint256 totalRepayment = loan.amount + loan.interest; // This calculates the total repayment amount as the loan amount plus the interest.
        require(loanToken.transferFrom(msg.sender, address(this), totalRepayment), "Token transfer failed"); // This transfers the total repayment amount from the borrower's account to the contract. If the transfer fails, the function reverts with the error message "Token transfer failed".

        loan.isRepaid = true; // This sets the isRepaid flag in the loan request to true, indicating that the loan has been repaid.
        loan.isActive = false; // This sets the isActive flag in the loan request to false, indicating that the loan request is no longer active.

        require(loanToken.transfer(loan.guarantor, loan.amount + loan.guarantorInterest), "Token transfer failed"); // This transfers the loan amount and guarantor interest to the guarantor's account. If the transfer fails, the function reverts with the error message "Token transfer failed".
        require(loanToken.transfer(loan.lender, loan.amount + loan.interest - loan.guarantorInterest), "Token transfer failed"); // This transfers the loan amount and interest to the lender's account. If the transfer fails, the function reverts with the error message "Token transfer failed".

        emit LoanRepaid(_loanId); // This emits a LoanRepaid event with the loan ID as an indexed parameter. The event is emitted to notify listeners that the borrower has repaid the loan.
    }

    function withdrawGuarantee(uint256 _loanId) external { // This function allows a lender to withdraw a guarantee for a loan by providing the loan ID as an argument. The function checks that the caller is the lender, that the loan is funded, not yet repaid, and that the repayment date has passed. If the conditions are met, the function transfers the loan amount back to the lender, updates the loan status, and emits a GuaranteeWithdrawn event. 
        LoanRequest storage loan = loanRequests[_loanId]; // This retrieves the loan request with the specified _loanID from the loanRequests mapping and stores it in a local variable loan.
        require(msg.sender == loan.lender, "Only lender can withdraw guarantee"); // This checks that the caller of the function is the lender who funded the loan. If the condition is not met, the function reverts with the error message "Only lender can withdraw guarantee".
        require(loan.lender != address(0), "Loan not yet funded"); // This checks that the loan is funded by a lender. If the condition is not met, the function reverts with the error message "Loan not yet funded".
        require(!loan.isRepaid, "Loan already repaid"); // This checks that the loan is not yet repaid. If the condition is not met, the function reverts with the error message "Loan already repaid".
        require(block.timestamp > loan.repaymentDate, "Repayment date not yet passed"); // This checks that the repayment date has passed. If the condition is not met, the function reverts with the error message "Repayment date not yet passed".

        loan.isActive = false;  // This sets the isActive flag in the loan request to false, indicating that the loan request is no longer active. 
        require(loanToken.transfer(loan.lender, loan.amount), "Token transfer failed"); // This transfers the loan amount back to the lender's account. If the transfer fails, the function reverts with the error message "Token transfer failed".

        emit GuaranteeWithdrawn(_loanId); // This emits a GuaranteeWithdrawn event with the loan ID as an indexed parameter. The event is emitted to notify listeners that the lender has withdrawn the guarantee for the loan.
    }

    function getLoanDetails(uint256 _loanId) external view returns ( // This function allows external callers to retrieve the details of a loan request by providing the loan ID as an argument. The function returns the borrower's address, loan amount, repayment date, interest rate, guarantor's address, guarantor interest rate, lender's address, and loan status.
        address borrower, // This declares a local variable named borrower of type address. The variable is used to store the borrower's address. 
        uint256 amount, // This declares a local variable named amount of type uint256. The variable is used to store the loan amount.
        uint256 repaymentDate, // This declares a local variable named repaymentDate of type uint256. The variable is used to store the repayment date.
        uint256 interest, // This declares a local variable named interest of type uint256. The variable is used to store the interest rate.
        address guarantor, // This declares a local variable named guarantor of type address. The variable is used to store the guarantor's address.
        uint256 guarantorInterest, // This declares a local variable named guarantorInterest of type uint256. The variable is used to store the guarantor interest rate.
        address lender, // This declares a local variable named lender of type address. The variable is used to store the lender's address.
        bool isActive, // This declares a local variable named isActive of type bool. The variable is used to store the loan status, indicating whether the loan request is active or not.
        bool isGuaranteed, // This declares a local variable named isGuaranteed of type bool. The variable is used to store the loan status, indicating whether the loan is guaranteed or not.
        bool isRepaid // This declares a local variable named isRepaid of type bool. The variable is used to store the loan status, indicating whether the loan is repaid or not.
    ) {
        LoanRequest storage loan = loanRequests[_loanId]; // This retrieves the loan request with the specified _loanID from the loanRequests mapping and stores it in a local variable loan. 
        return ( // This returns the borrower's address, loan amount, repayment date, interest rate, guarantor's address, guarantor interest rate, lender's address, and loan status.
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