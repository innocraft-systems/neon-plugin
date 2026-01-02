---
name: gemini-models
description: This skill provides guidance for choosing and using Gemini models. Use when the user asks about "Gemini API", "Gemini models", "which Gemini", "Gemini 1.5", "Gemini 2", "Gemini 3", "Flash vs Pro", "OpenRouter Gemini", or needs help selecting the right model for their use case.
---

# Gemini Models Guide

Complete guide to Google's Gemini model family, from 1.5 to 3.0, with guidance on when to use each and direct API vs OpenRouter.

## Model Overview (December 2025)

| Model | ID | Context | Best For | Cost |
|-------|-----|---------|----------|------|
| **Gemini 1.5 Flash** | `gemini-1.5-flash` | 1M | Fast responses, high volume | $ |
| **Gemini 1.5 Pro** | `gemini-1.5-pro` | 2M | Long context, complex analysis | $$ |
| **Gemini 2.0 Flash** | `gemini-2.0-flash` | 1M | Agentic tasks, tool use | $$ |
| **Gemini 2.5 Flash** | `gemini-2.5-flash` | 1M | Image generation, fast | $$ |
| **Gemini 2.5 Pro** | `gemini-2.5-pro` | 2M | Complex reasoning, thinking | $$$ |
| **Gemini 3 Pro** | `gemini-3-pro` | 2M | State-of-the-art reasoning | $$$$ |

### Specialized Models

| Model | ID | Purpose |
|-------|-----|---------|
| **Nano Banana** | `gemini-2.5-flash-image` | Fast image generation |
| **Nano Banana Pro** | `gemini-3-pro-image-preview` | High-fidelity images, text rendering |
| **Veo 2** | `veo-2.0` | Video generation |
| **Gemini Live** | `gemini-2.0-flash-live` | Real-time audio/video streaming |

## When to Use Which Model

### Use Gemini 1.5 Flash When:
- High volume, low latency needed
- Simple Q&A, summarization
- Cost is a concern
- 1M context is sufficient

```typescript
// Example: Chatbot, quick responses
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
```

### Use Gemini 1.5 Pro When:
- Processing very long documents (up to 2M tokens)
- Need highest accuracy on 1.5 generation
- Complex multi-step analysis
- Code understanding across large codebases

```typescript
// Example: Analyze entire codebase
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-pro' });
```

### Use Gemini 2.0 Flash When:
- Building AI agents
- Need native tool/function calling
- Real-time applications
- Streaming responses

```typescript
// Example: AI agent with tools
const model = genAI.getGenerativeModel({
  model: 'gemini-2.0-flash',
  tools: [{ functionDeclarations: myTools }],
});
```

### Use Gemini 2.5 Flash When:
- Image generation (Nano Banana)
- Balanced speed and quality
- Multimodal understanding + generation

```typescript
// Example: Generate image
const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-image' });
```

### Use Gemini 2.5 Pro When:
- Complex reasoning with "thinking"
- Math, science, coding challenges
- Need extended thinking time

```typescript
// Example: Complex problem solving
const model = genAI.getGenerativeModel({
  model: 'gemini-2.5-pro',
  generationConfig: {
    thinkingConfig: { thinkingBudget: 10000 },
  },
});
```

### Use Gemini 3 Pro When:
- State-of-the-art quality needed
- Mission-critical applications
- Complex creative tasks
- Professional asset generation

```typescript
// Example: High-quality content
const model = genAI.getGenerativeModel({ model: 'gemini-3-pro' });
```

## Direct API vs OpenRouter

### Direct Google API

**Use when:**
- Need latest models immediately
- Using Google Cloud infrastructure
- Want official support
- Building production systems

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY!);
const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
```

**Pricing (Direct):**
| Model | Input/1M tokens | Output/1M tokens |
|-------|-----------------|------------------|
| 1.5 Flash | $0.075 | $0.30 |
| 1.5 Pro | $1.25 | $5.00 |
| 2.0 Flash | $0.10 | $0.40 |
| 2.5 Pro | $2.50 | $10.00 |

### OpenRouter

**Use when:**
- Want unified API across providers
- Need fallback options
- Prefer usage-based pricing
- Building multi-model apps

```typescript
import OpenAI from 'openai';

const openrouter = new OpenAI({
  baseURL: 'https://openrouter.ai/api/v1',
  apiKey: process.env.OPENROUTER_API_KEY!,
});

const response = await openrouter.chat.completions.create({
  model: 'google/gemini-2.0-flash-exp',
  messages: [{ role: 'user', content: 'Hello' }],
});
```

**OpenRouter Model IDs:**
| Model | OpenRouter ID |
|-------|---------------|
| Gemini 1.5 Flash | `google/gemini-flash-1.5` |
| Gemini 1.5 Pro | `google/gemini-pro-1.5` |
| Gemini 2.0 Flash | `google/gemini-2.0-flash-exp` |
| Gemini 2.0 Flash Thinking | `google/gemini-2.0-flash-thinking-exp` |

**Note:** OpenRouter may have newer models before stable SDK support.

## Setup

### Direct API

```bash
npm install @google/generative-ai
```

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY!);
```

