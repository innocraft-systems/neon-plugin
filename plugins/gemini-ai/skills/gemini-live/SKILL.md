---
name: gemini-live
description: This skill provides guidance for Gemini Live API for real-time audio/video streaming. Use when the user asks about "Gemini Live", "real-time audio", "voice chat", "live video", "streaming API", "voice assistant", "real-time AI", or needs help building voice/video chat applications.
---

# Gemini Live API

Build real-time voice and video AI experiences with the Gemini Live API. Enables bidirectional audio/video streaming for interactive applications.

## Overview

Released November 2025, the Live API enables:
- Real-time audio input/output
- Live video streaming
- Function calling during conversation
- Natural conversation flow
- Low latency responses

## Model

```
gemini-2.0-flash-live
```

## Setup

```bash
npm install @google/generative-ai ws
```

## Basic Audio Chat

### WebSocket Connection

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';
import WebSocket from 'ws';

const API_KEY = process.env.GOOGLE_API_KEY!;

async function createLiveSession() {
  const ws = new WebSocket(
    `wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=${API_KEY}`
  );

  return new Promise((resolve, reject) => {
    ws.on('open', () => {
      // Send setup message
      ws.send(JSON.stringify({
        setup: {
          model: 'models/gemini-2.0-flash-live',
          generationConfig: {
            responseModalities: ['AUDIO'],
          },
        },
      }));

      resolve(ws);
    });

    ws.on('error', reject);
  });
}
```

### Send Audio

```typescript
async function sendAudio(ws: WebSocket, audioChunk: Buffer) {
  ws.send(JSON.stringify({
    realtimeInput: {
      mediaChunks: [{
        mimeType: 'audio/pcm;rate=16000',
        data: audioChunk.toString('base64'),
      }],
    },
  }));
}
```

### Receive Audio

```typescript
function handleMessages(ws: WebSocket, onAudio: (audio: Buffer) => void) {
  ws.on('message', (data) => {
    const message = JSON.parse(data.toString());

    if (message.serverContent?.modelTurn?.parts) {
      for (const part of message.serverContent.modelTurn.parts) {
        if (part.inlineData?.mimeType?.includes('audio')) {
          const audio = Buffer.from(part.inlineData.data, 'base64');
          onAudio(audio);
        }
      }
    }

    if (message.serverContent?.turnComplete) {
      console.log('Turn complete');
    }
  });
}
```

## Complete Voice Chat Client

```typescript
import { Readable, Writable } from 'stream';
import WebSocket from 'ws';
import { Microphone } from 'node-microphone';
import Speaker from 'speaker';

interface LiveConfig {
  apiKey: string;
  systemInstruction?: string;
  voice?: string;
  tools?: any[];
  onTranscript?: (text: string) => void;
  onToolCall?: (call: any) => Promise<any>;
}

class GeminiLive {
  private ws: WebSocket | null = null;
  private config: LiveConfig;
  private microphone: Microphone | null = null;
  private speaker: Speaker | null = null;

  constructor(config: LiveConfig) {
    this.config = config;
  }

  async connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(
        `wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=${this.config.apiKey}`
      );

      this.ws.on('open', () => {
        this.sendSetup();
        resolve();
      });

      this.ws.on('message', (data) => {
        this.handleMessage(JSON.parse(data.toString()));
      });

      this.ws.on('error', reject);
      this.ws.on('close', () => {
        console.log('Connection closed');
      });
    });
  }

  private sendSetup() {
    const setup: any = {
      setup: {
        model: 'models/gemini-2.0-flash-live',
        generationConfig: {
          responseModalities: ['AUDIO'],
          speechConfig: {
            voiceConfig: {
              prebuiltVoiceConfig: {
                voiceName: this.config.voice || 'Aoede',
              },
            },
          },
        },
      },
    };

    if (this.config.systemInstruction) {
      setup.setup.systemInstruction = {
        parts: [{ text: this.config.systemInstruction }],
      };
    }

    if (this.config.tools) {
      setup.setup.tools = this.config.tools;
    }

    this.ws!.send(JSON.stringify(setup));
  }

  private async handleMessage(message: any) {
    // Handle audio output
    if (message.serverContent?.modelTurn?.parts) {
      for (const part of message.serverContent.modelTurn.parts) {
        if (part.inlineData?.mimeType?.includes('audio')) {
          this.playAudio(Buffer.from(part.inlineData.data, 'base64'));
        }
        if (part.text && this.config.onTranscript) {
          this.config.onTranscript(part.text);
        }
      }
    }

    // Handle tool calls
    if (message.toolCall) {
      const result = await this.config.onToolCall?.(message.toolCall);
      this.sendToolResponse(message.toolCall.id, result);
    }
  }

  private sendToolResponse(callId: string, result: any) {
    this.ws!.send(JSON.stringify({
      toolResponse: {
        functionResponses: [{
          id: callId,
          response: result,
        }],
      },
    }));
  }

  startMicrophone() {
    this.microphone = new Microphone({
      rate: 16000,
      channels: 1,
      bitwidth: 16,
    });

    const stream = this.microphone.startRecording();
    stream.on('data', (chunk: Buffer) => {
      this.sendAudio(chunk);
    });
  }

  stopMicrophone() {
    this.microphone?.stopRecording();
    this.microphone = null;
  }

  sendAudio(chunk: Buffer) {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify({
        realtimeInput: {
          mediaChunks: [{
            mimeType: 'audio/pcm;rate=16000',
            data: chunk.toString('base64'),
          }],
        },
      }));
    }
  }

  sendText(text: string) {
    this.ws?.send(JSON.stringify({
      clientContent: {
        turns: [{
          role: 'user',
          parts: [{ text }],
        }],
        turnComplete: true,
      },
    }));
  }

  private playAudio(audio: Buffer) {
    if (!this.speaker) {
      this.speaker = new Speaker({
        channels: 1,
        bitDepth: 16,
        sampleRate: 24000,
      });
    }
    this.speaker.write(audio);
  }

  disconnect() {
    this.stopMicrophone();
    this.speaker?.end();
    this.ws?.close();
  }
}

