const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { randomUUID } = require('crypto');

console.log("renderer.js loaded");

let recordedChunks = [];
let mediaRecorder = null;
let isRecording = false;

window.addEventListener('DOMContentLoaded', () => {
  console.log("DOMContentLoaded event triggered");

  loadOllamaModels();

  window.addEventListener('keydown', async (e) => {
    console.log("Key down:", e.code);
    if (e.code === 'Space') {
      e.preventDefault();
      try {
        startRecording();
      } catch (err) {
        console.error("Error starting recording:", err);
      }
    }
  });

  window.addEventListener('keyup', (e) => {
    console.log("Key up:", e.code);
    if (e.code === 'Space') {
      e.preventDefault();
      try {
        stopRecording();
      } catch (err) {
        console.error("Error stopping recording:", err);
      }
    }
  });
});

async function loadOllamaModels() {
  try {
    const response = await fetch('http://localhost:11434/api/tags');
    const data = await response.json();
    const modelSelect = document.getElementById('ollamaModelSelect');
    modelSelect.innerHTML = ''; // Clear loading

    data.models.forEach(model => {
      const option = document.createElement('option');
      option.value = model.name;
      option.textContent = model.name;
      modelSelect.appendChild(option);
    });

    console.log("Loaded Ollama models:", data.models.map(m => m.name));
  } catch (err) {
    console.error("Failed to fetch Ollama model list:", err);
    const modelSelect = document.getElementById('ollamaModelSelect');
    modelSelect.innerHTML = '<option disabled>Error loading models</option>';
  }
}

async function startRecording() {
  if (isRecording) return;
  isRecording = true;
  const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
  recordedChunks = [];
  mediaRecorder = new MediaRecorder(stream);

  mediaRecorder.ondataavailable = e => recordedChunks.push(e.data);
  mediaRecorder.start();

  console.log("Recording started...");
  document.getElementById('recordingStatus').textContent = "Recording...";
}

function stopRecording() {
  if (!isRecording || !mediaRecorder) return;
  isRecording = false;

  mediaRecorder.stop();

  mediaRecorder.onstop = () => {
    console.log("Recording stopped.");
    const blob = new Blob(recordedChunks, { type: 'audio/webm' });
    const reader = new FileReader();
    reader.onload = () => {
      const buffer = Buffer.from(new Uint8Array(reader.result));
      const audioPath = path.join(os.tmpdir(), `recording_${randomUUID()}.webm`);
      fs.writeFileSync(audioPath, buffer);
      console.log("Saved audio to:", audioPath);

      transcribeAndSend(audioPath);
    };
    reader.readAsArrayBuffer(blob);
  };
}

async function transcribeAndSend(audioPath) {
  const pythonPath = path.join(__dirname, 'venv', 'bin', 'python');
  const modelSize = document.getElementById('modelSelect')?.value || 'base';
  const outputDir = os.tmpdir();
  const outputFileName = `transcript_${randomUUID()}.json`;

  console.log("Launching transcription for:", audioPath);

  const python = spawn(pythonPath, [
    path.join(__dirname, 'backend', 'whisper_backend.py'),
    audioPath,
    modelSize,
    outputDir,
    '--output_filename',
    outputFileName
  ]);

  python.stdout.on('data', async data => {
    const lines = data.toString().split('\n').filter(Boolean);
    try {
      const res = JSON.parse(lines[0]);
      if (res.status === 'success') {
        const fullText = res.transcript;
        console.log("Transcript received:", fullText);
        document.getElementById('recordingStatus').textContent = "Sending to Ollama...";
        await queryOllama(fullText);
        cleanupFiles(audioPath, res.output_file);
      } else {
        console.error("Transcription error:", res.message);
      }
    } catch (err) {
      console.error("Failed to parse output:", err);
      console.error("Raw output was:", data.toString());
    }
  });

  python.stderr.on('data', data => {
    console.error("Python stderr:", data.toString());
  });

  python.on('close', code => {
    console.log(`Python exited with code ${code}`);
  });
}

async function queryOllama(fullText) {
  try {
    const output = document.getElementById('llmOutput');

    const youLine = document.createElement('div');
    youLine.style.color = 'deepskyblue';
    youLine.textContent = `You: ${fullText}`;
    output.appendChild(youLine);

    const selectedModel = document.getElementById('ollamaModelSelect')?.value || 'Ollama';

    const modelLabel = document.createElement('div');
    modelLabel.textContent = `${selectedModel}:`;
    output.appendChild(modelLabel);


    const response = await fetch('http://localhost:11434/api/generate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: document.getElementById('ollamaModelSelect')?.value || 'gemma3:12b',
        prompt: fullText
      })
    });

    const reader = response.body.getReader();
    const decoder = new TextDecoder('utf-8');
    let buffer = '';

    while (true) {
      const { value, done } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop();

      for (const line of lines) {
        if (!line.trim()) continue;
        try {
          const parsed = JSON.parse(line);
          if (parsed.response) {
            const responseText = document.createTextNode(parsed.response);
            output.appendChild(responseText);
            output.scrollTop = output.scrollHeight;
          }
        } catch (err) {
          console.error("Failed to parse streamed chunk:", err, line);
        }
      }
    }

    document.getElementById('recordingStatus').textContent = "Ready for next message.";

  } catch (err) {
    console.error("Failed to get a response from Ollama:", err);
  }
}

function cleanupFiles(audioPath, transcriptPath) {
  fs.unlink(transcriptPath, err => {
    if (err) console.error("Failed to delete transcript:", err);
    else console.log("Deleted transcript:", transcriptPath);
  });

  fs.unlink(audioPath, err => {
    if (err) console.error("Failed to delete audio:", err);
    else console.log("Deleted audio file:", audioPath);
  });
}
