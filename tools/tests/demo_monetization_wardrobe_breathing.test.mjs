import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const read = (file) => readFileSync(file, 'utf8');
const season = read('lib/páginas/tienda/season_pass_preview_screen.dart');
const shop = read('lib/páginas/tienda/store_screen.dart');
const breathing = read('lib/páginas/habitos/habit_interaction_card.dart');
const wardrobe = read('lib/páginas/tienda/wardrobe_screen.dart');
const mascot = read('lib/páginas/tienda/healthy_mascot_live.dart');
const profile = read('lib/páginas/perfil/profile_screen.dart');
const chatbot = read('lib/páginas/chatbot/nutrichat.dart');
const shelf = read('lib/páginas/tienda/healthy_achievement_display.dart');

test('monetización es únicamente exhibición sin dinero ni economía real', () => {
  assert.match(shop, /const SeasonPassPreviewScreen\(\)/);
  assert.match(season, /Simulación académica/);
  assert.match(season, /No se realiza ningún cargo ni se entregan recompensas/);
  assert.match(season, /_explain\('Pase premium'\)/);
  assert.doesNotMatch(season, /cloud_firestore|cloud_functions|Firebase|in_app_purchase|buy\(/);
});

test('el cronómetro no se reinicia al informar su propio avance al padre', () => {
  assert.match(breathing, /widget\.initialValue != _value/);
  assert.match(breathing, /_watch\.elapsed\.inSeconds/);
  assert.match(breathing, /Timer\.periodic/);
});

test('el armario conserva y gira accesorios, y centraliza títulos de perfil', () => {
  assert.match(wardrobe, /'rotation': rotation/);
  assert.match(wardrobe, /Transform\.rotate\(/);
  assert.match(wardrobe, /wardrobe-accessory-rotation/);
  assert.match(wardrobe, /perfil_titulo/);
  assert.match(wardrobe, /'profileTitle': choice/);
  assert.doesNotMatch(profile, /_showCustomization\(/);
  assert.match(shelf, /class HealthyAchievementDisplay/);
});

test('vestimenta guardada se aplica a perfil y chat con animación de atención', () => {
  assert.match(mascot, /ShopService\.instance\.watch\(\)/);
  assert.match(mascot, /hh_wardrobe_layout_v1_/);
  assert.match(mascot, /HealthyMascotIdle\(/);
  assert.match(chatbot, /Mr\. Healthy sigue tu mensaje/);
  assert.match(chatbot, /HealthyMascotLive\(/);
  assert.match(profile, /HealthyMascotLive\(/);
});
