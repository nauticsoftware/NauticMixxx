const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const path = require('node:path');
const root = path.join(__dirname, '../..');
const source = fs.readFileSync(path.join(root, 'controllers/Hercules_DJControl_Inpulse_500_RX3/Hercules-DJControl-Inpulse-500-RX3-script.js'), 'utf8');
let now = 1000, nextTimer = 1, assertions = 0;
const values = new Map(), timers = new Map(), writes = [], leds = [], scratching = new Set(), scratchTicks = [];
function check(value, expected, message) { assert.deepEqual(value, expected, message); assertions++; }
const engine = {
 getValue(g,k) { return values.get(g+'|'+k) || 0; },
 setValue(g,k,v) { values.set(g+'|'+k,v); writes.push([g,k,v]); if (g==='[Tab]' && v===1) { if(k==='library')values.set('[Tab]|current',1); if(k==='overview')values.set('[Tab]|current',0); } },
 beginTimer(ms,callback) { const id=nextTimer++;timers.set(id,{at:now+ms,callback});return id; },
 stopTimer(id) { timers.delete(id); },
 isScratching(d) {return scratching.has(d);},
 scratchDisable(d, ramp = true) { if (!ramp) scratching.delete(d); }, scratchEnable(d) {scratching.add(d);},
 scratchTick(d,v) {scratchTicks.push([d,v]);}
};
function Component(options) { Object.assign(this, options); this.inValueScale = v => v > 63 ? v-128 : v; }
const context = vm.createContext({engine, Date:{now:()=>now}, console,
 midi:{sendShortMsg:(...args)=>leds.push(args)},
 script:{deckFromGroup:g=>Number(g.match(/\d+/)[0]),triggerControl:(g,k)=>engine.setValue(g,k,1)},
 components:{Deck:function(){},Button:Component,JogWheelBasic:Component}
});
vm.runInContext(fs.readFileSync(path.join(root, 'controllers/Hercules_DJControl_Inpulse_500_RX3/midi-components-0.0.js'), 'utf8'), context);
vm.runInContext(source,context);
const m=context.DJCi500;
const press=()=>m.rx3BrowserPush(0,0,127,0x90);
const release=()=>m.rx3BrowserPush(0,0,0,0x90);
const advance=ms=>{now+=ms;for(const [id,t] of [...timers])if(t.at<=now){timers.delete(id);t.callback();}};
press();check(engine.getValue('[Tab]','current'),0,'no Browse on down');
advance(150);release();check(engine.getValue('[Tab]','current'),1,'opens on release');check(timers.size,0,'short press cancels hold');
engine.setValue('[Tab]','overview',1);advance(400);press();advance(1999);check(m.rx3GridActive(),false,'not before two seconds');advance(1);
check(m.rx3GridActive(),true,'enters at two seconds');check(engine.getValue('[Tab]','current'),0,'grid uses waveforms');release();check(m.rx3GridActive(),true,'long release consumed');
advance(400);press();release();check(m.rx3GridActive(),false,'single short press leaves Grid');check(engine.getValue('[Tab]','current'),0,'exit does not open Browse');
advance(400);press();press();check(timers.size,1,'duplicate positive edge not a second timer');
m.moveLibrary(0,0,1);advance(4000);release();check(m.rx3GridActive(),false,'press+turn cancels long press');check(engine.getValue('[Tab]','current'),0,'press+turn does not open Browse');
advance(400);press();m.rx3BrowserPush(0,0,64,0x80);check(engine.getValue('[Tab]','current'),1,'Note Off with release velocity handled');
advance(400);press();now+=2000;release();check(m.rx3GridActive(),true,'release boundary handles delayed timer');
const decks=[1,2,3,4].map(d=>({currentDeck:'[Channel'+d+']',loopAdjustMode:null,vinylButtonState:[true,true,true,true]}));
function buildComponent(name,deckData,midiChannel) {
 const start=source.indexOf('    this.'+name+' = new components.');assert.ok(start>=0);
 const end=source.indexOf('\n    });',start)+8;
 context.fixtureDeck=deckData;context.fixtureChannel=midiChannel;
 return vm.runInContext('(function(deckData,midiChannel){'+source.slice(start,end)+';return this.'+name+';}).call({},fixtureDeck,fixtureChannel)',context);
}
for (let i=0;i<4;i++) {
 const d=decks[i];d.jogWheel=buildComponent('jogWheel',d,i%2+1);d.jogWheelShift=buildComponent('jogWheelShift',d,i%2+1);
 engine.setValue(d.currentDeck,'track_loaded',1);
}
writes.length=0;
decks[0].jogWheel.inputWheel(0,0,3);check(writes.length,0,'fractional jog ticks accumulated');decks[0].jogWheel.inputWheel(0,0,1);
check(writes,[['[Channel1]','beats_translate_move',1]],'jog only edits its own grid');
writes.length=0;decks[1].jogWheelShift.inputWheel(0,0,124);check(writes,[['[Channel2]','beats_translate_move',-1]],'shift jog remains grid editing');
decks[0].jogWheel.inputTouch(0,0,127);check(scratching.size,0,'Grid touch never scratches');
engine.setValue('[Channel3]','track_loaded',0);writes.length=0;decks[2].jogWheel.inputWheel(0,0,8);check(writes,[],'empty deck consumes jog without playback movement');
m.rx3SetGridMode(false);
for(let i=0;i<4;i++){
 const d=decks[i],number=i+1; const button=buildComponent('vinylButton',d,i%2+1);button.unshift();
 d.jogWheel.inputTouch(0,0,127);check(scratching.has(number),true,'Vinyl ON touch enables scratch');
 button.input(0,0,127,0x91);check(d.vinylButtonState[i],false,'stores correct deck slot');check(scratching.has(number),false,'switching OFF releases active scratch');
 button.input(0,0,127,0x91);check(d.vinylButtonState[i],false,'duplicate Note On cannot enable Vinyl again');
 button.input(0,0,64,0x81);check(d.vinylButtonState[i],false,'Note Off release velocity never toggles Vinyl');
 button.input(0,0,0,0x91);d.jogWheel.inputTouch(0,0,127);check(scratching.has(number),false,'Vinyl OFF ignores touch for scratch');
 writes.length=0;d.jogWheel.inputWheel(0,0,1);check(writes,[[d.currentDeck,'jog',1]],'Vinyl OFF jog uses pitch bend');
 button.input(0,0,127,0x91);d.jogWheel.inputTouch(0,0,127);check(scratching.has(number),true,'Vinyl can be re-enabled');
 d.jogWheel.inputWheel(0,0,1);check(scratchTicks.at(-1),[number,1],'Vinyl ON jog uses scratch');
 d.jogWheel.inputTouch(0,0,0);
}
m.rx3SetGridMode(false);
engine.setValue('[RX3Browser]','enabled',1);
m.rx3ShowPerformance();engine.setValue('[Library]','focused_widget',3);writes.length=0;advance(400);press();release();
check(engine.getValue('[RX3Browser]','open'),1,'native browser opens from controller');
check(writes.some(w=>w[0]==='[Library]' && w[1]==='focused_widget'),false,'reopening native Browse never redirects focus to folders');
check(writes.some(w=>w[0]==='[RX3Browser]' && w[1]==='enter'),false,'reopening Browse does not confirm or leave the selected list');
check(engine.getValue('[Library]','focused_widget'),3,'track list remains the navigation target');
writes.length=0;m.moveLibrary(0,0,127);m.moveLibrary(0,0,127);
check(writes, [
 ['[RX3Browser]','move',-1],['[RX3Browser]','move',0],
 ['[RX3Browser]','move',-1],['[RX3Browser]','move',0]
],'native encoder supports repeated navigation ticks and releases each trigger');
advance(400);press();release();
check(writes.some(w=>w[0]==='[RX3Browser]' && w[1]==='enter' && w[2]===1),true,'encoder confirms native category/folder');
m.rx3BrowserBack(0,0,127,0x90);
check(writes.some(w=>w[0]==='[RX3Browser]' && w[1]==='back' && w[2]===1),true,'shift encoder navigates back toward SOURCE');
engine.setValue('[RX3Browser]','enabled',0);
advance(400);press();m.rx3ShowPerformance();advance(4000);check(m.rx3GridActive(),false,'cancelled UI gesture never enters Grid later');
console.log('PASS: '+assertions+' browser/grid/vinyl checks, including actual jog and VINYL handlers on decks 1-4.');
