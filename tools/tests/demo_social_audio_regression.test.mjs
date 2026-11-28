import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';

const read = (path) => readFileSync(resolve(process.cwd(), path), 'utf8');
const chat = read('lib/páginas/chatbot/nutrichat.dart');
const sound = read('lib/servicios/healthy_retro_sound_service.dart');
const nativeAudio = read('android/app/src/main/kotlin/com/example/healthy_habit/MainActivity.kt');
const synth = read('android/app/src/main/kotlin/com/example/healthy_habit/HealthySoundEngine.kt');
const pair = read('lib/páginas/habitos/habitos_en_pareja_screen.dart');
const streak = read('lib/páginas/estadisticas/daily_streak_screen.dart');
const dialog = read('lib/páginas/estadisticas/daily_streak_reward_dialog.dart');
const shopSound = read('lib/servicios/healthy_feedback_service.dart');

test('Mr. Healthy elimina selector sin comportamiento y solo reproduce bips', () => {
  assert.doesNotMatch(chat, /tooltip: 'Personalidad de Mr. Healthy'/);
  assert.doesNotMatch(chat, /_tts\.speak\(/);
  assert.match(chat, /HealthyRetroSoundService\.play\('talk'\)/);
  assert.match(nativeAudio, /healthy_habit\/retro_sounds/);
  assert.match(sound, /settings\['sonidosApp'\] == false/);
  // El sintetizador original está separado del puente Flutter.
  assert.match(nativeAudio, /HealthySoundEngine\.play\(kind\)/);
  assert.match(synth, /AudioTrack\.Builder\(\)/);
  assert.match(synth, /val supported = baseEvents/);
});

test('recompensas y precios usan imagen de moneda real', () => {
  assert.match(streak, /HealthyCoinAmount\(/);
  assert.match(streak, /HealthyCoinIcon\(/);
  assert.doesNotMatch(streak, /🪙/);
  assert.match(dialog, /HealthyCoinAmount\(/);
  assert.match(shopSound, /HealthyRetroSoundService\.play\('purchase'\)/);
});

test('pareja enseña ambos perfiles sin afirmar registros no certificados', () => {
  assert.match(pair, /_participantPortraits\(item\.data\(\)\)/);
  assert.match(pair, /AmigosServicio\.perfiles\(\[sender, recipient\]\)/);
  assert.match(pair, /no se sincronizan/);
  assert.doesNotMatch(pair, /habitCoins:\s*\d+/);
});