// Usage
const live = new GeminiLive({
  apiKey: process.env.GOOGLE_API_KEY!,
  systemInstruction: 'You are a helpful Kenyan business assistant. Speak naturally in English with occasional Swahili phrases.',
  voice: 'Aoede',
  onTranscript: (text) => console.log('AI:', text),
});

await live.connect();
live.startMicrophone();

// Speak to the AI...

// Later
live.disconnect();
```

## Available Voices

| Voice | Description |
|-------|-------------|
| Aoede | Female, warm |
| Charon | Male, deep |
| Fenrir | Male, young |
| Kore | Female, professional |
| Puck | Male, friendly |

## Function Calling in Live

```typescript
const live = new GeminiLive({
  apiKey: process.env.GOOGLE_API_KEY!,
  systemInstruction: 'You are a voice assistant for an electronics shop in Nairobi.',
  tools: [{
    functionDeclarations: [{
      name: 'check_stock',
      description: 'Check if a product is in stock',
      parameters: {
        type: 'object',
        properties: {
          product: { type: 'string', description: 'Product name' },
        },
        required: ['product'],
      },
    }, {
      name: 'get_price',
      description: 'Get the price of a product',
      parameters: {
        type: 'object',
        properties: {
          product: { type: 'string', description: 'Product name' },
        },
        required: ['product'],
      },
    }],
  }],
  onToolCall: async (call) => {
    switch (call.functionCalls[0].name) {
      case 'check_stock':
        return { inStock: true, quantity: 5 };
      case 'get_price':
        return { price: 45000, currency: 'KES' };
    }
  },
});
```

## Video Streaming

### Send Video Frames

```typescript
import { createCanvas } from 'canvas';

async function sendVideoFrame(ws: WebSocket, frameBuffer: Buffer) {
  ws.send(JSON.stringify({
    realtimeInput: {
      mediaChunks: [{
        mimeType: 'image/jpeg',
        data: frameBuffer.toString('base64'),
      }],
    },
  }));
}

// From webcam (using node-webcam or similar)
async function streamWebcam(ws: WebSocket) {
  const webcam = new Webcam();

  setInterval(async () => {
    const frame = await webcam.capture();
    await sendVideoFrame(ws, frame);
  }, 100); // 10 fps
}
```

### Video + Audio

```typescript
const setup = {
  setup: {
    model: 'models/gemini-2.0-flash-live',
    generationConfig: {
      responseModalities: ['AUDIO', 'TEXT'],
    },
  },
};

// Send both audio and video
function sendMultiModal(
  ws: WebSocket,
  audioChunk: Buffer,
  videoFrame: Buffer
) {
  ws.send(JSON.stringify({
    realtimeInput: {
      mediaChunks: [
        {
          mimeType: 'audio/pcm;rate=16000',
          data: audioChunk.toString('base64'),
        },
        {
          mimeType: 'image/jpeg',
          data: videoFrame.toString('base64'),
        },
      ],
    },
  }));
}
```

## Browser Client

```typescript
// React component for voice chat
import { useState, useRef, useCallback } from 'react';

