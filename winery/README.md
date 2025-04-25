
## 🍷 Project Name: **Vintner's Vault**

*Tagline:* *Unlocking the Future of Fine Wine Investment through Decentralization*

---

## 📘 README

### Overview

**Vintner's Vault** is a decentralized platform built on the Stacks blockchain, designed to revolutionize the fine wine investment landscape. By leveraging smart contracts, it facilitates collaborative acquisition, authentication, and trading of fine wines. The platform empowers sommeliers and wine enthusiasts to participate in a transparent, secure, and community-driven ecosystem.

### Features

- **Sommelier Registration:** Wine experts can register by committing a certain level of expertise, gaining the ability to curate vintages and propose acquisitions.

- **Vintage Management:** Registered sommeliers can introduce new wine vintages, providing detailed information and provenance documentation.

- **Acquisition Proposals:** Community members can propose wine acquisitions for specific vintages, subject to appraisal and approval.

- **Appraisal System:** Acquisitions undergo a decentralized appraisal process, where registered sommeliers cast weighted votes based on their expertise.

- **Seasonal Investment Cycles:** The platform operates in investment seasons, allowing for periodic evaluation and progression of wine investments.

- **Governance:** A designated "Cellar Master" oversees critical functions, including activating the consortium, finalizing investment seasons, and managing thresholds.

### Smart Contract Structure

- **Constants:** Define error codes, thresholds, and limits to maintain contract integrity.

- **Data Variables:** Store global states such as the Cellar Master's address, consortium status, and investment season.

- **Maps:**
  - `wine-vintages`: Stores information about each registered vintage.
  - `vintage-sommeliers`: Tracks sommeliers associated with specific vintages and their committed expertise.
  - `sommelier-profiles`: Contains profiles of registered sommeliers, including their expertise and contributions.
  - `vintage-acquisitions`: Records proposed acquisitions for vintages.
  - `acquisition-appraisals`: Logs appraisals submitted by sommeliers for each acquisition.
  - `appraisal-tallies`: Aggregates appraisal results for acquisitions.

- **Functions:**
  - `activate-consortium`: Enables the consortium, allowing operations to commence.
  - `register-sommelier`: Allows users to register as sommeliers by committing expertise.
  - `register-vintage`: Enables sommeliers to register new wine vintages.
  - `propose-acquisition`: Allows proposals for acquiring specific wines under a vintage.
  - `appraise-acquisition`: Facilitates the appraisal process for proposed acquisitions.
  - `process-acquisition`: Finalizes acquisitions that meet approval thresholds.
  - `finalize-investment-season`: Advances the investment season, allowing for new cycles.
  - `set-vintage-acquisition-status`: Toggles the acquisition status of a vintage.
  - `update-minimum-expertise`: Adjusts the minimum expertise required for sommelier registration.
  - `update-acquisition-threshold`: Modifies the approval threshold for acquisitions.
  - `suspend-consortium`: Halts consortium operations.
  - `transfer-cellar-master-role`: Transfers the Cellar Master role to another principal.

### Getting Started

1. **Prerequisites:**
   - Install the Clarity development environment.
   - Set up a local Stacks blockchain instance or connect to a testnet.

2. **Deployment:**
   - Compile the smart contract using the Clarity compiler.
   - Deploy the contract to the desired Stacks network.

3. **Interaction:**
   - Use Clarity-compatible wallets or interfaces to interact with the contract functions.
   - Register as a sommelier, propose vintages, and participate in the appraisal process.

### Contribution

We welcome contributions from the community to enhance Vintner's Vault. To contribute:

1. Fork the repository.
2. Create a new branch for your feature or bugfix.
3. Commit your changes with clear messages.
4. Submit a pull request detailing your modifications.

Please ensure your code adheres to the project's coding standards and includes relevant tests.
