'use strict';
function normalizeText(input) {
  return input.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase()
    .replace(/[¿?¡!.,;:]/g, ' ').replace(/\s+/g, ' ').trim();
}
const INTENTS = [
  {intent:'SHOW_PENDING_HABITS', patterns:[/\b(que|cuales)\b.*\b(falta|faltan|pendientes)\b/, /\b(habitos?)\b.*\b(pendientes?|faltan)\b/, /\b(pendientes?)\b.*\b(habitos?)\b/]},
  {intent:'SHOW_PROGRESS', patterns:[/\b(estadisticas?|progreso|avance|grafica|graficas)\b/, /\bcomo voy\b/]},
  {intent:'SHOW_STREAK', patterns:[/\b(racha|dias seguidos|dias consecutivos)\b/, /\bcuantos dias llevo\b/]},
  {intent:'OPEN_CHALLENGES', patterns:[/\b(desafios?|retos?)\b/]},
  {intent:'REGISTER_HABIT', patterns:[/\b(ya|acabo de|termine|complete|registre)\b.*\b(bebi|tome|agua|habito|hice|comi|fruta|verduras?)\b/, /\b(registra|registrar|marca|marcar)\b.*\b(habito|agua|consumo|comida|actividad)\b/]}
];
function classifyIntent(value) {
  if (typeof value !== 'string' || value.length === 0 || value.length > 500) {
    throw new TypeError('El texto debe contener entre 1 y 500 caracteres.');
  }
  const normalized = normalizeText(value);
  if (!normalized) throw new TypeError('El texto no puede estar vacio.');
  for (const entry of INTENTS) {
    if (entry.patterns.some((pattern) => pattern.test(normalized))) {
      return {intent:entry.intent, method:'rules_v1', requiresConfirmation:entry.intent==='REGISTER_HABIT'};
    }
  }
  return {intent:'UNKNOWN', method:'rules_v1', requiresConfirmation:false};
}
module.exports = {classifyIntent, normalizeText};