function VoiceChat() {
  const [isListening, setIsListening] = useState(false);
  const [transcript, setTranscript] = useState('');
  const wsRef = useRef<WebSocket | null>(null);
  const audioContextRef = useRef<AudioContext | null>(null);
  const mediaStreamRef = useRef<MediaStream | null>(null);

  const connect = useCallback(async () => {
    // Connect to your backend WebSocket proxy
    wsRef.current = new WebSocket('wss://your-server.com/gemini-live');

    wsRef.current.onmessage = (event) => {
      const data = JSON.parse(event.data);

      if (data.audio) {
        playAudio(data.audio);
      }
      if (data.text) {
        setTranscript(prev => prev + data.text);
      }
    };

    // Request microphone access
    const stream = await navigator.mediaDevices.getUserMedia({
      audio: {
        sampleRate: 16000,
        channelCount: 1,
      },
    });
    mediaStreamRef.current = stream;

    // Set up audio processing
    audioContextRef.current = new AudioContext({ sampleRate: 16000 });
    const source = audioContextRef.current.createMediaStreamSource(stream);
    const processor = audioContextRef.current.createScriptProcessor(4096, 1, 1);

    processor.onaudioprocess = (e) => {
      if (wsRef.current?.readyState === WebSocket.OPEN) {
        const audioData = e.inputBuffer.getChannelData(0);
        const pcm = convertFloat32ToPCM(audioData);
        wsRef.current.send(pcm);
      }
    };

    source.connect(processor);
    processor.connect(audioContextRef.current.destination);

    setIsListening(true);
  }, []);

  const disconnect = useCallback(() => {
    mediaStreamRef.current?.getTracks().forEach(t => t.stop());
    wsRef.current?.close();
    setIsListening(false);
  }, []);

  const playAudio = (base64Audio: string) => {
    const audioContext = new AudioContext({ sampleRate: 24000 });
    const audioData = Uint8Array.from(atob(base64Audio), c => c.charCodeAt(0));
    const audioBuffer = audioContext.createBuffer(1, audioData.length / 2, 24000);
    // ... decode and play
  };

  return (
    <div>
      <button onClick={isListening ? disconnect : connect}>
        {isListening ? 'Stop' : 'Start Voice Chat'}
      </button>
      <div>{transcript}</div>
    </div>
  );
}
```

## Backend Proxy (Express)

```typescript
import express from 'express';
import WebSocket, { WebSocketServer } from 'ws';

const app = express();
const server = app.listen(3000);
const wss = new WebSocketServer({ server, path: '/gemini-live' });

wss.on('connection', (clientWs) => {
  // Connect to Gemini
  const geminiWs = new WebSocket(
    `wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=${process.env.GOOGLE_API_KEY}`
  );

  geminiWs.on('open', () => {
    // Send setup
    geminiWs.send(JSON.stringify({
      setup: {
        model: 'models/gemini-2.0-flash-live',
        generationConfig: {
          responseModalities: ['AUDIO', 'TEXT'],
        },
      },
    }));
  });

  // Forward client audio to Gemini
  clientWs.on('message', (data) => {
    if (geminiWs.readyState === WebSocket.OPEN) {
      geminiWs.send(JSON.stringify({
        realtimeInput: {
          mediaChunks: [{
            mimeType: 'audio/pcm;rate=16000',
            data: Buffer.from(data).toString('base64'),
          }],
        },
      }));
    }
  });

  // Forward Gemini responses to client
  geminiWs.on('message', (data) => {
    const message = JSON.parse(data.toString());

    if (message.serverContent?.modelTurn?.parts) {
      for (const part of message.serverContent.modelTurn.parts) {
        if (part.inlineData) {
          clientWs.send(JSON.stringify({
            audio: part.inlineData.data,
          }));
        }
        if (part.text) {
          clientWs.send(JSON.stringify({
            text: part.text,
          }));
        }
      }
    }
  });

  clientWs.on('close', () => {
    geminiWs.close();
  });
});
```

## Use Cases

### Voice Customer Service

```typescript
const customerServiceBot = new GeminiLive({
  apiKey: API_KEY,
  systemInstruction: `You are a customer service agent for Martin's Electronics in Nairobi.

You can help with:
- Product inquiries
- Order status
- Returns and exchanges
- Store hours and location

Be friendly, professional, and occasionally use Swahili greetings.
Store hours: Mon-Sat 9am-7pm, closed Sunday.
Location: Tom Mboya Street, opposite Archives.
`,
  tools: [{
    functionDeclarations: [
      {
        name: 'check_order',
        description: 'Check order status by phone number',
        parameters: {
          type: 'object',
          properties: {
            phone: { type: 'string' },
          },
        },
      },
    ],
  }],
});
```

### Voice-Activated Inventory

```typescript
const inventoryAssistant = new GeminiLive({
  systemInstruction: `You help warehouse staff check and update inventory using voice.
Always confirm actions before executing.`,
  tools: [{
    functionDeclarations: [
      { name: 'check_stock', /* ... */ },
      { name: 'add_stock', /* ... */ },
      { name: 'remove_stock', /* ... */ },
    ],
  }],
  onToolCall: async (call) => {
    // Connect to inventory system
  },
});
```

## Audio Formats

| Direction | Format | Sample Rate |
|-----------|--------|-------------|
| Input | PCM 16-bit | 16000 Hz |
| Output | PCM 16-bit | 24000 Hz |

## Latency Optimization

1. **Use WebSocket** - Lower latency than REST
2. **Stream early** - Don't wait for complete utterance
3. **Buffer wisely** - Balance latency vs quality
4. **Regional endpoints** - Use closest data center
5. **Preload connection** - Keep WebSocket ready

## Limitations

- 15 minute max session duration
- Audio only (no video generation output)
- English primary, limited multilingual
- ~500ms typical response latency

## Resources

- [Live API Docs](https://ai.google.dev/gemini-api/docs/live)
- [WebSocket Reference](https://ai.google.dev/gemini-api/docs/live-websocket)
