# Emergency Response Coordination

A blockchain-based disaster relief and resource allocation system built on Stacks blockchain using Clarity smart contracts.

## Features

- **Emergency Creation**: Register emergencies with severity levels and funding requirements
- **Resource Management**: Add and allocate resources for disaster response  
- **Donation System**: Secure STX donations with transparent fund tracking
- **Organization Registry**: Verified organizations for coordinated response
- **Fund Distribution**: Controlled fund distribution to recipients
- **Analytics**: Real-time statistics and funding progress tracking

## Contract Functions

### Emergency Management
- `create-emergency` - Register new emergency situations
- `update-emergency-status` - Update emergency response status
- `get-emergency` - Retrieve emergency details

### Resource Management
- `add-resource` - Add available resources
- `allocate-resource` - Allocate resources to emergencies
- `get-resource` - Get resource information

### Donation & Funding
- `donate-to-emergency` - Donate STX to emergency response
- `distribute-funds` - Distribute funds to recipients
- `get-donation` - Check donation details

### Organization Management
- `register-organization` - Register response organizations
- `verify-organization` - Verify organization credentials
- `update-reputation` - Update organization reputation

## Installation

1. Install Clarinet
2. Clone this repository
3. Run `clarinet test` to execute tests
4. Deploy using `clarinet deploy`

## Usage

This contract enables transparent, blockchain-based emergency response coordination with secure fund management and resource allocation capabilities.

## License

MIT License
