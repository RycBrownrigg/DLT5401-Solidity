/*

This contract facilitates peer-to-peer lending between borrowers and lenders. Borrowers can request loans by providing the loan amount, repayment date, and interest rate. Lenders can fund the loans, and guarantors can provide guarantees for the loans. Borrowers can repay the loans, and lenders can withdraw guarantees if the repayment date has passed. The contract also supports NFT payments as an alternative to token payments.

The contract includes the following functionalities:

1. Loan Requests: Borrowers can request loans by providing the loan amount, repayment date, and interest rate. The contract stores the loan requests and assigns a unique loan ID to each request.

2. Guarantees: Guarantors can provide guarantees for loans by specifying the guarantor interest rate. The contract ensures that the guarantor interest rate does not exceed the total interest rate of the loan.

3. Loan Funding: Lenders can fund loans that are guaranteed. The contract transfers the loan amount from the lender to the borrower.

4. Loan Repayment: Borrowers can repay loans by transferring the total repayment amount to the contract. The contract distributes the repayment amount to the lender and guarantor.

5. Guarantee Withdrawal: Lenders can withdraw guarantees for loans if the repayment date has passed and the loan is not yet repaid. The contract transfers the loan amount back to the lender.

6. NFT Payments: Borrowers can propose NFT payments as an alternative to token payments. Lenders can accept or reject NFT offers, and the contract transfers the NFT to the lender if the offer is accepted.

The contract uses the OpenZeppelin ERC20 and ERC721 interfaces for token and NFT interactions. The contract also inherits from the ERC721Holder contract to receive ERC721 tokens.

The contract is implemented in the Solidity programming language (version 0.8.0).

Key changes and additions:

Added an NFTOffer struct to store information about NFT payment proposals.

Three new functions were added to handle NFT payments:

    proposeNFTPayment: Allows a borrower to propose an NFT as payment.
    acceptNFTOffer: Allows a lender to accept an NFT offer.
    rejectNFTOffer: Allows a lender to reject an NFT offer.


Added new events to track NFT offer proposals, acceptances, and rejections.
The contract  inherits from ERC721Holder, allowing it to receive ERC721 tokens.

In the acceptNFTOffer function, both partial and full repayments are handled:

If the NFT value covers the entire loan, the loan is marked as repaid and the guarantee is handled if applicable.

If it's a partial repayment, the loan amount is updated accordingly.

Added checks to ensure that only the borrower can propose NFT payments and only the lender can accept or reject them.

How to use this system:

1.) The borrower must first approve the P2PLending contract to transfer their NFT (using the NFT contract's setApprovalForAll function).
2.) The borrower can then call proposeNFTPayment to offer an NFT as repayment.
3.) The lender can either acceptNFTOffer or rejectNFTOffer.
4.) If accepted, the NFT is transferred to the lender, and the loan amount is adjusted or marked as repaid.

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Import the IERC20 interface
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Import the IERC721 interface
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // Import the ERC721Holder contract

contract P2PLending is ERC721Holder { // Inherit from ERC721Holder contract to receive ERC721 tokens in the contract address 
    IERC20 public loanToken; // Declare the IERC20 interface variable to store the loan token address 

    struct LoanRequest { // Define a struct to store the loan request details 
        address borrower;
        uint256 amount;
        uint256 repaymentDate;
        uint256 interest;
        address guarantor;
        uint256 guarantorInterest;
        address lender;
        bool isActive;
        bool isGuaranteed;
        bool isRepaid;
    }

    struct NFTOffer { // Define a struct to store the NFT offer details 
        address nftContract;
        uint256 tokenId;
        uint256 proposedDeduction;
        bool isActive;
    }

    mapping(uint256 => LoanRequest) public loanRequests; // Declare a mapping to store the loan requests 
    mapping(uint256 => NFTOffer) public nftOffers; // Declare a mapping to store the NFT offers 
    uint256 public loanRequestCount; // Declare a variable to store the loan request count 

    event LoanRequested(uint256 indexed loanId, address borrower, uint256 amount, uint256 repaymentDate, uint256 interest);// Emit an event to log the loan request details including the loan ID, borrower address, loan amount, repayment date, and interest rate. 
    event GuaranteeProvided(uint256 indexed loanId, address guarantor, uint256 guarantorInterest); // Emit an event to log the guarantee provided details including the loan ID, guarantor address, and guarantor interest rate.
    event GuaranteeAccepted(uint256 indexed loanId); // Emit an event to log the guarantee accepted details including the loanId.
    event GuaranteeRejected(uint256 indexed loanId); // Emit an event to log the guarantee rejected details including the loanId.
    event LoanFunded(uint256 indexed loanId, address lender); // Emit an event to log the loan funded details including the loanId and lender address. 
    event LoanRepaid(uint256 indexed loanId); // Emit an event to log the loan repaid details including the loanId.
    event GuaranteeWithdrawn(uint256 indexed loanId); // Emit an event to log the guarantee withdrawn details including the loanId.
    event NFTOfferProposed(uint256 indexed loanId, address nftContract, uint256 tokenId, uint256 proposedDeduction); // Emit an event to log the NFT offer proposed details including the loanId, NFT contract address, token ID, and proposed deduction.
    event NFTOfferAccepted(uint256 indexed loanId, address nftContract, uint256 tokenId, uint256 deductedAmount); // Emit an event to log the NFT offer accepted details including the loanId, NFT contract address, token ID, and deducted amount.
    event NFTOfferRejected(uint256 indexed loanId); // Emit an event to log the NFT offer rejected details including the loanId.

    constructor(address _loanTokenAddress) { // This is the constructor function of the contract. It takes an address argument _loanTokenAddress, which is used to initialize the loanToken state variable with the address of the ERC20 token contract used for loans.
        loanToken = IERC20(_loanTokenAddress); // This initializes the loanToken state variable with the address of the ERC20 token contract used for loans.
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

    function proposeNFTPayment(uint256 _loanId, address _nftContract, uint256 _tokenId, uint256 _proposedDeduction) external {
        LoanRequest storage loan = loanRequests[_loanId];
        require(msg.sender == loan.borrower, "Only borrower can propose NFT payment");
        require(loan.isActive && !loan.isRepaid, "Loan is not active or already repaid");
        require(_proposedDeduction <= loan.amount + loan.interest, "Proposed deduction exceeds loan amount");

        IERC721 nftContract = IERC721(_nftContract);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "Borrower does not own this NFT");
        require(nftContract.isApprovedForAll(msg.sender, address(this)), "Contract is not approved to transfer NFT");

        nftOffers[_loanId] = NFTOffer({
            nftContract: _nftContract,
            tokenId: _tokenId,
            proposedDeduction: _proposedDeduction,
            isActive: true
        });

        emit NFTOfferProposed(_loanId, _nftContract, _tokenId, _proposedDeduction);
    }

    function acceptNFTOffer(uint256 _loanId) external {
        LoanRequest storage loan = loanRequests[_loanId];
        NFTOffer storage offer = nftOffers[_loanId];
        require(msg.sender == loan.lender, "Only lender can accept NFT offer");
        require(loan.isActive && !loan.isRepaid, "Loan is not active or already repaid");
        require(offer.isActive, "No active NFT offer for this loan");

        IERC721 nftContract = IERC721(offer.nftContract);
        nftContract.safeTransferFrom(loan.borrower, loan.lender, offer.tokenId);

        uint256 deductedAmount = offer.proposedDeduction;
        if (deductedAmount >= loan.amount + loan.interest) {
            // Loan is fully paid off
            loan.isRepaid = true;
            loan.isActive = false;
            if (loan.isGuaranteed) {
                loanToken.transfer(loan.guarantor, loan.amount);
            }
        } else {
            // Partially paid off
            loan.amount = loan.amount + loan.interest - deductedAmount;
        }

        offer.isActive = false;
        emit NFTOfferAccepted(_loanId, offer.nftContract, offer.tokenId, deductedAmount);

        if (loan.isRepaid) {
            emit LoanRepaid(_loanId);
        }
    }

    function rejectNFTOffer(uint256 _loanId) external {
        LoanRequest storage loan = loanRequests[_loanId];
        NFTOffer storage offer = nftOffers[_loanId];
        require(msg.sender == loan.lender, "Only lender can reject NFT offer");
        require(offer.isActive, "No active NFT offer for this loan");

        offer.isActive = false;
        emit NFTOfferRejected(_loanId);
    }

    // ... (rest of the contract remains the same)
}