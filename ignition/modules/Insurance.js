const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules")

const InsuranceModule = buildModule("InsuranceModule", (m) => {
    const currency = m.getParameter("currency", "0x0000000000000000000000000000000000000000")
    const flightVerifier = m.getParameter("flightVerifier", "0x0000000000000000000000000000000000000000")

    const insurance = m.contract("Insurance", [currency, flightVerifier])

    return { insurance }
})

module.exports = InsuranceModule