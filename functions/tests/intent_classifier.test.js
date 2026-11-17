'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {classifyIntent,normalizeText} = require('../intent_classifier');
test('normaliza acentos',()=>assert.equal(normalizeText('¿Cómo VOY?'),'como voy'));
const examples=[
  ['¿Qué hábitos me faltan hoy?','SHOW_PENDING_HABITS'],
  ['Quiero ver mis estadísticas','SHOW_PROGRESS'],
  ['¿Cómo voy esta semana?','SHOW_PROGRESS'],
  ['¿Cuántos días llevo?','SHOW_STREAK'],
  ['Muéstrame mis desafíos','OPEN_CHALLENGES'],
  ['Ya bebí agua','REGISTER_HABIT'],
  ['Registra mi hábito de agua','REGISTER_HABIT'],
  ['Cuéntame un chiste','UNKNOWN']
];
for(const [input,expected] of examples) {
  test(input,()=>assert.equal(classifyIntent(input).intent,expected));
}
test('registro exige confirmacion',()=>assert.equal(classifyIntent('Ya bebí agua').requiresConfirmation,true));
test('rechaza entradas invalidas',()=>{
  assert.throws(()=>classifyIntent('   '),TypeError);
  assert.throws(()=>classifyIntent('x'.repeat(501)),TypeError);
  assert.throws(()=>classifyIntent(null),TypeError);
});
