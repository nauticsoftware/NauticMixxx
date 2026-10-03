const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const here = __dirname;
const source = fs.readFileSync(path.join(here, "../controllers",
    "Hercules_DJControl_Inpulse_500_RX3",
    "Hercules-DJControl-Inpulse-500-RX3-script.js"), "utf8");
const sandbox = {components: {Deck: function() {}}};
sandbox.components.Deck.prototype = {};
vm.runInNewContext(source, sandbox);

const shape = sandbox.DJCi500.rx3ShapeJogBend;
assert.equal(shape(0), 0);
assert.equal(shape(1), 1.9);
assert.equal(shape(-1), -1.9);
assert.equal(shape(63), 2.4);
assert.equal(shape(-63), -2.4);
assert.equal(shape(127), 2.4);
assert.equal(shape(NaN), 0);
for (let velocity = 2; velocity <= 63; velocity++) {
    assert.ok(shape(velocity) > shape(velocity - 1));
    assert.equal(shape(-velocity), -shape(velocity));
}
sandbox.DJCi500.rx3JogBendSensitivity = 0.5;
assert.equal(shape(1), 0.95);
assert.equal(shape(63), 1.2);
