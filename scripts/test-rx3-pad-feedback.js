const fs=require('fs'),vm=require('vm'),path=require('path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..');
const resources=path.join(root,'vendor/controller-mappings');
const timers=new Map();let nextTimer=1;const writes=[];
const values=new Map(),listeners=new Map(),messages=[];
const k=(g,c)=>g+'|'+c;
const sandbox={console,midi:{sendShortMsg:(...args)=>messages.push(args)},engine:{
getValue:(g,c)=>values.get(k(g,c))??0,
setValue:(g,c,v)=>{values.set(k(g,c),v);writes.push([g,c,v]);(listeners.get(k(g,c))??[]).forEach(f=>f(v,g,c));},
getParameter:()=>0,setParameter:()=>{},setSoftTakeover:()=>{},softTakeover:()=>{},softTakeoverIgnoreNextValue:()=>{},
makeConnection:(g,c,f)=>{const a=listeners.get(k(g,c))??[];a.push(f);listeners.set(k(g,c),a);return {trigger:()=>f(sandbox.engine.getValue(g,c),g,c),disconnect:()=>{const i=a.indexOf(f);if(i>=0)a.splice(i,1);}};},
beginTimer:(ms,callback)=>{const id=nextTimer++;timers.set(id,{ms,callback});return id;},stopTimer:id=>timers.delete(id),isScratching:()=>false},
script:{channelRegEx:/\[Channel(\d+)\]/,eqRegEx:/Equalizer/,quickEffectRegEx:/QuickEffect/,deckFromGroup:g=>Number(g.match(/\d+/)[0]),toggleControl:()=>{},triggerControl:()=>{},absoluteNonLin:()=>0}};
vm.createContext(sandbox);
vm.runInContext(fs.readFileSync(path.join(resources,'midi-components-0.0.js'),'utf8'),sandbox);
vm.runInContext(fs.readFileSync(path.join(root,'controllers/Hercules_DJControl_Inpulse_500_RX3/Hercules-DJControl-Inpulse-500-RX3-script.js'),'utf8'),sandbox);
const m=sandbox.DJCi500;m.deckA=new m.Deck([1,3],1);m.deckB=new m.Deck([2,4],2);

const fire=()=>{for(const [id,t] of [...timers]){timers.delete(id);t.callback();}};
const last=(status,pad)=>messages.filter(a=>a[0]===status&&a[1]===pad).at(-1)?.[2];
const expected=[0x60,0x1F,0x5C,0x63,0x1C,0x74,0x03,0x7C];
// Already-restored Rekordbox slots need a full repaint even if their status
// does not emit again when track_loaded arrives. Include cue at position zero.
for(let i=1;i<=8;i++)values.set(k('[Channel1]',`hotcue_${i}_status`),i===7?0:i===8?2:1);
messages.length=0;sandbox.engine.setValue('[Channel1]','track_loaded',1);fire();
for(let i=0;i<8;i++)for(const offset of [0,8])assert.equal(last(0x96,i+offset),i===6?127:expected[i]);
for(let i=0;i<8;i++)assert.equal(last(0x97,i),127,'other deck remains empty');
// Normal cue changes remain immediate, independent on both decks.
sandbox.engine.setValue('[Channel2]','hotcue_2_status',1);
assert.equal(last(0x97,1),0x1F);
sandbox.engine.setValue('[Channel1]','hotcue_1_status',0);
assert.equal(last(0x96,0),127);
// Load callbacks coalesce; an unload paints all empty pads without editing cues.
for(let i=1;i<=8;i++)values.set(k('[Channel1]',`hotcue_${i}_status`),0);
sandbox.engine.setValue('[Channel1]','track_loaded',0);
sandbox.engine.setValue('[Channel1]','track_loaded',1);
assert.equal(timers.size,1);fire();
for(let i=0;i<8;i++)assert.equal(last(0x96,i),127);
// Load feedback cannot overwrite another active pad mode.
m.rx3SetPadMode(m.deckA,5);messages.length=0;
sandbox.engine.setValue('[Channel1]','hotcue_1_status',1);
assert.equal(messages.length,0);
sandbox.engine.setValue('[Channel1]','track_loaded',1);fire();
for(let i=0;i<8;i++)assert.equal(last(0x96,i),127);
m.rx3SetPadMode(m.deckA,1);assert.equal(last(0x96,0),0x60);
// Deck reassignment disconnects old slots and refreshes the selected deck.
values.set(k('[Channel3]','hotcue_3_status'),1);
m.deckA.setCurrentDeck('[Channel3]');assert.equal(last(0x96,2),0x5C);
messages.length=0;sandbox.engine.setValue('[Channel1]','hotcue_3_status',1);
assert.equal(messages.length,0);
assert(writes.every(a=>a[1]==='track_loaded'||a[1].endsWith('_status')||a[0].startsWith('[RX3PadMode')),
    'LED refresh never changes playback or imported cue data');
console.log('PASS: real HotcueButton load repaint, both decks, assigned/empty/saved-loop slots, SHIFT banks, mode isolation and deck reassignment');
