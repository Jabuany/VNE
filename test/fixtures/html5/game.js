'use strict';

const status = document.getElementById('status');
const play = document.getElementById('play');
const audioStatus = document.getElementById('audio-status');
let audioContext;
let tone;

async function verify() {
  const count = Number(localStorage.getItem('vne-fixture-visits') || '0') + 1;
  localStorage.setItem('vne-fixture-visits', String(count));
  document.getElementById('visits').textContent = 'Visita ' + count;

  const css = getComputedStyle(document.body).getPropertyValue('--fixture');
  if (css.trim() !== 'loaded') throw new Error('CSS');
  await document.getElementById('picture').decode();
  const fonts = await document.fonts.load('16px Fixture', 'A');
  if (fonts.length !== 1) throw new Error('Fuente');
  const manifest = await fetch('./game.json').then(response => response.json());
  if (manifest.fixture !== true) throw new Error('JSON');
  audioContext = new AudioContext();
  const bytes = await fetch('./media/tone.wav').then(response => response.arrayBuffer());
  tone = await audioContext.decodeAudioData(bytes);
  if (tone.duration <= 0) throw new Error('Audio');

  const missing = await fetch('./media/missing.png');
  if (missing.status !== 404) throw new Error('Recurso ausente');
  const externalBlocked = await fetch('https://outside.invalid/').then(
    () => false,
    () => true,
  );
  if (!externalBlocked) throw new Error('Red externa');
  status.textContent = 'Recursos OK · red bloqueada';
  play.disabled = false;
}

play.addEventListener('click', async () => {
  try {
    await audioContext.resume();
    const source = audioContext.createBufferSource();
    source.buffer = tone;
    source.connect(audioContext.destination);
    source.start();
    audioStatus.textContent = 'Audio iniciado';
  } catch (_) {
    audioStatus.textContent = 'Audio no disponible';
  }
});

verify().catch(error => {
  status.textContent = 'Prueba fallida · ' + error.message;
});
