import { promises as fs } from "fs";

async function parseFile(file) {
  const output = await fs.readFile(file, { encoding: "utf8" });

  const lines = output.split("\n").map((line) => line.trim());

  let lastID = 0;
  const validators = [];
  let validator = {};
  for (const line of lines) {
    let [key, value] = line.split(" ");
    validator[key] = value;
    if (key == "id" && value != lastID) {
      validators.push(validator);
      lastID = value;
      validator = {};
    }
  }

  return validators;
}

function countMinters(validators) {
  const minterCounts = {};
  for (const validator of validators) {
    if (minterCounts[validator.minter] == undefined) {
      minterCounts[validator.minter] = 1;
    } else {
      minterCounts[validator.minter]++;
    }
  }
  return minterCounts;
}

function diff(source, comp) {
  const keys = Object.keys(source);

  const output = {};

  for (let key of keys) {
    if (source[key] !== comp[key]) {
      output[key] = source[key] - (comp[key] || 0);
    }
  }
  return output;
}

const validators1 = await parseFile("./GetValidatorsScript1.txt");
const validators2 = await parseFile("./GetValidatorsScript2.txt");

const months = {};

for (const validator of validators2) {
  const monthsRenewed = (validator.renewalExpiry - validator.created) / 2628000;
  if (monthsRenewed > 1) {
    console.log(`Validator ${validator.id} owned by ${validator.minter} lasts ${monthsRenewed} months`);
  }

  if (months[validator.minter] == undefined) {
    months[validator.minter] = [];
  }

  months[validator.minter].push(monthsRenewed > 6 ? 6 : monthsRenewed);
}

const minterCounts1 = countMinters(validators1);
const minterCounts2 = countMinters(validators2);

const diffCounts = diff(minterCounts2, minterCounts1);
console.log(diffCounts);

let userIndex = 0;

let usersOutput = "";
let monthsOutput = "";

for (const [address, amplifiers] of Object.entries(diffCounts)) {
  for (let i = 0; i < amplifiers; i++) {
    usersOutput += `users[${userIndex}] = ${address};\n`;
    monthsOutput += `months[${userIndex}] = ${months[address].pop()};\n`;
    userIndex++;
  }
}

console.log(usersOutput);
console.log(monthsOutput);