Get API key: https://aistudio.google.com/apikey

### OpenRouter

```bash
npm install openai
```

```typescript
import OpenAI from 'openai';

const client = new OpenAI({
  baseURL: 'https://openrouter.ai/api/v1',
  apiKey: process.env.OPENROUTER_API_KEY!,
  defaultHeaders: {
    'HTTP-Referer': 'https://your-app.com',
    'X-Title': 'Your App Name',
  },
});
```

Get API key: https://openrouter.ai/keys

## Basic Usage

### Text Generation

```typescript
// Direct API
const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });

const result = await model.generateContent('Explain quantum computing');
const text = result.response.text();
```

```typescript
// OpenRouter
const response = await client.chat.completions.create({
  model: 'google/gemini-2.0-flash-exp',
  messages: [
    { role: 'user', content: 'Explain quantum computing' },
  ],
});

const text = response.choices[0].message.content;
```

### Streaming

```typescript
// Direct API
const result = await model.generateContentStream('Write a story');

for await (const chunk of result.stream) {
  process.stdout.write(chunk.text());
}
```

```typescript
// OpenRouter
const stream = await client.chat.completions.create({
  model: 'google/gemini-2.0-flash-exp',
  messages: [{ role: 'user', content: 'Write a story' }],
  stream: true,
});

for await (const chunk of stream) {
  process.stdout.write(chunk.choices[0]?.delta?.content || '');
}
```

### Chat/Multi-turn

```typescript
// Direct API
const chat = model.startChat({
  history: [
    { role: 'user', parts: [{ text: 'Hello' }] },
    { role: 'model', parts: [{ text: 'Hi there!' }] },
  ],
});

const result = await chat.sendMessage('What can you do?');
```

### System Instructions

```typescript
// Direct API
const model = genAI.getGenerativeModel({
  model: 'gemini-2.0-flash',
  systemInstruction: 'You are a helpful Kenyan business assistant. Always respond in Sheng when appropriate.',
});
```

```typescript
// OpenRouter
const response = await client.chat.completions.create({
  model: 'google/gemini-2.0-flash-exp',
  messages: [
    {
      role: 'system',
      content: 'You are a helpful Kenyan business assistant.',
    },
    { role: 'user', content: 'How can I grow my business?' },
  ],
});
```

## Function Calling / Tools

### Direct API

```typescript
const tools = [
  {
    functionDeclarations: [
      {
        name: 'get_weather',
        description: 'Get current weather for a location',
        parameters: {
          type: 'object',
          properties: {
            location: {
              type: 'string',
              description: 'City name',
            },
          },
          required: ['location'],
        },
      },
    ],
  },
];

const model = genAI.getGenerativeModel({
  model: 'gemini-2.0-flash',
  tools,
});

const result = await model.generateContent('What\'s the weather in Nairobi?');

// Check for function call
const call = result.response.functionCalls()?.[0];
if (call) {
  console.log('Function:', call.name);
  console.log('Args:', call.args);
}
```

### OpenRouter

```typescript
const response = await client.chat.completions.create({
  model: 'google/gemini-2.0-flash-exp',
  messages: [{ role: 'user', content: 'What\'s the weather in Nairobi?' }],
  tools: [
    {
      type: 'function',
      function: {
        name: 'get_weather',
        description: 'Get current weather for a location',
        parameters: {
          type: 'object',
          properties: {
            location: { type: 'string', description: 'City name' },
          },
          required: ['location'],
        },
      },
    },
  ],
});

const toolCall = response.choices[0].message.tool_calls?.[0];
```

## Thinking Mode (2.5 Pro / 3 Pro)

Enable extended reasoning for complex problems:

```typescript
const model = genAI.getGenerativeModel({
  model: 'gemini-2.5-pro',
  generationConfig: {
    thinkingConfig: {
      thinkingBudget: 10000, // tokens for reasoning
    },
  },
});

const result = await model.generateContent(
  'Solve this complex math problem step by step...'
);

// Access thinking process
const thinking = result.response.candidates?.[0]?.content?.parts?.find(
  p => p.thought
);
console.log('Reasoning:', thinking?.thought);
```

## Grounding with Google Search

```typescript
const model = genAI.getGenerativeModel({
  model: 'gemini-2.0-flash',
  tools: [{ googleSearch: {} }],
});

const result = await model.generateContent(
  'What are the latest iPhone 16 prices in Kenya?'
);

// Access search results
const groundingMetadata = result.response.candidates?.[0]?.groundingMetadata;
console.log('Sources:', groundingMetadata?.webSearchQueries);
```

