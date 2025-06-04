const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules")

const InsuranceModule = buildModule("InsuranceModule", (m) => {
    const currency = m.getParameter("_currency", "0xC21C311b7FabEb355e8BE695bE0ad2e1B89b8c7B")

    const insurance = m.contract("Insurance", [currency])

    return { insurance }
})

module.exports = InsuranceModule