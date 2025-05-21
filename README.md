# Secureblock Smart Contract

## Overview
Secureblock is a decentralized financial aid management system built on the Stacks blockchain. This smart contract enables secure, transparent fundraising and distribution of funds to verified beneficiaries, making it ideal for humanitarian aid, disaster relief, charitable organizations, and community support initiatives.

## Key Features

- **Secure Fund Collection**: Accept STX donations from donors with minimum contribution thresholds
- **Verified Beneficiary Management**: Register and manage approved fund recipients 
- **Transparent Fund Distribution**: Track all disbursements on the blockchain
- **Emergency Controls**: Toggle operational status and activate emergency mode when needed
- **Administrative Controls**: Transfer admin rights and update beneficiary states

## Contract Structure

### Core Variables
- `treasury-admin`: Principal address managing the contract
- `treasury-balance`: Current balance of STX in the contract
- `treasury-operational`: Boolean indicating if the contract is accepting contributions
- `treasury-min-contribution`: Minimum donation amount (default: 1 STX)
- `treasury-emergency-mode`: Boolean for emergency operations pause

### Data Maps
- `beneficiaries`: Tracks all registered aid recipients and their details
- `donors`: Records all contributors and their donation history

## Public Functions

### For Donors
- **donate()**: Contribute STX to the treasury

### For Administrators
- **register-beneficiary(entity)**: Add a new approved beneficiary
- **disburse-funds(entity, amount)**: Send funds to a beneficiary
- **set-min-contribution(new-min)**: Update minimum donation threshold
- **toggle-treasury-status()**: Enable/disable contributions
- **enable-emergency-mode()**: Activate emergency operations pause
- **disable-emergency-mode()**: Deactivate emergency operations pause
- **update-beneficiary-state(entity, state)**: Change a beneficiary's status
- **transfer-admin-rights(new-admin)**: Transfer administration control

### Read-Only Functions
- **get-admin()**: Returns current administrator
- **get-treasury-balance()**: Returns current contract balance
- **get-beneficiary-data(entity)**: Get details about a beneficiary
- **get-donor-data(entity)**: Get details about a donor
- **is-treasury-active()**: Check if the contract is operational

## Error Codes
- **ERR-UNAUTHORIZED (u100)**: Caller is not the admin
- **ERR-BENEFICIARY-EXISTS (u101)**: Beneficiary already registered
- **ERR-BENEFICIARY-NOT-FOUND (u102)**: Beneficiary does not exist
- **ERR-INSUFFICIENT-TREASURY-FUNDS (u103)**: Not enough funds for disbursement
- **ERR-CONTRIBUTION-TOO-SMALL (u104)**: Donation below minimum threshold
- **ERR-TREASURY-INACTIVE (u105)**: Contract is not accepting transactions
- **ERR-INVALID-VALUE (u106)**: Amount invalid or out of range
- **ERR-INVALID-STATE (u107)**: Invalid beneficiary status value
- **ERR-INVALID-ADMIN (u108)**: Invalid admin address

## Beneficiary States
Beneficiaries can have the following states:
- **active**: Currently eligible to receive funds
- **pending**: Registration in process, not yet eligible
- **suspended**: Temporarily ineligible for distributions
- **completed**: Aid program completed, no longer eligible

## Usage Example

```clarity
;; Deploy the contract (handled by deployment process)

;; As admin, register a new beneficiary
(contract-call? .secureblock register-beneficiary 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; As a donor, make a contribution
(contract-call? .secureblock donate)

;; As admin, distribute funds to a beneficiary
(contract-call? .secureblock disburse-funds 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM u5000000)
```

## Security Considerations

- Only the designated administrator can register beneficiaries and distribute funds
- Crisis mode can immediately halt all operations in case of emergency
- Minimum contribution threshold helps prevent spam transactions
- Disbursement can only occur if sufficient funds are available

## Development and Testing

To deploy and test this contract:

1. Install the Clarinet development environment
2. Clone this repository
3. Run `clarinet console` to interact with the contract
4. Use the test suite to verify functionality
