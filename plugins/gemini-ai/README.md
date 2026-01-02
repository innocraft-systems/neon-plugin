# Gemini AI Plugin

Complete Google Gemini API integration for Claude Code - all models from 1.5 to 3.0, multimodal capabilities, Live API, and image/video generation.

## Features

- **All Gemini Models** - 1.5 Flash/Pro, 2.0 Flash, 2.5 Flash/Pro, 3.0 Pro
- **Image Generation** - Nano Banana (2.5 Flash Image) and Nano Banana Pro (3 Pro Image)
- **Video Generation** - Veo 2.0 and 3.1
- **Live API** - Real-time audio/video streaming
- **Multimodal** - Image, video, audio understanding
- **Tool Calling** - Native function calling support
- **Thinking Mode** - Extended reasoning for complex tasks

## Skills

### gemini-models
- Complete model comparison and selection guide
- When to use Flash vs Pro
- Direct API vs OpenRouter
- Pricing and rate limits
- Code examples for each model

### gemini-multimodal
- Image understanding and analysis
- Image generation with Nano Banana
- Video understanding
- Video generation with Veo
- Audio transcription and analysis

### gemini-live
- Real-time voice chat
- WebSocket streaming
- Function calling in live sessions
- Browser and Node.js clients
- Voice customer service examples

## Quick Start

### Direct API

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY!);
const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });

const result = await model.generateContent('Hello!');
console.log(result.response.text());
```

### OpenRouter

```typescript
import OpenAI from 'openai';

const client = new OpenAI({
  baseURL: 'https://openrouter.ai/api/v1',
  apiKey: process.env.OPENROUTER_API_KEY!,
});

const response = await client.chat.completions.create({
  model: 'google/gemini-2.0-flash-exp',
  messages: [{ role: 'user', content: 'Hello!' }],
});
```

## Model Selection

| Use Case | Recommended Model |
|----------|-------------------|
| Fast chat/Q&A | Gemini 1.5 Flash |
| Long documents | Gemini 1.5 Pro |
| AI agents | Gemini 2.0 Flash |
| Image generation | Gemini 2.5 Flash Image |
| Complex reasoning | Gemini 2.5/3 Pro |
| Voice chat | Gemini 2.0 Flash Live |

## Resources

- [Google AI Studio](https://aistudio.google.com/)
- [Gemini API Docs](https://ai.google.dev/gemini-api/docs)
- [OpenRouter](https://openrouter.ai/)