## Node.js Client Wrapper

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';
import OpenAI from 'openai';

type Provider = 'google' | 'openrouter';

interface GeminiClientConfig {
  provider: Provider;
  apiKey: string;
  defaultModel?: string;
}

class GeminiClient {
  private provider: Provider;
  private googleClient?: GoogleGenerativeAI;
  private openrouterClient?: OpenAI;
  private defaultModel: string;

  constructor(config: GeminiClientConfig) {
    this.provider = config.provider;
    this.defaultModel = config.defaultModel || 'gemini-2.0-flash';

    if (config.provider === 'google') {
      this.googleClient = new GoogleGenerativeAI(config.apiKey);
    } else {
      this.openrouterClient = new OpenAI({
        baseURL: 'https://openrouter.ai/api/v1',
        apiKey: config.apiKey,
      });
    }
  }

  private getOpenRouterModelId(model: string): string {
    const mapping: Record<string, string> = {
      'gemini-1.5-flash': 'google/gemini-flash-1.5',
      'gemini-1.5-pro': 'google/gemini-pro-1.5',
      'gemini-2.0-flash': 'google/gemini-2.0-flash-exp',
      'gemini-2.5-pro': 'google/gemini-2.5-pro-exp',
    };
    return mapping[model] || `google/${model}`;
  }

  async generate(
    prompt: string,
    options: { model?: string; systemPrompt?: string } = {}
  ): Promise<string> {
    const model = options.model || this.defaultModel;

    if (this.provider === 'google') {
      const genModel = this.googleClient!.getGenerativeModel({
        model,
        systemInstruction: options.systemPrompt,
      });
      const result = await genModel.generateContent(prompt);
      return result.response.text();
    } else {
      const messages: any[] = [];
      if (options.systemPrompt) {
        messages.push({ role: 'system', content: options.systemPrompt });
      }
      messages.push({ role: 'user', content: prompt });

      const response = await this.openrouterClient!.chat.completions.create({
        model: this.getOpenRouterModelId(model),
        messages,
      });
      return response.choices[0].message.content || '';
    }
  }

  async generateWithTools(
    prompt: string,
    tools: any[],
    options: { model?: string } = {}
  ): Promise<{ text?: string; toolCalls?: any[] }> {
    const model = options.model || this.defaultModel;

    if (this.provider === 'google') {
      const genModel = this.googleClient!.getGenerativeModel({
        model,
        tools: [{ functionDeclarations: tools }],
      });
      const result = await genModel.generateContent(prompt);
      const calls = result.response.functionCalls();
      return {
        text: result.response.text(),
        toolCalls: calls,
      };
    } else {
      const response = await this.openrouterClient!.chat.completions.create({
        model: this.getOpenRouterModelId(model),
        messages: [{ role: 'user', content: prompt }],
        tools: tools.map(t => ({ type: 'function', function: t })),
      });
      return {
        text: response.choices[0].message.content || undefined,
        toolCalls: response.choices[0].message.tool_calls,
      };
    }
  }
}

// Usage
const gemini = new GeminiClient({
  provider: process.env.USE_OPENROUTER ? 'openrouter' : 'google',
  apiKey: process.env.USE_OPENROUTER
    ? process.env.OPENROUTER_API_KEY!
    : process.env.GOOGLE_API_KEY!,
  defaultModel: 'gemini-2.0-flash',
});

const response = await gemini.generate('Hello!', {
  systemPrompt: 'You are a helpful assistant.',
});
```

## Rate Limits

### Direct API

| Model | RPM | TPM |
|-------|-----|-----|
| 1.5 Flash | 1,500 | 1M |
| 1.5 Pro | 360 | 120K |
| 2.0 Flash | 1,000 | 1M |
| 2.5 Pro | 100 | 50K |

### OpenRouter
- Varies by plan
- Check dashboard for current limits

## Error Handling

```typescript
try {
  const result = await model.generateContent(prompt);
} catch (error) {
  if (error.message.includes('SAFETY')) {
    console.log('Content filtered by safety settings');
  } else if (error.message.includes('RATE_LIMIT')) {
    console.log('Rate limited, implement backoff');
  } else if (error.message.includes('QUOTA')) {
    console.log('API quota exceeded');
  }
}
```

## Best Practices

1. **Start with Flash** - Use 1.5/2.0 Flash for prototyping
2. **Upgrade when needed** - Move to Pro for production quality
3. **Use OpenRouter for flexibility** - Easy model switching
4. **Cache responses** - Reduce costs with caching
5. **Stream long responses** - Better UX for chat
6. **Set safety thresholds** - Adjust for your use case

## Resources

- [Google AI Studio](https://aistudio.google.com/)
- [Gemini API Docs](https://ai.google.dev/gemini-api/docs)
- [OpenRouter Docs](https://openrouter.ai/docs)
